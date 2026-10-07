#!/usr/bin/env python3
"""scripts/evidence.py — requirement-level verification evidence (AVE-REQ-097).

Every ./scripts/verify.sh run records its evidence in ``var/verify/runs/<run-id>/`` (gitignored):
``steps.tsv`` (one line per verification step), one JSON report per pytest run (written by
``backend/tests/evidence_plugin.py``), one ``suite-<file>.json`` result per tooling test file that
ran (written by scripts/tests/run.sh and by the ``unittest`` command) and ``manifest.json``, which
ties the results to the commit, the tree fingerprint (``vstate_fingerprint`` in
scripts/lib/verify-state.sh), the toolchain and configuration hashes, and maps every requirement
criterion tag ``AVE-REQ-NNN AC-n`` and scenario tag ``AT-NN`` to the tests that carry it and their
outcomes. ``var/verify/latest-<tier>.json`` is a copy of the newest manifest of each tier.

Commands:
  record --dir DIR --tier TIER --fingerprint FP
      Write DIR/manifest.json from DIR's step log, reports and suite results; refresh
      latest-<tier>.json (var/verify/ is created when absent; exit 2 when it cannot be).
  show [AVE-REQ-NNN ...] [--tier TIER] [--require-fresh] [--require-complete]
      Per-criterion evidence from the heaviest manifest that is fresh (same tree fingerprint and
      toolchain as now), or from the newest one when none is. --tier selects the run that is
      shown. --require-fresh exits 1 when the tree or the toolchain changed since that run;
      --require-complete exits 1 when the run, or a fresh run of any tier (with or without
      --tier), failed, or a named requirement has a criterion without passing, non-contract
      evidence or with a tagged test that did not run.
  check-done --dir DIR [--tier TIER]
      Exit 1 when a requirement with status `done` has a criterion that this run's results do
      not evidence. Every tier fails on failed, contract-only and missing evidence; the release
      tier (the default) also fails on a tagged test that did not run. verify.sh runs it in
      every tier.
  unittest [--dir DIR] [DIRECTORY]
      Run the Python unit tests of DIRECTORY (default scripts/tests), each test_*.py file as one
      suite, and exit 1 when any file fails. A file fails when a test fails or errors, is skipped,
      is expected to fail or passes unexpectedly, or when no test ran (the --forbid-skips rule of
      the pytest plugin). With DIR (default $AVE_EVIDENCE_DIR), write each file's suite result.
  record-suite --dir DIR --file FILE --exit STATUS --checks N [--failed M]
      Write DIR/suite-<file name>.json: the file, its exit status, the numbers of checks it ran
      and of checks that failed, and the criterion tags of its comment lines with their line
      numbers (used by scripts/tests/run.sh for each shell suite). A suite passes only with exit
      status 0, N >= 1 and M = 0.
  check-report --file FILE
      Exit 1 when a pytest evidence report is missing, records a session that did not end with
      status 0, holds no executed test, or holds a selected test that never ran (used by the
      backend test steps: a session that passed without running its tests proves nothing).

Evidence rules (docs/requirements/README.md, Definition of Done):
  * a criterion is evidenced by a test that carries its tag and passed in the run, or by an
    inspection line ``- AC-n → inspection: …`` in the requirement's ## Test evidence;
  * a failed, skipped or erroring tagged test counts against the criterion;
  * tests marked ``contract`` replace an external provider with a fake: they prove the
    interface only and never evidence a criterion on their own;
  * the tooling tests in scripts/tests/ (the shell suites that scripts/tests/run.sh lists, one
    ``run_suite <file>`` line each, and the Python unit tests ``test_*.py``) tag their cases with
    ``# AVE-REQ-NNN AC-n`` comment lines; those tags count only through a suite result of the run,
    with the exit status and the check counts of that file: a file that never ran gives no
    evidence, and a failing one, or a shell suite that exited 0 without running a check or with a
    failed check in its total, counts against its criteria; in a unit-test file each tag stands
    directly above the test it names and binds to that test by class and name
    (``Class.test_x``), and a tag above no test that ran fails the file;
  * every tooling tag names an existing criterion: one that does not stops ``record`` and
    ``check-done`` with the file and line;
  * every comment tag in scripts/tests/ stands in a tooling test file: a tag in any other file
    there (the suite runner, a fixture builder, a suite run.sh does not list; bytecode
    directories excepted) has no runner and no suite result, so it stops ``record`` and
    ``check-done`` with the file and line;
  * a test that exists and did not run (a deselected pytest test, a tooling file without a suite
    result of the run) is recorded as ``not-run``: it evidences nothing, and a run that left a
    tagged test out certifies no requirement complete;
  * an inspection line counts for a criterion whose ## Verification strategy line names
    inspection (``- AC-n — inspection — <why>``); where that line names a test level beside
    inspection (``- AC-n — integration and inspection — …``) the inspection line counts only
    beside a tagged test that passed in the run, so it never stands in for the test the
    strategy names;
  * a run is recorded once, and a suite result counts when it belongs to a tooling test file of
    this tree and carries that file's tags. ``var/verify/`` is local, unauthenticated data: the
    run that certifies a requirement is the one the reviewer or CI starts.

Python standard library only; writes only into the run directory it is given and var/verify/.
"""

import os
import sys

if __name__ == "__main__" and not sys.flags.safe_path:
    # AVE-REQ-097 AC-4: the script's directory stays out of the module path, so no file beside this
    # script (a module, a bytecode file that Git ignores) stands in for a standard-library module.
    # These are the first statements the script executes: an import above them, `__future__`
    # included, would be looked up beside the script.
    os.execv(sys.executable, [sys.executable, "-P", "-B", os.path.abspath(__file__), *sys.argv[1:]])

import argparse
import ast
import functools
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import types
import unittest
import warnings
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
REQUIREMENTS = ROOT / "docs" / "requirements"
SCENARIOS_FILE = ROOT / "ai-video-editor-requirements" / "spec" / "ACCEPTANCE_TESTS.md"
VERIFY_DIR = ROOT / "var" / "verify"
TOOLING_TESTS = ROOT / "scripts" / "tests"
RUNNER = "run.sh"
"""The suite runner in scripts/tests/: each ``run_suite <file>`` line names a shell suite it runs."""
_LISTED_SUITE = re.compile(r"^run_suite (\S+)", re.MULTILINE)
UNIT_PATTERN = "test_*.py"
"""The Python unit tests in scripts/tests/, run by the ``unittest`` command."""
TIERS = ("fast", "media", "release")
SCHEMA = 1
KEEP_RUNS = 20

CRITERION_TAG = re.compile(r"^(AVE-REQ-\d{3,}) AC-(\d+)$")
SCENARIO_TAG = re.compile(r"^AT-\d{2}$")
_TAG_IN_TEXT = re.compile(r"\bAVE-REQ-\d{3,} AC-\d+\b")
_STRATEGY_LINE = re.compile(r"^- (AC-\d+) — ([^—]*) — ")
NOT_RUN = "not-run"
"""Outcome of a test that exists and was not executed in the run."""
_UNRUN_OUTCOMES = (NOT_RUN, "deselected")
"""Report outcomes of a test that did not run: selected and never started, or deselected."""
_TEST_NAME = re.compile(r"test_\w+")
_REDIRECTING = (
    "GIT_DIR",
    "GIT_WORK_TREE",
    "GIT_INDEX_FILE",
    "GIT_OBJECT_DIRECTORY",
    "GIT_ALTERNATE_OBJECT_DIRECTORIES",
    "GIT_COMMON_DIR",
    "GIT_NAMESPACE",
)
"""Variables that point Git at another repository, index or object store."""
_INSPECTION_LINE = re.compile(r"^- (AC-\d+) → inspection:")
_CONFIGURATION = ("scripts/verify.sh", "backend/pyproject.toml", "backend/uv.lock")


class EvidenceError(Exception):
    """Invalid input: an unknown tag, a missing run directory, a malformed report."""


# --------------------------------------------------------------------------------------------
# Requirement files


def _load_reader() -> types.ModuleType:
    """scripts/reqfile.py, the one reader of requirement files, shared with check_baseline.py.

    It runs from its source text, so no bytecode cache decides what a requirement file says.
    """
    path = Path(__file__).resolve().parent / "reqfile.py"
    module = types.ModuleType("ave_reqfile")
    module.__file__ = str(path)
    exec(compile(path.read_bytes(), str(path), "exec"), module.__dict__)
    return module


reqfile = _load_reader()


@dataclass(frozen=True)
class Requirement:
    """The parts of a working requirement file that evidence depends on."""

    id: str
    path: Path
    status: str
    criteria: tuple[str, ...]
    inspected: frozenset[str]
    problems: tuple[str, ...] = ()
    """Why the file is outside the canonical form (empty for a file check_baseline.py accepts)."""
    beside_test: frozenset[str] = frozenset()
    """Criteria whose strategy line names a test level beside inspection: their inspection line
    counts only beside a tagged test that passed."""


def read_requirement(path: Path) -> Requirement:
    """Parses a working requirement file (docs/requirements/AVE-REQ-NNN-<slug>.md) with the reader
    check_baseline.py uses: the status and the criteria of the done gate are the ones the baseline
    gate checked (AVE-REQ-097 AC-4)."""
    item = reqfile.read(path)
    # An inspection line counts for a criterion whose strategy line names inspection. The level
    # field of that line is the one word "inspection", or it names a test level too ("integration
    # and inspection"): every other level field of the criterion, on the same line or on a line of
    # its own, makes it a criterion with a test level.
    levels: dict[str, list[str]] = {}
    for line in item.sections.get("Verification strategy", []):
        if match := _STRATEGY_LINE.match(line):
            levels.setdefault(match.group(1), []).append(match.group(2).strip())
    by_inspection = {
        name for name, fields in levels.items() if any("inspection" in level for level in fields)
    }
    inspected = frozenset(
        match.group(1)
        for line in item.sections.get("Test evidence", [])
        if (match := _INSPECTION_LINE.match(line)) and match.group(1) in by_inspection
    )
    beside_test = frozenset(
        name for name in by_inspection if any(level != "inspection" for level in levels[name])
    )
    return Requirement(
        item.id,
        path,
        item.get("status"),
        tuple(item.criteria()),
        inspected,
        tuple(item.problems),
        beside_test,
    )


def requirements() -> dict[str, Requirement]:
    """Every working requirement, by ID (check-project-control.sh reports malformed file names)."""
    found: dict[str, Requirement] = {}
    for path in sorted(REQUIREMENTS.glob("AVE-REQ-[0-9]*.md")):
        if not reqfile.NAME.match(path.name):
            continue
        requirement = read_requirement(path)
        if requirement.id in found:
            raise EvidenceError(
                f"{requirement.id} has two working files: {found[requirement.id].path.name}"
                f" and {path.name}"
            )
        found[requirement.id] = requirement
    return found


def form_problems(known: dict[str, Requirement]) -> list[str]:
    """One line per requirement file outside the canonical form: such a file has no single
    reading, so no gate takes its status or criteria on trust."""
    return [
        f"{requirement.id}: {requirement.path.name} is outside the canonical form"
        f" ({requirement.problems[0]}); python3 -I -B scripts/check_baseline.py lists every problem"
        for requirement in known.values()
        if requirement.problems
    ]


def scenario_ids() -> frozenset[str]:
    """Scenario IDs defined by the baseline acceptance tests."""
    text = SCENARIOS_FILE.read_text(encoding="utf-8")
    return frozenset(re.findall(r"^## (AT-\d{2})\b", text, flags=re.MULTILINE))


def tag_problems(
    criteria: list[str], scenarios: list[str], known: dict[str, Requirement] | None = None
) -> list[str]:
    """Why each malformed or unknown tag is invalid (empty when every tag names a real
    criterion or scenario)."""
    known = requirements() if known is None else known
    problems = []
    for tag in criteria:
        match = CRITERION_TAG.match(tag)
        if not match:
            problems.append(f"{tag!r} is not of the form 'AVE-REQ-NNN AC-n'")
            continue
        requirement = known.get(match.group(1))
        if requirement is None:
            problems.append(f"{tag!r} names no requirement file")
        elif f"AC-{match.group(2)}" not in requirement.criteria:
            problems.append(f"{tag!r}: {requirement.path.name} has no such criterion")
    valid_scenarios = scenario_ids() if scenarios else frozenset()
    for tag in scenarios:
        if not SCENARIO_TAG.match(tag) or tag not in valid_scenarios:
            problems.append(f"{tag!r} is not a scenario of ACCEPTANCE_TESTS.md")
    return problems


# --------------------------------------------------------------------------------------------
# Collecting a run's results


@dataclass
class Evidence:
    """Tagged results of one run."""

    criteria: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    scenarios: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    tests: dict[str, int] = field(default_factory=dict)
    suites: list[dict[str, Any]] = field(default_factory=list)
    invocations: dict[str, Any] = field(default_factory=dict)


def read_steps(run_dir: Path) -> list[dict[str, Any]]:
    """The step log written by verify.sh: ``name<TAB>PASS|FAIL<TAB>seconds`` per line."""
    path = run_dir / "steps.tsv"
    if not path.is_file():
        return []
    steps = []
    for line in path.read_text(encoding="utf-8").splitlines():
        name, status, seconds = line.split("\t")
        steps.append({"name": name, "status": status, "seconds": int(seconds)})
    return steps


def _shown(path: Path) -> str:
    """``path`` relative to the repository root, or absolute when it lies outside."""
    resolved = path.resolve()
    return str(resolved.relative_to(ROOT)) if resolved.is_relative_to(ROOT) else str(resolved)


def comment_tags(path: Path) -> list[tuple[int, str]]:
    """Criterion tags in the comment lines of a tooling test file: (line number, tag)."""
    found = []
    text = path.read_text(encoding="utf-8", errors="replace")
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("#"):
            found.extend((number, tag) for tag in _TAG_IN_TEXT.findall(stripped))
    return found


def write_suite_result(
    run_dir: Path, suite: Path, exitstatus: int, checks: int = 0, failed: int = 0
) -> Path:
    """Records that ``suite`` ran in this run with ``exitstatus``, ``checks`` executed checks and
    ``failed`` failed ones: ``run_dir/suite-<name>.json`` holds the file, the exit status, both
    counts and the tags of its comment lines. A suite with exit status 0 and no check, or with a
    failed check, counts as failed when collected."""
    if not run_dir.is_dir():
        raise EvidenceError(f"run directory {run_dir} does not exist")
    if not suite.is_file():
        raise EvidenceError(f"suite {suite} does not exist")
    result = {
        "schema": SCHEMA,
        "file": _shown(suite),
        "exitstatus": int(exitstatus),
        "checks": int(checks),
        "failed": int(failed),
        "tags": [{"line": line, "tag": tag} for line, tag in comment_tags(suite)],
    }
    target = run_dir / f"suite-{suite.name}.json"
    _write_json(target, result)
    return target


def listed_suites() -> list[Path]:
    """The shell suites that scripts/tests/run.sh runs: one ``run_suite <file>`` line each, at the
    start of the line. Without the runner no shell suite is listed."""
    runner = TOOLING_TESTS / RUNNER
    if not runner.is_file():
        return []
    names = _LISTED_SUITE.findall(runner.read_text(encoding="utf-8", errors="replace"))
    return sorted({TOOLING_TESTS / name for name in names})


def tooling_files() -> list[Path]:
    """The tooling test files of this tree, the files a runner writes a suite result for: the
    shell suites run.sh lists and the Python unit tests."""
    units = {path for path in TOOLING_TESTS.glob(UNIT_PATTERN) if path.is_file()}
    return sorted(units | {path for path in listed_suites() if path.is_file()})


def unowned_tag_problems() -> list[str]:
    """``file:line: problem`` for each comment tag in a file of scripts/tests/ that is no tooling
    test file (AVE-REQ-097 AC-4). No runner writes a suite result for such a file, so its tag
    would read ``not-run`` in every tier and no run could evidence its criterion completely.
    Bytecode directories hold no comment line and are left out."""
    owned = {path.resolve() for path in tooling_files()}
    problems = []
    for directory, subdirectories, names in os.walk(TOOLING_TESTS):
        subdirectories[:] = sorted(name for name in subdirectories if name != "__pycache__")
        for name in sorted(names):
            path = Path(directory) / name
            if not path.is_file() or path.resolve() in owned:
                continue
            problems += [
                f"{_shown(path)}:{line}: the tag {tag} stands in a file that is neither a suite"
                f" {RUNNER} lists nor a {UNIT_PATTERN} file"
                for line, tag in comment_tags(path)
            ]
    return problems


def read_suite_results(run_dir: Path) -> list[dict[str, Any]]:
    """The suite results of one run directory, each with the name of its result file.

    A result counts only when it belongs to a tooling test file of this tree: it names the file,
    its own name derives from the file's and its tags are the file's comment tags. Anything else
    in the run directory was written by no runner.
    """
    files = {_shown(path): path for path in tooling_files()}
    results = []
    for path in sorted(run_dir.glob("suite-*.json")):
        result = json.loads(path.read_text(encoding="utf-8"))
        if result.get("schema") != SCHEMA:
            raise EvidenceError(f"{path}: unsupported suite result schema")
        suite = files.get(str(result.get("file")))
        if suite is None or path.name != f"suite-{suite.name}.json":
            raise EvidenceError(
                f"{path}: names no tooling test file of this tree ({result.get('file')!r}); a suite"
                " result is written by scripts/tests/run.sh or `evidence.py unittest` only"
            )
        tags = [{"line": line, "tag": tag} for line, tag in comment_tags(suite)]
        if result.get("tags") != tags:
            raise EvidenceError(f"{path}: its tags differ from the comment tags of {result['file']}")
        results.append({**result, "report": path.name})
    return results


def tooling_tag_problems(
    results: list[dict[str, Any]], known: dict[str, Requirement]
) -> list[str]:
    """``file:line: problem`` for each tooling tag that names no existing criterion, in the
    suite results of a run and in every tooling test file of :data:`TOOLING_TESTS`."""
    located = {
        (result["file"], entry["line"], entry["tag"])
        for result in results
        for entry in result["tags"]
    }
    for path in tooling_files():
        located.update((_shown(path), line, tag) for line, tag in comment_tags(path))
    return [
        f"{file}:{line}: {problem}"
        for file, line, tag in sorted(located)
        for problem in tag_problems([tag], [], known)
    ]


def collect(run_dir: Path, known: dict[str, Requirement] | None = None) -> Evidence:
    """Tagged results of the pytest reports and tooling suite results of one run directory."""
    evidence = Evidence()
    for report_path in sorted(run_dir.glob("pytest-*.json")):
        report = json.loads(report_path.read_text(encoding="utf-8"))
        if report.get("schema") != SCHEMA:
            raise EvidenceError(f"{report_path}: unsupported report schema")
        if "invocation" in report:
            evidence.invocations[report_path.name] = report["invocation"]
        for test in report["tests"]:
            evidence.tests[test["outcome"]] = evidence.tests.get(test["outcome"], 0) + 1
            outcome = NOT_RUN if test["outcome"] in _UNRUN_OUTCOMES else test["outcome"]
            item = {
                "test": test["nodeid"],
                "outcome": outcome,
                "contract": bool(test.get("contract")),
                "report": report_path.name,
            }
            for tag in test.get("req", []):
                evidence.criteria.setdefault(tag, []).append(item)
            for tag in test.get("scenario", []):
                evidence.scenarios.setdefault(tag, []).append(item)
    results = read_suite_results(run_dir)
    unowned = unowned_tag_problems()
    if unowned:
        raise EvidenceError(
            "criterion tags in scripts/tests/ outside the tooling test files (a tag counts through"
            " the suite result of a file that a runner runs):\n  " + "\n  ".join(unowned)
        )
    problems = tooling_tag_problems(results, requirements() if known is None else known)
    if problems:
        raise EvidenceError(
            "tooling test tags that name no existing criterion:\n  " + "\n  ".join(problems)
        )
    for result in results:
        checks, failed = int(result.get("checks", 0)), int(result.get("failed", 0))
        # AVE-REQ-097 AC-4: a suite that exited 0 but ran no check is a placeholder, and one whose
        # own total reports a failed check caught a failure and returned success: both fail.
        passed = result["exitstatus"] == 0 and checks >= 1 and failed == 0
        outcome = "passed" if passed else "failed"
        evidence.suites.append(
            {
                "file": result["file"],
                "exitstatus": result["exitstatus"],
                "checks": checks,
                "failed": failed,
            }
        )
        for tag in sorted({entry["tag"] for entry in result["tags"]}):
            item = {
                "test": result["file"],
                "outcome": outcome,
                "contract": False,
                "report": result["report"],
            }
            evidence.criteria.setdefault(tag, []).append(item)
    # A tooling test file without a suite result of this run exists and did not run.
    reported = {result["file"] for result in results}
    for path in tooling_files():
        if _shown(path) in reported:
            continue
        for tag in sorted({tag for _line, tag in comment_tags(path)}):
            item = {"test": _shown(path), "outcome": NOT_RUN, "contract": False, "report": ""}
            evidence.criteria.setdefault(tag, []).append(item)
    # A pytest test deselected in one report and executed in another of the same run did run.
    for tagged in (evidence.criteria, evidence.scenarios):
        for tag, items in tagged.items():
            ran = {item["test"] for item in items if item["outcome"] != NOT_RUN}
            tagged[tag] = [
                item for item in items if item["outcome"] != NOT_RUN or item["test"] not in ran
            ]
    return evidence


def unrun(items: list[dict[str, Any]]) -> int:
    """How many of a criterion's tagged tests exist and did not run."""
    return sum(1 for item in items if item["outcome"] == NOT_RUN)


def _unit_problems(result: unittest.TestResult) -> list[str]:
    """Why a unit-test file proves nothing: each test that did not pass, or no test at all."""
    problems = [
        f"{label}: {test.id()}"
        for label, entries in (
            ("failed", result.failures),
            ("error", result.errors),
            ("skipped", result.skipped),
            ("expected to fail", result.expectedFailures),
        )
        for test, _ in entries
    ]
    problems += [f"passed unexpectedly: {test.id()}" for test in result.unexpectedSuccesses]
    if result.testsRun == 0:
        problems.append("no test ran")
    return problems


def qualified_tests(source: str) -> dict[int, str]:
    """The line of each ``def test_…`` of a Python source → its class-qualified name, as
    ``__qualname__`` spells it (``Class.test_x``; the bare name at module level). Empty for a
    source Python cannot parse: such a file runs no test either."""
    try:
        tree = ast.parse(source)
    except (SyntaxError, ValueError):
        return {}
    found: dict[int, str] = {}

    def visit(node: ast.AST, prefix: str) -> None:
        for child in ast.iter_child_nodes(node):
            if isinstance(child, ast.ClassDef):
                visit(child, f"{prefix}{child.name}.")
            elif isinstance(child, ast.FunctionDef | ast.AsyncFunctionDef):
                if _TEST_NAME.fullmatch(child.name):
                    found[child.lineno] = prefix + child.name
                visit(child, f"{prefix}{child.name}.<locals>.")
            else:
                visit(child, prefix)

    visit(tree, "")
    return found


def tagged_tests(path: Path) -> list[tuple[int, str, str]]:
    """(line, tag, test) for each comment tag of a unit-test file; the test is the class-qualified
    name of the ``def test_…`` on the next code line (decorator lines skipped), or "" when no
    test follows the tag."""
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    definitions = qualified_tests(text)
    found = []
    for number, tag in comment_tags(path):
        name = ""
        for following, line in enumerate(lines[number:], start=number + 1):
            stripped = line.strip()
            if not stripped or stripped.startswith(("#", "@")):
                continue
            name = definitions.get(following, "")
            break
        found.append((number, tag, name))
    return found


def started_test(test: unittest.TestCase) -> str:
    """The class-qualified name of the test function a started test runs: the class that defines
    the method (the test's own class, or the base it inherits the method from) and the name."""
    method = str(getattr(test, "_testMethodName", ""))
    owner = next((cls for cls in type(test).__mro__ if method in vars(cls)), type(test))
    return f"{owner.__qualname__}.{method}"


class _RecordingResult(unittest.TextTestResult):
    """Remembers the class-qualified name of every test that started."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.started: set[str] = set()

    def startTest(self, test: unittest.TestCase) -> None:  # noqa: N802 - unittest's name
        self.started.add(started_test(test))
        super().startTest(test)


def run_unit_file(path: Path, result_path: Path) -> int:
    """Runs one ``test_*.py`` file in this interpreter and writes ``{"tests": n, "problems":
    [...]}`` to ``result_path`` (the ``unittest-file`` command, started once per file).

    Warnings are errors, so a test that returns a value (a generator or a coroutine whose body
    never ran) fails; each comment tag must stand above a test that ran, compared by class and
    name: a test of the same name in another class leaves the tag unbound."""
    warnings.simplefilter("error")
    loader = unittest.TestLoader()
    suite = loader.discover(str(path.parent), pattern=path.name, top_level_dir=str(path.parent))
    runner = unittest.TextTestRunner(
        stream=sys.stdout, verbosity=1, resultclass=_RecordingResult, warnings="error"
    )
    result = runner.run(suite)
    problems = _unit_problems(result)
    for line, tag, name in tagged_tests(path):
        if not name:
            problems.append(f"line {line}: the tag {tag} stands above no test")
        elif name not in result.started:
            problems.append(f"line {line}: {tag} stands above {name}, which did not run")
    _write_json(result_path, {"tests": result.testsRun, "problems": problems})
    return 1 if problems else 0


def _run_unit_child(path: Path) -> tuple[int, list[str]]:
    """Runs one unit-test file in a child interpreter; returns (tests run, problems).

    A file that ends the interpreter, or replaces the runner's judgement in its own process,
    reaches no other file and no result of this process: without a result the file fails."""
    with tempfile.TemporaryDirectory(prefix="evidence-unit.") as scratch:
        result_path = Path(scratch) / "result.json"
        command = [sys.executable, "-B", str(Path(__file__).resolve()), "unittest-file"]
        completed = subprocess.run(  # noqa: S603 - the interpreter running this file
            [*command, str(path), "--result", str(result_path)], check=False
        )
        try:
            data = json.loads(result_path.read_text(encoding="utf-8"))
            tests, problems = int(data["tests"]), [str(problem) for problem in data["problems"]]
        except (OSError, ValueError, KeyError, TypeError):
            return 0, [f"the test process ended without a result (exit {completed.returncode})"]
    if completed.returncode != 0 and not problems:
        problems.append(f"the test process exited {completed.returncode}")
    return tests, problems


def run_unit_tests(directory: Path, run_dir: Path | None) -> int:
    """Runs each ``test_*.py`` file of ``directory`` as one suite, each in its own interpreter;
    writes its suite result into ``run_dir`` when given. Exit status 1 when any file fails or
    none exists."""
    files = sorted(directory.glob(UNIT_PATTERN))
    if not files:
        print(f"FAIL: no {UNIT_PATTERN} file in {directory}")
        return 1
    failed = []
    for path in files:
        print(f"--- {_shown(path)}", flush=True)
        tests_run, problems = _run_unit_child(path)
        if problems:
            failed.append(path)
            print(f"FAIL: {_shown(path)} — a test that did not pass proves nothing:")
            for problem in problems:
                print(f"  {problem}")
        if run_dir is not None:
            write_suite_result(run_dir, path, 1 if problems else 0, tests_run, len(problems))
    if failed:
        print(f"evidence.py unittest: FAIL ({len(failed)} of {len(files)} file(s))")
        return 1
    print(f"evidence.py unittest: PASS ({len(files)} file(s))")
    return 0


def criterion_state(
    items: list[dict[str, Any]], inspected: bool, beside_test: bool = False
) -> str:
    """``passed``, ``inspected``, ``contract-only``, ``failed``, ``not-run`` (every tagged test
    exists and none ran) or ``missing`` (no test carries the tag). ``inspected``: an inspection
    line counts for the criterion; with ``beside_test`` (its strategy names a test level too) the
    line counts only beside a tagged test that passed in the run."""
    ran = [item for item in items if item["outcome"] != NOT_RUN]
    if any(item["outcome"] != "passed" for item in ran):
        return "failed"
    if any(not item["contract"] for item in ran):
        return "passed"
    if inspected and (ran or not beside_test):
        return "inspected"
    if ran:
        return "contract-only"
    return NOT_RUN if items else "missing"


# --------------------------------------------------------------------------------------------
# Manifest


def _run(argv: list[str], whole: bool = False) -> str:
    """The first line (the whole text with ``whole``) a command prints, or "unavailable". No Git
    variable of the caller points the command at another repository."""
    environment = {k: v for k, v in os.environ.items() if k not in _REDIRECTING}
    try:
        completed = subprocess.run(
            argv, capture_output=True, text=True, check=False, cwd=ROOT, env=environment
        )
    except OSError:
        return "unavailable"
    text = completed.stdout.strip()
    if completed.returncode != 0 or not text:
        return "unavailable"
    return text if whole else text.splitlines()[0]


def current_fingerprint() -> str:
    """The Stop-gate fingerprint of the working tree, or an empty string when unavailable."""
    script = ". ./scripts/lib/verify-state.sh && vstate_fingerprint"
    value = _run(["bash", "-c", script])
    return "" if value == "unavailable" else value


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else "missing"


def configuration() -> dict[str, str]:
    files = [ROOT / name for name in _CONFIGURATION] + sorted(
        (ROOT / "scripts/verify.d").glob("*.sh")
    )
    return {str(path.relative_to(ROOT)): _sha256(path) for path in files}


_ENVIRONMENT_LISTING = (
    "import importlib.metadata as m;"
    "print(chr(10).join(sorted(d.metadata['Name'] + '==' + d.version for d in m.distributions())))"
)


def toolchain() -> dict[str, str]:
    """The tools a run uses: the media tools are the binaries the product resolves (AVE_FFMPEG and
    AVE_FFPROBE, else PATH), and ``environment`` is a digest of the packages installed in the
    backend environment (a package outside uv.lock changes it)."""
    ffmpeg = os.environ.get("AVE_FFMPEG") or "ffmpeg"
    ffprobe = os.environ.get("AVE_FFPROBE") or "ffprobe"
    return {
        "python3": sys.version.split()[0],
        "uv": _run(["uv", "--version"]),
        "ffmpeg": _run([ffmpeg, "-hide_banner", "-version"]),
        "ffprobe": _run([ffprobe, "-hide_banner", "-version"]),
        "environment": _environment_digest(),
    }


@functools.cache
def _environment_digest() -> str:
    """A digest of the packages installed in the backend environment (read once per process)."""
    backend = ["uv", "run", "--frozen", "--no-env-file", "--quiet", "--directory", "backend"]
    backend += ["python", "-c"]
    packages = _run([*backend, _ENVIRONMENT_LISTING], whole=True)
    if packages == "unavailable":
        return packages
    return hashlib.sha256(packages.encode("utf-8")).hexdigest()[:16]


def _now() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def _write_json(path: Path, data: dict[str, Any]) -> None:
    staged = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    staged.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    staged.replace(path)


def record(run_dir: Path, tier: str, fingerprint: str) -> dict[str, Any]:
    """Writes ``run_dir/manifest.json`` and ``latest-<tier>.json``; prunes old runs. The evidence
    directory var/verify/ is created when it is absent (a run directory may lie elsewhere); when
    it cannot be created the run stays unrecorded."""
    if not run_dir.is_dir():
        raise EvidenceError(f"run directory {run_dir} does not exist")
    if (run_dir / "manifest.json").exists():
        raise EvidenceError(
            f"{run_dir} is recorded already: a run is recorded once, for the tree and the tier"
            " that produced its results"
        )
    try:
        VERIFY_DIR.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        raise EvidenceError(
            f"cannot create the evidence directory {VERIFY_DIR} ({error}); nothing was recorded"
        ) from error
    steps = read_steps(run_dir)
    evidence = collect(run_dir)
    status = _run(["git", "status", "--porcelain", "--untracked-files=all"])
    manifest = {
        "schema": SCHEMA,
        "run_id": run_dir.name,
        "tier": tier,
        "result": "PASS" if steps and all(s["status"] == "PASS" for s in steps) else "FAIL",
        "commit": _run(["git", "rev-parse", "HEAD"]),
        "uncommitted_changes": status not in ("", "unavailable"),
        "fingerprint": fingerprint,
        "recorded": _now(),
        "toolchain": toolchain(),
        "configuration": configuration(),
        "pytest": evidence.invocations,
        "steps": steps,
        "tests": evidence.tests,
        "suites": evidence.suites,
        "criteria": evidence.criteria,
        "scenarios": evidence.scenarios,
    }
    _write_json(run_dir / "manifest.json", manifest)
    _write_json(VERIFY_DIR / f"latest-{tier}.json", manifest)
    kept = VERIFY_DIR / "runs"
    runs = sorted(p for p in kept.iterdir() if p.is_dir()) if kept.is_dir() else []
    for old in runs[:-KEEP_RUNS]:
        shutil.rmtree(old, ignore_errors=True)
    return manifest


def manifests(tier: str | None) -> list[tuple[Path, dict[str, Any]]]:
    """The newest manifest of ``tier``, or of every tier when ``tier`` is None."""
    candidates = [VERIFY_DIR / f"latest-{name}.json" for name in ((tier,) if tier else TIERS)]
    found = [
        (path, json.loads(path.read_text(encoding="utf-8")))
        for path in candidates
        if path.is_file()
    ]
    if not found:
        wanted = f"tier {tier}" if tier else "any tier"
        raise EvidenceError(f"no recorded verification run for {wanted}; run ./scripts/verify.sh")
    return found


def staleness(manifest: dict[str, Any], fingerprint: str, tools: dict[str, str]) -> str:
    """Why a manifest certifies nothing about the current tree and toolchain ("" when fresh)."""
    if not manifest["fingerprint"] or manifest["fingerprint"] != fingerprint:
        return "the tree changed since this run"
    recorded = manifest.get("toolchain", {})
    changed = sorted(name for name in set(recorded) | set(tools) if recorded.get(name) != tools.get(name))
    if changed:
        return "the toolchain differs from this run's (" + ", ".join(changed) + ")"
    return ""


# --------------------------------------------------------------------------------------------
# Commands


def cmd_record(args: argparse.Namespace) -> int:
    manifest = record(Path(args.dir), args.tier, args.fingerprint)
    tagged = len(manifest["criteria"])
    print(f"Evidence: {manifest['result']} — {tagged} criteria tagged — {args.dir}/manifest.json")
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    fingerprint, tools = current_fingerprint(), toolchain()
    found = manifests(args.tier)
    fresh_ones = [pair for pair in found if not staleness(pair[1], fingerprint, tools)]
    # The heaviest fresh run decides: a fast run never hides a media or release run of this tree.
    if fresh_ones:
        path, manifest = max(fresh_ones, key=lambda pair: TIERS.index(pair[1]["tier"]))
    else:
        path, manifest = max(found, key=lambda pair: pair[1]["recorded"])
    stale = staleness(manifest, fingerprint, tools)
    dirty = " (with uncommitted changes)" if manifest["uncommitted_changes"] else ""
    shown = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
    print(
        f"Evidence: {shown} — tier {manifest['tier']}, {manifest['result']}, "
        f"commit {manifest['commit'][:12]}{dirty}, recorded {manifest['recorded']}"
    )
    print(
        f"Freshness: STALE — {stale}; it certifies nothing about the current tree (rerun"
        f" ./scripts/verify.sh --tier {manifest['tier']})"
        if stale
        else "Freshness: FRESH — the tree and the toolchain are unchanged since this run"
    )
    known = requirements()
    recorded_ids = sorted({tag.split(" ")[0] for tag in manifest["criteria"]})
    shown_ids = args.ids or recorded_ids
    # A manifest that names a requirement without a working file is refused in both forms.
    unknown = sorted({name for name in [*shown_ids, *recorded_ids] if name not in known})
    if unknown:
        raise EvidenceError(
            f"unknown requirement IDs: {', '.join(unknown)} (no file in docs/requirements/)"
        )
    incomplete = False
    for requirement_id in shown_ids:
        requirement = known[requirement_id]
        print(f"{requirement_id} ({requirement.status})")
        if requirement.problems:
            incomplete = True
            print(f"  form   NOT CANONICAL  {requirement.problems[0]}")
        for criterion in requirement.criteria:
            items = manifest["criteria"].get(f"{requirement_id} {criterion}", [])
            state = criterion_state(
                items, criterion in requirement.inspected, criterion in requirement.beside_test
            )
            left = unrun(items)
            incomplete |= state not in ("passed", "inspected") or left > 0
            note = f" — {left} tagged test(s) did not run" if left and state != NOT_RUN else ""
            print(f"  {criterion:<6} {state:<14} {_test_summary(items)}{note}")
    # A failed fresh run of any tier counts, also when --tier selects the run that is shown.
    every_tier = found if args.tier is None else manifests(None)
    failed_runs = sorted({manifest["tier"]} if manifest["result"] != "PASS" else set()) + sorted(
        m["tier"]
        for _path, m in every_tier
        if m["tier"] != manifest["tier"]
        and m["result"] != "PASS"
        and not staleness(m, fingerprint, tools)
    )
    if args.require_complete and failed_runs:
        print(
            f"Completeness: the run of tier {', '.join(failed_runs)} FAILED; a failed run"
            " certifies no requirement complete"
        )
    if args.require_fresh and stale:
        return 1
    return 1 if args.require_complete and (incomplete or failed_runs) else 0


def _test_summary(items: list[dict[str, Any]], shown: int = 4) -> str:
    """Distinct tests (parametrized cases folded into their function), the first few by name."""
    names = sorted({item["test"].split("[", 1)[0] for item in items})
    if not names:
        return ""
    more = f" (+{len(names) - shown} more)" if len(names) > shown else ""
    return f"{len(items)} result(s): " + ", ".join(names[:shown]) + more


def done_problems(
    run_dir: Path, known: dict[str, Requirement] | None = None, tier: str = "release"
) -> list[str]:
    """Criteria of `done` requirements that this run does not evidence, and requirement files
    outside the canonical form (their status and criteria have no single reading)."""
    known = requirements() if known is None else known
    evidence = collect(run_dir, known)
    problems = form_problems(known)
    for requirement in known.values():
        if requirement.status != "done":
            continue
        for criterion in requirement.criteria:
            items = evidence.criteria.get(f"{requirement.id} {criterion}", [])
            state = criterion_state(
                items, criterion in requirement.inspected, criterion in requirement.beside_test
            )
            left = unrun(items)
            if state in ("failed", "contract-only", "missing"):
                problems.append(f"{requirement.id} {criterion}: {state} in this run")
            elif tier == "release" and left:
                # The release tier runs every test: one that did not run leaves the criterion open.
                problems.append(
                    f"{requirement.id} {criterion}: {left} tagged test(s) did not run in this run"
                )
    return problems


def cmd_check_done(args: argparse.Namespace) -> int:
    problems = done_problems(Path(args.dir), tier=args.tier)
    for problem in problems:
        print(f"ERROR: {problem}")
    done = sum(1 for r in requirements().values() if r.status == "done")
    if problems:
        print(
            f"FAIL: {len(problems)} problem(s): criteria of done requirements without evidence in"
            " this run, or requirement files outside the canonical form"
        )
        return 1
    if args.tier == "release":
        print(
            f"OK: every criterion of the {done} done requirements has a passing test in this run"
            " or a recorded inspection that its Verification strategy names"
        )
    else:
        print(
            f"OK: no criterion of the {done} done requirements has failed, contract-only or missing"
            f" evidence in this run (tier {args.tier}; the release tier runs every tagged test)"
        )
    return 0


def report_problems(path: Path) -> list[str]:
    """Why a pytest evidence report proves nothing: no report, a session that did not end with
    status 0, no executed test, or a selected test that never ran."""
    if not path.is_file():
        return ["no report: the pytest session ended before it wrote one"]
    try:
        report = json.loads(path.read_text(encoding="utf-8"))
        tests = report["tests"]
        status = int(report["exitstatus"])
        outcomes = [str(test["outcome"]) for test in tests]
    except (ValueError, KeyError, TypeError):
        return ["the report is unreadable"]
    problems = []
    if report.get("schema") != SCHEMA:
        problems.append("unsupported report schema")
    if status != 0:
        problems.append(f"the session ended with status {status}")
    if not any(outcome not in _UNRUN_OUTCOMES for outcome in outcomes):
        problems.append("no test ran")
    never = [test["nodeid"] for test in tests if test["outcome"] == NOT_RUN]
    if never:
        problems.append(f"{len(never)} selected test(s) never ran, for example {never[0]}")
    return problems


def cmd_check_report(args: argparse.Namespace) -> int:
    problems = report_problems(Path(args.file))
    for problem in problems:
        print(f"ERROR: {args.file}: {problem}")
    if problems:
        print("FAIL: a pytest session that did not run its selected tests proves nothing")
        return 1
    return 0


def cmd_unittest(args: argparse.Namespace) -> int:
    run_dir = Path(args.dir) if args.dir else None
    if run_dir is not None and not run_dir.is_dir():
        raise EvidenceError(f"run directory {run_dir} does not exist")
    return run_unit_tests(Path(args.directory), run_dir)


def cmd_record_suite(args: argparse.Namespace) -> int:
    write_suite_result(Path(args.dir), Path(args.file), args.exit, args.checks, args.failed)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="scripts/evidence.py", description=__doc__.split("\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)
    rec = commands.add_parser("record", help="write a run's manifest")
    rec.add_argument("--dir", required=True)
    rec.add_argument("--tier", required=True, choices=TIERS)
    rec.add_argument("--fingerprint", default="")
    rec.set_defaults(handler=cmd_record)
    show = commands.add_parser("show", help="per-criterion evidence of the newest run")
    show.add_argument("ids", nargs="*", metavar="AVE-REQ-NNN")
    show.add_argument("--tier", choices=TIERS)
    show.add_argument("--require-fresh", action="store_true")
    show.add_argument("--require-complete", action="store_true")
    show.set_defaults(handler=cmd_show)
    check = commands.add_parser("check-done", help="done requirements are evidenced by a run")
    check.add_argument("--dir", required=True)
    check.add_argument("--tier", choices=TIERS, default="release")
    check.set_defaults(handler=cmd_check_done)
    unit = commands.add_parser("unittest", help="run the tooling unit tests; record each file")
    unit.add_argument("--dir", default=os.environ.get("AVE_EVIDENCE_DIR", ""))
    unit.add_argument("directory", nargs="?", default=str(TOOLING_TESTS))
    unit.set_defaults(handler=cmd_unittest)
    unit_file = commands.add_parser("unittest-file", help="run one unit-test file (internal)")
    unit_file.add_argument("file")
    unit_file.add_argument("--result", required=True)
    unit_file.set_defaults(handler=lambda a: run_unit_file(Path(a.file), Path(a.result)))
    suite = commands.add_parser("record-suite", help="record one tooling suite's result")
    suite.add_argument("--dir", required=True)
    suite.add_argument("--file", required=True)
    suite.add_argument("--exit", required=True, type=int)
    suite.add_argument("--checks", required=True, type=int, help="checks the suite ran (TOTAL pass=N)")
    suite.add_argument("--failed", type=int, default=0, help="checks that failed (TOTAL fail=M)")
    suite.set_defaults(handler=cmd_record_suite)
    report = commands.add_parser("check-report", help="a pytest report holds executed tests")
    report.add_argument("--file", required=True)
    report.set_defaults(handler=cmd_check_report)
    args = parser.parse_args(argv)
    try:
        return int(args.handler(args))
    except EvidenceError as error:
        print(f"evidence.py: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
