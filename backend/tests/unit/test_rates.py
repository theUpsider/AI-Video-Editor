"""Auto frame-rate resolution: AVE-REQ-018 AC-2 and AC-3."""

from __future__ import annotations

from fractions import Fraction

import pytest

from ave.domain.rates import PROVISIONAL_FPS, resolve_auto_frame_rate, update_auto_frame_rate
from tests.assets import fake_asset

NTSC60 = Fraction(60000, 1001)


@pytest.mark.req("AVE-REQ-018 AC-3")
def test_no_source_gives_a_provisional_30() -> None:
    """AVE-REQ-018 AC-3: without sources the project shows a provisional 30 fps."""
    resolution = resolve_auto_frame_rate([])
    assert resolution.fps == PROVISIONAL_FPS
    assert resolution.provisional


@pytest.mark.req("AVE-REQ-018 AC-2")
def test_reference_rate_is_kept_exactly() -> None:
    """AVE-REQ-018 AC-2: 60/1 stays 60/1 and 60000/1001 stays 60000/1001."""
    a60 = fake_asset("A", fps=Fraction(60))
    b_ntsc = fake_asset("B", fps=NTSC60, time_base=Fraction(1, 60000), duration=Fraction(100))
    assert resolve_auto_frame_rate([a60, b_ntsc], reference_asset_id="A").fps == 60
    resolved = resolve_auto_frame_rate([a60, b_ntsc], reference_asset_id="B")
    assert resolved.fps == NTSC60
    assert resolved.fps != 60
    # Without a reference the dominant rate (by duration) wins: B has 100 s, A 30 s.
    assert resolve_auto_frame_rate([a60, b_ntsc]).fps == NTSC60


@pytest.mark.req("AVE-REQ-018 AC-3")
def test_resolved_rate_does_not_change_after_another_import() -> None:
    """AVE-REQ-018 AC-3: once resolved, a later import cannot silently change project timing."""
    provisional = update_auto_frame_rate(None, [])
    assert provisional.provisional
    first = update_auto_frame_rate(provisional, [fake_asset("A", fps=Fraction(60))])
    assert (first.fps, first.provisional, first.source_asset_id) == (Fraction(60), False, "A")
    later = update_auto_frame_rate(
        first, [fake_asset("A"), fake_asset("C", fps=Fraction(25), duration=Fraction(900))]
    )
    assert later is first
