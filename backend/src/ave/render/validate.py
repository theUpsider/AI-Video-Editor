"""Decoded-output validation and media reading helpers (AVE-REQ-072 AC-4, AVE-REQ-075 AC-4).

:func:`validate_output` checks a rendered file the way a consumer sees it: FFprobe properties
(container, codecs, exact dimensions, exact frame rate as a rational, stream count, durations),
every video packet timestamp (strictly increasing, uniform, starting at zero) and a full decode of
all streams without errors. The renderer publishes an output only when every check passes.

The decoding helpers (:func:`iter_video_frames`, :func:`decode_video_frames`, :func:`decode_audio`)
return actual decoded pixels (RGB, optionally at reduced resolution) and PCM samples so that tests
and product checks can inspect real content rather than plans.
"""

from __future__ import annotations

import itertools
from collections.abc import Iterator
from fractions import Fraction
from pathlib import Path

import numpy as np
import numpy.typing as npt
from pydantic import BaseModel, ConfigDict

from ave.errors import AveError
from ave.media.probe import ProbeInfo, VideoStreamInfo, probe, read_packet_pts
from ave.proc import media_url, run_tool, stream_tool
from ave.timebase import PositiveRational, frame_start

__all__ = [
    "ExpectedOutput",
    "ValidationCheck",
    "ValidationResult",
    "audio_window",
    "decode_audio",
    "decode_video_frames",
    "iter_video_frames",
    "validate_output",
]

_DECODE_TIMEOUT_S = 1800.0
_MATRICES = {"bt709": "bt709", "bt470bg": "bt601", "smpte170m": "bt601", "bt2020nc": "bt2020"}


class _Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")


class ExpectedOutput(_Frozen):
    """Properties a rendered file must have."""

    width: int
    height: int
    fps: PositiveRational
    frame_count: int
    sample_rate: int = 48000
    channels: int = 2
    sample_count: int
    video_codec: str = "h264"
    audio_codec: str = "aac"
    pix_fmt: str = "yuv420p"
    container: str = "mp4"


class ValidationCheck(_Frozen):
    """One validation assertion with the expected and actual values."""

    name: str
    passed: bool
    expected: str
    actual: str


class ValidationResult(_Frozen):
    """Outcome of validating one rendered file."""

    passed: bool
    checks: tuple[ValidationCheck, ...]
    probe: ProbeInfo | None = None

    @property
    def failures(self) -> tuple[ValidationCheck, ...]:
        """The checks that failed."""
        return tuple(c for c in self.checks if not c.passed)


class _Checks:
    def __init__(self) -> None:
        self.items: list[ValidationCheck] = []

    def add(self, name: str, passed: bool, expected: object, actual: object) -> bool:
        self.items.append(
            ValidationCheck(name=name, passed=passed, expected=str(expected), actual=str(actual))
        )
        return passed


def _check_video(
    path: Path, info: ProbeInfo, stream: VideoStreamInfo, expected: ExpectedOutput, checks: _Checks
) -> None:
    frame = frame_start(1, expected.fps)
    checks.add(
        "video codec",
        stream.codec_name == expected.video_codec,
        expected.video_codec,
        stream.codec_name,
    )
    checks.add(
        "dimensions",
        (stream.width, stream.height) == (expected.width, expected.height),
        f"{expected.width}x{expected.height}",
        f"{stream.width}x{stream.height}",
    )
    checks.add(
        "square pixels",
        stream.sample_aspect_ratio in (None, Fraction(1)),
        "1:1",
        stream.sample_aspect_ratio,
    )
    checks.add("pixel format", stream.pix_fmt == expected.pix_fmt, expected.pix_fmt, stream.pix_fmt)
    checks.add(
        "r_frame_rate", stream.r_frame_rate == expected.fps, expected.fps, stream.r_frame_rate
    )
    checks.add(
        "avg_frame_rate", stream.avg_frame_rate == expected.fps, expected.fps, stream.avg_frame_rate
    )
    pts = read_packet_pts(path, stream.index, max_packets=None)
    checks.add(
        "video frame count", len(pts) == expected.frame_count, expected.frame_count, len(pts)
    )
    if stream.time_base is not None and pts:
        ordered = sorted(pts)
        step = frame / stream.time_base
        uniform = all(b - a == step for a, b in itertools.pairwise(ordered))
        checks.add(
            "timestamps strictly increasing and uniform",
            uniform and len(set(pts)) == len(pts),
            f"delta {step} ticks",
            "uniform" if uniform else "irregular",
        )
        start = (ordered[0] * stream.time_base) - info.container_start_time
        checks.add("video starts at zero", start == 0, 0, start)
    duration = stream.duration
    expected_duration = frame_start(expected.frame_count, expected.fps)
    checks.add(
        "video duration within one frame",
        duration is not None and abs(duration - expected_duration) < frame,
        expected_duration,
        duration,
    )


def validate_output(path: Path | str, expected: ExpectedOutput) -> ValidationResult:
    """Validates a rendered file against ``expected`` by probing and fully decoding it."""
    file_path = Path(path)
    checks = _Checks()
    try:
        info = probe(file_path, inspect_pts=False)
    except AveError as exc:
        checks.add("probe", False, "readable media", exc.message)
        return ValidationResult(passed=False, checks=tuple(checks.items))
    checks.add(
        "container",
        expected.container in info.format_name.split(","),
        expected.container,
        info.format_name,
    )
    videos, audios = info.video_streams, info.audio_streams
    checks.add(
        "stream count",
        (len(videos), len(audios), len(info.streams)) == (1, 1, 2),
        "1 video + 1 audio",
        f"{len(videos)} video + {len(audios)} audio of {len(info.streams)} streams",
    )
    if videos:
        _check_video(file_path, info, videos[0], expected, checks)
    if audios:
        audio = audios[0]
        frame = frame_start(1, expected.fps)
        checks.add(
            "audio codec",
            audio.codec_name == expected.audio_codec,
            expected.audio_codec,
            audio.codec_name,
        )
        checks.add(
            "audio sample rate",
            audio.sample_rate == expected.sample_rate,
            expected.sample_rate,
            audio.sample_rate,
        )
        checks.add(
            "audio channels", audio.channels == expected.channels, expected.channels, audio.channels
        )
        expected_audio = Fraction(expected.sample_count, expected.sample_rate)
        checks.add(
            "audio duration within one frame",
            audio.duration is not None and abs(audio.duration - expected_audio) < frame,
            expected_audio,
            audio.duration,
        )
    try:
        run_tool(
            "ffmpeg",
            [
                "-hide_banner",
                "-nostdin",
                "-v",
                "error",
                "-xerror",
                "-i",
                media_url(file_path),
                "-map",
                "0",
                "-f",
                "null",
                "-",
            ],
            timeout=_DECODE_TIMEOUT_S,
        )
        checks.add("full decode without errors", True, "no decoder errors", "ok")
    except AveError as exc:
        checks.add(
            "full decode without errors",
            False,
            "no decoder errors",
            exc.details.get("stderr") or exc.message,
        )
    passed = all(c.passed for c in checks.items)
    return ValidationResult(passed=passed, checks=tuple(checks.items), probe=info)


# --------------------------------------------------------------------------------------------
# Decoding helpers
# --------------------------------------------------------------------------------------------


def _scale_filter(stream: VideoStreamInfo | None, width: int, height: int) -> str:
    options = [f"{width}:{height}", "flags=area"]
    if stream is not None and stream.color_space in _MATRICES:
        options.append(f"in_color_matrix={_MATRICES[stream.color_space]}")
    if stream is not None and stream.color_range in {"tv", "pc"}:
        options.append(f"in_range={stream.color_range}")
    return "scale=" + ":".join(options) + ",format=rgb24"


def iter_video_frames(
    path: Path | str,
    *,
    width: int,
    height: int,
    start_frame: int = 0,
    count: int | None = None,
    stream: VideoStreamInfo | None = None,
) -> Iterator[npt.NDArray[np.uint8]]:
    """Yields decoded frames as ``(height, width, 3)`` RGB arrays, in presentation order.

    Frames are counted from the first decoded frame (no rate conversion); scaling uses area
    averaging, which suits measurements on large uniform patches.
    """
    trim = f"trim=start_frame={start_frame}"
    if count is not None:
        trim += f":end_frame={start_frame + count}"
    args = [
        "-hide_banner",
        "-nostdin",
        "-v",
        "error",
        "-i",
        media_url(path),
        "-map",
        "0:v:0",
        "-vf",
        f"{trim},{_scale_filter(stream, width, height)}",
        "-fps_mode",
        "passthrough",
        "-f",
        "rawvideo",
        "-",
    ]
    frame_bytes = width * height * 3
    with stream_tool("ffmpeg", args, timeout=_DECODE_TIMEOUT_S) as pipe:
        while True:
            data = pipe.read(frame_bytes)
            if len(data) < frame_bytes:
                break
            yield np.frombuffer(data, dtype=np.uint8).reshape(height, width, 3)


def decode_video_frames(
    path: Path | str,
    *,
    width: int,
    height: int,
    start_frame: int = 0,
    count: int | None = None,
    stream: VideoStreamInfo | None = None,
) -> npt.NDArray[np.uint8]:
    """All requested frames as one ``(n, height, width, 3)`` array."""
    frames = list(
        iter_video_frames(
            path, width=width, height=height, start_frame=start_frame, count=count, stream=stream
        )
    )
    if not frames:
        return np.zeros((0, height, width, 3), dtype=np.uint8)
    return np.stack(frames)


def decode_audio(
    path: Path | str,
    *,
    sample_rate: int = 48000,
    channels: int | None = None,
    stream_index: int | None = None,
) -> npt.NDArray[np.float32]:
    """Decodes one audio stream to float32 PCM shaped ``(samples, channels)``.

    ``stream_index`` is the absolute container index (default: first audio stream); ``channels``
    downmixes or keeps the source layout when ``None``.
    """
    file_path = Path(path)
    if channels is None:
        info = probe(file_path, inspect_pts=False)
        streams = info.audio_streams
        chosen = (
            next((s for s in streams if s.index == stream_index), None)
            if stream_index is not None
            else (streams[0] if streams else None)
        )
        if chosen is None or not chosen.channels:
            raise AveError("no decodable audio stream", code="MISSING_STREAM")
        channels = chosen.channels
    selector = f"0:{stream_index}" if stream_index is not None else "0:a:0"
    completed = run_tool(
        "ffmpeg",
        [
            "-hide_banner",
            "-nostdin",
            "-v",
            "error",
            "-i",
            media_url(file_path),
            "-map",
            selector,
            "-ac",
            str(channels),
            "-ar",
            str(sample_rate),
            "-f",
            "f32le",
            "-",
        ],
        timeout=_DECODE_TIMEOUT_S,
    )
    samples = np.frombuffer(completed.stdout, dtype="<f4").astype(np.float32)
    return samples.reshape(-1, channels)


def audio_window(
    samples: npt.NDArray[np.float32], sample_rate: int, start_s: float, end_s: float
) -> npt.NDArray[np.float32]:
    """Samples presented in ``[start_s, end_s)`` (clamped to the available range)."""
    first = max(0, int(np.ceil(start_s * sample_rate)))
    last = min(len(samples), int(np.ceil(end_s * sample_rate)))
    return samples[first:last]
