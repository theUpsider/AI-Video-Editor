"""Placement of decoded audio samples by presentation timestamps (ADR-004 source time).

Every consumer of decoded audio - the renderer and the synchronization analysis - reads its input
with FFmpeg's ``-copyts`` (raw stream timestamps, never re-based by FFmpeg) and starts its filter
chain with :func:`audio_placement_filter`:

1. ``asetpts`` subtracts the exact origin of the output's sample 0, in seconds of the input's raw
   timeline (the container start time from the probe, plus a seek point), rounded to the input
   sample;
2. ``aresample`` with ``first_pts=0``, ``min_comp=0`` and ``min_hard_comp`` =
   :data:`AUDIO_TIMESTAMP_TOLERANCE_S` makes the samples follow those timestamps: silence before a
   stream that starts late, and silence inserted into (or samples dropped from) every timestamp gap
   or overlap of the tolerance or more.

Without ``-copyts`` FFmpeg re-bases timestamps itself - for MPEG-TS/PS on the start of the streams
it reads rather than on the container start - so an explicit, exact origin is the only consistent
reference. The result: output sample ``k`` presents raw time ``origin + k / rate`` within one input
sample plus the tolerance.

The first decoded packet anchors the placement: ``aresample`` measures every later packet's
timestamp deviation from the contiguous continuation of the samples placed since that anchor (or
since its last correction). A decode from the stream start (the analysis extraction) is anchored
on the stream's first packet; a decode after a seek (a rendered clip) on the first decoded packet
that ends after the seek point. Timestamp jitter therefore stays uncorrected while its peak-to-peak
spread (the largest minus the smallest deviation of the packets from a contiguous stream) is
below the tolerance, which holds for an amplitude below 5 ms around the contiguous positions. A
rendered clip then sits the deviation of its anchor from the stream's first packet (at most the
spread) from the analysis placement of the same source. Jitter with a spread of 10 ms or more is
corrected like a gap wherever a packet deviates 10 ms or more from the current anchor: silence is
inserted or samples are dropped, and the analysis and each render of one source can correct
different packets, because each decode has its own anchor (ASM-008).
"""

from __future__ import annotations

from fractions import Fraction

__all__ = ["AUDIO_TIMESTAMP_TOLERANCE_S", "audio_placement_filter"]

AUDIO_TIMESTAMP_TOLERANCE_S = Fraction(1, 100)
"""Timestamp deviations below this value (10 ms) are jitter and stay uncorrected (FFmpeg's default
is 0.1 s); a deviation is measured from the contiguous continuation of the placement anchor, the
first decoded packet (see the module description).

Deviations of 10 ms or more are real gaps or overlaps and are corrected in full: one lost AAC frame
is 21.3 ms at 48 kHz. Exactly 10 ms is corrected, because FFmpeg holds the option as a
single-precision float just under 0.01 and corrects every larger deviation. Below 10 ms the sample
count is trusted: container timestamp rounding (1 ms in Matroska) and muxer jitter of a few
milliseconds never turn into inserted silence (a 1 ms threshold inserted hundreds of dropouts into
a stream with +-2 ms jitter). Jitter stays uncorrected while its peak-to-peak spread is below
10 ms (an amplitude below 5 ms): with jitter of 5 ms each way, every late packet lies 10 ms from
an early anchor (and every early packet from a late one), so silence is inserted and samples are
dropped (measured on MPEG-TS packets alternating +-5 ms: 701 silence runs in the 30 s analysis
extraction and 141 in every 6 s render, whichever packet anchors it; alternating +-4.5 ms: none)."""


def audio_placement_filter(origin: Fraction, rate: int, resampler: str = "soxr") -> str:
    """Filters that put raw-timestamped input audio on a ``rate`` grid starting at ``origin``.

    ``origin`` is in seconds of the input's raw timeline (``-copyts``); output sample ``k`` presents
    raw time ``origin + k / rate``.
    """
    tolerance = float(AUDIO_TIMESTAMP_TOLERANCE_S)
    return (
        f"asetpts=PTS-round(({origin.numerator}/{origin.denominator})/TB),"
        f"aresample={rate}:resampler={resampler}:min_comp=0:min_hard_comp={tolerance!r}:"
        "first_pts=0"
    )
