"""The fixture cache key follows the generator's sources: AVE-REQ-097 AC-2.

A fixture cached by an older generator must never serve a run of an edited one: stale files in the
ignored cache directory would let a media test pass on a tree whose generator is broken. The
generator's sources are its own three modules and every ``ave`` module they import.
"""

from __future__ import annotations

import hashlib
import shutil
import subprocess
import sys
from fractions import Fraction
from pathlib import Path

import pytest

from ave.fixtures import generate
from ave.fixtures.generate import FixtureSpec, VideoSpec, generator_digest, generator_sources

pytestmark = pytest.mark.req("AVE-REQ-097 AC-2")

SOURCE_ROOT = Path(generate.__file__).resolve().parents[2]

# Written by hand from the import statements of the generator: its three modules, the modules
# they import, the modules those import, and the packages above each.
GENERATOR_MODULES = {
    "ave": "ave/__init__.py",
    "ave.errors": "ave/errors.py",
    "ave.fixtures": "ave/fixtures/__init__.py",
    "ave.fixtures.barcode": "ave/fixtures/barcode.py",
    "ave.fixtures.generate": "ave/fixtures/generate.py",
    "ave.fixtures.standard": "ave/fixtures/standard.py",
    "ave.media": "ave/media/__init__.py",
    "ave.media.asset": "ave/media/asset.py",
    "ave.media.probe": "ave/media/probe.py",
    "ave.paths": "ave/paths.py",
    "ave.proc": "ave/proc.py",
    "ave.timebase": "ave/timebase.py",
}


def _spec() -> FixtureSpec:
    return FixtureSpec(
        name="cache-key",
        description="cache key probe",
        duration=Fraction(1),
        video=VideoSpec(width=64, height=36, fps=Fraction(30), color=(10, 20, 30)),
    )


def _sources_only(directory: str, names: list[str]) -> list[str]:
    """The entries of ``directory`` that a copy leaves out: all but subdirectories and sources."""
    return [
        name
        for name in names
        if name == "__pycache__" or not (name.endswith(".py") or Path(directory, name).is_dir())
    ]


def _copy_of_the_package(tmp_path: Path) -> Path:
    """A copy of the sources of the ``ave`` package below ``tmp_path``, its package root."""
    shutil.copytree(SOURCE_ROOT / "ave", tmp_path / "ave", ignore=_sources_only)
    return tmp_path


def _append(path: Path, text: str) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(text)


def test_the_cache_key_changes_with_the_generator_sources(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(generate, "ffmpeg_version", lambda: "ffmpeg version test")
    before = _spec().cache_key()
    assert before == _spec().cache_key()
    monkeypatch.setattr(generate, "generator_digest", lambda: "0" * 16)
    assert _spec().cache_key() != before


def test_the_generator_sources_are_its_modules_and_every_ave_module_they_import() -> None:
    sources = generator_sources()
    assert {name: path.relative_to(SOURCE_ROOT).as_posix() for name, path in sources.items()} == (
        GENERATOR_MODULES
    )


def test_the_generator_digest_is_the_hash_of_the_generator_sources() -> None:
    expected = hashlib.sha256()
    for name, relative in sorted(GENERATOR_MODULES.items()):
        data = (SOURCE_ROOT / relative).read_bytes()
        expected.update(f"{name}\0{len(data)}\0".encode() + data)
    assert generator_digest() == expected.hexdigest()[:16]


def test_every_ave_module_that_the_generator_loads_is_among_its_sources() -> None:
    """A second reading: the modules a fresh interpreter holds after it imported the generator."""
    listing = subprocess.run(
        [
            sys.executable,
            "-c",
            "import sys, ave.fixtures.standard\n"
            "print('\\n'.join(sorted(n for n in sys.modules if n.split('.')[0] == 'ave')))",
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=120,
    )
    loaded = set(listing.stdout.split())
    assert {"ave.fixtures.standard", "ave.proc", "ave.media.probe", "ave.errors"} <= loaded
    assert loaded <= set(generator_sources())


@pytest.mark.parametrize("helper", ["ave/proc.py", "ave/media/probe.py", "ave/errors.py"])
def test_an_edit_to_an_imported_helper_changes_the_digest(tmp_path: Path, helper: str) -> None:
    root = _copy_of_the_package(tmp_path)
    _append(root / helper, "\nEDITED = True\n")
    assert generator_digest(root) != generator_digest()


def test_a_copy_of_the_sources_has_the_same_digest_and_an_edit_outside_them_keeps_it(
    tmp_path: Path,
) -> None:
    root = _copy_of_the_package(tmp_path)
    _append(root / "ave/render/compiler.py", "\nEDITED = True\n")
    assert "ave.render.compiler" not in generator_sources(root)
    assert generator_digest(root) == generator_digest()


def test_imports_inside_functions_and_in_relative_form_join_the_sources(tmp_path: Path) -> None:
    root = _copy_of_the_package(tmp_path)
    (root / "ave/fixtures/extra_one.py").write_text("ONE = 1\n", encoding="utf-8")
    (root / "ave/extra_two.py").write_text("from .domain import rates\n", encoding="utf-8")
    _append(
        root / "ave/fixtures/barcode.py",
        "\n\ndef late() -> None:\n    from . import extra_one\n    from .. import extra_two\n",
    )
    assert set(generator_sources(root)) == set(GENERATOR_MODULES) | {
        "ave.fixtures.extra_one",
        "ave.extra_two",
        "ave.domain",
        "ave.domain.rates",
    }
