"""Pytest plugin: requirement tags, evidence reports and the no-skip rule (AVE-REQ-097).

* ``@pytest.mark.req("AVE-REQ-NNN AC-n", ...)`` names the acceptance criteria a test verifies and
  ``@pytest.mark.scenario("AT-NN", ...)`` the acceptance scenarios it runs. ``req`` goes on unit
  and integration tests alike; ``scenario`` only on tests that judge real rendered output.
* ``@pytest.mark.contract`` marks a test that replaces an external provider with a fake: it proves
  the interface only and never evidences a criterion on its own (scripts/evidence.py).
* Every tag is validated at collection against the working requirement files
  (docs/requirements/) and the baseline scenario list: an unknown tag stops the run, so
  evidence can never point at nothing.
* Every collected test file and every loaded conftest.py is a file Git knows: one that an ignore
  rule hides stops the run, so evidence comes only from files of the tree the fingerprint names.
* ``--evidence-report PATH`` writes one JSON record per collected test (node ID, outcome, tags,
  contract flag) for ``scripts/evidence.py``, with the invocation (arguments, configuration
  file). A deselected test is recorded as ``deselected`` and a selected test that never started
  as ``not-run``: neither evidences anything.
* ``--forbid-skips`` (set by verify.sh) fails the session when any collected test or collector
  was skipped, xfailed or xpassed (skip marks, ``unittest.skip``, a module-level
  ``pytest.skip(allow_module_level=True)``, ``pytest.importorskip``) or when a selected test
  never ran (``pytest.exit``, ``--collect-only``): a test that did not run proves nothing, so
  verification never lets one through as green. Such a session selects by marker expression
  only: ``--deselect`` and ``-k`` are usage errors there, wherever the option came from.
* The recorder cannot be switched off: blocking it (``-p no:ave-evidence-recorder``) is a usage
  error.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest

ROOT = Path(__file__).resolve().parents[2]
GIT_ROOT = ROOT
"""The work tree whose files Git must know (the plugin's own tests point it at a scratch tree)."""
SCHEMA = 1
RECORDER = "ave-evidence-recorder"
_NOT_RUN = ("skipped", "xfailed", "xpassed")
_REDIRECTING = ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR", "GIT_NAMESPACE")


def _evidence_module() -> ModuleType:
    """scripts/evidence.py, the single parser of requirement files and tags, run from its source
    text so no bytecode cache decides what it does."""
    path = ROOT / "scripts" / "evidence.py"
    module = ModuleType("ave_repository_evidence")
    module.__file__ = str(path)
    sys.modules[module.__name__] = module  # dataclasses resolve annotations through sys.modules
    exec(compile(path.read_bytes(), str(path), "exec"), module.__dict__)  # noqa: S102
    return module


def _ignored_by_git(paths: set[Path]) -> list[str]:
    """The files of ``paths`` inside the work tree that a Git ignore rule hides."""
    inside = sorted(
        path.relative_to(GIT_ROOT).as_posix() for path in paths if path.is_relative_to(GIT_ROOT)
    )
    if not inside:
        return []
    environment = {k: v for k, v in os.environ.items() if k not in _REDIRECTING}
    try:
        completed = subprocess.run(
            ["git", "-C", str(GIT_ROOT), "check-ignore", "--stdin"],  # noqa: S607
            input="\n".join(inside) + "\n",
            capture_output=True,
            text=True,
            check=False,
            env=environment,
        )
    except OSError:
        return []
    # 0: at least one path is ignored; 1: none; anything else: no work tree to ask.
    return sorted(completed.stdout.split()) if completed.returncode == 0 else []


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
    if config.getoption("--forbid-skips"):
        narrowed = [
            option
            for option, value in (
                ("--deselect", config.getoption("deselect", None)),
                ("-k", config.getoption("keyword", "")),
            )
            if value
        ]
        if narrowed:
            raise pytest.UsageError(
                f"{' and '.join(narrowed)} with --forbid-skips: a verification session selects its"
                " tests by marker expression only"
            )
    if config.pluginmanager.is_blocked(RECORDER):
        raise pytest.UsageError(
            f"the evidence recorder is blocked (-p no:{RECORDER}); every session records its tests"
        )
    config.pluginmanager.register(EvidenceRecorder(config), RECORDER)


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
        self.deselected: dict[str, dict[str, Any]] = {}

    @pytest.hookimpl(tryfirst=True)
    def pytest_collection_modifyitems(self, items: list[pytest.Item]) -> None:
        """Runs before the marker selection, so every collected test is validated and recorded."""
        files = {item.path for item in items}
        files |= {
            Path(module_file)
            for plugin in self.config.pluginmanager.get_plugins()
            if (module_file := getattr(plugin, "__file__", None))
            and Path(module_file).name == "conftest.py"
        }
        hidden = _ignored_by_git(files)
        if hidden:
            raise pytest.UsageError(
                "test files that Git ignores (evidence comes only from files of the tree the"
                " fingerprint names):\n  " + "\n  ".join(hidden)
            )
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

    def pytest_deselected(self, items: list[pytest.Item]) -> None:
        """A deselected test exists and does not run: it is recorded, and evidences nothing."""
        for item in items:
            record = self.results.pop(item.nodeid, None)
            if record is not None:
                record["outcome"] = "deselected"
                self.deselected[item.nodeid] = record

    def pytest_collectreport(self, report: pytest.CollectReport) -> None:
        """A collector skipped at collection yields no test items; it is recorded as one
        skipped entry, so --forbid-skips sees it."""
        if report.skipped:
            self.results[report.nodeid] = {
                "nodeid": report.nodeid,
                "req": [],
                "scenario": [],
                "contract": False,
                "markers": [],
                "outcome": "skipped",
                "duration": 0.0,
            }

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
        selected = list(self.results.values())
        not_run = [record["nodeid"] for record in selected if record["outcome"] in _NOT_RUN]
        never = [record["nodeid"] for record in selected if record["outcome"] == "not-run"]
        if self.config.getoption("--forbid-skips") and (not_run or never):
            reporter = self.config.pluginmanager.get_plugin("terminalreporter")
            if reporter is not None:
                for label, nodeids in (
                    ("did not run as passing tests", not_run),
                    ("were selected and never ran", never),
                ):
                    if nodeids:
                        reporter.write_line(
                            f"--forbid-skips: {len(nodeids)} test(s) {label}:", red=True
                        )
                        for nodeid in nodeids[:20]:
                            reporter.write_line(f"  {nodeid}")
            exitstatus = int(pytest.ExitCode.TESTS_FAILED)
            session.exitstatus = pytest.ExitCode.TESTS_FAILED
        path = self.config.getoption("--evidence-report")
        if path:
            report = {
                "schema": SCHEMA,
                "exitstatus": int(exitstatus),
                "invocation": {
                    "args": [str(arg) for arg in self.config.invocation_params.args],
                    "inifile": str(self.config.inipath or ""),
                },
                "tests": selected + list(self.deselected.values()),
            }
            target = Path(path)
            target.parent.mkdir(parents=True, exist_ok=True)
            text = json.dumps(report, indent=2, sort_keys=True) + "\n"
            target.write_text(text, encoding="utf-8")
