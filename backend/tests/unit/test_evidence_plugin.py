"""The evidence plugin (tests/evidence_plugin.py) on generated test modules: AVE-REQ-097.

Each case runs an inner pytest session with ``pytester`` on a small generated module whose tags,
outcomes and markers are known, and checks the session's exit status and evidence report.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any

import pytest

from tests import evidence_plugin

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
    assert any(arg.startswith("--evidence-report=") for arg in data["invocation"]["args"])
    assert "inifile" in data["invocation"]


def test_a_deselected_test_is_recorded_and_evidences_nothing(pytester: pytest.Pytester) -> None:
    """A test left out by a marker expression, ``-k`` or ``--deselect`` exists and did not run:
    the report names it with its tags, so no run that left it out counts as complete."""
    status, data = _run(
        pytester,
        MODULE,
        "--deselect",
        "test_generated.py::test_tagged_fail",
        "-k",
        "not skipped and not expected",
    )
    assert status == pytest.ExitCode.OK
    outcomes = {Path(t["nodeid"]).name.split("::")[1]: t["outcome"] for t in data["tests"]}
    assert outcomes == {
        "test_tagged_pass": "passed",
        "test_contract_pass": "passed",
        "test_tagged_fail": "deselected",
        "test_skipped": "deselected",
        "test_expected_failure": "deselected",
    }
    left_out = next(t for t in data["tests"] if t["nodeid"].endswith("::test_tagged_fail"))
    assert left_out["req"] == ["AVE-REQ-012 AC-3"]


@pytest.mark.parametrize(
    ("source", "args"),
    [
        pytest.param(
            "import pytest\n\ndef test_a_precondition():\n"
            '    pytest.exit("precondition unavailable", returncode=0)\n\n'
            "def test_b():\n    assert 1 == 2\n",
            (),
            id="pytest.exit-with-status-0",
        ),
        pytest.param("def test_passes():\n    pass\n", ("--collect-only",), id="collect-only"),
        pytest.param("def test_passes():\n    pass\n", ("--setup-plan",), id="setup-plan"),
    ],
)
def test_forbid_skips_fails_a_session_whose_selected_tests_never_ran(
    pytester: pytest.Pytester, source: str, args: tuple[str, ...]
) -> None:
    """A session that ends with status 0 without running a selected test proves nothing: under
    --forbid-skips it fails, and the report records the test as not-run."""
    status, _ = _run(pytester, source, *args)
    assert status == pytest.ExitCode.OK
    status, data = _run(pytester, source, "--forbid-skips", *args)
    assert status == pytest.ExitCode.TESTS_FAILED
    assert data["exitstatus"] == pytest.ExitCode.TESTS_FAILED
    assert "not-run" in {test["outcome"] for test in data["tests"]}


@pytest.mark.parametrize(
    "selection",
    [("--deselect", "test_generated.py::test_tagged_fail"), ("-k", "not tagged_fail")],
    ids=["deselect", "keyword"],
)
def test_a_verification_session_selects_by_marker_expression_only(
    pytester: pytest.Pytester, selection: tuple[str, str]
) -> None:
    """Under --forbid-skips a test left out by --deselect or -k (an option an installed file or the
    environment can inject) stops the session before any test runs."""
    pytester.makepyfile(test_generated=MODULE)
    result = pytester.runpytest_inprocess(
        "-p", "tests.evidence_plugin", "-p", "no:cacheprovider", "--forbid-skips", *selection
    )
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    assert "selects its tests by marker expression only" in "\n".join(
        result.errlines + result.outlines
    )


def test_the_recorder_cannot_be_blocked(pytester: pytest.Pytester) -> None:
    pytester.makepyfile(test_generated="def test_passes():\n    pass\n")
    result = pytester.runpytest_inprocess(
        "-p", "tests.evidence_plugin", "-p", "no:cacheprovider", "-p", "no:ave-evidence-recorder"
    )
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    assert "the evidence recorder is blocked" in "\n".join(result.errlines + result.outlines)


def test_a_test_file_that_git_ignores_stops_the_session(
    pytester: pytest.Pytester, monkeypatch: pytest.MonkeyPatch
) -> None:
    """A tagged test in a directory that .gitignore hides is invisible to git status, to the
    tree fingerprint and to a search of the tracked tree: collecting it is a usage error. The
    same file in a directory Git sees is collected."""
    source = 'import pytest\n\n@pytest.mark.req("AVE-REQ-012 AC-1")\ndef test_x():\n    pass\n'
    subprocess.run(["git", "init", "-q", str(pytester.path)], check=True)  # noqa: S607
    (pytester.path / ".gitignore").write_text("htmlcov/\n", encoding="utf-8")
    monkeypatch.setattr(evidence_plugin, "GIT_ROOT", pytester.path)
    visible = pytester.mkdir("visible")
    (visible / "test_seen.py").write_text(source, encoding="utf-8")
    arguments = ("-p", "tests.evidence_plugin", "-p", "no:cacheprovider")
    assert pytester.runpytest_inprocess(*arguments).ret == pytest.ExitCode.OK
    hidden = pytester.mkdir("htmlcov")
    (hidden / "test_hidden.py").write_text(source, encoding="utf-8")
    result = pytester.runpytest_inprocess(*arguments)
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    output = "\n".join(result.errlines + result.outlines)
    assert "test files that Git ignores" in output
    assert "htmlcov/test_hidden.py" in output
    (hidden / "test_hidden.py").unlink()
    (hidden / "conftest.py").write_text("collect_ignore = []\n", encoding="utf-8")
    (hidden / "test_other.py").write_text(source, encoding="utf-8")
    (pytester.path / ".gitignore").write_text("htmlcov/conftest.py\n", encoding="utf-8")
    result = pytester.runpytest_inprocess(*arguments)
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    assert "htmlcov/conftest.py" in "\n".join(result.errlines + result.outlines)


def test_a_git_that_fails_inside_a_repository_stops_the_session(
    pytester: pytest.Pytester, monkeypatch: pytest.MonkeyPatch
) -> None:
    """The guard against ignored test files needs Git's answer. Inside a repository a Git that
    fails (here: a configuration variable of the caller that Git rejects) or that does not start
    is a usage error; a tree without a repository is the one case in which nothing is asked."""
    source = 'import pytest\n\n@pytest.mark.req("AVE-REQ-012 AC-1")\ndef test_x():\n    pass\n'
    monkeypatch.setattr(evidence_plugin, "GIT_ROOT", pytester.path)
    (pytester.path / "test_seen.py").write_text(source, encoding="utf-8")
    arguments = ("-p", "tests.evidence_plugin", "-p", "no:cacheprovider")
    assert not evidence_plugin._in_repository(pytester.path)
    with monkeypatch.context() as broken:
        broken.setenv("GIT_CONFIG_COUNT", "abc")
        assert pytester.runpytest_inprocess(*arguments).ret == pytest.ExitCode.OK
    subprocess.run(["git", "init", "-q", str(pytester.path)], check=True)  # noqa: S607
    assert evidence_plugin._in_repository(pytester.path)
    assert evidence_plugin._in_repository(pytester.mkdir("below"))
    assert pytester.runpytest_inprocess(*arguments).ret == pytest.ExitCode.OK
    with monkeypatch.context() as broken:
        broken.setenv("GIT_CONFIG_COUNT", "abc")
        result = pytester.runpytest_inprocess(*arguments)
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    output = "\n".join(result.errlines + result.outlines)
    assert "Git failed (git check-ignore: exit 128" in output
    assert "inside a repository the session runs only with that answer" in output
    with monkeypatch.context() as broken:
        broken.setenv("PATH", str(pytester.mkdir("no-tools")))
        result = pytester.runpytest_inprocess(*arguments)
    assert result.ret == pytest.ExitCode.USAGE_ERROR
    assert "Git did not start" in "\n".join(result.errlines + result.outlines)
    assert pytester.runpytest_inprocess(*arguments).ret == pytest.ExitCode.OK


PASSING_MODULE = "def test_passes():\n    pass\n"


@pytest.mark.parametrize(
    ("source", "nodeid", "outcome"),
    [
        pytest.param(
            'import pytest\n\ndef test_x():\n    pytest.skip("not available")\n',
            "test_generated.py::test_x",
            "skipped",
            id="skip-only",
        ),
        pytest.param(
            'import pytest\n\n@pytest.mark.xfail(reason="known")\n'
            "def test_x():\n    assert False\n",
            "test_generated.py::test_x",
            "xfailed",
            id="xfail-only",
        ),
        pytest.param(
            'import pytest\n\n@pytest.mark.xfail(reason="known")\ndef test_x():\n    pass\n',
            "test_generated.py::test_x",
            "xpassed",
            id="xpass-only",
        ),
        pytest.param(
            'import pytest\n\npytest.skip("not available", allow_module_level=True)\n\n'
            "def test_x():\n    pass\n",
            "test_generated.py",
            "skipped",
            id="module-level-skip",
        ),
        pytest.param(
            'import pytest\n\npytest.importorskip("ave_module_that_does_not_exist")\n\n'
            "def test_x():\n    pass\n",
            "test_generated.py",
            "skipped",
            id="importorskip",
        ),
    ],
)
def test_forbid_skips_fails_a_session_with_a_test_that_did_not_run(
    pytester: pytest.Pytester, source: str, nodeid: str, outcome: str
) -> None:
    """One test, or one whole module skipped at collection, that did not run as a passing test
    makes an otherwise green session fail under --forbid-skips (the verify.sh setting); the
    report records it; without the option the same session passes."""
    pytester.makepyfile(test_passing=PASSING_MODULE)
    status, data = _run(pytester, source)
    assert status == pytest.ExitCode.OK
    assert data["exitstatus"] == pytest.ExitCode.OK
    outcomes = {test["nodeid"]: test["outcome"] for test in data["tests"]}
    assert outcomes == {"test_passing.py::test_passes": "passed", nodeid: outcome}
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
