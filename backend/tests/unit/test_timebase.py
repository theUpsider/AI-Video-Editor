"""Exact timing model: AVE-REQ-012 (canonical rational timing and temporal invariants)."""

from __future__ import annotations

import json
import random
from fractions import Fraction

import pytest
from pydantic import BaseModel, ValidationError

from ave.domain.model import Clip
from ave.timebase import (
    AffineClockMap,
    Interval,
    ProjectTime,
    Rational,
    ReferenceTime,
    SourceTime,
    TimeDomain,
    TimeValueError,
    frame_at,
    frame_count,
    frame_start,
    frames_in,
    parse_ffmpeg_rational,
    project_to_reference,
    project_to_section,
    rational_from_float,
    sample_count,
    samples_in,
    to_rational,
)

NTSC60 = Fraction(60000, 1001)


class _Holder(BaseModel):
    value: Rational


@pytest.mark.req("AVE-REQ-012 AC-1")
def test_time_domains_are_explicit_and_mapped_by_the_spec_convention() -> None:
    """AVE-REQ-012 AC-1: source, reference, project, section and output time are distinct.

    Spec example: A is the reference, B starts 2 s later (a_B = 2, b_B = 1); reference time 10 s
    reads A at 10 s and B at 8 s.
    """
    assert {d.value for d in TimeDomain} == {"source", "reference", "project", "section", "output"}
    a_map = AffineClockMap(a=Fraction(0))
    b_map = AffineClockMap(a=Fraction(2), b=Fraction(1))
    t_ref = ReferenceTime(Fraction(10))
    assert a_map.to_source(t_ref) == 10
    assert b_map.to_source(t_ref) == 8
    assert b_map.to_reference(SourceTime(Fraction(8))) == 10
    # A segment placed at project 14 s showing reference 12 s onward.
    t_project = ProjectTime(Fraction(15))
    reference = project_to_reference(
        t_project, ProjectTime(Fraction(14)), ReferenceTime(Fraction(12))
    )
    assert reference == 13
    assert b_map.to_source(reference) == 11
    assert project_to_section(t_project, ProjectTime(Fraction(14))) == 1
    clip = Clip(
        id="c",
        track_id="v",
        asset_id="b",
        kind="video",
        timeline_start=Fraction(14),
        source_in=Fraction(10),
        source_out=Fraction(18),
    )
    assert clip.source_time_at(t_project) == 11
    assert clip.project_time_of(SourceTime(Fraction(11))) == 15


@pytest.mark.req("AVE-REQ-012 AC-1")
def test_affine_map_with_clock_scale_round_trips_exactly() -> None:
    """AVE-REQ-012 AC-1: drift scale b maps source and reference intervals exactly."""
    clock = AffineClockMap(a=Fraction(-7, 3), b=Fraction(1001, 1000))
    for t in (Fraction(0), Fraction(1, 7), Fraction(12345, 60)):
        assert clock.to_source(clock.to_reference(SourceTime(t))) == t
    span = clock.reference_interval(Interval.of(0, 25))
    assert clock.source_interval(span) == Interval.of(0, 25)


@pytest.mark.req("AVE-REQ-012 AC-2")
def test_intervals_are_half_open() -> None:
    """AVE-REQ-012 AC-2: [3, 6) holds 3 but not 6; frames 180..359 at 60 fps."""
    overlay = Interval.of(3, 6)
    assert overlay.contains(Fraction(3))
    assert not overlay.contains(Fraction(6))
    assert frames_in(overlay, Fraction(60)) == range(180, 360)
    assert Interval.of(0, 3).intersection(Interval.of(3, 6)) is None
    assert not Interval.of(0, 3).overlaps(Interval.of(3, 6))
    assert samples_in(Interval.of(0, 1), 48000) == range(48000)


@pytest.mark.req("AVE-REQ-012 AC-2")
@pytest.mark.parametrize(("start", "end"), [(5, 5), (6, 3), (0, -1)])
def test_empty_and_negative_intervals_are_rejected(start: int, end: int) -> None:
    """AVE-REQ-012 AC-2: negative durations and empty intervals are invalid."""
    with pytest.raises((TimeValueError, ValidationError)):
        Interval.of(start, end)


@pytest.mark.req("AVE-REQ-012 AC-2")
@pytest.mark.parametrize(
    "value",
    [
        float("nan"),
        float("inf"),
        2.5,
        True,
        "nan",
        "inf",
        "1/0",
        "-3/-2x",
        {"num": 1, "den": 0},
        {"num": 1, "den": -2},
        {"num": 1.5, "den": 2},
        {"num": 1},
        2**63,
        None,
    ],
)
def test_invalid_time_values_are_rejected(value: object) -> None:
    """AVE-REQ-012 AC-2: NaN, floats, bad denominators and out-of-range values are rejected."""
    with pytest.raises((TimeValueError, ValidationError)):
        _Holder.model_validate({"value": value})


@pytest.mark.req("AVE-REQ-012 AC-2")
def test_floats_need_an_explicit_resolution() -> None:
    """AVE-REQ-012 AC-2: floats enter only through explicit conversion on a declared grid."""
    assert rational_from_float(2.0000000245, 48000) == 2
    assert rational_from_float(0.5, 1000) == Fraction(1, 2)
    with pytest.raises(TimeValueError):
        rational_from_float(float("nan"), 48000)
    with pytest.raises(TimeValueError):
        rational_from_float(1.0, 0)


@pytest.mark.req("AVE-REQ-012 AC-2")
def test_invalid_source_bounds_and_time_transforms_are_rejected() -> None:
    """AVE-REQ-012 AC-2: source_out <= source_in, negative points, zero speed or scale fail."""
    base = {"id": "c", "track_id": "v", "asset_id": "a", "kind": "video", "timeline_start": 0}
    with pytest.raises(ValidationError):
        Clip.model_validate({**base, "source_in": 4, "source_out": 4})
    with pytest.raises(ValidationError):
        Clip.model_validate({**base, "source_in": -1, "source_out": 4})
    with pytest.raises(ValidationError):
        Clip.model_validate({**base, "source_in": 0, "source_out": 4, "source_speed": 0})
    with pytest.raises(ValidationError):
        AffineClockMap.model_validate({"a": 0, "b": {"num": -1, "den": 2}})


@pytest.mark.req("AVE-REQ-012 AC-2")
def test_json_form_is_reduced_num_den() -> None:
    """AVE-REQ-012 AC-2: canonical JSON {"num", "den"} with reduced positive denominator."""
    holder = _Holder.model_validate({"value": {"num": 120000, "den": 2002}})
    assert json.loads(holder.model_dump_json()) == {"value": {"num": 60000, "den": 1001}}
    assert _Holder.model_validate_json('{"value": {"num": 60000, "den": 1001}}').value == NTSC60
    assert to_rational("60000/1001") == NTSC60
    assert to_rational("2.5") == Fraction(5, 2)
    assert parse_ffmpeg_rational("0/0") is None
    assert parse_ffmpeg_rational("60/1") == 60


@pytest.mark.req("AVE-REQ-012 AC-3")
def test_60000_over_1001_is_not_60() -> None:
    """AVE-REQ-012 AC-3: the NTSC rate stays distinct from 60 and frame times are exact."""
    assert NTSC60 != 60
    assert frame_start(1, NTSC60) == Fraction(1001, 60000)
    assert frame_start(60000, NTSC60) == 1001
    assert frame_count(Fraction(1001), NTSC60) == 60000
    assert frame_count(Fraction(1), NTSC60) == 60  # frames 0..59 start before 1 s (59 * 1001/60000)
    assert frame_count(Fraction(2), NTSC60) == 120  # 119.88 frames -> frames 0..119
    assert frame_count(Fraction(2), Fraction(60)) == 120
    assert frame_start(10**6, NTSC60) != frame_start(10**6, Fraction(60))


@pytest.mark.req("AVE-REQ-012 AC-3")
def test_long_timeline_frame_grid_is_exact() -> None:
    """AVE-REQ-012 AC-3: 10**6 frames at 60000/1001 keep exact times and indices."""
    n = 10**6
    t = frame_start(n, NTSC60)
    assert t == Fraction(n * 1001, 60000)
    assert frame_at(t, NTSC60) == n
    assert frame_at(t - Fraction(1, 10**12), NTSC60) == n - 1
    rng = random.Random(1001)
    for _ in range(2000):
        k = rng.randrange(0, 10**9)
        assert frame_at(frame_start(k, NTSC60), NTSC60) == k
        assert frames_in(
            Interval(start=frame_start(k, NTSC60), end=frame_start(k + 3, NTSC60)), NTSC60
        ) == range(k, k + 3)
    # Rounding the rate (here to 59.94) would move frame 10**6 by about a whole frame.
    rounded_rate = Fraction(5994, 100)
    assert (frame_start(n, rounded_rate) - t) * NTSC60 > Fraction(1, 2)
    assert frame_at(t, Fraction(60)) != n


@pytest.mark.req("AVE-REQ-012 AC-3")
def test_repeated_edits_do_not_accumulate_error() -> None:
    """AVE-REQ-012 AC-3: 20,000 random moves, trims and splits at 60000/1001 stay exact.

    The oracle tracks every value as an integer number of 1/60000 s ticks; the model must agree
    with it exactly after every operation (no rounding of the rate or of intermediate values).
    """
    rng = random.Random(7)
    tick = Fraction(1, 60000)
    clip = Clip(
        id="c",
        track_id="v",
        asset_id="a",
        kind="video",
        timeline_start=Fraction(0),
        source_in=Fraction(0),
        source_out=frame_start(10**6, NTSC60),
    )
    ticks = {"start": 0, "in": 0, "out": 10**6 * 1001}
    for step in range(20_000):
        frames = rng.randrange(1, 500)
        delta_ticks = frames * 1001
        operation = step % 3
        if operation == 0:  # move later or earlier
            sign = -1 if ticks["start"] >= delta_ticks and rng.random() < 0.5 else 1
            ticks["start"] += sign * delta_ticks
            clip = clip.model_copy(
                update={"timeline_start": clip.timeline_start + sign * frame_start(frames, NTSC60)}
            )
        elif operation == 1 and ticks["out"] - ticks["in"] > 2 * delta_ticks:  # trim head
            ticks["in"] += delta_ticks
            ticks["start"] += delta_ticks
            clip = clip.model_copy(
                update={
                    "source_in": clip.source_in + frame_start(frames, NTSC60),
                    "timeline_start": clip.timeline_start + frame_start(frames, NTSC60),
                }
            )
        elif ticks["out"] - ticks["in"] > 2 * delta_ticks:  # split and keep the left part
            ticks["out"] -= delta_ticks
            clip = clip.model_copy(
                update={"source_out": clip.source_out - frame_start(frames, NTSC60)}
            )
        assert clip.timeline_start == ticks["start"] * tick
        assert clip.source_in == ticks["in"] * tick
        assert clip.source_out == ticks["out"] * tick
    assert clip.duration == (ticks["out"] - ticks["in"]) * tick
    assert (clip.duration * NTSC60).denominator == 1  # still a whole number of frames


@pytest.mark.req("AVE-REQ-012 AC-3")
def test_sample_grid_follows_the_same_rule() -> None:
    """AVE-REQ-012 AC-3: audio samples use k / rate with the half-open grid rule."""
    assert sample_count(Fraction(22), 48000) == 1_056_000
    assert sample_count(Fraction(1001, 60000), 48000) == 801  # 800.8 -> samples 0..800
    assert samples_in(Interval.of(Fraction(1, 3), 1), 48000) == range(16000, 48000)
