"""Publishing guard of the renderer: an original is never the render destination."""

from __future__ import annotations

from fractions import Fraction
from pathlib import Path

import pytest

from ave.domain.model import Canvas, Clip, Sequence, Track
from ave.errors import AveError
from ave.render.compiler import RenderPlan, compile_render_plan
from ave.render.ffmpeg import OUTPUT_PATH_CONFLICT, render
from tests.assets import fake_asset

ORIGINAL_BYTES = b"original camera file - must never change"


def _plan_for(video: Path, audio: Path) -> RenderPlan:
    """A plan reading ``video`` (picture) and ``audio`` (sound) from two assets."""
    assets = {
        "V": fake_asset("V", duration=Fraction(10)).model_copy(update={"path": str(video)}),
        "S": fake_asset("S", duration=Fraction(10)).model_copy(update={"path": str(audio)}),
    }
    clips = (
        Clip(id="v", track_id="v", asset_id="V", kind="video", timeline_start=Fraction(0),
             source_in=Fraction(0), source_out=Fraction(1)),
        Clip(id="a", track_id="a", asset_id="S", kind="audio", timeline_start=Fraction(0),
             source_in=Fraction(0), source_out=Fraction(1)),
    )  # fmt: skip
    tracks = (Track(id="v", kind="video", index=0), Track(id="a", kind="audio", index=0))
    sequence = Sequence(
        id="s", fps=Fraction(30), canvas=Canvas(width=320, height=180), tracks=tracks, clips=clips
    )
    return compile_render_plan(sequence, assets)


def test_render_refuses_every_destination_that_is_an_input(tmp_path: Path) -> None:
    """AVE-REQ-072 AC-4: a destination equal to an input file - by path, through ``..``, a
    symbolic link or a hard link, for picture and sound inputs - is refused before any work;
    the originals keep their bytes and no partial file appears."""
    media = tmp_path / "media"
    media.mkdir()
    video, audio = media / "camera-a.mp4", media / "recorder.wav"
    video.write_bytes(ORIGINAL_BYTES)
    audio.write_bytes(ORIGINAL_BYTES)
    (tmp_path / "links").mkdir()
    symlink = tmp_path / "links" / "export.mp4"
    symlink.symlink_to(video)
    hardlink = tmp_path / "links" / "hard.wav"
    hardlink.hardlink_to(audio)
    plan = _plan_for(video, audio)
    for destination in (video, media / ".." / "media" / "camera-a.mp4", symlink, audio, hardlink):
        with pytest.raises(AveError) as refused:
            render(plan, destination, work_dir=tmp_path / "work")
        assert refused.value.code == OUTPUT_PATH_CONFLICT
    assert video.read_bytes() == ORIGINAL_BYTES
    assert audio.read_bytes() == ORIGINAL_BYTES
    assert sorted(p.name for p in media.iterdir()) == ["camera-a.mp4", "recorder.wav"]
    assert sorted(p.name for p in (tmp_path / "links").iterdir()) == ["export.mp4", "hard.wav"]
    assert not (tmp_path / "work").exists()  # refused before any intermediate was created
