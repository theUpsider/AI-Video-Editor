"""Typed composition document: sequences, tracks, clips and synchronization groups (ADR-004).

All models are frozen Pydantic v2 models; edits produce new values (``model_copy``), which keeps
revision snapshots immutable. Times are exact rationals in explicitly named domains:

* ``Clip.timeline_start`` is **project time**;
* ``Clip.source_in`` / ``Clip.source_out`` are **source time** of the clip's asset (half-open);
* ``SyncMember.a`` is **reference time** (seconds on the group's reference clock).

Clip mapping: project time ``T`` in ``[timeline_start, timeline_start + d)`` shows source time
``t = source_in + (T - timeline_start) * source_speed`` with ``d = (source_out - source_in) /
source_speed``. ``source_speed`` is source seconds per project second; synchronization drift
correction uses ``1 / b``.

Track semantics: video tracks stack by ``index`` (higher index on top); ``hidden`` video tracks are
not rendered. An audio track is audible when it is not ``muted`` and, if any audio track is
``solo``, it is solo itself. ``solo`` on video tracks follows the same rule among video tracks.
"""

from __future__ import annotations

import itertools
import math
import re
from fractions import Fraction
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, field_validator
from pydantic import model_validator as _model_validator

from ave.timebase import (
    AffineClockMap,
    Interval,
    NonNegativeRational,
    PositiveRational,
    ProjectTime,
    Rational,
    SourceTime,
    TimeValueError,
)

__all__ = [
    "FULL_FRAME",
    "Canvas",
    "Clip",
    "ClipKind",
    "Fit",
    "Identifier",
    "NormRect",
    "Sequence",
    "SyncAnchor",
    "SyncGroup",
    "SyncMember",
    "Track",
    "TrackKind",
]

Identifier = Annotated[
    str, StringConstraints(min_length=1, max_length=128, pattern=r"^[A-Za-z0-9][A-Za-z0-9_.:-]*$")
]
"""Stable object identifier (letters, digits and ``_ . : -``)."""

TrackKind = Literal["video", "audio"]
ClipKind = Literal["video", "audio", "image"]
Fit = Literal["contain", "cover", "stretch"]
"""Region fitting. ``stretch`` changes the aspect ratio and is never a default."""

_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")


class _Frozen(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")


class Canvas(_Frozen):
    """Output canvas in square pixels; defaults to 1920x1080 (AVE-REQ-018 AC-1)."""

    width: int = Field(default=1920, ge=16, le=16384)
    height: int = Field(default=1080, ge=16, le=16384)

    @property
    def aspect(self) -> Fraction:
        """Exact width / height."""
        return Fraction(self.width, self.height)


class NormRect(_Frozen):
    """A rectangle in canvas fractions: ``x, y`` top-left, ``w, h`` size; all in ``[0, 1]``."""

    x: NonNegativeRational = Fraction(0)
    y: NonNegativeRational = Fraction(0)
    w: PositiveRational = Fraction(1)
    h: PositiveRational = Fraction(1)

    @_model_validator(mode="after")
    def _inside_canvas(self) -> NormRect:
        if self.x + self.w > 1 or self.y + self.h > 1:
            raise ValueError(f"region must lie inside the canvas: {self}")
        return self


FULL_FRAME = NormRect()
"""The whole canvas."""


class Track(_Frozen):
    """A video or audio track; video z-order follows ``index`` (higher on top)."""

    id: Identifier
    kind: TrackKind
    name: str = ""
    index: int = Field(ge=0)
    muted: bool = False
    solo: bool = False
    locked: bool = False
    hidden: bool = False


class Clip(_Frozen):
    """A placed reference to a half-open source interval of one asset stream."""

    id: Identifier
    track_id: Identifier
    asset_id: Identifier
    kind: ClipKind
    timeline_start: NonNegativeRational
    """Project time at which the clip starts."""
    source_in: NonNegativeRational
    """Source time of the first presented instant (inclusive)."""
    source_out: NonNegativeRational
    """Source time where the clip ends (exclusive)."""
    source_speed: PositiveRational = Fraction(1)
    """Source seconds per project second (``1 / b`` for drift correction)."""
    stream_index: int | None = Field(default=None, ge=0)
    """Absolute container stream index; ``None`` selects the first stream of the clip's kind."""
    region: NormRect = FULL_FRAME
    fit: Fit = "contain"
    focus_x: NonNegativeRational = Fraction(1, 2)
    """Horizontal focus point for cover cropping, 0 (left) .. 1 (right)."""
    focus_y: NonNegativeRational = Fraction(1, 2)
    """Vertical focus point for cover cropping, 0 (top) .. 1 (bottom)."""
    gain_db: float = 0.0
    enabled: bool = True
    link_group: Identifier | None = None
    locked: bool = False

    @field_validator("focus_x", "focus_y")
    @classmethod
    def _unit_focus(cls, value: Fraction) -> Fraction:
        if value > 1:
            raise ValueError("focus must lie in [0, 1]")
        return value

    @field_validator("gain_db")
    @classmethod
    def _finite_gain(cls, value: float) -> float:
        if not math.isfinite(value) or not -96.0 <= value <= 24.0:
            raise ValueError("gain_db must be finite and within [-96, 24] dB")
        return value

    @_model_validator(mode="after")
    def _valid_source_bounds(self) -> Clip:
        if self.source_out <= self.source_in:
            raise TimeValueError(
                f"clip {self.id}: source_out must be greater than source_in "
                f"([{self.source_in}, {self.source_out}))"
            )
        return self

    @property
    def source_interval(self) -> Interval:
        """Source-time interval ``[source_in, source_out)``."""
        return Interval(start=self.source_in, end=self.source_out)

    @property
    def duration(self) -> Fraction:
        """Project-time duration ``(source_out - source_in) / source_speed``."""
        return (self.source_out - self.source_in) / self.source_speed

    @property
    def timeline_end(self) -> Fraction:
        """Project time where the clip ends (exclusive)."""
        return self.timeline_start + self.duration

    @property
    def timeline_interval(self) -> Interval:
        """Project-time interval occupied by the clip."""
        return Interval(start=self.timeline_start, end=self.timeline_end)

    def source_time_at(self, t: ProjectTime) -> SourceTime:
        """Source time shown at project time ``t`` (``t`` must lie inside the clip)."""
        if not self.timeline_interval.contains(t):
            raise TimeValueError(f"project time {t} lies outside clip {self.id}")
        return SourceTime(self.source_in + (t - self.timeline_start) * self.source_speed)

    def project_time_of(self, t: SourceTime) -> ProjectTime:
        """Project time at which source time ``t`` is shown (``t`` must lie inside the clip)."""
        if not self.source_interval.contains(t):
            raise TimeValueError(f"source time {t} lies outside clip {self.id}")
        return ProjectTime(self.timeline_start + (t - self.source_in) / self.source_speed)


class SyncAnchor(_Frozen):
    """One piece of alignment evidence: a source instant matched to a reference instant."""

    reference_time: Rational
    source_time: Rational
    score: float = Field(ge=-1.0, le=1.0)
    """Normalized correlation (or 1.0 for a user-confirmed anchor)."""


class SyncMember(_Frozen):
    """Mapping of one asset's clock onto the group reference: ``T_ref = a + b * t_source``."""

    asset_id: Identifier
    a: Rational
    """Offset in reference seconds."""
    b: PositiveRational = Fraction(1)
    """Source-to-reference clock scale."""
    method: str = Field(min_length=1, max_length=64)
    confidence: float = Field(ge=0.0, le=1.0)
    anchors: tuple[SyncAnchor, ...] = ()
    residual_s: float | None = Field(default=None, ge=0.0)
    user_supplied: bool = False

    @property
    def clock_map(self) -> AffineClockMap:
        """The member's source-to-reference map."""
        return AffineClockMap(a=self.a, b=self.b)


class SyncGroup(_Frozen):
    """Synchronized assets sharing one reference clock (the reference has ``a=0, b=1``)."""

    id: Identifier
    reference_asset_id: Identifier
    members: tuple[SyncMember, ...]
    sign_convention: Literal["T_reference = a + b * t_source"] = "T_reference = a + b * t_source"

    @_model_validator(mode="after")
    def _check_members(self) -> SyncGroup:
        ids = [member.asset_id for member in self.members]
        if len(ids) != len(set(ids)):
            raise ValueError(f"sync group {self.id}: duplicate member assets")
        reference = self.member(self.reference_asset_id)
        if reference.a != 0 or reference.b != 1:
            raise ValueError(f"sync group {self.id}: the reference member must have a=0, b=1")
        return self

    def member(self, asset_id: str) -> SyncMember:
        """The member for ``asset_id``."""
        for member in self.members:
            if member.asset_id == asset_id:
                return member
        raise KeyError(f"asset {asset_id} is not a member of sync group {self.id}")


class Sequence(_Frozen):
    """A timeline with its output canvas, rate, tracks, clips and synchronization groups."""

    id: Identifier
    name: str = ""
    kind: Literal["main", "short"] = "main"
    parent_id: Identifier | None = None
    canvas: Canvas = Canvas()
    fps: PositiveRational
    """Exact output frame rate (``60/1`` and ``60000/1001`` are different rates)."""
    sample_rate: int = Field(default=48000, ge=8000, le=192000)
    background: str = "#000000"
    tracks: tuple[Track, ...] = ()
    clips: tuple[Clip, ...] = ()
    sync_groups: tuple[SyncGroup, ...] = ()

    @field_validator("background")
    @classmethod
    def _hex_color(cls, value: str) -> str:
        if not _COLOR.match(value):
            raise ValueError("background must be a #RRGGBB color")
        return value.upper()

    @_model_validator(mode="after")
    def _check_structure(self) -> Sequence:
        _require_unique("track", [t.id for t in self.tracks])
        _require_unique("clip", [c.id for c in self.clips])
        _require_unique("sync group", [g.id for g in self.sync_groups])
        _require_unique("track index", [(t.kind, t.index) for t in self.tracks])
        tracks = {t.id: t for t in self.tracks}
        for clip in self.clips:
            track = tracks.get(clip.track_id)
            if track is None:
                raise ValueError(f"clip {clip.id} references unknown track {clip.track_id}")
            expected = "audio" if clip.kind == "audio" else "video"
            if track.kind != expected:
                raise ValueError(f"{clip.kind} clip {clip.id} cannot sit on {track.kind} track")
        for track in self.tracks:
            ordered = sorted(self.clips_on(track.id), key=lambda c: c.timeline_start)
            for before, after in itertools.pairwise(ordered):
                if after.timeline_start < before.timeline_end:
                    raise TimeValueError(
                        f"clips {before.id} and {after.id} overlap on track {track.id}"
                    )
        return self

    def track(self, track_id: str) -> Track:
        """The track with ``track_id``."""
        for track in self.tracks:
            if track.id == track_id:
                return track
        raise KeyError(f"unknown track {track_id}")

    def clips_on(self, track_id: str) -> tuple[Clip, ...]:
        """Clips placed on ``track_id`` in document order."""
        return tuple(c for c in self.clips if c.track_id == track_id)

    @property
    def end(self) -> Fraction:
        """Project time where the last enabled clip ends (0 for an empty sequence)."""
        ends = [c.timeline_end for c in self.clips if c.enabled]
        return max(ends, default=Fraction(0))

    def rendered_tracks(self, kind: TrackKind) -> tuple[Track, ...]:
        """Tracks of ``kind`` that contribute to the output, honoring mute/hidden and solo."""
        tracks = [t for t in self.tracks if t.kind == kind]
        if any(t.solo for t in tracks):
            tracks = [t for t in tracks if t.solo]
        if kind == "audio":
            return tuple(t for t in tracks if not t.muted)
        return tuple(t for t in tracks if not t.hidden)

    def sync_group(self, group_id: str) -> SyncGroup:
        """The synchronization group with ``group_id``."""
        for group in self.sync_groups:
            if group.id == group_id:
                return group
        raise KeyError(f"unknown sync group {group_id}")


def _require_unique(label: str, values: list[object]) -> None:
    seen: set[object] = set()
    for value in values:
        if value in seen:
            raise ValueError(f"duplicate {label}: {value}")
        seen.add(value)
