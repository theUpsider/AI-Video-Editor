"""AT-02 / AT-04: split / full-width / split CPU render validated on decoded output.

The sequence uses the *estimated* A/B mapping; every expectation below is computed from the
specification's composition table and the fixture manifests, never from the compiler:

* output frame ``n`` presents project time ``n / 60``;
* ``[0, 8)``: A shows source frame ``120 + n``, B (true ``a_B = 2``) shows ``n``;
* ``[8, 14)``: C shows ``n - 480``;
* ``[14, 22)``: A shows ``n - 120``, B shows ``n - 240``;
* contain geometry: each square image is 960x960 at (0, 60) / (960, 60) (scale 8/9).
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path

import numpy as np
import numpy.typing as npt
import pytest

from ave.domain.model import SyncMember
from ave.fixtures.barcode import barcode_layout
from ave.fixtures.standard import (
    C_EVENT_FRAMES,
    COLOR_A,
    COLOR_B,
    COLOR_C,
    PILOT_HZ,
    REFERENCE_EVENT_FRAMES,
    StandardFixtures,
)
from ave.media.asset import MediaAsset, sha256_file
from ave.media.probe import probe
from ave.render.compiler import compile_render_plan
from ave.render.ffmpeg import RenderReport, render
from ave.render.profile import OutputProfile
from ave.render.validate import decode_audio, decode_video_frames, iter_video_frames
from ave.sync.audio import estimate_offset
from ave.timebase import Interval
from tests.compositions import standard_sequence, sync_group
from tests.oracles import (
    Placement,
    detect_chirps,
    is_flash,
    match_events,
    nearest_color,
    patch_rgb,
    read_barcode,
    tone_amplitude,
)

pytestmark = pytest.mark.media

FPS = 60
FACTOR = 4  # analysis decode at 480x270
SQUARE = barcode_layout(1080, 1080)
WIDE = barcode_layout(1920, 1080)
LEFT = Placement(scale=8 / 9, x=0, y=60)
RIGHT = Placement(scale=8 / 9, x=960, y=60)
FULL = Placement(scale=1.0, x=0, y=0)
PALETTE = {"a": COLOR_A, "b": COLOR_B, "c": COLOR_C, "black": (0, 0, 0)}
ONE_FRAME = 1 / FPS


def expected_sources(n: int) -> dict[str, int]:
    """Source frame per perspective for global output frame ``n`` (specification table)."""
    if n < 480:
        return {"a": 120 + n, "b": n}
    if n < 840:
        return {"c": n - 480}
    return {"a": n - 120, "b": n - 240}


@dataclass
class FrameScan:
    """Per-frame measurements of a decoded render."""

    left: list[int | None]
    right: list[int | None]
    full: list[int | None]
    left_color: list[str]
    right_color: list[str]
    full_color: list[str]
    left_flash: list[int]
    right_flash: list[int]
    full_flash: list[int]


def scan(path: Path, *, left: Placement = LEFT, right: Placement = RIGHT) -> FrameScan:
    """Reads barcodes, patch colors and flashes of every frame at 480x270."""
    result = FrameScan([], [], [], [], [], [], [], [], [])
    for n, frame in enumerate(iter_video_frames(path, width=480, height=270)):
        for name, layout, placement in (
            ("left", SQUARE, left),
            ("right", SQUARE, right),
            ("full", WIDE, FULL),
        ):
            getattr(result, name).append(read_barcode(frame, layout, placement, FACTOR))
            rgb = patch_rgb(frame, layout, placement, FACTOR)
            getattr(result, f"{name}_color").append(nearest_color(rgb, PALETTE))
            if is_flash(rgb):
                getattr(result, f"{name}_flash").append(n)
    return result


@dataclass
class Rendered:
    report: RenderReport
    path: Path
    estimate_offset_s: float
    scan: FrameScan
    audio: npt.NDArray[np.float32]
    checksums_before: dict[str, str]


@pytest.fixture(scope="module")
def rendered(
    std: StandardFixtures, std_assets: dict[str, MediaAsset], artifacts_dir: Path
) -> Rendered:
    """Estimate sync from audio, build the AT-02 sequence and render it with the default profile."""
    before = {k: sha256_file(a.path) for k, a in std_assets.items()}
    estimate = estimate_offset(std_assets["A"].path, std_assets["B"].path)
    member: SyncMember = estimate.to_sync_member("B")
    sequence = standard_sequence(sync_group(member))
    plan = compile_render_plan(sequence, std_assets)
    output = artifacts_dir / "at02-split-full-split.mp4"
    report = render(plan, output)
    (artifacts_dir / "at02-report.json").write_text(report.model_dump_json(indent=2))
    (artifacts_dir / "at02-sync-estimate.json").write_text(estimate.model_dump_json(indent=2))
    assert report.succeeded, report.error
    audio = decode_audio(output, sample_rate=48000, channels=2)
    assert estimate.offset_s is not None
    return Rendered(report, output, estimate.offset_s, scan(output), audio, before)


def test_export_is_real_validated_and_published(rendered: Rendered) -> None:
    """AVE-REQ-072 AC-1/AC-2/AC-4, AVE-REQ-075 AC-1/AC-4: CPU H.264/AAC MP4 with the default
    profile, validated by decoding and published atomically; duration 22 s within one frame."""
    report = rendered.report
    assert report.device == "cpu"
    assert report.validation is not None
    assert report.validation.passed
    assert report.output_path == str(rendered.path)
    assert not list(rendered.path.parent.glob(".*partial*"))
    info = probe(rendered.path)
    (video,) = info.video_streams
    (audio,) = info.audio_streams
    assert (video.codec_name, video.width, video.height) == ("h264", 1920, 1080)
    assert video.r_frame_rate == FPS
    assert video.avg_frame_rate == FPS
    assert video.duration is not None
    assert abs(video.duration - 22) < Fraction(1, FPS)
    assert (audio.codec_name, audio.sample_rate, audio.channels) == ("aac", 48000, 2)
    assert audio.duration is not None
    assert abs(audio.duration - 22) < Fraction(1, FPS)
    assert report.encoder_settings["video"].startswith("libx264 crf=20 preset=medium")
    commands = json.dumps([c.argv for c in report.commands])
    for accelerator in ("cuda", "nvenc", "vaapi", "qsv", "videotoolbox"):
        assert accelerator not in commands


def test_contain_geometry_is_960_square_at_y60(rendered: Rendered) -> None:
    """AVE-REQ-020 AC-1 / AVE-REQ-019 AC-1/AC-2: undistorted 960x960 images, black bars."""
    for n in (30, 1000):
        (frame,) = decode_video_frames(
            rendered.path, width=1920, height=1080, start_frame=n, count=1
        )
        content = frame.max(axis=2) > 48
        for x0, x1 in ((0, 960), (960, 1920)):
            ys, xs = np.nonzero(content[:, x0:x1])
            top, bottom = int(ys.min()), int(ys.max()) + 1
            left, right = x0 + int(xs.min()), x0 + int(xs.max()) + 1
            assert abs(top - 60) <= 2
            assert abs(bottom - 1020) <= 2
            assert abs(left - x0) <= 2
            assert abs(right - x1) <= 2
            assert abs((right - left) - (bottom - top)) <= 3  # square: no stretch
        assert frame[:56].max() < 40  # background strip above
        assert frame[1024:].max() < 40  # and below
    (full,) = decode_video_frames(rendered.path, width=1920, height=1080, start_frame=600, count=1)
    covered = full.max(axis=2) > 48
    covered[300:780, 720:1200] = True  # C's own barcode grid has black cells
    assert covered.all()  # C fills the whole canvas: no background anywhere


def test_decoded_source_frames_follow_the_timeline(rendered: Rendered) -> None:
    """AVE-REQ-021 AC-1/AC-3, AVE-REQ-020 AC-4, AVE-REQ-024 AC-4: both perspectives, then C,
    then both again; A and C exact, B within one frame under the estimated mapping."""
    s = rendered.scan
    assert len(s.left) == 1320
    errors: dict[str, list[int]] = {"a": [], "b": [], "c": []}
    unreadable = 0
    for n in range(1320):
        expected = expected_sources(n)
        if "c" in expected:
            observed = {"c": s.full[n]}
            assert s.full_color[n] in ("c", "black") or n in s.full_flash
        else:
            observed = {"a": s.left[n], "b": s.right[n]}
            assert s.left_color[n] == "a" or n in s.left_flash
            assert s.right_color[n] == "b" or n in s.right_flash
        for name, value in observed.items():
            if value is None:
                unreadable += 1
            else:
                errors[name].append(value - expected[name])
    assert unreadable <= 13  # at most 1% of frames unreadable after H.264
    assert set(errors["a"]) == {0}
    assert set(errors["c"]) == {0}
    assert set(errors["b"]) <= {-1, 0, 1}
    assert len(errors["b"]) > 900


def test_flash_events_align_in_both_perspectives(rendered: Rendered) -> None:
    """AT-02/AT-04: shared flashes appear in both halves on the expected output frame."""
    s = rendered.scan
    expected_split = sorted(
        [e - 120 for e in REFERENCE_EVENT_FRAMES if 0 <= e - 120 < 480]
        + [e + 120 for e in REFERENCE_EVENT_FRAMES if 840 <= e + 120 < 1320]
    )
    assert expected_split == [73, 234, 446, 903, 1183]
    left = [n for n in s.left_flash if expected_sources(n).get("a") is not None]
    right = [n for n in s.right_flash if expected_sources(n).get("b") is not None]
    assert left == expected_split
    assert len(right) == len(expected_split)
    assert all(abs(r - e) <= 1 for r, e in zip(right, expected_split, strict=True))
    full = [n for n in s.full_flash if 480 <= n < 840]
    assert full == [480 + c for c in C_EVENT_FRAMES]


def _quiet_windows(events: list[float]) -> list[tuple[str, float, float]]:
    """0.5 s windows inside each segment that stay clear of cuts and chirps."""
    windows = []
    for kind, first, last in (("split", 0, 8), ("full", 8, 14), ("split", 14, 22)):
        start = first + 0.15
        while start + 0.5 <= last - 0.15:
            end = start + 0.5
            if all(end < e - 0.05 or start > e + 0.1 for e in events):
                windows.append((kind, start, end))
            start += 0.5
    return windows


def test_audio_events_and_routing(rendered: Rendered) -> None:
    """AVE-REQ-031 AC-1/AC-3, AVE-REQ-021 AC-2, AVE-REQ-024 AC-1: A in split segments, C in the
    full segment, B never audible although B's audio produced the synchronization."""
    left = rendered.audio[:, 0]
    expected = sorted(
        [(e - 120) / FPS for e in REFERENCE_EVENT_FRAMES if 0 <= e - 120 < 480]
        + [(480 + c) / FPS for c in C_EVENT_FRAMES]
        + [(e + 120) / FPS for e in REFERENCE_EVENT_FRAMES if 840 <= e + 120 < 1320]
    )
    pairs, missing, unexpected = match_events(detect_chirps(left, 48000), expected, ONE_FRAME)
    assert not missing
    assert not unexpected
    assert max(abs(d - e) for e, d in pairs) < ONE_FRAME
    windows = _quiet_windows(expected)
    assert len(windows) >= 25
    for kind, start, end in windows:
        chunk = left[int(start * 48000) : int(end * 48000)]
        amplitudes = {k: tone_amplitude(chunk, 48000, hz) for k, hz in PILOT_HZ.items()}
        audible = "a" if kind == "split" else "c"
        assert amplitudes[audible] > 0.04, (kind, start, amplitudes)
        for other in {"a", "b", "c"} - {audible}:
            assert amplitudes[other] < 0.002, (kind, start, amplitudes)
    assert rendered.estimate_offset_s == pytest.approx(2.0, abs=1e-4)


def test_originals_are_unchanged(rendered: Rendered, std_assets: dict[str, MediaAsset]) -> None:
    """AT-02 evidence: rendering never modifies the original media (SHA-256 before/after)."""
    after = {k: sha256_file(a.path) for k, a in std_assets.items()}
    assert after == rendered.checksums_before
    assert after == {k: a.sha256 for k, a in std_assets.items()}


def test_ground_truth_range_is_frame_exact_across_cuts(
    std_assets: dict[str, MediaAsset], artifacts_dir: Path
) -> None:
    """AVE-REQ-021 AC-3 / AVE-REQ-012 AC-3: a range [6, 16) crossing both cuts, with the
    ground-truth mapping, shows exactly the expected source frame on every output frame."""
    member = SyncMember(asset_id="B", a=Fraction(2), method="ground-truth", confidence=1.0)
    plan = compile_render_plan(
        standard_sequence(sync_group(member)),
        std_assets,
        profile=OutputProfile(preset="veryfast"),
        project_range=Interval.of(6, 16),
    )
    output = artifacts_dir / "at02-range-6-16.mp4"
    report = render(plan, output)
    assert report.succeeded, report.error
    s = scan(output)
    assert len(s.left) == 600
    mismatches = []
    for k in range(600):
        n = 360 + k
        expected = expected_sources(n)
        observed = {"c": s.full[k]} if "c" in expected else {"a": s.left[k], "b": s.right[k]}
        for name, value in observed.items():
            if value != expected[name]:
                mismatches.append((n, name, value, expected[name]))
    assert mismatches == []
    # Boundary frames: last split frame, first and last C frame, first split frame after C.
    assert (s.left[119], s.right[119]) == (599, 479)
    assert (s.full[120], s.full[479]) == (0, 359)
    assert (s.left[480], s.right[480]) == (720, 600)
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    before = audio[int(1.55 * 48000) : int(1.95 * 48000)]
    after = audio[int(2.05 * 48000) : int(2.45 * 48000)]
    assert tone_amplitude(before, 48000, PILOT_HZ["a"]) > 0.04
    assert tone_amplitude(before, 48000, PILOT_HZ["c"]) < 0.002
    assert tone_amplitude(after, 48000, PILOT_HZ["c"]) > 0.04
    assert tone_amplitude(after, 48000, PILOT_HZ["a"]) < 0.002


def test_cover_mode_crops_without_changing_aspect(
    std_assets: dict[str, MediaAsset], artifacts_dir: Path
) -> None:
    """AVE-REQ-020 AC-2 / AVE-REQ-019 AC-1: cover fills each 960x1080 half by cropping 60 px on
    each side of the unscaled 1080x1080 image (barcode cells keep their 120 px size)."""
    member = SyncMember(asset_id="B", a=Fraction(2), method="ground-truth", confidence=1.0)
    plan = compile_render_plan(
        standard_sequence(sync_group(member), fit="cover"),
        std_assets,
        profile=OutputProfile(preset="veryfast"),
        project_range=Interval.of(0, 1),
    )
    output = artifacts_dir / "at02-cover.mp4"
    report = render(plan, output)
    assert report.succeeded, report.error
    left = Placement(scale=1.0, x=0, y=0, crop_x=60)
    right = Placement(scale=1.0, x=960, y=0, crop_x=60)
    s = scan(output, left=left, right=right)
    assert s.left == [120 + n for n in range(60)]
    assert s.right == list(range(60))
    (frame,) = decode_video_frames(output, width=1920, height=1080, start_frame=10, count=1)
    covered = frame.max(axis=2) > 48
    covered[300:780, 240:720] = True  # barcode grids (black cells) of the two halves
    covered[300:780, 1200:1680] = True
    assert covered.all()  # no background bars: both regions are completely filled
    # Barcode grid edges: 300 - 60 = 240 px from each half's left edge, 480 px wide (scale 1).
    row = frame[540, :960].astype(int).max(axis=1)
    dark = np.nonzero(row < 40)[0]
    assert abs(int(dark.min()) - 240) <= 2
    assert abs(int(dark.max()) + 1 - 720) <= 2
