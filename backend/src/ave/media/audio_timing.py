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
   or overlap larger than the tolerance.

Without ``-copyts`` FFmpeg re-bases timestamps itself - for MPEG-TS/PS on the start of the streams
it reads rather than on the container start - so an explicit, exact origin is the only consistent
reference. The result: output sample ``k`` presents raw time ``origin + k / rate`` within one input
sample plus the tolerance.
"""

from __future__ import annotations

from fractions import Fraction

__all__ = ["AUDIO_TIMESTAMP_TOLERANCE_S", "audio_placement_filter"]

AUDIO_TIMESTAMP_TOLERANCE_S = Fraction(1, 1000)
"""Largest timestamp discontinuity left uncorrected (FFmpeg's default is 0.1 s): smaller deviations
are timestamp rounding jitter, larger ones are real gaps or overlaps."""


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
