"""Self-checks of the synthetic fixtures: the ground truth must hold in the actual media."""

from __future__ import annotations

from fractions import Fraction

import pytest

from ave.fixtures.barcode import barcode_layout
from ave.fixtures.generate import SYNTHETIC_LABEL, Fixture, ensure_fixture
from ave.fixtures.standard import REFERENCE_EVENT_FRAMES, StandardFixtures
from ave.media.asset import sha256_file
from ave.render.validate import decode_audio, iter_video_frames
from tests.oracles import Placement, detect_chirps, is_flash, match_events, patch_rgb, read_barcode

pytestmark = pytest.mark.media


def _scan(fixture: Fixture) -> tuple[list[int | None], list[int]]:
    spec = fixture.spec.video
    assert spec is not None
    factor = 4 if spec.width >= 1000 else 1
    layout = barcode_layout(spec.width, spec.height)
    identity = Placement(scale=1.0, x=0.0, y=0.0)
    indices, flashes = [], []
    frames = iter_video_frames(
        fixture.path, width=spec.width // factor, height=spec.height // factor
    )
    for number, frame in enumerate(frames):
        indices.append(read_barcode(frame, layout, identity, factor))
        if is_flash(patch_rgb(frame, layout, identity, factor)):
            flashes.append(number)
    return indices, flashes


@pytest.mark.parametrize("name", ["a", "b", "c"])
def test_barcodes_and_flashes_match_the_manifest(std: StandardFixtures, name: str) -> None:
    """Every decoded frame shows its own index; flashes sit exactly on the manifest events."""
    fixture = getattr(std, name)
    assert fixture.manifest["synthetic"] is True
    assert fixture.manifest["label"] == SYNTHETIC_LABEL
    assert sha256_file(fixture.path) == fixture.manifest["sha256"]
    indices, flashes = _scan(fixture)
    assert indices == list(range(len(indices)))
    assert len(indices) == fixture.spec.duration * 60
    events = [Fraction(e["num"], e["den"]) for e in fixture.manifest["events"]]
    assert flashes == [int(e * 60) for e in events]
    if name == "b":
        assert flashes == [frame - 120 for frame in REFERENCE_EVENT_FRAMES]


@pytest.mark.parametrize("name", ["a", "b", "c"])
def test_chirps_match_the_manifest(std: StandardFixtures, name: str) -> None:
    """Decoded audio holds a chirp onset at every manifest event (within 1 ms)."""
    fixture = getattr(std, name)
    rate = fixture.spec.audio[0].sample_rate
    audio = decode_audio(fixture.path, sample_rate=rate, channels=1)[:, 0]
    events = [e["num"] / e["den"] for e in fixture.manifest["events"]]
    pairs, missing, unexpected = match_events(detect_chirps(audio, rate), events, 0.001)
    assert not missing
    assert not unexpected
    assert len(pairs) == len(events)


def test_vfr_fixture_frames_follow_their_timestamps(timing_fixtures: dict[str, Fixture]) -> None:
    """The VFR fixture's barcodes count frames in presentation order."""
    indices, _ = _scan(timing_fixtures["vfr"])
    assert indices == list(range(len(timing_fixtures["vfr"].manifest["vfr_frame_ticks"])))


def test_fixtures_are_cached_by_specification(std: StandardFixtures) -> None:
    """A second request reuses the cached file (same path, checksum and modification time)."""
    before = std.c.path.stat().st_mtime_ns
    again = ensure_fixture(std.c.spec)
    assert again.path == std.c.path
    assert again.sha256 == std.c.sha256
    assert again.path.stat().st_mtime_ns == before
