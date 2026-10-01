"""Source timing edge cases on real media: late stream starts, VFR gaps, literal image names.

The sources are timing variants of fixture A (:mod:`tests.media.derived`) and copies of the still
fixture. Expected frames and sample positions come from fixture A's manifest (frame ``n`` at
``n / 60`` s, chirps at the event frames), the stated transformation of each variant and the frame
rule of ADR-004 - never from the compiler.
"""

from __future__ import annotations

import bisect
import shutil
from fractions import Fraction
from pathlib import Path

import numpy as np
import pytest

from ave.domain.model import Canvas, Clip, Sequence, Track
from ave.fixtures.barcode import barcode_layout
from ave.fixtures.generate import Fixture
from ave.fixtures.standard import COLOR_A, PILOT_HZ, REFERENCE_EVENT_FRAMES, StandardFixtures
from ave.media.asset import MediaAsset, describe_asset
from ave.media.probe import probe
from ave.proc import media_url, run_tool
from ave.render.compiler import compile_render_plan
from ave.render.ffmpeg import render
from ave.render.profile import OutputProfile
from ave.render.validate import decode_audio, iter_video_frames
from tests.media.derived import (
    AUDIO_DELAY,
    GAP_FIRST,
    GAP_RESUME,
    VIDEO_DELAY,
    DerivedMedia,
    derived_media,
)
from tests.oracles import (
    Placement,
    detect_chirps,
    match_events,
    nearest_color,
    patch_rgb,
    read_barcode,
    tone_amplitude,
)

pytestmark = pytest.mark.media

FAST = OutputProfile(preset="veryfast")
FPS = Fraction(60)
TRACKS = (Track(id="v", kind="video", index=0), Track(id="a", kind="audio", index=0))
SQUARE = barcode_layout(1080, 1080)
# 1080x1080 contained in 640x360: scale 1/3 -> 360x360 at x = 140.
SQUARE_IN_640 = Placement(scale=1 / 3, x=140, y=0)
A_FRAMES = 1800
"""Fixture A: 30 s at 60/1."""


@pytest.fixture(scope="module")
def derived(std: StandardFixtures, artifacts_dir: Path) -> DerivedMedia:
    """Timing variants of fixture A."""
    return derived_media(std, artifacts_dir / "derived")


def _clips(asset: MediaAsset, source_in: Fraction, duration: Fraction, *, audio: bool) -> Sequence:
    common = {
        "asset_id": asset.id,
        "timeline_start": Fraction(0),
        "source_in": source_in,
        "source_out": source_in + duration,
    }
    clips = [Clip.model_validate({"id": "pic", "track_id": "v", "kind": "video", **common})]
    if audio:
        clips.append(Clip.model_validate({"id": "snd", "track_id": "a", "kind": "audio", **common}))
    canvas = Canvas(width=640, height=360)
    return Sequence(id="timing", fps=FPS, canvas=canvas, tracks=TRACKS, clips=tuple(clips))


def _render(sequence: Sequence, asset: MediaAsset, output: Path) -> None:
    report = render(compile_render_plan(sequence, {asset.id: asset}, profile=FAST), output)
    assert report.succeeded, report.error


def _shown_frames(path: Path) -> list[int | str | None]:
    """Source frame index per output frame, or ``"background"`` where A's color patch is absent
    (frame 0's barcode is all black, so the patch tells it apart from an empty canvas)."""
    palette = {"a": COLOR_A, "background": (0, 0, 0)}
    shown: list[int | str | None] = []
    for frame in iter_video_frames(path, width=640, height=360):
        color = nearest_color(patch_rgb(frame, SQUARE, SQUARE_IN_640, 1), palette)
        shown.append(read_barcode(frame, SQUARE, SQUARE_IN_640, 1) if color == "a" else color)
    return shown


def _frame_rule(frames: list[int], times: list[Fraction], t: Fraction) -> int:
    """ADR-004 frame rule: the latest frame with presentation time <= t; before the first frame,
    the first frame (documented clamp of ave.render.compiler)."""
    return frames[max(0, bisect.bisect_right(times, t) - 1)]


def test_audio_follows_timestamps_when_the_audio_stream_starts_late(
    derived: DerivedMedia, artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-4: the audio stream starts 0.5 s after the container start; a clip reading
    source [1/4, 33/4) presents silence until source time 0.5 and every chirp at its source time
    (event + 0.5) minus 1/4 - not shifted earlier by the stream's late start."""
    asset = describe_asset(derived.late_audio, asset_id="late-audio")
    (stream,) = asset.probe.audio_streams
    assert asset.probe.container_start_time == 0
    assert stream.start_time == AUDIO_DELAY  # audio start differs from the container start
    source_in = Fraction(1, 4)
    output = artifacts_dir / "late-audio-start.mp4"
    _render(_clips(asset, source_in, Fraction(8), audio=True), asset, output)
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    events = [
        float(Fraction(frame, 60) + AUDIO_DELAY - source_in)
        for frame in REFERENCE_EVENT_FRAMES
        if 0 <= Fraction(frame, 60) + AUDIO_DELAY - source_in < 8
    ]
    assert len(events) == 2
    pairs, missing, unexpected = match_events(detect_chirps(audio, 48000), events, 0.01)
    assert not missing
    assert not unexpected
    assert max(abs(detected - expected) for expected, detected in pairs) <= 2 / 48000
    start = float(AUDIO_DELAY - source_in)  # 0.25 s: output time of the stream's first sample
    # Clear of the AAC frame (about 43 ms with overlap) that contains the onset of the pilot.
    before = audio[int(0.02 * 48000) : int((start - 0.06) * 48000)]
    after = audio[int((start + 0.05) * 48000) : int((start + 0.65) * 48000)]
    assert np.abs(before).max() < 1e-3  # silence before the stream starts
    assert tone_amplitude(after, 48000, PILOT_HZ["a"]) > 0.04


def test_vfr_gap_longer_than_the_seek_margin_keeps_the_frame_rule(
    derived: DerivedMedia, artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-4: frame 59 (59/60 s) is followed by frame 240 (4 s); output frames for
    source times in [3.5, 4) show frame 59, the latest frame with PTS <= t, although it lies
    more than the one-second seek margin before t."""
    asset = describe_asset(derived.vfr_gap, asset_id="gap")
    (video,) = asset.probe.video_streams
    assert video.frame_timing == "vfr"
    source_in, duration = Fraction(7, 2), Fraction(3, 2)
    sequence = _clips(asset, source_in, duration, audio=False)
    plan = compile_render_plan(sequence, {asset.id: asset}, profile=FAST)
    (layer,) = plan.segments[0].layers
    assert layer.seek is not None
    assert layer.seek - Fraction(GAP_FIRST - 1, 60) > 1  # the needed frame precedes the seek
    output = artifacts_dir / "vfr-gap.mp4"
    _render(sequence, asset, output)
    frames = [*range(GAP_FIRST), *range(GAP_RESUME, A_FRAMES)]
    times = [Fraction(n, 60) for n in frames]
    count = int(duration * FPS)
    expected = [_frame_rule(frames, times, source_in + Fraction(k) / FPS) for k in range(count)]
    assert expected[:30] == [GAP_FIRST - 1] * 30
    assert expected[30] == GAP_RESUME
    assert _shown_frames(output) == expected


def test_output_before_the_first_video_frame_shows_the_first_frame(
    derived: DerivedMedia, artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-4: the video stream starts 0.5 s after the container start; output frames
    whose source time precedes the first frame show that first frame (clamp, no background
    flash), later frames follow the frame rule on the shifted timestamps."""
    asset = describe_asset(derived.late_video, asset_id="late-video")
    (video,) = asset.probe.video_streams
    assert asset.probe.container_start_time == 0
    assert video.start_time == VIDEO_DELAY
    output = artifacts_dir / "late-video-start.mp4"
    _render(_clips(asset, Fraction(0), Fraction(1), audio=False), asset, output)
    frames = list(range(A_FRAMES))
    times = [Fraction(n, 60) + VIDEO_DELAY for n in frames]
    expected = [_frame_rule(frames, times, Fraction(k) / FPS) for k in range(60)]
    assert expected[:31] == [0] * 31
    assert expected[31:] == list(range(1, 30))
    assert _shown_frames(output) == expected


@pytest.fixture(scope="module")
def literal_image(timing_fixtures: dict[str, Fixture], artifacts_dir: Path) -> Path:
    """The 640x360 still fixture saved as ``photo%d.png`` next to a different 64x48
    ``photo1.png`` (the file an image-sequence reading of the name would open)."""
    directory = artifacts_dir / "literal-image"
    directory.mkdir()
    named = directory / "photo%d.png"
    shutil.copyfile(timing_fixtures["still"].path, named)
    decoy = directory / "photo1.png"
    run_tool(
        "ffmpeg",
        [
            "-hide_banner", "-nostdin", "-v", "error", "-f", "lavfi",
            "-i", "color=c=0x2040C0:s=64x48", "-frames:v", "1", "-update", "1",
            "-f", "image2", media_url(decoy),
        ],
        timeout=60,
    )  # fmt: skip
    assert probe(decoy).video_streams[0].width == 64
    return named


def test_probe_reads_a_percent_name_as_that_file(literal_image: Path) -> None:
    """AVE-REQ-004 AC-3, AVE-REQ-004 AC-4: an untrusted name with ``%d`` never selects another
    file: the still image reports its own exact 640x360."""
    asset = describe_asset(literal_image, asset_id="literal")
    (video,) = asset.probe.video_streams
    assert (video.width, video.height) == (640, 360)
    assert asset.probe.format_name == "image2"


def test_render_reads_a_percent_name_as_that_file(literal_image: Path, artifacts_dir: Path) -> None:
    """AVE-REQ-072 AC-3: the rendered still is the named file (barcode 0 on the fixture's
    yellow background), not the 64x48 blue ``photo1.png``."""
    asset = describe_asset(literal_image, asset_id="literal")
    clip = Clip(
        id="still", track_id="v", asset_id=asset.id, kind="image", timeline_start=Fraction(0),
        source_in=Fraction(0), source_out=Fraction(1, 2),
    )  # fmt: skip
    sequence = Sequence(
        id="still", fps=Fraction(30), canvas=Canvas(width=640, height=360), tracks=TRACKS,
        clips=(clip,),
    )  # fmt: skip
    output = artifacts_dir / "literal-image.mp4"
    _render(sequence, asset, output)
    layout = barcode_layout(640, 360)
    identity = Placement(scale=1.0, x=0, y=0)
    frames = list(iter_video_frames(output, width=640, height=360))
    assert len(frames) == 15
    for frame in frames:
        assert read_barcode(frame, layout, identity, 1) == 0
        assert np.abs(patch_rgb(frame, layout, identity, 1) - (230, 180, 30)).max() < 12
