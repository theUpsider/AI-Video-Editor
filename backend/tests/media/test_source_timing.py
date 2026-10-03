"""Source timing edge cases on real media: late stream starts, VFR gaps, audio timestamp gaps and
jitter, keyframe indexes, literal image names.

The sources are timing variants of fixture A (:mod:`tests.media.derived`), a raw H.264 stream
generated here and copies of the still fixture. Expected frames and sample positions come from
fixture A's manifest (frame ``n`` at ``n / 60`` s, chirps at the event frames), the stated
transformation of each variant, the files' own packet tables and the frame rule of ADR-004 -
never from the compiler.
"""

from __future__ import annotations

import bisect
import itertools
import json
import math
import shutil
from fractions import Fraction
from pathlib import Path
from typing import Literal

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
from ave.sync.audio import extract_analysis_audio
from tests.media.derived import (
    AAC_PRIMING,
    AUDIO_DELAY,
    AUDIO_GAP_AT,
    AUDIO_JITTER,
    GAP_FIRST,
    GAP_RESUME,
    LATE_AAC_DELAY,
    LONG_GOP_FRAMES,
    VIDEO_DELAY,
    WIDE_JITTER,
    DerivedMedia,
    audio_gap_media,
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


@pytest.mark.req("AVE-REQ-012 AC-4")
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


def _chirp_errors(audio: np.ndarray, expected: list[float]) -> list[float]:
    """Absolute errors of the detected chirps against ``expected``; every expected chirp is found
    and no other chirp is present."""
    pairs, missing, unexpected = match_events(detect_chirps(audio, 48000), expected, 0.01)
    assert not missing
    assert not unexpected
    return [abs(detected - value) for value, detected in pairs]


def _stream_start(path: Path, selector: str) -> Fraction:
    """Start (``start_pts * time_base``) of one stream, read with FFprobe: the file's own
    timestamps, independent of the code under test."""
    completed = run_tool(
        "ffprobe",
        [
            "-v", "error", "-select_streams", selector, "-show_entries",
            "stream=start_pts,time_base", "-of", "json", media_url(path),
        ],
        timeout=60,
    )  # fmt: skip
    (stream,) = json.loads(completed.stdout)["streams"]
    return int(stream["start_pts"]) * Fraction(stream["time_base"])


@pytest.mark.req("AVE-REQ-012 AC-4")
@pytest.mark.parametrize("variant", ["late_aac_mp4", "late_aac_ts"])
@pytest.mark.parametrize("source_in", [Fraction(3, 4), Fraction(5, 2)], ids=["in-0.75", "in-2.5"])
def test_late_aac_audio_follows_timestamps_in_mp4_and_mpegts(
    derived: DerivedMedia, artifacts_dir: Path, variant: str, source_in: Fraction
) -> None:
    """AVE-REQ-012 AC-4: AAC audio shifted 0.8 s against the video, in MP4 (container start 0)
    and in MPEG-TS (container start 43/30 s, where FFmpeg would re-base on the audio stream's own
    start): every chirp of the rendered range sits at its event time + 0.8 s minus source_in, for
    seek points below and above one second."""
    path = getattr(derived, variant)
    # The file's own timestamps: the audio stream starts 0.8 s minus the AAC priming after the
    # video, which defines source time 0.
    shift = _stream_start(path, "a:0") - _stream_start(path, "v:0")
    assert shift == LATE_AAC_DELAY - AAC_PRIMING
    asset = describe_asset(path, asset_id=variant)
    (video,) = asset.probe.video_streams
    assert video.start_time == asset.probe.container_start_time
    duration = Fraction(8)
    output = artifacts_dir / f"{variant}-{source_in.numerator}-{source_in.denominator}.mp4"
    _render(_clips(asset, source_in, duration, audio=True), asset, output)
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    expected = [
        float(Fraction(frame, 60) + LATE_AAC_DELAY - source_in)
        for frame in REFERENCE_EVENT_FRAMES
        if 0 <= Fraction(frame, 60) + LATE_AAC_DELAY - source_in < duration
    ]
    assert len(expected) == (2 if source_in < 1 else 3)
    assert max(_chirp_errors(audio, expected)) <= 2 / 48000


@pytest.mark.req("AVE-REQ-012 AC-4")
def test_mpegts_video_follows_the_exact_container_start(
    derived: DerivedMedia, artifacts_dir: Path
) -> None:
    """AVE-REQ-012 AC-4: an MPEG-TS source whose container start (129000/90000 s) has no exact
    microsecond value shows, at source time t, frame floor(60 t) - the frame rule on the exact
    origin, not one frame earlier."""
    asset = describe_asset(derived.late_aac_ts, asset_id="ts")
    assert asset.probe.container_start_time == Fraction(43, 30)
    source_in = Fraction(5, 2)
    output = artifacts_dir / "ts-frames.mp4"
    _render(_clips(asset, source_in, Fraction(1), audio=False), asset, output)
    assert _shown_frames(output) == [150 + k for k in range(60)]


@pytest.mark.req("AVE-REQ-012 AC-4")
def test_long_gop_mpegts_keeps_the_frame_rule(derived: DerivedMedia, artifacts_dir: Path) -> None:
    """AVE-REQ-012 AC-4: an MPEG-TS source (no keyframe index) with one keyframe every 20 s
    and B-frames, cut at 9.39 s in the middle of a group of pictures, shows the frame rule's
    frame on every output frame - never a later keyframe."""
    asset = describe_asset(derived.long_gop_ts, asset_id="long-gop")
    (video,) = asset.probe.video_streams
    assert video.keyframe_pts is not None
    assert len(video.keyframe_pts) == -(-A_FRAMES // LONG_GOP_FRAMES)
    source_in, duration = Fraction(939, 100), Fraction(3, 2)
    output = artifacts_dir / "long-gop-ts.mp4"
    _render(_clips(asset, source_in, duration, audio=False), asset, output)
    expected = [int((source_in + Fraction(k, 60)) * 60) for k in range(int(duration * FPS))]
    assert expected[0] == 563
    assert _shown_frames(output) == expected


MATROSKA_PRECISION = Fraction(1, 1000)
"""Matroska stores timestamps in milliseconds."""


@pytest.mark.req("AVE-REQ-012 AC-4")
@pytest.mark.parametrize(
    ("variant", "origin"),
    [("intra_ts", Fraction(7, 5)), ("intra_ts_offset", Fraction(43, 30))],
    ids=["start-1.4", "start-43-30"],
)
@pytest.mark.parametrize(
    "source_in", [Fraction(0), Fraction(59, 60), Fraction(1999, 100)], ids=["0", "59-60", "19.99"]
)
def test_intra_only_mpegts_needs_no_keyframe_index(
    derived: DerivedMedia, artifacts_dir: Path, variant: str, origin: Fraction, source_in: Fraction
) -> None:
    """AVE-REQ-012 AC-4: an intra-only MPEG-TS source stores no keyframe index (one entry per
    frame would grow with the recording) and still shows the frame rule's frame, floor(60 t), at
    cuts on the first frame, on a frame time (59/60 s) and between frames late in the file - also
    when the container starts at 129000/90000 s, an origin without an exact microsecond value."""
    path = getattr(derived, variant)
    assert _stream_start(path, "v:0") == origin  # the file's own timestamps
    asset = describe_asset(path, asset_id=variant)
    assert asset.probe.container_start_time == origin
    assert asset.probe.warnings == ()
    (video,) = asset.probe.video_streams
    assert video.keyframe_pts is None
    output = artifacts_dir / f"{variant}-{source_in.numerator}-{source_in.denominator}.mp4"
    _render(_clips(asset, source_in, Fraction(1, 2), audio=False), asset, output)
    first = math.floor(source_in * 60)
    assert _shown_frames(output) == [first + k for k in range(30)]


@pytest.mark.req("AVE-REQ-012 AC-4")
def test_stream_without_presentation_timestamps_gets_an_empty_keyframe_index(
    tmp_path: Path,
) -> None:
    """AVE-REQ-012 AC-4: a raw H.264 elementary stream (no keyframe index in the format, no
    presentation timestamp on any packet) is no intra-only stream: the probe stores an empty
    keyframe index, so a cut anywhere in it seeks to the start of the file."""
    raw = tmp_path / "raw.h264"
    run_tool(
        "ffmpeg",
        [
            "-hide_banner", "-nostdin", "-v", "error", "-f", "lavfi",
            "-i", "testsrc2=size=160x90:rate=30:duration=4", "-c:v", "libx264",
            "-preset", "veryfast", "-g", "30", "-bf", "2", "-pix_fmt", "yuv420p", "-f", "h264",
            media_url(raw),
        ],
        timeout=120,
    )  # fmt: skip
    table = run_tool(
        "ffprobe",
        [
            "-v", "error", "-select_streams", "v:0", "-show_entries", "packet=pts,flags",
            "-of", "csv=p=0", media_url(raw),
        ],
        timeout=60,
    )  # fmt: skip
    packets = [line.split(",") for line in table.stdout.decode().split()]
    assert len(packets) == 120
    assert {pts for pts, _ in packets} == {"N/A"}  # the file's own packets carry no PTS
    assert 0 < sum(flags.startswith("K") for _, flags in packets) < len(packets)
    asset = describe_asset(raw, asset_id="raw")
    assert asset.probe.format_name == "h264"
    (video,) = asset.probe.video_streams
    assert video.keyframe_pts == ()
    plan = compile_render_plan(
        _clips(asset, Fraction(5, 2), Fraction(1, 2), audio=False), {asset.id: asset}, profile=FAST
    )
    (layer,) = plan.segments[0].layers
    assert layer.seek == 0


def _packet_table(path: Path) -> list[tuple[Fraction, Fraction]]:
    """``(start, duration)`` of every audio packet in seconds, from FFprobe's packet table in
    exact time-base ticks (the file's own timestamps, independent of the code under test)."""
    completed = run_tool(
        "ffprobe",
        [
            "-v", "error", "-select_streams", "a:0", "-show_entries",
            "stream=time_base:packet=pts,duration", "-of", "json", media_url(path),
        ],
        timeout=60,
    )  # fmt: skip
    data = json.loads(completed.stdout)
    (stream,) = data["streams"]
    tick = Fraction(stream["time_base"])
    return [(int(p["pts"]) * tick, int(p["duration"]) * tick) for p in data["packets"]]


def _contiguity_deviations(packets: list[tuple[Fraction, Fraction]]) -> list[Fraction]:
    """Each packet's start minus its position in a contiguous stream that begins at the first
    packet (the sum of the earlier packets' durations)."""
    deviations, position = [], packets[0][0]
    for start, duration in packets:
        deviations.append(start - position)
        position += duration
    return deviations


def _packet_gaps(path: Path) -> list[tuple[Fraction, Fraction]]:
    """``(time, gap)`` wherever an audio packet starts more than :data:`MATROSKA_PRECISION` after
    the previous packet ends (:func:`_packet_table`); ``time`` is that packet's start relative to
    the first packet."""
    packets = _packet_table(path)
    first = packets[0][0]
    return [
        (start - first, start - (previous + length))
        for (previous, length), (start, _) in itertools.pairwise(packets)
        if start - (previous + length) > MATROSKA_PRECISION
    ]


def _zero_runs(samples: np.ndarray, minimum: int) -> list[int]:
    """Lengths of the runs of at least ``minimum`` exactly-zero samples (inserted silence; the
    pilot tone is never zero for that long)."""
    zero = np.concatenate(([0], (samples == 0).astype(np.int8), [0]))
    edges = np.diff(zero)
    lengths = np.flatnonzero(edges == -1) - np.flatnonzero(edges == 1)
    return [int(length) for length in lengths if length >= minimum]


TIMESTAMP_PRECISION = {"mkv": MATROSKA_PRECISION, "ts": Fraction(1, 90000)}
"""Timestamp resolution of the gap variants (Matroska milliseconds, the MPEG-TS 90 kHz clock)."""
CONTENT_START = {"mkv": Fraction(0), "ts": AAC_PRIMING}
"""Source time of the gap variants' first real sample (re-encoded AAC presents its priming
first)."""
CHIRP_PRECISION = {"mkv": MATROSKA_PRECISION, "ts": Fraction(2, 48000)}
"""Largest chirp error after a corrected gap: the container's timestamp rounding (Matroska), or
the detection's two samples (MPEG-TS, whose 90 kHz gaps are whole 48 kHz samples)."""


@pytest.mark.req("AVE-REQ-012 AC-4")
@pytest.mark.parametrize("container", ["mkv", "ts"])
@pytest.mark.parametrize(
    ("gap", "corrected"),
    [
        pytest.param(Fraction(5, 1000), False, id="5ms"),
        pytest.param(Fraction(12, 1000), True, id="12ms"),
        pytest.param(Fraction(21, 1000), True, id="21ms"),
        pytest.param(Fraction(50, 1000), True, id="50ms"),
    ],
)
def test_audio_gaps_of_10_ms_or_more_stay_gaps_and_smaller_ones_are_jitter(
    std: StandardFixtures,
    artifacts_dir: Path,
    container: Literal["mkv", "ts"],
    gap: Fraction,
    corrected: bool,
) -> None:
    """AVE-REQ-012 AC-4 (ASM-008): a timestamp gap at 8 s inside an audio stream, in Matroska
    (PCM, millisecond timestamps) and in MPEG-TS (AAC, 90 kHz timestamps). A gap of 10 ms or
    more (12 ms, 21 ms - one lost AAC frame - and 50 ms) keeps every later sample at its
    timestamp, in the analysis extraction and in the render: silence of the gap's length fills
    it and chirps after it sit the gap later. A 5 ms gap is jitter: the samples stay contiguous
    (no zero run) and chirps after it sit exactly the gap earlier than their timestamps."""
    path = audio_gap_media(std, artifacts_dir / "derived", gap, container)
    precision, lead = TIMESTAMP_PRECISION[container], CONTENT_START[container]
    ((gap_end, measured),) = _packet_gaps(path)
    assert abs(measured - gap) <= precision
    # The gap starts at content time 8 s, or at the next PES packet (MPEG-TS): before any chirp.
    gap_start = gap_end - measured
    assert AUDIO_GAP_AT + lead - precision <= gap_start < AUDIO_GAP_AT + lead + Fraction(1, 5)
    events = [Fraction(frame, 60) + lead for frame in REFERENCE_EVENT_FRAMES]
    timestamps = [e + gap if e > gap_start else e for e in events]
    placed = timestamps if corrected else events
    tolerance = float(CHIRP_PRECISION[container])
    analysis = extract_analysis_audio(path)
    errors = _chirp_errors(analysis, [float(e) for e in placed])
    before = [error for error, e in zip(errors, events, strict=True) if e < gap_start]
    assert len(before) == 2
    assert max(before) <= 2 / 48000
    assert max(errors) <= tolerance
    second = 48000
    window = analysis[int((gap_start - 1) * second) : int((gap_end + 1) * second)]
    runs = _zero_runs(window, 8)
    if corrected:
        (run,) = runs  # the gap is filled with silence of its length
        assert abs(run - gap * second) <= precision * second + 1
    else:
        assert runs == []
    asset = describe_asset(path, asset_id=f"gap-{container}")
    source_in, duration = Fraction(15, 2), Fraction(8)
    clip = Clip(
        id="snd", track_id="a", asset_id=asset.id, kind="audio", timeline_start=Fraction(0),
        source_in=source_in, source_out=source_in + duration,
    )  # fmt: skip
    sequence = Sequence(
        id="gap", fps=FPS, canvas=Canvas(width=640, height=360), tracks=TRACKS, clips=(clip,)
    )
    output = artifacts_dir / f"audio-gap-{container}-{gap.numerator}-{gap.denominator}.mp4"
    _render(sequence, asset, output)
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    expected = [float(e - source_in) for e in placed if 0 <= e - source_in < duration]
    assert len(expected) == 2
    assert max(_chirp_errors(audio, expected)) <= tolerance


def _packet_deviations(path: Path) -> list[Fraction]:
    """Each 16-bit PCM audio packet's timestamp minus its position in a contiguous stream, with
    exact packet durations from the byte sizes (FFprobe's packet table, independent of the code
    under test; Matroska's printed durations are rounded to milliseconds)."""
    completed = run_tool(
        "ffprobe",
        [
            "-v", "error", "-select_streams", "a:0", "-show_entries",
            "stream=sample_rate,channels:packet=pts_time,size", "-of", "json", media_url(path),
        ],
        timeout=60,
    )  # fmt: skip
    data = json.loads(completed.stdout)
    (stream,) = data["streams"]
    bytes_per_second = 2 * int(stream["channels"]) * int(stream["sample_rate"])
    packets = [(Fraction(p["pts_time"]), Fraction(int(p["size"]), bytes_per_second))
               for p in data["packets"]]  # fmt: skip
    return _contiguity_deviations(packets)


@pytest.mark.req("AVE-REQ-012 AC-4")
def test_timestamp_jitter_never_inserts_silence(derived: DerivedMedia) -> None:
    """AVE-REQ-012 AC-4: audio packets whose timestamps wobble by up to 2 ms (with Matroska's
    millisecond rounding) are decoded as the contiguous stream they are: no silence is inserted
    anywhere inside it and every chirp stays sample-exact - jitter is not a gap."""
    deviations = _packet_deviations(derived.audio_jitter)
    largest = max(abs(d) for d in deviations)
    # Deviations are measured from the (itself jittered) first packet: up to twice the jitter
    # plus the millisecond rounding; at least 1.5 ms shows the jitter is really there.
    assert Fraction(3, 2000) <= largest <= 2 * AUDIO_JITTER + MATROSKA_PRECISION
    samples = extract_analysis_audio(derived.audio_jitter)
    interior = samples[: len(samples) - 48000 // 10]  # the stream's end may be padded
    assert _zero_runs(interior, 8) == []
    expected = [float(Fraction(frame, 60)) for frame in REFERENCE_EVENT_FRAMES]
    assert max(_chirp_errors(samples, expected)) <= 2 / 48000


JITTER_PLACEMENT_BOUND = Fraction(1, 100)
"""ASM-008: while the peak-to-peak spread of the timestamp jitter stays below the 10 ms tolerance,
a rendered clip of a jittered source sits less than 10 ms from the analysis placement: the
deviation of its anchor packet from the stream's first packet, at most that spread."""


@pytest.mark.req("AVE-REQ-012 AC-4")
@pytest.mark.parametrize("source_in", [Fraction(15, 2), Fraction(33, 2)], ids=["7.5", "16.5"])
def test_render_of_a_jittered_source_inserts_no_silence(
    derived: DerivedMedia, artifacts_dir: Path, tmp_path: Path, source_in: Fraction
) -> None:
    """AVE-REQ-012 AC-4 (ASM-008): a rendered clip of the jittered stream (a spread of at most
    5 ms) is anchored on the first decoded packet that ends after its seek point: its float PCM
    audio stage (the render's kept work directory) holds no inserted silence, and every chirp of
    the decoded export lies within the file's largest packet deviation from its first packet
    (plus two samples of detection) and below 10 ms of its time."""
    largest = max(abs(d) for d in _packet_deviations(derived.audio_jitter))
    asset = describe_asset(derived.audio_jitter, asset_id="jitter")
    duration = Fraction(8)
    clip = Clip(
        id="snd", track_id="a", asset_id=asset.id, kind="audio", timeline_start=Fraction(0),
        source_in=source_in, source_out=source_in + duration,
    )  # fmt: skip
    sequence = Sequence(
        id="jitter", fps=FPS, canvas=Canvas(width=640, height=360), tracks=TRACKS, clips=(clip,)
    )
    output = artifacts_dir / f"jitter-{source_in.numerator}-{source_in.denominator}.mp4"
    plan = compile_render_plan(sequence, {asset.id: asset}, profile=FAST)
    report = render(plan, output, work_dir=tmp_path, keep_work_dir=True)
    assert report.succeeded, report.error
    (stage,) = tmp_path.glob("render-*/audio.wav")
    pcm = decode_audio(stage, sample_rate=48000, channels=2)[:, 0]
    assert len(pcm) == duration * 48000
    assert _zero_runs(pcm, 8) == []
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    expected = [
        float(Fraction(frame, 60) - source_in)
        for frame in REFERENCE_EVENT_FRAMES
        if 0 <= Fraction(frame, 60) - source_in < duration
    ]
    assert len(expected) == 2
    errors = _chirp_errors(audio, expected)
    assert max(errors) <= float(largest) + 2 / 48000
    assert max(errors) < float(JITTER_PLACEMENT_BOUND)


@pytest.mark.req("AVE-REQ-012 AC-4")
def test_jitter_spread_just_below_10_ms_stays_contiguous_in_the_analysis(
    derived: DerivedMedia,
) -> None:
    """AVE-REQ-012 AC-4 (ASM-008): AAC packets in MPEG-TS whose timestamps sit alternately
    4.5 ms early (the first packet included) and 4.5 ms late spread 9 ms peak to peak, just
    below the 10 ms tolerance. Deviations count from the first decoded packet, an early one, so
    every late packet deviates the full 9 ms from the anchor of the analysis extraction, which
    keeps the samples contiguous: no inserted silence anywhere, every chirp sample-exact."""
    path = derived.audio_jitter_ts
    deviations = _contiguity_deviations(_packet_table(path))
    assert set(deviations) == {Fraction(0), 2 * WIDE_JITTER}  # the file's own timestamps
    samples = extract_analysis_audio(path)
    interior = samples[: len(samples) - 48000 // 10]  # the stream's end is padded
    assert _zero_runs(interior, 8) == []
    expected = [float(Fraction(frame, 60) + AAC_PRIMING) for frame in REFERENCE_EVENT_FRAMES]
    assert max(_chirp_errors(samples, expected)) <= 2 / 48000


@pytest.mark.req("AVE-REQ-012 AC-4")
@pytest.mark.parametrize(
    ("source_in", "anchor"),
    [
        pytest.param(Fraction(2), 2 * WIDE_JITTER, id="late-anchor"),
        pytest.param(Fraction(25, 2), Fraction(0), id="early-anchor"),
    ],
)
def test_render_of_a_jitter_spread_just_below_10_ms_inserts_no_silence(
    derived: DerivedMedia,
    artifacts_dir: Path,
    tmp_path: Path,
    source_in: Fraction,
    anchor: Fraction,
) -> None:
    """AVE-REQ-012 AC-4 (ASM-008): a rendered clip of the same 9 ms spread stream is anchored on
    the first decoded packet that ends after its seek point; each case's seek point lies in one
    packet only, which is then the anchor wherever the demuxer's seek lands: a late packet
    (every early packet then deviates 9 ms the other way) or an early one. The clip's float PCM
    audio stage holds no inserted silence, and every chirp of the decoded export sits exactly
    the anchor's deviation from the first packet (0 or 9 ms, at most the peak-to-peak spread)
    after its analysis placement."""
    path = derived.audio_jitter_ts
    packets = _packet_table(path)
    deviations = _contiguity_deviations(packets)
    asset = describe_asset(path, asset_id="jitter-ts")
    assert asset.probe.container_start_time == packets[0][0]  # source time 0: the first packet
    duration = Fraction(6)
    clip = Clip(
        id="snd", track_id="a", asset_id=asset.id, kind="audio", timeline_start=Fraction(0),
        source_in=source_in, source_out=source_in + duration,
    )  # fmt: skip
    sequence = Sequence(
        id="jitter-ts", fps=FPS, canvas=Canvas(width=640, height=360), tracks=TRACKS, clips=(clip,)
    )
    plan = compile_render_plan(sequence, {asset.id: asset}, profile=FAST)
    (planned,) = plan.audio
    seek = packets[0][0] + planned.seek
    holding = [
        deviation
        for (start, length), deviation in zip(packets, deviations, strict=True)
        if start <= seek < start + length
    ]
    assert holding == [anchor]  # one packet holds the seek point, of the kind the id names
    output = artifacts_dir / f"jitter-ts-{source_in.numerator}-{source_in.denominator}.mp4"
    report = render(plan, output, work_dir=tmp_path, keep_work_dir=True)
    assert report.succeeded, report.error
    (stage,) = tmp_path.glob("render-*/audio.wav")
    pcm = decode_audio(stage, sample_rate=48000, channels=2)[:, 0]
    assert len(pcm) == duration * 48000
    assert _zero_runs(pcm, 8) == []
    audio = decode_audio(output, sample_rate=48000, channels=1)[:, 0]
    content = [Fraction(frame, 60) + AAC_PRIMING - source_in for frame in REFERENCE_EVENT_FRAMES]
    expected = [float(time + anchor) for time in content if 0 <= time < duration]
    assert len(expected) == 2
    assert max(_chirp_errors(audio, expected)) <= 2 / 48000


@pytest.mark.req("AVE-REQ-012 AC-4")
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


@pytest.mark.req("AVE-REQ-012 AC-4")
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


@pytest.mark.req("AVE-REQ-004 AC-3", "AVE-REQ-004 AC-4")
def test_probe_reads_a_percent_name_as_that_file(literal_image: Path) -> None:
    """AVE-REQ-004 AC-3, AVE-REQ-004 AC-4: an untrusted name with ``%d`` never selects another
    file: the still image reports its own exact 640x360."""
    asset = describe_asset(literal_image, asset_id="literal")
    (video,) = asset.probe.video_streams
    assert (video.width, video.height) == (640, 360)
    assert asset.probe.format_name == "image2"


@pytest.mark.req("AVE-REQ-072 AC-3")
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
