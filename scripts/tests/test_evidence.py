"""Unit tests of scripts/evidence.py (stdlib unittest; run by verify.sh's fast tier).

Run: python3 -B scripts/evidence.py unittest scripts/tests
Every case works on synthetic run directories and requirement data in a temporary directory;
nothing is written into the repository. The synthetic requirement IDs and criterion tags are built
at run time (:func:`_id`, :func:`_tag`): the only tags written out in this file are the comment
tags of its own cases.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "scripts" / "evidence.py"
_SPEC = importlib.util.spec_from_file_location("evidence_under_test", EVIDENCE)
assert _SPEC is not None
assert _SPEC.loader is not None
evidence = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = evidence
_SPEC.loader.exec_module(evidence)


def _id(number: int) -> str:
    """A requirement ID of the synthetic data."""
    return "AVE-REQ-" + f"{number:03d}"


def _tag(number: int, criterion: int) -> str:
    """A criterion tag of the synthetic data."""
    return f"{_id(number)} AC-{criterion}"


def _requirement(number: int, status: str, criteria: int, inspected: tuple[str, ...] = ()) -> Any:
    return evidence.Requirement(
        _id(number),
        Path(f"{_id(number)}-x.md"),
        status,
        tuple(f"AC-{n}" for n in range(1, criteria + 1)),
        frozenset(inspected),
    )


def _test(nodeid: str, outcome: str, req: list[str], contract: bool = False) -> dict[str, Any]:
    return {"nodeid": nodeid, "outcome": outcome, "req": req, "scenario": [], "contract": contract}


def _outcomes(items: list[dict[str, Any]]) -> list[str]:
    return [item["outcome"] for item in items]


def _unit_module(tag: str, extra: str = "") -> str:
    """A unit-test file tagged with ``tag``: one passing test plus the ``extra`` class body."""
    return (
        f"# {tag}\nimport unittest\n\n\nclass Case(unittest.TestCase):\n"
        f"    def test_passes(self):\n        pass\n\n{extra}"
    )


# Unit-test files whose skipped tests must fail the step: (case, file content, reported problem).
SKIPPING_MODULES = (
    (
        "skipped test",
        _unit_module(
            "{tag}", "    @unittest.skip('not available')\n    def test_other(self):\n        pass\n"
        ),
        "skipped: test_fixture.Case.test_other",
    ),
    (
        "skipped class",
        "# {tag}\nimport unittest\n\n\n@unittest.skip('not available')\n"
        "class Case(unittest.TestCase):\n    def test_other(self):\n        pass\n",
        "skipped: test_fixture.Case.test_other",
    ),
    (
        "skipped module",
        "# {tag}\nimport unittest\n\nraise unittest.SkipTest('not available')\n",
        "skipped: ",
    ),
)

# Unit-test files that did not pass in another way: (case, file content, reported problem).
NOT_PASSING_MODULES = (
    (
        "failing test",
        _unit_module("{tag}", "    def test_other(self):\n        self.assertEqual(1, 2)\n"),
        "failed: test_fixture.Case.test_other",
    ),
    (
        "erroring test",
        _unit_module("{tag}", "    def test_other(self):\n        raise RuntimeError('broken')\n"),
        "error: test_fixture.Case.test_other",
    ),
    (
        "expected failure",
        _unit_module(
            "{tag}",
            "    @unittest.expectedFailure\n    def test_other(self):\n        self.fail('known')\n",
        ),
        "expected to fail: test_fixture.Case.test_other",
    ),
    (
        "unexpected success",
        _unit_module(
            "{tag}", "    @unittest.expectedFailure\n    def test_other(self):\n        pass\n"
        ),
        "passed unexpectedly: test_fixture.Case.test_other",
    ),
    ("file without tests", "# {tag}\nimport unittest\n", "no test ran"),
)


class RunDirectory:
    """A synthetic verify.sh run directory."""

    def __init__(self, base: Path) -> None:
        self.path = base / "runs" / "20261002T000000Z-1"
        self.path.mkdir(parents=True)

    def report(self, name: str, tests: list[dict[str, Any]]) -> None:
        data = {"schema": 1, "exitstatus": 0, "tests": tests}
        (self.path / f"pytest-{name}.json").write_text(json.dumps(data), encoding="utf-8")

    def steps(self, *steps: tuple[str, str]) -> None:
        lines = "".join(f"{name}\t{status}\t1\n" for name, status in steps)
        (self.path / "steps.tsv").write_text(lines, encoding="utf-8")


class EvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: shutil.rmtree(self.tmp))
        self.run_dir = RunDirectory(self.tmp)
        # Tooling-test tags are read from this (empty) directory, not from the repository.
        self.tooling = self.tmp / "tooling"
        self.tooling.mkdir()
        patcher = mock.patch.object(evidence, "TOOLING_TESTS", self.tooling)
        patcher.start()
        self.addCleanup(patcher.stop)

    def _known(self, *requirements: Any) -> Any:
        """Patches the working requirement files with synthetic ones."""
        known = {requirement.id: requirement for requirement in requirements}
        return mock.patch.object(evidence, "requirements", return_value=known)

    # AVE-REQ-097 AC-2
    def test_criterion_states_follow_the_run_results(self) -> None:
        self.run_dir.report(
            "unit",
            [
                _test("t::a", "passed", [_tag(12, 1)]),
                _test("t::b", "passed", [_tag(12, 2)]),
                _test("t::c", "failed", [_tag(12, 2)]),
                _test("t::d", "passed", [_tag(12, 3)], contract=True),
                _test("t::e", "skipped", [_tag(12, 4)]),
            ],
        )
        collected = evidence.collect(self.run_dir.path, {}).criteria
        state = evidence.criterion_state
        self.assertEqual(state(collected[_tag(12, 1)], False), "passed")
        self.assertEqual(state(collected[_tag(12, 2)], False), "failed")
        self.assertEqual(state(collected[_tag(12, 3)], False), "contract-only")
        self.assertEqual(state(collected[_tag(12, 3)], True), "inspected")
        self.assertEqual(state(collected[_tag(12, 4)], False), "failed")
        self.assertEqual(state([], False), "missing")

    # AVE-REQ-097 AC-4
    def test_done_requirements_need_passing_non_contract_evidence(self) -> None:
        known = {
            _id(12): _requirement(12, "done", 3, inspected=("AC-3",)),
            _id(24): _requirement(24, "done", 2),
            _id(31): _requirement(31, "in-progress", 1),
        }
        self.run_dir.report(
            "unit",
            [
                _test("t::a", "passed", [_tag(12, 1), _tag(12, 2)]),
                _test("t::b", "passed", [_tag(24, 1)], contract=True),
                _test("t::c", "skipped", [_tag(24, 2)]),
            ],
        )
        problems = evidence.done_problems(self.run_dir.path, known)
        self.assertEqual(
            problems,
            [
                f"{_tag(24, 1)}: contract-only in this run",
                f"{_tag(24, 2)}: failed in this run",
            ],
        )

    # AVE-REQ-097 AC-4
    def test_tooling_tags_count_only_through_a_suite_result_of_the_run(self) -> None:
        ran = self.tooling / "test-ran.sh"
        ran.write_text(
            f"#!/usr/bin/env bash\n# {_tag(12, 1)}\ntrue\n# {_tag(12, 2)}, {_tag(12, 1)}\n",
            encoding="utf-8",
        )
        (self.tooling / "test_idle.py").write_text(f"# {_tag(12, 3)}\n", encoding="utf-8")
        known = {_id(12): _requirement(12, "done", 3)}
        # Every step passed; only the file with a suite result of this run evidences its tags.
        self.run_dir.steps(
            ("Verification tooling regression suites", "PASS"),
            ("Evidence tooling unit tests", "PASS"),
        )
        self.assertEqual(evidence.collect(self.run_dir.path, known).criteria, {})
        evidence.write_suite_result(self.run_dir.path, ran, 0, 3)
        result = json.loads((self.run_dir.path / "suite-test-ran.sh.json").read_text())
        self.assertEqual(result["exitstatus"], 0)
        self.assertEqual(result["checks"], 3)
        self.assertEqual(
            result["tags"],
            [
                {"line": 2, "tag": _tag(12, 1)},
                {"line": 4, "tag": _tag(12, 2)},
                {"line": 4, "tag": _tag(12, 1)},
            ],
        )
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(sorted(collected.criteria), [_tag(12, 1), _tag(12, 2)])
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["passed"])
        self.assertEqual(
            collected.suites, [{"file": str(ran.resolve()), "exitstatus": 0, "checks": 3}]
        )
        self.assertEqual(
            evidence.done_problems(self.run_dir.path, known),
            [f"{_tag(12, 3)}: missing in this run"],
        )
        # A suite that ran and failed counts against every criterion it carries.
        evidence.write_suite_result(self.run_dir.path, ran, 1, 3)
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["failed"])
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 2)]), ["failed"])
        # A suite that exited 0 without running a check is a placeholder: it counts against every
        # criterion it carries, and so does a result that records no check count at all.
        evidence.write_suite_result(self.run_dir.path, ran, 0, 0)
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["failed"])
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 2)]), ["failed"])
        self.assertEqual(
            evidence.done_problems(self.run_dir.path, known),
            [
                f"{_tag(12, 1)}: failed in this run",
                f"{_tag(12, 2)}: failed in this run",
                f"{_tag(12, 3)}: missing in this run",
            ],
        )
        stored = json.loads((self.run_dir.path / "suite-test-ran.sh.json").read_text())
        del stored["checks"]
        (self.run_dir.path / "suite-test-ran.sh.json").write_text(json.dumps(stored))
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["failed"])

    # AVE-REQ-097 AC-4
    def test_a_suite_that_run_sh_never_runs_gives_no_evidence(self) -> None:
        """scripts/tests/run.sh records a result for each suite it runs, and only for those: a
        tagged suite it does not list gives no evidence, a failing listed one counts against its
        criterion, and a listed one that exits 0 without printing a ``TOTAL: pass=N fail=M`` line
        with N >= 1 fails the runner and counts against its criterion too."""
        project = self.tmp / "project"
        tests = project / "scripts" / "tests"
        tests.mkdir(parents=True)
        shutil.copy(EVIDENCE, project / "scripts" / "evidence.py")
        shutil.copy(ROOT / "scripts" / "tests" / "run.sh", tests / "run.sh")
        listed = re.findall(
            r"^run_suite (\S+)", (tests / "run.sh").read_text(encoding="utf-8"), flags=re.M
        )
        self.assertGreater(len(listed), 2)
        failing, noop = listed[-1], listed[-2]
        bodies = {
            "pass": "printf 'STUB TOTAL: pass=1 fail=0\\n'\nexit 0\n",
            "fail": "printf 'STUB TOTAL: pass=0 fail=1\\n'\nexit 1\n",
            "noop": "exit 0\n",  # a placeholder: exits 0 and runs no check
        }
        stubs = [
            (name, _tag(12, number), "fail" if name == failing else "noop" if name == noop else "pass")
            for number, name in enumerate(listed, 1)
        ]
        stubs.append(("test-placeholder.sh", _tag(13, 1), "fail"))  # tagged, never run by run.sh
        for name, tag, kind in stubs:
            stub = tests / name
            stub.write_text(f"#!/usr/bin/env bash\n# {tag}\n{bodies[kind]}", encoding="utf-8")
            stub.chmod(0o755)
        environment = {**os.environ, "AVE_EVIDENCE_DIR": str(self.run_dir.path)}
        completed = subprocess.run(
            ["bash", str(tests / "run.sh")],
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 1, completed.stdout + completed.stderr)
        self.assertIn(f"<== FAIL: {noop} (no check ran", completed.stdout)
        self.assertIn(f"<== FAIL: {failing} (exit 1)", completed.stdout)
        self.assertIn(f"<== PASS: {listed[0]} (1 checks)", completed.stdout)
        known = {
            _id(12): _requirement(12, "done", len(listed)),
            _id(13): _requirement(13, "done", 1),
        }
        collected = evidence.collect(self.run_dir.path, known).criteria
        for name, tag, kind in stubs[:-1]:
            self.assertEqual(_outcomes(collected[tag]), ["passed" if kind == "pass" else "failed"], name)
            self.assertEqual(collected[tag][0]["test"], f"scripts/tests/{name}")
        self.assertNotIn(_tag(13, 1), collected)
        self.assertEqual(
            evidence.done_problems(self.run_dir.path, known),
            [
                f"{_tag(12, len(listed) - 1)}: failed in this run",
                f"{_tag(12, len(listed))}: failed in this run",
                f"{_tag(13, 1)}: missing in this run",
            ],
        )

    def _run_unit(self, source: str | None) -> tuple[int, str]:
        """Runs ``evidence.py unittest`` on a directory holding ``test_fixture.py`` (none when
        ``source`` is None), with this case's run directory."""
        directory = self.tmp / "unit"
        shutil.rmtree(directory, ignore_errors=True)
        directory.mkdir()
        if source is not None:
            (directory / "test_fixture.py").write_text(source, encoding="utf-8")
        environment = {k: v for k, v in os.environ.items() if k != "AVE_EVIDENCE_DIR"}
        completed = subprocess.run(
            [sys.executable, "-B", str(EVIDENCE), "unittest", "--dir", str(self.run_dir.path)]
            + [str(directory)],
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )
        return completed.returncode, completed.stdout + completed.stderr

    def _check_unit_file(self, source: str, expected_exit: int, problem: str | None) -> None:
        known = {_id(12): _requirement(12, "done", 1)}
        code, output = self._run_unit(source.replace("{tag}", _tag(12, 1)))
        self.assertEqual(code, expected_exit, output)
        if problem is not None:
            self.assertIn(problem, output)
        collected = evidence.collect(self.run_dir.path, known).criteria
        outcome = "passed" if expected_exit == 0 else "failed"
        self.assertEqual(_outcomes(collected[_tag(12, 1)]), [outcome], output)
        expected_problems = [] if expected_exit == 0 else [f"{_tag(12, 1)}: failed in this run"]
        self.assertEqual(evidence.done_problems(self.run_dir.path, known), expected_problems)

    # AVE-REQ-097 AC-4
    def test_a_skipped_unit_test_fails_the_unit_test_step_and_evidences_nothing(self) -> None:
        """A skip in a test, a class or a whole file fails ``evidence.py unittest`` (the
        "Evidence tooling unit tests" step) and the file's tags count as failed."""
        for case, source, problem in SKIPPING_MODULES:
            with self.subTest(case):
                self._check_unit_file(source, 1, problem)

    # AVE-REQ-097 AC-4
    def test_the_unit_test_step_fails_on_every_test_that_did_not_pass(self) -> None:
        for case, source, problem in NOT_PASSING_MODULES:
            with self.subTest(case):
                self._check_unit_file(source, 1, problem)
        with self.subTest("every test passed"):
            self._check_unit_file(_unit_module("{tag}"), 0, "evidence.py unittest: PASS")
        with self.subTest("no test file"):
            code, output = self._run_unit(None)
            self.assertEqual(code, 1, output)
            self.assertIn("FAIL: no test_*.py file", output)

    # AVE-REQ-097 AC-2
    def test_manifest_ties_results_to_commit_fingerprint_and_configuration(self) -> None:
        self.run_dir.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
        self.run_dir.steps(("Project control files", "PASS"), ("Backend unit tests", "PASS"))
        suite = self.tooling / "test-suite.sh"
        suite.write_text(f"# {_tag(12, 2)}\n", encoding="utf-8")
        evidence.write_suite_result(self.run_dir.path, suite, 0, 1)
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "in-progress", 2)),
        ):
            manifest = evidence.record(self.run_dir.path, "fast", "f" * 40)
            latest = json.loads((self.tmp / "latest-fast.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest, latest)
        self.assertEqual(manifest["result"], "PASS")
        self.assertEqual(manifest["fingerprint"], "f" * 40)
        self.assertRegex(manifest["commit"], r"^[0-9a-f]{40}$")
        self.assertIn("scripts/verify.sh", manifest["configuration"])
        self.assertIn("ffmpeg", manifest["toolchain"])
        self.assertEqual(manifest["criteria"][_tag(12, 1)][0]["test"], "t::a")
        self.assertEqual(manifest["criteria"][_tag(12, 2)][0]["test"], str(suite.resolve()))
        self.assertEqual(
            manifest["suites"], [{"file": str(suite.resolve()), "exitstatus": 0, "checks": 1}]
        )
        self.run_dir.steps(("Project control files", "PASS"), ("Backend unit tests", "FAIL"))
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "in-progress", 2)),
        ):
            self.assertEqual(evidence.record(self.run_dir.path, "fast", "")["result"], "FAIL")

    # AVE-REQ-097 AC-2
    def test_tooling_tags_that_name_no_criterion_stop_the_run_with_file_and_line(self) -> None:
        """Checked in every tier: the tagged file need not have run."""
        suite = self.tooling / "test-suite.sh"
        suite.write_text(
            f"#!/usr/bin/env bash\n# {_tag(12, 1)}\ntrue\n# {_tag(12, 9)}\n# {_tag(999, 1)}\n",
            encoding="utf-8",
        )
        shown = str(suite.resolve())
        self.run_dir.steps(("Evidence tooling unit tests", "PASS"))
        known = _requirement(12, "done", 2)
        with mock.patch.object(evidence, "VERIFY_DIR", self.tmp), self._known(known):
            with self.assertRaises(evidence.EvidenceError) as raised:
                evidence.record(self.run_dir.path, "fast", "")
            message = str(raised.exception)
            self.assertIn(f"{shown}:4: {_tag(12, 9)!r}: {known.path.name} has no such", message)
            self.assertIn(f"{shown}:5: {_tag(999, 1)!r} names no requirement file", message)
            self.assertNotIn(f"{shown}:2:", message)
            self.assertFalse((self.run_dir.path / "manifest.json").exists())
            self.assertFalse((self.tmp / "latest-fast.json").exists())
            # The commands exit 2 with the same message: the "Evidence manifest" step of every
            # tier and the release tier's check-done step fail.
            for command in (["record", "--tier", "fast"], ["check-done"]):
                stderr = io.StringIO()
                with contextlib.redirect_stderr(stderr), contextlib.redirect_stdout(io.StringIO()):
                    code = evidence.main([*command, "--dir", str(self.run_dir.path)])
                self.assertEqual(code, 2, command)
                self.assertIn(f"{shown}:5: ", stderr.getvalue())
        # A suite result names its file and line as well, wherever the file lies.
        suite.unlink()
        elsewhere = self.tmp / "elsewhere" / "test-other.sh"
        elsewhere.parent.mkdir()
        elsewhere.write_text(f"true\n# {_tag(12, 3)}\n", encoding="utf-8")
        evidence.write_suite_result(self.run_dir.path, elsewhere, 0, 1)
        with self.assertRaises(evidence.EvidenceError) as raised:
            evidence.done_problems(self.run_dir.path, {known.id: known})
        self.assertIn(f"{elsewhere.resolve()}:2: {_tag(12, 3)!r}", str(raised.exception))

    def _show(self, *args: str) -> int:
        with contextlib.redirect_stdout(io.StringIO()):
            return int(evidence.main(["show", *args]))

    # AVE-REQ-097 AC-2
    def test_show_reports_an_unknown_requirement_id_as_an_error(self) -> None:
        self.run_dir.report(
            "unit",
            [_test("t::a", "passed", [_tag(12, 1)]), _test("t::b", "passed", [_tag(999, 1)])],
        )
        self.run_dir.steps(("Backend unit tests", "PASS"))
        with mock.patch.object(evidence, "VERIFY_DIR", self.tmp):
            evidence.record(self.run_dir.path, "fast", "")
            with self._known(_requirement(12, "in-progress", 1)):
                for args in ([], [_id(999)]):
                    stderr = io.StringIO()
                    with contextlib.redirect_stderr(stderr):
                        self.assertEqual(self._show(*args), 2, args)
                    self.assertIn(f"unknown requirement IDs: {_id(999)}", stderr.getvalue())
                self.assertEqual(self._show(_id(12)), 0)

    # AVE-REQ-097 AC-2
    def test_stale_evidence_is_reported_and_refused_when_freshness_is_required(self) -> None:
        self.run_dir.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
        self.run_dir.steps(("Backend unit tests", "PASS"))
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "in-progress", 1)),
        ):
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            with mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40):
                self.assertEqual(self._show("--require-fresh"), 0)
            with mock.patch.object(evidence, "current_fingerprint", return_value="b" * 40):
                self.assertEqual(self._show("--require-fresh"), 1)
            # A run without a fingerprint (outside Git) is never fresh.
            evidence.record(self.run_dir.path, "fast", "")
            with mock.patch.object(evidence, "current_fingerprint", return_value=""):
                self.assertEqual(self._show("--require-fresh"), 1)

    # AVE-REQ-097 AC-4
    def test_a_failed_run_never_certifies_a_requirement_complete(self) -> None:
        """Every criterion has passing evidence, yet a run with a failed step makes
        ``show --require-fresh --require-complete`` exit 1."""
        self.run_dir.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
        flags = (_id(12), "--require-fresh", "--require-complete")
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "verification", 1)),
            mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40),
        ):
            self.run_dir.steps(("Backend unit tests", "PASS"), ("Backend lint", "FAIL"))
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            self.assertEqual(self._show(*flags), 1)
            self.run_dir.steps(("Backend unit tests", "PASS"), ("Backend lint", "PASS"))
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            self.assertEqual(self._show(*flags), 0)

    # AVE-REQ-097 AC-2
    def test_unknown_or_malformed_tags_are_reported(self) -> None:
        known = {_id(12): _requirement(12, "ready", 2)}
        problems = evidence.tag_problems(
            [_tag(12, 1), _tag(12, 3), _tag(13, 1), _tag(12, 1) + "/AC-2"],
            [],
            known,
        )
        self.assertEqual(len(problems), 3)
        self.assertIn("has no such criterion", problems[0])
        self.assertIn("names no requirement file", problems[1])
        self.assertIn("is not of the form", problems[2])

    def test_requirement_files_are_parsed_for_status_criteria_and_inspections(self) -> None:
        path = self.tmp / f"{_id(50)}-sample.md"
        path.write_text(
            f"---\nid: {_id(50)}\nstatus: done\n---\n\n## Acceptance criteria\n"
            "- [x] AC-1 One.\n- [x] AC-2 Two.\n\n## Test evidence\n"
            "- AC-1 → `tests/x.py::t` — pass\n- AC-2 → inspection: checked the log — pass\n",
            encoding="utf-8",
        )
        requirement = evidence.read_requirement(path)
        self.assertEqual(requirement.id, _id(50))
        self.assertEqual(requirement.status, "done")
        self.assertEqual(requirement.criteria, ("AC-1", "AC-2"))
        self.assertEqual(requirement.inspected, frozenset({"AC-2"}))


if __name__ == "__main__":
    unittest.main()
