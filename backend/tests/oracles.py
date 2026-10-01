"""Independent test oracles for decoded media.

Nothing here imports the compiler, the render module's planning code or the layout geometry:
expected positions come from the specification's numbers and the fixture manifests, and
measurements come from decoded pixels and samples.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

import numpy as np
import numpy.typing as npt
from scipy import signal as sps

from ave.fixtures.barcode import CELLS, BarcodeLayout, decode_bits
from ave.fixtures.generate import chirp

Frame = npt.NDArray[np.uint8]


@dataclass(frozen=True)
class Placement:
    """Where a source image appears in a decoded frame: ``out = offset + source * scale``.

    ``crop_x``/``crop_y`` are subtracted in scaled-source pixels (cover mode crop).
    """

    scale: float
    x: float
    y: float
    crop_x: float = 0.0
    crop_y: float = 0.0

    def map(self, sx: float, sy: float, analysis_factor: float) -> tuple[float, float]:
        """Analysis-frame coordinates of source pixel ``(sx, sy)``."""
        ox = self.x + sx * self.scale - self.crop_x
        oy = self.y + sy * self.scale - self.crop_y
        return ox / analysis_factor, oy / analysis_factor


def sample_patch(frame: Frame, x: float, y: float, radius: int = 2) -> npt.NDArray[np.float64]:
    """Mean RGB of a small square around ``(x, y)``."""
    cx, cy = round(x), round(y)
    region = frame[max(0, cy - radius) : cy + radius + 1, max(0, cx - radius) : cx + radius + 1]
    return np.asarray(region.reshape(-1, 3).mean(axis=0), dtype=np.float64)


def read_barcode(
    frame: Frame, layout: BarcodeLayout, placement: Placement, analysis_factor: float
) -> int | None:
    """Frame index encoded in the barcode at ``placement`` (``None`` when unreadable)."""
    bits = []
    for cell in range(CELLS):
        sx, sy = layout.cell_center(cell)
        x, y = placement.map(sx, sy, analysis_factor)
        bits.append(1 if sample_patch(frame, x, y).mean() > 128 else 0)
    return decode_bits(bits)


def patch_rgb(
    frame: Frame, layout: BarcodeLayout, placement: Placement, analysis_factor: float
) -> npt.NDArray[np.float64]:
    """Mean color of the source's background patch."""
    sx, sy = layout.patch_center
    x, y = placement.map(sx, sy, analysis_factor)
    return sample_patch(frame, x, y, radius=3)


def is_flash(rgb: npt.NDArray[np.float64]) -> bool:
    """True when a background patch is white (flash frame)."""
    return bool(rgb.min() > 225)


def nearest_color(rgb: npt.NDArray[np.float64], palette: dict[str, tuple[int, int, int]]) -> str:
    """Name of the palette entry closest to ``rgb``."""
    return min(palette, key=lambda name: float(np.sum((rgb - np.array(palette[name])) ** 2)))


def detect_chirps(
    samples: npt.NDArray[np.float32], rate: int, relative_threshold: float = 0.35
) -> list[float]:
    """Onset times (s) of the fixture chirp found by matched filtering a mono signal."""
    template = chirp(rate)
    response = np.abs(sps.correlate(samples.astype(np.float64), template, mode="valid"))
    response /= float(np.dot(template, template))
    threshold = relative_threshold * float(response.max()) if response.size else 0.0
    peaks, _ = sps.find_peaks(response, height=threshold, distance=int(0.1 * rate))
    return [float(p) / rate for p in peaks]


def tone_amplitude(samples: npt.NDArray[np.float32], rate: int, frequency: float) -> float:
    """Amplitude of a sinusoid at ``frequency`` (Hann-windowed projection)."""
    data = samples.astype(np.float64)
    window = np.hanning(len(data))
    phase = np.exp(-2j * np.pi * frequency * np.arange(len(data)) / rate)
    return float(2 * abs(np.sum(window * data * phase)) / np.sum(window))


def match_events(
    detected: Sequence[float], expected: Sequence[float], tolerance: float
) -> tuple[list[tuple[float, float]], list[float], list[float]]:
    """Pairs each expected time with the nearest detection within ``tolerance``.

    Returns ``(pairs, missing_expected, unexpected_detections)``.
    """
    remaining = list(detected)
    pairs: list[tuple[float, float]] = []
    missing: list[float] = []
    for value in expected:
        if not remaining:
            missing.append(value)
            continue
        nearest = min(remaining, key=lambda d: abs(d - value))
        if abs(nearest - value) <= tolerance:
            pairs.append((value, nearest))
            remaining.remove(nearest)
        else:
            missing.append(value)
    return pairs, missing, remaining
