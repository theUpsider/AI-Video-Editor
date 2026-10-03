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
      latest-<tier>.json.
  show [AVE-REQ-NNN ...] [--tier TIER] [--require-fresh] [--require-complete]
      Per-criterion evidence from the newest manifest, with its freshness against the current
      tree. --require-fresh exits 1 when the tree changed since that run; --require-complete
      exits 1 when the run failed or a named requirement has a criterion without passing,
      non-contract evidence.
  check-done --dir DIR
      Exit 1 when a requirement with status `done` has a criterion that this run's results do
      not evidence (used by verify.sh in the release tier).
  unittest [--dir DIR] [DIRECTORY]
      Run the Python unit tests of DIRECTORY (default scripts/tests), each test_*.py file as one
      suite, and exit 1 when any file fails. A file fails when a test fails or errors, is skipped,
      is expected to fail or passes unexpectedly, or when no test ran (the --forbid-skips rule of
      the pytest plugin). With DIR (default $AVE_EVIDENCE_DIR), write each file's suite result.
  record-suite --dir DIR --file FILE --exit STATUS
      Write DIR/suite-<file name>.json: the file, its exit status and the criterion tags of its
      comment lines with their line numbers (used by scripts/tests/run.sh for each shell suite).

Evidence rules (docs/requirements/README.md, Definition of Done):
  * a criterion is evidenced by a test that carries its tag and passed in the run, or by an
    inspection line ``- AC-n → inspection: …`` in the requirement's ## Test evidence;
  * a failed, skipped or erroring tagged test counts against the criterion;
  * tests marked ``contract`` replace an external provider with a fake: they prove the
    interface only and never evidence a criterion on their own;
  * the tooling tests in scripts/tests/ (shell suites and Python unit tests) tag their cases with
    ``# AVE-REQ-NNN AC-n`` comment lines; those tags count only through a suite result of the run,
    with the exit status of that file: a file that never ran gives no evidence, and a failing one
    counts against its criteria;
  * every tooling tag names an existing criterion: one that does not stops ``record`` and
    ``check-done`` with the file and line.

Python standard library only; writes only into the run directory it is given and var/verify/.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import unittest
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
REQUIREMENTS = ROOT / "docs" / "requirements"
SCENARIOS_FILE = ROOT / "ai-video-editor-requirements" / "spec" / "ACCEPTANCE_TESTS.md"
VERIFY_DIR = ROOT / "var" / "verify"
TOOLING_TESTS = ROOT / "scripts" / "tests"
TOOLING_PATTERNS = ("*.sh", "test_*.py")
"""Tooling test files in scripts/tests/: shell suites and Python unit tests."""
UNIT_PATTERN = "test_*.py"
TIERS = ("fast", "media", "release")
SCHEMA = 1
KEEP_RUNS = 20

CRITERION_TAG = re.compile(r"^AVE-REQ-(\d{3}) AC-(\d+)$")
SCENARIO_TAG = re.compile(r"^AT-\d{2}$")
_TAG_IN_TEXT = re.compile(r"\bAVE-REQ-\d{3} AC-\d+\b")
_AC_LINE = re.compile(r"^- \[[ x]\] (AC-\d+)\b")
_INSPECTION_LINE = re.compile(r"^- (AC-\d+) → inspection:")
_CONFIGURATION = ("scripts/verify.sh", "backend/pyproject.toml", "backend/uv.lock")


class EvidenceError(Exception):
    """Invalid input: an unknown tag, a missing run directory, a malformed report."""


# --------------------------------------------------------------------------------------------
# Requirement files


@dataclass(frozen=True)
class Requirement:
    """The parts of a working requirement file that evidence depends on."""

    id: str
    path: Path
    status: str
    criteria: tuple[str, ...]
    inspected: frozenset[str]


def _section(lines: list[str], heading: str) -> list[str]:
    inside, body = False, []
    for line in lines:
        if line.startswith("## "):
            inside = line.strip() == heading
            continue
        if inside:
            body.append(line)
    return body


def read_requirement(path: Path) -> Requirement:
    """Parses a working requirement file (docs/requirements/AVE-REQ-NNN-<slug>.md)."""
    lines = path.read_text(encoding="utf-8").splitlines()
    status = next(
        (line.split(":", 1)[1].strip() for line in lines if line.startswith("status:")), ""
    )
    criteria = tuple(
        match.group(1)
        for line in _section(lines, "## Acceptance criteria")
        if (match := _AC_LINE.match(line))
    )
    inspected = frozenset(
        match.group(1)
        for line in _section(lines, "## Test evidence")
        if (match := _INSPECTION_LINE.match(line))
    )
    return Requirement(path.name[:11], path, status, criteria, inspected)


def requirements() -> dict[str, Requirement]:
    """Every working requirement, by ID."""
    found = (read_requirement(path) for path in sorted(REQUIREMENTS.glob("AVE-REQ-[0-9]*.md")))
    return {requirement.id: requirement for requirement in found}


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
        requirement = known.get(f"AVE-REQ-{match.group(1)}")
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
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("#"):
            found.extend((number, tag) for tag in _TAG_IN_TEXT.findall(stripped))
    return found


def write_suite_result(run_dir: Path, suite: Path, exitstatus: int) -> Path:
    """Records that ``suite`` ran in this run with ``exitstatus``: ``run_dir/suite-<name>.json``
    holds the file, the exit status and the tags of its comment lines."""
    if not run_dir.is_dir():
        raise EvidenceError(f"run directory {run_dir} does not exist")
    if not suite.is_file():
        raise EvidenceError(f"suite {suite} does not exist")
    result = {
        "schema": SCHEMA,
        "file": _shown(suite),
        "exitstatus": int(exitstatus),
        "tags": [{"line": line, "tag": tag} for line, tag in comment_tags(suite)],
    }
    target = run_dir / f"suite-{suite.name}.json"
    _write_json(target, result)
    return target


def read_suite_results(run_dir: Path) -> list[dict[str, Any]]:
    """The suite results of one run directory, each with the name of its result file."""
    results = []
    for path in sorted(run_dir.glob("suite-*.json")):
        result = json.loads(path.read_text(encoding="utf-8"))
        if result.get("schema") != SCHEMA:
            raise EvidenceError(f"{path}: unsupported suite result schema")
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
    for pattern in TOOLING_PATTERNS:
        for path in sorted(TOOLING_TESTS.glob(pattern)):
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
        for test in report["tests"]:
            outcome = test["outcome"]
            evidence.tests[outcome] = evidence.tests.get(outcome, 0) + 1
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
    problems = tooling_tag_problems(results, requirements() if known is None else known)
    if problems:
        raise EvidenceError(
            "tooling test tags that name no existing criterion:\n  " + "\n  ".join(problems)
        )
    for result in results:
        outcome = "passed" if result["exitstatus"] == 0 else "failed"
        evidence.suites.append({"file": result["file"], "exitstatus": result["exitstatus"]})
        for tag in sorted({entry["tag"] for entry in result["tags"]}):
            item = {
                "test": result["file"],
                "outcome": outcome,
                "contract": False,
                "report": result["report"],
            }
            evidence.criteria.setdefault(tag, []).append(item)
    return evidence


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


def run_unit_tests(directory: Path, run_dir: Path | None) -> int:
    """Runs each ``test_*.py`` file of ``directory`` as one suite; writes its suite result into
    ``run_dir`` when given. Exit status 1 when any file fails or none exists."""
    files = sorted(directory.glob(UNIT_PATTERN))
    if not files:
        print(f"FAIL: no {UNIT_PATTERN} file in {directory}")
        return 1
    failed = []
    for path in files:
        print(f"--- {_shown(path)}", flush=True)
        loader = unittest.TestLoader()
        suite = loader.discover(str(directory), pattern=path.name, top_level_dir=str(directory))
        result = unittest.TextTestRunner(stream=sys.stdout, verbosity=1).run(suite)
        problems = _unit_problems(result)
        if problems:
            failed.append(path)
            print(f"FAIL: {_shown(path)} — a test that did not pass proves nothing:")
            for problem in problems:
                print(f"  {problem}")
        if run_dir is not None:
            write_suite_result(run_dir, path, 1 if problems else 0)
    if failed:
        print(f"evidence.py unittest: FAIL ({len(failed)} of {len(files)} file(s))")
        return 1
    print(f"evidence.py unittest: PASS ({len(files)} file(s))")
    return 0


def criterion_state(items: list[dict[str, Any]], inspected: bool) -> str:
    """``passed``, ``inspected``, ``contract-only``, ``failed`` or ``missing``."""
    if any(item["outcome"] != "passed" for item in items):
        return "failed"
    if any(not item["contract"] for item in items):
        return "passed"
    if inspected:
        return "inspected"
    return "contract-only" if items else "missing"


# --------------------------------------------------------------------------------------------
# Manifest


def _run(argv: list[str]) -> str:
    try:
        completed = subprocess.run(argv, capture_output=True, text=True, check=False, cwd=ROOT)
    except OSError:
        return "unavailable"
    lines = completed.stdout.strip().splitlines()
    return lines[0] if completed.returncode == 0 and lines else "unavailable"


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


def toolchain() -> dict[str, str]:
    return {
        "python3": sys.version.split()[0],
        "uv": _run(["uv", "--version"]),
        "ffmpeg": _run(["ffmpeg", "-hide_banner", "-version"]),
        "ffprobe": _run(["ffprobe", "-hide_banner", "-version"]),
    }


def _now() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def _write_json(path: Path, data: dict[str, Any]) -> None:
    staged = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    staged.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    staged.replace(path)


def record(run_dir: Path, tier: str, fingerprint: str) -> dict[str, Any]:
    """Writes ``run_dir/manifest.json`` and ``latest-<tier>.json``; prunes old runs."""
    if not run_dir.is_dir():
        raise EvidenceError(f"run directory {run_dir} does not exist")
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
        "steps": steps,
        "tests": evidence.tests,
        "suites": evidence.suites,
        "criteria": evidence.criteria,
        "scenarios": evidence.scenarios,
    }
    _write_json(run_dir / "manifest.json", manifest)
    _write_json(VERIFY_DIR / f"latest-{tier}.json", manifest)
    runs = sorted(p for p in (VERIFY_DIR / "runs").iterdir() if p.is_dir())
    for old in runs[:-KEEP_RUNS]:
        shutil.rmtree(old, ignore_errors=True)
    return manifest


def latest_manifest(tier: str | None) -> tuple[Path, dict[str, Any]]:
    """The newest manifest of ``tier``, or of any tier when ``tier`` is None."""
    candidates = [VERIFY_DIR / f"latest-{name}.json" for name in ((tier,) if tier else TIERS)]
    found = [
        (path, json.loads(path.read_text(encoding="utf-8")))
        for path in candidates
        if path.is_file()
    ]
    if not found:
        wanted = f"tier {tier}" if tier else "any tier"
        raise EvidenceError(f"no recorded verification run for {wanted}; run ./scripts/verify.sh")
    return max(found, key=lambda pair: pair[1]["recorded"])


# --------------------------------------------------------------------------------------------
# Commands


def cmd_record(args: argparse.Namespace) -> int:
    manifest = record(Path(args.dir), args.tier, args.fingerprint)
    tagged = len(manifest["criteria"])
    print(f"Evidence: {manifest['result']} — {tagged} criteria tagged — {args.dir}/manifest.json")
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    path, manifest = latest_manifest(args.tier)
    fresh = bool(manifest["fingerprint"]) and manifest["fingerprint"] == current_fingerprint()
    dirty = " (with uncommitted changes)" if manifest["uncommitted_changes"] else ""
    shown = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
    print(
        f"Evidence: {shown} — tier {manifest['tier']}, {manifest['result']}, "
        f"commit {manifest['commit'][:12]}{dirty}, recorded {manifest['recorded']}"
    )
    print(
        "Freshness: FRESH — the tree is unchanged since this run"
        if fresh
        else "Freshness: STALE — the tree changed since this run; it certifies nothing about the "
        f"current tree (rerun ./scripts/verify.sh --tier {manifest['tier']})"
    )
    known = requirements()
    shown_ids = args.ids or sorted({tag[:11] for tag in manifest["criteria"]})
    unknown = [name for name in shown_ids if name not in known]
    if unknown:
        raise EvidenceError(
            f"unknown requirement IDs: {', '.join(unknown)} (no file in docs/requirements/)"
        )
    incomplete = False
    for requirement_id in shown_ids:
        requirement = known[requirement_id]
        print(f"{requirement_id} ({requirement.status})")
        for criterion in requirement.criteria:
            items = manifest["criteria"].get(f"{requirement_id} {criterion}", [])
            state = criterion_state(items, criterion in requirement.inspected)
            incomplete |= state not in ("passed", "inspected")
            print(f"  {criterion:<6} {state:<14} {_test_summary(items)}")
    failed_run = manifest["result"] != "PASS"
    if args.require_complete and failed_run:
        print("Completeness: the run FAILED; a failed run certifies no requirement complete")
    if args.require_fresh and not fresh:
        return 1
    return 1 if args.require_complete and (incomplete or failed_run) else 0


def _test_summary(items: list[dict[str, Any]], shown: int = 4) -> str:
    """Distinct tests (parametrized cases folded into their function), the first few by name."""
    names = sorted({item["test"].split("[", 1)[0] for item in items})
    if not names:
        return ""
    more = f" (+{len(names) - shown} more)" if len(names) > shown else ""
    return f"{len(items)} result(s): " + ", ".join(names[:shown]) + more


def done_problems(run_dir: Path, known: dict[str, Requirement] | None = None) -> list[str]:
    """Criteria of `done` requirements that this run does not evidence."""
    known = requirements() if known is None else known
    evidence = collect(run_dir, known)
    problems = []
    for requirement in known.values():
        if requirement.status != "done":
            continue
        for criterion in requirement.criteria:
            items = evidence.criteria.get(f"{requirement.id} {criterion}", [])
            state = criterion_state(items, criterion in requirement.inspected)
            if state not in ("passed", "inspected"):
                problems.append(f"{requirement.id} {criterion}: {state} in this run")
    return problems


def cmd_check_done(args: argparse.Namespace) -> int:
    problems = done_problems(Path(args.dir))
    for problem in problems:
        print(f"ERROR: {problem}")
    done = sum(1 for r in requirements().values() if r.status == "done")
    if problems:
        print(f"FAIL: {len(problems)} criteria of done requirements lack evidence in this run")
        return 1
    print(f"OK: every criterion of the {done} done requirements is evidenced by this run")
    return 0


def cmd_unittest(args: argparse.Namespace) -> int:
    run_dir = Path(args.dir) if args.dir else None
    if run_dir is not None and not run_dir.is_dir():
        raise EvidenceError(f"run directory {run_dir} does not exist")
    return run_unit_tests(Path(args.directory), run_dir)


def cmd_record_suite(args: argparse.Namespace) -> int:
    write_suite_result(Path(args.dir), Path(args.file), args.exit)
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
    check.set_defaults(handler=cmd_check_done)
    unit = commands.add_parser("unittest", help="run the tooling unit tests; record each file")
    unit.add_argument("--dir", default=os.environ.get("AVE_EVIDENCE_DIR", ""))
    unit.add_argument("directory", nargs="?", default=str(TOOLING_TESTS))
    unit.set_defaults(handler=cmd_unittest)
    suite = commands.add_parser("record-suite", help="record one tooling suite's result")
    suite.add_argument("--dir", required=True)
    suite.add_argument("--file", required=True)
    suite.add_argument("--exit", required=True, type=int)
    suite.set_defaults(handler=cmd_record_suite)
    args = parser.parse_args(argv)
    try:
        return int(args.handler(args))
    except EvidenceError as error:
        print(f"evidence.py: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
