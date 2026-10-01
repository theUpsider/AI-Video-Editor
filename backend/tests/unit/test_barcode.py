"""Fixture barcode encoding (test infrastructure for decoded-frame oracles)."""

from __future__ import annotations

from ave.fixtures.barcode import CELLS, MAX_INDEX, barcode_layout, decode_bits, encode_bits


def test_every_index_round_trips() -> None:
    """All 4096 indices encode to 16 cells and decode back."""
    for index in range(MAX_INDEX + 1):
        bits = encode_bits(index)
        assert len(bits) == CELLS
        assert decode_bits(bits) == index


def test_every_single_bit_error_is_detected() -> None:
    """A misread cell never yields a wrong frame index (it yields None)."""
    for index in range(MAX_INDEX + 1):
        bits = list(encode_bits(index))
        for position in range(CELLS):
            corrupted = bits.copy()
            corrupted[position] ^= 1
            assert decode_bits(corrupted) is None


def test_layout_cells_survive_scaling() -> None:
    """Cells are 120 px at 1080 lines: 26 px after 8/9 scaling and 4x analysis reduction."""
    layout = barcode_layout(1080, 1080)
    assert layout.cell == 120
    assert layout.grid_size == 480
    assert (layout.x0, layout.y0) == (300, 300)
    assert layout.patch_x + layout.patch_size < layout.x0
    assert barcode_layout(2560, 1440).cell == 160
