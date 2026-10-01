"""Compiles a sequence and a project range into a :class:`RenderPlan` (ADR-005, AVE-REQ-072/075).

The compiler is pure: it reads the composition, asset probe data and an output profile and decides
every timing and geometry value; :mod:`ave.render.ffmpeg` only executes the plan.

Video timing rule
-----------------
The range ``[R0, R1)`` is presented on output frames ``n = 0 .. ceil((R1 - R0) * fps) - 1``; frame
``n`` presents project time ``T_n = R0 + n / fps``. For each active clip, frame ``n`` shows the
**latest source frame whose presentation timestamp is ``<= t_n``**, where
``t_n = source_in + (T_n - timeline_start) * source_speed * editorial_speed`` (:attr:`Clip.speed`)
and a frame's source time is ``pts * time_base - container_start_time``. The rule holds for
constant- and variable-frame-rate sources alike because it is evaluated on actual PTS, never on
``frame_number / average_rate``.

Before a source's first video frame (``t_n`` earlier than the first frame's PTS, for example when
the video stream starts after the container start) no frame satisfies ``PTS <= t_n``; such output
frames show the source's **first frame** (clamped), so a clip never flashes the background at the
source's start.

Decoding starts at a keyframe at or before the seek point ``S0 = max(0, floor(t_first - 1 s))``
(FFmpeg ``-noaccurate_seek``: the demuxer seeks to a keyframe whose timestamp is ``<= S0`` and
every frame from there is decoded and passed to the timestamp mapping). The latest frame with
``PTS <= t`` is therefore always among the decoded frames, however long a variable-frame-rate gap
before ``t`` is; the one-second margin only absorbs decode-order versus presentation-order
(B-frame) differences of the seek. Decoding stops when the segment's last output frame is complete.

Exact evaluation in FFmpeg: a source frame with PTS ``p`` becomes due at segment-relative output
time ``y(p) = p * (time_base / speed) + c`` (all rational). The plan chooses an integer tick rate
``M`` (a multiple of every denominator involved) and integers ``K, G, C`` so that
``settb=1/M`` rescales PTS exactly, ``setpts=(PTS/K)*G+C`` yields ``y(p) * M`` as an exact integer
(every intermediate stays below 2**53), and ``fps=...:round=up:start_time=0`` then shows on output
frame ``k`` the latest source frame with ``ceil(y(p) * fps) <= k``, which is exactly
``pts <= t_k``. When ``M`` would exceed FFmpeg's 32-bit time-base limit the constant offset is
rounded to the nearest ``1/M`` tick and the plan records a warning.

Segments
--------
The range is split at every visible clip boundary into intervals with a constant layer set; each
segment covers the whole output frames whose presentation time lies inside it, so cuts are
quantized to the output grid exactly once. Segments with no frame are dropped.

Audio
-----
Audio is planned once for the whole range at 48 kHz: output sample ``k`` presents ``R0 + k/48000``.
Each audible clip contributes the samples ``k`` whose time lies in its project interval, read from
source time ``t_k`` (rounded to the nearest 48 kHz sample after resampling, an error of at most
10.4 microseconds), time-scaled with pitch preservation when the clip's speed (drift correction
times editorial speed) is not 1, gained and delayed to its exact sample position; clips are summed
without normalization.

Audio sample positions follow presentation timestamps: the decoded samples are placed by their
timestamps relative to the seek point ``S0`` (source time, i.e. relative to the container start),
not by counting samples from the first one delivered. A stream that starts after ``S0`` (its own
start later than the container start) is preceded by silence up to its first timestamp, to the
input sample.
"""

from __future__ import annotations

import itertools
import math
from collections.abc import Mapping
from fractions import Fraction
from typing import Literal

from pydantic import BaseModel, ConfigDict

from ave.domain.layout import compute_layer_geometry
from ave.domain.model import Canvas, Clip, Sequence
from ave.errors import RenderPlanningError, SourceBoundsError
from ave.media.asset import MediaAsset
from ave.media.probe import AudioStreamInfo, VideoStreamInfo
from ave.render.profile import DEFAULT_PROFILE, OutputProfile
from ave.timebase import (
    Interval,
    NonNegativeRational,
    PositiveRational,
    Rational,
    frame_count,
    frame_start,
    frames_in,
    round_half_up,
    sample_count,
    samples_in,
)

__all__ = [
    "AudioClipPlan",
    "RenderPlan",
    "SegmentPlan",
    "TimestampMap",
    "VideoLayerPlan",
    "compile_render_plan",
]

SEEK_MARGIN_S = 1
"""Seconds between the seek point and the first needed source instant (covers B-frame reordering at
the seek and resampler warm-up; variable-frame-rate gaps need no margin, see the module doc)."""
READ_MARGIN_S = 2
"""Seconds of audio read after the last needed source instant; also the timestamp headroom checked
for exact evaluation of video PTS beyond the last needed instant."""
MAX_TICK_RATE = 2**31 - 1
"""FFmpeg time bases are 32-bit rationals."""
_MAX_EXACT = 2**53
"""FFmpeg evaluates setpts expressions in IEEE doubles: integers stay exact below 2**53."""


class _Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")


class TimestampMap(_Frozen):
    """Integer form ``y(p) * M = (p * K / K) * G + C`` evaluated inside FFmpeg (module doc)."""

    tick_rate: int
    """``M``: ticks per second of the intermediate time base ``1/M``."""
    pts_divisor: int
    """``K = time_base * M``: PTS after ``settb=1/M`` equal ``p * K``."""
    multiplier: int
    """``G = time_base / speed * M``."""
    offset: int
    """``C = c * M`` (``c`` = due time of PTS 0 relative to the segment start)."""
    exact: bool
    """False when ``C`` had to be rounded to fit ``M`` into FFmpeg's 32-bit time base."""


class VideoLayerPlan(_Frozen):
    """One clip's contribution to one segment."""

    clip_id: str
    asset_id: str
    kind: Literal["video", "image"]
    input_path: str
    stream_index: int
    z: int
    input_format: Literal["image2"] | None = None
    """``image2`` when the asset was probed through FFmpeg's image2 demuxer: the renderer then
    forces that demuxer with sequence patterns disabled, so the file is read as itself."""
    seek: NonNegativeRational | None
    """Input seek point ``S0`` in source seconds (``None`` for still images)."""
    read_duration: PositiveRational | None
    """Seconds of a still image's looped input; ``None`` for video, which is decoded from the
    keyframe at or before ``S0`` until the segment's frames are complete."""
    timestamps: TimestampMap | None
    first_source_time: Rational
    """``t`` shown on the segment's first frame."""
    last_source_time: Rational
    """``t`` shown on the segment's last frame."""
    scaled_width: int
    scaled_height: int
    crop_x: int
    crop_y: int
    crop_width: int
    crop_height: int
    x: int
    y: int


class SegmentPlan(_Frozen):
    """A run of output frames with a constant layer set."""

    index: int
    first_frame: int
    """Index of the segment's first output frame in the export."""
    frame_count: int
    project_interval: Interval
    """Project-time interval between the segment's boundaries."""
    layers: tuple[VideoLayerPlan, ...]
    """Layers bottom to top."""


class AudioClipPlan(_Frozen):
    """One audible clip's contribution to the export's audio."""

    clip_id: str
    asset_id: str
    input_path: str
    stream_index: int
    channels: int
    seek: int
    """Input seek point ``S0`` (whole seconds of source time)."""
    read_duration: int
    """Whole seconds of input read from ``S0``."""
    source_start_sample: int
    """First source sample (at the output rate, relative to ``S0``)."""
    source_sample_count: int
    """Source samples read (at the output rate) before time scaling."""
    speed: PositiveRational
    """Source seconds per output second (``Clip.speed``); audio is time-scaled with pitch kept."""
    gain_db: float
    output_offset: int
    """First output sample index of the clip."""
    output_samples: int
    """Exact number of output samples contributed."""


class RenderPlan(_Frozen):
    """Everything needed to render one project range of one sequence."""

    sequence_id: str
    project_range: Interval
    fps: PositiveRational
    canvas: Canvas
    background: str
    sample_rate: int
    channels: int
    frame_count: int
    sample_count: int
    segments: tuple[SegmentPlan, ...]
    audio: tuple[AudioClipPlan, ...]
    profile: OutputProfile
    warnings: tuple[str, ...] = ()

    @property
    def duration(self) -> Fraction:
        """Exact video duration of the export: ``frame_count / fps``."""
        return frame_start(self.frame_count, self.fps)


# --------------------------------------------------------------------------------------------
# Compilation
# --------------------------------------------------------------------------------------------


def compile_render_plan(
    sequence: Sequence,
    assets: Mapping[str, MediaAsset],
    *,
    profile: OutputProfile = DEFAULT_PROFILE,
    project_range: Interval | None = None,
) -> RenderPlan:
    """Plans the export of ``project_range`` (default: the whole sequence)."""
    profile.check_canvas(sequence.canvas)
    if project_range is None:
        if sequence.end <= 0:
            raise RenderPlanningError("the sequence is empty", code="INVALID_TIME_RANGE")
        project_range = Interval(start=Fraction(0), end=sequence.end)
    if profile.sample_rate != sequence.sample_rate:
        raise RenderPlanningError(
            f"profile sample rate {profile.sample_rate} differs from the sequence rate "
            f"{sequence.sample_rate}",
            code="UNSUPPORTED_CAPABILITY",
        )
    warnings: list[str] = []
    segments = _plan_segments(sequence, assets, project_range, warnings)
    audio = _plan_audio(sequence, assets, project_range)
    return RenderPlan(
        sequence_id=sequence.id,
        project_range=project_range,
        fps=sequence.fps,
        canvas=sequence.canvas,
        background=sequence.background,
        sample_rate=profile.sample_rate,
        channels=profile.channels,
        frame_count=frame_count(project_range.duration, sequence.fps),
        sample_count=sample_count(project_range.duration, profile.sample_rate),
        segments=segments,
        audio=audio,
        profile=profile,
        warnings=tuple(warnings),
    )


def _asset_for(clip: Clip, assets: Mapping[str, MediaAsset]) -> MediaAsset:
    asset = assets.get(clip.asset_id)
    if asset is None:
        raise RenderPlanningError(
            f"clip {clip.id} references missing asset {clip.asset_id}",
            code="MISSING_ASSET",
            clip_id=clip.id,
            asset_id=clip.asset_id,
        )
    return asset


def _check_source_bounds(clip: Clip, asset: MediaAsset, end: Fraction | None) -> None:
    if end is not None and clip.source_out > end:
        raise SourceBoundsError(
            f"clip {clip.id} reads source [{clip.source_in}, {clip.source_out}) but the stream "
            f"ends at {end}",
            clip_id=clip.id,
            asset_id=asset.id,
        )


def _video_stream(clip: Clip, asset: MediaAsset) -> VideoStreamInfo:
    stream = asset.video_stream(clip.stream_index)
    if stream is None:
        raise RenderPlanningError(
            f"clip {clip.id}: asset {asset.id} has no video stream"
            + (f" with index {clip.stream_index}" if clip.stream_index is not None else ""),
            code="MISSING_STREAM",
            clip_id=clip.id,
            asset_id=asset.id,
        )
    if clip.kind == "video":
        if stream.time_base is None:
            raise RenderPlanningError(
                f"clip {clip.id}: video stream has no time base", code="UNSUPPORTED_CAPABILITY"
            )
        _check_source_bounds(clip, asset, asset.probe.source_duration(stream))
    return stream


def _audio_stream(clip: Clip, asset: MediaAsset) -> AudioStreamInfo:
    stream = asset.audio_stream(clip.stream_index)
    if stream is None or not stream.sample_rate or not stream.channels:
        raise RenderPlanningError(
            f"clip {clip.id}: the selected audio of asset {asset.id} is unavailable; choose another"
            " audio source or disable the clip explicitly (no substitute is chosen silently)",
            code="MISSING_STREAM",
            clip_id=clip.id,
            asset_id=asset.id,
        )
    _check_source_bounds(clip, asset, asset.probe.source_duration(stream))
    return stream


def _visible_clips(sequence: Sequence, project_range: Interval) -> list[tuple[Clip, int]]:
    tracks = {t.id: t for t in sequence.rendered_tracks("video")}
    result = []
    for clip in sequence.clips:
        track = tracks.get(clip.track_id)
        if track is None or not clip.enabled or clip.kind == "audio":
            continue
        if clip.timeline_interval.overlaps(project_range):
            result.append((clip, track.index))
    return result


def _plan_segments(
    sequence: Sequence,
    assets: Mapping[str, MediaAsset],
    project_range: Interval,
    warnings: list[str],
) -> tuple[SegmentPlan, ...]:
    clips = _visible_clips(sequence, project_range)
    streams = {clip.id: _video_stream(clip, _asset_for(clip, assets)) for clip, _ in clips}
    boundaries = {project_range.start, project_range.end}
    for clip, _ in clips:
        for edge in (clip.timeline_start, clip.timeline_end):
            if project_range.start < edge < project_range.end:
                boundaries.add(edge)
    ordered = sorted(boundaries)
    segments: list[SegmentPlan] = []
    for start, end in itertools.pairwise(ordered):
        interval = Interval(start=start, end=end)
        frames = frames_in(interval.shift(-project_range.start), sequence.fps)
        if not frames:
            continue
        active = sorted(
            (
                (z, clip)
                for clip, z in clips
                if clip.timeline_start <= start and end <= clip.timeline_end
            ),
            key=lambda item: item[0],
        )
        layers = tuple(
            _plan_layer(
                sequence,
                clip,
                _asset_for(clip, assets),
                streams[clip.id],
                z,
                project_range.start,
                frames,
                warnings,
            )
            for z, clip in active
        )
        segments.append(
            SegmentPlan(
                index=len(segments),
                first_frame=frames.start,
                frame_count=len(frames),
                project_interval=interval,
                layers=layers,
            )
        )
    return tuple(segments)


def _plan_layer(
    sequence: Sequence,
    clip: Clip,
    asset: MediaAsset,
    stream: VideoStreamInfo,
    z: int,
    range_start: Fraction,
    frames: range,
    warnings: list[str],
) -> VideoLayerPlan:
    fps = sequence.fps
    segment_start = range_start + frame_start(frames.start, fps)
    last_time = range_start + frame_start(frames.stop - 1, fps)
    t_first = clip.source_in + (segment_start - clip.timeline_start) * clip.speed
    t_last = clip.source_in + (last_time - clip.timeline_start) * clip.speed
    geometry = compute_layer_geometry(
        sequence.canvas,
        clip.region,
        Fraction(stream.display_width),
        Fraction(stream.display_height),
        clip.fit,
        clip.focus_x,
        clip.focus_y,
    )
    read_duration: Fraction | None = None
    if clip.kind == "image":
        seek: Fraction | None = None
        read_duration = frame_start(len(frames), fps) + 1
        timestamps = None
    else:
        seek = Fraction(max(0, math.floor(t_first - SEEK_MARGIN_S)))
        timestamps = _timestamp_map(clip, asset, stream, segment_start, fps, t_last, warnings)
    return VideoLayerPlan(
        clip_id=clip.id,
        asset_id=asset.id,
        kind=clip.kind if clip.kind == "image" else "video",
        input_path=asset.path,
        input_format="image2" if asset.probe.format_name == "image2" else None,
        stream_index=stream.index,
        z=z,
        seek=seek,
        read_duration=read_duration,
        timestamps=timestamps,
        first_source_time=t_first,
        last_source_time=t_last,
        scaled_width=geometry.scaled_width,
        scaled_height=geometry.scaled_height,
        crop_x=geometry.crop.x,
        crop_y=geometry.crop.y,
        crop_width=geometry.crop.width,
        crop_height=geometry.crop.height,
        x=geometry.position[0],
        y=geometry.position[1],
    )


def _timestamp_map(
    clip: Clip,
    asset: MediaAsset,
    stream: VideoStreamInfo,
    segment_start: Fraction,
    fps: Fraction,
    t_last: Fraction,
    warnings: list[str],
) -> TimestampMap:
    """Integer coefficients for exact PTS-to-output-frame mapping inside FFmpeg."""
    time_base = stream.time_base
    if time_base is None:  # pragma: no cover - checked by _video_stream
        raise RenderPlanningError("video stream has no time base", code="UNSUPPORTED_CAPABILITY")
    origin = asset.probe.container_start_time
    alpha = time_base / clip.speed
    constant = clip.timeline_start - segment_start - (origin + clip.source_in) / clip.speed
    base = math.lcm(time_base.denominator, alpha.denominator)
    if base > MAX_TICK_RATE:
        raise RenderPlanningError(
            f"clip {clip.id}: time base {time_base} with speed {clip.speed} needs a tick "
            "rate beyond FFmpeg's 32-bit limit",
            code="UNSUPPORTED_CAPABILITY",
            clip_id=clip.id,
        )
    tick_rate = math.lcm(base, constant.denominator)
    exact = tick_rate <= MAX_TICK_RATE
    if not exact:
        tick_rate = base * (MAX_TICK_RATE // base)
        warnings.append(
            f"clip {clip.id}: timing offset rounded to 1/{tick_rate} s to fit FFmpeg's time base"
        )
    pts_divisor = time_base * tick_rate
    multiplier = alpha * tick_rate
    offset = round_half_up(constant * tick_rate)
    if pts_divisor.denominator != 1 or multiplier.denominator != 1:  # pragma: no cover
        raise RenderPlanningError("internal error: non-integer timestamp coefficients")
    largest_pts = (t_last + origin + READ_MARGIN_S + 1) / time_base
    if (
        abs(largest_pts * pts_divisor) >= _MAX_EXACT
        or abs(largest_pts * multiplier.numerator) + abs(offset) >= _MAX_EXACT
    ):
        raise RenderPlanningError(
            f"clip {clip.id}: source timestamps too large for exact evaluation",
            code="UNSUPPORTED_CAPABILITY",
            clip_id=clip.id,
        )
    return TimestampMap(
        tick_rate=tick_rate,
        pts_divisor=pts_divisor.numerator,
        multiplier=multiplier.numerator,
        offset=offset,
        exact=exact,
    )


def _plan_audio(
    sequence: Sequence, assets: Mapping[str, MediaAsset], project_range: Interval
) -> tuple[AudioClipPlan, ...]:
    rate = sequence.sample_rate
    audible = {t.id for t in sequence.rendered_tracks("audio")}
    plans: list[AudioClipPlan] = []
    for clip in sequence.clips:
        if clip.kind != "audio" or not clip.enabled or clip.track_id not in audible:
            continue
        window = clip.timeline_interval.intersection(project_range)
        if window is None:
            continue
        samples = samples_in(window.shift(-project_range.start), rate)
        if not samples:
            continue
        asset = _asset_for(clip, assets)
        stream = _audio_stream(clip, asset)
        first_time = project_range.start + Fraction(samples.start, rate)
        end_time = project_range.start + Fraction(samples.stop, rate)
        t_start = clip.source_in + (first_time - clip.timeline_start) * clip.speed
        t_end = clip.source_in + (end_time - clip.timeline_start) * clip.speed
        seek = max(0, math.floor(t_start - SEEK_MARGIN_S))
        source_start = round_half_up((t_start - seek) * rate)
        source_count = round_half_up((t_end - t_start) * rate)
        plans.append(
            AudioClipPlan(
                clip_id=clip.id,
                asset_id=asset.id,
                input_path=asset.path,
                stream_index=stream.index,
                channels=stream.channels or 1,
                seek=seek,
                read_duration=math.ceil(t_end - seek) + READ_MARGIN_S,
                source_start_sample=source_start,
                source_sample_count=max(source_count, 1),
                speed=clip.speed,
                gain_db=clip.gain_db,
                output_offset=samples.start,
                output_samples=len(samples),
            )
        )
    return tuple(plans)
