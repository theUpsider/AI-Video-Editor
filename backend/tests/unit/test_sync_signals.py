"""Audio offset estimation on synthetic signals: AVE-REQ-024 AC-2, AC-3 (and AC-1 semantics).

Each recording is cut from one simulated scene: an event at reference time T appears in a
recording that started at reference time ``s`` at local time ``T - s``; therefore the expected
offset is ``a = s`` under ``T_reference = a + t_target``.
"""

from __future__ import annotations

import tracemalloc
from fractions import Fraction

import numpy as np
import numpy.typing as npt
import pytest
from scipy import signal as sps

from ave.errors import AveError
from ave.fixtures.generate import chirp
from ave.sync.audio import (
    SyncStatus,
    _highpass,
    estimate_offset_from_signals,
)

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


@pytest.mark.req("AVE-REQ-024 AC-2")
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


@pytest.mark.req("AVE-REQ-024 AC-2")
def test_negative_offset_when_the_reference_starts_later() -> None:
    """AVE-REQ-024 AC-2: swapping roles gives a = -2 (target started before the reference)."""
    reference = recording(2.0, 25.0, 44100, gain=0.3, noise=0.01, seed=3)
    target = recording(0.0, 30.0, 48000)
    result = estimate_offset_from_signals(reference, 44100, target, 48000)
    assert result.status == SyncStatus.OK
    assert result.offset == -2


@pytest.mark.req("AVE-REQ-024 AC-2")
def test_sub_frame_offset_is_resolved_to_the_sample() -> None:
    """AVE-REQ-024 AC-2: a non-integer offset (3.4567 s) is found within two samples."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(3.4567, 20.0, 48000, gain=2.0, noise=0.005, seed=9)
    result = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert result.status == SyncStatus.OK
    assert result.offset_s is not None
    assert abs(result.offset_s - 3.4567) < 2 / 48000


@pytest.mark.req("AVE-REQ-024 AC-2")
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


@pytest.mark.req("AVE-REQ-024 AC-3")
def test_evidence_is_reported() -> None:
    """AVE-REQ-024 AC-3: method, confidence, chance probability of the coinciding onsets,
    residual/anchors and aligned intervals."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(2.0, 25.0, 44100, gain=0.3, noise=0.01, seed=3)
    result = estimate_offset_from_signals(reference, 48000, target, 44100)
    assert result.method == "audio-onset-xcorr+waveform-refine"
    assert result.sign_convention.startswith("T_reference = a + b * t_target")
    assert result.confidence > 0.6
    assert result.peak_ratio is not None
    assert result.peak_ratio > 2
    assert result.matched_onsets >= 7
    assert result.chance_probability is not None
    assert result.chance_probability < 1e-12
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


@pytest.mark.req("AVE-REQ-024 AC-3")
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


@pytest.mark.req("AVE-REQ-024 AC-3")
def test_silent_audio_is_insufficient_evidence() -> None:
    """AVE-REQ-024 AC-3: a silent track cannot be synchronized by sound."""
    reference = recording(0.0, 30.0, 48000)
    silent = np.zeros(48000 * 10)
    result = estimate_offset_from_signals(reference, 48000, silent, 48000)
    assert result.status == SyncStatus.INSUFFICIENT_EVIDENCE
    assert result.reason is not None
    assert "silent" in result.reason


@pytest.mark.req("AVE-REQ-024 AC-3")
def test_periodic_audio_is_ambiguous_with_alternatives() -> None:
    """AVE-REQ-024 AC-3: a metronome-like signal has many equally good offsets."""
    clicks = tuple(0.25 + 0.5 * i for i in range(80))
    reference = recording(0.0, 30.0, 48000, events=clicks)
    target = recording(3.0, 20.0, 48000, events=clicks, seed=4)
    result = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert result.status == SyncStatus.AMBIGUOUS
    assert result.offset is None
    assert len(result.alternatives) >= 2


@pytest.mark.req("AVE-REQ-024 AC-3")
def test_offset_bounds_exclude_implausible_lags() -> None:
    """AVE-REQ-024 AC-3: a plausibility bound that excludes the true offset prevents a match:
    the bounded search reports insufficient evidence instead of some offset inside the bound."""
    reference = recording(0.0, 30.0, 48000)
    target = recording(6.0, 20.0, 48000, seed=2)
    unbounded = estimate_offset_from_signals(reference, 48000, target, 48000)
    assert unbounded.status == SyncStatus.OK
    assert unbounded.offset == 6
    bounded = estimate_offset_from_signals(reference, 48000, target, 48000, max_offset_s=3.0)
    assert bounded.status == SyncStatus.INSUFFICIENT_EVIDENCE
    assert bounded.offset is None


_RATE = 48000


@pytest.mark.req("AVE-REQ-024 AC-2")
def test_analysis_runs_on_float32_copies_without_full_length_float64() -> None:
    """AVE-REQ-024 AC-2: a 60 s / 50 s pair with a known +2 s offset is still found within
    0.1 ms while the estimation allocates at most 8 bytes per input sample (the two float32
    working copies plus block-sized temporaries; no full-length float64 arrays)."""
    reference = recording(0.0, 60.0, _RATE).astype(np.float32)
    target = recording(2.0, 50.0, _RATE, seed=3).astype(np.float32)
    before = (reference.copy(), target.copy())
    tracemalloc.start()
    try:
        result = estimate_offset_from_signals(reference, _RATE, target, _RATE)
        _, peak = tracemalloc.get_traced_memory()
    finally:
        tracemalloc.stop()
    assert result.status == SyncStatus.OK
    assert result.offset_s is not None
    assert abs(result.offset_s - 2.0) < 1e-4
    assert peak <= 8 * (len(reference) + len(target))
    assert np.array_equal(reference, before[0])  # the caller's arrays are not modified
    assert np.array_equal(target, before[1])


@pytest.mark.req("AVE-REQ-024 AC-2")
def test_block_highpass_matches_the_reference_zero_phase_filter() -> None:
    """AVE-REQ-024 AC-2: the in-place block high-pass equals scipy's sosfiltfilt (odd padding,
    steady-state initial conditions) across block boundaries, so the analysis method and its
    accuracy are unchanged by the bounded-memory processing."""
    data = recording(0.0, 13.0, _RATE, noise=0.02, seed=7)
    sos = sps.butter(4, 150.0, btype="highpass", fs=_RATE, output="sos")
    expected = sps.sosfiltfilt(sos, data.astype(np.float32).astype(np.float64))
    filtered = data.astype(np.float32)
    assert len(filtered) > 2 * 2**18  # several processing blocks
    _highpass(filtered, _RATE)
    assert np.abs(filtered - expected).max() < 1e-5
