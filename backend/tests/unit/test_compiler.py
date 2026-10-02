"""Render planning: AVE-REQ-012 AC-4, AVE-REQ-021, AVE-REQ-031, AVE-REQ-072, AVE-REQ-075."""

from __future__ import annotations

import bisect
import math
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path

import pytest

from ave.domain.model import Canvas, Clip, Sequence, SyncMember, Track
from ave.errors import RenderPlanningError, SourceBoundsError
from ave.media.asset import MediaAsset
from ave.media.probe import parse_probe_json
from ave.render.compiler import compile_render_plan
from ave.render.ffmpeg import build_audio_command, build_segment_command, video_timescale
from ave.render.profile import OutputProfile
from ave.timebase import Interval
from tests.assets import fake_asset
from tests.compositions import standard_sequence, sync_group

B_TRUE = SyncMember(asset_id="B", a=Fraction(2), method="ground-truth", confidence=1.0)


def _assets() -> dict[str, MediaAsset]:
    return {
        "A": fake_asset("A", duration=Fraction(30)),
        "B": fake_asset("B", duration=Fraction(25), audio=(44100, 1)),
        "C": fake_asset("C", width=1920, height=1080, duration=Fraction(6)),
    }


def _single_clip_sequence(
    asset: MediaAsset,
    *,
    source_in: Fraction,
    source_out: Fraction,
    speed: Fraction,
    fps: Fraction,
    editorial_speed: Fraction = Fraction(1),
) -> Sequence:
    clip = Clip(
        id="clip",
        track_id="v",
        asset_id=asset.id,
        kind="video",
        timeline_start=Fraction(0),
        source_in=source_in,
        source_out=source_out,
        source_speed=speed,
        editorial_speed=editorial_speed,
    )
    return Sequence(
        id="s",
        fps=fps,
        canvas=Canvas(width=640, height=360),
        tracks=(Track(id="v", kind="video", index=0),),
        clips=(clip,),
    )


def test_standard_composition_plans_three_segments_on_the_frame_grid() -> None:
    """AVE-REQ-021 AC-1/AC-3: split/full/split cut exactly at frames 480 and 840 of 1320."""
    plan = compile_render_plan(standard_sequence(sync_group(B_TRUE)), _assets())
    assert plan.frame_count == 1320
    assert plan.sample_count == 22 * 48000
    assert [(s.first_frame, s.frame_count) for s in plan.segments] == [
        (0, 480),
        (480, 360),
        (840, 480),
    ]
    assert [[layer.clip_id for layer in s.layers] for s in plan.segments] == [
        ["split-1.left.video", "split-1.right.video"],
        ["full-c.video"],
        ["split-2.left.video", "split-2.right.video"],
    ]
    left, right = plan.segments[0].layers
    assert (left.x, left.y, left.scaled_width, left.scaled_height) == (0, 60, 960, 960)
    assert (right.x, right.y) == (960, 60)
    assert (left.first_source_time, right.first_source_time) == (2, 0)
    assert plan.segments[2].layers[1].first_source_time == 10
    assert plan.duration == 22


def test_audio_routing_follows_segments_and_skips_muted_sources() -> None:
    """AVE-REQ-031 AC-1/AC-3 / AVE-REQ-021 AC-2: A, then C, then A; B never enters the mix."""
    plan = compile_render_plan(standard_sequence(sync_group(B_TRUE)), _assets())
    routed = [(a.clip_id, a.asset_id, a.output_offset, a.output_samples) for a in plan.audio]
    assert routed == [
        ("split-1.left.audio", "A", 0, 384_000),
        ("full-c.audio", "C", 384_000, 288_000),
        ("split-2.left.audio", "A", 672_000, 384_000),
    ]
    first = plan.audio[0]
    assert (first.seek, first.source_start_sample) == (1, 48_000)  # source 2 s, decoded from 1 s
    assert sum(a.output_samples for a in plan.audio) == plan.sample_count


def test_unavailable_reference_audio_is_reported_not_substituted() -> None:
    """AVE-REQ-031 AC-4 / AC-2: a missing audio stream is a visible planning error."""
    assets = _assets() | {"A": fake_asset("A", duration=Fraction(30), audio=None)}
    with pytest.raises(RenderPlanningError) as error:
        compile_render_plan(standard_sequence(sync_group(B_TRUE)), assets)
    assert error.value.code == "MISSING_STREAM"
    assert "no substitute" in error.value.message
    # A silent secondary video is fine when its audio is not routed: no synthetic stream is added.
    silent_b = _assets() | {"B": fake_asset("B", duration=Fraction(25), audio=None)}
    sequence = standard_sequence(sync_group(B_TRUE))
    sequence = sequence.model_copy(
        update={"clips": tuple(c for c in sequence.clips if not c.id.endswith("right.audio"))}
    )
    plan = compile_render_plan(sequence, silent_b)
    assert {a.asset_id for a in plan.audio} == {"A", "C"}


def test_planning_errors_are_structured() -> None:
    """Missing assets, out-of-bounds sources, odd canvases and empty ranges fail clearly."""
    sequence = standard_sequence(sync_group(B_TRUE))
    with pytest.raises(RenderPlanningError) as missing:
        compile_render_plan(sequence, {k: v for k, v in _assets().items() if k != "C"})
    assert missing.value.code == "MISSING_ASSET"
    short_c = _assets() | {"C": fake_asset("C", width=1920, height=1080, duration=Fraction(5))}
    with pytest.raises(SourceBoundsError):
        compile_render_plan(sequence, short_c)
    odd = sequence.model_copy(update={"canvas": Canvas(width=1919, height=1080)})
    with pytest.raises(RenderPlanningError) as canvas:
        compile_render_plan(odd, _assets())
    assert canvas.value.code == "UNSUPPORTED_CAPABILITY"
    empty = Sequence(id="e", fps=Fraction(60))
    with pytest.raises(RenderPlanningError):
        compile_render_plan(empty, {})


def _simulate_ffmpeg_selection(
    pts: list[int],
    k_divisor: int,
    multiplier: int,
    offset: int,
    tick_rate: int,
    fps: Fraction,
    count: int,
) -> list[int]:
    """Frame index shown on each output frame by settb -> setpts -> fps(round=up, start 0)."""
    positions = []
    for p in pts:
        value = (p * k_divisor // k_divisor) * multiplier + offset  # settb is exact, setpts integer
        positions.append(math.ceil(Fraction(value * fps.numerator, tick_rate * fps.denominator)))
    # PTS are in presentation order, so positions are non-decreasing.
    return [bisect.bisect_right(positions, k) - 1 for k in range(count)]


def _rule(pts: list[int], time_base: Fraction, origin: Fraction, clip: Clip, start: Fraction,
          fps: Fraction, count: int) -> list[int]:  # fmt: skip
    """Specification rule (ADR-004): latest frame with source time <= t_k, where
    t_k = source_in + (T_k - timeline_start) * source_speed * editorial_speed."""
    times = [p * time_base - origin for p in pts]
    speed = clip.source_speed * clip.editorial_speed
    shown = []
    for k in range(count):
        t = clip.source_in + (start + Fraction(k) / fps - clip.timeline_start) * speed
        shown.append(bisect.bisect_right(times, t) - 1)
    return shown


@dataclass(frozen=True)
class TimingCase:
    """Source timing, output rate and clip mapping of one frame-rule scenario."""

    name: str
    time_base: Fraction
    pts_steps: tuple[int, ...]
    fps: Fraction = Fraction(60)
    source_in: Fraction = Fraction(0)
    speed: Fraction = Fraction(1)
    """Drift correction (``source_speed``)."""
    editorial: Fraction = Fraction(1)
    """Editorial speed change (``editorial_speed``)."""
    origin: Fraction = Fraction(0)
    """Exact start of the video stream (the container start); FFprobe prints it rounded."""
    range_start: Fraction = Fraction(0)


TB60 = Fraction(1, 15360)
NTSC60 = Fraction(60000, 1001)
TIMING_CASES = [
    TimingCase("cfr-tie", TB60, (256,), source_in=Fraction(2)),
    TimingCase("cfr-fraction", TB60, (256,), source_in=Fraction(7, 3)),
    TimingCase("ntsc-output", TB60, (256,), fps=NTSC60, source_in=Fraction(5)),
    TimingCase("30-to-60", TB60, (512,), source_in=Fraction(3)),
    TimingCase("drift", TB60, (256,), source_in=Fraction(3), speed=Fraction(1000, 1001)),
    TimingCase("editorial-speed", TB60, (256,), source_in=Fraction(3), editorial=Fraction(3, 2)),
    TimingCase(
        "drift-and-editorial",
        TB60,
        (256,),
        source_in=Fraction(3),
        speed=Fraction(1000, 1001),
        editorial=Fraction(2),
    ),
    TimingCase(
        "origin", Fraction(1, 90000), (1500,), source_in=Fraction(1, 7), origin=Fraction(1, 3)
    ),
    TimingCase("vfr", Fraction(1, 120), (2, 1, 3, 2, 4, 1, 5), source_in=Fraction(1, 3)),
    TimingCase("vfr-ntsc", Fraction(1, 120), (3, 1, 4, 1, 5), fps=NTSC60),
    TimingCase("mid-range", TB60, (256,), source_in=Fraction(2), range_start=Fraction(3, 2)),
]


@pytest.mark.parametrize("case", TIMING_CASES, ids=[c.name for c in TIMING_CASES])
def test_timestamp_map_reproduces_the_frame_rule(case: TimingCase) -> None:
    """AVE-REQ-012 AC-4: output frame k shows the latest source frame with PTS <= t_k.

    The integer coefficients of the plan, evaluated the way FFmpeg evaluates them, select exactly
    the frames the rule selects - for CFR ties, fractional offsets, 60000/1001 output, rate
    conversion, drift correction, editorial speed and both combined, a non-zero container start
    and variable frame rates.
    """
    origin = case.origin  # exact; the probe sees only its six-decimal print and the stream start
    start_pts = origin / case.time_base
    assert start_pts.denominator == 1
    pts: list[int] = []
    tick = int(start_pts)
    while len(pts) < 2000:
        pts.append(tick)
        tick += case.pts_steps[len(pts) % len(case.pts_steps)]
    duration = pts[-1] * case.time_base - origin
    asset = fake_asset(
        "X",
        time_base=case.time_base,
        duration=duration,
        start_time=f"{float(origin):.6f}",
        video_start_pts=int(start_pts),
        audio=None,
    )
    sequence = _single_clip_sequence(
        asset,
        source_in=case.source_in,
        source_out=case.source_in + 4 * case.speed * case.editorial,
        speed=case.speed,
        fps=case.fps,
        editorial_speed=case.editorial,
    )
    window = Interval(start=case.range_start, end=Fraction(4))
    plan = compile_render_plan(sequence, {"X": asset}, project_range=window)
    (segment,) = plan.segments
    (layer,) = segment.layers
    assert layer.timestamps is not None
    ts = layer.timestamps
    assert ts.exact
    count = min(segment.frame_count, 200)
    start = window.start + Fraction(segment.first_frame) / case.fps
    simulated = _simulate_ffmpeg_selection(pts, ts.pts_divisor, ts.multiplier, ts.offset,
                                           ts.tick_rate, case.fps, count)  # fmt: skip
    expected = _rule(pts, case.time_base, origin, sequence.clips[0], start, case.fps, count)
    assert simulated == expected
    if case.name == "cfr-tie":
        assert expected[:3] == [120, 121, 122]  # exact ties pick the frame at exactly t


def test_segment_commands_use_identical_encoder_settings_and_no_shell() -> None:
    """AVE-REQ-072 AC-1/AC-2 / AVE-REQ-075 AC-3: one software profile for every segment."""
    plan = compile_render_plan(standard_sequence(sync_group(B_TRUE)), _assets())
    commands = []
    for segment in plan.segments:
        args, script = build_segment_command(plan, segment, Path("/w/out.mp4"), Path("/w/s.filter"))
        assert "/media/" not in script  # file paths never enter filter graphs
        assert all(isinstance(a, str) for a in args)
        encoder = args[args.index("-c:v") :]
        commands.append(encoder)
        assert args[args.index("-crf") + 1] == "20"
        assert args[args.index("-preset") + 1] == "medium"
        assert "file:/media/A.mp4" in args or "file:/media/C.mp4" in args
    assert commands[0] == commands[2]
    assert video_timescale(Fraction(60)) == 15360
    assert video_timescale(Fraction(60000, 1001)) == 60000
    bitrate = plan.model_copy(
        update={"profile": OutputProfile(rate_control="bitrate", video_bitrate_kbps=12000)}
    )
    args, _ = build_segment_command(bitrate, plan.segments[0], Path("/w/o.mp4"), Path("/w/s"))
    assert args[args.index("-b:v") + 1] == "12000k"
    audio_args, audio_script = build_audio_command(plan, Path("/w/a.wav"), Path("/w/a.filter"))
    assert "normalize=0" in audio_script
    assert "volume=0.0dB" in audio_script
    assert "-i" in audio_args
    with pytest.raises(ValueError, match="video_bitrate_kbps"):
        OutputProfile(rate_control="bitrate")


def test_editorial_speed_retimes_audio_with_pitch_kept_on_top_of_drift() -> None:
    """AVE-REQ-012 AC-4: an audio clip with drift correction 1000/1001 and editorial speed 2
    reads source seconds at 2000/1001 per output second, fills exactly its project duration and
    is time-scaled with pitch preserved (Rubber Band tempo = combined speed, pitch 1)."""
    asset = fake_asset("A", duration=Fraction(30))
    clip = Clip(
        id="snd", track_id="a", asset_id="A", kind="audio", timeline_start=Fraction(1),
        source_in=Fraction(4), source_out=Fraction(12), source_speed=Fraction(1000, 1001),
        editorial_speed=Fraction(2),
    )  # fmt: skip
    sequence = Sequence(
        id="s", fps=Fraction(60), tracks=(Track(id="a", kind="audio", index=0),), clips=(clip,)
    )
    plan = compile_render_plan(sequence, {"A": asset}, project_range=Interval.of(0, 6))
    (audio,) = plan.audio
    speed = Fraction(2000, 1001)
    assert audio.speed == speed
    duration = 8 / speed  # project seconds: (source_out - source_in) / (drift * editorial)
    assert audio.output_offset == 48000
    assert audio.output_samples == math.ceil((1 + duration) * 48000) - 48000
    assert audio.source_sample_count == round(audio.output_samples * speed)
    _, script = build_audio_command(plan, Path("/w/a.wav"), Path("/w/a.filter"))
    assert f"rubberband=tempo={float(speed)!r}:pitch=1" in script


def _image2_asset() -> MediaAsset:
    probe = parse_probe_json(
        {
            "format": {"format_name": "image2", "start_time": "0.000000"},
            "streams": [
                {
                    "index": 0, "codec_type": "video", "codec_name": "png", "width": 640,
                    "height": 360, "time_base": "1/25", "r_frame_rate": "25/1",
                    "avg_frame_rate": "25/1",
                }
            ],
        }
    )  # fmt: skip
    return MediaAsset(id="img", path="/media/photo%d.png", sha256="0" * 64, probe=probe)


def test_inputs_are_opened_literally_and_video_keeps_frames_before_the_seek() -> None:
    """AVE-REQ-072 AC-3, AVE-REQ-012 AC-4: an image2 still is opened with sequence patterns
    disabled (``%d`` in its name is literal); video inputs seek to a keyframe without discarding
    frames before the seek point and are not cut by a read duration; audio is placed by its
    timestamps relative to the exact container start plus the seek point (raw timestamps via
    ``-copyts``, ``first_pts=0``, gaps above the 10 ms jitter tolerance compensated)."""
    still = Clip(
        id="still", track_id="v", asset_id="img", kind="image", timeline_start=Fraction(0),
        source_in=Fraction(0), source_out=Fraction(1),
    )  # fmt: skip
    sequence = Sequence(
        id="s", fps=Fraction(30), canvas=Canvas(width=640, height=360),
        tracks=(Track(id="v", kind="video", index=0),), clips=(still,),
    )  # fmt: skip
    plan = compile_render_plan(sequence, {"img": _image2_asset()})
    (layer,) = plan.segments[0].layers
    assert layer.input_format == "image2"
    args, _ = build_segment_command(plan, plan.segments[0], Path("/w/o.mp4"), Path("/w/s"))
    position = args.index("file:/media/photo%d.png")
    assert args[position - 5 : position] == ["-f", "image2", "-pattern_type", "none", "-i"]

    video_plan = compile_render_plan(standard_sequence(sync_group(B_TRUE)), _assets())
    first = video_plan.segments[0]
    args, _ = build_segment_command(video_plan, first, Path("/w/o.mp4"), Path("/w/s"))
    position = args.index("file:/media/A.mp4")
    assert args[position - 4 : position] == ["-noaccurate_seek", "-ss", "1", "-i"]
    assert "-t" not in args
    assert all(layer.input_format is None for layer in first.layers)
    audio_args, audio_script = build_audio_command(
        video_plan, Path("/w/a.wav"), Path("/w/a.filter")
    )
    assert audio_args.index("-copyts") < audio_args.index("-i")
    # Seek points from the specification table: A[2,10) -> 1, C[0,6) -> 0, A[12,20) -> 11; the
    # fake assets start at container time 0.
    placement = (
        "asetpts=PTS-round(({seek}/1)/TB),"
        "aresample=48000:resampler=soxr:min_comp=0:min_hard_comp=0.01:first_pts=0,"
    )
    chains = audio_script.splitlines()[: len(video_plan.audio)]
    for chain, seek in zip(chains, (1, 0, 11), strict=True):
        assert chain.split("]", 1)[1].startswith(placement.format(seek=seek))
