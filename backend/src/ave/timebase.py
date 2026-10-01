"""Exact time for every time domain of the editor (ADR-004, AVE-REQ-012).

Every time value is an exact rational number (:class:`fractions.Fraction`). Floats never enter the
model implicitly: :func:`to_rational` rejects them, and :func:`rational_from_float` is the only,
explicit conversion with a declared resolution (used for measured quantities such as estimated
synchronization offsets).

Time domains
------------
The editor distinguishes five time domains. They share the representation but never a variable:

* **source time** (:data:`SourceTime`) - presentation time inside one original media stream, in
  seconds, normalized by the container start time recorded at probe time;
* **reference time** (:data:`ReferenceTime`) - the clock of a synchronization group's reference
  source; source ``i`` maps as ``T_reference = a_i + b_i * t_source_i``;
* **project time** (:data:`ProjectTime`) - the edited timeline of a sequence;
* **section time** (:data:`SectionTime`) - a project interval re-based into an independent output
  (``T_section = T_project - S``);
* **output time** (:data:`OutputTime`) - timestamps of an encoded export, starting at zero.

Functions that convert between domains live next to the entities that define the mapping
(:class:`AffineClockMap` here, clip mapping in :mod:`ave.domain.model`).

Grid rules
----------
Intervals are half-open ``[start, end)``. Output frame ``n`` presents time ``n / fps`` and content
with interval ``[s, e)`` appears on frames ``ceil(s * fps) .. ceil(e * fps) - 1``. Audio sample
``k`` presents time ``k / rate`` with the same rule. Quantization onto a grid happens once, when a
render is planned; intermediate edit operations stay exact.

Representable range
-------------------
Python integers are unbounded, so arithmetic cannot overflow. For interoperability with JSON
clients and FFmpeg, values entering through validation must have a numerator and denominator whose
magnitude fits in a signed 64-bit integer (:data:`MAX_COMPONENT`); larger values are rejected
rather than rounded.
"""

from __future__ import annotations

import math
from collections.abc import Iterator
from enum import StrEnum
from fractions import Fraction
from typing import Annotated, Any, NewType

from pydantic import (
    BaseModel,
    ConfigDict,
    PlainSerializer,
    PlainValidator,
    WithJsonSchema,
    model_validator,
)

__all__ = [
    "MAX_COMPONENT",
    "AffineClockMap",
    "Interval",
    "NonNegativeRational",
    "OutputTime",
    "PositiveRational",
    "ProjectTime",
    "Rational",
    "ReferenceTime",
    "SectionTime",
    "SourceTime",
    "TimeDomain",
    "TimeValueError",
    "frame_at",
    "frame_count",
    "frame_start",
    "frames_in",
    "iter_frame_times",
    "parse_ffmpeg_rational",
    "project_to_reference",
    "project_to_section",
    "rational_from_float",
    "rational_to_json",
    "round_half_up",
    "sample_at",
    "sample_count",
    "sample_start",
    "samples_in",
    "to_rational",
]

MAX_COMPONENT = 2**63 - 1
"""Largest accepted magnitude of a numerator or denominator (signed 64-bit range)."""


class TimeValueError(ValueError):
    """An invalid time value, interval or time transform (error code ``INVALID_TIME_RANGE``)."""

    code = "INVALID_TIME_RANGE"


class TimeDomain(StrEnum):
    """The explicit time domains of the editor (AVE-REQ-012 AC-1)."""

    SOURCE = "source"
    REFERENCE = "reference"
    PROJECT = "project"
    SECTION = "section"
    OUTPUT = "output"


SourceTime = NewType("SourceTime", Fraction)
"""Seconds of presentation time inside one original stream (normalized by the container start)."""
ReferenceTime = NewType("ReferenceTime", Fraction)
"""Seconds on a synchronization group's reference clock."""
ProjectTime = NewType("ProjectTime", Fraction)
"""Seconds on a sequence timeline."""
SectionTime = NewType("SectionTime", Fraction)
"""Seconds inside an independently exported section or short."""
OutputTime = NewType("OutputTime", Fraction)
"""Seconds of an encoded export's presentation timeline (starts at zero)."""


# --------------------------------------------------------------------------------------------
# Conversion and validation
# --------------------------------------------------------------------------------------------


def _check_range(value: Fraction) -> Fraction:
    if abs(value.numerator) > MAX_COMPONENT or value.denominator > MAX_COMPONENT:
        raise TimeValueError(
            f"rational {value} exceeds the representable range (|num|, den <= 2**63 - 1)"
        )
    return value


def to_rational(value: Any) -> Fraction:
    """Converts an exact representation into a :class:`Fraction`.

    Accepted: ``Fraction``, ``int``, ``{"num": int, "den": int}`` with ``den > 0``, and strings
    ``"a/b"``, ``"a:b"`` or exact decimals such as ``"2.5"``. Rejected: ``float`` (including NaN
    and infinities), ``bool``, non-positive denominators, non-finite strings and anything else.
    Unreduced input is normalized to the reduced form.
    """
    if isinstance(value, bool):
        raise TimeValueError("booleans are not time values")
    if isinstance(value, Fraction):
        return _check_range(value)
    if isinstance(value, int):
        return _check_range(Fraction(value))
    if isinstance(value, float):
        raise TimeValueError(
            "floating-point time values are rejected; use rational_from_float() with an explicit"
            " resolution"
        )
    if isinstance(value, dict):
        return _rational_from_mapping(value)
    if isinstance(value, str):
        return _rational_from_string(value)
    raise TimeValueError(f"unsupported time value type: {type(value).__name__}")


def _rational_from_mapping(value: dict[Any, Any]) -> Fraction:
    if set(value) != {"num", "den"}:
        raise TimeValueError('a rational object must have exactly the keys "num" and "den"')
    num, den = value["num"], value["den"]
    if not isinstance(num, int) or isinstance(num, bool):
        raise TimeValueError("rational num must be an integer")
    if not isinstance(den, int) or isinstance(den, bool):
        raise TimeValueError("rational den must be an integer")
    if den <= 0:
        raise TimeValueError("rational den must be positive")
    return _check_range(Fraction(num, den))


def _rational_from_string(value: str) -> Fraction:
    text = value.strip()
    if not text or any(word in text.lower() for word in ("nan", "inf")):
        raise TimeValueError(f"not a finite exact number: {value!r}")
    for separator in ("/", ":"):
        if separator in text:
            num_text, den_text = text.split(separator, 1)
            try:
                num, den = int(num_text), int(den_text)
            except ValueError as exc:
                raise TimeValueError(f"not a rational: {value!r}") from exc
            if den <= 0:
                raise TimeValueError(f"rational denominator must be positive: {value!r}")
            return _check_range(Fraction(num, den))
    try:
        return _check_range(Fraction(text))
    except (ValueError, ZeroDivisionError) as exc:
        raise TimeValueError(f"not an exact number: {value!r}") from exc


def rational_from_float(value: float, resolution: int) -> Fraction:
    """Explicitly converts a measured float into a rational on the grid ``1/resolution``.

    The result is the nearest multiple of ``1/resolution`` (round half up). NaN and infinities are
    rejected. This is the only sanctioned float-to-time conversion.
    """
    if resolution <= 0:
        raise TimeValueError("resolution must be a positive integer")
    if not math.isfinite(value):
        raise TimeValueError(f"cannot convert non-finite value {value!r} to a rational")
    return _check_range(Fraction(round_half_up(Fraction(value) * resolution), resolution))


def parse_ffmpeg_rational(text: str | None) -> Fraction | None:
    """Parses an FFmpeg rational such as ``"60000/1001"``; ``0/0``, ``0`` and ``N/A`` give None."""
    if text is None:
        return None
    text = text.strip()
    if not text or text in {"N/A", "0/0", "0:0"}:
        return None
    try:
        value = to_rational(text)
    except TimeValueError:
        return None
    if value == 0:
        return None
    return value


def rational_to_json(value: Fraction) -> dict[str, int]:
    """Canonical JSON form ``{"num": n, "den": d}`` of a rational (reduced, ``d > 0``)."""
    return {"num": value.numerator, "den": value.denominator}


def _validate_rational(value: Any) -> Fraction:
    return to_rational(value)


def _validate_positive(value: Any) -> Fraction:
    result = to_rational(value)
    if result <= 0:
        raise TimeValueError(f"value must be positive, got {result}")
    return result


def _validate_non_negative(value: Any) -> Fraction:
    result = to_rational(value)
    if result < 0:
        raise TimeValueError(f"value must not be negative, got {result}")
    return result


_RATIONAL_JSON_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "num": {"type": "integer"},
        "den": {"type": "integer", "minimum": 1},
    },
    "required": ["num", "den"],
    "additionalProperties": False,
    "description": "Exact rational number num/den in reduced form with a positive denominator.",
}

_serializer = PlainSerializer(rational_to_json, return_type=dict[str, int], when_used="json")

Rational = Annotated[
    Fraction,
    PlainValidator(_validate_rational),
    _serializer,
    WithJsonSchema(_RATIONAL_JSON_SCHEMA),
]
"""Pydantic field type for an exact rational; JSON form ``{"num", "den"}``."""

PositiveRational = Annotated[
    Fraction,
    PlainValidator(_validate_positive),
    _serializer,
    WithJsonSchema(_RATIONAL_JSON_SCHEMA),
]
"""A rational that must be strictly positive (rates, speeds, scales)."""

NonNegativeRational = Annotated[
    Fraction,
    PlainValidator(_validate_non_negative),
    _serializer,
    WithJsonSchema(_RATIONAL_JSON_SCHEMA),
]
"""A rational that must be zero or positive (timeline positions, source points)."""


def round_half_up(value: Fraction) -> int:
    """Rounds an exact rational to the nearest integer, halves away from minus infinity."""
    return math.floor(value + Fraction(1, 2))


# --------------------------------------------------------------------------------------------
# Intervals
# --------------------------------------------------------------------------------------------


class Interval(BaseModel):
    """A half-open interval ``[start, end)`` of exact time with ``end > start``.

    Empty and negative intervals are rejected (``INVALID_TIME_RANGE``). The domain of the interval
    is given by the field or variable that holds it.
    """

    model_config = ConfigDict(frozen=True, extra="forbid")

    start: Rational
    end: Rational

    @model_validator(mode="after")
    def _check_order(self) -> Interval:
        if self.end <= self.start:
            raise TimeValueError(
                f"interval end must be greater than start: [{self.start}, {self.end})"
            )
        return self

    @classmethod
    def of(cls, start: Any, end: Any) -> Interval:
        """Builds an interval from any exact representation accepted by :func:`to_rational`."""
        return cls(start=to_rational(start), end=to_rational(end))

    @classmethod
    def from_duration(cls, start: Any, duration: Any) -> Interval:
        """Builds ``[start, start + duration)``; the duration must be positive."""
        begin = to_rational(start)
        return cls(start=begin, end=begin + to_rational(duration))

    @property
    def duration(self) -> Fraction:
        """Length ``end - start`` (always positive)."""
        return self.end - self.start

    def contains(self, t: Fraction) -> bool:
        """True when ``start <= t < end`` (the end point is excluded)."""
        return self.start <= t < self.end

    def contains_interval(self, other: Interval) -> bool:
        """True when ``other`` lies completely inside this interval."""
        return self.start <= other.start and other.end <= self.end

    def overlaps(self, other: Interval) -> bool:
        """True when the two half-open intervals share at least one instant."""
        return self.start < other.end and other.start < self.end

    def intersection(self, other: Interval) -> Interval | None:
        """The common part, or ``None`` when the intervals do not overlap."""
        start, end = max(self.start, other.start), min(self.end, other.end)
        if end <= start:
            return None
        return Interval(start=start, end=end)

    def shift(self, offset: Fraction) -> Interval:
        """The interval moved by ``offset`` seconds."""
        return Interval(start=self.start + offset, end=self.end + offset)

    def __str__(self) -> str:
        return f"[{self.start}, {self.end})"


# --------------------------------------------------------------------------------------------
# Frame and sample grids
# --------------------------------------------------------------------------------------------


def _require_positive_rate(rate: Fraction | int) -> Fraction:
    value = to_rational(rate)
    if value <= 0:
        raise TimeValueError(f"rate must be positive, got {value}")
    return value


def frame_start(n: int, fps: Fraction) -> Fraction:
    """Presentation time of output frame ``n``: ``n * fps.den / fps.num`` seconds (exact)."""
    rate = _require_positive_rate(fps)
    return Fraction(n * rate.denominator, rate.numerator)


def frame_at(t: Fraction, fps: Fraction) -> int:
    """Index of the frame whose display period ``[n/fps, (n+1)/fps)`` contains ``t``."""
    return math.floor(to_rational(t) * _require_positive_rate(fps))


def frames_in(interval: Interval, fps: Fraction) -> range:
    """Frames ``n`` with ``interval.start <= n / fps < interval.end``.

    That is ``ceil(start * fps) .. ceil(end * fps) - 1``; the range can be empty when the interval
    is shorter than one frame period and contains no grid point.
    """
    rate = _require_positive_rate(fps)
    return range(math.ceil(interval.start * rate), math.ceil(interval.end * rate))


def frame_count(duration: Fraction, fps: Fraction) -> int:
    """Number of frames presented in ``[0, duration)``."""
    if duration <= 0:
        return 0
    return math.ceil(to_rational(duration) * _require_positive_rate(fps))


def sample_start(k: int, rate: int | Fraction) -> Fraction:
    """Presentation time of audio sample ``k`` at ``rate`` samples per second."""
    return Fraction(k) / _require_positive_rate(rate)


def sample_at(t: Fraction, rate: int | Fraction) -> int:
    """Index of the sample period that contains ``t``."""
    return math.floor(to_rational(t) * _require_positive_rate(rate))


def samples_in(interval: Interval, rate: int | Fraction) -> range:
    """Samples ``k`` with ``interval.start <= k / rate < interval.end``."""
    value = _require_positive_rate(rate)
    return range(math.ceil(interval.start * value), math.ceil(interval.end * value))


def sample_count(duration: Fraction, rate: int | Fraction) -> int:
    """Number of samples presented in ``[0, duration)``."""
    if duration <= 0:
        return 0
    return math.ceil(to_rational(duration) * _require_positive_rate(rate))


def iter_frame_times(interval: Interval, fps: Fraction) -> Iterator[tuple[int, Fraction]]:
    """Yields ``(n, n / fps)`` for every frame presented in ``interval``."""
    for n in frames_in(interval, fps):
        yield n, frame_start(n, fps)


# --------------------------------------------------------------------------------------------
# Synchronization clock maps
# --------------------------------------------------------------------------------------------


class AffineClockMap(BaseModel):
    """Maps one source clock onto a synchronization reference clock.

    ``T_reference = a + b * t_source`` where ``a`` is the offset in reference seconds and ``b`` the
    source-to-reference clock scale (``b > 0``). The reference source itself has ``a = 0, b = 1``.
    Example from the specification: B starts two seconds after A, so ``a_B = 2, b_B = 1``;
    reference time 10 s reads A at 10 s and B at 8 s.
    """

    model_config = ConfigDict(frozen=True, extra="forbid")

    a: Rational
    b: PositiveRational = Fraction(1)

    def to_reference(self, t: SourceTime) -> ReferenceTime:
        """Reference time of source time ``t``."""
        return ReferenceTime(self.a + self.b * t)

    def to_source(self, t: ReferenceTime) -> SourceTime:
        """Source time that shows reference time ``t``: ``(t - a) / b``."""
        return SourceTime((t - self.a) / self.b)

    def source_interval(self, reference: Interval) -> Interval:
        """Source interval covering the reference interval ``[G0, G1)``."""
        return Interval(
            start=self.to_source(ReferenceTime(reference.start)),
            end=self.to_source(ReferenceTime(reference.end)),
        )

    def reference_interval(self, source: Interval) -> Interval:
        """Reference interval covered by the source interval."""
        return Interval(
            start=self.to_reference(SourceTime(source.start)),
            end=self.to_reference(SourceTime(source.end)),
        )


def project_to_reference(
    t: ProjectTime, project_start: ProjectTime, reference_start: ReferenceTime
) -> ReferenceTime:
    """Reference time shown at project time ``t`` for a segment placed at ``P0`` showing ``G0``.

    ``T_reference = G0 + (T_project - P0)`` (no editorial speed change).
    """
    return ReferenceTime(reference_start + (t - project_start))


def project_to_section(t: ProjectTime, section_start: ProjectTime) -> SectionTime:
    """Section time of project time ``t`` for a section that starts at project time ``S``."""
    return SectionTime(t - section_start)
