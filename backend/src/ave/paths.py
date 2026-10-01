"""Application-owned filesystem roots.

All runtime output (generated fixtures, render work directories, test artifacts, later the data
root) lives below one *var root*: ``$AVE_VAR_DIR`` when set, otherwise the repository's gitignored
``var/`` directory. Nothing is ever written next to imported originals.
"""

from __future__ import annotations

import os
from pathlib import Path

__all__ = ["fixtures_root", "render_work_root", "test_artifacts_root", "var_root"]

_REPOSITORY_ROOT = Path(__file__).resolve().parents[3]


def var_root() -> Path:
    """The runtime root directory (created on demand)."""
    configured = os.environ.get("AVE_VAR_DIR")
    root = Path(configured).expanduser().resolve() if configured else _REPOSITORY_ROOT / "var"
    root.mkdir(parents=True, exist_ok=True)
    return root


def _subdir(name: str) -> Path:
    path = var_root() / name
    path.mkdir(parents=True, exist_ok=True)
    return path


def fixtures_root() -> Path:
    """Cache of generated synthetic fixtures (``var/fixtures``)."""
    return _subdir("fixtures")


def render_work_root() -> Path:
    """Scratch space for render intermediates (``var/render-work``)."""
    return _subdir("render-work")


def test_artifacts_root() -> Path:
    """Outputs of test runs kept for inspection (``var/test-artifacts``)."""
    return _subdir("test-artifacts")
