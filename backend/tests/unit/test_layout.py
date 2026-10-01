"""Layout geometry: AVE-REQ-018 (canvas), AVE-REQ-019 (fit), AVE-REQ-020 (split screen)."""

from __future__ import annotations

import random
from fractions import Fraction

import pytest
from pydantic import ValidationError

from ave.domain.layout import compute_layer_geometry, region_pixels, split_regions
from ave.domain.model import FULL_FRAME, Canvas, Clip, NormRect
from ave.errors import RenderPlanningError
from ave.render.profile import OutputProfile

HD = Canvas()


def test_contain_split_of_square_sources_is_960_at_y60() -> None:
    """AVE-REQ-020 AC-1: two square sources in contain mode are 960x960 with 60 px bars."""
    left, right = split_regions()
    for region, x in ((left, 0), (right, 960)):
        geometry = compute_layer_geometry(HD, region, 1080, 1080, "contain")
        assert (geometry.scaled_width, geometry.scaled_height) == (960, 960)
        assert geometry.position == (x, 60)
        assert geometry.crop.width == 960
        assert geometry.crop.height == 960
        assert geometry.region.height - geometry.crop.height == 120  # 60 px above and below


def test_cover_split_crops_instead_of_stretching() -> None:
    """AVE-REQ-020 AC-2 / AVE-REQ-019 AC-1: cover fills 960x1080 by cropping a 1080x1080 image."""
    left, right = split_regions()
    for region, x in ((left, 0), (right, 960)):
        geometry = compute_layer_geometry(HD, region, 1080, 1080, "cover")
        assert (geometry.scaled_width, geometry.scaled_height) == (1080, 1080)
        assert (geometry.crop.width, geometry.crop.height) == (960, 1080)
        assert (geometry.crop.x, geometry.crop.y) == (60, 0)
        assert geometry.position == (x, 0)
        assert geometry.scale_x == geometry.scale_y == 1


@pytest.mark.parametrize(
    ("focus", "crop_x"), [(Fraction(0), 0), (Fraction(1, 4), 30), (Fraction(1), 120)]
)
def test_cover_crop_follows_the_focus_point(focus: Fraction, crop_x: int) -> None:
    """AVE-REQ-019 AC-4 / AVE-REQ-020 AC-2: the crop is adjustable through the focus point."""
    left, _ = split_regions()
    geometry = compute_layer_geometry(HD, left, 1080, 1080, "cover", focus_x=focus)
    assert geometry.crop.x == crop_x


def test_full_width_16_9_source_fills_the_canvas() -> None:
    """AVE-REQ-021 AC-1 geometry: a 1920x1080 source contained full-frame fills 1920x1080."""
    geometry = compute_layer_geometry(HD, FULL_FRAME, 1920, 1080, "contain")
    assert geometry.placed.width == 1920
    assert geometry.placed.height == 1080
    assert geometry.position == (0, 0)


def test_fit_never_changes_aspect_beyond_rounding() -> None:
    """AVE-REQ-019 AC-1/AC-2: contain and cover keep the source aspect (property test)."""
    rng = random.Random(19)
    for _ in range(3000):
        canvas = Canvas(width=2 * rng.randrange(160, 1920), height=2 * rng.randrange(90, 1080))
        x = Fraction(rng.randrange(0, 50), 100)
        y = Fraction(rng.randrange(0, 50), 100)
        region = NormRect(
            x=x, y=y, w=Fraction(rng.randrange(10, 50), 100), h=Fraction(rng.randrange(10, 50), 100)
        )
        sw, sh = rng.randrange(64, 4096), rng.randrange(64, 4096)
        for fit in ("contain", "cover"):
            g = compute_layer_geometry(canvas, region, sw, sh, fit)
            aspect = Fraction(g.scaled_width, g.scaled_height)
            source = Fraction(sw, sh)
            tolerance = Fraction(2, min(g.scaled_width, g.scaled_height)) * 2
            assert abs(aspect / source - 1) <= tolerance
            assert g.scaled_width % 2 == 0
            assert g.scaled_height % 2 == 0
            assert g.position[0] % 2 == 0
            assert g.position[1] % 2 == 0
            if fit == "contain":
                # The whole image is inside the region.
                assert g.region.x <= g.position[0]
                assert g.placed.right <= g.region.right
                assert g.region.y <= g.position[1]
                assert g.placed.bottom <= g.region.bottom
            else:
                # The region is filled and the crop lies inside the scaled image.
                assert (g.crop.width, g.crop.height) == (g.region.width, g.region.height)
                assert 0 <= g.crop.x <= g.scaled_width - g.crop.width
                assert 0 <= g.crop.y <= g.scaled_height - g.crop.height


def test_default_fit_is_contain_and_stretch_is_explicit() -> None:
    """AVE-REQ-019 AC-2: no default operation stretches a source."""
    clip = Clip(
        id="c",
        track_id="v",
        asset_id="a",
        kind="video",
        timeline_start=Fraction(0),
        source_in=Fraction(0),
        source_out=Fraction(1),
    )
    assert clip.fit == "contain"
    stretched = compute_layer_geometry(HD, FULL_FRAME, 1080, 1080, "stretch")
    assert stretched.scale_x != stretched.scale_y  # only an explicit request distorts


def test_normalized_regions_map_to_even_pixels() -> None:
    """AVE-REQ-019 AC-3: transforms use normalized canvas coordinates with documented rounding."""
    rect = region_pixels(
        HD, NormRect(x=Fraction(1, 3), y=Fraction(1, 4), w=Fraction(1, 3), h=Fraction(1, 2))
    )
    assert (rect.x, rect.y, rect.width, rect.height) == (640, 270, 640, 540)
    with pytest.raises(ValidationError):
        NormRect(x=Fraction(3, 4), w=Fraction(1, 2))


def test_split_divider_and_gap_are_configurable() -> None:
    """AVE-REQ-020 AC-3: the divider position and a background gap are adjustable."""
    left, right = split_regions(divider=Fraction(2, 5), gap=Fraction(1, 48))
    assert region_pixels(HD, left).right == 748
    assert region_pixels(HD, right).x == 788
    g = compute_layer_geometry(HD, left, 1080, 1080, "contain")
    assert g.placed.right <= 748
    with pytest.raises(ValueError, match="no room"):
        split_regions(divider=Fraction(1, 100), gap=Fraction(1, 10))


def test_canvas_defaults_and_presets() -> None:
    """AVE-REQ-018 AC-1: 1920x1080 by default; 1:1, 9:16 and custom sizes are selectable."""
    assert (HD.width, HD.height) == (1920, 1080)
    assert HD.aspect == Fraction(16, 9)
    assert Canvas(width=1080, height=1080).aspect == 1
    assert Canvas(width=1080, height=1920).aspect == Fraction(9, 16)
    assert Canvas(width=2560, height=1440).aspect == Fraction(16, 9)


def test_odd_canvas_is_rejected_with_an_explanation() -> None:
    """AVE-REQ-018 AC-4: encoder constraints are explained, never silently fixed by stretching."""
    with pytest.raises(RenderPlanningError) as error:
        OutputProfile().check_canvas(Canvas(width=1081, height=1080))
    assert "1080 or 1082" in error.value.message
    assert "never stretched" in error.value.message
    OutputProfile().check_canvas(Canvas(width=1080, height=1920))
