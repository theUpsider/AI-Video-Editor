"""Pure layout geometry: where and how large a source appears on the canvas (AVE-REQ-019/020).

Given the canvas, a clip's normalized region, the source's display size (after sample aspect ratio
and rotation), the fit mode and the focus point, :func:`compute_layer_geometry` returns integer
pixel values that the renderer applies literally (``scale`` -> ``crop`` -> overlay at
``position``). Preview and export share these semantics.

Fit modes
---------
* ``contain`` - uniform scale ``min(rw/sw, rh/sh)``; the whole source is visible and centered;
  uncovered parts of the region show the background.
* ``cover`` - uniform scale ``max(rw/sw, rh/sh)``; the region is filled and the overflow is cropped
  around the focus point (``focus = 0`` keeps the left/top edge, ``1`` the right/bottom edge).
* ``stretch`` - non-uniform scale to the region; changes the aspect ratio and is never a default.

Rounding (documented contract)
------------------------------
All intermediate values are exact rationals; each pixel value is rounded once:

1. Region edges: ``round_half_up(fraction * canvas_size)``, then snapped to the alignment grid
   (``align = 2`` for 4:2:0 chroma subsampling, so every size and offset is even).
2. Scaled size: ``contain`` rounds ``source * scale`` half-up to the alignment grid and clamps it to
   the region; ``cover`` rounds up to the grid so the region is always fully covered.
3. Offsets: the ``contain`` centering offset and the ``cover`` crop offset are rounded down to the
   alignment grid, which keeps the image inside the region.

Rounding changes a dimension by less than one alignment step, so the aspect ratio error is below
``align / size`` (0.2 % for a 960-pixel side). Examples from the specification: a 1080x1080 source
contained in the left half of 1920x1080 becomes 960x960 at (0, 60); in the right half 960x960 at
(960, 60); covered, it is scaled to 1080x1080 and cropped to 960x1080 at x offset 60.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from fractions import Fraction

from ave.domain.model import Canvas, Fit, NormRect
from ave.timebase import round_half_up

__all__ = ["LayerGeometry", "PixelRect", "compute_layer_geometry", "region_pixels", "split_regions"]


@dataclass(frozen=True)
class PixelRect:
    """An integer pixel rectangle (top-left ``x, y``, ``width x height``)."""

    x: int
    y: int
    width: int
    height: int

    @property
    def right(self) -> int:
        """Exclusive right edge."""
        return self.x + self.width

    @property
    def bottom(self) -> int:
        """Exclusive bottom edge."""
        return self.y + self.height


@dataclass(frozen=True)
class LayerGeometry:
    """How one source is placed: scale to ``scaled_*``, crop ``crop``, overlay at ``position``."""

    fit: Fit
    region: PixelRect
    scale_x: Fraction
    """Exact horizontal scale factor before rounding (equal to ``scale_y`` unless stretched)."""
    scale_y: Fraction
    scaled_width: int
    scaled_height: int
    crop: PixelRect
    """Crop rectangle in scaled-image coordinates (the full image for contain/stretch)."""
    position: tuple[int, int]
    """Canvas position of the cropped image's top-left corner."""

    @property
    def placed(self) -> PixelRect:
        """Canvas rectangle actually covered by the source image."""
        return PixelRect(self.position[0], self.position[1], self.crop.width, self.crop.height)


def _snap(value: Fraction | int, align: int) -> int:
    return align * round_half_up(Fraction(value) / align)


def _floor_to(value: Fraction | int, align: int) -> int:
    return align * math.floor(Fraction(value) / align)


def _ceil_to(value: Fraction | int, align: int) -> int:
    return align * math.ceil(Fraction(value) / align)


def region_pixels(canvas: Canvas, region: NormRect, *, align: int = 2) -> PixelRect:
    """Pixel rectangle of a normalized region on ``canvas`` (edges snapped to ``align``)."""
    x0 = _snap(round_half_up(region.x * canvas.width), align)
    y0 = _snap(round_half_up(region.y * canvas.height), align)
    x1 = _snap(round_half_up((region.x + region.w) * canvas.width), align)
    y1 = _snap(round_half_up((region.y + region.h) * canvas.height), align)
    x1 = min(max(x1, x0 + align), _floor_to(canvas.width, align))
    y1 = min(max(y1, y0 + align), _floor_to(canvas.height, align))
    return PixelRect(x0, y0, x1 - x0, y1 - y0)


def compute_layer_geometry(
    canvas: Canvas,
    region: NormRect,
    source_width: Fraction | int,
    source_height: Fraction | int,
    fit: Fit,
    focus_x: Fraction = Fraction(1, 2),
    focus_y: Fraction = Fraction(1, 2),
    *,
    align: int = 2,
) -> LayerGeometry:
    """Places a source of display size ``source_width x source_height`` into ``region``."""
    sw, sh = Fraction(source_width), Fraction(source_height)
    if sw <= 0 or sh <= 0:
        raise ValueError("source dimensions must be positive")
    if not (0 <= focus_x <= 1 and 0 <= focus_y <= 1):
        raise ValueError("focus must lie in [0, 1]")
    rect = region_pixels(canvas, region, align=align)
    rw, rh = rect.width, rect.height

    if fit == "stretch":
        return LayerGeometry(
            fit=fit,
            region=rect,
            scale_x=rw / sw,
            scale_y=rh / sh,
            scaled_width=rw,
            scaled_height=rh,
            crop=PixelRect(0, 0, rw, rh),
            position=(rect.x, rect.y),
        )

    if fit == "contain":
        scale = min(rw / sw, rh / sh)
        width = min(max(_snap(sw * scale, align), align), rw)
        height = min(max(_snap(sh * scale, align), align), rh)
        position = (
            rect.x + _floor_to(Fraction(rw - width, 2), align),
            rect.y + _floor_to(Fraction(rh - height, 2), align),
        )
        return LayerGeometry(
            fit=fit,
            region=rect,
            scale_x=scale,
            scale_y=scale,
            scaled_width=width,
            scaled_height=height,
            crop=PixelRect(0, 0, width, height),
            position=position,
        )

    if fit == "cover":
        scale = max(rw / sw, rh / sh)
        width = max(_ceil_to(sw * scale, align), rw)
        height = max(_ceil_to(sh * scale, align), rh)
        crop_x = min(_floor_to(focus_x * (width - rw), align), width - rw)
        crop_y = min(_floor_to(focus_y * (height - rh), align), height - rh)
        return LayerGeometry(
            fit=fit,
            region=rect,
            scale_x=scale,
            scale_y=scale,
            scaled_width=width,
            scaled_height=height,
            crop=PixelRect(crop_x, crop_y, rw, rh),
            position=(rect.x, rect.y),
        )

    raise ValueError(f"unknown fit mode {fit!r}")


def split_regions(
    divider: Fraction = Fraction(1, 2), gap: Fraction = Fraction(0)
) -> tuple[NormRect, NormRect]:
    """Left and right regions of a two-perspective split (AVE-REQ-020).

    ``divider`` is the horizontal position of the split (0..1), ``gap`` the total horizontal gap
    (canvas fraction) centered on the divider, which shows the background.
    """
    half_gap = Fraction(gap) / 2
    left_w = Fraction(divider) - half_gap
    right_x = Fraction(divider) + half_gap
    if left_w <= 0 or right_x >= 1:
        raise ValueError("divider and gap leave no room for both perspectives")
    zero, one = Fraction(0), Fraction(1)
    return (
        NormRect(x=zero, y=zero, w=left_w, h=one),
        NormRect(x=right_x, y=zero, w=one - right_x, h=one),
    )
