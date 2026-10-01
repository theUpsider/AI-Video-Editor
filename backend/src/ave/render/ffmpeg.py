"""Executes a :class:`RenderPlan` with FFmpeg on the CPU (ADR-005, AVE-REQ-072/075).

Pipeline (every command is an argv list; filter graphs go through ``-filter_complex_script``
files that never contain file paths):

1. **Segments** - one FFmpeg run per segment: each layer input is seeked accurately near the needed
   source time, mapped onto the output frame grid with exact integer timestamp arithmetic (see
   :mod:`ave.render.compiler`), scaled/cropped per the layout geometry and overlaid in z-order on
   the background canvas. Every segment is encoded with identical libx264 settings into an MP4
   whose video time scale represents the frame rate exactly; the first frame is an IDR frame and
   GOPs are closed.
2. **Audio** - one run renders the range's audio: sample-accurate trims, resampling to 48 kHz with
   SoX, pitch-preserving time scaling (Rubber Band) when ``source_speed != 1``, gain, exact sample
   delay and an un-normalized mix, written as 32-bit float PCM.
3. **Assembly** - the segments are concatenated by stream copy (concat demuxer) and muxed with the
   AAC-encoded audio into an MP4 with ``+faststart``.
4. **Validation and publish** - the result, written under a temporary name next to the
   destination, is validated by :func:`ave.render.validate.validate_output` and atomically renamed
   only when every check passes; otherwise it is deleted. Partial output is never published.
"""

from __future__ import annotations

import shutil
import time
import uuid
from fractions import Fraction
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict

from ave.errors import AveError, MediaToolError
from ave.paths import render_work_root
from ave.proc import ffmpeg_version, media_url, run_tool
from ave.render.compiler import AudioClipPlan, RenderPlan, SegmentPlan, VideoLayerPlan
from ave.render.validate import ExpectedOutput, ValidationResult, validate_output

__all__ = [
    "CommandRecord",
    "RenderReport",
    "build_audio_command",
    "build_mux_command",
    "build_segment_command",
    "expected_output",
    "render",
    "video_timescale",
]

_BASE_ARGS = ["-hide_banner", "-nostdin", "-v", "error", "-y"]


class _Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")


class CommandRecord(_Frozen):
    """One executed (or failed) FFmpeg command with its filter script and wall time."""

    stage: str
    argv: tuple[str, ...]
    filter_script: str | None = None
    seconds: float


class RenderReport(_Frozen):
    """Outcome of one render: plan, commands, timings, encoder settings and validation."""

    status: Literal["succeeded", "failed"]
    output_path: str | None
    """Published file (``None`` when the render failed and nothing was published)."""
    plan: RenderPlan
    commands: tuple[CommandRecord, ...]
    encoder_settings: dict[str, Any]
    ffmpeg_version: str
    validation: ValidationResult | None
    error: dict[str, Any] | None
    seconds: float
    device: str = "cpu"

    @property
    def succeeded(self) -> bool:
        """True when the output was validated and published."""
        return self.status == "succeeded"


# --------------------------------------------------------------------------------------------
# Command construction (pure)
# --------------------------------------------------------------------------------------------


def video_timescale(fps: Fraction) -> int:
    """MP4 video time scale: the rate numerator doubled until it reaches at least 10000.

    Being a multiple of ``fps.numerator`` makes every frame duration an integer number of ticks,
    so ``60/1`` (15360) and ``60000/1001`` (60000) timestamps are exact.
    """
    scale = fps.numerator
    while scale < 10000:
        scale *= 2
    return scale


def _rate(value: Fraction) -> str:
    return f"{value.numerator}/{value.denominator}"


def _decimal(value: Fraction | int) -> str:
    """Exact decimal text for an integer number of seconds (seek points are whole seconds)."""
    number = Fraction(value)
    if number.denominator != 1:
        raise ValueError(f"expected whole seconds, got {number}")
    return str(number.numerator)


def _video_input_args(layer: VideoLayerPlan, fps: Fraction) -> list[str]:
    if layer.kind == "image":
        return [
            "-loop", "1", "-framerate", _rate(fps),
            "-t", str(float(layer.read_duration)), "-i", media_url(layer.input_path),
        ]  # fmt: skip
    if layer.seek is None:  # pragma: no cover - the compiler always sets a seek for video
        raise ValueError("video layer without seek point")
    return [
        "-ss", _decimal(layer.seek), "-t", _decimal(layer.read_duration),
        "-i", media_url(layer.input_path),
    ]  # fmt: skip


def _layer_chain(
    input_index: int, layer: VideoLayerPlan, segment: SegmentPlan, fps: Fraction
) -> str:
    rate = _rate(fps)
    if layer.timestamps is None:
        timing = f"fps=fps={rate}:start_time=0:round=up"
    else:
        ts = layer.timestamps
        timing = (
            f"settb=1/{ts.tick_rate},"
            f"setpts=(PTS/{ts.pts_divisor})*{ts.multiplier}+({ts.offset}),"
            f"fps=fps={rate}:start_time=0:round=up"
        )
    return (
        f"[{input_index}:{layer.stream_index}]{timing},trim=end_frame={segment.frame_count},"
        f"scale={layer.scaled_width}:{layer.scaled_height}:flags=bicubic:out_range=tv,setsar=1,"
        f"crop={layer.crop_width}:{layer.crop_height}:{layer.crop_x}:{layer.crop_y},"
        f"format=yuv420p[l{input_index}]"
    )


def build_segment_command(
    plan: RenderPlan, segment: SegmentPlan, output: Path, script: Path
) -> tuple[list[str], str]:
    """Arguments and filter script that render ``segment`` into ``output`` (MP4, video only)."""
    fps = plan.fps
    color = "0x" + plan.background.lstrip("#")
    lines = [
        f"color=c={color}:s={plan.canvas.width}x{plan.canvas.height}:r={_rate(fps)},"
        f"trim=end_frame={segment.frame_count},format=yuv420p[bg]"
    ]
    args = [*_BASE_ARGS, "-copyts"]
    for index, layer in enumerate(segment.layers):
        args += _video_input_args(layer, fps)
        lines.append(_layer_chain(index, layer, segment, fps))
    current = "bg"
    for index, layer in enumerate(segment.layers):
        target = "vout" if index == len(segment.layers) - 1 else f"o{index}"
        lines.append(
            f"[{current}][l{index}]overlay=x={layer.x}:y={layer.y}:eof_action=endall:"
            f"repeatlast=0:format=yuv420[{target}]"
        )
        current = target
    if not segment.layers:
        lines[0] = lines[0].replace("[bg]", "[vout]")
    profile = plan.profile
    gop = max(1, round(profile.gop_seconds * fps))
    rate_control = (
        ["-crf", str(profile.crf)]
        if profile.rate_control == "crf"
        else ["-b:v", f"{profile.video_bitrate_kbps}k"]
    )
    args += [
        "-filter_complex_script", str(script.resolve()),
        "-map", "[vout]", "-an", "-frames:v", str(segment.frame_count), "-fps_mode", "passthrough",
        "-c:v", profile.video_encoder, "-preset", profile.preset, *rate_control,
        "-profile:v", profile.h264_profile, "-pix_fmt", profile.pix_fmt,
        "-g", str(gop), "-flags", "+cgop",
        "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
        "-color_range", "tv",
        "-video_track_timescale", str(video_timescale(fps)),
        "-f", "mp4", media_url(output),
    ]  # fmt: skip
    return args, ";\n".join(lines) + "\n"


def _channel_map(channels: int) -> str:
    if channels == 1:
        return "pan=stereo|c0=c0|c1=c0"
    if channels == 2:
        return "pan=stereo|c0=c0|c1=c1"
    return "aformat=channel_layouts=stereo"


def _audio_chain(index: int, clip: AudioClipPlan, plan: RenderPlan) -> str:
    start = clip.source_start_sample
    end = start + clip.source_sample_count
    stretch = "" if clip.speed == 1 else f"rubberband=tempo={float(clip.speed)!r}:pitch=1,"
    return (
        f"[{index}:{clip.stream_index}]aresample={plan.sample_rate}:resampler=soxr,"
        f"{_channel_map(clip.channels)},"
        f"atrim=start_sample={start}:end_sample={end},asetpts=PTS-STARTPTS,{stretch}"
        f"apad=whole_len={clip.output_samples},atrim=end_sample={clip.output_samples},"
        f"volume={clip.gain_db!r}dB,adelay=delays={clip.output_offset}S:all=1,"
        f"apad=whole_len={plan.sample_count},atrim=end_sample={plan.sample_count}[a{index}]"
    )


def build_audio_command(plan: RenderPlan, output: Path, script: Path) -> tuple[list[str], str]:
    """Arguments and filter script that render the range's mixed audio as float WAV."""
    args = list(_BASE_ARGS)
    lines = []
    for index, clip in enumerate(plan.audio):
        args += [
            "-ss", _decimal(clip.seek), "-t", _decimal(clip.read_duration),
            "-i", media_url(clip.input_path),
        ]  # fmt: skip
        lines.append(_audio_chain(index, clip, plan))
    output_format = (
        f"aformat=sample_fmts=flt:channel_layouts=stereo:sample_rates={plan.sample_rate}"
    )
    if plan.audio:
        inputs = "".join(f"[a{i}]" for i in range(len(plan.audio)))
        lines.append(
            f"{inputs}amix=inputs={len(plan.audio)}:duration=longest:normalize=0:"
            f"dropout_transition=0,{output_format}[aout]"
        )
    else:
        lines.append(
            f"anullsrc=r={plan.sample_rate}:cl=stereo,atrim=end_sample={plan.sample_count},"
            f"{output_format}[aout]"
        )
    args += [
        "-filter_complex_script", str(script.resolve()),
        "-map", "[aout]", "-c:a", "pcm_f32le", "-rf64", "auto", "-f", "wav", media_url(output),
    ]  # fmt: skip
    return args, ";\n".join(lines) + "\n"


def build_mux_command(plan: RenderPlan, concat_list: Path, audio: Path, output: Path) -> list[str]:
    """Arguments that concatenate the segments by stream copy and mux them with AAC audio."""
    profile = plan.profile
    return [
        *_BASE_ARGS,
        "-f", "concat", "-safe", "1", "-i", media_url(concat_list),
        "-i", media_url(audio),
        "-map", "0:v:0", "-map", "1:a:0",
        "-c:v", "copy",
        "-c:a", profile.audio_encoder, "-b:a", f"{profile.audio_bitrate_kbps}k",
        "-ar", str(profile.sample_rate), "-ac", str(profile.channels),
        "-video_track_timescale", str(video_timescale(plan.fps)),
        "-movflags", "+faststart",
        "-f", "mp4", media_url(output),
    ]  # fmt: skip


def expected_output(plan: RenderPlan) -> ExpectedOutput:
    """What validation requires of the rendered file."""
    return ExpectedOutput(
        width=plan.canvas.width,
        height=plan.canvas.height,
        fps=plan.fps,
        frame_count=plan.frame_count,
        sample_rate=plan.sample_rate,
        channels=plan.channels,
        sample_count=plan.sample_count,
    )


# --------------------------------------------------------------------------------------------
# Execution
# --------------------------------------------------------------------------------------------


class _Runner:
    """Runs commands and records them for the report."""

    def __init__(self) -> None:
        self.records: list[CommandRecord] = []

    def run(
        self, stage: str, args: list[str], *, timeout: float, script: str | None = None
    ) -> None:
        started = time.monotonic()
        try:
            run_tool("ffmpeg", args, timeout=timeout)
        finally:
            self.records.append(
                CommandRecord(
                    stage=stage,
                    argv=("ffmpeg", *args),
                    filter_script=script,
                    seconds=round(time.monotonic() - started, 3),
                )
            )


def _timeout(seconds: Fraction, scale: float) -> float:
    return 120.0 + scale * float(seconds)


def _write(path: Path, text: str) -> Path:
    path.write_text(text, encoding="utf-8")
    return path


def _render_steps(
    plan: RenderPlan, work: Path, staged: Path, runner: _Runner, scale: float
) -> None:
    segment_files = []
    for segment in plan.segments:
        output = work / f"segment_{segment.index:05d}.mp4"
        script = work / f"segment_{segment.index:05d}.filter"
        args, text = build_segment_command(plan, segment, output, script)
        _write(script, text)
        duration = Fraction(segment.frame_count) / plan.fps
        runner.run(f"segment {segment.index}", args, timeout=_timeout(duration, scale), script=text)
        segment_files.append(output.name)
    audio = work / "audio.wav"
    audio_script = work / "audio.filter"
    args, text = build_audio_command(plan, audio, audio_script)
    _write(audio_script, text)
    runner.run("audio", args, timeout=_timeout(plan.duration, scale / 4), script=text)
    concat_list = _write(
        work / "segments.ffconcat",
        "ffconcat version 1.0\n" + "".join(f"file {name}\n" for name in segment_files),
    )
    runner.run(
        "mux",
        build_mux_command(plan, concat_list, audio, staged),
        timeout=_timeout(plan.duration, scale / 4),
    )


def render(
    plan: RenderPlan,
    output_path: Path | str,
    *,
    work_dir: Path | None = None,
    keep_work_dir: bool = False,
    timeout_scale: float = 30.0,
) -> RenderReport:
    """Renders ``plan`` to ``output_path`` and publishes it only after validation succeeds.

    Intermediates go to a new ``render-<id>`` directory below ``work_dir`` (default
    ``var/render-work``), kept only with ``keep_work_dir``. ``timeout_scale`` bounds each FFmpeg
    step to ``120 s + timeout_scale * media seconds``.
    The returned report has ``status == "failed"`` (and nothing is published) when a command
    fails or validation rejects the output.
    """
    if not plan.segments:
        raise AveError("render plan has no output frames", code="INVALID_TIME_RANGE")
    started = time.monotonic()
    destination = Path(output_path).resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Intermediates live in a fresh directory owned by this render (removed afterwards).
    work = (work_dir or render_work_root()) / f"render-{uuid.uuid4().hex}"
    work.mkdir(parents=True)
    staged = destination.with_name(f".{destination.stem}.partial-{uuid.uuid4().hex}.mp4")
    runner = _Runner()
    validation: ValidationResult | None = None
    error: dict[str, Any] | None = None
    try:
        _render_steps(plan, work, staged, runner, timeout_scale)
        validation = validate_output(staged, expected_output(plan))
        if validation.passed:
            staged.replace(destination)  # atomic rename within one directory
        else:
            error = {
                "code": "RENDER_VALIDATION_FAILED",
                "message": "rendered output failed decoded validation",
                "failures": [c.model_dump() for c in validation.failures],
            }
    except MediaToolError as exc:
        error = exc.to_dict()
    finally:
        staged.unlink(missing_ok=True)
        if not keep_work_dir:
            shutil.rmtree(work, ignore_errors=True)
    return RenderReport(
        status="succeeded" if error is None else "failed",
        output_path=str(destination) if error is None else None,
        plan=plan,
        commands=tuple(runner.records),
        encoder_settings=plan.profile.describe(),
        ffmpeg_version=ffmpeg_version(),
        validation=validation,
        error=error,
        seconds=round(time.monotonic() - started, 3),
    )
