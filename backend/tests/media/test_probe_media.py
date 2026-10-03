"""Real FFprobe on generated fixtures: AVE-REQ-004 (AT-01, AT-03)."""

from __future__ import annotations

from fractions import Fraction
from pathlib import Path

import pytest

from ave.errors import ProbeError
from ave.fixtures.generate import VFR_TICK_RATE, Fixture
from ave.fixtures.standard import StandardFixtures
from ave.media.probe import ProbeInfo, VideoStreamInfo, probe, read_packet_pts

pytestmark = pytest.mark.media

RATES = {
    "rate-24": Fraction(24),
    "rate-25": Fraction(25),
    "rate-30": Fraction(30),
    "rate-30000-1001": Fraction(30000, 1001),
    "rate-60": Fraction(60),
    "rate-60000-1001": Fraction(60000, 1001),
}


def _video(info: ProbeInfo) -> VideoStreamInfo:
    (stream,) = info.video_streams
    return stream


@pytest.mark.req("AVE-REQ-004 AC-3")
def test_exact_2560x1440_at_60(std: StandardFixtures) -> None:
    """AVE-REQ-004 AC-3: a "2K/60" input reports its exact pixels and exact 60/1 rate."""
    info = probe(std.qhd.path)
    video = _video(info)
    assert (video.width, video.height) == (2560, 1440)
    assert (video.display_width, video.display_height) == (2560, 1440)
    assert video.r_frame_rate == Fraction(60)
    assert video.avg_frame_rate == Fraction(60)
    assert video.frame_timing == "cfr"
    assert video.nb_frames == 240
    assert video.duration == 4


@pytest.mark.req("AVE-REQ-004 AC-1")
def test_stream_properties_are_persistable(std: StandardFixtures) -> None:
    """AVE-REQ-004 AC-1: dimensions, SAR, rotation, time base, rates, codec, pixel format, color
    tags and audio properties are recorded and survive a JSON round trip."""
    info = probe(std.b.path)
    video = _video(info)
    assert video.codec_name == "h264"
    assert video.pix_fmt == "yuv420p"
    assert (video.color_space, video.color_primaries, video.color_transfer) == ("bt709",) * 3
    assert video.color_range == "tv"
    assert video.sample_aspect_ratio == 1
    assert video.rotation == 0
    assert video.time_base == Fraction(1, 15360)
    assert video.duration == 25
    (audio,) = info.audio_streams
    assert (audio.codec_name, audio.sample_rate, audio.channels) == ("aac", 44100, 1)
    assert audio.duration == 25
    assert ProbeInfo.model_validate_json(info.model_dump_json()) == info


@pytest.mark.req("AVE-REQ-004 AC-2")
def test_rate_matrix_keeps_exact_rates(timing_fixtures: dict[str, Fixture]) -> None:
    """AVE-REQ-004 AC-2: 24, 25, 30, 30000/1001, 60 and 60000/1001 are distinct exact rates."""
    measured = {}
    for key, rate in RATES.items():
        video = _video(probe(timing_fixtures[key].path))
        assert video.r_frame_rate == rate, key
        assert video.avg_frame_rate == rate, key
        assert video.frame_timing == "cfr", key
        assert video.pts_packets_inspected == video.nb_frames, key
        assert video.min_frame_interval == 1 / rate, key
        measured[key] = video.r_frame_rate
    assert measured["rate-60"] != measured["rate-60000-1001"]
    assert measured["rate-30"] != measured["rate-30000-1001"]


@pytest.mark.req("AVE-REQ-004 AC-2")
def test_variable_frame_rate_is_detected_from_timestamps(
    timing_fixtures: dict[str, Fixture],
) -> None:
    """AVE-REQ-004 AC-2: irregular presentation timestamps classify the stream as VFR."""
    fixture = timing_fixtures["vfr"]
    video = _video(probe(fixture.path))
    assert video.frame_timing == "vfr"
    assert video.min_frame_interval == Fraction(1, VFR_TICK_RATE)
    assert video.max_frame_interval == Fraction(5, VFR_TICK_RATE)
    pts = sorted(read_packet_pts(fixture.path, video.index, max_packets=None))
    assert video.time_base == Fraction(1, VFR_TICK_RATE)
    assert pts == fixture.manifest["vfr_frame_ticks"]


@pytest.mark.req("AVE-REQ-004 AC-4")
def test_rotation_sar_and_audio_layouts(timing_fixtures: dict[str, Fixture]) -> None:
    """AVE-REQ-004 AC-4: rotation metadata, anamorphic pixels, several/no/only audio streams."""
    rotated = _video(probe(timing_fixtures["rotated"].path))
    assert (rotated.width, rotated.height) == (320, 180)
    assert rotated.rotation == 90
    assert (rotated.display_width, rotated.display_height) == (180, 320)

    anamorphic = _video(probe(timing_fixtures["anamorphic"].path))
    assert anamorphic.sample_aspect_ratio == Fraction(4, 3)
    assert (anamorphic.display_width, anamorphic.display_height) == (1920, 1080)

    multi = probe(timing_fixtures["multi-audio"].path)
    assert [(a.sample_rate, a.channels) for a in multi.audio_streams] == [(48000, 1), (44100, 2)]

    silent = probe(timing_fixtures["no-audio"].path)
    assert silent.audio_streams == ()
    assert not silent.has_audio

    audio_only = probe(timing_fixtures["audio-only"].path)
    assert audio_only.video_streams == ()
    assert [(a.sample_rate, a.channels) for a in audio_only.audio_streams] == [(48000, 2)]

    still = _video(probe(timing_fixtures["still"].path))
    assert (still.width, still.height) == (640, 360)
    assert still.frame_timing == "unknown"  # one picture has no frame rate to classify


def test_corrupt_and_missing_files_fail_cleanly(tmp_path: Path) -> None:
    """AVE-REQ-004: unreadable input raises a structured probe error (no invented values)."""
    corrupt = tmp_path / "corrupt.mp4"
    corrupt.write_bytes(b"\x00\x00\x00\x18ftypmp42" + bytes(range(256)) * 64)
    with pytest.raises(ProbeError) as error:
        probe(corrupt)
    assert error.value.code == "PROBE_FAILED"
    with pytest.raises(ProbeError):
        probe(tmp_path / "missing.mp4")
