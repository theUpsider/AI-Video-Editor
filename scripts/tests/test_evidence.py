"""Unit tests of scripts/evidence.py (stdlib unittest; run by verify.sh's fast tier).

Run: python3 -B -m unittest discover -s scripts/tests -p 'test_*.py'
Every case works on synthetic run directories and requirement data in a temporary directory;
nothing is written into the repository.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
_SPEC = importlib.util.spec_from_file_location("evidence_under_test", ROOT / "scripts/evidence.py")
assert _SPEC is not None
assert _SPEC.loader is not None
evidence = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = evidence
_SPEC.loader.exec_module(evidence)


def _requirement(rid: str, status: str, criteria: int, inspected: tuple[str, ...] = ()) -> Any:
    return evidence.Requirement(
        rid,
        Path(f"{rid}-x.md"),
        status,
        tuple(f"AC-{n}" for n in range(1, criteria + 1)),
        frozenset(inspected),
    )


def _test(nodeid: str, outcome: str, req: list[str], contract: bool = False) -> dict[str, Any]:
    return {"nodeid": nodeid, "outcome": outcome, "req": req, "scenario": [], "contract": contract}


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
        self.addCleanup(lambda: __import__("shutil").rmtree(self.tmp))
        self.run_dir = RunDirectory(self.tmp)
        # Tooling-test tags are read from this (empty) directory, not from the repository.
        self.tooling = self.tmp / "tooling"
        self.tooling.mkdir()
        patcher = mock.patch.object(evidence, "TOOLING_TESTS", self.tooling)
        patcher.start()
        self.addCleanup(patcher.stop)

    # AVE-REQ-097 AC-2
    def test_criterion_states_follow_the_run_results(self) -> None:
        self.run_dir.report(
            "unit",
            [
                _test("t::a", "passed", ["AVE-REQ-012 AC-1"]),
                _test("t::b", "passed", ["AVE-REQ-012 AC-2"]),
                _test("t::c", "failed", ["AVE-REQ-012 AC-2"]),
                _test("t::d", "passed", ["AVE-REQ-012 AC-3"], contract=True),
                _test("t::e", "skipped", ["AVE-REQ-012 AC-4"]),
            ],
        )
        collected = evidence.collect(self.run_dir.path).criteria
        state = evidence.criterion_state
        self.assertEqual(state(collected["AVE-REQ-012 AC-1"], False), "passed")
        self.assertEqual(state(collected["AVE-REQ-012 AC-2"], False), "failed")
        self.assertEqual(state(collected["AVE-REQ-012 AC-3"], False), "contract-only")
        self.assertEqual(state(collected["AVE-REQ-012 AC-3"], True), "inspected")
        self.assertEqual(state(collected["AVE-REQ-012 AC-4"], False), "failed")
        self.assertEqual(state([], False), "missing")

    # AVE-REQ-097 AC-4
    def test_done_requirements_need_passing_non_contract_evidence(self) -> None:
        known = {
            "AVE-REQ-012": _requirement("AVE-REQ-012", "done", 3, inspected=("AC-3",)),
            "AVE-REQ-024": _requirement("AVE-REQ-024", "done", 2),
            "AVE-REQ-031": _requirement("AVE-REQ-031", "in-progress", 1),
        }
        self.run_dir.report(
            "unit",
            [
                _test("t::a", "passed", ["AVE-REQ-012 AC-1", "AVE-REQ-012 AC-2"]),
                _test("t::b", "passed", ["AVE-REQ-024 AC-1"], contract=True),
                _test("t::c", "skipped", ["AVE-REQ-024 AC-2"]),
            ],
        )
        problems = evidence.done_problems(self.run_dir.path, known)
        self.assertEqual(
            problems,
            [
                "AVE-REQ-024 AC-1: contract-only in this run",
                "AVE-REQ-024 AC-2: failed in this run",
            ],
        )

    # AVE-REQ-097 AC-4
    def test_tooling_test_tags_take_the_outcome_of_their_step(self) -> None:
        (self.tooling / "test-suite.sh").write_text("# AVE-REQ-093 AC-1\ncase\n", encoding="utf-8")
        (self.tooling / "test_unit.py").write_text("# AVE-REQ-093 AC-2\n", encoding="utf-8")
        self.run_dir.steps(
            ("Verification tooling regression suites", "FAIL"),
            ("Evidence tooling unit tests", "PASS"),
        )
        with mock.patch.object(evidence, "ROOT", self.tmp):
            collected = evidence.collect(self.run_dir.path).criteria
        self.assertEqual([i["outcome"] for i in collected["AVE-REQ-093 AC-1"]], ["failed"])
        self.assertEqual([i["outcome"] for i in collected["AVE-REQ-093 AC-2"]], ["passed"])
        # A tier that did not run the step gives its tags no evidence at all.
        self.run_dir.steps(("Evidence tooling unit tests", "PASS"))
        with mock.patch.object(evidence, "ROOT", self.tmp):
            collected = evidence.collect(self.run_dir.path).criteria
        self.assertNotIn("AVE-REQ-093 AC-1", collected)

    # AVE-REQ-097 AC-2
    def test_manifest_ties_results_to_commit_fingerprint_and_configuration(self) -> None:
        self.run_dir.report("unit", [_test("t::a", "passed", ["AVE-REQ-012 AC-1"])])
        self.run_dir.steps(("Project control files", "PASS"), ("Backend unit tests", "PASS"))
        with mock.patch.object(evidence, "VERIFY_DIR", self.tmp):
            manifest = evidence.record(self.run_dir.path, "fast", "f" * 40)
            latest = json.loads((self.tmp / "latest-fast.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest, latest)
        self.assertEqual(manifest["result"], "PASS")
        self.assertEqual(manifest["fingerprint"], "f" * 40)
        self.assertRegex(manifest["commit"], r"^[0-9a-f]{40}$")
        self.assertIn("scripts/verify.sh", manifest["configuration"])
        self.assertIn("ffmpeg", manifest["toolchain"])
        self.assertEqual(manifest["criteria"]["AVE-REQ-012 AC-1"][0]["test"], "t::a")
        self.run_dir.steps(("Project control files", "PASS"), ("Backend unit tests", "FAIL"))
        with mock.patch.object(evidence, "VERIFY_DIR", self.tmp):
            self.assertEqual(evidence.record(self.run_dir.path, "fast", "")["result"], "FAIL")

    def _show(self, *args: str) -> int:
        with contextlib.redirect_stdout(io.StringIO()):
            return int(evidence.main(["show", *args]))

    # AVE-REQ-097 AC-2
    def test_stale_evidence_is_reported_and_refused_when_freshness_is_required(self) -> None:
        self.run_dir.report("unit", [_test("t::a", "passed", ["AVE-REQ-012 AC-1"])])
        self.run_dir.steps(("Backend unit tests", "PASS"))
        with mock.patch.object(evidence, "VERIFY_DIR", self.tmp):
            evidence.record(self.run_dir.path, "fast", "a" * 40)
            with mock.patch.object(evidence, "current_fingerprint", return_value="a" * 40):
                self.assertEqual(self._show("--require-fresh"), 0)
            with mock.patch.object(evidence, "current_fingerprint", return_value="b" * 40):
                self.assertEqual(self._show("--require-fresh"), 1)
            # A run without a fingerprint (outside Git) is never fresh.
            evidence.record(self.run_dir.path, "fast", "")
            with mock.patch.object(evidence, "current_fingerprint", return_value=""):
                self.assertEqual(self._show("--require-fresh"), 1)

    # AVE-REQ-097 AC-2
    def test_unknown_or_malformed_tags_are_reported(self) -> None:
        known = {"AVE-REQ-012": _requirement("AVE-REQ-012", "ready", 2)}
        problems = evidence.tag_problems(
            ["AVE-REQ-012 AC-1", "AVE-REQ-012 AC-3", "AVE-REQ-013 AC-1", "AVE-REQ-012 AC-1/AC-2"],
            [],
            known,
        )
        self.assertEqual(len(problems), 3)
        self.assertIn("has no such criterion", problems[0])
        self.assertIn("names no requirement file", problems[1])
        self.assertIn("is not of the form", problems[2])

    def test_requirement_files_are_parsed_for_status_criteria_and_inspections(self) -> None:
        path = self.tmp / "AVE-REQ-050-sample.md"
        path.write_text(
            "---\nid: AVE-REQ-050\nstatus: done\n---\n\n## Acceptance criteria\n"
            "- [x] AC-1 One.\n- [x] AC-2 Two.\n\n## Test evidence\n"
            "- AC-1 → `tests/x.py::t` — pass\n- AC-2 → inspection: checked the log — pass\n",
            encoding="utf-8",
        )
        requirement = evidence.read_requirement(path)
        self.assertEqual(requirement.id, "AVE-REQ-050")
        self.assertEqual(requirement.status, "done")
        self.assertEqual(requirement.criteria, ("AC-1", "AC-2"))
        self.assertEqual(requirement.inspected, frozenset({"AC-2"}))


if __name__ == "__main__":
    unittest.main()
