"""The specification's standard 22-second composition, built through the domain API.

Project ``[0, 8)`` split A ``[2, 10)`` | B ``[0, 8)``; ``[8, 14)`` full-width C ``[0, 6)``;
``[14, 22)`` split A ``[12, 20)`` | B ``[10, 18)``. Final audio: A in the split segments, C in the
full-width segment; B's audio clips stay on the timeline but disabled (muted in the export).
"""

from __future__ import annotations

from fractions import Fraction

from ave.domain.model import Fit, Sequence, SyncGroup, SyncMember, Track
from ave.domain.sync_layout import SyncedSource, full_frame_clips, split_screen_clips
from ave.timebase import Interval

TRACKS = (
    Track(id="v-a", kind="video", name="Camera A", index=0),
    Track(id="v-b", kind="video", name="Camera B", index=1),
    Track(id="v-c", kind="video", name="Joint shot C", index=2),
    Track(id="a-a", kind="audio", name="Camera A audio", index=0),
    Track(id="a-b", kind="audio", name="Camera B audio", index=1),
    Track(id="a-c", kind="audio", name="Joint shot C audio", index=2),
)
LEFT = SyncedSource(asset_id="A", video_track_id="v-a", audio_track_id="a-a")
RIGHT = SyncedSource(asset_id="B", video_track_id="v-b", audio_track_id="a-b")
FULL = SyncedSource(asset_id="C", video_track_id="v-c", audio_track_id="a-c")


def reference_member() -> SyncMember:
    """A as the synchronization reference (a=0, b=1)."""
    return SyncMember(asset_id="A", a=Fraction(0), method="reference", confidence=1.0)


def sync_group(member_b: SyncMember) -> SyncGroup:
    """A/B synchronization group with A as reference."""
    return SyncGroup(id="sync-ab", reference_asset_id="A", members=(reference_member(), member_b))


def standard_sequence(
    group: SyncGroup, *, fit: Fit = "contain", fps: Fraction = Fraction(60)
) -> Sequence:
    """The AT-02 split/full/split sequence at 1920x1080."""
    clips = (
        *split_screen_clips(
            group, Interval.of(2, 10), Fraction(0), LEFT, RIGHT,
            audio_asset_id="A", id_prefix="split-1", fit=fit,
        ),
        *full_frame_clips(FULL, Interval.of(0, 6), Fraction(8), id_prefix="full-c"),
        *split_screen_clips(
            group, Interval.of(12, 20), Fraction(14), LEFT, RIGHT,
            audio_asset_id="A", id_prefix="split-2", fit=fit,
        ),
    )  # fmt: skip
    return Sequence(
        id="at02",
        name="AT-02 standard composition",
        fps=fps,
        tracks=TRACKS,
        clips=clips,
        sync_groups=(group,),
    )
