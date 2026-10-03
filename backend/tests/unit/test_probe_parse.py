"""FFprobe JSON parsing without media files: AVE-REQ-004 AC-1, AC-2, AC-4."""

from __future__ import annotations

from fractions import Fraction
from typing import Any

import pytest

from ave.errors import ProbeError
from ave.media.probe import VideoStreamInfo, parse_probe_json


def _video(**overrides: Any) -> dict[str, Any]:
    stream: dict[str, Any] = {
        "index": 0,
        "codec_type": "video",
        "codec_name": "h264",
        "width": 1920,
        "height": 1080,
        "r_frame_rate": "60000/1001",
        "avg_frame_rate": "60000/1001",
        "time_base": "1/60000",
        "start_pts": 0,
        "duration_ts": 600600,
    }
    stream.update(overrides)
    return stream


def _parse(*streams: dict[str, Any], pts: dict[int, list[int]] | None = None) -> Any:
    return parse_probe_json(
        {"format": {"format_name": "mov,mp4", "duration": "10.010000"}, "streams": list(streams)},
        pts,
    )


def _first_video(info: Any) -> VideoStreamInfo:
    stream = info.video_streams[0]
    assert isinstance(stream, VideoStreamInfo)
    return stream


def test_exact_rates_and_durations_are_rationals() -> None:
    """AVE-REQ-004 AC-1/AC-2: 60000/1001 is kept exactly and durations come from ticks."""
    video = _first_video(_parse(_video()))
    assert video.r_frame_rate == Fraction(60000, 1001)
    assert video.r_frame_rate != 60
    assert video.duration == Fraction(1001, 100)
    assert video.time_base == Fraction(1, 60000)


def test_missing_optional_tags_stay_unknown() -> None:
    """AVE-REQ-004 AC-4: absent color tags, SAR or rates are None, never invented."""
    video = _first_video(_parse(_video(r_frame_rate="0/0", avg_frame_rate="0/0")))
    assert video.color_space is None
    assert video.color_primaries is None
    assert video.sample_aspect_ratio is None
    assert video.r_frame_rate is None
    assert video.frame_timing == "unknown"
    info = _parse(_video())
    assert info.audio_streams == ()
    assert not info.has_audio


def test_rotation_swaps_display_dimensions() -> None:
    """AVE-REQ-004 AC-1/AC-4: display-matrix and legacy rotate tags give portrait display size."""
    matrix = _first_video(_parse(_video(side_data_list=[{"rotation": -90}])))
    assert (matrix.width, matrix.height) == (1920, 1080)
    assert (matrix.display_width, matrix.display_height) == (1080, 1920)
    assert matrix.rotation == -90
    legacy = _first_video(_parse(_video(tags={"rotate": "90"})))
    assert legacy.rotation == -90
    assert legacy.display_aspect == Fraction(9, 16)
    upside_down = _first_video(_parse(_video(side_data_list=[{"rotation": 180}])))
    assert (upside_down.display_width, upside_down.display_height) == (1920, 1080)


def test_sample_aspect_ratio_scales_display_width() -> None:
    """AVE-REQ-004 AC-1: anamorphic 1440x1080 with SAR 4:3 displays as 1920x1080."""
    video = _first_video(_parse(_video(width=1440, sample_aspect_ratio="4:3")))
    assert video.sample_aspect_ratio == Fraction(4, 3)
    assert (video.display_width, video.display_height) == (1920, 1080)


def test_frame_timing_comes_from_presentation_timestamps() -> None:
    """AVE-REQ-004 AC-2: equal PTS deltas are CFR, irregular deltas VFR, even if rates agree."""
    cfr = _first_video(_parse(_video(), pts={0: [0, 2002, 1001, 3003, 4004]}))
    assert cfr.frame_timing == "cfr"
    assert cfr.min_frame_interval == Fraction(1001, 60000)
    vfr = _first_video(_parse(_video(), pts={0: [0, 1001, 3003, 4004, 7007]}))
    assert vfr.frame_timing == "vfr"
    assert vfr.max_frame_interval == Fraction(3003, 60000)
    jitter = _first_video(_parse(_video(time_base="1/90000"), pts={0: [0, 1501, 3003, 4504, 6006]}))
    assert jitter.frame_timing == "cfr"  # one tick of rounding is not VFR
    by_metadata = _first_video(_parse(_video(avg_frame_rate="50/1")))
    assert by_metadata.frame_timing == "vfr"


def test_multiple_audio_streams_are_listed_in_order() -> None:
    """AVE-REQ-004 AC-4: every audio stream is kept with its own properties."""
    audio = [
        {"index": 1, "codec_type": "audio", "codec_name": "aac", "sample_rate": "48000",
         "channels": 1, "time_base": "1/48000"},
        {"index": 2, "codec_type": "audio", "codec_name": "pcm_s16le", "sample_rate": "44100",
         "channels": 2, "channel_layout": "stereo", "time_base": "1/44100"},
    ]  # fmt: skip
    info = _parse(_video(), *audio)
    assert [(a.index, a.sample_rate, a.channels) for a in info.audio_streams] == [
        (1, 48000, 1),
        (2, 44100, 2),
    ]
    assert info.stream(2).codec_name == "pcm_s16le"
    with pytest.raises(ProbeError):
        info.stream(9)


def test_invalid_probe_output_is_rejected() -> None:
    """A video stream without dimensions or a missing format section is a probe error."""
    with pytest.raises(ProbeError):
        _parse(_video(width=0))
    with pytest.raises(ProbeError):
        parse_probe_json({"streams": []})


def _with_start(printed: str | None, *streams: dict[str, Any]) -> Any:
    fmt: dict[str, Any] = {"format_name": "mpegts", "duration": "10.000000"}
    if printed is not None:
        fmt["start_time"] = printed
    return parse_probe_json({"format": fmt, "streams": list(streams)})


def _audio(**overrides: Any) -> dict[str, Any]:
    stream: dict[str, Any] = {
        "index": 1,
        "codec_type": "audio",
        "codec_name": "aac",
        "sample_rate": "48000",
        "channels": 2,
        "time_base": "1/90000",
        "start_pts": 199080,
    }
    stream.update(overrides)
    return stream


def test_container_start_is_recovered_exactly_from_the_rounded_print() -> None:
    """AVE-REQ-012 AC-4: FFprobe prints the TS start 129000/90000 s as 1.433333; the origin of
    source time is the exact stream start, never the rounded print (which would put every frame
    1/3 microsecond late and select the previous frame on ties)."""
    info = _with_start("1.433333", _video(time_base="1/90000", start_pts=129000), _audio())
    assert info.container_start_time == Fraction(43, 30)
    assert info.warnings == ()


def test_container_start_takes_the_earliest_matching_stream() -> None:
    """AVE-REQ-012 AC-4: two streams whose starts both round to the printed microsecond (here
    0.3333331 s and 1/3 s) - the container start is the earlier one, as in FFmpeg, in either
    stream order."""
    video = _video(time_base="1/90000", start_pts=30000)
    audio = _audio(time_base="1/10000000", start_pts=3333331)
    for streams in ((video, audio), (audio, video)):
        info = _with_start("0.333333", *streams)
        assert info.container_start_time == Fraction(3333331, 10000000)
        assert info.warnings == ()


def test_unmatched_container_start_falls_back_with_a_warning() -> None:
    """AVE-REQ-012 AC-4, AVE-REQ-004 AC-4: when no stream start rounds to the printed value
    (129001/90000 s prints as 1.433344, not 1.433333) the printed value is used and the probe
    says that the origin is approximate; nothing is invented silently."""
    info = _with_start("1.433333", _video(time_base="1/90000", start_pts=129001))
    assert info.container_start_time == Fraction(1433333, 1000000)
    assert len(info.warnings) == 1
    assert "approximate" in info.warnings[0]


@pytest.mark.parametrize("missing", ["start_pts", "time_base"])
def test_stream_start_known_only_as_printed_never_defines_the_origin(missing: str) -> None:
    """AVE-REQ-012 AC-4, AVE-REQ-004 AC-4: a stream that reports its start only as printed
    seconds (``start_time`` 1.433333 without ``start_pts`` or without ``time_base``) is itself
    rounded to microseconds, so it supplies no exact origin: the printed container start is used
    and reported as approximate, even though the two printed values agree."""
    stream = _video(time_base="1/90000", start_pts=129000, start_time="1.433333")
    del stream[missing]
    info = _with_start("1.433333", stream)
    assert info.streams[0].start_time == Fraction(1433333, 1000000)
    assert info.container_start_time == Fraction(1433333, 1000000)
    assert len(info.warnings) == 1
    assert "approximate" in info.warnings[0]


def test_missing_container_start_is_zero_without_a_warning() -> None:
    """AVE-REQ-004 AC-4: a container without a start time starts source time at 0."""
    info = _with_start(None, _video())
    assert info.container_start_time == 0
    assert info.warnings == ()
