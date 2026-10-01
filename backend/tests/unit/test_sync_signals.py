"""Audio offset estimation on synthetic signals: AVE-REQ-024 AC-2, AC-3 (and AC-1 semantics).

Each recording is cut from one simulated scene: an event at reference time T appears in a
recording that started at reference time ``s`` at local time ``T - s``; therefore the expected
offset is ``a = s`` under ``T_reference = a + t_target``.
"""

from __future__ import annotations

from fractions import Fraction

import numpy as np
import numpy.typing as npt
import pytest

from ave.errors import AveError
from ave.fixtures.generate import chirp
from ave.sync.audio import SyncStatus, estimate_offset_from_signals

SCENE_EVENTS = (1.3, 3.217, 5.9, 9.433, 13.05, 17.717, 21.367, 24.8, 28.1, 33.7, 36.2)
FRAME_60 = 1 / 60


def recording(
    start: float,
    duration: float,
    rate: int,
    *,
    events: tuple[float, ...] = SCENE_EVENTS,
    gain: float = 1.0,
    noise: float = 0.001,
    pilot_hz: float = 1000.0,
    seed: int = 0,
) -> npt.NDArray[np.float64]:
    """A mono recording of the scene starting at reference time ``start``."""
    count = int(duration * rate)
    t = np.arange(count) / rate
    signal = 0.05 * np.sin(2 * np.pi * pilot_hz * t)
    burst = 0.5 * chirp(rate)
    for event in events:
        local = round((event - start) * rate)
        if 0 <= local < count:
            end = min(count, local + len(burst))
            signal[local:end] += burst[: end - local]
    signal *= gain
    return signal + noise * np.random.default_rng(seed).standard_normal(count)


def test_positive_offset_with_gain_noise_and_rate_mismatch() -> None:
    """AVE-REQ-024 AC-2: B starts 2 s after A at 44.1 kHz with -10 dB gain and noise."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(2.0, 25.0, 44100, gain=0.3, noise=0.01, pilot_hz=1700.0, seed=3)
    result = estimate_offset_from_signals(reference, 48000, target, 44100)
    assert result.status == SyncStatus.OK
    assert result.offset_s is not None
    assert abs(result.offset_s - 2.0) < FRAME_60
    assert abs(result.offset_s - 2.0) < 1e-4  # far inside one output frame on clean synthetics
    assert result.offset == 2


def test_negative_offset_when_the_reference_starts_later() -> None:
    """AVE-REQ-024 AC-2: swapping roles gives a = -2 (target started before the reference)."""
    reference = recording(2.0, 25.0, 44100, gain=0.3, noise=0.01, seed=3)
    target = recording(0.0, 30.0, 48000)
    result = estimate_offset_from_signals(reference, 44100, target, 48000)
    assert result.status == SyncStatus.OK
    assert result.offset == -2


def test_sub_frame_offset_is_resolved_to_the_sample() -> None:
    """AVE-REQ-024 AC-2: a non-integer offset (3.4567 s) is found within two samples."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(3.4567, 20.0, 48000, gain=2.0, noise=0.005, seed=9)
    result = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert result.status == SyncStatus.OK
    assert result.offset_s is not None
    assert abs(result.offset_s - 3.4567) < 2 / 48000


def test_partial_overlap() -> None:
    """AVE-REQ-024 AC-2: only 9 s of a 15 s target overlap the reference."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(21.0, 15.0, 48000, noise=0.004, seed=5)
    result = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert result.status == SyncStatus.OK
    assert result.offset == 21
    assert result.reference_overlap is not None
    assert result.reference_overlap.start == 21
    assert result.reference_overlap.end == 30


def test_evidence_is_reported() -> None:
    """AVE-REQ-024 AC-3: method, confidence, residual/anchors and aligned intervals."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(2.0, 25.0, 44100, gain=0.3, noise=0.01, seed=3)
    result = estimate_offset_from_signals(reference, 48000, target, 44100)
    assert result.method == "audio-onset-xcorr+waveform-refine"
    assert result.sign_convention.startswith("T_reference = a + b * t_target")
    assert result.confidence > 0.6
    assert result.peak_ratio is not None
    assert result.peak_ratio > 2
    assert result.matched_onsets >= 7
    assert len(result.anchors) >= 2
    assert result.residual_s is not None
    assert result.residual_s < 1e-4
    assert result.reference_overlap is not None
    assert result.target_source_interval is not None
    assert (result.reference_overlap.start, result.reference_overlap.end) == (2, 27)
    assert (result.target_source_interval.start, result.target_source_interval.end) == (0, 25)
    member = result.to_sync_member("B")
    assert (member.a, member.b, member.user_supplied) == (Fraction(2), Fraction(1), False)
    assert member.method == result.method
    assert len(member.anchors) == len(result.anchors)


def test_unrelated_audio_is_insufficient_evidence() -> None:
    """AVE-REQ-024 AC-3: recordings of different scenes do not produce a confident offset."""
    reference = recording(0.0, 30.0, 48000)
    other_events = (0.7, 4.41, 6.02, 11.9, 15.15, 19.0, 23.3)
    target = recording(0.0, 25.0, 48000, events=other_events, seed=8)
    result = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert result.status == SyncStatus.INSUFFICIENT_EVIDENCE
    assert result.offset is None
    with pytest.raises(AveError) as error:
        result.to_sync_member("B")
    assert error.value.code == "INSUFFICIENT_SYNC_EVIDENCE"


def test_silent_audio_is_insufficient_evidence() -> None:
    """AVE-REQ-024 AC-3: a silent track cannot be synchronized by sound."""
    reference = recording(0.0, 30.0, 48000)
    silent = np.zeros(48000 * 10)
    result = estimate_offset_from_signals(reference, 48000, silent, 48000)
    assert result.status == SyncStatus.INSUFFICIENT_EVIDENCE
    assert result.reason is not None
    assert "silent" in result.reason


def test_periodic_audio_is_ambiguous_with_alternatives() -> None:
    """AVE-REQ-024 AC-3: a metronome-like signal has many equally good offsets."""
    clicks = tuple(0.25 + 0.5 * i for i in range(80))
    reference = recording(0.0, 30.0, 48000, events=clicks)
    target = recording(3.0, 20.0, 48000, events=clicks, seed=4)
    result = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert result.status == SyncStatus.AMBIGUOUS
    assert result.offset is None
    assert len(result.alternatives) >= 2


def test_offset_bounds_exclude_implausible_lags() -> None:
    """AVE-REQ-024 AC-3: a plausibility bound that excludes the true offset prevents a match."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(6.0, 20.0, 48000, seed=2)
    unbounded = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert unbounded.offset == 6
    bounded = estimate_offset_from_signals(reference, 48000, target, 48000, max_offset_s=3.0)
    assert bounded.status != SyncStatus.OK or bounded.offset != 6
