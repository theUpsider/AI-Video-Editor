"""Unit tests of scripts/evidence.py (stdlib unittest; run by verify.sh's fast tier).

Run: python3 -B scripts/evidence.py unittest scripts/tests
Every case works on synthetic run directories and requirement data in a temporary directory;
nothing is written into the repository. The synthetic requirement IDs and criterion tags are built
at run time (:func:`_id`, :func:`_tag`): the only tags written out in this file are the comment
tags of its own cases.
"""

from __future__ import annotations

import contextlib
import dataclasses
import hashlib
import importlib.util
import io
import json
import os
import py_compile
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
    """A unit-test file with one passing test, tagged with ``tag``, plus the ``extra`` class body."""
    return (
        "import unittest\n\n\nclass Case(unittest.TestCase):\n"
        f"    # {tag}\n    def test_passes(self):\n        pass\n\n{extra}"
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
    (
        "tag above a method that is no test",
        "import unittest\n\n\nclass Case(unittest.TestCase):\n    def test_passes(self):\n"
        "        pass\n\n    # {tag}\n    def never_collected_test(self):\n        pass\n",
        "stands above no test",
    ),
    (
        "tag above a test that is never collected",
        "import unittest\n\n\nclass Case(unittest.TestCase):\n    def test_passes(self):\n"
        "        pass\n\n\nclass Helper:\n    # {tag}\n    def test_other(self):\n        pass\n",
        "stands above Helper.test_other, which did not run",
    ),
    (
        "tag above a never-collected test whose name a test of another class carries",
        "import unittest\n\n\nclass Case(unittest.TestCase):\n    def test_other(self):\n"
        "        pass\n\n\nclass Helper:\n    # {tag}\n    def test_other(self):\n        pass\n",
        "stands above Helper.test_other, which did not run",
    ),
    (
        "tag above a module-level function that no loader collects",
        "import unittest\n\n\nclass Case(unittest.TestCase):\n    def test_other(self):\n"
        "        pass\n\n\n# {tag}\ndef test_other():\n    pass\n",
        "stands above test_other, which did not run",
    ),
    (
        "generator test whose body never runs",
        _unit_module("{tag}", "    def test_other(self):\n        self.assertEqual(1, 2)\n        yield\n"),
        "error: test_fixture.Case.test_other",
    ),
    (
        "coroutine test whose body never runs",
        _unit_module("{tag}", "    async def test_other(self):\n        self.assertEqual(1, 2)\n"),
        "error: test_fixture.Case.test_other",
    ),
)


class RunDirectory:
    """A synthetic verify.sh run directory."""

    def __init__(self, base: Path, name: str = "20261002T000000Z-1") -> None:
        self.path = base / "runs" / name
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

    def _suite(self, name: str, text: str) -> Path:
        """Writes the shell suite ``name`` into the tooling directory and lists it in that
        directory's run.sh, the way scripts/tests/run.sh lists the suites of the repository."""
        suite = self.tooling / name
        suite.write_text(text, encoding="utf-8")
        runner = self.tooling / "run.sh"
        listed = runner.read_text(encoding="utf-8") if runner.is_file() else "#!/usr/bin/env bash\n"
        if f"run_suite {name}\n" not in listed:
            runner.write_text(listed + f"run_suite {name}\n", encoding="utf-8")
        return suite

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
        not_run = [{"test": "t::m", "outcome": "not-run", "contract": False, "report": "r"}]
        self.assertEqual(state(not_run, False), "not-run")
        self.assertEqual(state(not_run, True), "inspected")
        self.assertEqual(state(collected[_tag(12, 1)] + not_run, False), "passed")
        self.assertEqual(evidence.unrun(collected[_tag(12, 1)] + not_run), 1)

    # AVE-REQ-097 AC-4
    def test_the_done_gate_judges_every_tier(self) -> None:
        """Failed, contract-only and missing evidence fail in every tier; a tagged test that
        exists and did not run leaves the criterion to the release tier, which fails on it. A
        test deselected in one report and executed in another of the same run did run."""
        known = {_id(12): _requirement(12, "done", 5)}
        self.run_dir.report(
            "unit",
            [
                _test("t::a", "passed", [_tag(12, 1)]),
                _test("t::m", "not-run", [_tag(12, 2)]),
                _test("t::b", "passed", [_tag(12, 3)]),
                _test("t::n", "not-run", [_tag(12, 3)]),
                _test("t::x", "not-run", [_tag(12, 4)]),
            ],
        )
        self.run_dir.report("media", [_test("t::x", "passed", [_tag(12, 4)])])
        missing = f"{_tag(12, 5)}: missing in this run"
        self.assertEqual(evidence.done_problems(self.run_dir.path, known, "fast"), [missing])
        self.assertEqual(evidence.done_problems(self.run_dir.path, known, "media"), [missing])
        self.assertEqual(
            evidence.done_problems(self.run_dir.path, known),
            [
                f"{_tag(12, 2)}: 1 tagged test(s) did not run in this run",
                f"{_tag(12, 3)}: 1 tagged test(s) did not run in this run",
                missing,
            ],
        )
        with self._known(*known.values()):
            for tier, expected in (("fast", 1), ("release", 1)):
                with contextlib.redirect_stdout(io.StringIO()):
                    code = evidence.main(
                        ["check-done", "--dir", str(self.run_dir.path), "--tier", tier]
                    )
                self.assertEqual(code, expected, tier)

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
        ran = self._suite(
            "test-ran.sh",
            f"#!/usr/bin/env bash\n# {_tag(12, 1)}\ntrue\n# {_tag(12, 2)}, {_tag(12, 1)}\n",
        )
        (self.tooling / "test_idle.py").write_text(f"# {_tag(12, 3)}\n", encoding="utf-8")
        known = {_id(12): _requirement(12, "done", 3)}
        # Every step passed; only the file with a suite result of this run evidences its tags.
        self.run_dir.steps(
            ("Verification tooling regression suites", "PASS"),
            ("Evidence tooling unit tests", "PASS"),
        )
        idle = evidence.collect(self.run_dir.path, known).criteria
        self.assertEqual(sorted(idle), [_tag(12, 1), _tag(12, 2), _tag(12, 3)])
        for items in idle.values():
            self.assertEqual(evidence.criterion_state(items, False), "not-run")
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
        self.assertEqual(sorted(collected.criteria), [_tag(12, 1), _tag(12, 2), _tag(12, 3)])
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["passed"])
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 3)]), ["not-run"])
        self.assertEqual(
            collected.suites,
            [{"file": str(ran.resolve()), "exitstatus": 0, "checks": 3, "failed": 0}],
        )
        idle_problem = f"{_tag(12, 3)}: 1 tagged test(s) did not run in this run"
        self.assertEqual(evidence.done_problems(self.run_dir.path, known), [idle_problem])
        self.assertEqual(evidence.done_problems(self.run_dir.path, known, "fast"), [])
        # A suite that ran and failed counts against every criterion it carries.
        evidence.write_suite_result(self.run_dir.path, ran, 1, 3)
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["failed"])
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 2)]), ["failed"])
        # A suite whose own total reports a failed check caught a failure and returned success.
        evidence.write_suite_result(self.run_dir.path, ran, 0, 3, 1)
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["failed"])
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
                idle_problem,
            ],
        )
        stored = json.loads((self.run_dir.path / "suite-test-ran.sh.json").read_text())
        del stored["checks"]
        (self.run_dir.path / "suite-test-ran.sh.json").write_text(json.dumps(stored))
        collected = evidence.collect(self.run_dir.path, known)
        self.assertEqual(_outcomes(collected.criteria[_tag(12, 1)]), ["failed"])

    # AVE-REQ-097 AC-4
    def test_run_sh_records_each_listed_suite_and_a_tagged_file_it_never_runs_stops_the_tool(
        self,
    ) -> None:
        """scripts/tests/run.sh records a result for each suite it runs, and only for those: a
        failing listed suite counts against its criterion, and a listed one that exits 0 without
        printing a ``TOTAL: pass=N fail=M`` line with N >= 1, or with M >= 1 in that line, fails
        the runner and counts against its criterion too. The runner itself carries no tag, and a
        tagged suite it does not list has no runner: its tag stops the evidence tool."""
        project = self.tmp / "project"
        tests = project / "scripts" / "tests"
        tests.mkdir(parents=True)
        shutil.copy(EVIDENCE, project / "scripts" / "evidence.py")
        shutil.copy(ROOT / "scripts" / "reqfile.py", project / "scripts" / "reqfile.py")
        shutil.copy(ROOT / "scripts" / "tests" / "run.sh", tests / "run.sh")
        listed = re.findall(
            r"^run_suite (\S+)", (tests / "run.sh").read_text(encoding="utf-8"), flags=re.M
        )
        self.assertGreater(len(listed), 3)
        failing, noop, caught = listed[-1], listed[-2], listed[-3]
        bodies = {
            "pass": "printf 'STUB TOTAL: pass=1 fail=0\\n'\nexit 0\n",
            "fail": "printf 'STUB TOTAL: pass=0 fail=1\\n'\nexit 1\n",
            "noop": "exit 0\n",  # a placeholder: exits 0 and runs no check
            "caught": "printf 'STUB TOTAL: pass=3 fail=1\\n'\nexit 0\n",  # a caught failure
        }
        kinds = {failing: "fail", noop: "noop", caught: "caught"}
        stubs = [
            (name, _tag(12, number), kinds.get(name, "pass")) for number, name in enumerate(listed, 1)
        ]
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
        self.assertIn(f"<== FAIL: {caught} (its total reports 1 failed check(s)", completed.stdout)
        self.assertIn(f"<== FAIL: {failing} (exit 1)", completed.stdout)
        self.assertIn(f"<== PASS: {listed[0]} (1 checks)", completed.stdout)
        # The real runner, copied as it is, carries no criterion tag: the synthetic requirements
        # below are the only ones the collection needs.
        known = {
            _id(12): _requirement(12, "done", len(listed)),
            _id(13): _requirement(13, "done", 1),
        }
        with (
            mock.patch.object(evidence, "ROOT", project),
            mock.patch.object(evidence, "TOOLING_TESTS", tests),
        ):
            collected = evidence.collect(self.run_dir.path, known).criteria
            problems = evidence.done_problems(self.run_dir.path, known)
            # A tagged suite that run.sh does not list never has a suite result.
            placeholder = tests / "test-placeholder.sh"
            placeholder.write_text(
                f"#!/usr/bin/env bash\n# {_tag(13, 1)}\n{bodies['pass']}", encoding="utf-8"
            )
            for refused in (evidence.collect, evidence.done_problems):
                with self.assertRaises(evidence.EvidenceError) as raised:
                    refused(self.run_dir.path, known)
                self.assertIn(
                    f"scripts/tests/test-placeholder.sh:2: the tag {_tag(13, 1)} stands in a file"
                    " that is neither a suite run.sh lists nor a test_*.py file",
                    str(raised.exception),
                )
        for name, tag, kind in stubs:
            self.assertEqual(_outcomes(collected[tag]), ["passed" if kind == "pass" else "failed"], name)
            self.assertEqual(collected[tag][0]["test"], f"scripts/tests/{name}")
        self.assertEqual(
            problems,
            [
                f"{_tag(12, len(listed) - 2)}: failed in this run",
                f"{_tag(12, len(listed) - 1)}: failed in this run",
                f"{_tag(12, len(listed))}: failed in this run",
                f"{_tag(13, 1)}: missing in this run",
            ],
        )

    # AVE-REQ-097 AC-4
    def test_a_tag_in_a_file_no_runner_runs_stops_record_and_check_done(self) -> None:
        """A comment tag counts through the suite result of the file that holds it. A file of the
        tooling directory that is neither a suite run.sh lists nor a ``test_*.py`` file never has
        one, so a tag there stops ``record`` and ``check-done`` with the file and line."""
        self._suite("test-suite.sh", f"#!/usr/bin/env bash\n# {_tag(12, 1)}\ntrue\n")
        # A suite is listed by a `run_suite <file>` line at the start of a line: a comment that
        # names one lists nothing.
        runner = self.tooling / "run.sh"
        runner.write_text(
            runner.read_text(encoding="utf-8") + "# run_suite test-unlisted.sh\n", encoding="utf-8"
        )
        self.run_dir.steps(("Evidence tooling unit tests", "PASS"))
        known = _requirement(12, "done", 1)
        rule = "stands in a file that is neither a suite run.sh lists nor a test_*.py file"
        strays = {
            "the suite runner": "run.sh",
            "a fixture builder": "make-fixture.sh",
            "a suite the runner names in a comment only": "test-unlisted.sh",
            "a Python file that is no unit-test file": "helpers.py",
            "a file in a subdirectory": "data/notes.txt",
        }
        with mock.patch.object(evidence, "VERIFY_DIR", self.tmp), self._known(known):
            for case, name in strays.items():
                with self.subTest(case):
                    stray = self.tooling / name
                    stray.parent.mkdir(exist_ok=True)
                    before = stray.read_text(encoding="utf-8") if stray.is_file() else None
                    kept = before or "#!/usr/bin/env bash\n"
                    stray.write_text(f"{kept}true\n  # see {_tag(12, 1)}\n", encoding="utf-8")
                    line = len(kept.splitlines()) + 2
                    located = f"{stray.resolve()}:{line}: the tag {_tag(12, 1)} {rule}"
                    with self.assertRaises(evidence.EvidenceError) as raised:
                        evidence.record(self.run_dir.path, "fast", "")
                    self.assertIn(located, str(raised.exception))
                    self.assertFalse((self.run_dir.path / "manifest.json").exists())
                    for command in (["record", "--tier", "fast"], ["check-done"]):
                        stderr = io.StringIO()
                        with (
                            contextlib.redirect_stderr(stderr),
                            contextlib.redirect_stdout(io.StringIO()),
                        ):
                            code = evidence.main([*command, "--dir", str(self.run_dir.path)])
                        self.assertEqual(code, 2, command)
                        self.assertIn(located, stderr.getvalue())
                    if before is None:
                        stray.unlink()
                    else:
                        stray.write_text(before, encoding="utf-8")
            with self.subTest("a file that is no UTF-8 text"):
                binary = self.tooling / "capture.bin"
                binary.write_bytes(b"\xff\xfe\x00\n" + f"# {_tag(12, 1)}\n".encode())
                with self.assertRaises(evidence.EvidenceError) as raised:
                    evidence.record(self.run_dir.path, "fast", "")
                located = f"{binary.resolve()}:2: the tag {_tag(12, 1)} {rule}"
                self.assertIn(located, str(raised.exception))
                binary.unlink()
            # Outside a comment line the text names no test, and a bytecode directory holds no
            # comment line: neither stops the tool, and the listed suite alone carries the tag.
            (self.tooling / "make-fixture.sh").write_text(
                f"#!/usr/bin/env bash\nprintf '%s\\n' '# {_tag(12, 1)}'\n", encoding="utf-8"
            )
            cache = self.tooling / "__pycache__"
            cache.mkdir()
            (cache / "helpers.cpython-312.pyc").write_bytes(f"\n# {_tag(12, 1)}\n".encode())
            self.assertEqual(evidence.unowned_tag_problems(), [])
            self.assertEqual(
                [path.name for path in evidence.tooling_files()], ["test-suite.sh"]
            )
            manifest = evidence.record(self.run_dir.path, "fast", "")
        self.assertEqual(_outcomes(manifest["criteria"][_tag(12, 1)]), ["not-run"])

    # AVE-REQ-097 AC-4
    def test_every_comment_tag_of_the_real_tooling_directory_has_a_runner(self) -> None:
        """On scripts/tests/ of this tree: the suite runner carries no tag, every file with a
        comment tag is a suite run.sh lists or a unit-test file, and once each of them has a
        passing suite result the release tier's done gate finds no tagged test that did not run
        (a tag without a runner would keep its criterion open in every tier)."""
        real = ROOT / "scripts" / "tests"
        with mock.patch.object(evidence, "TOOLING_TESTS", real):
            self.assertEqual(evidence.comment_tags(real / "run.sh"), [])
            self.assertEqual(evidence.unowned_tag_problems(), [])
            files = evidence.tooling_files()
            listed = re.findall(
                r"^run_suite (\S+)", (real / "run.sh").read_text(encoding="utf-8"), flags=re.M
            )
            units = sorted(path.name for path in real.glob("test_*.py"))
            self.assertIn(Path(__file__).name, units)
            self.assertGreater(len(listed), 3)
            self.assertEqual(sorted(path.name for path in files), sorted([*listed, *units]))
            tagged = {
                tag.split(" ")[0] for path in files for _line, tag in evidence.comment_tags(path)
            }
            self.assertIn(_id(97), tagged)
            known = {
                name: dataclasses.replace(requirement, status="done")
                for name, requirement in evidence.requirements().items()
                if name in tagged
            }
            for path in files:
                evidence.write_suite_result(self.run_dir.path, path, 0, 1)
            problems = evidence.done_problems(self.run_dir.path, known)
            self.assertEqual([problem for problem in problems if "did not run" in problem], [])
            # The check has teeth: without the result of one listed suite its tags read not-run.
            (self.run_dir.path / f"suite-{listed[0]}.json").unlink()
            problems = evidence.done_problems(self.run_dir.path, known)
            self.assertTrue(any("tagged test(s) did not run" in problem for problem in problems))

    # AVE-REQ-097 AC-1
    def test_the_suite_runner_stops_when_its_temp_dir_lies_inside_a_work_tree(self) -> None:
        """The suites run Git commands in their fixtures. With TMPDIR inside a repository those
        commands would act on it, so run.sh stops before the first suite and leaves the commit,
        the branch and the working tree as they were."""
        project = self.tmp / "enclosing"
        tests = project / "scripts" / "tests"
        tests.mkdir(parents=True)
        shutil.copy(ROOT / "scripts" / "tests" / "run.sh", tests / "run.sh")

        def git(*arguments: str) -> str:
            command = ["git", "-C", str(project), "-c", "user.name=t", "-c", "user.email=t@t"]
            completed = subprocess.run(
                [*command, *arguments], check=True, capture_output=True, text=True
            )
            return completed.stdout

        git("init", "-q")
        (project / "notes.txt").write_text("one\n", encoding="utf-8")
        git("add", "-A")
        git("commit", "-qm", "one")
        (project / "notes.txt").write_text("two\n", encoding="utf-8")
        git("commit", "-qam", "two")
        (project / "work-in-progress.txt").write_text("unsaved\n", encoding="utf-8")
        scratch = project / "var" / "tmp"
        scratch.mkdir(parents=True)
        before = (git("rev-parse", "HEAD"), git("status", "--porcelain"), git("branch"))
        completed = subprocess.run(
            ["bash", str(tests / "run.sh")],
            env={**os.environ, "TMPDIR": str(scratch)},
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 2, completed.stdout + completed.stderr)
        self.assertIn("lies inside a Git work tree", completed.stderr)
        self.assertNotIn("==>", completed.stdout)
        self.assertEqual((git("rev-parse", "HEAD"), git("status", "--porcelain"), git("branch")), before)
        self.assertEqual(list(scratch.iterdir()), [])

    def _run_unit(self, source: str | None) -> tuple[int, str]:
        """Runs ``evidence.py unittest`` on a directory holding ``test_fixture.py`` (none when
        ``source`` is None), with this case's run directory."""
        directory = self.tooling  # a suite result counts for a file of the tooling directory
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

    # AVE-REQ-097 AC-4
    def test_a_unit_test_file_reaches_no_other_file_and_no_result_of_the_runner(self) -> None:
        """Each file runs in its own interpreter: one that ends the interpreter fails for lack of
        a result, and one that replaces the runner's judgement changes no other file's result."""
        with self.subTest("a file that ends the interpreter"):
            self._check_unit_file(
                "# {tag}\nimport os\n\nos._exit(0)\n",
                1,
                "the test process ended without a result (exit 0)",
            )
        with self.subTest("a file that replaces the runner's judgement"):
            shutil.rmtree(self.tooling)
            self.tooling.mkdir()
            for stale in self.run_dir.path.glob("suite-*.json"):
                stale.unlink()
            (self.tooling / "test_aaa.py").write_text(
                "import sys\nimport unittest\n\n\nclass Case(unittest.TestCase):\n"
                "    def test_patch(self):\n"
                "        sys.modules['__main__']._unit_problems = lambda result: []\n",
                encoding="utf-8",
            )
            (self.tooling / "test_zzz.py").write_text(
                f"# {_tag(12, 1)}\nimport unittest\n\n\nclass Case(unittest.TestCase):\n"
                "    def test_fails(self):\n        self.assertEqual(1, 2)\n",
                encoding="utf-8",
            )
            environment = {k: v for k, v in os.environ.items() if k != "AVE_EVIDENCE_DIR"}
            completed = subprocess.run(
                [sys.executable, "-B", str(EVIDENCE), "unittest", "--dir", str(self.run_dir.path)]
                + [str(self.tooling)],
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(completed.returncode, 1, completed.stdout + completed.stderr)
            known = {_id(12): _requirement(12, "done", 1)}
            collected = evidence.collect(self.run_dir.path, known).criteria
            self.assertEqual(_outcomes(collected[_tag(12, 1)]), ["failed"])

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
        with self.subTest("a tag above a test that a test class inherits and runs"):
            self._check_unit_file(
                "import unittest\n\n\nclass Shared:\n    # {tag}\n    def test_shared(self):\n"
                "        pass\n\n\nclass Case(Shared, unittest.TestCase):\n    pass\n",
                0,
                "evidence.py unittest: PASS",
            )
        with self.subTest("no test file"):
            code, output = self._run_unit(None)
            self.assertEqual(code, 1, output)
            self.assertIn("FAIL: no test_*.py file", output)

    # AVE-REQ-097 AC-2
    def test_manifest_ties_results_to_commit_fingerprint_and_configuration(self) -> None:
        self.run_dir.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
        self.run_dir.steps(("Project control files", "PASS"), ("Backend unit tests", "PASS"))
        suite = self._suite("test-suite.sh", f"# {_tag(12, 2)}\n")
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
        self.assertIn("environment", manifest["toolchain"])
        self.assertEqual(manifest["pytest"], {})
        self.assertEqual(manifest["criteria"][_tag(12, 1)][0]["test"], "t::a")
        self.assertEqual(manifest["criteria"][_tag(12, 2)][0]["test"], str(suite.resolve()))
        self.assertEqual(
            manifest["suites"],
            [{"file": str(suite.resolve()), "exitstatus": 0, "checks": 1, "failed": 0}],
        )
        second = RunDirectory(self.tmp, "20261002T000001Z-1")
        second.steps(("Project control files", "PASS"), ("Backend unit tests", "FAIL"))
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "in-progress", 2)),
        ):
            self.assertEqual(evidence.record(second.path, "fast", "")["result"], "FAIL")
            # A run is recorded once: an old run takes no new fingerprint or tier.
            for tier, fingerprint in (("fast", "0" * 40), ("release", "f" * 40)):
                with self.assertRaises(evidence.EvidenceError) as raised:
                    evidence.record(self.run_dir.path, tier, fingerprint)
                self.assertIn("is recorded already", str(raised.exception))
            stored = json.loads((self.run_dir.path / "manifest.json").read_text(encoding="utf-8"))
            self.assertEqual((stored["tier"], stored["fingerprint"]), ("fast", "f" * 40))

    # AVE-REQ-097 AC-2
    def test_a_tag_outside_a_comment_line_credits_no_criterion(self) -> None:
        """Expected-output strings and fixture text of a suite name criteria too; only a comment
        line tags a case, so the audit of untested criteria reads the evidence tool."""
        suite = self._suite(
            "test-suite.sh",
            f'#!/usr/bin/env bash\n# {_tag(12, 1)}\nexpect "x" 0 "Recorded change: {_tag(12, 2)} differs"\n'
            f"sed 's/^{_tag(12, 3)} //' file\n",
        )
        self.assertEqual(evidence.comment_tags(suite), [(2, _tag(12, 1))])
        evidence.write_suite_result(self.run_dir.path, suite, 0, 1)
        known = {_id(12): _requirement(12, "done", 3)}
        self.assertEqual(
            evidence.done_problems(self.run_dir.path, known),
            [f"{_tag(12, 2)}: missing in this run", f"{_tag(12, 3)}: missing in this run"],
        )

    # AVE-REQ-097 AC-2
    def test_tooling_tags_that_name_no_criterion_stop_the_run_with_file_and_line(self) -> None:
        """Checked in every tier: the tagged file need not have run."""
        suite = self._suite(
            "test-suite.sh",
            f"#!/usr/bin/env bash\n# {_tag(12, 1)}\ntrue\n# {_tag(12, 9)}\n# {_tag(999, 1)}\n",
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
        # A suite result counts for a tooling test file of this tree only: one that names a file
        # elsewhere, carries another name or other tags than its file was written by no runner.
        suite.write_text(f"#!/usr/bin/env bash\n# {_tag(12, 1)}\ntrue\n", encoding="utf-8")
        elsewhere = self.tmp / "elsewhere" / "test-other.sh"
        elsewhere.parent.mkdir()
        elsewhere.write_text(f"true\n# {_tag(12, 2)}\n", encoding="utf-8")
        planted = evidence.write_suite_result(self.run_dir.path, elsewhere, 0, 1)
        with self.assertRaises(evidence.EvidenceError) as raised:
            evidence.done_problems(self.run_dir.path, {known.id: known})
        self.assertIn("names no tooling test file of this tree", str(raised.exception))
        planted.unlink()
        real = evidence.write_suite_result(self.run_dir.path, suite, 0, 1)
        self.assertEqual(
            evidence.done_problems(self.run_dir.path, {known.id: known}),
            [f"{_tag(12, 2)}: missing in this run"],
        )
        renamed = real.with_name("suite-note.json")
        real.rename(renamed)
        with self.assertRaises(evidence.EvidenceError) as raised:
            evidence.done_problems(self.run_dir.path, {known.id: known})
        self.assertIn("names no tooling test file of this tree", str(raised.exception))
        stored = json.loads(renamed.read_text(encoding="utf-8"))
        renamed.unlink()
        stored["tags"].append({"line": 9, "tag": _tag(12, 2)})
        real.write_text(json.dumps(stored), encoding="utf-8")
        with self.assertRaises(evidence.EvidenceError) as raised:
            evidence.done_problems(self.run_dir.path, {known.id: known})
        self.assertIn("its tags differ from the comment tags", str(raised.exception))

    # AVE-REQ-097 AC-2
    def test_the_toolchain_names_the_media_tool_the_product_resolves(self) -> None:
        """AVE_FFMPEG replaces the ffmpeg of PATH for the product, so the manifest records the
        binary it names; no Git variable of the caller redirects the commit lookup."""
        stub = self.tmp / "ffmpeg"
        stub.write_text("#!/bin/sh\necho 'ffmpeg version 0.0-stub'\n", encoding="utf-8")
        stub.chmod(0o755)
        with mock.patch.dict(os.environ, {"AVE_FFMPEG": str(stub), "GIT_DIR": str(self.tmp / "x")}):
            self.assertEqual(evidence.toolchain()["ffmpeg"], "ffmpeg version 0.0-stub")
            self.assertRegex(evidence._run(["git", "rev-parse", "HEAD"]), r"^[0-9a-f]{40}$")

    # AVE-REQ-097 AC-2
    def test_the_package_listing_starts_uv_without_an_environment_file(self) -> None:
        """The digest of the installed packages comes from the locked environment as it is: uv reads
        no environment file, so no variable of such a file reaches the listing."""
        seen: list[list[str]] = []

        def listing(argv: list[str], whole: bool = False) -> str:
            seen.append(argv)
            return "numpy==2.0.0"

        with mock.patch.object(evidence, "_run", side_effect=listing):
            digest = evidence._environment_digest.__wrapped__()
        self.assertEqual(digest, hashlib.sha256(b"numpy==2.0.0").hexdigest()[:16])
        self.assertEqual(seen[0][:4], ["uv", "run", "--frozen", "--no-env-file"])

    # AVE-REQ-097 AC-4
    def test_a_pytest_report_without_executed_tests_proves_nothing(self) -> None:
        report = self.run_dir.path / "pytest-unit.json"
        self.assertIn("no report", evidence.report_problems(report)[0])
        cases = {
            "no test": ([], 0, "no test ran"),
            "deselected tests only": ([_test("t::a", "deselected", [])], 0, "no test ran"),
            "a selected test that never ran": (
                [_test("t::a", "passed", []), _test("t::b", "not-run", [])],
                0,
                "1 selected test(s) never ran, for example t::b",
            ),
            "a failed session": ([_test("t::a", "failed", [])], 1, "the session ended with status 1"),
        }
        for name, (tests, status, problem) in cases.items():
            with self.subTest(name):
                data = {"schema": 1, "exitstatus": status, "tests": tests}
                report.write_text(json.dumps(data), encoding="utf-8")
                self.assertIn(problem, evidence.report_problems(report))
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(evidence.main(["check-report", "--file", str(report)]), 1)
        data = {"schema": 1, "exitstatus": 0, "tests": [_test("t::a", "passed", [])]}
        report.write_text(json.dumps(data), encoding="utf-8")
        self.assertEqual(evidence.report_problems(report), [])

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
                # In every form: without IDs, for the unknown ID and for a known one.
                for args in ([], [_id(999)], [_id(12)]):
                    stderr = io.StringIO()
                    with contextlib.redirect_stderr(stderr):
                        self.assertEqual(self._show(*args), 2, args)
                    self.assertIn(f"unknown requirement IDs: {_id(999)}", stderr.getvalue())

    # AVE-REQ-097 AC-2
    def test_stale_evidence_is_reported_and_refused_when_freshness_is_required(self) -> None:
        self.run_dir.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
        self.run_dir.steps(("Backend unit tests", "PASS"))
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "in-progress", 1)),
        ):
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            with mock.patch.object(evidence, "current_fingerprint", return_value="b" * 40):
                self.assertEqual(self._show("--require-fresh"), 1)
            with mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40):
                self.assertEqual(self._show("--require-fresh"), 0)
                # Another toolchain than the recorded one certifies nothing either.
                other = {**evidence.toolchain(), "ffmpeg": "ffmpeg version 0.0-other"}
                with mock.patch.object(evidence, "toolchain", return_value=other):
                    self.assertEqual(self._show("--require-fresh"), 1)
            # A run without a fingerprint (outside Git) is never fresh.
            evidence.record(RunDirectory(self.tmp, "20261002T000001Z-1").path, "fast", "")
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
            second = RunDirectory(self.tmp, "20261002T000001Z-1")
            second.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
            second.steps(("Backend unit tests", "PASS"), ("Backend lint", "PASS"))
            evidence.record(second.path, "fast", "a" * 40)
            self.assertEqual(self._show(*flags), 0)
            # A failed media run of the same tree stays decisive after a newer fast run passed.
            media = RunDirectory(self.tmp, "20261002T000002Z-1")
            media.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
            media.report("media", [_test("t::m", "failed", [_tag(12, 1)])])
            media.steps(("Backend unit tests", "PASS"), ("Backend media tests", "FAIL"))
            evidence.record(media.path, "media", "a" * 40)
            third = RunDirectory(self.tmp, "20261002T000003Z-1")
            third.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
            third.steps(("Backend unit tests", "PASS"))
            evidence.record(third.path, "fast", "a" * 40)
            self.assertEqual(self._show(*flags), 1)
            self.assertEqual(self._show(*flags, "--tier", "fast"), 0)
            # The heaviest fresh run is the one shown, whatever was recorded last.
            shown = io.StringIO()
            with contextlib.redirect_stdout(shown):
                evidence.main(["show", _id(12)])
            self.assertIn("tier media, FAIL", shown.getvalue())

    # AVE-REQ-097 AC-4
    def test_a_failed_fresh_run_of_a_lighter_tier_refuses_completeness(self) -> None:
        """The heaviest fresh run is the one shown, and a failed fresh run of any tier counts: a
        passing release run certifies no requirement complete while a fast run of the same tree
        failed. A failed fast run of another tree is stale and decides nothing."""
        passed = [_test("t::a", "passed", [_tag(12, 1)])]
        flags = (_id(12), "--require-fresh", "--require-complete")
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "verification", 1)),
            mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40),
        ):
            self.run_dir.report("unit", passed)
            self.run_dir.steps(("Backend unit tests", "PASS"), ("Backend lint", "PASS"))
            evidence.record(self.run_dir.path, "release", "a" * 40)
            self.assertEqual(self._show(*flags), 0)
            fast = RunDirectory(self.tmp, "20261002T000001Z-1")
            fast.report("unit", passed)
            fast.steps(("Backend unit tests", "PASS"), ("Backend lint", "FAIL"))
            evidence.record(fast.path, "fast", "a" * 40)
            shown = io.StringIO()
            with contextlib.redirect_stdout(shown):
                code = evidence.main(["show", *flags])
            self.assertEqual(code, 1, shown.getvalue())
            self.assertIn("tier release, PASS", shown.getvalue())
            self.assertIn("Completeness: the run of tier fast FAILED", shown.getvalue())
            self.assertEqual(self._show(_id(12), "--require-fresh"), 0)
            other = RunDirectory(self.tmp, "20261002T000002Z-1")
            other.report("unit", passed)
            other.steps(("Backend unit tests", "PASS"), ("Backend lint", "FAIL"))
            evidence.record(other.path, "fast", "b" * 40)
            self.assertEqual(self._show(*flags), 0)

    # AVE-REQ-097 AC-2
    def test_record_creates_the_evidence_directory_or_ends_with_a_tool_error(self) -> None:
        """``record --dir`` with a run directory outside var/verify/ in a tree that never ran
        verify.sh: the evidence directory is created; where it cannot be, the command ends with
        the tool's error status and the run stays unrecorded."""
        self.run_dir.steps(("Project control files", "PASS"))
        absent = self.tmp / "fresh-copy" / "var" / "verify"
        with mock.patch.object(evidence, "VERIFY_DIR", absent), self._known():
            manifest = evidence.record(self.run_dir.path, "fast", "f" * 40)
            latest = json.loads((absent / "latest-fast.json").read_text(encoding="utf-8"))
        self.assertEqual(latest, manifest)
        self.assertEqual(manifest["result"], "PASS")
        blocked = self.tmp / "blocked"
        blocked.write_text("a file where the directory would be\n", encoding="utf-8")
        second = RunDirectory(self.tmp, "20261002T000001Z-1")
        second.steps(("Project control files", "PASS"))
        with mock.patch.object(evidence, "VERIFY_DIR", blocked / "verify"), self._known():
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr), contextlib.redirect_stdout(io.StringIO()):
                code = evidence.main(["record", "--dir", str(second.path), "--tier", "fast"])
        self.assertEqual(code, 2, stderr.getvalue())
        self.assertIn("evidence.py: cannot create the evidence directory", stderr.getvalue())
        self.assertFalse((second.path / "manifest.json").exists())

    # AVE-REQ-097 AC-4
    def test_require_complete_refuses_a_missing_and_a_contract_only_criterion(self) -> None:
        """A passing fresh run certifies a requirement complete only when each of its criteria has
        passing evidence from a test that replaces no provider."""
        self.run_dir.report(
            "unit",
            [
                _test("t::a", "passed", [_tag(12, 1)]),
                _test("t::c", "passed", [_tag(13, 1)], contract=True),
            ],
        )
        self.run_dir.steps(("Backend unit tests", "PASS"))
        known = [_requirement(number, "verification", 1) for number in (12, 13, 14)]
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(*known),
            mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40),
        ):
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            for number, expected in ((12, 0), (13, 1), (14, 1)):
                with self.subTest(_id(number)):
                    self.assertEqual(self._show(_id(number), "--require-fresh"), 0)
                    flags = (_id(number), "--require-fresh", "--require-complete")
                    self.assertEqual(self._show(*flags), expected)

    # AVE-REQ-097 AC-4
    def test_a_run_without_a_step_log_is_recorded_as_failed(self) -> None:
        """No step ran, so nothing passed: the manifest of such a run reads FAIL."""
        self.run_dir.report("unit", [_test("t::a", "passed", [_tag(12, 1)])])
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "in-progress", 1)),
        ):
            manifest = evidence.record(self.run_dir.path, "fast", "a" * 40)
        self.assertEqual((manifest["steps"], manifest["result"]), ([], "FAIL"))

    # AVE-REQ-097 AC-2
    def test_without_a_fresh_run_show_reports_the_newest_recorded_one(self) -> None:
        later = RunDirectory(self.tmp, "20261002T000001Z-1")
        runs = (
            (self.run_dir, "media", "2026-10-02T00:00:00Z"),
            (later, "fast", "2026-10-02T00:00:05Z"),
        )
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(),
            mock.patch.object(evidence, "current_fingerprint", return_value="b" * 40),
        ):
            for run, tier, moment in runs:
                run.steps(("Project control files", "PASS"))
                with mock.patch.object(evidence, "_now", return_value=moment):
                    evidence.record(run.path, tier, "a" * 40)
            shown = io.StringIO()
            with contextlib.redirect_stdout(shown):
                self.assertEqual(evidence.main(["show"]), 0)
        self.assertIn("tier fast, PASS", shown.getvalue())
        self.assertIn("Freshness: STALE", shown.getvalue())

    def _repository(self) -> tuple[Path, Any]:
        """A Git repository with one commit that holds the files a manifest describes, and a
        function that runs Git in it."""
        project = self.tmp / "repository"
        (project / "scripts" / "lib").mkdir(parents=True)
        shutil.copy(ROOT / "scripts" / "lib" / "verify-state.sh", project / "scripts" / "lib")
        (project / "scripts" / "verify.sh").write_bytes(b"#!/usr/bin/env bash\n")

        def git(*arguments: str) -> str:
            command = ["git", "-C", str(project), "-c", "user.name=t", "-c", "user.email=t@t"]
            completed = subprocess.run(
                [*command, *arguments], check=True, capture_output=True, text=True
            )
            return completed.stdout.strip()

        git("init", "-q")
        git("add", "-A")
        git("commit", "-qm", "one")
        return project, git

    # AVE-REQ-097 AC-2
    def test_the_manifest_names_the_commit_the_file_hashes_and_uncommitted_changes(self) -> None:
        project, git = self._repository()
        tools = {"python3": "0", "ffmpeg": "ffmpeg version 0.0-stub"}
        verify = project / "scripts" / "verify.sh"
        with (
            mock.patch.object(evidence, "ROOT", project),
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            mock.patch.object(evidence, "toolchain", return_value=tools),
            self._known(),
        ):
            self.run_dir.steps(("Project control files", "PASS"))
            clean = evidence.record(self.run_dir.path, "fast", "f" * 40)
            verify.write_bytes(b"#!/usr/bin/env bash\n# edited\n")
            second = RunDirectory(self.tmp, "20261002T000001Z-1")
            second.steps(("Project control files", "PASS"))
            edited = evidence.record(second.path, "fast", "e" * 40)
        self.assertEqual(clean["commit"], git("rev-parse", "HEAD"))
        self.assertEqual(clean["toolchain"], tools)
        self.assertEqual(
            clean["configuration"],
            {
                "scripts/verify.sh": hashlib.sha256(b"#!/usr/bin/env bash\n").hexdigest(),
                "backend/pyproject.toml": "missing",
                "backend/uv.lock": "missing",
            },
        )
        self.assertFalse(clean["uncommitted_changes"])
        self.assertEqual(edited["commit"], clean["commit"])
        self.assertTrue(edited["uncommitted_changes"])
        self.assertEqual(
            edited["configuration"]["scripts/verify.sh"],
            hashlib.sha256(b"#!/usr/bin/env bash\n# edited\n").hexdigest(),
        )

    # AVE-REQ-097 AC-2
    def test_an_uncommitted_edit_makes_the_recorded_run_stale(self) -> None:
        """Freshness follows the working tree: the fingerprint is the Stop gate's, which changes
        with an edit that no commit holds, while the commit stays the same."""
        project, git = self._repository()
        quiet_git = {"GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"}
        with (
            mock.patch.object(evidence, "ROOT", project),
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            mock.patch.object(evidence, "toolchain", return_value={"python3": "0"}),
            mock.patch.dict(os.environ, quiet_git),
            self._known(),
        ):
            head = git("rev-parse", "HEAD")
            before = evidence.current_fingerprint()
            self.assertRegex(before, r"^[0-9a-f]{40}$")
            self.assertNotEqual(before, head)
            self.run_dir.steps(("Project control files", "PASS"))
            evidence.record(self.run_dir.path, "fast", before)
            self.assertEqual(self._show("--require-fresh"), 0)
            (project / "scripts" / "verify.sh").write_bytes(b"#!/usr/bin/env bash\nexit 1\n")
            self.assertEqual(git("rev-parse", "HEAD"), head)
            self.assertNotEqual(evidence.current_fingerprint(), before)
            self.assertEqual(self._show("--require-fresh"), 1)

    # AVE-REQ-097 AC-4
    def test_no_file_beside_the_script_stands_in_for_a_standard_module(self) -> None:
        """A bytecode file beside evidence.py that carries the name of a standard-library module
        (Git ignores ``*.pyc``, so no status or diff shows it) is never imported: the script keeps
        its own directory out of the module path, whatever environment starts it."""
        scripts = self.tmp / "copy" / "scripts"
        tests = scripts / "tests"
        tests.mkdir(parents=True)
        for name in ("evidence.py", "reqfile.py"):
            shutil.copy(ROOT / "scripts" / name, scripts / name)
        shadow = self.tmp / "shadow.py"
        shadow.write_text(
            "import os\nprint('shadow module imported', flush=True)\nos._exit(0)\n", encoding="utf-8"
        )
        py_compile.compile(str(shadow), cfile=str(scripts / "unittest.pyc"), doraise=True)
        # A source module beside the script under the name of the first module a script could
        # import: the restart comes before any import that the directory could answer.
        shutil.copy(shadow, scripts / "__future__.py")
        failing = _unit_module(_tag(97, 4), "    def test_other(self):\n        self.assertEqual(1, 2)\n")
        (tests / "test_fixture.py").write_text(failing, encoding="utf-8")
        dropped = ("AVE_EVIDENCE_DIR", "PYTHONSAFEPATH")
        environment = {k: v for k, v in os.environ.items() if k not in dropped}
        completed = subprocess.run(
            [sys.executable, "-B", str(scripts / "evidence.py"), "unittest", str(tests)],
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )
        output = completed.stdout + completed.stderr
        self.assertNotIn("shadow module imported", output)
        self.assertEqual(completed.returncode, 1, output)
        self.assertIn("failed: test_fixture.Case.test_other", output)

    # AVE-REQ-097 AC-4
    def test_the_suite_runner_fails_when_a_suite_result_cannot_be_recorded(self) -> None:
        """Inside verify.sh a suite counts through its recorded result: when the result cannot be
        written, run.sh fails although every suite passed."""
        project = self.tmp / "unrecorded"
        tests = project / "scripts" / "tests"
        tests.mkdir(parents=True)
        for name in ("evidence.py", "reqfile.py"):
            shutil.copy(ROOT / "scripts" / name, project / "scripts" / name)
        shutil.copy(ROOT / "scripts" / "tests" / "run.sh", tests / "run.sh")
        listed = re.findall(
            r"^run_suite (\S+)", (tests / "run.sh").read_text(encoding="utf-8"), flags=re.M
        )
        self.assertGreater(len(listed), 3)
        for name in listed:
            stub = tests / name
            stub.write_text(
                "#!/usr/bin/env bash\nprintf 'STUB TOTAL: pass=1 fail=0\\n'\n", encoding="utf-8"
            )
            stub.chmod(0o755)
        outcomes = {}
        for label, directory in (("recorded", self.run_dir.path), ("lost", self.tmp / "no-run")):
            completed = subprocess.run(
                ["bash", str(tests / "run.sh")],
                env={**os.environ, "AVE_EVIDENCE_DIR": str(directory)},
                capture_output=True,
                text=True,
                check=False,
            )
            outcomes[label] = (completed.returncode, completed.stdout)
        self.assertEqual(outcomes["recorded"][0], 0, outcomes["recorded"][1])
        self.assertEqual(outcomes["lost"][0], 1, outcomes["lost"][1])
        self.assertIn(f"<== FAIL: {listed[0]} (result not recorded in ", outcomes["lost"][1])

    # AVE-REQ-097 AC-4
    def test_a_run_that_left_a_tagged_test_out_certifies_no_requirement_complete(self) -> None:
        self.run_dir.report(
            "unit",
            [_test("t::a", "passed", [_tag(12, 1)]), _test("t::m", "not-run", [_tag(12, 1)])],
        )
        self.run_dir.steps(("Backend unit tests", "PASS"))
        with (
            mock.patch.object(evidence, "VERIFY_DIR", self.tmp),
            self._known(_requirement(12, "verification", 1)),
            mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40),
        ):
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            self.assertEqual(self._show(_id(12), "--require-fresh"), 0)
            self.assertEqual(self._show(_id(12), "--require-fresh", "--require-complete"), 1)

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

    def _requirement_file(
        self, number: int, status: str = "done", ticks: str = "x", ident: str = ""
    ) -> Path:
        """A working requirement file in canonical form with two ticked criteria."""
        ident = ident or _id(number)
        path = self.tmp / f"{ident}-sample.md"
        path.write_text(
            f"---\nid: {ident}\ntitle: Sample\ntype: functional\nstatus: {status}\n"
            "priority: must\nparent: AVE-FEAT-001\nsource: derived\nscope: v1\n"
            "primary_gate: M1\norigins: []\ndependencies: []\nscenarios: []\n---\n\n"
            f"# {ident} — Sample\n\n## Intent\nStub.\n\n## Description\nStub.\n\n"
            f"## Acceptance criteria\n- [{ticks}] AC-1 One.\n- [{ticks}] AC-2 Two.\n\n"
            "## Edge cases\nNone.\n\n## Dependencies\nNone.\n\n"
            "## Verification strategy\n- AC-1 — unit — a test.\n"
            "- AC-2 — inspection — a judgement no test can make.\n\n"
            "## Implementation evidence\n- `src/x` — stub\n\n## Test evidence\n"
            "- AC-1 → `tests/x.py::t` — pass\n- AC-2 → inspection: checked the log — pass\n\n"
            "## Status\n- 2026-10-02 — done — verify-requirement PASS (lead)\n",
            encoding="utf-8",
            newline="",
        )
        return path

    def _edit(self, path: Path, old: str, new: str) -> None:
        text = path.read_text(encoding="utf-8")
        self.assertIn(old, text)
        path.write_text(text.replace(old, new, 1), encoding="utf-8", newline="")

    def _check_done(self, path: Path) -> list[str]:
        """The done gate's problems for one requirement file and a run without any evidence."""
        requirement = evidence.read_requirement(path)
        run_dir = self.tmp / "empty-run"
        run_dir.mkdir(exist_ok=True)
        return list(evidence.done_problems(run_dir, {requirement.id: requirement}))

    # AVE-REQ-097 AC-4, AVE-REQ-093 AC-4
    def test_requirement_files_are_parsed_for_status_criteria_and_inspections(self) -> None:
        requirement = evidence.read_requirement(self._requirement_file(50))
        self.assertEqual(requirement.id, _id(50))
        self.assertEqual(requirement.status, "done")
        self.assertEqual(requirement.criteria, ("AC-1", "AC-2"))
        self.assertEqual(requirement.inspected, frozenset({"AC-2"}))
        self.assertEqual(requirement.problems, ())

    # AVE-REQ-097 AC-4
    def test_an_inspection_line_counts_only_for_a_criterion_verified_by_inspection(self) -> None:
        line = "- AC-1 → inspection: read the code — pass\n"
        with self.subTest("the strategy names no inspection for the criterion"):
            path = self._requirement_file(50)
            self._edit(path, "## Test evidence\n", "## Test evidence\n" + line)
            self.assertEqual(evidence.read_requirement(path).inspected, frozenset({"AC-2"}))
        with self.subTest("the strategy names inspection"):
            path = self._requirement_file(50)
            self._edit(path, "- AC-1 — unit — a test.", "- AC-1 — unit and inspection — both.")
            self._edit(path, "## Test evidence\n", "## Test evidence\n" + line)
            self.assertEqual(evidence.read_requirement(path).inspected, frozenset({"AC-1", "AC-2"}))
        with self.subTest("an inspection line inside a fenced block"):
            path = self._requirement_file(50)
            self._edit(
                path,
                "- AC-2 → inspection: checked the log — pass\n",
                "```text\n- AC-2 → inspection: checked the log — pass\n```\n",
            )
            self.assertEqual(evidence.read_requirement(path).inspected, frozenset())

    # AVE-REQ-097 AC-2, AVE-REQ-097 AC-4
    def test_requirement_ids_of_any_width_stay_apart(self) -> None:
        """AVE-REQ-0180 never stands in for AVE-REQ-018, and two files with one ID stop the tool."""
        short = self._requirement_file(18)
        self._requirement_file(180, status="proposed", ticks=" ", ident=_id(18) + "0")
        with mock.patch.object(evidence, "REQUIREMENTS", self.tmp):
            known = evidence.requirements()
            self.assertEqual(sorted(known), [_id(18), _id(18) + "0"])
            self.assertEqual(known[_id(18)].status, "done")
            self.assertEqual(known[_id(18) + "0"].status, "proposed")
            self.assertEqual(evidence.tag_problems([_id(18) + "0 AC-1"], [], known), [])
            shutil.copy(short, self.tmp / f"{_id(18)}-copy.md")
            with self.assertRaises(evidence.EvidenceError) as raised:
                evidence.requirements()
            self.assertIn(f"{_id(18)} has two working files", str(raised.exception))

    # AVE-REQ-097 AC-4, AVE-REQ-093 AC-4
    def test_a_done_requirement_without_evidence_fails_the_done_gate(self) -> None:
        problems = self._check_done(self._requirement_file(50))
        self.assertEqual(problems, [f"{_id(50)} AC-1: missing in this run"])

    # AVE-REQ-097 AC-4, AVE-REQ-093 AC-4
    def test_a_spelling_that_hides_done_or_a_criterion_fails_the_done_gate(self) -> None:
        cases = {
            "capital-X ticks": ("- [x] AC-1 One.\n- [x] AC-2 Two.", "- [X] AC-1 One.\n- [X] AC-2 Two."),
            "quoted status": ("status: done\n", 'status: "done"\n'),
            "single-quoted status": ("status: done\n", "status: 'done'\n"),
            "second status line": ("status: done\n", "status: in-progress\nstatus: done\n"),
            "status behind a line separator": ("priority: must\n", "priority: must\u2028status: ready\n"),
            "second criteria heading": ("- [x] AC-2 Two.", "## Acceptance criteria\n- [x] AC-2 Two."),
            "criteria heading with two spaces": ("- [x] AC-2 Two.", "##  Acceptance criteria\n- [x] AC-2 Two."),
            "carriage return between criteria": ("\n- [x] AC-2 Two.", "\r- [x] AC-2 Two."),
            "criteria inside an HTML comment": ("- [x] AC-1 One.", "<!--\n- [x] AC-1 One.\n-->"),
        }
        for name, (old, new) in cases.items():
            with self.subTest(name):
                path = self._requirement_file(50)
                self._edit(path, old, new)
                problems = self._check_done(path)
                self.assertTrue(
                    any("is outside the canonical form" in problem for problem in problems),
                    f"{name}: the done gate accepted the file ({problems})",
                )
                # The hint names the isolated start of the baseline checker, the one whose
                # result no module path or Python variable of the caller changes.
                self.assertTrue(
                    all(
                        problem.endswith("; python3 -I -B scripts/check_baseline.py lists every problem")
                        for problem in problems
                        if "is outside the canonical form" in problem
                    ),
                    problems,
                )

    # AVE-REQ-097 AC-4
    def test_show_lists_every_criterion_of_a_file_with_a_repeated_criteria_heading(self) -> None:
        path = self._requirement_file(50)
        self._edit(path, "- [x] AC-2 Two.", "## Acceptance criteria\n- [x] AC-2 Two.")
        requirement = evidence.read_requirement(path)
        self.assertEqual(requirement.criteria, ("AC-1", "AC-2"))
        self.assertTrue(requirement.problems)


if __name__ == "__main__":
    unittest.main()
