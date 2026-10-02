"""The evidence plugin (tests/evidence_plugin.py) on generated test modules: AVE-REQ-097.

Each case runs an inner pytest session with ``pytester`` on a small generated module whose tags,
outcomes and markers are known, and checks the session's exit status and evidence report.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest

pytestmark = pytest.mark.req("AVE-REQ-097 AC-2", "AVE-REQ-097 AC-4")

MODULE = """
import pytest

@pytest.mark.req("AVE-REQ-012 AC-1", "AVE-REQ-012 AC-2")
@pytest.mark.scenario("AT-02")
def test_tagged_pass():
    pass

@pytest.mark.req("AVE-REQ-012 AC-3")
def test_tagged_fail():
    assert 1 == 2

@pytest.mark.req("AVE-REQ-012 AC-4")
@pytest.mark.contract
def test_contract_pass():
    pass

@pytest.mark.req("AVE-REQ-024 AC-1")
def test_skipped():
    pytest.skip("not available")

@pytest.mark.xfail(reason="known")
def test_expected_failure():
    assert False
"""


def _run(pytester: pytest.Pytester, source: str, *args: str) -> tuple[int, dict[str, Any]]:
    pytester.makepyfile(test_generated=source)
    report = pytester.path / "evidence.json"
    result = pytester.runpytest_inprocess(
        "-p",
        "tests.evidence_plugin",
        "-p",
        "no:cacheprovider",
        f"--evidence-report={report}",
        *args,
    )
    data = json.loads(report.read_text()) if report.is_file() else {}
    return int(result.ret), data


def test_report_records_tags_outcomes_and_contract_flags(pytester: pytest.Pytester) -> None:
    """Every test that ran is recorded with its outcome, its full criterion and scenario tags and
    its contract flag, so scripts/evidence.py can map criteria to results."""
    status, data = _run(pytester, MODULE)
    assert status == pytest.ExitCode.TESTS_FAILED  # test_tagged_fail
    tests = {Path(t["nodeid"]).name.split("::")[1]: t for t in data["tests"]}
    assert tests["test_tagged_pass"]["outcome"] == "passed"
    assert tests["test_tagged_pass"]["req"] == ["AVE-REQ-012 AC-1", "AVE-REQ-012 AC-2"]
    assert tests["test_tagged_pass"]["scenario"] == ["AT-02"]
    assert tests["test_tagged_pass"]["contract"] is False
    assert tests["test_tagged_fail"]["outcome"] == "failed"
    assert tests["test_contract_pass"]["contract"] is True
    assert tests["test_skipped"]["outcome"] == "skipped"
    assert tests["test_expected_failure"]["outcome"] == "xfailed"
    assert data["schema"] == 1


def test_forbid_skips_fails_a_session_with_tests_that_did_not_run(
    pytester: pytest.Pytester,
) -> None:
    """A skipped or expected-to-fail test makes an otherwise green session fail under
    --forbid-skips (the verify.sh setting); without the option the same session passes."""
    source = MODULE.replace("assert 1 == 2", "pass")
    status, _ = _run(pytester, source)
    assert status == pytest.ExitCode.OK
    status, _ = _run(pytester, source, "--forbid-skips")
    assert status == pytest.ExitCode.TESTS_FAILED


@pytest.mark.parametrize(
    ("tag", "message"),
    [
        ('req("AVE-REQ-012 AC-99")', "has no such criterion"),
        ('req("AVE-REQ-999 AC-1")', "names no requirement file"),
        ('req("AVE-REQ-012 AC-1/AC-2")', "is not of the form"),
        ('req("REQ-012 AC-1")', "is not of the form"),
        ('scenario("AT-99")', "is not a scenario"),
        ("req()", "takes tag strings only"),
    ],
)
def test_unknown_or_malformed_tags_stop_the_session(
    pytester: pytest.Pytester, tag: str, message: str
) -> None:
    """A tag that does not name an existing criterion or scenario is a usage error before any
    test runs: evidence can never point at a criterion that does not exist."""
    source = f"import pytest\n\n@pytest.mark.{tag}\ndef test_x():\n    pass\n"
    pytester.makepyfile(test_generated=source)
    result = pytester.runpytest_inprocess("-p", "tests.evidence_plugin", "-p", "no:cacheprovider")
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    assert message in "\n".join(result.errlines + result.outlines)
