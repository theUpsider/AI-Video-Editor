"""Auto frame-rate resolution for a sequence (AVE-REQ-018 AC-2/AC-3).

Rules:

1. Without any video source the rate is a *provisional* 30/1.
2. The first resolution uses the selected reference source, otherwise the dominant rate (largest
   total video duration; ties prefer the higher rate). A constant-rate source contributes its exact
   ``r_frame_rate`` (``60/1`` stays ``60/1``, ``60000/1001`` stays ``60000/1001``); a
   variable-rate source contributes the standard rate nearest to its average rate.
3. Once resolved, the rate never changes because of a later import; only an explicit user or AI
   operation changes it (:func:`update_auto_frame_rate` returns the unchanged resolution).
"""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable
from dataclasses import dataclass
from fractions import Fraction

from ave.media.asset import MediaAsset
from ave.media.probe import VideoStreamInfo

__all__ = [
    "PROVISIONAL_FPS",
    "STANDARD_RATES",
    "RateResolution",
    "resolve_auto_frame_rate",
    "stream_frame_rate",
    "update_auto_frame_rate",
]

PROVISIONAL_FPS = Fraction(30)
STANDARD_RATES = tuple(
    Fraction(value)
    for value in (
        "24000/1001", "24", "25", "30000/1001", "30", "48", "50", "60000/1001", "60",
        "100", "120000/1001", "120",
    )
)  # fmt: skip


@dataclass(frozen=True)
class RateResolution:
    """The sequence rate chosen by the Auto setting and why."""

    fps: Fraction
    provisional: bool
    source_asset_id: str | None
    reason: str


def stream_frame_rate(stream: VideoStreamInfo) -> Fraction | None:
    """Exact rate of a CFR stream, or the nearest standard rate of a VFR stream's average."""
    if stream.frame_timing == "cfr" and stream.r_frame_rate is not None:
        return stream.r_frame_rate
    average = stream.avg_frame_rate or stream.r_frame_rate
    if average is None:
        return None
    return min(STANDARD_RATES, key=lambda rate: (abs(rate - average), -rate))


def _video(asset: MediaAsset) -> VideoStreamInfo | None:
    stream = asset.video_stream()
    if stream is None or stream.frame_timing == "unknown":  # stills carry no frame rate
        return None
    return stream


def resolve_auto_frame_rate(
    assets: Iterable[MediaAsset], reference_asset_id: str | None = None
) -> RateResolution:
    """Resolves the Auto rate from the reference source or the dominant source rate."""
    candidates = [(asset, stream) for asset in assets if (stream := _video(asset)) is not None]
    for asset, stream in candidates:
        if asset.id == reference_asset_id and (rate := stream_frame_rate(stream)) is not None:
            return RateResolution(rate, False, asset.id, "rate of the selected reference source")
    weight: dict[Fraction, Fraction] = defaultdict(Fraction)
    first_source: dict[Fraction, str] = {}
    for asset, stream in candidates:
        rate = stream_frame_rate(stream)
        if rate is not None:
            weight[rate] += stream.duration or Fraction(0)
            first_source.setdefault(rate, asset.id)
    if not weight:
        return RateResolution(PROVISIONAL_FPS, True, None, "no video source yet: provisional")
    rate = max(weight, key=lambda value: (weight[value], value))
    return RateResolution(rate, False, first_source[rate], "dominant source rate by duration")


def update_auto_frame_rate(
    current: RateResolution | None,
    assets: Iterable[MediaAsset],
    reference_asset_id: str | None = None,
) -> RateResolution:
    """Resolution after an import: a resolved rate is kept; a provisional one may resolve."""
    if current is not None and not current.provisional:
        return current
    return resolve_auto_frame_rate(assets, reference_asset_id)
