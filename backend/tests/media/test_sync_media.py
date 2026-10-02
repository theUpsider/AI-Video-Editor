"""Audio sync on the real fixture files: AVE-REQ-024 (AT-04)."""

from __future__ import annotations

import math
import tracemalloc
from fractions import Fraction
from pathlib import Path

import numpy as np
import pytest

from ave.fixtures.standard import B_OFFSET, REFERENCE_EVENT_FRAMES, StandardFixtures
from ave.media.probe import probe
from ave.sync.audio import SyncStatus, estimate_offset, extract_analysis_audio
from tests.media.derived import AUDIO_DELAY, LATE_AAC_DELAY, DerivedMedia, derived_media
from tests.oracles import detect_chirps, match_events

pytestmark = pytest.mark.media

ONE_FRAME_60 = Fraction(1, 60)


@pytest.fixture(scope="module")
def derived(std: StandardFixtures, artifacts_dir: Path) -> DerivedMedia:
    """Timing variants of fixture A (audio starting 0.5 s after the container start)."""
    return derived_media(std, artifacts_dir / "derived")


def test_known_offset_is_recovered_within_one_frame(std: StandardFixtures) -> None:
    """AVE-REQ-024 AC-4 / AC-2: a_B = 2 from AAC audio at 48 kHz (A) vs 44.1 kHz (B)."""
    assert probe(std.a.path).audio_streams[0].sample_rate == 48000
    assert probe(std.b.path).audio_streams[0].sample_rate == 44100
    result = estimate_offset(std.a.path, std.b.path)
    assert result.status == SyncStatus.OK
    assert result.offset is not None
    assert result.offset_s is not None
    assert abs(result.offset - B_OFFSET) <= ONE_FRAME_60
    assert abs(result.offset_s - float(B_OFFSET)) < 1e-4  # measured: about 25 ns
    assert result.matched_onsets >= 7
    assert result.residual_s is not None
    assert result.residual_s < 1e-4
    # AVE-REQ-024 AC-3: aligned intervals in reference time and in B's source time.
    assert result.reference_overlap is not None
    assert result.target_source_interval is not None
    assert (result.reference_overlap.start, result.reference_overlap.end) == (2, 27)
    assert (result.target_source_interval.start, result.target_source_interval.end) == (0, 25)


def test_negative_offset_with_swapped_reference(std: StandardFixtures) -> None:
    """AVE-REQ-024 AC-2: with B as reference, A maps with a = -2."""
    result = estimate_offset(std.b.path, std.a.path)
    assert result.status == SyncStatus.OK
    assert result.offset is not None
    assert abs(result.offset + B_OFFSET) <= ONE_FRAME_60


def test_unrelated_recording_is_not_synchronized(std: StandardFixtures) -> None:
    """AVE-REQ-024 AC-3: the joint shot C shares no events with A."""
    result = estimate_offset(std.a.path, std.c.path)
    assert result.status == SyncStatus.INSUFFICIENT_EVIDENCE
    assert result.offset is None


def test_late_audio_start_is_part_of_the_offset(
    std: StandardFixtures, derived: DerivedMedia
) -> None:
    """AVE-REQ-024 AC-2, AVE-REQ-012 AC-4: A's own audio, starting 0.5 s after the container
    start, is found at a = -0.5 against A (its events sit 0.5 s later in source time)."""
    late = probe(derived.late_audio)
    assert late.container_start_time == 0
    assert late.audio_streams[0].start_time == AUDIO_DELAY
    result = estimate_offset(std.a.path, derived.late_audio)
    assert result.status == SyncStatus.OK
    assert result.offset_s is not None
    assert abs(result.offset_s + float(AUDIO_DELAY)) < 1e-4


@pytest.mark.parametrize("variant", ["late_aac_mp4", "late_aac_ts"])
def test_late_aac_audio_offset_in_mp4_and_mpegts(
    std: StandardFixtures, derived: DerivedMedia, variant: str
) -> None:
    """AVE-REQ-024 AC-2, AVE-REQ-012 AC-4: A's AAC audio shifted 0.8 s against its video, in MP4
    and in MPEG-TS (container start 43/30 s, audio stream start 2.212 s), is found at a = -0.8
    against A: the offset is measured in source time, from the exact container start."""
    result = estimate_offset(std.a.path, getattr(derived, variant))
    assert result.status == SyncStatus.OK
    assert result.offset_s is not None
    assert abs(result.offset_s + float(LATE_AAC_DELAY)) < 1e-4


def test_analysis_audio_follows_timestamps_in_float32_within_its_memory(
    derived: DerivedMedia,
) -> None:
    """AVE-REQ-024 AC-1, AVE-REQ-012 AC-4: the camera's analysis audio is mono float32 at
    48 kHz with sample k at source time k / 48000 - silence before the late stream start,
    chirps at event + 0.5 s - and its extraction peaks at about 4 bytes per sample."""
    info = probe(derived.late_audio)
    end = info.source_duration(info.audio_streams[0])
    assert end is not None
    tracemalloc.start()
    try:
        samples = extract_analysis_audio(derived.late_audio)
        _, peak = tracemalloc.get_traced_memory()
    finally:
        tracemalloc.stop()
    assert samples.dtype == np.float32
    assert samples.ndim == 1
    assert len(samples) == math.ceil(end * 48000)
    assert peak <= 4 * len(samples) + 2 * 2**20
    assert np.abs(samples[: int(0.49 * 48000)]).max() < 1e-6
    expected = [float(Fraction(frame, 60) + AUDIO_DELAY) for frame in REFERENCE_EVENT_FRAMES]
    pairs, missing, unexpected = match_events(detect_chirps(samples, 48000), expected, 0.01)
    assert not missing
    assert not unexpected
    assert max(abs(detected - value) for value, detected in pairs) <= 2 / 48000
