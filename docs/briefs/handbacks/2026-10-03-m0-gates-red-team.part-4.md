# Handback — M0 gates red-team, part 4: completeness critic of AVE-REQ-097

Brief: [2026-10-03-m0-gates-red-team.md](../2026-10-03-m0-gates-red-team.md). Run `wf_98f469f7-ec5` at `35f99c5` ([script](../../workflows/m0-gates-red-team-wf_98f469f7-ec5.js)). Each finder worked read-only in a private clone; the reports below are theirs, unedited apart from local paths. The lead's disposition closes each section.

## Lens critic AVE-REQ-097

### Scope, method and probes without a finding

```text
critic AVE-REQ-097 — gaps left by lenses 097-D and 097-E, probed in a private clone at 35f99c5. The input held two finder results; no 097-F result (pytest plugin, hooks, CI) was in it, so that area had no listed probes and I covered its main openings. Gaps named and probed: selected tests that never run (session ended with status 0); files Git ignores that the runners still load (a conftest.py, a sourceless .pyc); the Python environment as an input (PYTHONPATH, site-packages); the fixture cache under var/; the Stop gate's own state file; what decides that a test is a media test; whether the suites named in § Verification strategy fail when the behavior is removed (mutants); two statements of § Edge cases and § Verification strategy; the Windows host path and CI. 10 findings (5 blocking, 5 boundary), 10 held probes.
```

### Baseline

```text
All three baseline commands passed in the clone at 35f99c5 before the first probe (container image ave-dev:3084842326).
- `./scripts/verify.sh`: exit 0, `verify.sh: PASS — tier fast (9 of 9 steps passed)`; `112 passed, 84 deselected in 21.66s`; `Evidence: PASS — 36 criteria tagged`.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest`: exit 0, `OK`, `evidence.py unittest: PASS (1 file(s))`.
- `./scripts/dev-container.sh bash scripts/tests/run.sh`: exit 0, `scripts/tests/run.sh: PASS (6 suites)` (CHECKER 200, BASELINE 101, STOP HOOK 72, SESSION START 31, VERIFY TIERS 23, PROBE 28, each fail=0).
I ran no release tier: every finding was confirmed in the fast tier or in the step it concerns. Logs: <session scratchpad>\critic097\ (baseline-fast.log, baseline-unittest.log, baseline-run.log).

Scope notes for the lead:
- The input named three finders and held the results of 097-D and 097-E only. Findings 1 to 3 lie in lens 097-F's area and may repeat probes of that lens.
- All findings are measured at 35f99c5. At the end the main checkout held uncommitted changes in 31 files by another agent. A read-only grep there showed text that addresses finding 1 (`not-run`, `pytest.exit`, `evidence.py check-report`), finding 2 ("every loaded conftest.py is a file Git knows") and part (a) of finding 3 (PYTHONPATH unset in verify.sh). I probed none of that work.
```

### Finding critic-097-1 (blocking) — A test that ends the pytest session with status 0 leaves the later tests unrun: the fast tier passes and the criterion of a failing test reads passed

Criterion: AVE-REQ-097 AC-4 (caught exceptions returning success; Edge cases line 1; ARCHITECTURE § Testing strategy item 3; plugin docstring: "a test that did not run proves nothing, so verification never lets one through as green"); Edge case "a failing step in any tier fails that tier" (AC-1)

Reproduction:

```text
In the clone, inside `./scripts/dev-container.sh bash -c '…'`. Definitions reused below:
BROKEN = appended to backend/tests/unit/test_rates.py: `@pytest.mark.req("AVE-REQ-018 AC-3")` / `def test_redteam_broken() -> None:` / `    assert resolve_auto_frame_rate([]).fps == 31`
STEP = the "Backend unit tests" step alone, after `find backend scripts -name __pycache__ -type d -prune -exec rm -rf {} +`: `uv run --frozen --quiet --directory backend pytest -q -m "not media and not slow" -p no:cacheprovider --forbid-skips --evidence-report=<dir>/pytest-unit.json`
Control: BROKEN, STEP.
(a) append `def test_redteam_stop() -> None:` / `    pytest.exit("enough for today", returncode=0)` and then BROKEN; delete __pycache__; `./scripts/verify.sh`; `python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete`
(b) the same with `import os` added to the imports and `os._exit(0)` as the body of test_redteam_stop; `./scripts/verify.sh`; `ls` of the newest var/verify/runs/ directory; `python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh`
```

Observed:

```text
Control: `1 failed, 112 passed, 84 deselected in 15.53s`, exit 1.
(a) `73 passed, 84 deselected in 17.00s`, `!!!!!!!!!!!!!!!!!!! _pytest.outcomes.Exit: enough for today !!!!!!!!!!!!!!!!!!!!`, `<== PASS: Backend unit tests (18s)`; format check, lint and type check PASS; `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0. Manifest `PASS tests {'passed': 73}`: 41 of the 114 selected tests, the failing one among them, have no outcome and appear nowhere. show: `Freshness: FRESH`, `AC-3   passed   2 result(s): tests/unit/test_rates.py::test_no_source_gives_a_provisional_30, …::test_resolved_rate_does_not_change_after_another_import`, exit 0.
(b) the step output ends after 73 dots without a summary line, `<== PASS: Backend unit tests (8s)`, `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0. Run directory: `manifest.json steps.tsv suite-test_evidence.py.json` (no pytest-unit.json). Manifest `PASS tests {} criteria 2`. show: `tier fast, PASS`, `Freshness: FRESH`, AC-1 to AC-4 `missing`, exit 0.
```

Expected:

```text
The step fails: selected tests did not run (a); the session left no report (b).
```

Fix:

```text
backend/tests/evidence_plugin.py: note the selection at `pytest_collection_finish`; under --forbid-skips a selected test that is still `not-run` at session finish sets TESTS_FAILED, whatever status pytest.exit asked for. scripts/verify.d/20-backend.sh: after pytest returns 0 the step checks, outside the test process (os._exit skips every hook), that the report exists, records exit status 0 and holds one outcome per selected test. Holding cases: backend/tests/unit/test_evidence_plugin.py `test_forbid_skips_fails_a_session_with_a_test_that_did_not_run` gains a module `def test_a(): pytest.exit("x", returncode=0)` + `def test_b(): pass` (TESTS_FAILED); scripts/tests/test_evidence.py: a run directory whose pytest step passed without a report fails the report check.
```

Lead's disposition: fixed (with 097-D): under --forbid-skips a selected test that never ran fails the session, and after each pytest step `evidence.py check-report` fails a report that is missing, records a non-zero status or holds a selected test without an outcome; cases in test_evidence_plugin.py (a test that calls pytest.exit with status 0) and test_evidence.py (a report without executed tests).

### Finding critic-097-2 (blocking) — A conftest.py in a directory name that .gitignore lists is loaded: it tags a passing test with a criterion no test in the tree carries and removes a failing test, on a tree Git reports clean

Criterion: AVE-REQ-097 AC-2 (evidence tied to the tree fingerprint and to requirement IDs), AC-4; verify-requirement § 4 (tag search with `git grep --untracked`). Combination of 097-D finding 1 with another file kind

Reproduction:

```text
mkdir -p backend/tests/unit/test-results; write backend/tests/unit/test-results/conftest.py (no test file beside it): module docstring, `from __future__ import annotations`, `import pytest`, then
@pytest.hookimpl(tryfirst=True)
def pytest_collection_modifyitems(items: list[pytest.Item]) -> None:
    kept = []
    for item in items:
        if item.name == "test_redteam_broken":
            continue
        if item.name == "test_no_source_gives_a_provisional_30":
            item.add_marker(pytest.mark.req("AVE-REQ-096 AC-3"))
        kept.append(item)
    items[:] = kept
git status --short; git check-ignore -v backend/tests/unit/test-results/conftest.py; git grep -n -w --untracked 'AVE-REQ-096 AC-3' -- ':!*.md'; bash -c '. ./scripts/lib/verify-state.sh && vstate_fingerprint'; ./scripts/verify.sh; python3 -B scripts/evidence.py show AVE-REQ-096 --require-fresh
Then BROKEN (finding 1) appended to test_rates.py and STEP.
```

Observed:

```text
git status: empty. `.gitignore:36:test-results/	backend/tests/unit/test-results/conftest.py`. git grep: exit 1 (AVE-REQ-096 AC-3 has no tagged test in the tree). Fingerprint 378cf5a1364a821068f227f71a0aab5634289bd9, the clean tree's. `Success: no issues found in 53 source files` (52 without the file), `112 passed, 84 deselected in 17.84s`, `Evidence: PASS — 37 criteria tagged` (36 on the clean tree), `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0. Manifest `PASS fingerprint 378cf5a1364a uncommitted False`. show: `tier fast, PASS, commit 35f99c504c7f`, `Freshness: FRESH`, `AVE-REQ-096 (in-progress)`, `AC-3   passed   1 result(s): tests/unit/test_rates.py::test_no_source_gives_a_provisional_30`, exit 0.
With BROKEN: `112 passed, 84 deselected in 21.23s`, exit 0; the report holds 112 tests and no test_redteam_broken (control of finding 1: `1 failed`, exit 1).
```

Expected:

```text
A file Git ignores takes no part in a run whose evidence is tied to the tree: the run stops.
```

Fix:

```text
The check proposed for 097-D finding 1 runs over the collected test files; by that wording it does not reach this file, which is no collected test. One rule covers both and finding 8: scripts/verify.sh fails a step when `git ls-files -o -i --exclude-standard -- backend/src backend/tests scripts` lists a path outside `__pycache__/` (measured in the clone: empty on the clean tree; with the files planted it lists `backend/tests/unit/test-results/conftest.py` and `scripts/unittest.pyc`). Holding cases: scripts/tests/test-stop-hook.sh § "untracked and ignored files": an ignored file under the fixture's scripts/ fails verify.sh; backend/tests/unit/test_evidence_plugin.py: a pytester project with `git init`, `.gitignore` holding `test-results/` and this conftest.py stops the session.
```

Lead's disposition: fixed: the plugin refuses a test file or conftest.py that Git ignores, and verify.sh gained the step "No ignored file among sources, tests and scripts" over backend/src, backend/tests, scripts and .claude/hooks (bytecode directories and operating-system folder files exempt); tiers-suite cases plant a bytecode file beside the scripts, a conftest.py in an ignored test directory, a module in an ignored source directory and a file beside the hooks, each failing a run on a tree Git reports clean.

### Finding critic-097-3 (blocking) — PYTHONPATH and the backend environment set pytest options inside the interpreter, after verify.sh has started: clearing PYTEST_ADDOPTS in verify.sh leaves both open

Criterion: AVE-REQ-097 AC-4; AC-2 (configuration); extends 097-D finding 4 and its proposed fix

Reproduction:

```text
BROKEN (finding 1) appended to test_rates.py.
(a) /tmp/rt-site/sitecustomize.py: `import os` / `os.environ.setdefault("PYTEST_ADDOPTS", "--deselect tests/unit/test_rates.py::test_redteam_broken")`; `env -u PYTEST_ADDOPTS -u PYTEST_PLUGINS PYTHONPATH=/tmp/rt-site ./scripts/verify.sh`; `python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete`
(b) SP="$(uv run --frozen --quiet --directory backend python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"; one line in "$SP/zz_redteam.pth": `import os; os.environ.setdefault("PYTEST_ADDOPTS", "--deselect tests/unit/test_rates.py::test_redteam_broken")`; `env -u PYTEST_ADDOPTS -u PYTHONPATH` STEP; rm "$SP/zz_redteam.pth"; STEP again.
```

Observed:

```text
(a) `112 passed, 85 deselected in 22.63s`, `<== PASS: Backend unit tests (24s)`, `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0; show: `tier fast, PASS, commit 35f99c504c7f (with uncommitted changes)`, `Freshness: FRESH`, exit 0.
(b) site-packages `/state/venvs/2661032823/lib/python3.11/site-packages` (on Linux and in CI: backend/.venv, a path .gitignore lists); with no variable set by the caller `112 passed, 85 deselected in 22.10s`, exit 0: `uv run --frozen` kept the file. After removing it: `1 failed, 112 passed, 84 deselected in 23.12s`, exit 1.
```

Expected:

```text
(a) the step fails. (b) the run fails or shows the test it left out; the documents name the installed environment as an input outside the tree fingerprint.
```

Fix:

```text
scripts/verify.sh clears PYTHONPATH, PYTHONHOME and PYTHONSTARTUP beside PYTEST_ADDOPTS and PYTEST_PLUGINS (or starts its steps from an allow-list environment). For (b): the plugin records deselected tests and --forbid-skips fails on a deselection that the step's own `-m` expression does not explain; § Edge cases states that the installed environment lies outside the fingerprint and that CI's fresh environment is the certifying run. Holding cases: scripts/tests/test-verify-tiers.sh, a fixture step echoing `${PYTHONPATH-unset}` prints `unset` when the caller exports it; backend/tests/unit/test_evidence_plugin.py, `--forbid-skips --deselect <node>` exits non-zero.
```

Lead's disposition: fixed: verify.sh clears PYTHONPATH, PYTHONHOME, PYTHONSTARTUP and their relatives beside the pytest variables and sets PYTHONSAFEPATH; a --forbid-skips session treats --deselect and -k as usage errors, so an option injected inside the interpreter stops the session (two plugin cases). The Edge cases state that the files of the backend environment beyond package names and versions are local state, with the reviewer's clone and CI's fresh environment as the certifying runs.

### Finding critic-097-4 (blocking) — An edited fixture generator is not run when var/fixtures is warm: the media test passes on the old files

Criterion: AVE-REQ-097 AC-2 (stale evidence cannot certify changed code); a third cache in an ignored path beside the two of 097-E finding 6

Reproduction:

```text
var/fixtures filled by an earlier run of the media tests (17 entries). In backend/src/ave/fixtures/generate.py replace `        start = int(event * spec.sample_rate)` with `        start = int(event * spec.sample_rate) + spec.sample_rate // 50` (every chirp 20 ms late); delete every __pycache__.
T=tests/media/test_fixtures_media.py::test_chirps_match_the_manifest
flock -w 1500 "$AVE_HEAVY_LOCK" uv run --frozen --quiet --directory backend pytest -q "$T" -p no:cacheprovider --forbid-skips
AVE_VAR_DIR=/tmp/rt-var flock -w 1500 "$AVE_HEAVY_LOCK" <the same pytest command>   # empty cache
```

Observed:

```text
git status: ` M backend/src/ave/fixtures/generate.py`. Warm cache: `3 passed in 2.58s`, exit 0. Empty cache: `FAILED tests/media/test_fixtures_media.py::test_chirps_match_the_manifest[a]`, `[b]`, `[c]`, `3 failed in 29.09s`, exit 1. The cache key (generate.py:133-143) covers the specification, GENERATOR_VERSION (a constant, 1 since the file's only commit 24499a6) and the FFmpeg version. Not run: the whole media tier on the edited tree.
```

Expected:

```text
A media run of the edited tree runs the edited generator: the three cases fail, as CI's cold cache makes them fail.
```

Fix:

```text
backend/src/ave/fixtures/generate.py `cache_key` takes a SHA-256 over the generator sources (generate.py, barcode.py, standard.py) in place of the hand-kept constant; or the media step sets AVE_VAR_DIR to a directory of the run. The same warm cache misleads a reviewer's mutation run in a copy that carries var/ (the WF-004 case for media). Holding cases: a unit test that `FixtureSpec.cache_key()` changes when the generator source hash is patched; backend/tests/media/test_fixtures_media.py::test_fixtures_are_cached_by_specification gains "a changed generator source gives another directory".
```

Lead's disposition: fixed: FixtureSpec.cache_key holds generator_digest(), a SHA-256 over barcode.py, generate.py and standard.py; test_fixture_cache_key.py pins that the key changes with the digest and that the digest is the hash of those three files.

### Finding critic-097-5 (blocking) — `show AVE-REQ-NNN` accepts a manifest that names a requirement without a working file; the Edge case holds only for `show` without IDs

Criterion: AVE-REQ-097 AC-2, Edge case "A manifest that names a requirement without a working file → evidence.py show reports the unknown ID as an error"

Reproduction:

```text
Run directory var/probe/g: pytest-unit.json `{"schema": 1, "exitstatus": 0, "tests": [{"nodeid": "tests/unit/test_layout.py::test_canvas_defaults_and_presets", "outcome": "passed", "req": ["AVE-REQ-018 AC-1"], "scenario": [], "contract": false}, {"nodeid": "tests/unit/test_gone.py::test_x", "outcome": "passed", "req": ["AVE-REQ-999 AC-1"], "scenario": [], "contract": false}]}`; steps.tsv `Backend unit tests<TAB>PASS<TAB>1`.
python3 -B scripts/evidence.py record --dir var/probe/g --tier fast --fingerprint "$(. ./scripts/lib/verify-state.sh && vstate_fingerprint)"
python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh
python3 -B scripts/evidence.py show --require-fresh
```

Observed:

```text
record: `Evidence: PASS — 2 criteria tagged — var/probe/g/manifest.json`, exit 0 (a report tag naming no requirement file is accepted; only tooling tags are checked there). `show AVE-REQ-018 --require-fresh`: `Freshness: FRESH`, `AC-1   passed   1 result(s)`, exit 0, no word about AVE-REQ-999. `show --require-fresh`: `evidence.py: unknown requirement IDs: AVE-REQ-999 (no file in docs/requirements/)`, exit 2. scripts/tests/test_evidence.py:465 asserts the exit 0 of the named form; verify-requirement § 5 uses the named form. A small finding: the statement is false in the form the review uses.
```

Expected:

```text
What the Edge case states, in both forms; or the Edge case and the AC-2 line of § Verification strategy say "show without IDs".
```

Fix:

```text
scripts/evidence.py `cmd_show` checks every requirement ID of the manifest before it prints (and `record` runs tag_problems over the report tags); otherwise reword the two lines of the requirement. Holding case: test_show_reports_an_unknown_requirement_id_as_an_error, line 465 expects 2.
```

Lead's disposition: fixed: cmd_show checks every requirement ID of the manifest before it prints, in both forms; the unit test expects exit 2 without IDs, for the unknown ID and for a known ID.

### Finding critic-097-6 (boundary) — Nine one-line changes to scripts/evidence.py, scripts/verify.sh and run.sh survive every tooling suite and the fast tier: freshness by commit instead of by tree, and --require-complete without its criterion check, among them

Criterion: AVE-REQ-097 AC-2 and AC-4, § Verification strategy (AC-2: "manifest ties results to commit, fingerprint, configuration and suite results, stale evidence refused with --require-fresh"; test-stop-hook.sh "a real run leaves a manifest with the tree fingerprint"); verify-requirement § 8 "Fails without the behavior"

Reproduction:

```text
Each mutant in a copy inside the container: `git clone -q /workspace /tmp/mut/<name>`, one exact replacement (anchor counted once), `env -u AVE_EVIDENCE_DIR python3 -B scripts/evidence.py unittest`.
scripts/evidence.py: m1 `return 1 if args.require_complete and (incomplete or failed_run) else 0` → `… and failed_run else 0`; m2 `"PASS" if steps and all(…)` → `"PASS" if all(…)`; m3 `return max(found, …)` → `return min(found, …)`; m4 `"commit": _run(["git", "rev-parse", "HEAD"]),` → `"commit": "0" * 40,`; m5 configuration values `_sha256(path)` → `"same"`; m6 `"ffmpeg": _run([…]),` → `"ffmpeg": "same",`; m7 `"uncommitted_changes": status not in ("", "unavailable"),` → `False,`. scripts/tests/run.sh: m8 `if ! record_suite "$name" "$status" "$checks"; then` → `… && false; then`. Control c1: criterion_state `if any(not item["contract"] for item in items):` → `if items:`.
A = m1 to m8 in one copy; B = scripts/verify.sh `record_evidence "$before"` → `record_evidence "$(git rev-parse HEAD 2>/dev/null)"` plus evidence.py current_fingerprint script → `"git rev-parse HEAD"`; for each: the unit tests and `bash scripts/tests/run.sh`.
Then m1 to m7 and B applied in the clone itself: `./scripts/verify.sh`; `sed -i 's/if asset.id == reference_asset_id and/if asset.id != reference_asset_id and/' backend/src/ave/domain/rates.py`; `python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete`; `… show AVE-REQ-096 --require-fresh --require-complete`.
```

Observed:

```text
m1 to m8, each: `evidence.py unittest: PASS (1 file(s))`, exit 0. Control c1: exit 1 (`FAIL: test_criterion_states_follow_the_run_results`, `FAIL: test_done_requirements_need_passing_non_contract_evidence`).
A and B, each: unit tests exit 0; run.sh exit 0 with `CHECKER TOTAL: pass=200 fail=0`, `BASELINE TOTAL: pass=101 fail=0`, `STOP HOOK TOTAL: pass=72 fail=0`, `SESSION START TOTAL: pass=31 fail=0`, `VERIFY TIERS TOTAL: pass=23 fail=0`, `PROBE TOTAL: pass=28 fail=0`.
In the clone: `Ran 13 tests … OK`, `112 passed, 84 deselected`, `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0. After the uncommitted edit (` M backend/src/ave/domain/rates.py`): `tier fast, PASS, commit 000000000000`, `Freshness: FRESH — the tree is unchanged since this run`, exit 0. show AVE-REQ-096 --require-complete: AC-1 to AC-4 `missing`, exit 0. Manifest: fingerprint 35f99c50… (HEAD), `uncommitted_changes False`, toolchain ffmpeg `same`, configuration values `['same']`.
Causes read in the suites: test-stop-hook.sh:58 checks `len(d["fingerprint"])==40`; test_evidence.py mocks current_fingerprint, checks the commit by a 40-hex pattern and the configuration and toolchain by key presence, and holds no case of --require-complete with an unevidenced criterion, of a run without steps, or of two manifests.
```

Expected:

```text
Each behavior the Verification strategy names is held by a case that fails when the behavior is removed.
```

Fix:

```text
scripts/tests/test_evidence.py: show --require-complete exits 1 for a missing and for a contract-only criterion of a named requirement in a passing fresh run; record on a run directory without steps.tsv gives FAIL; latest_manifest over two tiers returns the later one; the manifest's commit equals `git rev-parse HEAD`, configuration["scripts/verify.sh"] equals the file's SHA-256, uncommitted_changes is true in a fixture repository with an edit; run.sh fails when a suite result cannot be written; one case of show --require-fresh on the real fingerprint (fixture repository: record, edit a tracked file without committing, expect exit 1). scripts/tests/test-stop-hook.sh:58 compares the manifest's fingerprint with `$(fp)`. Boundary: each path needs an edit to the gate's code; reported because § Verification strategy names these suites as the guard.
```

Lead's disposition: fixed: each of the nine changes now fails a named case — show --require-complete with a missing and with a contract-only criterion, a run without a step log recorded as failed, the newest recorded manifest shown when none is fresh, the commit, the configuration hashes and uncommitted changes of a fixture repository, the toolchain entry of the resolved media tool, run.sh failing when a suite result cannot be recorded, an uncommitted edit making the run stale through the real fingerprint, and the Stop-hook suite comparing the manifest's fingerprint with the fixture tree's. The lead's mutation check of this batch lists each mutant with the case that caught it.

### Finding critic-097-7 (boundary) — The fast tier's freedom from renders rests on the `media` marker alone: an unmarked test that runs FFmpeg passes the Stop gate's test step

Criterion: AVE-REQ-097 AC-3 (no repeated renders on every response); ARCHITECTURE § Verification pipeline item 4: "so no turn triggers media renders"

Reproduction:

```text
Shims /tmp/rt-shim/ffmpeg and /tmp/rt-shim/ffprobe: `#!/bin/sh`, one line appended to /tmp/rt-shim/calls.log, `exec /usr/bin/<tool> "$@"`. `PATH="/tmp/rt-shim:$PATH"` STEP (finding 1) on the clean tree.
Then backend/tests/unit/test_redteam_render.py without a marker: imports `Path`, `media_url`, `run_tool`; `def test_renders_without_the_media_marker(tmp_path: Path) -> None:` builds `arguments = ["-hide_banner", "-f", "lavfi", "-i", "testsrc2=size=640x360:rate=30:duration=2", "-c:v", "libx264", "-y"]`, calls `run_tool("ffmpeg", [*arguments, media_url(target)], timeout=120.0)` and asserts `target.stat().st_size > 0`. STEP with the shims; `uv run --frozen --quiet ruff format --check` and `ruff check` on the file.
```

Observed:

```text
Clean tree: `112 passed, 84 deselected in 33.75s`, `media tool calls: 0`. With the file: `113 passed, 84 deselected in 35.25s`, exit 0, `media tool calls: 1` (`ffmpeg -hide_banner -f lavfi -i testsrc2=size=640x360:rate=30:duration=2 -c:v libx264 -y file:/tmp/pytest-of-root/pytest-10/…`); `1 file already formatted`, `All checks passed!`. The Stop hook itself was not run on this tree; it runs this step.
```

Expected:

```text
A guard holds the claim, or the documents say that the marker is the guard and name the inspection that checks it.
```

Fix:

```text
scripts/verify.d/20-backend.sh: the fast pytest step runs with AVE_FFMPEG and AVE_FFPROBE pointing at a stub that exits 1 with "media tools belong to the media tier" (ave.proc.tool_path reads both variables; the fast tier makes no media tool call today), so an unmarked rendering test fails. Holding cases: scripts/tests/test-verify-tiers.sh, a fixture fast step sees the two variables and a media step does not; a unit test that run_tool("ffmpeg", …) raises under the fast step's environment.
```

Lead's disposition: fixed: the fast tier's pytest step sets AVE_FFMPEG and AVE_FFPROBE to scripts/lib/media-tier-only.sh, which exits 1; the tiers suite checks that the fast step sees the stand-in and the media step the real tools, and test_fast_tier_media_tools.py that a media tool call under the stand-in raises.

### Finding critic-097-8 (boundary) — A planted last-pass makes the Stop gate pass a failing tree without a run, replace the FAIL record of that same fingerprint with PASS, and session-start report the tree as verified

Criterion: AVE-REQ-097 AC-3 (Stop gate), AC-4 (test-stop-hook.sh: "a failing check blocks; it never passes as green"); .git/claude-verify appears in no diff or status

Reproduction:

```text
BROKEN (finding 1) appended to test_rates.py.
Control, on the Windows host: `printf '{"stop_hook_active": false}' | env -u CLAUDE_PROJECT_DIR -u VERIFY_TIER .claude/hooks/stop-verify.sh; echo $?`; `cat .git/claude-verify/last-result`
In the container: FP="$(. ./scripts/lib/verify-state.sh && vstate_fingerprint)"; rm -f .git/claude-verify/last.log; printf '%s\n' "$FP" > .git/claude-verify/last-pass; `printf '{"stop_hook_active": false}' | env -u CLAUDE_PROJECT_DIR .claude/hooks/stop-verify.sh; echo $?`; ls .git/claude-verify; cat last-result and attempts; `printf '{"hook_event_name": "SessionStart", "source": "startup"}' | .claude/hooks/session-start.sh`
```

Observed:

```text
Control: `hook exit=2`, `Stop blocked: ./scripts/verify.sh failed (gate attempt 1 of 3).`, `1 failed, 112 passed, 84 deselected`, last-result `FAIL 2026-10-06T04:28:01Z 1f295b0df245af98f1f8afcd49e2268aeffd0045`.
After the write: `hook exit=0`; the state directory holds `attempts last-pass last-result` and no last.log (verify.sh did not run); `last-result: PASS 2026-10-06T04:42:27Z 1f295b0df245af98f1f8afcd49e2268aeffd0045`; `attempts: 0`; session-start: `- Last verification: PASS 2026-10-06T04:42:27Z (matches the current tree)`.
```

Expected:

```text
A cache hit never overrules a recorded FAIL of the same fingerprint; the documents name the state directory as local, unauthenticated data.
```

Fix:

```text
.claude/hooks/stop-verify.sh: when last-result reads `FAIL … <fingerprint>` for the current fingerprint, skip the cache and run verify.sh (restore_pass_records stays for "a failed run on another tree"); § Edge cases gains a line that `.git/claude-verify` is local state and that the certifying runs are verify-requirement's and CI's. Holding case: scripts/tests/test-stop-hook.sh § "failing path": after "exit 2 on failure", writing `$(fp)` to last-pass still gives exit 2 and a new last.log. Boundary: the Stop gate credits no criterion and releases by design; reported because no named inspection sees this file and session-start then states PASS for the tree.
```

Lead's disposition: fixed: the Stop hook skips its cache when last-result records a failure for the current fingerprint and runs verify.sh; a Stop-hook suite case plants last-pass after a failing run and expects exit 2 with a new log. The Edge cases keep .git/claude-verify as local state.

### Finding critic-097-9 (boundary) — A sourceless .pyc beside the gate scripts, ignored by Git, is imported in place of a standard-library module: the unit-test step passes a failing tooling test and credits its tag

Criterion: AVE-REQ-097 AC-4; AC-2 (fingerprint); Edge case "a change to the gate itself → the diff shows it"; extends 097-E finding 6 and its proposed fix

Reproduction:

```text
scripts/tests/test_redteam_fail.py (untracked, visible): `import unittest`, `class Case(unittest.TestCase):`, `    # AVE-REQ-096 AC-3`, `    def test_fails(self) -> None:`, `        self.assertEqual(1, 2)`.
Control: `python3 -B scripts/evidence.py unittest --dir <dir> scripts/tests`
/tmp/rt-pyc/unittest.py: pops sys.path[0], deletes itself from sys.modules, imports the real unittest, restores the path, wraps `TestResult.addFailure` so that a failure whose test id contains "redteam" is dropped, and sets `sys.modules["unittest"]` to the real module.
python3 -c 'import py_compile; py_compile.compile("/tmp/rt-pyc/unittest.py", cfile="/workspace/scripts/unittest.pyc", doraise=True)'
git status --short; git check-ignore -v scripts/unittest.pyc; the fingerprint with and without the file
PYTHONPYCACHEPREFIX=/tmp/rt-pycache python3 -B scripts/evidence.py unittest --dir <dir> scripts/tests
```

Observed:

```text
Control: `failed: test_redteam_fail.Case.test_fails`, `evidence.py unittest: FAIL (1 of 2 file(s))`, exit 1.
With the file: git status lists only `?? scripts/tests/test_redteam_fail.py`; `.gitignore:24:*.pyc	scripts/unittest.pyc`; fingerprint a9fff431618c85e52f7614449c33e8ce11c7bb7b with and without it. `Ran 13 tests … OK`, `--- scripts/tests/test_redteam_fail.py`, `F`, `Ran 1 test`, `OK`, `evidence.py unittest: PASS (2 file(s))`, exit 0; suite result `{'file': 'scripts/tests/test_redteam_fail.py', 'exitstatus': 0, 'checks': 1, 'tags': [{'line': 7, 'tag': 'AVE-REQ-096 AC-3'}]}`. Neither `-B` nor PYTHONPYCACHEPREFIX keeps a .pyc beside the script from loading.
```

Expected:

```text
No ignored file beside the gate scripts is imported by a gate.
```

Fix:

```text
The ignored-file rule of finding 2, which lists scripts/unittest.pyc; and the gates' interpreters start with `-P` (`python3 -B -P scripts/evidence.py …`), which keeps the script's directory out of sys.path (evidence.py imports the standard library only). Holding case: scripts/tests/test_evidence.py, `_run_unit` on a copied evidence.py with a shadow .pyc beside it still reports the failing fixture. Boundary: the file acts as gate code; reported because the named inspection, the diff, cannot see it.
```

Lead's disposition: fixed: the ignored-file step lists a bytecode file beside the scripts, verify.sh sets PYTHONSAFEPATH for every step, and evidence.py restarts itself with -P when started without it (check_baseline.py already runs isolated); a unit test compiles a module named unittest beside a copy of evidence.py and expects the failing fixture to be reported.

### Finding critic-097-10 (boundary) — The record cited for the hook smoke test covers the SessionStart hook and CI; no document records a live Stop-hook run

Criterion: AVE-REQ-097 AC-3 ("Use supported hooks only after a small smoke test"); § Verification strategy AC-3: "hooks were smoke-tested before use (ASM-001, ASM-003)"

Reproduction:

```text
grep -n -A12 '^### ASM-001\|^### ASM-003' docs/ASSUMPTIONS.md
git grep -n -i 'stop hook\|stop gate\|stop-verify' -- docs/ASSUMPTIONS.md docs/WORKFLOW_LOG.md docs/PROGRESS.md docs/ENVIRONMENT_CAPABILITIES.md
Read-only, main checkout: cat .git/claude-verify/last-result
```

Observed:

```text
ASM-001 status: `confirmed — 2026-10-01 — the resumed session showed the "Project state" block injected by .claude/hooks/session-start.sh (source: resume)`; its Reason: `The bootstrap session created the hooks mid-session and could not exercise them.` ASM-003 status: `confirmed — 2026-10-01 — first CI run green on commit f605c6c`: CI, no hook. The git grep finds ASSUMPTIONS.md:46 (the assumption text), ENVIRONMENT_CAPABILITIES.md:100 (`SessionStart hook active …; the Stop gate runs the fast tier only`) and PROGRESS.md:89; none records a Stop hook that loaded, blocked a stop or released in a live session. The main checkout's state file reads `PASS 2026-10-06T03:23:21Z cfaf58aff77b…`, which only the Stop hook writes: the hook runs live; the record is what is missing.
```

Expected:

```text
The cited records show the smoke test of the Stop hook: loaded in a live session, a failing tree blocked the stop, the continuation carried stop_hook_active, the gate released at its limit.
```

Fix:

```text
docs/ASSUMPTIONS.md: extend ASM-001 (or add an assumption) with the date and the observation of a live Stop-gate pass, block and release on this host; the AC-3 line of the requirement cites it and drops ASM-003 from that sentence. No suite case: inspection.
```

Lead's disposition: fixed in the 097 batch: ASM-001 records the date and the observation of a live Stop-gate pass, block and release on this host, and the AC-3 strategy line cites it.

### Probes the gates rejected

```text
- Tag `AVE-REQ-018 AC-9` on a media-marked test, fast pytest step: `…has no such criterion`, `no tests ran in 3.70s`, exit 4 (tags of deselected tests are checked too).
- Media tests with ffmpeg and ffprobe hidden from every PATH directory (`-m media -x`): `MediaToolError`, `117 deselected, 1 error in 3.31s`, exit 1.
- Fast pytest step on the clean tree behind logging shims for ffmpeg and ffprobe: 112 passed, 0 media tool calls: the fast tier renders nothing today.
- Windows host entry with a failing unit test: `./scripts/verify.sh` from Git Bash exits 1 through dev-container.sh (`verify.sh: FAIL — tier fast (1 of 9 steps failed)`); `.claude/hooks/stop-verify.sh` on the host exits 2 with the log tail and records `FAIL … 1f295b0d…`.
- Fingerprint by Git for Windows on the host and by Git inside the container: equal on the clean tree (378cf5a1364a…) and on an edited tree (1f295b0df245…).
- Three fast-tier runs at once in one tree: exits 0 0 0, three run directories, each `PASS — tier fast (9 of 9 steps passed)`, latest-fast.json valid with 112 passed.
- Blunt shadow module scripts/unittest.pyc that drops every failure: the unit-test step fails, exit 1, through test_evidence.py's own subTest `[failing test]`, which runs evidence.py unittest as a child process (the targeted variant is finding 9).
- Control mutant (contract evidence counts as passing): test_evidence.py fails two tests, exit 1.
- `evidence.py show` without IDs on a manifest that names AVE-REQ-999: `unknown requirement IDs: AVE-REQ-999`, exit 2.
- CI, read-only through gh: tag v7 of actions/checkout exists; run 37399176405 at 5650249 with fetch-depth 1 shows `112 passed`, `84 passed … in 342.19s`, the four `### awk =` sections, `CHECKER TOTAL: pass=773 fail=0`, `<== PASS: Done requirements evidenced by this run`, `verify.sh: PASS — tier release (12 of 12 steps passed)`; the last 8 runs of verify.yml concluded success.
```

### Cleanup

```text
Clone restored before removal (`git status --short` empty, HEAD 35f99c5, no assume-unchanged or skip-worktree entry). Container ave-dev-3084842326-2661032823 stopped with `./scripts/dev-container.sh --stop` (state absent). .claude\worktrees\redteam-critic-ave-req-097 deleted; .claude/worktrees now lists ave-req-094-probe-evidence only, which I left alone. No commit, no push, no `git worktree prune`.

Deviation to know about: one heavy media run went without the heavy-media lock. For the hold probe "media tests without FFmpeg" my first PATH mirror left /bin/ffmpeg visible, so `pytest -m media -x` ran the whole media selection (`79 passed, 117 deselected in 330.70s`) outside `flock`. I rebuilt the mirror, confirmed that `command -v ffmpeg` failed, and repeated the probe (the held line reports the repeat). The fixture-cache probe of finding 4 ran under `flock "$AVE_HEAVY_LOCK"`.

Shared state volume: the .pth file of finding 3 was planted in /state/venvs/2661032823/lib/python3.11/site-packages and removed in the same command; the control afterwards failed again (`1 failed`) and a listing found no "redteam" entry. The environment directory /state/venvs/2661032823 itself stays on the volume, as dev-container.sh leaves it. Mutant copies and shims lived under the container's /tmp and went with the container.

Main checkout: read-only queries only (git status, git diff, grep, cat of .git/claude-verify/last-result, and gh api, gh run list and gh run view against GitHub). It is on ccr-af7078da-q8r8mf at f894bbf with uncommitted changes in 31 files and the untracked docs/briefs/handbacks/2026-10-03-m0-gates-red-team.part-2.md; none holds probe text (a grep for "redteam" under backend/tests, scripts and .claude/hooks found nothing), and none is my doing.
```
