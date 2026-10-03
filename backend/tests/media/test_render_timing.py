"""Render timing, rate conversion, VFR, speed, stills, canvases and atomic publish.

AVE-REQ-012 AC-3/AC-4, AVE-REQ-018 AC-1/AC-2, AVE-REQ-072 AC-4, AVE-REQ-075 AC-2/AC-3/AC-4.
Expected frames are computed here from the frame rule and the fixture manifests.
"""

from __future__ import annotations

import bisect
import math
import shutil
import sys
from fractions import Fraction
from pathlib import Path

import numpy as np
import pytest

import ave.render.ffmpeg as render_module
from ave.domain.model import Canvas, Clip, Sequence, Track
from ave.fixtures.barcode import barcode_layout
from ave.fixtures.generate import VFR_TICK_RATE, Fixture
from ave.fixtures.standard import PILOT_HZ, REFERENCE_EVENT_FRAMES, StandardFixtures
from ave.media.asset import MediaAsset, describe_asset
from ave.media.probe import probe
from ave.render.compiler import compile_render_plan
from ave.render.ffmpeg import RenderReport, render
from ave.render.profile import OutputProfile
from ave.render.validate import (
    ExpectedOutput,
    ValidationCheck,
    ValidationResult,
    decode_audio,
    decode_video_frames,
    iter_video_frames,
    validate_output,
)
from tests.oracles import (
    Placement,
    detect_chirps,
    match_events,
    patch_rgb,
    read_barcode,
    tone_amplitude,
)

pytestmark = pytest.mark.media

FAST = OutputProfile(preset="veryfast")
TRACKS = (Track(id="v", kind="video", index=0), Track(id="a", kind="audio", index=0))


def _sequence(
    asset: MediaAsset,
    *,
    canvas: Canvas,
    fps: Fraction,
    source_in: Fraction,
    duration: Fraction,
    speed: Fraction = Fraction(1),
    kind: str = "video",
    with_audio: bool = False,
) -> Sequence:
    common = {
        "asset_id": asset.id,
        "timeline_start": Fraction(0),
        "source_in": source_in,
        "source_out": source_in + duration * speed,
        "editorial_speed": speed,
    }
    clips = [Clip.model_validate({"id": "pic", "track_id": "v", "kind": kind, **common})]
    if with_audio:
        clips.append(Clip.model_validate({"id": "snd", "track_id": "a", "kind": "audio", **common}))
    return Sequence(id="t", fps=fps, canvas=canvas, tracks=TRACKS, clips=tuple(clips))


def _render(sequence: Sequence, asset: MediaAsset, out: Path) -> RenderReport:
    plan = compile_render_plan(sequence, {asset.id: asset}, profile=FAST)
    report = render(plan, out)
    assert report.succeeded, report.error
    return report


def _barcodes(
    path: Path, width: int, height: int, source: tuple[int, int], place: Placement
) -> list[int | None]:
    layout = barcode_layout(*source)
    return [
        read_barcode(f, layout, place, 1)
        for f in iter_video_frames(path, width=width, height=height)
    ]


@pytest.mark.req("AVE-REQ-012 AC-4")
def test_vfr_source_is_mapped_by_presentation_timestamps(
    timing_fixtures: dict[str, Fixture], artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-4: each output frame shows the latest VFR frame with PTS <= t."""
    fixture = timing_fixtures["vfr"]
    asset = describe_asset(fixture.path, asset_id="vfr")
    source_in = Fraction(1, 3)
    sequence = _sequence(asset, canvas=Canvas(width=640, height=360), fps=Fraction(60),
                         source_in=source_in, duration=Fraction(4))  # fmt: skip
    output = artifacts_dir / "vfr-to-60.mp4"
    _render(sequence, asset, output)
    times = [Fraction(t, VFR_TICK_RATE) for t in fixture.manifest["vfr_frame_ticks"]]
    expected = [bisect.bisect_right(times, source_in + Fraction(k, 60)) - 1 for k in range(240)]
    # 320x240 contained in 640x360: scale 3/2 -> 480x360 centered at x = 80.
    observed = _barcodes(output, 640, 360, (320, 240), Placement(scale=1.5, x=80, y=0))
    assert len(observed) == 240
    readable = [(o, e) for o, e in zip(observed, expected, strict=True) if o is not None]
    assert len(readable) >= 238
    assert all(o == e for o, e in readable)
    assert len(set(expected)) < 240  # the VFR source really repeats frames on the 60 fps grid


@pytest.mark.req("AVE-REQ-012 AC-3", "AVE-REQ-012 AC-4", "AVE-REQ-018 AC-2")
@pytest.mark.parametrize(
    "fps", [Fraction(60000, 1001), Fraction(30), Fraction(24)], ids=["60000-1001", "30", "24"]
)
def test_output_rate_conversion_keeps_playback_speed(
    std: StandardFixtures, fps: Fraction, artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-3/AC-4, AVE-REQ-018 AC-2: 60/1 source rendered at another exact rate shows
    source frame floor((5 + k / fps) * 60) on output frame k; 60000/1001 stays distinct."""
    asset = describe_asset(std.a.path, asset_id="A")
    sequence = _sequence(asset, canvas=Canvas(width=640, height=360), fps=fps,
                         source_in=Fraction(5), duration=Fraction(2))  # fmt: skip
    output = artifacts_dir / f"rate-{fps.numerator}-{fps.denominator}.mp4"
    _render(sequence, asset, output)
    (video,) = probe(output).video_streams
    assert video.r_frame_rate == fps
    count = math.ceil(2 * fps)
    assert video.nb_frames == count
    expected = [math.floor((5 + Fraction(k) / fps) * 60) for k in range(count)]
    # 1080x1080 contained in 640x360: scale 1/3 -> 360x360 at x = 140.
    observed = _barcodes(output, 640, 360, (1080, 1080), Placement(scale=1 / 3, x=140, y=0))
    assert observed == expected


@pytest.mark.req("AVE-REQ-012 AC-4", "AVE-REQ-075 AC-2")
def test_speed_change_retimes_video_and_audio_with_pitch_kept(
    std: StandardFixtures, artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-4, AVE-REQ-075 AC-2: an editorial speed of 5/4 (no drift correction) maps
    frames by t = 2 + 1.25 T and moves audio events to (t - 2) / 1.25 with the 1 kHz pilot still
    at 1 kHz (pitch kept)."""
    asset = describe_asset(std.a.path, asset_id="A")
    speed = Fraction(5, 4)
    sequence = _sequence(asset, canvas=Canvas(width=640, height=360), fps=Fraction(60),
                         source_in=Fraction(2), duration=Fraction(4), speed=speed,
                         with_audio=True)  # fmt: skip
    output = artifacts_dir / "speed-5-4.mp4"
    _render(sequence, asset, output)
    expected = [math.floor((2 + Fraction(k, 60) * speed) * 60) for k in range(240)]
    observed = _barcodes(output, 640, 360, (1080, 1080), Placement(scale=1 / 3, x=140, y=0))
    assert observed == expected
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    events = [(f / 60 - 2) / 1.25 for f in REFERENCE_EVENT_FRAMES if 2 <= f / 60 < 7]
    _, missing, unexpected = match_events(detect_chirps(audio, 48000), events, 1 / 60)
    assert not missing
    assert not unexpected
    quiet = audio[int(1.5 * 48000) : int(2.5 * 48000)]
    assert tone_amplitude(quiet, 48000, PILOT_HZ["a"]) > 0.035
    assert tone_amplitude(quiet, 48000, PILOT_HZ["a"] * 1.25) < 0.005


@pytest.mark.req("AVE-REQ-075 AC-2", "AVE-REQ-075 AC-3")
def test_still_image_clip_and_silent_audio(
    timing_fixtures: dict[str, Fixture], artifacts_dir: Path
) -> None:
    """AVE-REQ-075 AC-2/AC-3: stills render on the CPU path without models or providers; a
    timeline without audio clips exports explicit silence."""
    asset = describe_asset(timing_fixtures["still"].path, asset_id="still")
    sequence = _sequence(asset, canvas=Canvas(width=640, height=360), fps=Fraction(30),
                         source_in=Fraction(0), duration=Fraction(1), kind="image")  # fmt: skip
    output = artifacts_dir / "still.mp4"
    _render(sequence, asset, output)
    layout = barcode_layout(640, 360)
    identity = Placement(scale=1.0, x=0, y=0)
    frames = list(iter_video_frames(output, width=640, height=360))
    assert len(frames) == 30
    for frame in frames:
        assert read_barcode(frame, layout, identity, 1) == 0
        assert np.abs(patch_rgb(frame, layout, identity, 1) - (230, 180, 30)).max() < 12
    assert np.abs(decode_audio(output, channels=2)).max() < 1e-4
    forbidden = ("torch", "transformers", "faster_whisper", "anthropic", "openai", "httpx",
                 "requests", "huggingface_hub")  # fmt: skip
    assert not [m for m in sys.modules if m.split(".")[0] in forbidden]


@pytest.mark.req("AVE-REQ-018 AC-1")
@pytest.mark.parametrize(("width", "height"), [(360, 360), (360, 640)], ids=["1x1", "9x16"])
def test_square_and_vertical_canvases(
    std: StandardFixtures, width: int, height: int, artifacts_dir: Path
) -> None:
    """AVE-REQ-018 AC-1: 1:1 and 9:16 canvases render a 16:9 source undistorted and centered."""
    asset = describe_asset(std.c.path, asset_id="C")
    sequence = _sequence(asset, canvas=Canvas(width=width, height=height), fps=Fraction(30),
                         source_in=Fraction(0), duration=Fraction(1, 2))  # fmt: skip
    output = artifacts_dir / f"canvas-{width}x{height}.mp4"
    _render(sequence, asset, output)
    (video,) = probe(output).video_streams
    assert (video.width, video.height) == (width, height)
    frame = next(iter_video_frames(output, width=width, height=height))
    ys, xs = np.nonzero(frame.max(axis=2) > 48)
    box_h = int(ys.max()) + 1 - int(ys.min())
    box_w = int(xs.max()) + 1 - int(xs.min())
    assert box_w == width
    assert abs(box_h - width * 9 / 16) <= 2
    assert abs(int(ys.min()) - (height - width * 9 / 16) / 2) <= 2


def _tiny_plan(timing_fixtures: dict[str, Fixture]) -> tuple[MediaAsset, Sequence]:
    asset = describe_asset(timing_fixtures["still"].path, asset_id="still")
    sequence = _sequence(asset, canvas=Canvas(width=320, height=180), fps=Fraction(30),
                         source_in=Fraction(0), duration=Fraction(1, 2), kind="image")  # fmt: skip
    return asset, sequence


@pytest.mark.req("AVE-REQ-072 AC-4")
def test_failed_validation_never_publishes(
    timing_fixtures: dict[str, Fixture], artifacts_dir: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """AVE-REQ-072 AC-4: an output that fails validation is deleted; an existing file at the
    destination is left untouched and no partial file remains."""
    asset, sequence = _tiny_plan(timing_fixtures)
    target_dir = artifacts_dir / "atomic"
    target_dir.mkdir()
    destination = target_dir / "export.mp4"
    destination.write_bytes(b"previous export")

    def failing(_path: Path, _expected: ExpectedOutput) -> ValidationResult:
        check = ValidationCheck(name="forced", passed=False, expected="pass", actual="fail")
        return ValidationResult(passed=False, checks=(check,))

    monkeypatch.setattr(render_module, "validate_output", failing)
    report = render(compile_render_plan(sequence, {asset.id: asset}, profile=FAST), destination)
    assert report.status == "failed"
    assert report.output_path is None
    assert report.error is not None
    assert report.error["code"] == "RENDER_VALIDATION_FAILED"
    assert destination.read_bytes() == b"previous export"
    assert sorted(p.name for p in target_dir.iterdir()) == ["export.mp4"]


@pytest.mark.req("AVE-REQ-072 AC-4", "AVE-REQ-075 AC-4")
def test_validator_rejects_damaged_output(
    timing_fixtures: dict[str, Fixture], artifacts_dir: Path
) -> None:
    """AVE-REQ-072 AC-4 / AVE-REQ-075 AC-4: validation decodes the file; truncation fails it."""
    asset, sequence = _tiny_plan(timing_fixtures)
    plan = compile_render_plan(sequence, {asset.id: asset}, profile=FAST)
    output = artifacts_dir / "intact.mp4"
    report = render(plan, output)
    assert report.succeeded
    expected = render_module.expected_output(plan)
    assert validate_output(output, expected).passed
    damaged = artifacts_dir / "damaged.mp4"
    shutil.copyfile(output, damaged)
    with damaged.open("r+b") as handle:
        handle.truncate(damaged.stat().st_size // 2)
    assert not validate_output(damaged, expected).passed
    wrong = expected.model_copy(update={"fps": Fraction(25)})
    failures = {c.name for c in validate_output(output, wrong).failures}
    assert {"r_frame_rate", "avg_frame_rate"} <= failures


@pytest.mark.req("AVE-REQ-020 AC-3", "AVE-REQ-019 AC-1")
def test_gaps_and_bars_show_the_configured_background(
    std: StandardFixtures, artifacts_dir: Path
) -> None:
    """AVE-REQ-020 AC-3 (background) / AVE-REQ-019 AC-1: an empty stretch of the timeline and the
    contain bars show the sequence background color, not black or stretched media."""
    asset = describe_asset(std.c.path, asset_id="C")
    clip = Clip(
        id="late", track_id="v", asset_id="C", kind="video", timeline_start=Fraction(1, 2),
        source_in=Fraction(0), source_out=Fraction(1, 2),
    )  # fmt: skip
    sequence = Sequence(
        id="gap", fps=Fraction(30), canvas=Canvas(width=360, height=640), background="#204060",
        tracks=TRACKS, clips=(clip,),
    )  # fmt: skip
    plan = compile_render_plan(sequence, {"C": asset}, profile=FAST)
    assert [len(s.layers) for s in plan.segments] == [0, 1]
    output = artifacts_dir / "gap-background.mp4"
    assert render(plan, output).succeeded
    frames = list(iter_video_frames(output, width=360, height=640))
    assert len(frames) == 30
    background = np.array([0x20, 0x40, 0x60])
    for frame in frames[:15]:
        assert np.abs(frame.reshape(-1, 3).mean(axis=0) - background).max() < 4
    for frame in frames[15:]:
        assert np.abs(frame[20, 180].astype(int) - background).max() < 6  # bar above the image
        assert np.abs(frame[320, 20].astype(int) - (50, 170, 70)).max() < 12  # C's color


BT709_KR, BT709_KB = Fraction(2126, 10000), Fraction(722, 10000)
"""Luma coefficients of ITU-R BT.709-6 (Part 1, section 3)."""


def _nearest(value: Fraction) -> int:
    """The specification's rounding to the nearest integer (halves upward)."""
    return math.floor(value + Fraction(1, 2))


def _bt709_round_trip(rgb: tuple[int, int, int]) -> np.ndarray:
    """8-bit RGB after encoding ``rgb`` as 8-bit BT.709 limited-range Y'CbCr and decoding it
    again (ITU-R BT.709-6, Part 1, section 3: Y' = 16 + 219 E'Y, Cb/Cr = 128 + 224 E'Cb/E'Cr)."""
    red, green, blue = (Fraction(value, 255) for value in rgb)
    luma = BT709_KR * red + (1 - BT709_KR - BT709_KB) * green + BT709_KB * blue
    coded_luma = _nearest(16 + 219 * luma)
    coded_blue = _nearest(128 + 224 * (blue - luma) / (2 * (1 - BT709_KB)))
    coded_red = _nearest(128 + 224 * (red - luma) / (2 * (1 - BT709_KR)))
    luma = Fraction(coded_luma - 16, 219)
    blue = luma + 2 * (1 - BT709_KB) * Fraction(coded_blue - 128, 224)
    red = luma + 2 * (1 - BT709_KR) * Fraction(coded_red - 128, 224)
    green = (luma - BT709_KR * red - BT709_KB * blue) / (1 - BT709_KR - BT709_KB)
    return np.array([min(255, max(0, _nearest(255 * value))) for value in (red, green, blue)])


@pytest.mark.req("AVE-REQ-020 AC-3", "AVE-REQ-019 AC-1")
@pytest.mark.parametrize("background", ["#204060", "#C03020", "#30A040", "#E0C020"])
def test_background_decodes_to_its_color_under_the_tagged_bt709_matrix(
    std: StandardFixtures, artifacts_dir: Path, background: str
) -> None:
    """AVE-REQ-020 AC-3 (background), AVE-REQ-019 AC-1: the output is tagged BT.709 limited
    range, and the empty stretch of the timeline and the contain bars above and below C decode,
    with that matrix, to the BT.709 round trip of the configured color: every channel mean within
    one level (a BT.601-coded background reads up to 17 levels off)."""
    asset = describe_asset(std.c.path, asset_id="C")
    clip = Clip(
        id="late", track_id="v", asset_id="C", kind="video", timeline_start=Fraction(1, 2),
        source_in=Fraction(0), source_out=Fraction(1, 2),
    )  # fmt: skip
    sequence = Sequence(
        id="color", fps=Fraction(30), canvas=Canvas(width=360, height=640),
        background=background, tracks=TRACKS, clips=(clip,),
    )  # fmt: skip
    plan = compile_render_plan(sequence, {"C": asset}, profile=FAST)
    assert [len(s.layers) for s in plan.segments] == [0, 1]
    output = artifacts_dir / f"background-{background.lstrip('#')}.mp4"
    assert render(plan, output).succeeded
    (video,) = probe(output).video_streams
    assert (video.color_space, video.color_range) == ("bt709", "tv")
    frames = decode_video_frames(output, width=360, height=640, stream=video).astype(float)
    assert len(frames) == 30
    red, green, blue = (int(background[i : i + 2], 16) for i in (1, 3, 5))
    expected = _bt709_round_trip((red, green, blue))
    # C (16:9) contained in 360x640 is 360x202.5, centered: the bars end near row 219 and start
    # again near row 421. About 20 rows next to the image are left out (coding bleed).
    regions = {
        "gap": frames[:15],
        "bar above": frames[15:, :200],
        "bar below": frames[15:, 442:],
    }
    for name, pixels in regions.items():
        mean = pixels.reshape(-1, 3).mean(axis=0)
        assert np.abs(mean - expected).max() <= 1, (name, mean, expected)
