"""Shared pytest fixtures: generated synthetic media, asset descriptions and artifact folders."""

from __future__ import annotations

import shutil
from pathlib import Path

import pytest

from ave.fixtures.generate import Fixture, ensure_fixture
from ave.fixtures.standard import StandardFixtures, standard_fixtures, timing_fixture_specs
from ave.media.asset import MediaAsset, describe_asset
from ave.paths import test_artifacts_root

pytest_plugins = ["tests.evidence_plugin", "pytester"]


@pytest.fixture(scope="session")
def std() -> StandardFixtures:
    """Standard composition sources A, B, C and the 2560x1440 clip (cached under var/)."""
    return standard_fixtures()


@pytest.fixture(scope="session")
def timing_fixtures() -> dict[str, Fixture]:
    """Probe/timing fixtures: exact rates, VFR, rotation, SAR, audio layouts, still image."""
    return {key: ensure_fixture(spec) for key, spec in timing_fixture_specs().items()}


@pytest.fixture(scope="session")
def std_assets(std: StandardFixtures) -> dict[str, MediaAsset]:
    """Probed and checksummed assets ``A``, ``B`` and ``C``."""
    return {
        "A": describe_asset(std.a.path, asset_id="A"),
        "B": describe_asset(std.b.path, asset_id="B"),
        "C": describe_asset(std.c.path, asset_id="C"),
    }


@pytest.fixture(scope="session")
def artifacts_dir() -> Path:
    """Fresh ``var/test-artifacts/media`` directory for rendered outputs and reports."""
    path = test_artifacts_root() / "media"
    shutil.rmtree(path, ignore_errors=True)
    path.mkdir(parents=True)
    return path
