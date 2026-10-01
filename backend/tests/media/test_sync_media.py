"""Audio sync on the real fixture files: AVE-REQ-024 (AT-04)."""

from __future__ import annotations

from fractions import Fraction

import pytest

from ave.fixtures.standard import B_OFFSET, StandardFixtures
from ave.media.probe import probe
from ave.sync.audio import SyncStatus, estimate_offset

pytestmark = pytest.mark.media

ONE_FRAME_60 = Fraction(1, 60)


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
