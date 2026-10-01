"""Composition document and synchronized layouts.

AVE-REQ-020 (split layout binding), AVE-REQ-021 (mixed segments), AVE-REQ-031 (explicit audio).
"""

from __future__ import annotations

from fractions import Fraction

import pytest
from pydantic import ValidationError

from ave.domain.model import Clip, Sequence, SyncGroup, SyncMember, Track
from ave.domain.sync_layout import (
    SyncedSource,
    common_overlap,
    member_coverage,
    split_screen_clips,
    synced_clip,
)
from ave.errors import SourceBoundsError
from ave.timebase import Interval, ProjectTime, SourceTime
from tests.compositions import LEFT, RIGHT, TRACKS, standard_sequence, sync_group

B_TRUE = SyncMember(asset_id="B", a=Fraction(2), method="ground-truth", confidence=1.0)


def _clip(clip_id: str, track: str, start: int, source: tuple[int, int], **extra: object) -> Clip:
    return Clip.model_validate(
        {
            "id": clip_id,
            "track_id": track,
            "asset_id": "A",
            "kind": "video",
            "timeline_start": start,
            "source_in": source[0],
            "source_out": source[1],
            **extra,
        }
    )


def test_standard_composition_matches_the_specification_table() -> None:
    """AVE-REQ-021 AC-1 / AC-2 / AC-4: split [0,8), full [8,14), split [14,22) with routing."""
    sequence = standard_sequence(sync_group(B_TRUE))
    clips = {c.id: c for c in sequence.clips}
    expected = {
        "split-1.left.video": ("A", 0, (2, 10)),
        "split-1.right.video": ("B", 0, (0, 8)),
        "full-c.video": ("C", 8, (0, 6)),
        "split-2.left.video": ("A", 14, (12, 20)),
        "split-2.right.video": ("B", 14, (10, 18)),
    }
    for clip_id, (asset, start, (source_in, source_out)) in expected.items():
        clip = clips[clip_id]
        assert clip.asset_id == asset
        assert clip.timeline_start == start
        assert (clip.source_in, clip.source_out) == (source_in, source_out)
    assert sequence.end == 22
    audible = {c.id for c in sequence.clips if c.kind == "audio" and c.enabled}
    assert audible == {"split-1.left.audio", "full-c.audio", "split-2.left.audio"}
    # Layout is chosen per segment (split regions vs full frame), not globally.
    assert clips["split-1.left.video"].region.w == Fraction(1, 2)
    assert clips["full-c.video"].region.w == 1


def test_split_layout_binds_sync_members_without_changing_audio() -> None:
    """AVE-REQ-020 AC-4 / AVE-REQ-031 AC-1: B's audio stays available but is not in the mix."""
    group = sync_group(B_TRUE)
    clips = split_screen_clips(
        group, Interval.of(2, 10), Fraction(0), LEFT, RIGHT, audio_asset_id="A", id_prefix="s"
    )
    by_id = {c.id: c for c in clips}
    assert by_id["s.right.audio"].asset_id == "B"
    assert by_id["s.right.audio"].enabled is False
    assert by_id["s.left.audio"].enabled is True
    assert {c.link_group for c in clips} == {"s"}
    swapped = split_screen_clips(
        group, Interval.of(2, 10), Fraction(0), RIGHT, LEFT, audio_asset_id="A", id_prefix="s"
    )
    assert next(c for c in swapped if c.id == "s.left.video").asset_id == "B"
    assert next(c for c in swapped if c.id == "s.right.audio").enabled is True


def test_default_coverage_is_the_common_overlap() -> None:
    """AVE-REQ-020 AC-4 / spec example: A [0,30), B [0,25) at a=2 overlap on reference [2,27)."""
    group = sync_group(B_TRUE)
    durations = {"A": Fraction(30), "B": Fraction(25)}
    assert member_coverage(group.member("B"), Fraction(25)) == Interval.of(2, 27)
    overlap = common_overlap(group, durations)
    assert overlap == Interval.of(2, 27)
    assert overlap.duration == 25
    clips = split_screen_clips(
        group, overlap, Fraction(0), LEFT, RIGHT, audio_asset_id="A", id_prefix="s",
        source_durations=durations,
    )  # fmt: skip
    video = {c.asset_id: c for c in clips if c.kind == "video"}
    assert (video["A"].source_in, video["A"].source_out) == (2, 27)
    assert (video["B"].source_in, video["B"].source_out) == (0, 25)
    with pytest.raises(SourceBoundsError):
        split_screen_clips(
            group, Interval.of(1, 27), Fraction(0), LEFT, RIGHT, audio_asset_id="A",
            id_prefix="s", source_durations=durations,
        )  # fmt: skip


def test_clock_drift_maps_to_source_speed_without_changing_duration() -> None:
    """AVE-REQ-012 AC-4: clip speed 1/b keeps the reference duration on the project timeline."""
    member = SyncMember(
        asset_id="B", a=Fraction(2), b=Fraction(1001, 1000), method="m", confidence=1
    )
    clip = synced_clip(
        clip_id="c", member=member, reference=Interval.of(12, 20), project_start=Fraction(14),
        track_id="v-b", kind="video",
    )  # fmt: skip
    assert clip.source_speed == Fraction(1000, 1001)
    assert clip.duration == 8
    assert clip.source_in == (12 - 2) / Fraction(1001, 1000)


def test_editorial_speed_is_separate_from_drift_correction() -> None:
    """AVE-REQ-012 AC-4, AVE-REQ-012 AC-2: t = source_in + (T - timeline_start) * source_speed
    * editorial_speed (ADR-004 decision 4); duration and the inverse mapping use the product;
    documents without the field load with editorial speed 1; zero speed is rejected."""
    clip = _clip(
        "c", "v-b", 10, (3, 7), source_speed=Fraction(1000, 1001), editorial_speed=Fraction(2)
    )
    assert clip.speed == Fraction(2000, 1001)
    assert clip.duration == Fraction(4 * 1001, 2000)
    assert clip.source_time_at(ProjectTime(Fraction(11))) == 3 + Fraction(2000, 1001)
    assert clip.project_time_of(SourceTime(3 + Fraction(2000, 1001))) == 11
    legacy = _clip("c", "v-b", 10, (3, 7), source_speed=Fraction(1000, 1001)).model_dump(
        mode="json"
    )
    del legacy["editorial_speed"]
    loaded = Clip.model_validate(legacy)
    assert loaded.editorial_speed == 1
    assert loaded.speed == Fraction(1000, 1001)
    assert Clip.model_validate_json(clip.model_dump_json()) == clip
    with pytest.raises(ValidationError):
        _clip("c", "v-b", 10, (3, 7), editorial_speed=0)


def test_synced_builders_apply_editorial_speed_to_every_perspective() -> None:
    """AVE-REQ-012 AC-4: a split-screen segment at editorial speed 2 keeps drift correction
    1 / b in source_speed, halves the project duration of every clip and shows the same
    reference instant in both perspectives at every project time."""
    member = SyncMember(
        asset_id="B", a=Fraction(2), b=Fraction(1001, 1000), method="m", confidence=1
    )
    group = sync_group(member)
    clips = split_screen_clips(
        group, Interval.of(12, 20), Fraction(14), LEFT, RIGHT, audio_asset_id="A",
        id_prefix="s", editorial_speed=Fraction(2),
    )  # fmt: skip
    assert {c.editorial_speed for c in clips} == {2}
    assert {c.duration for c in clips} == {4}
    by_id = {c.id: c for c in clips}
    left, right = by_id["s.left.video"], by_id["s.right.video"]
    assert (left.source_speed, right.source_speed) == (1, Fraction(1000, 1001))
    for project in (
        ProjectTime(Fraction(14)),
        ProjectTime(Fraction(31, 2)),
        ProjectTime(Fraction(17)),
    ):
        reference_a = group.member("A").clock_map.to_reference(left.source_time_at(project))
        reference_b = member.clock_map.to_reference(right.source_time_at(project))
        assert reference_a == reference_b == 12 + 2 * (project - 14)


def test_sequence_validation_rejects_inconsistent_documents() -> None:
    """Overlaps on one track, wrong track kinds and unknown tracks are rejected."""
    with pytest.raises(ValidationError, match="overlap"):
        Sequence(
            id="s", fps=Fraction(60), tracks=TRACKS,
            clips=(_clip("x", "v-a", 0, (0, 5)), _clip("y", "v-a", 4, (0, 5))),
        )  # fmt: skip
    with pytest.raises(ValidationError, match="cannot sit"):
        Sequence(id="s", fps=Fraction(60), tracks=TRACKS, clips=(_clip("x", "a-a", 0, (0, 5)),))
    with pytest.raises(ValidationError, match="unknown track"):
        Sequence(id="s", fps=Fraction(60), tracks=TRACKS, clips=(_clip("x", "nope", 0, (0, 5)),))
    with pytest.raises(ValidationError):
        Sequence(id="s", fps=Fraction(0), tracks=TRACKS)
    with pytest.raises(ValidationError, match="reference member"):
        SyncGroup(
            id="g", reference_asset_id="A",
            members=(SyncMember(asset_id="A", a=Fraction(1), method="m", confidence=1),),
        )  # fmt: skip


def test_track_mute_solo_and_hidden_rules() -> None:
    """AVE-REQ-031: routing honors mute and solo; hidden video tracks are not rendered."""
    tracks = (
        Track(id="v1", kind="video", index=0, hidden=True),
        Track(id="v2", kind="video", index=1),
        Track(id="a1", kind="audio", index=0, muted=True),
        Track(id="a2", kind="audio", index=1),
        Track(id="a3", kind="audio", index=2),
    )
    sequence = Sequence(id="s", fps=Fraction(60), tracks=tracks)
    assert [t.id for t in sequence.rendered_tracks("video")] == ["v2"]
    assert [t.id for t in sequence.rendered_tracks("audio")] == ["a2", "a3"]
    solo = sequence.model_copy(
        update={"tracks": (*tracks[:4], Track(id="a3", kind="audio", index=2, solo=True))}
    )
    assert [t.id for t in solo.rendered_tracks("audio")] == ["a3"]


def test_document_round_trips_through_json() -> None:
    """The composition serializes with exact {num, den} values and reloads unchanged."""
    sequence = standard_sequence(sync_group(B_TRUE), fps=Fraction(60000, 1001))
    text = sequence.model_dump_json()
    assert '"fps":{"num":60000,"den":1001}' in text
    assert Sequence.model_validate_json(text) == sequence


def test_unrelated_source_has_no_common_coverage() -> None:
    """A member that never overlaps the reference has no split coverage."""
    late = SyncMember(asset_id="B", a=Fraction(40), method="m", confidence=1)
    group = SyncGroup(
        id="g", reference_asset_id="A",
        members=(SyncMember(asset_id="A", a=Fraction(0), method="m", confidence=1), late),
    )  # fmt: skip
    with pytest.raises(SourceBoundsError):
        common_overlap(group, {"A": Fraction(30), "B": Fraction(25)})
    assert isinstance(SyncedSource("A", "v"), SyncedSource)
