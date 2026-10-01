"""Builds timeline clips from synchronization groups (split/full/split layouts, AVE-REQ-020/021).

A synchronized segment shows the reference interval ``[G0, G1)`` starting at project time ``P0``.
For member ``i`` with ``T_ref = a_i + b_i * t_i`` the clip reads source time
``t_i = (G0 - a_i) / b_i`` onward with ``source_speed = 1 / b_i``, so its project duration is
``G1 - G0`` for every member. Final audio is an explicit, per-segment choice: every member gets an
audio clip, and only the selected member's clip is enabled (the others stay on the timeline,
disabled, and remain available for analysis).
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from fractions import Fraction

from ave.domain.layout import split_regions
from ave.domain.model import FULL_FRAME, Clip, ClipKind, Fit, NormRect, SyncGroup, SyncMember
from ave.errors import SourceBoundsError
from ave.timebase import Interval

__all__ = [
    "SyncedSource",
    "common_overlap",
    "full_frame_clips",
    "member_coverage",
    "split_screen_clips",
    "synced_clip",
]


@dataclass(frozen=True)
class SyncedSource:
    """Where one perspective of a synchronized segment goes on the timeline."""

    asset_id: str
    video_track_id: str
    audio_track_id: str | None = None


def member_coverage(member: SyncMember, source_duration: Fraction) -> Interval:
    """Reference interval covered by the member's source ``[0, source_duration)``."""
    return member.clock_map.reference_interval(Interval(start=Fraction(0), end=source_duration))


def common_overlap(
    group: SyncGroup,
    source_durations: Mapping[str, Fraction],
    asset_ids: Iterable[str] | None = None,
) -> Interval:
    """Reference interval covered by every selected member (default split coverage).

    Example from the specification: A covers ``[0, 30)``, B (``a=2``) source ``[0, 25)`` covers
    reference ``[2, 27)``; the common overlap is ``[2, 27)``.
    """
    ids = list(asset_ids) if asset_ids is not None else [m.asset_id for m in group.members]
    coverage: Interval | None = None
    for asset_id in ids:
        span = member_coverage(group.member(asset_id), source_durations[asset_id])
        coverage = span if coverage is None else coverage.intersection(span)
        if coverage is None:
            raise SourceBoundsError("the selected sync members have no common coverage")
    if coverage is None:
        raise ValueError("no members selected")
    return coverage


def synced_clip(
    *,
    clip_id: str,
    member: SyncMember,
    reference: Interval,
    project_start: Fraction,
    track_id: str,
    kind: ClipKind,
    region: NormRect = FULL_FRAME,
    fit: Fit = "contain",
    enabled: bool = True,
    link_group: str | None = None,
    source_duration: Fraction | None = None,
) -> Clip:
    """A clip showing reference interval ``reference`` of ``member`` from ``project_start``."""
    source = member.clock_map.source_interval(reference)
    if source.start < 0 or (source_duration is not None and source.end > source_duration):
        raise SourceBoundsError(
            f"asset {member.asset_id} does not cover reference interval {reference}",
            asset_id=member.asset_id,
            source_interval=str(source),
        )
    return Clip(
        id=clip_id,
        track_id=track_id,
        asset_id=member.asset_id,
        kind=kind,
        timeline_start=project_start,
        source_in=source.start,
        source_out=source.end,
        source_speed=1 / member.b,
        region=region,
        fit=fit,
        enabled=enabled,
        link_group=link_group,
    )


def split_screen_clips(
    group: SyncGroup,
    reference: Interval,
    project_start: Fraction,
    left: SyncedSource,
    right: SyncedSource,
    *,
    audio_asset_id: str | None,
    id_prefix: str,
    fit: Fit = "contain",
    divider: Fraction = Fraction(1, 2),
    gap: Fraction = Fraction(0),
    source_durations: Mapping[str, Fraction] | None = None,
) -> tuple[Clip, ...]:
    """Left/right split-screen clips for one synchronized segment, plus explicit audio routing.

    Both video clips and every member's audio clip share one link group. ``audio_asset_id`` selects
    the final audio; the other members' audio clips are added disabled.
    """
    if audio_asset_id is not None and audio_asset_id not in {left.asset_id, right.asset_id}:
        raise ValueError("the selected audio must belong to one of the split perspectives")
    durations = source_durations or {}
    left_region, right_region = split_regions(divider, gap)
    clips: list[Clip] = []
    for role, source, region in (("left", left, left_region), ("right", right, right_region)):
        member = group.member(source.asset_id)
        clips.append(
            synced_clip(
                clip_id=f"{id_prefix}.{role}.video",
                member=member,
                reference=reference,
                project_start=project_start,
                track_id=source.video_track_id,
                kind="video",
                region=region,
                fit=fit,
                link_group=id_prefix,
                source_duration=durations.get(source.asset_id),
            )
        )
        if source.audio_track_id is not None:
            clips.append(
                synced_clip(
                    clip_id=f"{id_prefix}.{role}.audio",
                    member=member,
                    reference=reference,
                    project_start=project_start,
                    track_id=source.audio_track_id,
                    kind="audio",
                    enabled=source.asset_id == audio_asset_id,
                    link_group=id_prefix,
                    source_duration=durations.get(source.asset_id),
                )
            )
    return tuple(clips)


def full_frame_clips(
    source: SyncedSource,
    source_interval: Interval,
    project_start: Fraction,
    *,
    id_prefix: str,
    fit: Fit = "contain",
    use_audio: bool = True,
) -> tuple[Clip, ...]:
    """A single full-canvas perspective (and its audio) for an unsynchronized segment."""
    clips = [
        Clip(
            id=f"{id_prefix}.video",
            track_id=source.video_track_id,
            asset_id=source.asset_id,
            kind="video",
            timeline_start=project_start,
            source_in=source_interval.start,
            source_out=source_interval.end,
            region=FULL_FRAME,
            fit=fit,
            link_group=id_prefix,
        )
    ]
    if source.audio_track_id is not None:
        clips.append(
            Clip(
                id=f"{id_prefix}.audio",
                track_id=source.audio_track_id,
                asset_id=source.asset_id,
                kind="audio",
                timeline_start=project_start,
                source_in=source_interval.start,
                source_out=source_interval.end,
                enabled=use_audio,
                link_group=id_prefix,
            )
        )
    return tuple(clips)
