"""The specification's standard synthetic travel composition and the probe/timing fixtures.

Ground truth (ACCEPTANCE_TESTS.md, standard composition):

* **A** - square 1080x1080 at 60/1, source ``[0, 30)``, 48 kHz audio; the synchronization reference.
* **B** - square 1080x1080 at 60/1, source ``[0, 25)``, starts two seconds after A
  (``a_B = 2, b_B = 1``), 44.1 kHz audio with a different gain and added noise.
* **C** - 1920x1080 at 60/1, six seconds, 48 kHz audio.

A and B share nonperiodic events at reference frames :data:`REFERENCE_EVENT_FRAMES` (60 fps grid),
each a one-frame white flash and a chirp in both audio tracks. Pilot tones identify the sources in
a mix: A 1000 Hz, B 1700 Hz, C 2600 Hz. C has its own events.
"""

from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction

from ave.fixtures.generate import AudioSpec, Fixture, FixtureSpec, VideoSpec, ensure_fixture

__all__ = [
    "B_OFFSET",
    "COLOR_A",
    "COLOR_B",
    "COLOR_C",
    "C_EVENT_FRAMES",
    "PILOT_HZ",
    "REFERENCE_EVENT_FRAMES",
    "StandardFixtures",
    "rate_fixture_spec",
    "standard_fixture_specs",
    "standard_fixtures",
    "timing_fixture_specs",
]

FPS = Fraction(60)
REFERENCE_EVENT_FRAMES = (193, 354, 566, 783, 1063, 1282, 1488)
"""Shared event frames on the reference (A) clock at 60 fps."""
B_OFFSET = Fraction(2)
"""Ground-truth ``a_B``: B's source time 0 is reference time 2 s."""
C_EVENT_FRAMES = (67, 211, 302)
PILOT_HZ = {"a": 1000.0, "b": 1700.0, "c": 2600.0}
COLOR_A = (200, 50, 50)
COLOR_B = (50, 90, 200)
COLOR_C = (50, 170, 70)


def _events(frames: tuple[int, ...], shift: int = 0) -> tuple[Fraction, ...]:
    return tuple(Fraction(frame - shift) / FPS for frame in frames)


def standard_fixture_specs() -> dict[str, FixtureSpec]:
    """Specifications of A, B, C and the 2560x1440 60/1 clip."""
    b_shift = int(B_OFFSET * FPS)
    return {
        "a": FixtureSpec(
            name="std-a",
            description="Standard composition source A: square, reference clock, 48 kHz",
            duration=Fraction(30),
            video=VideoSpec(width=1080, height=1080, fps=FPS, color=COLOR_A),
            audio=(
                AudioSpec(sample_rate=48000, pilot_hz=PILOT_HZ["a"], noise_rms=0.0005, seed=11),
            ),
            events=_events(REFERENCE_EVENT_FRAMES),
        ),
        "b": FixtureSpec(
            name="std-b",
            description="Standard composition source B: square, starts 2 s after A, 44.1 kHz, "
            "lower gain and noise",
            duration=Fraction(25),
            video=VideoSpec(width=1080, height=1080, fps=FPS, color=COLOR_B),
            audio=(
                AudioSpec(
                    sample_rate=44100,
                    pilot_hz=PILOT_HZ["b"],
                    gain=0.45,
                    noise_rms=0.01,
                    seed=23,
                ),
            ),
            events=_events(REFERENCE_EVENT_FRAMES, shift=b_shift),
        ),
        "c": FixtureSpec(
            name="std-c",
            description="Standard composition source C: 16:9 joint shot, 48 kHz",
            duration=Fraction(6),
            video=VideoSpec(width=1920, height=1080, fps=FPS, color=COLOR_C),
            audio=(
                AudioSpec(sample_rate=48000, pilot_hz=PILOT_HZ["c"], noise_rms=0.0005, seed=37),
            ),
            events=_events(C_EVENT_FRAMES),
        ),
        "qhd": FixtureSpec(
            name="qhd-2560x1440-60",
            description="Approximately 2K (exactly 2560x1440) at exactly 60/1 with audio",
            duration=Fraction(4),
            video=VideoSpec(width=2560, height=1440, fps=FPS, color=(120, 120, 40)),
            audio=(AudioSpec(sample_rate=48000, channels=2, pilot_hz=440.0, seed=5),),
            events=(Fraction(1), Fraction(37, 20)),
        ),
    }


@dataclass(frozen=True)
class StandardFixtures:
    """Generated standard composition sources."""

    a: Fixture
    b: Fixture
    c: Fixture
    qhd: Fixture


def standard_fixtures() -> StandardFixtures:
    """Generates (or reuses) the standard composition fixtures."""
    specs = standard_fixture_specs()
    return StandardFixtures(
        a=ensure_fixture(specs["a"]),
        b=ensure_fixture(specs["b"]),
        c=ensure_fixture(specs["c"]),
        qhd=ensure_fixture(specs["qhd"]),
    )


def rate_fixture_spec(fps: Fraction, name: str) -> FixtureSpec:
    """A one-second 160x90 clip at an exact frame rate (AT-03 rate matrix)."""
    return FixtureSpec(
        name=name,
        description=f"Exact-rate probe clip at {fps.numerator}/{fps.denominator} fps",
        duration=Fraction(1),
        video=VideoSpec(width=160, height=90, fps=fps, color=(90, 90, 90)),
    )


def timing_fixture_specs() -> dict[str, FixtureSpec]:
    """Probe and timing fixtures: rates, VFR, rotation, SAR, multi/no/only audio, still image."""
    specs = {
        f"rate-{label}": rate_fixture_spec(fps, f"rate-{label}")
        for label, fps in (
            ("24", Fraction(24)),
            ("25", Fraction(25)),
            ("30", Fraction(30)),
            ("30000-1001", Fraction(30000, 1001)),
            ("60", Fraction(60)),
            ("60000-1001", Fraction(60000, 1001)),
        )
    }
    specs["vfr"] = FixtureSpec(
        name="vfr-barcode",
        description="Variable frame rate (irregular PTS on a 1/120 s grid) with frame barcodes",
        duration=Fraction(6),
        video=VideoSpec(width=320, height=240, fps=Fraction(60), color=(150, 60, 150), vfr=True),
    )
    specs["rotated"] = FixtureSpec(
        name="rotated-portrait",
        description="Landscape-coded 320x180 with a 90 degree display rotation (portrait display)",
        duration=Fraction(1),
        video=VideoSpec(width=320, height=180, fps=Fraction(30), color=(60, 60, 160), rotation=90),
        audio=(AudioSpec(sample_rate=48000, pilot_hz=500.0),),
    )
    specs["anamorphic"] = FixtureSpec(
        name="anamorphic-sar",
        description="1440x1080 coded with a 4:3 sample aspect ratio (1920x1080 display)",
        duration=Fraction(1),
        video=VideoSpec(
            width=1440, height=1080, fps=Fraction(25), color=(100, 140, 100), sar=Fraction(4, 3)
        ),
    )
    specs["multi-audio"] = FixtureSpec(
        name="multi-audio",
        description="Video with two audio streams (48 kHz mono, 44.1 kHz stereo)",
        duration=Fraction(1),
        video=VideoSpec(width=160, height=90, fps=Fraction(30), color=(40, 40, 40)),
        audio=(
            AudioSpec(sample_rate=48000, channels=1, pilot_hz=700.0),
            AudioSpec(sample_rate=44100, channels=2, pilot_hz=900.0),
        ),
    )
    specs["no-audio"] = FixtureSpec(
        name="no-audio",
        description="Video without any audio stream",
        duration=Fraction(1),
        video=VideoSpec(width=160, height=90, fps=Fraction(30), color=(10, 120, 10)),
    )
    specs["audio-only"] = FixtureSpec(
        name="audio-only",
        description="AAC audio-only file",
        duration=Fraction(2),
        container="m4a",
        audio=(AudioSpec(sample_rate=48000, channels=2, pilot_hz=330.0),),
    )
    specs["still"] = FixtureSpec(
        name="still-image",
        description="640x360 still picture with barcode index 0",
        duration=Fraction(1),
        container="png",
        video=VideoSpec(width=640, height=360, fps=Fraction(1), color=(230, 180, 30)),
    )
    return specs
