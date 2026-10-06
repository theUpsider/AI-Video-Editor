"""The fixture cache key follows the generator's sources: AVE-REQ-097 AC-2.

A fixture cached by an older generator must never serve a run of an edited one: stale files in the
ignored cache directory would let a media test pass on a tree whose generator is broken.
"""

from __future__ import annotations

import hashlib
from fractions import Fraction
from pathlib import Path

import pytest

from ave.fixtures import generate
from ave.fixtures.generate import FixtureSpec, VideoSpec, generator_digest

pytestmark = pytest.mark.req("AVE-REQ-097 AC-2")


def _spec() -> FixtureSpec:
    return FixtureSpec(
        name="cache-key",
        description="cache key probe",
        duration=Fraction(1),
        video=VideoSpec(width=64, height=36, fps=Fraction(30), color=(10, 20, 30)),
    )


def test_the_cache_key_changes_with_the_generator_sources(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(generate, "ffmpeg_version", lambda: "ffmpeg version test")
    before = _spec().cache_key()
    assert before == _spec().cache_key()
    monkeypatch.setattr(generate, "generator_digest", lambda: "0" * 16)
    assert _spec().cache_key() != before


def test_the_generator_digest_is_the_hash_of_the_generator_sources() -> None:
    package = Path(generate.__file__).resolve().parent
    expected = hashlib.sha256()
    for name in ("barcode.py", "generate.py", "standard.py"):
        expected.update((package / name).read_bytes())
    assert generator_digest() == expected.hexdigest()[:16]
