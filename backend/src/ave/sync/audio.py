"""Audio-based offset estimation between two recordings (AVE-REQ-024).

Method (interpretable, NumPy/SciPy only):

1. **Analysis audio** - each stream is decoded to mono float32 PCM at :data:`ANALYSIS_RATE`
   (48 kHz, SoX resampler), whatever its original rate and whether or not it is audible in the
   final edit. Sample ``k`` is source time ``k / ANALYSIS_RATE``: samples are placed by their
   presentation timestamps relative to the container start, so a stream that starts after the
   container start is preceded by silence. FFmpeg delivers the samples straight into one float32
   array (about 4 bytes per sample, no other full-length copy); all later full-length processing
   works in place on that array. A zero-phase 150 Hz high-pass removes rumble and DC.
2. **Coarse search** - a sparse 1 kHz onset function is computed for both signals: the rise of the
   log RMS energy (4 ms window, 1 ms hop) above a robust noise threshold. It is gain invariant and
   ignores steady tones and stationary noise. The onset functions are cross-correlated with FFTs
   over every lag whose overlap is at least ``min_overlap_s`` (optionally limited to
   ``|offset| <= max_offset_s``); the lag with the largest correlation (most matched onset
   energy) wins.
3. **Refinement** - the high-passed waveforms are cross-correlated at full rate within +-2 ms of
   the coarse lag, over windows around the reference onsets (where the evidence is); a parabola
   through the peak gives a sub-sample offset. When the waveforms do not correlate, the coarse
   result is kept with millisecond resolution.
4. **Evidence** - the number of target onsets that coincide with reference onsets at the chosen
   lag; the chance probability of that many coincidences (step 5); the normalized onset
   correlation inside the overlap (confidence); the ratio of the best correlation peak to the
   strongest peak outside a +-50 ms guard window; local refinements in up to three parts of the
   overlap (anchors) and their largest deviation from the global offset (residual); the aligned
   reference and target intervals.
5. **Chance coincidences** - unrelated recordings still line up a few onsets at some lag when every
   lag is searched. Under the null hypothesis of independent onset trains, a target onset inside
   the overlap lands within the match tolerance of a reference onset with probability
   ``p = n_ref * (2 * tolerance + 1) / overlap_hops``; the probability of at least ``m`` matches
   among ``n_tgt`` target onsets is the binomial tail, multiplied by the number of independent lag
   positions searched (admissible lags / (2 * tolerance + 1), a Bonferroni bound). The result is
   reported as ``chance_probability``.
6. **Decision** - silence, transient-free audio, fewer than two coinciding onsets, coincidences
   that chance explains (``chance_probability > MAX_CHANCE_PROBABILITY``) or weak correlation yield
   ``INSUFFICIENT_EVIDENCE``; a competing peak (for example periodic sound) yields ``AMBIGUOUS``
   with the alternatives; otherwise ``OK``.

Sign convention: the result is ``a`` in ``T_reference = a + b * t_target`` with ``b = 1``; a target
that starts two seconds after the reference has ``a = +2``. The thresholds are initial values
validated on synthetic fixtures; they are not accuracy claims for arbitrary real footage.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from enum import StrEnum
from fractions import Fraction
from pathlib import Path
from typing import Any

import numpy as np
import numpy.typing as npt
from pydantic import BaseModel, ConfigDict
from scipy import signal as sps
from scipy import special

from ave.domain.model import SyncAnchor, SyncMember
from ave.errors import AveError
from ave.media.probe import probe
from ave.proc import media_url, stream_tool
from ave.timebase import Interval, Rational, rational_from_float

__all__ = [
    "ANALYSIS_RATE",
    "MAX_CHANCE_PROBABILITY",
    "METHOD",
    "AnchorEstimate",
    "OffsetCandidate",
    "OffsetEstimate",
    "SyncStatus",
    "estimate_offset",
    "estimate_offset_from_signals",
    "extract_analysis_audio",
]

ANALYSIS_RATE = 48000
METHOD = "audio-onset-xcorr+waveform-refine"
HOP_S = Fraction(1, 1000)
HIGHPASS_HZ = 150.0
GUARD_S = 0.05
REFINE_RADIUS_S = 0.002
MIN_CONFIDENCE = 0.3
MIN_PEAK_RATIO = 1.5
MIN_REFINED_CORRELATION = 0.05
MIN_MATCHED_ONSETS = 2
"""Fewer coinciding onsets than this at the best lag is insufficient evidence."""
MAX_CHANCE_PROBABILITY = 1e-3
"""Largest accepted probability that unrelated onset trains coincide as often as observed."""
ENERGY_WINDOW_HOPS = 4
MIN_ONSET_RISE = 0.05
"""Smallest log-RMS rise per hop (nats) treated as an onset."""
ONSET_SEPARATION_S = 0.03
ONSET_TOLERANCE_HOPS = 3
EVENT_PRE_S = 0.005
EVENT_POST_S = 0.03
"""Waveform refinement uses reference samples from 5 ms before to 30 ms after each onset."""
MIN_ANCHOR_CORRELATION = 0.2
SILENCE_RMS = 10 ** (-60 / 20)
"""High-passed RMS below -60 dBFS counts as silent."""
_LOG_FLOOR = 1e-4
_EXTRACT_TIMEOUT_S = 900.0
_CHUNK = 1 << 18
"""Samples per block of the in-place full-length processing (bounded temporary memory)."""
_DRAIN_BYTES = 1 << 18
"""Bytes per pipe read while decoding (the only temporary buffer of the extraction)."""

FloatArray = npt.NDArray[np.float64]
Float32Array = npt.NDArray[np.float32]


class SyncStatus(StrEnum):
    """Outcome class of an offset estimate."""

    OK = "ok"
    AMBIGUOUS = "ambiguous"
    INSUFFICIENT_EVIDENCE = "insufficient_evidence"


INSUFFICIENT = SyncStatus.INSUFFICIENT_EVIDENCE


class _Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")


class OffsetCandidate(_Frozen):
    """A competing correlation peak."""

    offset_s: float
    score: float
    """Correlation relative to the best peak (1.0 = as strong as the best)."""


class AnchorEstimate(_Frozen):
    """A locally refined offset inside one window of the overlap."""

    reference_time_s: float
    offset_s: float
    correlation: float


class OffsetEstimate(_Frozen):
    """Result of :func:`estimate_offset` with its evidence."""

    status: SyncStatus
    method: str = METHOD
    sign_convention: str = "T_reference = a + b * t_target (b = 1)"
    offset_s: float | None = None
    """Estimated ``a`` in reference seconds."""
    offset: Rational | None = None
    """``a`` quantized to ``1 / ANALYSIS_RATE`` seconds."""
    resolution_s: float
    confidence: float
    """Normalized onset-envelope correlation inside the overlap at the chosen lag (0..1)."""
    peak_ratio: float | None = None
    """Best correlation peak divided by the strongest peak outside the guard window."""
    refined_correlation: float | None = None
    """Normalized waveform correlation at the refined offset."""
    alternatives: tuple[OffsetCandidate, ...] = ()
    anchors: tuple[AnchorEstimate, ...] = ()
    residual_s: float | None = None
    reference_overlap: Interval | None = None
    """Overlap in reference time (equals the reference source interval)."""
    target_source_interval: Interval | None = None
    """Target source interval that covers the overlap."""
    matched_onsets: int = 0
    """Target onsets that coincide with reference onsets at the chosen lag."""
    chance_probability: float | None = None
    """Bound on the probability that unrelated onset trains give ``matched_onsets`` coincidences at
    some searched lag (module doc, step 5); above :data:`MAX_CHANCE_PROBABILITY` the coincidences
    are no evidence."""
    reference_onsets: int = 0
    target_onsets: int = 0
    reference_duration_s: float
    target_duration_s: float
    reason: str | None = None

    @property
    def is_ok(self) -> bool:
        """True when the estimate is usable without user confirmation."""
        return self.status == SyncStatus.OK

    def to_sync_member(self, asset_id: str) -> SyncMember:
        """Synchronization-group member for the target asset (only for an ``OK`` estimate)."""
        if self.status != SyncStatus.OK or self.offset is None:
            raise AveError(
                f"no reliable offset ({self.status.value}): {self.reason or 'see evidence'}",
                code="INSUFFICIENT_SYNC_EVIDENCE",
            )
        anchors = tuple(
            SyncAnchor(
                reference_time=rational_from_float(a.reference_time_s, ANALYSIS_RATE),
                source_time=rational_from_float(a.reference_time_s - a.offset_s, ANALYSIS_RATE),
                score=max(-1.0, min(1.0, a.correlation)),
            )
            for a in self.anchors
        )
        return SyncMember(
            asset_id=asset_id,
            a=self.offset,
            b=Fraction(1),
            method=self.method,
            confidence=max(0.0, min(1.0, self.confidence)),
            anchors=anchors,
            residual_s=self.residual_s,
            user_supplied=False,
        )


# --------------------------------------------------------------------------------------------
# Signal extraction and features
# --------------------------------------------------------------------------------------------


def _read_float32(args: list[str], capacity: int | None) -> Float32Array:
    """Runs FFmpeg and reads its little-endian float32 stdout into one array.

    With a known ``capacity`` (samples) the bytes go straight into a preallocated array, so the
    peak memory is the array itself; output beyond ``capacity`` is read and discarded.
    """
    with stream_tool("ffmpeg", args, timeout=_EXTRACT_TIMEOUT_S) as pipe:
        if capacity is None:
            data = bytearray()
            while chunk := pipe.read(_DRAIN_BYTES):
                data += chunk
            usable = len(data) - len(data) % 4
            return np.frombuffer(memoryview(data)[:usable], dtype="<f4").astype(np.float32)
        samples = np.zeros(capacity, dtype=np.float32)
        view = samples.data.cast("B")
        filled = 0
        while filled < len(view):
            chunk = pipe.read(min(_DRAIN_BYTES, len(view) - filled))
            if not chunk:
                break
            view[filled : filled + len(chunk)] = chunk
            filled += len(chunk)
        view.release()
        while pipe.read(_DRAIN_BYTES):
            pass
    if filled < 4 * capacity:
        samples.resize(filled // 4, refcheck=False)
    return samples


def extract_analysis_audio(
    path: Path | str, *, stream_index: int | None = None, rate: int = ANALYSIS_RATE
) -> Float32Array:
    """Decodes one audio stream to mono float32 PCM at ``rate`` (SoX resampler).

    Sample ``k`` presents source time ``k / rate`` (time relative to the container start, the
    origin of every source time): FFmpeg places the decoded samples by their presentation
    timestamps (``aresample`` with ``first_pts=0`` and ``min_comp=0``), so a stream that starts
    after the container start begins with silence instead of being shifted earlier.

    ``stream_index`` is the absolute container index; the default is the first audio stream.
    The stream is read from the original file regardless of its mute state in any edit. Samples
    beyond the stream's end (codec end padding) are dropped, so aligned intervals match the real
    recording length. FFmpeg delivers mono float32 at ``rate``, read directly into the returned
    array: memory is about ``4 * rate * duration`` bytes.
    """
    info = probe(path, inspect_pts=False)
    streams = info.audio_streams
    stream = (
        next((s for s in streams if s.index == stream_index), None)
        if stream_index is not None
        else (streams[0] if streams else None)
    )
    if stream is None:
        raise AveError("the file has no such audio stream", code="MISSING_STREAM")
    end = info.source_duration(stream)
    return _read_float32(
        [
            "-hide_banner", "-nostdin", "-v", "error", "-i", media_url(path),
            "-map", f"0:{stream.index}",
            "-af", f"aresample={rate}:resampler=soxr:min_comp=0:first_pts=0",
            "-ac", "1", "-f", "f32le", "-",
        ],
        math.ceil(end * rate) if end is not None else None,
    )  # fmt: skip


def _resample(samples: npt.ArrayLike, from_rate: int, to_rate: int) -> Float32Array:
    """A float32 copy of mono ``samples`` at ``to_rate`` (the caller's array is never modified)."""
    data = np.asarray(samples)
    if data.ndim != 1:
        raise ValueError("analysis audio must be mono")
    if from_rate != to_rate:
        gcd = np.gcd(from_rate, to_rate)
        data = sps.resample_poly(data, to_rate // gcd, from_rate // gcd)
    return np.array(data, dtype=np.float32)


def _blocks(length: int, *, reverse: bool = False) -> list[tuple[int, int]]:
    """``[start, stop)`` blocks of at most :data:`_CHUNK` samples covering ``range(length)``."""
    blocks = [(start, min(length, start + _CHUNK)) for start in range(0, length, _CHUNK)]
    return blocks[::-1] if reverse else blocks


def _highpass(samples: Float32Array, rate: int) -> None:
    """Zero-phase 150 Hz high-pass of ``samples`` in place (float64 arithmetic per block).

    Equivalent to ``scipy.signal.sosfiltfilt`` with its default odd extension of ``3 * ntaps``
    samples and steady-state initial conditions, computed block by block so that no full-length
    temporary array exists.
    """
    count = len(samples)
    if count < 64:
        samples -= samples.mean(dtype=np.float64)
        return
    sos = sps.butter(4, HIGHPASS_HZ, btype="highpass", fs=rate, output="sos")
    taps = 2 * len(sos) + 1 - min(int((sos[:, 2] == 0).sum()), int((sos[:, 5] == 0).sum()))
    edge = 3 * taps
    steady = sps.sosfilt_zi(sos)
    first, last = float(samples[0]), float(samples[-1])
    left = 2 * first - samples[edge:0:-1].astype(np.float64)
    right = 2 * last - samples[-2 : -(edge + 2) : -1].astype(np.float64)
    _, state = sps.sosfilt(sos, left, zi=steady * left[0])
    for start, stop in _blocks(count):
        block, state = sps.sosfilt(sos, samples[start:stop].astype(np.float64), zi=state)
        samples[start:stop] = block
    tail, state = sps.sosfilt(sos, right, zi=state)
    _, state = sps.sosfilt(sos, tail[::-1], zi=steady * tail[-1])
    for start, stop in _blocks(count, reverse=True):
        block, state = sps.sosfilt(sos, samples[start:stop][::-1].astype(np.float64), zi=state)
        samples[start:stop] = block[::-1]


def _rms(samples: Float32Array) -> float:
    """Root mean square accumulated in float64, block by block."""
    total = 0.0
    for start, stop in _blocks(len(samples)):
        block = samples[start:stop].astype(np.float64)
        total += float(np.dot(block, block))
    return math.sqrt(total / max(1, len(samples)))


def _onset_envelope(samples: Float32Array, hop: int) -> FloatArray:
    """Sparse onset strength per hop: log-energy rises above a robust noise threshold.

    Energy is averaged over :data:`ENERGY_WINDOW_HOPS` hops; the rise of the log RMS from one hop to
    the next minus ``max(6 * robust_sigma, MIN_ONSET_RISE)`` is kept where positive. Gain changes
    cancel in the log domain; steady tones and stationary noise stay below the threshold.
    """
    frames = len(samples) // hop
    if frames < ENERGY_WINDOW_HOPS + 2:
        return np.zeros(max(frames, 0))
    hops = samples[: frames * hop].reshape(frames, hop)
    energy = np.empty(frames, dtype=np.float64)
    step = max(1, _CHUNK // hop)
    for start in range(0, frames, step):
        block = hops[start : start + step].astype(np.float64)
        energy[start : start + step] = np.mean(block * block, axis=1)
    kernel = np.ones(ENERGY_WINDOW_HOPS) / ENERGY_WINDOW_HOPS
    # Edge padding: the recording start must not look like a rise from silence.
    padded = np.concatenate((np.full(ENERGY_WINDOW_HOPS - 1, energy[0]), energy))
    smoothed = np.convolve(padded, kernel, mode="valid")
    log_rms = 0.5 * np.log(smoothed + _LOG_FLOOR**2)
    rise = np.diff(log_rms, prepend=log_rms[0])
    sigma = 1.4826 * float(np.median(np.abs(rise - np.median(rise))))
    threshold = max(6.0 * sigma, MIN_ONSET_RISE)
    return np.asarray(np.maximum(rise - threshold, 0.0), dtype=np.float64)


def _onset_peaks(envelope: FloatArray, separation: int) -> npt.NDArray[np.int64]:
    """Indices of onset peaks at least ``separation`` hops apart (strongest first wins)."""
    candidates = _local_maxima(np.where(envelope > 0, envelope, -np.inf))
    order = candidates[np.argsort(envelope[candidates])[::-1]]
    chosen: list[int] = []
    for index in order:
        if all(abs(int(index) - other) >= separation for other in chosen):
            chosen.append(int(index))
    return np.array(sorted(chosen), dtype=np.int64)


def _matched_onsets(
    ref_peaks: npt.NDArray[np.int64], tgt_peaks: npt.NDArray[np.int64], lag: int, tolerance: int
) -> int:
    """Number of target onsets that land within ``tolerance`` hops of a reference onset."""
    if not len(ref_peaks) or not len(tgt_peaks):
        return 0
    shifted = tgt_peaks + lag
    positions = np.searchsorted(ref_peaks, shifted)
    matched = 0
    for value, position in zip(shifted, positions, strict=True):
        neighbors = ref_peaks[max(0, position - 1) : position + 1]
        if len(neighbors) and int(np.min(np.abs(neighbors - value))) <= tolerance:
            matched += 1
    return matched


def _overlap_bounds(
    lags: npt.NDArray[np.int64], n_ref: int, n_tgt: int
) -> tuple[npt.NDArray[np.int64], npt.NDArray[np.int64]]:
    """Reference index bounds ``[lo, hi)`` of the overlap for each lag (target n -> ref n+lag)."""
    lo = np.maximum(lags, 0)
    hi = np.minimum(n_ref, n_tgt + lags)
    return lo, hi


def _envelope_correlation(
    ref_env: FloatArray, tgt_env: FloatArray, min_overlap: int, max_lag: int | None
) -> tuple[npt.NDArray[np.int64], FloatArray, FloatArray]:
    """Lags, raw correlation and in-overlap normalized correlation of two envelopes."""
    n_ref, n_tgt = len(ref_env), len(tgt_env)
    raw = sps.correlate(ref_env, tgt_env, mode="full", method="fft")
    lags = np.arange(-(n_tgt - 1), n_ref, dtype=np.int64)
    lo, hi = _overlap_bounds(lags, n_ref, n_tgt)
    overlap = hi - lo
    ref_energy = np.concatenate(([0.0], np.cumsum(ref_env * ref_env)))
    tgt_energy = np.concatenate(([0.0], np.cumsum(tgt_env * tgt_env)))
    e_ref = ref_energy[np.clip(hi, 0, n_ref)] - ref_energy[np.clip(lo, 0, n_ref)]
    e_tgt = tgt_energy[np.clip(hi - lags, 0, n_tgt)] - tgt_energy[np.clip(lo - lags, 0, n_tgt)]
    denominator = np.sqrt(np.maximum(e_ref * e_tgt, 1e-30))
    normalized = raw / denominator
    valid = overlap >= min_overlap
    if max_lag is not None:
        valid &= np.abs(lags) <= max_lag
    raw = np.where(valid, raw, -np.inf)
    normalized = np.where(valid, normalized, -np.inf)
    return lags, np.asarray(raw, dtype=np.float64), np.asarray(normalized, dtype=np.float64)


def _local_maxima(values: FloatArray) -> npt.NDArray[np.int64]:
    finite = np.isfinite(values)
    padded = np.concatenate(([-np.inf], np.where(finite, values, -np.inf), [-np.inf]))
    peaks = (padded[1:-1] >= padded[:-2]) & (padded[1:-1] > padded[2:]) & finite
    return np.flatnonzero(peaks).astype(np.int64)


def _event_windows(
    peaks: npt.NDArray[np.int64], hop: int, limit: tuple[int, int]
) -> list[tuple[int, int]]:
    """Reference sample windows around onset peaks (``-EVENT_PRE_S .. +EVENT_POST_S``)."""
    lo, hi = limit
    pre, post = int(EVENT_PRE_S * ANALYSIS_RATE), int(EVENT_POST_S * ANALYSIS_RATE)
    windows = []
    for peak in peaks:
        start, stop = max(lo, int(peak) * hop - pre), min(hi, int(peak) * hop + post)
        if stop - start >= 16:
            windows.append((start, stop))
    return windows


def _windowed_correlation(
    ref: Float32Array, tgt: Float32Array, lag: int, windows: list[tuple[int, int]]
) -> float:
    """Normalized correlation of ``tgt[n]`` and ``ref[n + lag]`` over reference windows."""
    dot = ref_energy = tgt_energy = 0.0
    for start, stop in windows:
        lo, hi = max(start, lag, 0), min(stop, len(tgt) + lag, len(ref))
        if hi - lo < 16:
            continue
        a = ref[lo:hi].astype(np.float64)
        b = tgt[lo - lag : hi - lag].astype(np.float64)
        dot += float(np.dot(a, b))
        ref_energy += float(np.dot(a, a))
        tgt_energy += float(np.dot(b, b))
    denominator = np.sqrt(ref_energy * tgt_energy)
    return dot / float(denominator) if denominator > 0 else 0.0


def _refine(
    ref: Float32Array,
    tgt: Float32Array,
    center: int,
    radius: int,
    windows: list[tuple[int, int]],
) -> tuple[float, float] | None:
    """Sub-sample lag maximizing windowed waveform correlation within ``center +- radius``."""
    if not windows:
        return None
    lags = np.arange(center - radius, center + radius + 1)
    scores = np.array([_windowed_correlation(ref, tgt, int(lag), windows) for lag in lags])
    best = int(np.argmax(scores))
    if best in (0, len(scores) - 1):
        return None
    left, mid, right = scores[best - 1], scores[best], scores[best + 1]
    curvature = left - 2 * mid + right
    delta = 0.5 * (left - right) / curvature if curvature < 0 else 0.0
    return float(lags[best] + delta), float(mid)


# --------------------------------------------------------------------------------------------
# Estimation
# --------------------------------------------------------------------------------------------


def _estimate(
    status: SyncStatus, ref_s: float, tgt_s: float, coarse: _Coarse | None = None, **values: Any
) -> OffsetEstimate:
    evidence: dict[str, Any] = {}
    if coarse is not None:
        evidence = {
            "offset_s": coarse.offset_s,
            "confidence": max(0.0, coarse.confidence),
            "peak_ratio": coarse.peak_ratio,
            "alternatives": coarse.alternatives,
            "matched_onsets": coarse.matched,
            "chance_probability": coarse.chance,
            "reference_onsets": coarse.reference_onsets,
            "target_onsets": coarse.target_onsets,
        }
    evidence.update(values)
    evidence.setdefault("offset", None)
    evidence.setdefault("offset_s", None)
    evidence.setdefault("confidence", 0.0)
    evidence.setdefault("peak_ratio", None)
    evidence.setdefault("refined_correlation", None)
    evidence.setdefault("resolution_s", float(HOP_S))
    return OffsetEstimate(
        status=status, reference_duration_s=ref_s, target_duration_s=tgt_s, **evidence
    )


@dataclass(frozen=True)
class _Coarse:
    lag: int
    """Best lag in hops."""
    offset_s: float
    raw: float
    confidence: float
    peak_ratio: float | None
    alternatives: tuple[OffsetCandidate, ...]
    matched: int
    chance: float
    """Bound on the probability of ``matched`` coincidences between unrelated onset trains."""
    reference_onsets: int
    target_onsets: int


def _chance_probability(
    ref_peaks: npt.NDArray[np.int64],
    tgt_peaks: npt.NDArray[np.int64],
    lag: int,
    overlap: tuple[int, int],
    matched: int,
    searched_lags: int,
) -> float:
    """Probability bound that ``matched`` coincidences arise by chance (module doc, step 5).

    ``overlap`` is the reference hop interval ``[lo, hi)`` covered by both signals at ``lag``;
    ``searched_lags`` is the number of admissible lags of the coarse search.
    """
    if matched <= 0:
        return 1.0
    lo, hi = overlap
    window = 2 * ONSET_TOLERANCE_HOPS + 1
    n_ref = int(np.count_nonzero((ref_peaks >= lo) & (ref_peaks < hi)))
    shifted = tgt_peaks + lag
    n_tgt = max(matched, int(np.count_nonzero((shifted >= lo) & (shifted < hi))))
    p = min(1.0, n_ref * window / max(1, hi - lo))
    tail = float(special.bdtrc(matched - 1, n_tgt, p))  # P(X >= matched), X ~ Bin(n_tgt, p)
    trials = max(1.0, searched_lags / window)
    return min(1.0, trials * tail)


def _coarse_search(
    ref_env: FloatArray, tgt_env: FloatArray, min_overlap_hops: int, max_lag: int | None
) -> _Coarse | None:
    lags, raw, normalized = _envelope_correlation(ref_env, tgt_env, min_overlap_hops, max_lag)
    if not np.isfinite(raw).any():
        return None
    hop_s = float(HOP_S)
    best = int(np.argmax(raw))
    best_raw = float(raw[best])
    peaks = _local_maxima(raw)
    rivals = peaks[np.abs(peaks - best) > int(GUARD_S / hop_s)]
    rivals = rivals[np.argsort(raw[rivals])[::-1]]
    second = float(raw[rivals[0]]) if len(rivals) else 0.0
    ratio = best_raw / second if second > 0 and best_raw > 0 else None
    separation = int(ONSET_SEPARATION_S / hop_s)
    ref_peaks = _onset_peaks(ref_env, separation)
    tgt_peaks = _onset_peaks(tgt_env, separation)
    lag = int(lags[best])
    matched = _matched_onsets(ref_peaks, tgt_peaks, lag, ONSET_TOLERANCE_HOPS)
    overlap = (max(0, lag), min(len(ref_env), len(tgt_env) + lag))
    searched = int(np.count_nonzero(np.isfinite(raw)))
    return _Coarse(
        lag=lag,
        offset_s=float(lag) * hop_s,
        raw=best_raw,
        confidence=float(normalized[best]),
        peak_ratio=ratio,
        alternatives=tuple(
            OffsetCandidate(offset_s=float(lags[i]) * hop_s, score=float(raw[i]) / best_raw)
            for i in rivals[:5]
            if best_raw > 0 and raw[i] >= 0.5 * best_raw
        ),
        matched=matched,
        chance=_chance_probability(ref_peaks, tgt_peaks, lag, overlap, matched, searched),
        reference_onsets=len(ref_peaks),
        target_onsets=len(tgt_peaks),
    )


def _anchors(
    ref: Float32Array,
    tgt: Float32Array,
    lag: float,
    windows: list[tuple[int, int]],
    overlap: tuple[int, int],
    rate: int,
) -> tuple[tuple[AnchorEstimate, ...], float | None]:
    """Local offsets in up to three parts of the overlap; residual = largest deviation."""
    lo, hi = overlap
    length = hi - lo
    parts = 3 if length >= 9 * rate else 2 if length >= 4 * rate else 0
    radius = int(REFINE_RADIUS_S * rate)
    anchors = []
    for index in range(parts):
        start = lo + index * length // parts
        stop = lo + (index + 1) * length // parts
        local = [w for w in windows if start <= w[0] < stop]
        refined = _refine(ref, tgt, round(lag), radius, local)
        if refined is None or refined[1] < MIN_ANCHOR_CORRELATION:
            continue
        centers = [(w[0] + w[1]) / 2 for w in local]
        anchors.append(
            AnchorEstimate(
                reference_time_s=float(np.mean(centers)) / rate,
                offset_s=refined[0] / rate,
                correlation=refined[1],
            )
        )
    if len(anchors) < 2:
        return tuple(anchors), None
    return tuple(anchors), max(abs(a.offset_s - lag / rate) for a in anchors)


def estimate_offset_from_signals(
    reference: npt.ArrayLike,
    reference_rate: int,
    target: npt.ArrayLike,
    target_rate: int,
    *,
    max_offset_s: float | None = None,
    min_overlap_s: float | None = None,
) -> OffsetEstimate:
    """Estimates ``a`` such that the target's time ``t`` shows reference time ``a + t``.

    Inputs are mono PCM arrays at their own sample rates; both are copied to float32 at
    :data:`ANALYSIS_RATE` (the caller's arrays are not modified).
    """
    rate = ANALYSIS_RATE
    return _estimate_analysis(
        _resample(reference, reference_rate, rate),
        _resample(target, target_rate, rate),
        max_offset_s=max_offset_s,
        min_overlap_s=min_overlap_s,
    )


def _estimate_analysis(
    ref: Float32Array,
    tgt: Float32Array,
    *,
    max_offset_s: float | None,
    min_overlap_s: float | None,
) -> OffsetEstimate:
    """The estimation on float32 analysis signals at :data:`ANALYSIS_RATE` (filtered in place)."""
    rate = ANALYSIS_RATE
    _highpass(ref, rate)
    _highpass(tgt, rate)
    ref_s, tgt_s = len(ref) / rate, len(tgt) / rate
    if min(len(ref), len(tgt)) < rate // 2:
        return _estimate(INSUFFICIENT, ref_s, tgt_s, reason="audio shorter than 0.5 s")
    for label, data in (("reference", ref), ("target", tgt)):
        if _rms(data) < SILENCE_RMS:
            return _estimate(
                INSUFFICIENT, ref_s, tgt_s, reason=f"{label} audio is silent (below -60 dBFS)"
            )

    hop = int(HOP_S * rate)
    ref_env, tgt_env = _onset_envelope(ref, hop), _onset_envelope(tgt, hop)
    if not ref_env.any() or not tgt_env.any():
        return _estimate(INSUFFICIENT, ref_s, tgt_s, reason="no transient content to correlate")
    hop_s = float(HOP_S)
    min_overlap = min_overlap_s if min_overlap_s is not None else min(2.0, 0.5 * min(ref_s, tgt_s))
    max_lag = None if max_offset_s is None else int(max_offset_s / hop_s)
    coarse = _coarse_search(ref_env, tgt_env, max(1, int(min_overlap / hop_s)), max_lag)
    if coarse is None:
        return _estimate(INSUFFICIENT, ref_s, tgt_s, reason="no admissible overlap in the bounds")
    if coarse.matched < MIN_MATCHED_ONSETS:
        return _estimate(
            INSUFFICIENT, ref_s, tgt_s, coarse,
            reason=f"only {coarse.matched} coinciding onset(s) at the best alignment",
        )  # fmt: skip
    if coarse.chance > MAX_CHANCE_PROBABILITY:
        return _estimate(
            INSUFFICIENT, ref_s, tgt_s, coarse,
            reason=f"{coarse.matched} coinciding onsets are explained by chance (probability "
            f"{coarse.chance:.2g} > {MAX_CHANCE_PROBABILITY:g})",
        )  # fmt: skip
    if coarse.raw <= 0 or coarse.confidence < MIN_CONFIDENCE:
        return _estimate(
            INSUFFICIENT, ref_s, tgt_s, coarse,
            reason=f"weak correlation (confidence {coarse.confidence:.2f} < {MIN_CONFIDENCE})",
        )  # fmt: skip
    if coarse.peak_ratio is not None and coarse.peak_ratio < MIN_PEAK_RATIO:
        return _estimate(
            SyncStatus.AMBIGUOUS, ref_s, tgt_s, coarse,
            reason=f"competing correlation peaks (ratio {coarse.peak_ratio:.2f} < "
            f"{MIN_PEAK_RATIO})",
        )  # fmt: skip

    lo = max(0, coarse.lag * hop)
    hi = min(len(ref), len(tgt) + coarse.lag * hop)
    ref_peaks = _onset_peaks(ref_env, int(ONSET_SEPARATION_S / hop_s))
    windows = _event_windows(ref_peaks, hop, (lo, hi))
    refined = _refine(ref, tgt, coarse.lag * hop, int(REFINE_RADIUS_S * rate), windows)
    if refined is not None and refined[1] >= MIN_REFINED_CORRELATION:
        lag_samples, refined_corr, resolution = refined[0], refined[1], 1 / rate
    else:
        lag_samples, refined_corr, resolution = float(coarse.lag * hop), None, hop_s
    offset = rational_from_float(lag_samples / rate, rate)
    overlap_start = max(Fraction(0), offset)
    overlap_end = min(Fraction(len(ref), rate), offset + Fraction(len(tgt), rate))
    anchors, residual = _anchors(ref, tgt, lag_samples, windows, (lo, hi), rate)
    return _estimate(
        SyncStatus.OK, ref_s, tgt_s, coarse,
        offset_s=lag_samples / rate,
        offset=offset,
        resolution_s=resolution,
        refined_correlation=refined_corr,
        anchors=anchors,
        residual_s=residual,
        reference_overlap=Interval(start=overlap_start, end=overlap_end),
        target_source_interval=Interval(start=overlap_start - offset, end=overlap_end - offset),
    )  # fmt: skip


def estimate_offset(
    reference_path: Path | str,
    target_path: Path | str,
    *,
    reference_stream: int | None = None,
    target_stream: int | None = None,
    max_offset_s: float | None = None,
    min_overlap_s: float | None = None,
) -> OffsetEstimate:
    """Estimates the target recording's offset ``a`` against the reference from their audio.

    Each stream is decoded once into a float32 array that the estimation then filters in place,
    so the full-length memory is about ``4 * ANALYSIS_RATE`` bytes per second of each recording.
    """
    return _estimate_analysis(
        extract_analysis_audio(reference_path, stream_index=reference_stream),
        extract_analysis_audio(target_path, stream_index=target_stream),
        max_offset_s=max_offset_s,
        min_overlap_s=min_overlap_s,
    )
