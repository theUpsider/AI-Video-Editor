"""Timing variants of the standard fixture A, derived with FFmpeg for the source-timing tests.

Each variant changes one timing property by a known amount, so the expected frames and sample
positions follow from fixture A's manifest (frame ``n`` at ``n / 60`` s, chirps at the event
times) and the stated transformation - never from the compiler under test:

* ``late_audio`` - A's video unchanged; A's audio decoded and stored as PCM with its timestamps
  shifted by :data:`AUDIO_DELAY` (``-itsoffset``): the audio stream starts at 0.5 s while the
  container (and the video) start at 0. A chirp at event time ``e`` sits at ``e + 0.5``.
* ``late_video`` - A's video packets shifted by :data:`VIDEO_DELAY`, audio unchanged: source frame
  ``n`` is presented at ``n / 60 + 0.5``; nothing is presented before 0.5 s.
* ``vfr_gap`` - A's frames ``0 .. GAP_FIRST - 1`` and ``GAP_RESUME ..`` with their original
  timestamps: frame 59 at 59/60 s is followed by frame 240 at 4 s (a 3 s gap, longer than the
  renderer's one-second seek margin).
* ``late_aac_mp4`` / ``late_aac_ts`` - A's video and AAC audio stream-copied, the audio packets
  shifted by :data:`LATE_AAC_DELAY`, into MP4 (movie time scale 48 kHz, so the edit lists that
  carry the AAC priming and the shift stay sample-exact) and into MPEG-TS. The TS muxer moves
  every timestamp by its mux delay, so the container (and the video) start well after 0. In both
  files the audio stream starts :data:`LATE_AAC_DELAY` minus :data:`AAC_PRIMING` after the video
  and a chirp at event time ``e`` sits at ``e + LATE_AAC_DELAY`` after the video start.
* ``long_gop_ts`` - A's video re-encoded with one keyframe every :data:`LONG_GOP_FRAMES` frames
  (B-frames, no scene-cut keyframes) into MPEG-TS, a container without a keyframe index; frame
  ``n`` is presented ``n / 60`` after the video start.
* ``intra_ts`` - the first :data:`INTRA_SECONDS` of A's video re-encoded intra-only (every frame
  a keyframe) into MPEG-TS; frame ``n`` is presented ``n / 60`` after the video start.
* ``intra_ts_offset`` - the same with every timestamp moved by FFmpeg's ``-output_ts_offset``
  :data:`INTRA_TS_OFFSET`: the video (and container) start at 129000/90000 s, which FFprobe prints
  rounded as 1.433333.
* ``audio_jitter`` - A's audio alone as PCM in Matroska with every audio frame's timestamp moved
  by a pseudo-random amount within +-:data:`AUDIO_JITTER` (FFmpeg's seeded ``random``): the samples
  are contiguous, only their timestamps wobble, so a chirp at ``e`` stays at ``e``.

:func:`audio_gap_media` derives the timestamp-gap variants on demand: A's audio alone with every
timestamp from :data:`AUDIO_GAP_AT` on moved a given gap later, as PCM in Matroska or re-encoded
as AAC in MPEG-TS. In Matroska a chirp at ``e >= AUDIO_GAP_AT`` sits at ``e + gap``. In MPEG-TS
source time 0 is the first AAC packet, which presents the encoder's :data:`AAC_PRIMING` before
the first real sample, so every chirp sits :data:`AAC_PRIMING` later; the muxer groups several AAC
frames into one PES packet, so the gap shows at the start of the next PES packet, a fraction of a
second after ``AUDIO_GAP_AT`` and long before the next chirp.
"""

from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Literal

from ave.fixtures.standard import StandardFixtures
from ave.proc import media_url, run_tool

AUDIO_DELAY = Fraction(1, 2)
VIDEO_DELAY = Fraction(1, 2)
GAP_FIRST = 60
"""First dropped frame of ``vfr_gap``."""
GAP_RESUME = 240
"""First kept frame after the gap."""
LATE_AAC_DELAY = Fraction(4, 5)
AAC_PRIMING = Fraction(1024, 48000)
"""Encoder delay of FFmpeg's AAC encoder (one frame), presented before the first real sample."""
LONG_GOP_FRAMES = 1200
"""Keyframe interval of ``long_gop_ts`` (20 s at 60/1)."""
AUDIO_GAP_AT = Fraction(8)
"""Content time where the gap variants of :func:`audio_gap_media` move every later timestamp."""
AUDIO_JITTER = Fraction(2, 1000)
INTRA_SECONDS = 21
"""Length of the intra-only variants: long enough for a cut at 19.99 s."""
INTRA_TS_OFFSET = "0.033333"
"""``-output_ts_offset`` of ``intra_ts_offset``: FFmpeg's MPEG-TS start of 1.4 s becomes
129000/90000 s (the offset is rounded to the 90 kHz clock)."""

_BASE = ["-hide_banner", "-nostdin", "-v", "error", "-y"]
_TIMEOUT_S = 600.0


@dataclass(frozen=True)
class DerivedMedia:
    """Paths of the derived timing variants."""

    late_audio: Path
    late_video: Path
    vfr_gap: Path
    late_aac_mp4: Path
    late_aac_ts: Path
    long_gop_ts: Path
    audio_jitter: Path
    intra_ts: Path
    intra_ts_offset: Path


def _make(output: Path, args: list[str]) -> Path:
    if not output.is_file():
        staged = output.with_name(f".{output.name}.partial{output.suffix}")
        run_tool("ffmpeg", [*_BASE, *args, media_url(staged)], timeout=_TIMEOUT_S)
        staged.replace(output)
    return output


def derived_media(std: StandardFixtures, directory: Path) -> DerivedMedia:
    """Creates (once per directory) and returns the timing variants of fixture A."""
    directory.mkdir(parents=True, exist_ok=True)
    source = media_url(std.a.path)
    late_audio = _make(
        directory / "a-late-audio.mov",
        [
            "-i", source, "-itsoffset", str(float(AUDIO_DELAY)), "-i", source,
            "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "pcm_s16le", "-f", "mov",
        ],
    )  # fmt: skip
    late_video = _make(
        directory / "a-late-video.mp4",
        [
            "-itsoffset", str(float(VIDEO_DELAY)), "-i", source, "-i", source,
            "-map", "0:v:0", "-map", "1:a:0", "-c", "copy", "-f", "mp4",
        ],
    )  # fmt: skip
    vfr_gap = _make(
        directory / "a-vfr-gap.mp4",
        [
            "-i", source, "-an",
            "-vf", f"select='lt(n,{GAP_FIRST})+gte(n,{GAP_RESUME})'",
            "-fps_mode", "passthrough", "-c:v", "libx264", "-preset", "veryfast", "-crf", "12",
            "-pix_fmt", "yuv420p", "-f", "mp4",
        ],
    )  # fmt: skip
    late_aac = [
        "-i", source, "-itsoffset", str(float(LATE_AAC_DELAY)), "-i", source,
        "-map", "0:v:0", "-map", "1:a:0", "-c", "copy",
    ]  # fmt: skip
    late_aac_mp4 = _make(
        directory / "a-late-aac.mp4", [*late_aac, "-movie_timescale", "48000", "-f", "mp4"]
    )
    late_aac_ts = _make(directory / "a-late-aac.ts", [*late_aac, "-f", "mpegts"])
    long_gop_ts = _make(
        directory / "a-long-gop.ts",
        [
            "-i", source, "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "12",
            "-g", str(LONG_GOP_FRAMES), "-keyint_min", str(LONG_GOP_FRAMES),
            "-sc_threshold", "0", "-bf", "2", "-pix_fmt", "yuv420p", "-f", "mpegts",
        ],
    )  # fmt: skip
    jitter_s = float(2 * AUDIO_JITTER)
    audio_jitter = _make(
        directory / "a-audio-jitter.mkv",
        [
            "-i", source, "-vn", "-af", f"asetpts='PTS+(random(1)-0.5)*{jitter_s}/TB'",
            "-c:a", "pcm_s16le", "-f", "matroska",
        ],
    )  # fmt: skip
    intra = [
        "-i", source, "-an", "-t", str(INTRA_SECONDS), "-c:v", "libx264", "-preset", "veryfast",
        "-crf", "12", "-g", "1", "-bf", "0", "-pix_fmt", "yuv420p",
    ]  # fmt: skip
    intra_ts = _make(directory / "a-intra.ts", [*intra, "-f", "mpegts"])
    intra_ts_offset = _make(
        directory / "a-intra-offset.ts",
        [*intra, "-output_ts_offset", INTRA_TS_OFFSET, "-f", "mpegts"],
    )
    return DerivedMedia(
        late_audio=late_audio,
        late_video=late_video,
        vfr_gap=vfr_gap,
        late_aac_mp4=late_aac_mp4,
        late_aac_ts=late_aac_ts,
        long_gop_ts=long_gop_ts,
        audio_jitter=audio_jitter,
        intra_ts=intra_ts,
        intra_ts_offset=intra_ts_offset,
    )


def audio_gap_media(
    std: StandardFixtures, directory: Path, gap: Fraction, container: Literal["mkv", "ts"]
) -> Path:
    """A's audio alone with every timestamp from :data:`AUDIO_GAP_AT` on moved ``gap`` later:
    16-bit PCM in Matroska (``mkv``) or AAC in MPEG-TS (``ts``), created once per directory."""
    directory.mkdir(parents=True, exist_ok=True)
    codec = ["-c:a", "pcm_s16le", "-f", "matroska"]
    if container == "ts":
        codec = ["-c:a", "aac", "-b:a", "256k", "-f", "mpegts"]
    shift = f"PTS+{gap.numerator}/{gap.denominator}/TB"
    name = f"a-audio-gap-{gap.numerator}-{gap.denominator}.{container}"
    return _make(
        directory / name,
        [
            "-i", media_url(std.a.path), "-vn",
            "-af", f"asetpts='if(gte(T,{int(AUDIO_GAP_AT)}),{shift},PTS)'", *codec,
        ],
    )  # fmt: skip
