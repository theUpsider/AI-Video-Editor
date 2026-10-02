"""FFprobe-based media inspection into typed, persistable :class:`ProbeInfo` (AVE-REQ-004).

Properties come from the actual streams, never from file names or marketing labels: exact coded
width/height, sample aspect ratio, rotation (display matrix or legacy ``rotate`` tag) and the
resulting display size, exact rational frame rates (``60/1`` and ``60000/1001`` stay distinct),
stream time bases, start times, codecs, pixel formats, color tags and audio properties. Values that
a file does not carry are ``None``; nothing is invented.

Frame timing is classified by inspecting packet presentation timestamps (bounded to the first
:data:`DEFAULT_PTS_PACKETS` packets of each video stream): equal PTS deltas mean constant frame
rate, unequal deltas mean variable frame rate.

Source time convention: ``t_source = pts * time_base - container_start_time``. Normalizing by the
container (format) start time keeps the relative offset between the audio and video streams of one
file. The container start time is exact: FFmpeg reports it rounded to microseconds, so the probe
uses the exact start (``start_pts * time_base``) of the stream that defines it (see
:func:`parse_probe_json`).

Keyframe index: demuxers of containers without a keyframe index (MPEG-TS, MPEG-PS and others
outside :data:`INDEXED_SEEK_FORMATS`) cannot seek to a keyframe at or before a target time; their
seek lands on any packet and decoding resumes at the next keyframe, which may lie after the target.
For video streams of such containers the probe reads every packet once and records the keyframe
presentation timestamps, so the renderer can seek to a point that provably precedes a keyframe
(:mod:`ave.render.compiler`).

File names are untrusted (AVE-REQ-004): every FFprobe call passes :data:`LITERAL_INPUT_ARGS`, so the
image2 demuxer reads a name such as ``photo%d.png`` as that one file instead of expanding it as an
image-sequence pattern (``photo1.png``, ``photo2.png``...). FFprobe skips the option for every other
demuxer.
"""

from __future__ import annotations

import itertools
import json
from fractions import Fraction
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict

from ave.errors import MediaToolError, ProbeError
from ave.proc import media_url, run_tool
from ave.timebase import (
    NonNegativeRational,
    PositiveRational,
    Rational,
    TimeValueError,
    parse_ffmpeg_rational,
    round_half_up,
    to_rational,
)

__all__ = [
    "DEFAULT_PTS_PACKETS",
    "INDEXED_SEEK_FORMATS",
    "LITERAL_INPUT_ARGS",
    "AudioStreamInfo",
    "FrameTiming",
    "OtherStreamInfo",
    "ProbeInfo",
    "StreamInfo",
    "VideoStreamInfo",
    "parse_probe_json",
    "probe",
    "read_packet_pts",
    "read_video_packets",
]

DEFAULT_PTS_PACKETS = 1200
"""Number of video packets whose PTS are inspected to classify CFR versus VFR."""

FrameTiming = Literal["cfr", "vfr", "unknown"]

LITERAL_INPUT_ARGS = ("-pattern_type", "none")
"""Input options that make the image2 demuxer read the named file itself, never a numbered
sequence derived from ``%`` patterns in the name (FFprobe ignores them for other demuxers; FFmpeg
needs them together with ``-f image2``, see :mod:`ave.render.ffmpeg`)."""

INDEXED_SEEK_FORMATS = frozenset(
    {"mov", "mp4", "m4a", "3gp", "3g2", "mj2", "matroska", "webm", "avi", "mxf"}
)
"""Demuxers that seek with a keyframe index to a keyframe at or before the target time."""

_PROBE_TIMEOUT_S = 60.0
_INDEX_TIMEOUT_S = 1800.0


class _Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")


class _StreamBase(_Frozen):
    index: int
    codec_name: str | None
    codec_long_name: str | None = None
    time_base: PositiveRational | None
    start_pts: int | None
    start_time: Rational | None
    duration_ts: int | None
    duration: NonNegativeRational | None
    language: str | None = None
    is_default: bool = False
    is_attached_picture: bool = False


class VideoStreamInfo(_StreamBase):
    """A video stream with exact geometry, rates and color tags."""

    codec_type: Literal["video"] = "video"
    width: int
    height: int
    sample_aspect_ratio: PositiveRational | None
    """Pixel aspect ratio; ``None`` when the file does not declare one (treated as square)."""
    display_aspect_ratio: PositiveRational | None
    rotation: int
    """Display rotation in degrees (FFmpeg display-matrix convention, normalized to (-180, 180])."""
    display_width: int
    """Width as displayed: coded width scaled by the sample aspect ratio, swapped for 90/270."""
    display_height: int
    r_frame_rate: PositiveRational | None
    avg_frame_rate: PositiveRational | None
    nb_frames: int | None
    pix_fmt: str | None
    color_range: str | None
    color_space: str | None
    color_transfer: str | None
    color_primaries: str | None
    field_order: str | None
    profile: str | None
    bits_per_raw_sample: int | None
    frame_timing: FrameTiming
    pts_packets_inspected: int
    min_frame_interval: PositiveRational | None
    """Smallest PTS delta (seconds) among inspected packets."""
    max_frame_interval: PositiveRational | None
    """Largest PTS delta (seconds) among inspected packets."""
    keyframe_pts: tuple[int, ...] | None = None
    """PTS (time-base ticks, ascending) of every keyframe, recorded only for containers outside
    :data:`INDEXED_SEEK_FORMATS`; ``None`` when the demuxer's own keyframe index is used."""

    @property
    def is_vfr(self) -> bool:
        """True when inspected timestamps (or disagreeing rate metadata) show variable rate."""
        return self.frame_timing == "vfr"

    @property
    def display_aspect(self) -> Fraction:
        """Exact display aspect ratio (width / height) after SAR and rotation."""
        sar = self.sample_aspect_ratio or Fraction(1)
        aspect = Fraction(self.width) * sar / self.height
        return 1 / aspect if abs(self.rotation) == 90 else aspect


class AudioStreamInfo(_StreamBase):
    """An audio stream."""

    codec_type: Literal["audio"] = "audio"
    sample_rate: int | None
    channels: int | None
    channel_layout: str | None
    sample_fmt: str | None
    bit_rate: int | None


class OtherStreamInfo(_StreamBase):
    """Subtitle, data or attachment stream (kept so stream indices stay meaningful)."""

    codec_type: str


StreamInfo = VideoStreamInfo | AudioStreamInfo | OtherStreamInfo


class ProbeInfo(_Frozen):
    """Typed result of probing one media file."""

    format_name: str
    format_long_name: str | None
    duration: NonNegativeRational | None
    container_start_time: Rational
    """Origin of source time (format start time; zero when the file does not declare one)."""
    size_bytes: int | None
    bit_rate: int | None
    streams: tuple[StreamInfo, ...]

    @property
    def video_streams(self) -> tuple[VideoStreamInfo, ...]:
        """Video streams that are real pictures (attached cover art excluded)."""
        return tuple(
            s for s in self.streams if isinstance(s, VideoStreamInfo) and not s.is_attached_picture
        )

    @property
    def audio_streams(self) -> tuple[AudioStreamInfo, ...]:
        """All audio streams in container order."""
        return tuple(s for s in self.streams if isinstance(s, AudioStreamInfo))

    @property
    def has_audio(self) -> bool:
        """True when the file holds at least one audio stream."""
        return bool(self.audio_streams)

    def stream(self, index: int) -> StreamInfo:
        """The stream with absolute container index ``index``."""
        for item in self.streams:
            if item.index == index:
                return item
        raise ProbeError(f"no stream with index {index}", stream_index=index)

    def source_duration(self, stream: StreamInfo) -> Fraction | None:
        """Source-time end of ``stream`` (its start plus duration, relative to the origin)."""
        if stream.duration is None:
            return self.duration
        start = stream.start_time if stream.start_time is not None else self.container_start_time
        return start - self.container_start_time + stream.duration


# --------------------------------------------------------------------------------------------
# Parsing helpers
# --------------------------------------------------------------------------------------------


def _int_or_none(value: Any) -> int | None:
    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    try:
        return int(str(value))
    except ValueError:
        return None


def _decimal_or_none(value: Any) -> Fraction | None:
    if value is None:
        return None
    try:
        return to_rational(str(value))
    except TimeValueError:
        return None


def _str_or_none(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text if text and text not in {"unknown", "N/A"} else None


def _normalize_rotation(degrees: float) -> int:
    value = round(degrees) % 360
    return value - 360 if value > 180 else value


def _rotation(raw: dict[str, Any]) -> int:
    for side_data in raw.get("side_data_list") or ():
        if "rotation" in side_data:
            return _normalize_rotation(float(side_data["rotation"]))
    tags = raw.get("tags") or {}
    if "rotate" in tags:
        try:
            # The legacy tag is clockwise; the display matrix convention is counterclockwise.
            return _normalize_rotation(-float(tags["rotate"]))
        except ValueError:
            return 0
    return 0


def _sar(raw: dict[str, Any]) -> Fraction | None:
    value = parse_ffmpeg_rational(raw.get("sample_aspect_ratio"))
    return value if value is not None and value > 0 else None


def _common_fields(raw: dict[str, Any]) -> dict[str, Any]:
    time_base = parse_ffmpeg_rational(raw.get("time_base"))
    start_pts = _int_or_none(raw.get("start_pts"))
    duration_ts = _int_or_none(raw.get("duration_ts"))
    start_time = start_pts * time_base if (time_base and start_pts is not None) else None
    if start_time is None:
        start_time = _decimal_or_none(raw.get("start_time"))
    duration = duration_ts * time_base if (time_base and duration_ts is not None) else None
    if duration is None:
        duration = _decimal_or_none(raw.get("duration"))
    if duration is not None and duration < 0:
        duration = None
    disposition = raw.get("disposition") or {}
    tags = raw.get("tags") or {}
    return {
        "index": int(raw["index"]),
        "codec_name": _str_or_none(raw.get("codec_name")),
        "codec_long_name": _str_or_none(raw.get("codec_long_name")),
        "time_base": time_base,
        "start_pts": start_pts,
        "start_time": start_time,
        "duration_ts": duration_ts,
        "duration": duration,
        "language": _str_or_none(tags.get("language")),
        "is_default": bool(disposition.get("default", 0)),
        "is_attached_picture": bool(disposition.get("attached_pic", 0)),
    }


def _classify_timing(
    r_rate: Fraction | None,
    avg_rate: Fraction | None,
    pts: list[int] | None,
    time_base: Fraction | None,
) -> tuple[FrameTiming, int, Fraction | None, Fraction | None]:
    """CFR/VFR from inspected PTS deltas; falls back to rate metadata when PTS are unavailable."""
    if pts is not None and len(pts) < 3:
        return "unknown", len(pts), None, None
    if pts is not None and time_base is not None:
        ordered = sorted(set(pts))
        deltas = [b - a for a, b in itertools.pairwise(ordered)]
        smallest, largest = min(deltas), max(deltas)
        # One tick of jitter is container rounding of an exact rational rate, not VFR.
        timing: FrameTiming = "cfr" if largest - smallest <= 1 else "vfr"
        return timing, len(pts), smallest * time_base, largest * time_base
    if r_rate is not None and avg_rate is not None:
        return ("cfr" if r_rate == avg_rate else "vfr"), 0, None, None
    return "unknown", 0, None, None


def _video_stream(
    raw: dict[str, Any], pts: list[int] | None, keyframes: list[int] | None
) -> VideoStreamInfo:
    common = _common_fields(raw)
    width, height = int(raw.get("width") or 0), int(raw.get("height") or 0)
    if width <= 0 or height <= 0:
        raise ProbeError("video stream without valid dimensions", stream_index=common["index"])
    sar = _sar(raw)
    rotation = _rotation(raw)
    display_width = round_half_up(Fraction(width) * (sar or 1))
    display_height = height
    if abs(rotation) == 90:
        display_width, display_height = display_height, display_width
    r_rate = parse_ffmpeg_rational(raw.get("r_frame_rate"))
    avg_rate = parse_ffmpeg_rational(raw.get("avg_frame_rate"))
    timing, inspected, min_dt, max_dt = _classify_timing(r_rate, avg_rate, pts, common["time_base"])
    return VideoStreamInfo(
        **common,
        width=width,
        height=height,
        sample_aspect_ratio=sar,
        display_aspect_ratio=parse_ffmpeg_rational(raw.get("display_aspect_ratio")),
        rotation=rotation,
        display_width=display_width,
        display_height=display_height,
        r_frame_rate=r_rate,
        avg_frame_rate=avg_rate,
        nb_frames=_int_or_none(raw.get("nb_frames")),
        pix_fmt=_str_or_none(raw.get("pix_fmt")),
        color_range=_str_or_none(raw.get("color_range")),
        color_space=_str_or_none(raw.get("color_space")),
        color_transfer=_str_or_none(raw.get("color_transfer")),
        color_primaries=_str_or_none(raw.get("color_primaries")),
        field_order=_str_or_none(raw.get("field_order")),
        profile=_str_or_none(raw.get("profile")),
        bits_per_raw_sample=_int_or_none(raw.get("bits_per_raw_sample")),
        frame_timing=timing,
        pts_packets_inspected=inspected,
        min_frame_interval=min_dt,
        max_frame_interval=max_dt,
        keyframe_pts=tuple(sorted(keyframes)) if keyframes is not None else None,
    )


def _audio_stream(raw: dict[str, Any]) -> AudioStreamInfo:
    return AudioStreamInfo(
        **_common_fields(raw),
        sample_rate=_int_or_none(raw.get("sample_rate")),
        channels=_int_or_none(raw.get("channels")),
        channel_layout=_str_or_none(raw.get("channel_layout")),
        sample_fmt=_str_or_none(raw.get("sample_fmt")),
        bit_rate=_int_or_none(raw.get("bit_rate")),
    )


def _microseconds(value: Fraction) -> int:
    """``value`` in microseconds rounded half away from zero (FFmpeg's ``av_rescale_q``)."""
    scaled = value * 1_000_000
    magnitude = int(abs(scaled) + Fraction(1, 2))
    return magnitude if scaled >= 0 else -magnitude


def _exact_container_start(printed: Fraction | None, streams: list[StreamInfo]) -> Fraction:
    """The exact origin of source time.

    FFmpeg's container start time is the earliest stream start, kept (and printed by FFprobe) in
    microseconds: an MPEG-TS start of 129000/90000 s prints as 1.433333. The exact value is the
    start (``start_pts * time_base``) of the stream whose microsecond rounding equals the printed
    value; without such a stream the printed value is used. A file without a start time starts at 0.
    """
    if printed is None:
        return Fraction(0)
    target = printed * 1_000_000
    exact = [
        stream.start_time
        for stream in streams
        if stream.start_pts is not None
        and stream.time_base is not None
        and stream.start_time is not None
        and _microseconds(stream.start_time) == target
    ]
    return min(exact) if exact else printed


def parse_probe_json(
    data: dict[str, Any],
    packet_pts: dict[int, list[int]] | None = None,
    keyframe_pts: dict[int, list[int]] | None = None,
) -> ProbeInfo:
    """Builds :class:`ProbeInfo` from ``ffprobe -show_format -show_streams`` JSON.

    ``packet_pts`` maps a video stream index to the inspected packet PTS values (stream time-base
    ticks); without it, CFR/VFR classification falls back to comparing the rate metadata.
    ``keyframe_pts`` maps a video stream index to the PTS of all its keyframes (containers outside
    :data:`INDEXED_SEEK_FORMATS`).
    """
    fmt = data.get("format")
    if not isinstance(fmt, dict):
        raise ProbeError("ffprobe output has no format section")
    streams: list[StreamInfo] = []
    for raw in data.get("streams") or ():
        codec_type = raw.get("codec_type")
        if codec_type == "video":
            index = int(raw["index"])
            streams.append(
                _video_stream(raw, (packet_pts or {}).get(index), (keyframe_pts or {}).get(index))
            )
        elif codec_type == "audio":
            streams.append(_audio_stream(raw))
        else:
            streams.append(
                OtherStreamInfo(**_common_fields(raw), codec_type=str(codec_type or "unknown"))
            )
    duration = _decimal_or_none(fmt.get("duration"))
    # FFprobe prints the format start time (AVFormatContext.start_time, kept by FFmpeg in
    # microseconds) with six decimals, i.e. rounded: 129000/90000 s prints as 1.433333. The exact
    # origin is recovered from the stream start that FFmpeg rounded (_exact_container_start).
    start = _exact_container_start(_decimal_or_none(fmt.get("start_time")), streams)
    return ProbeInfo(
        format_name=str(fmt.get("format_name") or "unknown"),
        format_long_name=_str_or_none(fmt.get("format_long_name")),
        duration=duration if duration is not None and duration >= 0 else None,
        container_start_time=start,
        size_bytes=_int_or_none(fmt.get("size")),
        bit_rate=_int_or_none(fmt.get("bit_rate")),
        streams=tuple(streams),
    )


# --------------------------------------------------------------------------------------------
# FFprobe invocation
# --------------------------------------------------------------------------------------------


def read_packet_pts(
    path: Path, stream_index: int, *, max_packets: int | None = DEFAULT_PTS_PACKETS
) -> list[int]:
    """Packet PTS values (time-base ticks, decode order) of one stream, optionally bounded."""
    args = [
        "-v",
        "error",
        *LITERAL_INPUT_ARGS,
        "-select_streams",
        str(stream_index),
        "-show_entries",
        "packet=pts",
        "-of",
        "csv=p=0",
    ]
    if max_packets is not None:
        args += ["-read_intervals", f"%+#{max_packets}"]
    args.append(media_url(path))
    completed = run_tool("ffprobe", args, timeout=_PROBE_TIMEOUT_S)
    values: list[int] = []
    for line in completed.stdout.decode("ascii", errors="replace").splitlines():
        text = line.strip().rstrip(",")
        if text and text != "N/A":
            values.append(int(text))
    return values


def read_video_packets(
    path: Path, stream_index: int, *, max_packets: int | None = None
) -> list[tuple[int, bool]]:
    """``(pts, is_keyframe)`` of a stream's packets in file order (all packets by default)."""
    args = [
        "-v",
        "error",
        *LITERAL_INPUT_ARGS,
        "-select_streams",
        str(stream_index),
        "-show_entries",
        "packet=pts,flags",
        "-of",
        "csv=p=0",
    ]
    if max_packets is not None:
        args += ["-read_intervals", f"%+#{max_packets}"]
    args.append(media_url(path))
    completed = run_tool("ffprobe", args, timeout=_INDEX_TIMEOUT_S)
    packets: list[tuple[int, bool]] = []
    for line in completed.stdout.decode("ascii", errors="replace").splitlines():
        fields = line.strip().split(",")
        if fields and fields[0] not in {"", "N/A"}:
            packets.append((int(fields[0]), len(fields) > 1 and fields[1].startswith("K")))
    return packets


def _needs_keyframe_index(format_name: object) -> bool:
    return not set(str(format_name or "").split(",")) & INDEXED_SEEK_FORMATS


def probe(
    path: Path | str, *, inspect_pts: bool = True, max_pts_packets: int = DEFAULT_PTS_PACKETS
) -> ProbeInfo:
    """Probes ``path`` with FFprobe and returns typed stream information.

    Raises :class:`ProbeError` when the file cannot be parsed or has no audio or video stream.
    """
    file_path = Path(path)
    if not file_path.is_file():
        raise ProbeError("media file does not exist", path=file_path.name)
    args = [
        "-v",
        "error",
        *LITERAL_INPUT_ARGS,
        "-print_format",
        "json",
        "-show_format",
        "-show_streams",
        media_url(file_path),
    ]
    try:
        completed = run_tool("ffprobe", args, timeout=_PROBE_TIMEOUT_S)
        data = json.loads(completed.stdout.decode("utf-8", errors="replace"))
    except MediaToolError as exc:
        raise ProbeError(
            "ffprobe could not read the file", path=file_path.name, cause=exc.to_dict()
        ) from exc
    except json.JSONDecodeError as exc:
        raise ProbeError("ffprobe returned malformed JSON", path=file_path.name) from exc
    packet_pts: dict[int, list[int]] = {}
    keyframe_pts: dict[int, list[int]] = {}
    index_keyframes = _needs_keyframe_index((data.get("format") or {}).get("format_name"))
    if inspect_pts:
        for raw in data.get("streams") or ():
            disposition = raw.get("disposition") or {}
            if raw.get("codec_type") == "video" and not disposition.get("attached_pic"):
                index = int(raw["index"])
                if index_keyframes:
                    packets = read_video_packets(file_path, index)
                    packet_pts[index] = [pts for pts, _ in packets[:max_pts_packets]]
                    keyframe_pts[index] = [pts for pts, key in packets if key]
                else:
                    packet_pts[index] = read_packet_pts(
                        file_path, index, max_packets=max_pts_packets
                    )
    info = parse_probe_json(data, packet_pts, keyframe_pts)
    if not info.video_streams and not info.audio_streams:
        raise ProbeError("file holds no audio or video stream", path=file_path.name)
    return info
