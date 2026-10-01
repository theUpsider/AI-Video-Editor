"""Frame-index barcode drawn into synthetic fixtures and read back from decoded output.

Layout: a 4x4 grid of square cells centered in the frame, row-major, most significant bit first.
Cells 0-11 carry the 12-bit source frame index (0..4095); cells 12-15 carry a check nibble
``(n0 + 3*n1 + 5*n2) mod 16`` over the index's three nibbles, which detects every single-bit
error. A set bit is a white cell, a clear bit a black cell. Cells are ``min(width, height) // 9``
pixels (120 px at 1080 lines), large enough to survive 1080 -> 960 scaling, H.264 coding and
4x-reduced analysis decoding.

A separate *background patch* near the top-left corner shows the source's identifying color, or
white on flash frames.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

__all__ = [
    "CELLS",
    "DATA_BITS",
    "MAX_INDEX",
    "BarcodeLayout",
    "barcode_layout",
    "check_nibble",
    "decode_bits",
    "encode_bits",
    "ffmpeg_bit_expression",
]

GRID = 4
CELLS = GRID * GRID
DATA_BITS = 12
CHECK_BITS = CELLS - DATA_BITS
MAX_INDEX = (1 << DATA_BITS) - 1


def _even(value: int) -> int:
    return value - (value % 2)


@dataclass(frozen=True)
class BarcodeLayout:
    """Pixel geometry of the barcode and background patch inside one source frame."""

    frame_width: int
    frame_height: int
    cell: int
    x0: int
    y0: int
    patch_x: int
    patch_y: int
    patch_size: int

    def cell_rect(self, index: int) -> tuple[int, int, int, int]:
        """``(x, y, width, height)`` of cell ``index`` (row-major)."""
        row, column = divmod(index, GRID)
        return (self.x0 + column * self.cell, self.y0 + row * self.cell, self.cell, self.cell)

    def cell_center(self, index: int) -> tuple[float, float]:
        """Center of cell ``index`` in source pixel coordinates."""
        x, y, width, height = self.cell_rect(index)
        return (x + width / 2, y + height / 2)

    @property
    def grid_size(self) -> int:
        """Side length of the whole barcode grid in pixels."""
        return GRID * self.cell

    @property
    def patch_center(self) -> tuple[float, float]:
        """Center of the background patch in source pixel coordinates."""
        half = self.patch_size / 2
        return (self.patch_x + half, self.patch_y + half)


def barcode_layout(width: int, height: int) -> BarcodeLayout:
    """Barcode geometry for a ``width x height`` frame."""
    side = min(width, height)
    cell = max(_even(side // 9), 8)
    grid = GRID * cell
    return BarcodeLayout(
        frame_width=width,
        frame_height=height,
        cell=cell,
        x0=_even((width - grid) // 2),
        y0=_even((height - grid) // 2),
        patch_x=_even(side // 25),
        patch_y=_even(side // 25),
        patch_size=max(_even(side // 8), 4),
    )


def check_nibble(index: int) -> int:
    """Check value over the three nibbles of ``index``."""
    return ((index & 0xF) + 3 * ((index >> 4) & 0xF) + 5 * ((index >> 8) & 0xF)) % 16


def encode_bits(index: int) -> tuple[int, ...]:
    """The 16 cell values (0/1) for frame ``index``."""
    if not 0 <= index <= MAX_INDEX:
        raise ValueError(f"frame index {index} outside 0..{MAX_INDEX}")
    data = tuple((index >> (DATA_BITS - 1 - i)) & 1 for i in range(DATA_BITS))
    check = check_nibble(index)
    return data + tuple((check >> (CHECK_BITS - 1 - i)) & 1 for i in range(CHECK_BITS))


def decode_bits(bits: Sequence[int]) -> int | None:
    """The frame index for 16 cell values, or ``None`` when the check nibble does not match."""
    if len(bits) != CELLS:
        raise ValueError(f"expected {CELLS} bits")
    index = 0
    for bit in bits[:DATA_BITS]:
        index = (index << 1) | (1 if bit else 0)
    check = 0
    for bit in bits[DATA_BITS:]:
        check = (check << 1) | (1 if bit else 0)
    return index if check == check_nibble(index) else None


def ffmpeg_bit_expression(cell: int) -> str:
    """FFmpeg expression (frame number ``n``) that is 1 when ``cell`` is set.

    Must equal :func:`encode_bits` for every index; the fixture self-test decodes generated frames
    to prove it.
    """
    if cell < DATA_BITS:
        return f"mod(floor(n/{1 << (DATA_BITS - 1 - cell)}),2)"
    check = "mod(mod(n,16)+3*mod(floor(n/16),16)+5*mod(floor(n/256),16),16)"
    return f"mod(floor({check}/{1 << (CHECK_BITS - 1 - (cell - DATA_BITS))}),2)"
