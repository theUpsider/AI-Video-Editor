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
"""

from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path

from ave.fixtures.standard import StandardFixtures
from ave.proc import media_url, run_tool

AUDIO_DELAY = Fraction(1, 2)
VIDEO_DELAY = Fraction(1, 2)
GAP_FIRST = 60
"""First dropped frame of ``vfr_gap``."""
GAP_RESUME = 240
"""First kept frame after the gap."""

_BASE = ["-hide_banner", "-nostdin", "-v", "error", "-y"]
_TIMEOUT_S = 600.0


@dataclass(frozen=True)
class DerivedMedia:
    """Paths of the derived timing variants."""

    late_audio: Path
    late_video: Path
    vfr_gap: Path


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
    return DerivedMedia(late_audio=late_audio, late_video=late_video, vfr_gap=vfr_gap)
