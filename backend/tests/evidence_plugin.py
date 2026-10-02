"""Pytest plugin: requirement tags, evidence reports and the no-skip rule (AVE-REQ-097).

Markers:

* ``@pytest.mark.req("AVE-REQ-NNN AC-n", ...)`` - the acceptance criteria a test verifies, one full
  tag per criterion (docs/TRACEABILITY.md, Conventions);
* ``@pytest.mark.scenario("AT-NN", ...)`` - acceptance scenarios the test runs;
* ``@pytest.mark.contract`` - the test replaces an external provider with a fake: it proves the
  interface only and never evidences a criterion on its own (scripts/evidence.py).

At collection every tag is checked against the working requirement files and the baseline
scenarios; a malformed tag or one naming a criterion that does not exist is a usage error, so
evidence can never point at nothing.

Options:

* ``--evidence-report PATH`` writes one JSON record per test (node ID, outcome, tags, contract
  flag) for ``scripts/evidence.py``;
* ``--forbid-skips`` fails the session when any test is skipped, expected to fail or
  unexpectedly passes: a test that did not run proves nothing, so verification never lets one
  through as green.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = 1
_NOT_RUN = ("skipped", "xfailed", "xpassed")


def _evidence_module() -> ModuleType:
    """scripts/evidence.py, the single parser of requirement files and tags."""
    path = ROOT / "scripts" / "evidence.py"
    spec = importlib.util.spec_from_file_location("ave_repository_evidence", path)
    if spec is None or spec.loader is None:  # pragma: no cover - the file is a required file
        raise pytest.UsageError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module  # dataclasses resolve annotations through sys.modules
    previous, sys.dont_write_bytecode = sys.dont_write_bytecode, True
    try:
        spec.loader.exec_module(module)
    finally:
        sys.dont_write_bytecode = previous
    return module


def pytest_addoption(parser: pytest.Parser) -> None:
    group = parser.getgroup("evidence", "requirement evidence (AVE-REQ-097)")
    group.addoption("--evidence-report", metavar="PATH", help="write per-test evidence as JSON")
    group.addoption(
        "--forbid-skips",
        action="store_true",
        help="fail the session when any test is skipped, xfailed or xpassed",
    )


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers", "req(*tags): acceptance criteria verified ('AVE-REQ-NNN AC-n')"
    )
    config.addinivalue_line("markers", "scenario(*ids): acceptance scenarios run ('AT-NN')")
    config.addinivalue_line(
        "markers", "contract: replaces an external provider with a fake; proves the interface only"
    )
    config.pluginmanager.register(EvidenceRecorder(config), "ave-evidence-recorder")


def _tags(item: pytest.Item, name: str) -> list[str]:
    tags: list[str] = []
    for mark in item.iter_markers(name):
        if not mark.args or mark.kwargs or not all(isinstance(arg, str) for arg in mark.args):
            raise pytest.UsageError(f"{item.nodeid}: @pytest.mark.{name} takes tag strings only")
        tags.extend(mark.args)
    return sorted(set(tags))


def _outcome(report: pytest.TestReport) -> str | None:
    """The outcome a phase report decides, or None when the phase decides nothing."""
    if hasattr(report, "wasxfail"):
        return "xpassed" if report.passed else "xfailed"
    if report.when == "call":
        return report.outcome
    if report.failed:
        return "error"
    if report.skipped:
        return "skipped"
    return None


class EvidenceRecorder:
    """Validates the tags of the collected tests and records each test's outcome."""

    def __init__(self, config: pytest.Config) -> None:
        self.config = config
        self.results: dict[str, dict[str, Any]] = {}

    def pytest_collection_modifyitems(self, items: list[pytest.Item]) -> None:
        evidence = _evidence_module()
        known = evidence.requirements()
        problems = []
        for item in items:
            criteria, scenarios = _tags(item, "req"), _tags(item, "scenario")
            problems += [
                f"{item.nodeid}: {problem}"
                for problem in evidence.tag_problems(criteria, scenarios, known)
            ]
            self.results[item.nodeid] = {
                "nodeid": item.nodeid,
                "req": criteria,
                "scenario": scenarios,
                "contract": item.get_closest_marker("contract") is not None,
                "markers": sorted({mark.name for mark in item.iter_markers()}),
                "outcome": "not-run",
                "duration": 0.0,
            }
        if problems:
            raise pytest.UsageError("invalid evidence tags:\n  " + "\n  ".join(problems))

    def pytest_runtest_logreport(self, report: pytest.TestReport) -> None:
        record = self.results.get(report.nodeid)
        if record is None:
            return
        record["duration"] += report.duration
        outcome = _outcome(report)
        # The first non-passing phase decides (a teardown error after a passed call is an error).
        if outcome is not None and record["outcome"] in ("not-run", "passed"):
            record["outcome"] = outcome

    def pytest_sessionfinish(self, session: pytest.Session, exitstatus: int) -> None:
        ran = [record for record in self.results.values() if record["outcome"] != "not-run"]
        path = self.config.getoption("--evidence-report")
        if path:
            report = {"schema": SCHEMA, "exitstatus": int(exitstatus), "tests": ran}
            target = Path(path)
            target.parent.mkdir(parents=True, exist_ok=True)
            text = json.dumps(report, indent=2, sort_keys=True) + "\n"
            target.write_text(text, encoding="utf-8")
        not_run = [record["nodeid"] for record in ran if record["outcome"] in _NOT_RUN]
        if self.config.getoption("--forbid-skips") and not_run:
            reporter = self.config.pluginmanager.get_plugin("terminalreporter")
            if reporter is not None:
                reporter.write_line(
                    f"--forbid-skips: {len(not_run)} test(s) did not run as passing tests:",
                    red=True,
                )
                for nodeid in not_run:
                    reporter.write_line(f"  {nodeid}")
            session.exitstatus = pytest.ExitCode.TESTS_FAILED
