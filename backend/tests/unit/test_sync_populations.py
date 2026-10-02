"""Seeded signal populations for the audio offset estimator (slow tier): AVE-REQ-024 AC-3.

Hand-picked examples cannot show that an estimator never invents an offset. These tests run
seeded populations of synthetic recording pairs whose truth is known by construction and count
the outcomes: unrelated recordings must never give an offset, structured noise that violates the
estimator's independence assumption must never give a wrong one, and few shared events must
still give the true offset often enough for the gate to stay useful. The measured outcomes at
the time of writing are quoted in each docstring; the asserted floors leave room for numerical
differences between platforms, never for a wrong offset.
"""

from __future__ import annotations

from collections.abc import Iterator

import numpy as np
import numpy.typing as npt
import pytest

from ave.fixtures.generate import chirp
from ave.sync.audio import (
    MAX_CHANCE_PROBABILITY,
    MIN_MATCHED_ONSETS,
    SyncStatus,
    estimate_offset_from_signals,
)

pytestmark = pytest.mark.slow

FloatArray32 = npt.NDArray[np.float32]
UNRELATED_PAIRS = 400
_RATE = 48000
ONE_FRAME_60 = 1 / 60


def _unrelated_pairs() -> Iterator[tuple[int, FloatArray32, FloatArray32]]:
    """Seeded pairs of recordings of different scenes (independent random events).

    Like :func:`recording` - 1 kHz / 1.7 kHz pilot tones, the fixture chirp per event, gain and
    white noise - with 3 to 15 events each at uniformly random times in a 30 s reference and a
    25 s target. Pilot and noise are generated once and shared, so only the events, gain and
    noise level vary per pair.
    """
    t_ref = np.arange(30 * _RATE) / _RATE
    t_tgt = np.arange(25 * _RATE) / _RATE
    noise = np.random.default_rng(2024)
    ref_base = 0.05 * np.sin(2 * np.pi * 1000.0 * t_ref)
    ref_noise = 0.001 * noise.standard_normal(len(t_ref))
    tgt_base = 0.05 * np.sin(2 * np.pi * 1700.0 * t_tgt)
    tgt_noise = noise.standard_normal(len(t_tgt))
    burst = 0.5 * chirp(_RATE)
    for seed in range(UNRELATED_PAIRS):
        rng = np.random.default_rng(seed)
        reference = ref_base.copy()
        target = tgt_base.copy()
        for signal, span in ((reference, 29.8), (target, 24.8)):
            for event in rng.uniform(0.1, span, size=int(rng.integers(3, 16))):
                start = round(event * _RATE)
                signal[start : start + len(burst)] += burst
        target *= rng.uniform(0.3, 2.0)
        target += rng.uniform(0.001, 0.01) * tgt_noise
        reference += ref_noise
        yield seed, reference.astype(np.float32), target.astype(np.float32)


def test_unrelated_recordings_never_yield_an_offset() -> None:
    """AVE-REQ-024 AC-3: on 400 seeded pairs of unrelated recordings no estimate is OK - chance
    coincidences of onsets (two or three at the best of all searched lags) are reported as
    insufficient evidence with their chance probability, never as an offset."""
    results = [
        (seed, estimate_offset_from_signals(ref, _RATE, tgt, _RATE))
        for seed, ref, tgt in _unrelated_pairs()
    ]
    assert len(results) == UNRELATED_PAIRS
    assert [seed for seed, r in results if r.status == SyncStatus.OK] == []
    assert all(r.offset is None for _, r in results)
    # The population really contains the chance coincidences that the gate must reject.
    coincidences = [r for _, r in results if r.matched_onsets >= MIN_MATCHED_ONSETS]
    assert len(coincidences) >= 20
    for result in coincidences:
        assert result.chance_probability is not None
        assert result.chance_probability > MAX_CHANCE_PROBABILITY
        assert result.status == SyncStatus.INSUFFICIENT_EVIDENCE


LATTICE_BLOCK = 2400
"""Samples per noise block (50 ms at 48 kHz): every block boundary can be an onset."""
LATTICE_PAIRS = 200


def _lattice_noise(rng: np.random.Generator, count: int, level: float) -> FloatArray32:
    """White noise whose amplitude jumps at every block boundary of a fixed 50 ms lattice."""
    blocks = -(-count // LATTICE_BLOCK)
    amplitude = np.repeat(rng.uniform(0.0, level, size=blocks), LATTICE_BLOCK)[:count]
    return (amplitude * rng.standard_normal(count)).astype(np.float32)


def _scene_recording(
    rng: np.random.Generator,
    start: float,
    duration: float,
    rate: int,
    events: tuple[float, ...],
    *,
    pilot_hz: float,
    gain: float = 1.0,
    noise: float = 0.0,
    lattice: float = 0.0,
) -> FloatArray32:
    """A recording started at reference time ``start``: pilot tone, a chirp per event, optional
    white and lattice noise."""
    count = int(duration * rate)
    t = np.arange(count) / rate
    signal = 0.05 * np.sin(2 * np.pi * pilot_hz * t)
    burst = 0.5 * chirp(rate)
    for event in events:
        local = round((event - start) * rate)
        if 0 <= local < count:
            end = min(count, local + len(burst))
            signal[local:end] += burst[: end - local]
    signal = gain * signal + noise * rng.standard_normal(count)
    if lattice:
        signal = signal + _lattice_noise(rng, count, lattice)
    return signal.astype(np.float32)


def _lattice_population(level: float, *, related: bool, pairs: int) -> dict[str, int]:
    """Outcome counts of seeded pairs that both carry lattice noise of ``level``; related pairs
    share 4-11 chirps at an offset on the lattice (a multiple of 50 ms, the worst case: true and
    lattice-induced alignments have the same phase)."""
    counts = {"right": 0, "wrong": 0, "ambiguous": 0, "insufficient": 0}
    for seed in range(pairs):
        rng = np.random.default_rng(10_000 + seed)
        events = tuple(rng.uniform(0.2, 29.5, size=int(rng.integers(4, 12))))
        offset = round(float(rng.uniform(-6, 6)) / 0.05) * 0.05
        reference = _scene_recording(rng, 0.0, 30.0, _RATE, events, pilot_hz=1000.0, lattice=level)
        if not related:
            size = int(rng.integers(4, 12))
            events = tuple(rng.uniform(offset + 0.2, offset + 24.5, size=size))
        target = _scene_recording(rng, offset, 25.0, _RATE, events, pilot_hz=1700.0, lattice=level)
        result = estimate_offset_from_signals(reference, _RATE, target, _RATE)
        if result.status == SyncStatus.OK:
            assert result.offset_s is not None
            right = related and abs(result.offset_s - offset) < ONE_FRAME_60
            counts["right" if right else "wrong"] += 1
        else:
            counts["ambiguous" if result.status == SyncStatus.AMBIGUOUS else "insufficient"] += 1
    return counts


def test_strong_lattice_noise_never_yields_a_wrong_offset() -> None:
    """AVE-REQ-024 AC-3: noise whose level changes on a shared 50 ms lattice makes onsets
    coincide at every lattice-aligned lag, against the independence assumption of the chance
    gate. On 200 related and 200 unrelated seeded pairs no estimate is a wrong offset: the
    competing lattice alignment is reported as ambiguous (measured: related 173 ambiguous,
    27 insufficient; unrelated 1 ambiguous, 199 insufficient)."""
    related = _lattice_population(0.08, related=True, pairs=LATTICE_PAIRS)
    unrelated = _lattice_population(0.08, related=False, pairs=LATTICE_PAIRS)
    assert related["wrong"] == 0
    assert unrelated["wrong"] == 0
    assert unrelated["right"] == 0
    assert related["ambiguous"] >= LATTICE_PAIRS // 2  # the population exercises the rival check


def test_mild_lattice_noise_keeps_the_true_offset() -> None:
    """AVE-REQ-024 AC-2, AVE-REQ-024 AC-3: with mild lattice noise the true alignment dominates:
    related pairs give the true offset (measured 94 of 100, the rest insufficient) and never a
    wrong one."""
    related = _lattice_population(0.01, related=True, pairs=100)
    assert related["wrong"] == 0
    assert related["right"] >= 85


FEW_EVENT_PAIRS = 200


def test_few_shared_events_give_the_true_offset_or_no_offset() -> None:
    """AVE-REQ-024 AC-2, AVE-REQ-024 AC-3: pairs sharing only 3-4 transients over 20-30 s, each
    side with 2-6 events of its own, offsets within +-8 s, 44.1 or 48 kHz targets and varied gain:
    no estimate is wrong, and the gates still find the true offset for most pairs (measured 136
    of 200; the others are insufficient evidence)."""
    counts = {"right": 0, "wrong": 0, "other": 0}
    for seed in range(FEW_EVENT_PAIRS):
        rng = np.random.default_rng(seed)
        offset = float(rng.uniform(-8, 8))
        duration = float(rng.uniform(20, 30))
        low, high = max(0.0, offset) + 0.3, min(30.0, offset + duration) - 0.3
        shared = tuple(rng.uniform(low, high, size=int(rng.integers(3, 5))))
        own_reference = tuple(rng.uniform(0.2, 29.5, size=int(rng.integers(2, 7))))
        own_target = tuple(
            rng.uniform(offset + 0.2, offset + duration - 0.5, size=int(rng.integers(2, 7)))
        )
        rate = int(rng.choice([44100, 48000]))
        reference = _scene_recording(
            rng, 0.0, 30.0, _RATE, shared + own_reference, pilot_hz=1000.0, noise=0.002
        )
        target = _scene_recording(
            rng, offset, duration, rate, shared + own_target, pilot_hz=1700.0,
            gain=float(rng.uniform(0.3, 2.0)), noise=0.005,
        )  # fmt: skip
        result = estimate_offset_from_signals(reference, _RATE, target, rate)
        if result.status != SyncStatus.OK:
            counts["other"] += 1
            continue
        assert result.offset_s is not None
        counts["right" if abs(result.offset_s - offset) < ONE_FRAME_60 else "wrong"] += 1
    assert counts["wrong"] == 0
    assert counts["right"] >= 120
