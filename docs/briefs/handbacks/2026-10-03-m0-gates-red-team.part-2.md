# Handback — M0 gates red-team, part 2: lenses 097-D, 097-E and 097-F

Brief: [2026-10-03-m0-gates-red-team.md](../2026-10-03-m0-gates-red-team.md). Run `wf_98f469f7-ec5` at `35f99c5` ([script](../../workflows/m0-gates-red-team-wf_98f469f7-ec5.js)) for lenses 097-D and 097-E; lens 097-F ended there with a connection error and ran again as `wf_44376763-43f` ([script](../../workflows/m0-gates-red-team-lens-097-f-wf_44376763-43f.js)). Each finder worked read-only in a private clone; the reports below are theirs, unedited apart from local paths. The lead's disposition closes each section.

## Lens 097-D

### Scope, method and probes without a finding

```text
097-D — tiers and the suite runner (scripts/verify.sh, scripts/verify.d/*.sh, scripts/tests/run.sh and the six suites it lists), private clone at 35f99c5
```

### Baseline

```text
All three baseline commands passed in the clone at 35f99c5 (container image ave-dev:3084842326, Python 3.12.3, uv 0.8.17).
- `./scripts/verify.sh`: exit 0, `verify.sh: PASS — tier fast (9 of 9 steps passed)`; 112 passed, 84 deselected; 36 criteria tagged.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest`: exit 0, `Ran 13 tests`, `evidence.py unittest: PASS (1 file(s))`.
- `./scripts/dev-container.sh bash scripts/tests/run.sh`: exit 0, `scripts/tests/run.sh: PASS (6 suites)` (CHECKER 200, BASELINE 101, STOP HOOK 72, SESSION START 31, VERIFY TIERS 23, PROBE 28).

The release tier ran once, to confirm the second and third findings end to end: exit 0, 12 of 12 steps, 84 media and population tests in 558 s, 1597 s in total including the wait for the heavy-media lock.
```

### Finding 097-D-1 (blocking) — A test file in a directory name that .gitignore lists is collected and credited on a tree Git reports clean

Criterion: AVE-REQ-097 AC-2 (evidence tied to the tree fingerprint; stale or foreign evidence certifies nothing), AC-4

Reproduction:

```text
In the clone, inside `./scripts/dev-container.sh bash -s` (cwd = clone root):
mkdir -p backend/tests/unit/htmlcov
write backend/tests/unit/htmlcov/test_fab.py: module docstring, `from __future__ import annotations`, `import pytest`, `@pytest.mark.req("AVE-REQ-097 AC-1", "AVE-REQ-097 AC-3")`, `def test_fabricated() -> None: assert True`
git status --short
git check-ignore -v backend/tests/unit/htmlcov/test_fab.py
./scripts/verify.sh
python3 -B scripts/evidence.py show AVE-REQ-097 --tier fast --require-fresh --require-complete
```

Observed:

```text
git status: [] (empty); `.gitignore:30:htmlcov/  backend/tests/unit/htmlcov/test_fab.py`; `113 passed, 84 deselected`; `verify.sh: PASS — tier fast (9 of 9 steps passed)`; manifest `PASS uncommitted=False fp=378cf5a1364a` (the fingerprint of the clean tree, measured again after deleting the file); show: `commit 35f99c504c7f`, `Freshness: FRESH`, `AC-1 passed 1 result(s): tests/unit/htmlcov/test_fab.py::test_fabricated`, `AC-3 passed 1 result(s): tests/unit/htmlcov/test_fab.py::test_fabricated`, exit 0. In a fast-tier run without the file AC-1 and AC-3 read `missing`. mypy counted the file (53 source files), ruff skipped it.
```

Expected:

```text
Evidence comes only from files inside the fingerprinted tree: the run stops, or gives no evidence, for a test file Git ignores; `git status`, the manifest's `uncommitted_changes` and the `git grep --untracked` of verify-requirement § 4 all miss this file.
```

Fix:

```text
backend/tests/evidence_plugin.py, `pytest_collection_modifyitems`: one `git check-ignore --stdin` over the collected test files; a hit is a UsageError. Holding case: backend/tests/unit/test_evidence_plugin.py — a pytester project with `git init`, `.gitignore` holding `htmlcov/` and a tagged test under `htmlcov/` stops the session and writes no report entry.
```

Lead's disposition: fixed. The pytest plugin refuses a collected test file or a loaded conftest.py that Git ignores (usage error); case in `backend/tests/unit/test_evidence_plugin.py`.

### Finding 097-D-2 (blocking) — run.sh passes a suite whose own TOTAL line reports failed checks when the suite exits 0

Criterion: AVE-REQ-097 AC-4 (a caught failure returning success establishes nothing); AC-1 credited in the run; Edge cases: "the mechanical gate, which sees that checks ran and how they ended"

Reproduction:

```text
In the clone, inside the container:
sed -i 's|^  \*) printf .verify\.sh: unknown tier.*$|  *) TIER=fast ;;|' scripts/verify.sh   # the violated behavior: an unknown tier runs as fast
printf 'echo "test-verify-tiers.sh: finished"\n' >> scripts/tests/test-verify-tiers.sh   # one line after the suite's final `[ "$FAIL" -eq 0 ]`
RUN=/tmp/rt-run2/runs/20261006T000000Z-2; mkdir -p "$RUN"; AVE_EVIDENCE_DIR="$RUN" bash scripts/tests/run.sh
Control (disposable copy, same sed, suite unedited): bash scripts/tests/test-verify-tiers.sh
End to end (same two edits, PATH of the next finding): PATH="$NOAWK" ./scripts/verify.sh --tier release; python3 -B scripts/evidence.py show AVE-REQ-097 --tier release --require-fresh --require-complete
```

Observed:

```text
`  FAIL unknown tier exits 2`, `VERIFY TIERS TOTAL: pass=22 fail=1`, `test-verify-tiers.sh: finished`, `<== PASS: test-verify-tiers.sh (22 checks)`, `scripts/tests/run.sh: PASS (6 suites)`, exit 0; suite result `exitstatus 0, checks 22`; evidence.collect: `AVE-REQ-097 AC-1 passed [scripts/tests/test-verify-tiers.sh]`. Control: suite exit 1 (`pass=22 fail=1`). Release tier: `<== PASS: Verification tooling regression suites (125s)`, `verify.sh: PASS — tier release (12 of 12 steps passed)`; show: `Freshness: FRESH`, `AC-1 passed 1 result(s): scripts/tests/test-verify-tiers.sh`, AC-2, AC-3, AC-4 passed, exit 0.
```

Expected:

```text
`<== FAIL: test-verify-tiers.sh`, run.sh exit 1, the suite counted against AVE-REQ-097 AC-1.
```

Fix:

```text
scripts/tests/run.sh: read M from the same TOTAL line and fail the suite when M >= 1; `evidence.py record-suite` takes the failed count and credits only exit 0, N >= 1, M = 0. Holding case: scripts/tests/test_evidence.py `test_a_suite_that_run_sh_never_runs_gives_no_evidence` gets a stub `printf 'STUB TOTAL: pass=3 fail=1\n'; exit 0` that must end as `<== FAIL` with outcome failed.
```

Lead's disposition: fixed. `run.sh` reads both counts of the TOTAL line and fails a suite with a failed check; the suite result records the failed count and `evidence.py` credits only exit 0, N >= 1 and M = 0. Case: a stub suite printing `pass=3 fail=1` with exit 0.

### Finding 097-D-3 (blocking) — Skipped cases inside a listed suite credit their tags: test-checker.sh --all-awks passes with no awk implementation run

Criterion: AVE-REQ-097 AC-4 (skipped integration tests establish nothing); Edge cases line 1 ("A skipped … test → fails verification or gives no evidence")

Reproduction:

```text
In the clone, inside the container, no file edited: NOAWK = PATH in which every directory holding mawk, gawk, original-awk or busybox is replaced by a directory of symlinks to its other entries (function path_without of scripts/tests/test-verify-tiers.sh:35-54 called with those four names; `awk` stays).
RUN=/tmp/rt-run1/runs/20261006T000000Z-1; mkdir -p "$RUN"
PATH="$NOAWK" AVE_EVIDENCE_DIR="$RUN" bash scripts/tests/run.sh --all-awks
cat "$RUN/suite-test-checker.sh.json"
End to end: PATH="$NOAWK" ./scripts/verify.sh --tier release; python3 -B scripts/evidence.py show AVE-REQ-096 AVE-REQ-098 --tier release
```

Observed:

```text
`### awk = mawk: not installed, skipped` and the same line for gawk, original-awk and busybox; `CHECKER TOTAL: pass=9 fail=0` (200 with the system awk, 773 with all four); `<== PASS: test-checker.sh (9 checks)`; `scripts/tests/run.sh: PASS (6 suites)`, exit 0. Suite result: exitstatus 0, checks 9, tags at lines 191, 208, 219, 226, 249, 265, 274, all inside run_suite(), which never ran. evidence.collect: `AVE-REQ-096 AC-1 passed`, `AVE-REQ-096 AC-2 passed`, AVE-REQ-098 AC-2, AC-3 and AC-4 credited by test-checker.sh. Release tier: `verify.sh: PASS — tier release (12 of 12 steps passed)`; show: `AVE-REQ-096 AC-1 passed 1 result(s): scripts/tests/test-checker.sh`, `AC-2 passed 1 result(s): scripts/tests/test-checker.sh`. The suite holds the same silent skip for jq and node (lines 318, 326).
```

Expected:

```text
The suite fails, or its tags get no evidence, when the cases under them did not run.
```

Fix:

```text
scripts/tests/test-checker.sh: under --all-awks count the implementations that ran and add a failed check when none ran; count a missing jq or node as a failed check as well (CI and the container install them). Holding case: scripts/tests/test_evidence.py — run the real `test-checker.sh --all-awks` with the four names hidden from PATH and expect a non-zero exit (about 2 s).
```

Lead's disposition: fixed. `test-checker.sh --all-awks` adds a failed check when it ran no awk implementation and counts a missing `jq` or `node` as failed; case in `test-verify-tiers.sh` runs the real suite with the four awk names hidden.

### Finding 097-D-4 (blocking) — PYTEST_ADDOPTS from the caller's environment makes the backend test steps pass without running tests, or without the failing test

Criterion: AVE-REQ-097 AC-4; Edge cases "A failing step in any tier → that tier fails with exit 1" (AC-1, AC-4)

Reproduction:

```text
In the clone, inside the container:
(a) env PYTEST_ADDOPTS=--collect-only ./scripts/verify.sh
(b) printf '\n\ndef test_redteam_broken() -> None:\n    assert 1 + 1 == 3\n' >> backend/tests/unit/test_rates.py
control: uv run --frozen --quiet --directory backend pytest -q -m "not media and not slow" -p no:cacheprovider --forbid-skips
env PYTEST_ADDOPTS="--deselect tests/unit/test_rates.py::test_redteam_broken" ./scripts/verify.sh
python3 -B scripts/evidence.py show AVE-REQ-018 --tier fast --require-fresh --require-complete
```

Observed:

```text
(a) `112/196 tests collected (84 deselected) in 2.83s`, `<== PASS: Backend unit tests (5s)`, `verify.sh: PASS — tier fast (9 of 9 steps passed)`, manifest `PASS tests={} criteria=2`, show `Freshness: FRESH`. (b) control: `1 failed, 112 passed, 84 deselected`, exit 1; with the variable: `112 passed, 85 deselected`, `<== PASS: Backend unit tests (11s)`, `verify.sh: PASS — tier fast (9 of 9 steps passed)`, manifest `PASS tests={'passed': 112}`, show FRESH, every criterion passed, exit 0. `grep -n 'PYTEST_ADDOPTS|env -u|env -i|unset '` over verify.sh, verify.d, the hooks, dev-container.sh and run.sh finds nothing: no step clears its environment. On this Windows host dev-container.sh forwards only VERIFY_TIER, so the path is open where verify.sh runs natively (CI, Linux and cloud sessions).
```

Expected:

```text
The step fails: no test ran (a), a failing test was left out (b).
```

Fix:

```text
scripts/verify.sh unsets PYTEST_ADDOPTS and PYTEST_PLUGINS before its first step; the plugin's --forbid-skips also fails a session in which a collected test ended `not-run` or tests were removed by --deselect or -k. Holding cases: backend/tests/unit/test_evidence_plugin.py (--forbid-skips with --collect-only and with --deselect exits non-zero); scripts/tests/test-verify-tiers.sh (a fixture step echoing `${PYTEST_ADDOPTS-unset}` prints `unset` when the caller exports the variable).
```

Lead's disposition: fixed. `verify.sh` clears PYTEST_ADDOPTS and PYTEST_PLUGINS, the pytest steps pass `-c pyproject.toml`, and under `--forbid-skips` a selected test that never ran fails the session; a deselected test is recorded as not run. Cases in the plugin tests and in `test-verify-tiers.sh`.

### Finding 097-D-5 (blocking) — The manifest's commit, fingerprint and toolchain follow the caller's environment (GIT_DIR and GIT_WORK_TREE; AVE_FFMPEG)

Criterion: AVE-REQ-097 AC-2 (commit and tree fingerprint, configuration; stale evidence cannot certify changed code)

Reproduction:

```text
In the clone, inside the container:
git clone -q /workspace /tmp/rt-pristine
write backend/tests/unit/test_h.py (untracked): `@pytest.mark.req("AVE-REQ-097 AC-1")`, `def test_uncommitted() -> None: assert True`
GIT_DIR=/tmp/rt-pristine/.git GIT_WORK_TREE=/tmp/rt-pristine ./scripts/verify.sh
rm backend/tests/unit/test_h.py
python3 -B scripts/evidence.py show AVE-REQ-097 --tier fast --require-fresh
Toolchain: /tmp/rt-ff/ffmpeg = `#!/bin/sh` + `exec /usr/bin/ffmpeg "$@"`; AVE_FFMPEG=/tmp/rt-ff/ffmpeg uv run --frozen --quiet --directory backend python -B -c "from ave.proc import tool_path; print(tool_path('ffmpeg'))"; AVE_FFMPEG=/tmp/rt-ff/ffmpeg python3 -B -c '<load scripts/evidence.py; print toolchain()["ffmpeg"] and sorted(configuration())>'
```

Observed:

```text
`git status here: [?? backend/tests/unit/test_h.py]`, fingerprint of this tree 4ac87b5e1cd1; `113 passed`; `verify.sh: PASS — tier fast (9 of 9 steps passed)`; manifest `PASS commit 35f99c504c7f uncommitted=False fp=378cf5a1364a` (the other clone's clean tree) with AC-1 credited to `tests/unit/test_h.py::test_uncommitted`. After deleting the file: `Freshness: FRESH`, `AC-1 passed 1 result(s): tests/unit/test_h.py::test_uncommitted`, exit 0. Toolchain: `media code runs: /tmp/rt-ff/ffmpeg`; `manifest toolchain: ffmpeg version 6.1.1-3ubuntu5` (the PATH binary); configuration holds 8 file hashes and no environment entry. The media tier was not run with the override.
```

Expected:

```text
The manifest names the commit and fingerprint of the tree whose files were tested and the media tool the tests ran.
```

Fix:

```text
scripts/verify.sh unsets GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY, GIT_ALTERNATE_OBJECT_DIRECTORIES and GIT_COMMON_DIR before tree_state (or exits 2 when `git rev-parse --show-toplevel` differs from ROOT); `evidence.py toolchain()` records the binary that AVE_FFMPEG and AVE_FFPROBE resolve to. Holding cases: scripts/tests/test-verify-tiers.sh ("GIT_DIR and GIT_WORK_TREE of another repository: the manifest names this tree's fingerprint"); scripts/tests/test_evidence.py manifest case with AVE_FFMPEG pointing at a stub whose -version prints a marker.
```

Lead's disposition: fixed. `verify.sh`, `scripts/lib/verify-state.sh` and `evidence.py` clear the Git variables that redirect a command; the toolchain records the media tools the product resolves (AVE_FFMPEG, AVE_FFPROBE) and a digest of the installed backend packages. Cases: a foreign GIT_DIR in `test-verify-tiers.sh`, a stub ffmpeg in `test_evidence.py`.

### Finding 097-D-6 (blocking) — With TMPDIR inside the repository the suites run their Git commands on the enclosing repository: uncommitted work is committed and HEAD is detached at HEAD~1

Criterion: AVE-REQ-097 AC-1 (the release tier command); scripts/tests/run.sh:17 "Every suite builds its fixtures in a temp dir and leaves the working tree unchanged"; verify.sh rule "read-only toward the working tree"

Reproduction:

```text
Inside the container, in disposable copies of the clone (the run rewrites the repository it runs in):
git clone -q /workspace /tmp/rt-copyB; cd /tmp/rt-copyB
git config user.email dev@example.com; git config user.name Dev; git switch -q -c work
printf 'work in progress\n' > notes-wip.txt; printf '\nWIP line.\n' >> docs/ASSUMPTIONS.md
mkdir -p var/rt-tmp; TMPDIR="$PWD/var/rt-tmp" bash scripts/tests/run.sh
git reflog -5; git show --stat work; git status --short; ls notes-wip.txt
Scenario A: the same in /tmp/rt-copyA without identity, branch or changes.
```

Observed:

```text
Scenario B: run.sh exit 1 (`FAIL: test-checker.sh test-stop-hook.sh test-session-start.sh test-verify-tiers.sh`); reflog `35f99c5 HEAD@{0}: checkout: moving from work to HEAD~1`, `02090a3 HEAD@{1}: commit: baseline before output checks`; `git show --stat work`: `Dev: baseline before output checks`, `docs/ASSUMPTIONS.md | 2 ++`, `notes-wip.txt | 1 +`; afterwards detached HEAD, status empty, `ls: cannot access 'notes-wip.txt'`. Scenario A: HEAD 35f99c5 → 56e5864 (`checkout: moving from 35f99c5… to HEAD~1`), status empty. The same happened to the clone itself during the hold probe `TMPDIR="$PWD/var/rt-tmp" bash scripts/tests/test-session-start.sh`: `git status --short` stayed empty while HEAD had moved to 56e5864. Cause: make-fixture.sh refuses the directory, the suite continues, test-session-start.sh:58 and test-stop-hook.sh:90 create `$R` with mkdir -p, then test-stop-hook.sh:189 (`git add -A && git commit -qm "baseline before output checks"`) and test-session-start.sh:96 (`git checkout -q --detach HEAD~1`) run inside the enclosing work tree.
```

Expected:

```text
Exit 2 before any suite runs; HEAD, branch, index and working tree untouched.
```

Fix:

```text
Each suite stops when its fixture cannot be built (`"$W/make-fixture.sh" "$R" … || exit 2`) and exports GIT_CEILING_DIRECTORIES="$T"; scripts/tests/run.sh exits 2 when ${TMPDIR:-/tmp} resolves inside the repository. Holding case: scripts/tests/test_evidence.py — copy scripts/ into a scratch Git repository with two commits and an untracked file, run run.sh with TMPDIR inside it, assert exit 2 and unchanged `git rev-parse HEAD`, branch and `git status --porcelain`.
```

Lead's disposition: fixed. `run.sh` and the four suites that run Git commands stop with exit 2 when their temp dir lies inside a work tree, and the suites export GIT_CEILING_DIRECTORIES; `test-checker.sh` counts a fixture that could not be built as a failed case. Case in `test_evidence.py`: run.sh with TMPDIR inside a scratch repository leaves commit, branch and status unchanged.

### Finding 097-D-7 (blocking) — A never-collected tagged tooling unit test still credits its tag: tags count per file

Criterion: AVE-REQ-097 Edge cases line 1 ("never-collected test → fails verification or gives no evidence … this holds … for the tooling unit tests"); AC-4; AC-2 credited in the run

Reproduction:

```text
In the clone, inside the container:
sed -i 's/    if args.require_fresh and not fresh:/    if False and args.require_fresh and not fresh:/' scripts/evidence.py   # stale evidence is no longer refused
control: python3 -B scripts/evidence.py unittest --dir "$RUN" scripts/tests
python3: re.subn(r'(    # AVE-REQ-097 AC-2\n    def )test_', r'\1never_collected_test_', …) on scripts/tests/test_evidence.py   # 6 methods renamed, comment tags kept
python3 -B scripts/evidence.py unittest --dir "$RUN" scripts/tests; then evidence.collect("$RUN")
```

Observed:

```text
Control: `FAIL: test_stale_evidence_is_reported_and_refused_when_freshness_is_required`, `evidence.py unittest: FAIL (1 of 1 file(s))`, exit 1. After the rename: `Ran 7 tests`, `OK`, `evidence.py unittest: PASS (1 file(s))`, exit 0; `suite-test_evidence.py.json exit 0 checks 7 tags ['AVE-REQ-097 AC-2', 'AVE-REQ-097 AC-4']`; `AVE-REQ-097 AC-2 passed ['scripts/tests/test_evidence.py']`.
```

Expected:

```text
As the Edge case states: the uncollected tests give no evidence for AC-2, or the step fails.
```

Fix:

```text
scripts/evidence.py `run_unit_tests`: bind each comment tag to the `def test_…` that follows it and credit the tag only when that test ran and passed; a tag above no collected test fails the file. Otherwise reword the Edge case and docs/ARCHITECTURE.md § Testing strategy item 3 to say that tooling tags count per file and name the inspection. Holding case: scripts/tests/test_evidence.py NOT_PASSING_MODULES gets a module with a tagged, uncollected method.
```

Lead's disposition: fixed for unit-test files: each comment tag is bound to the `def test_…` below it, and a tag above no test that ran fails the file. Tags of a shell suite count per file (stated in § Edge cases).

### Finding 097-D-8 (blocking) — False failure: VERIFY_TIER exported by the caller reaches the tiers suite, so the documented `VERIFY_TIER=release ./scripts/verify.sh` cannot pass the release tier

Criterion: AVE-REQ-097 AC-1 (tiers behind documented commands; Verification strategy "--tier/VERIFY_TIER selection")

Reproduction:

```text
In the clone, inside the container:
VERIFY_TIER=release bash scripts/tests/test-verify-tiers.sh
Fixture (make-fixture.sh in /tmp, one step `release_step "show tier variable" sh -c 'echo "VERIFY_TIER seen by the step: ${VERIFY_TIER-unset}"'`): VERIFY_TIER=release ./scripts/verify.sh; ./scripts/verify.sh --tier release
```

Observed:

```text
Suite exit 1, `VERIFY TIERS TOTAL: pass=19 fail=4` (`FAIL default tier is fast`, `FAIL fast tier takes no lock …`, `FAIL without flock the fast tier still runs`, `FAIL fast tier still passes (the failing step is not in it)`). Fixture: `VERIFY_TIER seen by the step: release` against `unset` with --tier. scripts/dev-container.sh:112 forwards VERIFY_TIER into the container. The same suite passes 23 of 23 under `--tier release`. Not run: the release tier itself with VERIFY_TIER=release; the single release run went to the two suite-runner findings.
```

Expected:

```text
Both documented forms of selecting the release tier give the same result on the same tree.
```

Fix:

```text
scripts/verify.sh unsets VERIFY_TIER after reading it into TIER (or scripts/tests/test-verify-tiers.sh:18 unsets it beside AVE_HEAVY_LOCK_HELD). Holding case: test-verify-tiers.sh — a fixture step echoing `${VERIFY_TIER-unset}` prints `unset` under `VERIFY_TIER=release ./scripts/verify.sh`.
```

Lead's disposition: fixed. `verify.sh` reads VERIFY_TIER and unsets it before any step; `test-verify-tiers.sh` unsets it for its own runs.

### Finding 097-D-9 (boundary) — A step file in scripts/verify.d hidden by .git/info/exclude is sourced, turns a failed step into PASS and appears in no diff, status or fingerprint

Criterion: AVE-REQ-097 AC-4; Edge cases "A change to the gate itself … → the diff shows it" (the named inspection cannot see this one)

Reproduction:

```text
In the clone, inside the container:
printf 'scripts/verify.d/99-local.sh\n' >> .git/info/exclude
write scripts/verify.d/99-local.sh: `STEPS_FAILED=0; FAILED_STEPS=""` and `sed -i 's/\tFAIL\t/\tPASS\t/' "$AVE_EVIDENCE_DIR/steps.tsv"`
printf '\n\ndef test_redteam_broken() -> None:\n    assert 1 + 1 == 3\n' >> backend/tests/unit/test_rates.py
git status --short; ./scripts/verify.sh
python3 -B scripts/evidence.py show AVE-REQ-018 --tier fast --require-fresh --require-complete
```

Observed:

```text
`git status: [ M backend/tests/unit/test_rates.py]` only; `OK: 49 required files, …`; `<== FAIL: Backend unit tests (exit 1, 16s)`; `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0; manifest `PASS`, step `Backend unit tests=PASS`, `tests={'failed': 1, 'passed': 112}`; show `Freshness: FRESH`, exit 0. A global ignore file has the same effect as .git/info/exclude.
```

Expected:

```text
Only registered component files are sourced; an extra file in scripts/verify.d fails the "Project control files" step.
```

Fix:

```text
scripts/check-project-control.sh reports every scripts/verify.d entry outside REQUIRED_FILES; verify.sh sources the registered names instead of the glob. Holding case: scripts/tests/test-checker.sh `expect "unregistered step file fails" 1 … "printf '# x\n' > scripts/verify.d/99-local.sh"`, plus the same file listed in .git/info/exclude.
```

Lead's disposition: fixed. `verify.sh` sources the step files that `check-project-control.sh` lists as required files and nothing else; the checker fails on any other entry of `scripts/verify.d/`; cases in `test-checker.sh` and `test-verify-tiers.sh`. A tree with a file hidden by `.git/info/exclude` also has no fingerprint now.

### Finding 097-D-10 (boundary) — A tooling unit-test file that ends the interpreter with status 0 passes the "Evidence tooling unit tests" step with no file run

Criterion: AVE-REQ-097 AC-4; scripts/verify.d/15-evidence-tooling.sh header and Edge cases line 1 ("also fails a file without tests")

Reproduction:

```text
In the clone, inside the container:
printf '# AVE-REQ-097 AC-4\nimport os\n\nos._exit(0)\n' > scripts/tests/test_aaa.py
python3 -B scripts/evidence.py unittest --dir "$RUN" scripts/tests; ls "$RUN"
```

Observed:

```text
Output ends at `--- scripts/tests/test_aaa.py`; exit 0; no suite result at all: test_evidence.py, sorted after it, never ran. No tag is credited, so the criterion states stay honest; the step alone passes.
```

Expected:

```text
The step fails when a file produced no result.
```

Fix:

```text
scripts/evidence.py `run_unit_tests` runs each file in a child interpreter and fails a file that left no result. Holding case: NOT_PASSING_MODULES in scripts/tests/test_evidence.py gets "file that exits the interpreter".
```

Lead's disposition: fixed. Each unit-test file runs in a child interpreter; a file without a result fails.

### Finding 097-D-11 (boundary) — A generator test and a coroutine test pass under `evidence.py unittest` without running their bodies

Criterion: AVE-REQ-097 AC-4; docs/ARCHITECTURE.md § Testing strategy item 3 (the unit-test runner "applies the same rule" as --forbid-skips)

Reproduction:

```text
In the clone, inside the container: scripts/tests/test_vacuous.py with `# AVE-REQ-097 AC-1`, class Case(unittest.TestCase) holding `def test_generator(self): self.assertEqual(1, 2); yield` and `async def test_coroutine(self): self.assertEqual(1, 2)`
python3 -B scripts/evidence.py unittest --dir "$RUN" scripts/tests; then evidence.collect("$RUN")
```

Observed:

```text
`RuntimeWarning: coroutine 'Case.test_coroutine' was never awaited`, `Ran 2 tests in 0.014s`, `OK`, `evidence.py unittest: PASS (2 file(s))`, exit 0; `suite-test_vacuous.py.json exit 0 checks 2 tags ['AVE-REQ-097 AC-1']`; `AVE-REQ-097 AC-1 passed ['scripts/tests/test_vacuous.py']` (Python 3.12.3). The pytest side turns these warnings into errors (`filterwarnings = ["error"]`).
```

Expected:

```text
A test whose body did not run fails the file, as a skipped test does.
```

Fix:

```text
`run_unit_tests` runs with warnings as errors and fails a test method that returns a value. Holding case: NOT_PASSING_MODULES gets "generator test" and "coroutine test".
```

Lead's disposition: fixed. Unit-test files run with warnings as errors, so a generator or coroutine test fails.

### Finding 097-D-12 (boundary) — AVE_HEAVY_LOCK_HELD=1 inherited from the environment switches the heavy-media lock off: two media-tier runs overlap

Criterion: AVE-REQ-096 AC-4 (outside this brief's two requirements; lens item "heavy-media lock variables"); no AVE-REQ-097 criterion moves

Reproduction:

```text
Inside the container, fixture from scripts/tests/make-fixture.sh in /tmp with `media_step "media job" sh -c 'echo "$JOB start $(date +%s)" >> "$JOBLOG"; sleep 6; echo "$JOB end $(date +%s)" >> "$JOBLOG"'`, AVE_HEAVY_LOCK=/tmp/rt-fx/heavy.lock:
control: JOB=A ./scripts/verify.sh --tier media & sleep 2; JOB=B ./scripts/verify.sh --tier media
probe: the same with AVE_HEAVY_LOCK_HELD=1 on run A, whose caller holds nothing
```

Observed:

```text
Control: `A start …794; A end …800; B start …800; B end …806`, run B prints the waiting line once. Probe: `A start …806; B start …808; A end …812; B end …814`, no waiting line, both `verify.sh: PASS — tier media (5 of 5 steps passed)`. A run given another AVE_HEAVY_LOCK file overlaps the same way (by design). test-verify-tiers.sh covers only a caller that does hold the lock.
```

Expected:

```text
A run that is told the lock is held confirms it, or takes the lock.
```

Fix:

```text
scripts/verify.sh `hold_heavy_lock`: with an inherited AVE_HEAVY_LOCK_HELD=1, `flock -n "$HEAVY_LOCK" true` must fail, else the run exits 1 before any step. Holding case: test-verify-tiers.sh "AVE_HEAVY_LOCK_HELD=1 without a held lock fails before any step".
```

Lead's disposition: fixed (AVE-REQ-096 AC-4). A run told that the lock is held confirms it: with AVE_HEAVY_LOCK_HELD=1 and a free lock it fails before any step.

### Finding 097-D-13 (boundary) — CHECK_PATH exported by the caller replaces PATH for every checker case: --all-awks then runs one awk under four headings

Criterion: AVE-REQ-097 AC-1 (release tier: "tooling regression suites, every installed awk"); no criterion's own cases are lost

Reproduction:

```text
Inside the container: /tmp/rt-fake/mawk = `#!/bin/sh` + `exit 1`
control: PATH="/tmp/rt-fake:$PATH" bash scripts/tests/test-checker.sh --all-awks
probe: PATH="/tmp/rt-fake:$PATH" CHECK_PATH="/tmp/rt-fake:$PATH" bash scripts/tests/test-checker.sh --all-awks
```

Observed:

```text
Control: exit 1, `CHECKER TOTAL: pass=616 fail=157` (the broken mawk section fails). Probe: exit 0, `CHECKER TOTAL: pass=773 fail=0` with the headings `### awk = mawk`, `gawk`, `original-awk`, `busybox`: the shims are bypassed (scripts/tests/test-checker.sh:56 reads `${CHECK_PATH:-…}`, and the suite never initializes it).
```

Expected:

```text
The suite ignores a CHECK_PATH it did not set.
```

Fix:

```text
scripts/tests/test-checker.sh sets `CHECK_PATH=""` beside `SHIM=""` (line 20) and unsets FIXTURE_MODE. Holding case: under --all-awks each section first checks that `command -v awk` inside the checker's PATH equals "$SHIM/awk".
```

Lead's disposition: fixed. `test-checker.sh` initializes CHECK_PATH, unsets FIXTURE_MODE and checks in each awk section that the checker's PATH resolves awk to the shim.

### Probes the gates rejected

```text
- Unlisted tagged suite scripts/tests/test-extra.sh (TOTAL pass=1, exit 0): run.sh never ran it, no suite result, no evidence; all six scripts/tests/test-*.sh files are in run.sh's list.
- Listed suite without the executable bit: `<== FAIL: test-session-start.sh (exit 126)`, run.sh exit 1.
- Listed suite deleted: `<== FAIL: test-verify-tiers.sh (exit 127)` and `(result not recorded …)`, run.sh exit 1.
- Listed suite printing `TOTAL: pass=0 fail=0` and exiting 0: `<== FAIL … (no check ran …)`, tags counted as failed.
- Listed suite printing pass=99999999999999999999 and exiting 0: run.sh fails it as no-check (`[: integer expression expected`); its result file still records exit 0 with that count, which evidence.py alone reads as passed, so the step failure is what holds.
- Listed suite exiting 3 after a TOTAL line: `<== FAIL: test-probe-environment.sh (exit 3)`, tag failed.
- AVE_EVIDENCE_DIR naming a missing directory: every suite ends `<== FAIL … (result not recorded in /nonexistent/run)`.
- PYTEST_ADDOPTS='-k zzz_no_such_test': `196 deselected`, pytest exit 5, the step fails.
- git hidden from PATH: fast tier FAIL (1 of 9), but only through the unit test's commit assertion; the working-tree step itself printed `Skipped: no working-tree fingerprint` and reported PASS.
- Embedded repository (vendor/sub with its own .git): fast tier PASS with the working-tree step skipped as documented, manifest fingerprint empty, `show --require-fresh` exit 1 (STALE): the evidence certifies nothing.
- Untracked tooling unit test that writes report.txt into the tree: `<== FAIL: Working tree unchanged by verification`, `?? report.txt`, tier exit 1.
- Component step file replaced by a directory or by a dangling link: `ERROR: scripts/verify.d/90-tooling.sh: required file is missing`, tier FAIL.
- Component step file emptied to 0 bytes: control files OK and the tier passes without its steps; a gate edit that the diff shows (documented boundary).
- VERIFY_TIER=Release and VERIFY_TIER='release ': `verify.sh: unknown tier`, exit 2; empty VERIFY_TIER runs the fast tier.
- `--tier release --help` prints usage and exits 0 without running; a second --tier overrides the first; the hook and the CI workflow pass fixed arguments.
- AVE_HEAVY_LOCK=/nonexistent-dir/x.lock: `verify.sh: FAIL — cannot open the heavy-media lock`, exit 1, no step ran.
- Two media-tier runs in the default environment: the second prints the waiting line once and starts its step when the first ends.
- VERIFY_TIER=release inherited by test-stop-hook.sh: 72 of 72 pass, the hook still runs `--tier fast`.
- CLAUDE_VERIFY_GATE=off inherited by test-stop-hook.sh: suite exit 1 (`pass=28 fail=44`).
- FIXTURE_MODE exported empty: test-checker.sh exit 1 (`pass=132 fail=68`).
- TMPDIR inside the repository: the suites fail (`make-fixture.sh: refusing to build a fixture in …`, run.sh exit 1); the side effect is the sixth finding.
- Stub suite printing its TOTAL line on stderr only and exiting 0: `<== PASS: test-stop-hook.sh (2 checks)`; the fabricated TOTAL line that the Edge cases place outside the mechanical gate.
```

### Cleanup

```text
The clone's container is stopped (`--status`: state absent) and .claude/worktrees/redteam-097-d is removed; .claude/worktrees now lists ave-req-094-probe-evidence and redteam-097-f only. The main checkout saw only read-only Git queries; its HEAD moved from 5650249 to f894bbf through commits that are not mine. No commit, no push, no `git worktree prune`.

One deviation to know about: the hold probe with TMPDIR inside the repository moved the clone itself to HEAD~1 (56e5864) while `git status --short` stayed empty (sixth finding). I noticed five probes later and restored the clone with the setup command `git checkout -q 35f99c5` (status empty, fingerprint 378cf5a1364a). `git diff --stat 56e5864 35f99c5` over scripts, backend, .claude, .github, .devcontainer, the baseline package and docs/requirements is empty. The probes run in between were rerun at 35f99c5 and are reported from the reruns: exported CHECK_PATH, FIXTURE_MODE, the stubbed-suite holds, AVE_FFMPEG, and GIT_DIR/GIT_WORK_TREE.

The destructive reproductions ran in disposable copies under the container's /tmp (rt-copyA, rt-copyB, rt-copyC), which went away with the container.
```

## Lens 097-E

### Scope, method and probes without a finding

```text
097-E — evidence and the done gate: scripts/evidence.py (record, show, check-done, unittest, record-suite), manifests and latest-<tier>.json, the tree fingerprint and freshness, run directories, tags, inspection lines, contract-only evidence, done requirements with missing, stale or foreign evidence, and what the fast tier leaves to the Stop gate. Private clone at 35f99c5; 12 findings (9 blocking, 3 boundary), 22 held probes.
```

### Baseline

```text
In the clone at 35f99c5, before the first probe (2026-10-06): `./scripts/verify.sh` → `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0 (112 passed, 84 deselected; `Evidence: PASS — 36 criteria tagged`). `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest` → `Ran 13 tests … OK`, `evidence.py unittest: PASS (1 file(s))`, exit 0. `./scripts/dev-container.sh bash scripts/tests/run.sh` → `scripts/tests/run.sh: PASS (6 suites)`, exit 0 (checker 200, baseline 101, stop hook 72, session start 31, verify tiers 23, probe 28 checks). No requirement had status done. The release tier ran once, on the tree of finding 2: `verify.sh: PASS — tier release (12 of 12 steps passed)`, exit 0 (media step 84 passed in 458 s, tooling suites 247 s). Baseline logs: <session scratchpad>\baseline-fast.log, baseline-unittest.log, baseline-run.log.
```

### Finding 097-E-1 (blocking) — check-done skips a done requirement whose status is quoted or written twice

Criterion: AVE-REQ-097 AC-4 (done gate, scripts/verify.d/95-evidence.sh); AC-2 (evidence tied to requirement IDs)

Reproduction:

```text
All commands inside `./scripts/dev-container.sh bash -c '...'` in the clone.
Setup S (AVE-REQ-018 done as develop § 8 writes it; no test tags AC-3):
R=docs/requirements/AVE-REQ-018-configurable-canvas-dimensions-and-output-rate.md
sed -i -e 's/^status: in-progress$/status: done/' -e 's/^- \[ \] AC-/- [x] AC-/' -e 's/^_TBD: filled by the implementer.*/- `backend\/src\/ave\/domain\/rates.py` — canvas and rate (AC-1, AC-2, AC-3, AC-4)/' -e 's/^_TBD: filled by the lead.*/- verify-requirement: PASS — 2026-10-06 — no blocking findings/' "$R"
printf -- '- 2026-10-06 — done — verify-requirement PASS (lead)\n' >> "$R"
sed -i 's/^\(| \[AVE-REQ-018\]([^)]*) | \)in-progress |/\1done |/' docs/TRACEABILITY.md
sed -i -e '/^@pytest.mark.req("AVE-REQ-018 AC-3")$/d' -e 's/AVE-REQ-018 AC-3: //' backend/tests/unit/test_rates.py
mkdir -p var/probe/r && uv run --frozen --quiet --directory backend pytest -q -m "not media and not slow" -p no:cacheprovider --forbid-skips --evidence-report="$PWD/var/probe/r/pytest-unit.json"
Gates G: ./scripts/check-project-control.sh; python3 -B scripts/check_baseline.py; python3 -B scripts/evidence.py check-done --dir var/probe/r
Control: S, then G.
Variant a: S; sed -i 's/^status: done$/status: "done"/' "$R"; G (also run with 'done' in single quotes).
Variant b: S; sed -i -e 's/^status: done$/status: in-progress/' -e 's/^baseline: /status: done\nbaseline: /' "$R"; G (line 5 `status: in-progress`, line 14 `status: done`).
(S was run as these commands and through an equivalent helper script that writes fuller evidence lines; both gave the same results.)
```

Observed:

```text
Control: check-project-control.sh exit 0, check_baseline.py exit 0, check-done exit 1: `ERROR: AVE-REQ-018 AC-3: missing in this run` / `FAIL: 1 criteria of done requirements lack evidence in this run`.
Variants a and b: check-project-control.sh exit 0; check_baseline.py exit 0 with `by status: proposed 3, ready 84, in-progress 14, done 1, deferred 2`; check-done exit 0: `OK: every criterion of the 0 done requirements is evidenced by this run`.
```

Expected:

```text
check-done exit 1 naming AVE-REQ-018 AC-3, as in the control: both checkers treat the file as done (they unquote values and take the last key), so the done gate must too.
```

Fix:

```text
scripts/evidence.py:121-123 reads the first raw line that starts with `status:`. Read the status from the frontmatter block with the checkers' rules (unquote; raise EvidenceError on a repeated key), or make check_baseline.py and check-project-control.sh reject a quoted or repeated `status`. Suite case: scripts/tests/test_evidence.py::test_requirement_files_are_parsed_for_status_criteria_and_inspections with `status: "done"`, `status: 'done'` and two status keys, plus a parity case asserting that evidence.read_requirement and check_baseline.Working agree on status and criteria for every working file.
```

Lead's disposition: fixed with 093-A-1 (shared reader; the done gate fails on a file outside the canonical form).

### Finding 097-E-2 (blocking) — check-done does not see a criterion ticked with a capital X; the release tier passes end to end

Criterion: AVE-REQ-097 AC-4 (done gate)

Reproduction:

```text
Setup S of finding 1, then: sed -i 's/^- \[x\] AC-3 /- [X] AC-3 /' "$R"; gates G.
End to end on the same edits (written by the equivalent helper): ./scripts/verify.sh --tier release; then ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-018 --tier release --require-fresh --require-complete; git grep -n -w 'AVE-REQ-018 AC-3' -- ':!*.md'
```

Observed:

```text
G: check-project-control.sh exit 0; check_baseline.py exit 0 (`Acceptance criteria ticked: 4 of 404`, `done 1`); check-done exit 0: `OK: every criterion of the 1 done requirements is evidenced by this run`.
Release tier: `==> Done requirements evidenced by this run` / `OK: every criterion of the 1 done requirements is evidenced by this run` / `<== PASS`; `84 passed, 112 deselected in 458.27s`; `verify.sh: PASS — tier release (12 of 12 steps passed)`, exit 0.
show: `tier release, PASS`, `Freshness: FRESH`, `AVE-REQ-018 (done)` with lines for AC-1, AC-2 and AC-4 only, exit 0. git grep finds no test tagged AVE-REQ-018 AC-3.
```

Expected:

```text
The release tier fails at the done step with `AVE-REQ-018 AC-3: missing in this run`, as it does for `- [x] AC-3`.
```

Fix:

```text
scripts/evidence.py:83 `_AC_LINE` accepts `[ xX]` like check_baseline.py:67 and the awk checker (or both checkers reject `[X]`). Suite case: test_evidence.py::test_requirement_files_are_parsed_for_status_criteria_and_inspections with a `- [X] AC-2` line; test_done_requirements_need_passing_non_contract_evidence fed through read_requirement on such a file.
```

Lead's disposition: fixed with 093-A-1: a capital-X tick is outside the canonical form for both gates.

### Finding 097-E-3 (blocking) — A requirement file with a four-digit ID replaces the three-digit requirement inside evidence.py

Criterion: AVE-REQ-097 AC-4 (done gate); AC-2 (requirement IDs)

Reproduction:

```text
Setup S of finding 1, then add docs/requirements/AVE-REQ-0180-canvas-follow-up.md (written with printf '%s\n'): frontmatter `id: AVE-REQ-0180`, `title: Canvas follow-up`, `type: functional`, `status: proposed`, `priority: could`, `parent: AVE-FEAT-003`, `source: derived`, `scope: v1`, `primary_gate: M1`, `dependencies: []`; H1 `# AVE-REQ-0180 — Canvas follow-up`; the nine README headings; `- [ ] AC-1 First behavior.` to `- [ ] AC-4 Fourth behavior.`; the two _TBD evidence placeholders; Status line `- 2026-10-06 — proposed — discovered work (lead)`. Then gates G, and print evidence.requirements()['AVE-REQ-018'] (path, status).
```

Observed:

```text
Before the file: check-done exit 1 (`AVE-REQ-018 AC-3: missing in this run`). With the file: check-project-control.sh exit 0; check_baseline.py exit 0; check-done exit 0: `OK: every criterion of the 0 done requirements is evidenced by this run`. `evidence.py reads AVE-REQ-018 from: AVE-REQ-0180-canvas-follow-up.md | status: proposed`.
```

Expected:

```text
evidence.py keeps AVE-REQ-018 and AVE-REQ-0180 apart (check-done exit 1 for AVE-REQ-018 AC-3), or the checkers reject the four-digit name. A second file with the same three-digit ID is rejected by both checkers (held).
```

Fix:

```text
scripts/evidence.py:134 takes the ID as `path.name[:11]` while both checkers accept `AVE-REQ-\d{3,}`. Take it from `^(AVE-REQ-\d{3,})-`, raise EvidenceError when two files give one ID, and widen CRITERION_TAG, _TAG_IN_TEXT (lines 80, 82) and `tag[:11]` (line 490) to the same pattern. Suite case: test_evidence.py — requirements() over a temporary directory holding AVE-REQ-018-a.md (done) and AVE-REQ-0180-b.md (proposed) returns both IDs with their own status.
```

Lead's disposition: fixed. Requirement IDs come from the shared reader with any width; tags match `AVE-REQ-\d{3,}`; two files with one ID stop the tool.

### Finding 097-E-4 (blocking) — The tree fingerprint misses edits hidden by index flags and local exclude rules: evidence stays FRESH and the Stop gate reuses its pass

Criterion: AVE-REQ-097 AC-2 (stale evidence cannot certify changed code); AC-3 (Stop gate cache)

Reproduction:

```text
Inside the container, clean clone:
F=backend/src/ave/domain/rates.py; fp() { bash -c '. ./scripts/lib/verify-state.sh && vstate_fingerprint'; }
printf '{"stop_hook_active": false}' | .claude/hooks/stop-verify.sh   # runs the fast tier, records the pass
git update-index --assume-unchanged "$F"   # second run: --skip-worktree
sed -i 's/if asset.id == reference_asset_id and/if asset.id != reference_asset_id and/' "$F"
fp; git status --short
python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete; echo $?
printf '{"stop_hook_active": false}' | .claude/hooks/stop-verify.sh; echo $?
find backend scripts -name __pycache__ -type d -prune -exec rm -rf {} +; uv run --frozen --quiet --directory backend pytest -q tests/unit/test_rates.py -p no:cacheprovider
Third variant on a clean clone: echo 'scripts/tests/test_local_only.py' > .git/info/exclude; printf 'import unittest\n\n\nclass T(unittest.TestCase):\n    def test_a(self):\n        self.assertEqual(1, 2)\n' > scripts/tests/test_local_only.py; fp; git status --short; the same show command; python3 -B scripts/evidence.py unittest
```

Observed:

```text
Control (same edit, no flag): fingerprint 026b7106…, ` M backend/src/ave/domain/rates.py`, `Freshness: STALE`, exit 1.
--assume-unchanged and --skip-worktree: fingerprint 378cf5a1364a821068f227f71a0aab5634289bd9 (the clean tree), git status empty, `Evidence: var/verify/latest-fast.json — tier fast, PASS … / Freshness: FRESH — the tree is unchanged since this run`, exit 0; pytest `1 failed, 2 passed`. Stop gate (assume-unchanged): `exit=0 after 3s`, last-result still `PASS 2026-10-06T02:40:57Z 378cf5a1…` (no run; the run before the edit took 106 s).
.git/info/exclude: fingerprint equals the clean tree, git status empty, FRESH, exit 0, while `evidence.py unittest: FAIL (1 of 2 file(s))`; the same file without the exclude line changes the fingerprint and gives STALE.
During probing a skip-worktree flag that my restore helper had left set made a later control report FRESH on an edited tree with an empty git status; I repeated that control after clearing the flag.
```

Expected:

```text
`show --require-fresh` exits 1 and the Stop gate runs verify.sh whenever a file the steps read differs from the verified tree (Edge case: evidence recorded for an older tree is reported stale and refused).
```

Fix:

```text
scripts/lib/verify-state.sh vstate_fingerprint copies the real index (line 91) and runs `git add -A` (line 101), which honors assume-unchanged, skip-worktree, .git/info/exclude and core.excludesFile. Smallest change: return 1 (no fingerprint, as for a gitlink) when `git ls-files -v` lists a flagged entry (`^[a-zS]`) or when `git ls-files -o --exclude-per-directory=.gitignore` lists a file that `git ls-files -o --exclude-standard` omits. Suite cases: scripts/tests/test-stop-hook.sh § "tracked change invalidates" — an edit under each flag and an untracked file named in .git/info/exclude rerun verify; test_evidence.py::test_stale_evidence_is_reported_and_refused_when_freshness_is_required mocks current_fingerprint, so add one case on the real fingerprint.
```

Lead's disposition: fixed. A tree with a flagged index entry, a filter attribute or an ignore rule outside `.gitignore` has no fingerprint; five cases in `test-stop-hook.sh`.

### Finding 097-E-5 (blocking) — A step file rewritten with CRLF line endings loses its steps: the tier passes with 5 of 5 steps, the fingerprint is unchanged and git diff is empty

Criterion: AVE-REQ-097 AC-4 and AC-1 (a tier cannot pass without its checks; Edge case "a failing step in any tier fails that tier"); AC-2 (fingerprint); Edge case "a change to the gate itself → the diff shows it"

Reproduction:

```text
Inside the container, clean clone with a recorded Stop-gate pass:
sed -i 's/$/\r/' scripts/verify.d/20-backend.sh
bash -c '. ./scripts/lib/verify-state.sh && vstate_fingerprint'; git status --short; git diff | wc -l; git diff --stat
printf '{"stop_hook_active": false}' | .claude/hooks/stop-verify.sh; echo $?
./scripts/verify.sh; echo $?
python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete
```

Observed:

```text
`scripts/verify.d/20-backend.sh: Unicode text, UTF-8 text, with CRLF line terminators`; fingerprint 378cf5a1… (equal to the clean tree); git status ` M scripts/verify.d/20-backend.sh`; git diff 0 lines (`warning: in the working copy of 'scripts/verify.d/20-backend.sh', CRLF will be replaced by LF the next time Git touches it`). Stop gate `exit=0 after 2s` (cache hit, no run).
verify.sh exit 0: `./scripts/verify.d/20-backend.sh: line 11: $'\r': command not found`, `./scripts/verify.d/20-backend.sh: line 21: syntax error: unexpected end of file`, then `verify.sh: PASS — tier fast (5 of 5 steps passed)`: format check, lint, type check and unit tests never ran. show: `tier fast, PASS`, `Freshness: FRESH`, AC-1 to AC-4 `missing`, exit 1 with --require-complete.
```

Expected:

```text
A step file that cannot be loaded fails the tier (ARCHITECTURE § Verification pipeline 2: no component can go missing silently), and a tree whose bytes differ from the verified ones is not the verified tree (ADR-009: the container reads the checkout's bytes).
```

Fix:

```text
Two small changes. scripts/verify.sh:178: `. "./$step_file" || run_step "Load $step_file" false`, so a step file with a syntax error fails the run (root cause shared with lens 097-D). scripts/check-project-control.sh: fail when `git ls-files --eol` reports `w/crlf` or `w/mixed` for a text file (dev-container.sh checks MANIFEST.json only), since `* text=auto eol=lf` makes `git add` normalize the bytes the fingerprint hashes. Suite cases: scripts/tests/test-verify-tiers.sh § "a failing step fails the tier that runs it" — a step file with CRLF fails the tier; scripts/tests/test-checker.sh — a tracked shell script with CRLF fails the checker.
```

Lead's disposition: fixed. A step file that cannot be loaded fails the tier, and a working file with other line ends than its normalized blob adds its raw bytes to the fingerprint.

### Finding 097-E-6 (blocking) — A run passes on stale caches in ignored paths (bytecode, mypy) and is recorded PASS and FRESH for the edited tree

Criterion: AVE-REQ-097 AC-2 (evidence tied to the tree; stale evidence cannot certify changed code)

Reproduction:

```text
Inside the container, clean clone, every __pycache__ deleted:
F=backend/src/ave/domain/rates.py
uv run --frozen --quiet --directory backend pytest -q tests/unit/test_rates.py -p no:cacheprovider   # leaves backend/src/ave/domain/__pycache__/rates.cpython-311.pyc
cp -p "$F" /tmp/rates.before; sed -i 's/if asset.id == reference_asset_id and/if asset.id != reference_asset_id and/' "$F"; touch -r /tmp/rates.before "$F"   # same size, same modification time: the WF-004 case made deterministic
./scripts/verify.sh; python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete
find backend scripts -name __pycache__ -type d -prune -exec rm -rf {} +; uv run --frozen --quiet --directory backend pytest -q tests/unit/test_rates.py -p no:cacheprovider
Type check: clean clone; (cd backend && uv run --frozen --quiet mypy); cp -p "$F" /tmp/rates.before; sed -i 's/^PROVISIONAL_FPS = Fraction(30)$/PROVISIONAL_FPS: int = "abcde"/' "$F"; touch -r /tmp/rates.before "$F"; (cd backend && uv run --frozen --quiet mypy; uv run --frozen --quiet mypy --no-incremental)
```

Observed:

```text
Both files `size=3771 mtime=1791254470`; fingerprint changed to 026b7106…, git status ` M backend/src/ave/domain/rates.py`. verify.sh exit 0: `112 passed, 84 deselected in 17.40s`, `verify.sh: PASS — tier fast (9 of 9 steps passed)`. show: `tier fast, PASS, commit 35f99c504c7f (with uncommitted changes)`, `Freshness: FRESH`, AC-1 to AC-4 `passed`, exit 0. With the bytecode deleted: `1 failed, 2 passed`.
mypy as verify.d runs it: `Success: no issues found in 52 source files`; with --no-incremental: `Found 2 errors in 1 file (checked 52 source files)`.
(ruff's cache held: the same kind of edit was still reported.)
```

Expected:

```text
A run reads the sources of the tree it fingerprints: the unit-test step fails and the manifest of tree 026b7106… says FAIL.
```

Fix:

```text
scripts/verify.sh main: `export PYTHONPYCACHEPREFIX="$AVE_EVIDENCE_DIR/pycache"`, so no step reads bytecode from the tree; scripts/verify.d/20-backend.sh: `mypy --cache-dir="$AVE_EVIDENCE_DIR/mypy-cache"` (or --no-incremental). Suite case: scripts/tests/test-verify-tiers.sh — a fixture step imports a module beside a planted __pycache__ entry of equal size and time and must print the source's value.
```

Lead's disposition: fixed. A run keeps bytecode and the type checker's cache in a scratch directory outside the tree.

### Finding 097-E-7 (blocking) — An old run can be recorded again for the current tree, and a run directory prepared by the caller is reused

Criterion: AVE-REQ-097 AC-2 (Edge case: evidence recorded for an older tree is reported stale and refused); AC-4 for the reused run directory

Reproduction:

```text
Inside the container. RUN=var/verify/runs/20261006T021655Z-8 (the passing fast run of the clean tree); fp() { bash -c '. ./scripts/lib/verify-state.sh && vstate_fingerprint'; }
a) sed -i 's/if asset.id == reference_asset_id and/if asset.id != reference_asset_id and/' backend/src/ave/domain/rates.py; python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete (control); python3 -B scripts/evidence.py record --dir "$RUN" --tier fast --fingerprint "$(fp)"; the same show; then record --dir "$RUN" --tier release --fingerprint "$(fp)" and show --tier release.
b) with the original manifest back: sed -i "s/378cf5a1364a821068f227f71a0aab5634289bd9/$(fp)/" var/verify/latest-fast.json; show.
c) Setup S of finding 1 (AVE-REQ-018 done, AC-3 untagged); printf '{"schema": 1, "file": "scripts/tests/test-checker.sh", "exitstatus": 0, "checks": 200, "tags": [{"line": 1, "tag": "AVE-REQ-018 AC-3"}]}' > var/probe/planted.json; bash -c 'for i in 0 1 2 3 4; do d=var/verify/runs/$(date -u -d "+$i sec" +%Y%m%dT%H%M%SZ)-$$; mkdir -p "$d"; cp var/probe/planted.json "$d/suite-planted.json"; done; exec ./scripts/verify.sh'; python3 -B scripts/evidence.py check-done --dir <the run directory the manifest step printed>
```

Observed:

```text
a) control: `Freshness: STALE`, exit 1 (pytest tests/unit/test_rates.py: `1 failed, 2 passed`). After record (`Evidence: PASS — 36 criteria tagged — var/verify/runs/20261006T021655Z-8/manifest.json`, exit 0): `tier fast, PASS, commit 35f99c504c7f (with uncommitted changes), recorded 2026-10-06T02:38:10Z`, `Freshness: FRESH`, exit 0. As release: `var/verify/latest-release.json — tier release, PASS`, FRESH, exit 0 (the run held no release step).
b) STALE exit 1 before the edit of the file, FRESH exit 0 after it.
c) `verify.sh: PASS — tier fast (9 of 9 steps passed)`; the run directory holds `manifest.json pytest-unit.json steps.tsv suite-planted.json suite-test_evidence.py.json`; manifest `AVE-REQ-018 AC-3: [{'contract': False, 'outcome': 'passed', 'report': 'suite-planted.json', 'test': 'scripts/tests/test-checker.sh'}]`; check-done exit 0. An AVE_EVIDENCE_DIR preset by the caller is ignored (held).
```

Expected:

```text
A manifest names the fingerprint and tier of the run that produced its results, once; a run starts in a directory that did not exist. The remaining limit (a hand-edited file under the ignored var/verify) is stated in § Edge cases with the inspection that covers it.
```

Fix:

```text
scripts/verify.sh:171: create the parent with mkdir -p and the run directory with plain `mkdir`, failing when it exists, and write the tier and the fingerprint into it before the first step; scripts/evidence.py record: take both from that file instead of --tier/--fingerprint and raise EvidenceError when manifest.json already exists; add the Edge case "var/verify is local, unauthenticated data: the certifying run is the one the reviewer or CI starts". Suite cases: test_evidence.py::test_manifest_ties_results_to_commit_fingerprint_and_configuration — a second record of one run directory is refused; scripts/tests/test-verify-tiers.sh — an existing run directory fails the run.
```

Lead's disposition: fixed. A run directory is created anew (an existing one fails the run) and a run is recorded once. Hand-written files under `var/verify/` stay local, unauthenticated state (§ Edge cases, ASM-023).

### Finding 097-E-8 (blocking) — The fast tier, the only tier the skills and the Stop gate run, accepts a done requirement with contract-only and missing evidence

Criterion: AVE-REQ-097 AC-4 (provider mocks and missing tests cannot establish completed requirements); § Implementation evidence line on 95-evidence.sh; Definition of Done item 4

Reproduction:

```text
Setup S of finding 1 (AVE-REQ-018 done, AC-3 untagged), then sed -i 's/^@pytest.mark.req("AVE-REQ-018 AC-2")$/@pytest.mark.contract\n@pytest.mark.req("AVE-REQ-018 AC-2")/' backend/tests/unit/test_rates.py; ./scripts/verify.sh; python3 -B scripts/evidence.py check-done --dir "$(ls -d var/verify/runs/*/ | tail -1)"; python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh
Documents read: .claude/skills/develop/SKILL.md § 8 last item (`Run ./scripts/verify.sh; the checker validates the done invariants`), .claude/skills/verify-requirement/SKILL.md:60 (fast, or media), .claude/skills/milestone-review/SKILL.md:65 and :237 (`./scripts/verify.sh`; `CI PASS | FAIL | unknown`), .claude/hooks/stop-verify.sh:73.
```

Observed:

```text
`verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0. check-done on that run: `ERROR: AVE-REQ-018 AC-2: contract-only in this run`, `ERROR: AVE-REQ-018 AC-3: missing in this run`, `FAIL: 2 criteria of done requirements lack evidence in this run`, exit 1. show: `AVE-REQ-018 (done)`, `AC-2   contract-only`, `AC-3   missing`, exit 0.
check-done is a release_step only; no skill step runs `--tier release`, and stop-verify.sh:73 says the media and release tiers run at requirement verification and milestone reviews, which the skills do not do. Only CI runs it, and milestone-review accepts CI `unknown`.
```

Expected:

```text
A gate on the documented path to `done` fails for this tree: the fast tier judges done requirements as far as it can, or the skills run the release tier before the transition and at the milestone review.
```

Fix:

```text
Smallest: develop § 8 last item and milestone-review step 1 run `./scripts/verify.sh --tier release`; Definition of Done item 4 and stop-verify.sh:73 name that tier. Mechanical: run check-done in every tier with a per-tier rule — fail on `failed` and `contract-only`, and on `missing` when no collected test (deselected ones included) and no tooling file carries the tag; the plugin records deselected tagged tests for that. Suite cases: test_evidence.py::test_done_requirements_need_passing_non_contract_evidence gains the fast-tier rule; scripts/tests/test-verify-tiers.sh § "tier membership" asserts the done step runs in the fast tier.
```

Lead's disposition: fixed. The done step runs in every tier (failed, contract-only and missing evidence fail; the release tier also fails on a tagged test that did not run), and Definition of Done item 4, `develop`, `verify-requirement` and `milestone-review` name the release tier (WF-007).

### Finding 097-E-9 (blocking) — show --require-complete certifies from the newest manifest of any tier: a fast run hides a failed media run of the same tree and counts no deselected test

Criterion: AVE-REQ-097 AC-4 (skipped integration tests cannot establish completion; Edge case: a run with a failed step certifies no requirement complete); AC-2 (toolchain)

Reproduction:

```text
Inside the container, clean clone, FP=$(bash -c '. ./scripts/lib/verify-state.sh && vstate_fingerprint').
a) Two run directories built from the pytest-unit.json of the passing baseline fast run. A: that report, plus pytest-media.json `{"schema": 1, "exitstatus": 1, "tests": [{"nodeid": "tests/media/test_x.py::test_rendered_rate", "outcome": "failed", "req": ["AVE-REQ-018 AC-3"], "scenario": [], "contract": false}]}` and steps.tsv with `Backend unit tests PASS` and `Backend media and population tests FAIL`. B: the report and steps.tsv with `Backend unit tests PASS`. python3 -B scripts/evidence.py record --dir A --tier media --fingerprint "$FP"; sleep 2; record --dir B --tier fast --fingerprint "$FP"; show AVE-REQ-018 --require-fresh --require-complete; the same with --tier media.
b) After ./scripts/verify.sh on the clean tree: show AVE-REQ-018 --require-fresh --require-complete; git grep -h -o -E 'AVE-REQ-018 AC-[12]' -- backend/tests/media | sort | uniq -c
c) A manifest recorded for the current tree, then an ffmpeg printing `ffmpeg version 0.0-other` first on PATH: PATH=/tmp/fakebin:$PATH python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete
d) A copy of the manifest as var/verify/latest-media.json with `"recorded": "2099-01-01T00:00:00Z"`: show.
```

Observed:

```text
a) Without --tier: `var/verify/latest-fast.json — tier fast, PASS`, `Freshness: FRESH`, `AC-3   passed   2 result(s)`, exit 0. With --tier media: `tier media, FAIL`, `AC-3   failed   3 result(s)`, `Completeness: the run FAILED; a failed run certifies no requirement complete`, exit 1.
b) exit 0 with AC-1 to AC-4 `passed`, while that run reported `112 passed, 84 deselected` and backend/tests/media holds 3 tests tagged AVE-REQ-018 AC-1 and 2 tagged AC-2 that did not run.
c) manifest toolchain `ffmpeg version 6.1.1-3ubuntu5`; `Freshness: FRESH`, exit 0.
d) `Evidence: var/verify/latest-media.json — tier media … recorded 2099-01-01T00:00:00Z` is the one shown.
```

Expected:

```text
--require-complete exits 0 only for a run that executed every tagged test of the named requirement; a failed heavier run of the same tree stays visible after a fast run (the Stop gate starts one at every stop); a toolchain other than the recorded one is reported.
```

Fix:

```text
scripts/evidence.py latest_manifest (lines 449-460) picks by the manifest's own `recorded` text: with --require-complete require --tier, or prefer the heaviest fresh manifest and exit 1 when a fresh manifest of any tier says FAIL; the plugin records deselected tagged tests so a fast manifest shows them as not run and --require-complete exits 1; cmd_show compares manifest["toolchain"] with toolchain(). Suite cases: test_evidence.py::test_a_failed_run_never_certifies_a_requirement_complete — a failed media manifest plus a newer passing fast manifest; test_stale_evidence_is_reported_and_refused_when_freshness_is_required — a changed toolchain.
```

Lead's disposition: fixed. `show` takes the heaviest fresh manifest, `--require-complete` exits 1 for a failed fresh run of any tier and for a requirement with a tagged test that did not run, and freshness covers the toolchain. A hand-edited `recorded` field stays local state.

### Finding 097-E-10 (boundary) — Inspection lines are credited in any status, without the Verification strategy, and inside fenced blocks or HTML comments

Criterion: AVE-REQ-097 AC-4, Edge case "a criterion evidenced by an inspection line → credited only for a done requirement whose § Verification strategy justifies the inspection"

Reproduction:

````text
Setup S of finding 1, then one addition under § Test evidence of $R and gates G:
a) `- AC-3 → inspection: read the code — pass` (the Verification strategy of AVE-REQ-018 names no inspection);
b) that line inside a ```text fenced block;
c) that line between a `<!--` line and a `-->` line.
d) a) with frontmatter `status: verification`: printf 'Backend unit tests\tPASS\t1\n' > var/probe/r/steps.tsv; python3 -B scripts/evidence.py record --dir var/probe/r --tier fast --fingerprint "$(bash -c '. ./scripts/lib/verify-state.sh && vstate_fingerprint')"; python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete
````

Observed:

```text
a, b, c: check-project-control.sh exit 0; check_baseline.py exit 0; check-done exit 0: `OK: every criterion of the 1 done requirements is evidenced by this run`.
d: `AVE-REQ-018 (verification)`, `AC-3   inspected`, exit 0.
Held beside it: a failed tagged test beats the line; `->` instead of the arrow and a line under § Implementation evidence credit nothing.
```

Expected:

```text
What the Edge case states. Reported although inspection lines are a named limit, because the text claims two conditions the gate does not check, and because a line inside a code fence or an HTML comment is invisible in the rendered file and to both checkers, which skip fences.
```

Fix:

```text
scripts/evidence.py read_requirement (lines 129-133): skip fenced blocks and HTML comments in § Test evidence; credit `inspected` only when the status is done and the criterion's § Verification strategy line names inspection, or reword the Edge case to what the gate checks. Suite cases: test_evidence.py::test_requirement_files_are_parsed_for_status_criteria_and_inspections with the three placements; test_criterion_states_follow_the_run_results for the status rule.
```

Lead's disposition: fixed. An inspection line counts only for a criterion whose Verification strategy line names inspection; fenced lines are outside the section text the reader returns, and HTML comments are outside the canonical form.

### Finding 097-E-11 (boundary) — Contract-only depends on the marker alone: a provider test on a fake without it evidences a criterion

Criterion: AVE-REQ-097 AC-4, Edge case "a provider test that runs on a fake → never evidences a criterion alone"

Reproduction:

```text
Setup S of finding 1; add backend/tests/unit/test_fake_provider.py: `class FakeProvider` with `complete(self, prompt)` returning "ok", and `@pytest.mark.req("AVE-REQ-018 AC-3") def test_provider_answers() -> None: assert FakeProvider().complete("x") == "ok"` (no contract marker); rerun the pytest command of S; python3 -B scripts/evidence.py check-done --dir var/probe/r.
Contrast: no such file, the two AC-3 markers kept and `@pytest.mark.contract` put above each; same commands.
```

Observed:

```text
Unmarked fake: `113 passed, 84 deselected`; check-done exit 0: `OK: every criterion of the 1 done requirements is evidenced by this run`. Marked: `ERROR: AVE-REQ-018 AC-3: contract-only in this run`, exit 1. A tooling suite result always carries `contract: False` (evidence.py:303), so a shell or unittest case on a fake cannot be marked at all.
```

Expected:

```text
The Edge case and ARCHITECTURE § Testing strategy item 5 say what the gate reads (the marker) and name the inspection that judges whether a test replaces a provider.
```

Fix:

```text
Reword the Edge case to "a test marked contract …; whether a test on a fake carries the marker is judged by verify-requirement § 8", and add the marker to the "Real unit under test" item there. No suite case: inspection.
```

Lead's disposition: documented: the Edge case names the marker as what the gate reads and `verify-requirement` § 8 as the judge (ASM-021).

### Finding 097-E-12 (boundary) — Every step can write the run directory, and the unit-test step shares its process with the test files

Criterion: AVE-REQ-097 AC-4, Edge cases "a tooling suite or unit-test file that fails → counts against every criterion it tags" and "a skipped or never-collected test → fails verification or gives no evidence"

Reproduction:

```text
a) Setup S of finding 1; add backend/tests/unit/test_note.py whose single test writes Path(os.environ["AVE_EVIDENCE_DIR"]) / "suite-note.json" with schema 1, file "scripts/tests/test-checker.sh", exitstatus 0, checks 200 and the tag built as "AVE-REQ-" + "018 AC-" + "3"; AVE_EVIDENCE_DIR=$PWD/var/probe/r plus the pytest command of S; check-done --dir var/probe/r; git grep -n -w --untracked 'AVE-REQ-018 AC-3' -- ':!*.md'
b) Setup S; scripts/tests/test_aaa.py with one test: `sys.modules["__main__"]._unit_problems = lambda result: []`; scripts/tests/test_zzz.py: `# AVE-REQ-018 AC-3` and one test `self.assertEqual(1, 2)`; python3 -B scripts/evidence.py unittest --dir var/probe/r scripts/tests; check-done.
c) scripts/tests/test_aaa.py holding `import os` and `os._exit(0)`; python3 -B scripts/evidence.py unittest --dir <empty directory> scripts/tests; echo $?
```

Observed:

```text
a) `113 passed`; check-done exit 0: `OK: every criterion of the 1 done requirements is evidenced by this run`; git grep lists no tagged test.
b) `Ran 1 test … FAILED (failures=1)` for test_zzz.py, then `evidence.py unittest: PASS (3 file(s))`, exit 0; suite-test_zzz.py.json `{'exitstatus': 0, 'checks': 1}`; check-done exit 0.
c) the output ends at `--- scripts/tests/test_aaa.py`, exit 0, no suite result is written and test_evidence.py never runs: the "Evidence tooling unit tests" step would pass.
```

Expected:

```text
Results come from the runners only; a unit-test step that ended before every file reported fails. Fabricated results are a named limit (vacuous tests, a fabricated TOTAL line); reported because verify-requirement § 4 finds the tests of a criterion by `git grep` of the tag, which sees none of these files.
```

Fix:

```text
scripts/evidence.py collect(): accept a suite result only when its `file` is an existing tooling test under scripts/tests and its recorded tags equal comment_tags(file); run_unit_tests (lines 336-348): run each file in a child interpreter and fail a file that returns no result. Suite cases: test_evidence.py NOT_PASSING_MODULES gains "file that ends the interpreter" and "file that replaces the runner's judgement"; test_tooling_tags_count_only_through_a_suite_result_of_the_run gains a suite result for a file that did not run.
```

Lead's disposition: fixed for the paths a runner controls: a suite result must belong to a tooling test file of the tree, carry its file's name and tags, and unit-test files run in child interpreters. A test that writes result files itself is a vacuous test (§ Edge cases, inspection).

### Probes the gates rejected

```text
- Tracked edit of backend/src/ave/domain/rates.py: fingerprint changes, show --require-fresh prints STALE, exit 1.
- New untracked scripts/tests/test_local_only.py (not excluded): fingerprint changes, STALE, exit 1.
- Done requirement with `- [x] AC-3` and no tagged test: check-done `AVE-REQ-018 AC-3: missing in this run`, exit 1.
- The two AC-3 tests marked `contract`: check-done `contract-only in this run`, exit 1.
- A failed tagged test plus an inspection line for the same criterion: check-done `failed in this run`, exit 1.
- Tooling comment tag `# AVE-REQ-018 AC-9`: record and check-done exit 2 naming scripts/tests/test-probe-environment.sh:87.
- Malformed tooling comment tags (`AVE-REQ-18 AC-3`, `AVE-REQ-018 AC3`, two spaces, lower case, `AC-9x`): no credit and no error (record exit 0, 0 criteria tagged).
- AVE_EVIDENCE_DIR preset by the caller with a planted suite result: verify.sh used its own run directory and the planted file stayed unread.
- show AVE-REQ-999: exit 2; show --tier media without a media manifest: exit 2.
- record on a run directory without steps.tsv: result FAIL; show --require-complete exit 1.
- A pytest report with schema 2 in the run directory: check-done exit 2 (unsupported report schema).
- GIT_INDEX_FILE or GIT_DIR pointing at the index of the tree the manifest names, and GIT_WORK_TREE pointing elsewhere: STALE, exit 1.
- Indented criterion line `  - [x] AC-3`: check_baseline.py exit 1 (line that is no criterion; AC-3 missing).
- Fenced block holding `## note` inside § Acceptance criteria before AC-3: check_baseline.py exit 1.
- `status: Done`: both checkers exit 1 (invalid status).
- Second file AVE-REQ-018-zz-copy.md with the same three-digit ID: both checkers exit 1 (duplicate ID).
- Requirement file rewritten with CRLF line endings: check-done still reports AC-3 missing, exit 1.
- Inspection line with `->` instead of the arrow, or under § Implementation evidence: not credited, check-done exit 1.
- A `status: done` line in the body under frontmatter `status: verification`: evidence.py reads verification; the frontmatter decides.
- record-suite for a file that does not exist: exit 2; unittest on a directory without test files: exit 1.
- ruff with its cache on: a same-size edit with the modification time kept is still reported.
- Comment tags of the six shell suites and test_evidence.py, listed with comment_tags: each sits above a case of the criterion it names; none lies in fixture text.
```

### Cleanup

```text
Clone restored before removal (`git status --short` empty, no assume-unchanged or skip-worktree entry, HEAD 35f99c5). Container ave-dev-3084842326-360613191 stopped with `./scripts/dev-container.sh --stop` (state absent). .claude\worktrees\redteam-097-e deleted. Main checkout untouched: `git status --short` empty; its HEAD moved to 4413e4a during the run, which was not my doing. No commit, push or `git worktree prune`. Inside the private clone only, probes used `git checkout -- .`, `git update-index` flags, one `git add -A` followed by `git reset -q`, and edits of .git/info/exclude; helper scripts and probe output lived under the clone's ignored var/probe and went with the clone. One slip, corrected: my restore helper cleared only the assume-unchanged flag, so a skip-worktree flag stayed set for a few minutes and invalidated one control run; I cleared it, fixed the helper and repeated that batch (the results reported are from the repeat). The other finders' clones redteam-097-d and redteam-097-f and the worktree ave-req-094-probe-evidence were left alone.
```

## Lens 097-F

### Scope, method and probes without a finding

```text
097-F — the pytest plugin (backend/tests/evidence_plugin.py, conftest.py), the hooks (.claude/hooks/stop-verify.sh, scripts/lib/verify-state.sh, .claude/settings.json) and CI (.github/workflows/verify.yml). Measured at 35f99c5 in a private clone; the main checkout has since moved to f894bbf, where nothing below was re-run.
```

### Baseline

```text
All three briefed commands passed in the clone at 35f99c5 before the first probe. `./scripts/verify.sh`: 'verify.sh: PASS — tier fast (9 of 9 steps passed)', exit 0, 2 min 35 s (112 passed, 84 deselected; 36 criteria tagged). `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest`: 'Ran 13 tests ... OK', 'evidence.py unittest: PASS (1 file(s))', exit 0. `./scripts/dev-container.sh bash scripts/tests/run.sh`: 'scripts/tests/run.sh: PASS (6 suites)', exit 0, 4 min 41 s (test-checker.sh 200 checks, test-check-baseline.sh 101, test-stop-hook.sh 72, test-session-start.sh 31, test-verify-tiers.sh 23, test-probe-environment.sh 28). The release tier was not run in the clone: no requirement has status done, so check-done decides nothing there, and every finding rests on the fast tier, the unit-test step command or the hook. Fast-tier runs in total: the baseline, two end-to-end confirmations with PYTEST_ADDOPTS, and one through the real Stop hook. Observation outside the lens, from the first bytecode run: with PROVISIONAL_FPS changed from Fraction(30) to Fraction(31) in backend/src/ave/domain/rates.py and every cache deleted, the unit-test step stayed at '112 passed'; backend/tests/unit/test_rates.py:19 compares the result with the implementation's own constant (tag AVE-REQ-018 AC-3).
```

### Finding 097-F-1 (blocking) — Index flags and local ignore sources hide changed files from the tree fingerprint: the Stop gate skips a failing tree and stale evidence reads FRESH

Criterion: AVE-REQ-097 AC-2 (stale evidence cannot certify changed code); also the Stop gate of AC-3/AC-4

Reproduction:

```text
Real clone, after a passing Stop-gate run (last-pass and manifest fingerprint 378cf5a1364a821068f227f71a0aab5634289bd9):
  git update-index --skip-worktree backend/src/ave/domain/rates.py
  sed -i "s/RateResolution(PROVISIONAL_FPS, True, None/RateResolution(PROVISIONAL_FPS, 0==1, None/" backend/src/ave/domain/rates.py
  git status --short; git diff --stat; git ls-files -v | grep -E '^(S|[a-z])'
  (. ./scripts/lib/verify-state.sh && vstate_fingerprint)
  printf '{"session_id":"t","hook_event_name":"Stop","stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$PWD" .claude/hooks/stop-verify.sh; echo $?
  ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-018 --require-fresh --require-complete; echo $?
  ./scripts/dev-container.sh bash -c 'printf "{\"source\":\"resume\"}" | CLAUDE_PROJECT_DIR=/workspace .claude/hooks/session-start.sh'
  # control, the step command of scripts/verify.d/20-backend.sh on that tree:
  ./scripts/dev-container.sh bash -c 'uv run --frozen --quiet --directory backend pytest -q -m "not media and not slow" -p no:cacheprovider --forbid-skips --evidence-report=/workspace/var/rt/runs/v3-control/pytest-unit.json'
Fixture variants (in the container, repository built by scripts/tests/make-fixture.sh <dir> with-reqs, committed, one passing hook run first; the failing change is a broken Markdown link appended to docs/ARCHITECTURE.md or placed in a new docs/hidden-note.md), each followed by the hook with stop_hook_active false and by ./scripts/verify.sh:
  git update-index --assume-unchanged docs/ARCHITECTURE.md
  printf 'docs/hidden-note.md\n' >> .git/info/exclude
  printf 'docs/ARCHITECTURE.md filter=pin\n' >> .git/info/attributes; git config filter.pin.clean 'git cat-file blob HEAD:docs/ARCHITECTURE.md'
  git config --global core.excludesFile <file that lists hidden-note.md>
```

Observed:

```text
Real clone: git status --short and git diff --stat empty; flagged entry 'S backend/src/ave/domain/rates.py'; fingerprint 378cf5a1364a821068f227f71a0aab5634289bd9 (unchanged); hook exit=0 after 5s with last.log untouched (cache hit, no verify run); show printed 'Freshness: FRESH — the tree is unchanged since this run', AVE-REQ-018 AC-1 to AC-4 'passed' (AC-3 through tests/unit/test_rates.py::test_no_source_gives_a_provisional_30), show exit=0; session-start printed '- Last verification: PASS 2026-10-06T03:45:03Z (matches the current tree)'. Control on the same tree: 'FAILED tests/unit/test_rates.py::test_no_source_gives_a_provisional_30 ... 2 failed, 110 passed, 84 deselected', exit 1.
Fixture: skip-worktree, assume-unchanged, .git/info/exclude, .git/info/attributes with a clean filter, and core.excludesFile each gave 'exit=0  verify NOT run' with the fingerprint equal to the passing tree's (3e4a1ca4597e28484c80b92e2234e51624d88db7), while './scripts/verify.sh on that tree exits 1'. Controls in the same fixture: a visible broken link gave exit=2 'gate attempt 1 of 3'.
```

Expected:

```text
A changed tracked file, or a new file that verification reads, changes the fingerprint or leaves none: the Stop gate runs verify.sh and blocks, `show --require-fresh` reports STALE and exits 1, and the SessionStart block does not say the last pass matches the tree.
```

Fix:

```text
scripts/lib/verify-state.sh, vstate_fingerprint: return 1 (no fingerprint, the rule gitlinks already follow) when `git ls-files -v` lists an entry flagged S or lowercase, when .git/info/exclude or .git/info/attributes holds an active line, when core.excludesFile or core.attributesFile names a file with an active line, or when a filter.*.clean is configured for a path of the tree. Suite cases: scripts/tests/test-stop-hook.sh, one per source ('skip-worktree entry: no fingerprint, Stop runs verify.sh and blocks', likewise assume-unchanged, info/exclude, info/attributes filter, core.excludesFile); scripts/tests/test_evidence.py ('show --require-fresh exits 1 for a tree with a skip-worktree entry').
```

Lead's disposition: fixed with 097-E-4, filter attributes from `.git/info/attributes` and the user's excludes file included.

### Finding 097-F-2 (blocking) — A test module in a directory that .gitignore hides is collected, credits criteria and can rewrite outcomes, with git status, the fingerprint and git grep --untracked all blind to it

Criterion: AVE-REQ-097 AC-2 and AC-4

Reproduction:

```text
Clean clone (git status --short empty), no Git-state change:
  mkdir -p backend/tests/htmlcov
  cat > backend/tests/htmlcov/test_rt_hidden.py   # module docstring, `import pytest`, then
    @pytest.mark.req("AVE-REQ-075 AC-1")
    def test_rt_hidden_credit() -> None:
        assert sum([1, 2]) == 3
  git status --short; git check-ignore -v backend/tests/htmlcov/test_rt_hidden.py
  (. ./scripts/lib/verify-state.sh && vstate_fingerprint)
  git grep -n -w --untracked 'AVE-REQ-075 AC-1' -- ':!*.md'
  printf '{"session_id":"t","hook_event_name":"Stop","stop_hook_active":false}' | VERIFY_TIER=release CLAUDE_PROJECT_DIR="$PWD" .claude/hooks/stop-verify.sh; echo $?
  ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-075 --require-fresh; echo $?
Second run (unit-test step command of 20-backend.sh, in the container): the hidden module additionally replaces TestReport.from_item_and_call with a wrapper that sets every non-passed report to passed, and a visible backend/tests/unit/test_rt_probe.py holds test_rt_behaviour_holds and test_rt_behaviour_is_violated (assert sum([1, 2]) == 4), both tagged AVE-REQ-075 AC-2.
Third run: one test file in each of htmlcov, test-results, playwright-report, dist, node_modules, .venv, .pytest_cache, .ruff_cache, .mypy_cache, __pycache__ under backend/tests, then `uv run --frozen --quiet --directory backend pytest --collect-only -q -p no:cacheprovider`.
```

Observed:

```text
git status --short: empty; check-ignore: '.gitignore:30:htmlcov/	backend/tests/htmlcov/test_rt_hidden.py'; fingerprint 378cf5a1364a821068f227f71a0aab5634289bd9, equal to the clean clone's; git grep --untracked listed only backend/tests/media/test_at02_render.py. Hook exit=0 after 86s; log: '113 passed, 84 deselected', 'verify.sh: PASS — tier fast (9 of 9 steps passed)'. show: 'tier fast, PASS, commit 35f99c504c7f' (no uncommitted-changes note), 'Freshness: FRESH', 'AC-1   passed         1 result(s): tests/htmlcov/test_rt_hidden.py::test_rt_hidden_credit', exit 0 (AC-1 was 'missing' in the baseline run); manifest uncommitted_changes False.
Second run: '115 passed, 84 deselected', exit 0, report lists tests/unit/test_rt_probe.py::test_rt_behaviour_is_violated passed ['AVE-REQ-075 AC-2']; git status showed only the visible probe file and the fingerprint equalled the one without the hidden module (6cd467eeb67aec21d7a46c247daaf726aa2d799b).
Third run: htmlcov, test-results and playwright-report were collected (the latter two reported only the duplicate-basename import mismatch of my probe); dist, node_modules, the dot directories and __pycache__ were not.
```

Expected:

```text
Evidence comes only from test files inside the tree the fingerprint names; a collected test file that Git ignores stops the run.
```

Fix:

```text
backend/tests/evidence_plugin.py, EvidenceRecorder.pytest_collection_modifyitems: raise pytest.UsageError for every collected file under the repository root that is missing from `git ls-files --cached --others --exclude-standard -- backend/tests` (one Git call per session). Suite case in backend/tests/unit/test_evidence_plugin.py: 'a test file in a directory that .gitignore hides stops the session'.
```

Lead's disposition: fixed with 097-D-1.

### Finding 097-F-3 (blocking) — Pytest options from the environment or from a shadow configuration file change what the backend steps select and load; a failing tagged test is deselected, its criterion is credited, and the manifest records neither source

Criterion: AVE-REQ-097 AC-2 (configuration) and AC-4

Reproduction:

```text
End to end: backend/tests/unit/test_rt_probe.py (untracked) with test_rt_behaviour_holds (assert sum([1, 2]) == 3) and test_rt_behaviour_is_violated (assert sum([1, 2]) == 4), both @pytest.mark.req("AVE-REQ-075 AC-2"), then
  ./scripts/dev-container.sh bash -c 'PYTEST_ADDOPTS="--deselect tests/unit/test_rt_probe.py::test_rt_behaviour_is_violated" ./scripts/verify.sh'
  ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-075 --require-fresh
Unit-test step command of 20-backend.sh in the container, same probe file: no variable (control); PYTEST_ADDOPTS='-k "not violated"'; PYTEST_ADDOPTS=--ignore=tests/unit/test_rt_probe.py.
Shadow files, probe file reduced to one test tagged AVE-REQ-075 AC-4 that calls pytest.skip: backend/pytest.ini, then backend/.pytest.ini, each '[pytest]\naddopts = -p no:ave-evidence-recorder', then backend/pytest.toml with addopts = ["-p", "no:ave-evidence-recorder"]; the same option through PYTEST_ADDOPTS with a skipped and an xfail-marked tagged test.
Hidden shadow file, failing probe back in place: `printf 'backend/pytest.ini\n' >> .git/info/exclude` and backend/pytest.ini with testpaths = tests, the two markers and addopts = -ra --deselect tests/unit/test_rt_probe.py::test_rt_behaviour_is_violated.
```

Observed:

```text
End to end: '113 passed, 85 deselected', '<== PASS: Backend unit tests (13s)', 'verify.sh: PASS — tier fast (9 of 9 steps passed)'; show: 'Freshness: FRESH', 'AC-2   passed         1 result(s): tests/unit/test_rt_probe.py::test_rt_behaviour_holds', exit 0; manifest configuration keys are backend/pyproject.toml, backend/uv.lock, scripts/verify.sh and scripts/verify.d/*.sh only. Control without the variable: 'FAILED tests/unit/test_rt_probe.py::test_rt_behaviour_is_violated ... 1 failed, 113 passed, 84 deselected', exit 1.
-k: '113 passed, 85 deselected', exit 0. --ignore: '112 passed, 84 deselected', exit 0.
Each of pytest.ini, .pytest.ini and pytest.toml: '112 passed, 1 skipped, 84 deselected, 8 warnings', exit 0, no report file (the files replace [tool.pytest.ini_options], so --strict-markers and filterwarnings = error go too). Through PYTEST_ADDOPTS: '113 passed, 1 skipped, 84 deselected, 1 xfailed', exit 0, no report; control without it: exit 1.
Hidden shadow file: fingerprint 6cd467eeb67aec21d7a46c247daaf726aa2d799b with and without it, git status lists the probe test only, '113 passed, 85 deselected', exit 0, AC-2 passed.
Host note: scripts/dev-container.sh:112 forwards only VERIFY_TIER, so on this Windows host a host-level PYTEST_ADDOPTS does not reach the container; a Linux host, a cloud session, or a variable set inside the container reaches the step, and the configuration-file route works on every host.
```

Expected:

```text
The backend steps run the configuration of backend/pyproject.toml and the command line of 20-backend.sh and nothing else; the manifest names the options that were in effect.
```

Fix:

```text
scripts/verify.d/20-backend.sh: backend_uv runs `env -u PYTEST_ADDOPTS -u PYTEST_PLUGINS PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 uv run ...` and both pytest steps pass `-c pyproject.toml`. I ran that command with a shadow backend/pytest.ini and PYTEST_ADDOPTS='-k holds' both present: '1 failed, 113 passed, 84 deselected', exit 1, where the unchanged command gave '1 passed, 197 deselected', exit 0. The plugin writes the invocation arguments, the configuration file path and the deselected node IDs into the report, and evidence.py record stores them under configuration. Suite cases: backend/tests/unit/test_evidence_plugin.py ('the report records arguments, configuration file and deselected tests'); scripts/tests/test-verify-tiers.sh ('the backend steps run with PYTEST_ADDOPTS unset and -c pyproject.toml', the real 20-backend.sh sourced with a stub uv that prints its environment and arguments).
```

Lead's disposition: fixed with 097-D-4; the plugin records the invocation (arguments, configuration file) and the manifest keeps it under `pytest`; `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1` for every step.

### Finding 097-F-4 (blocking) — A pytest session that ends with status 0 without running its selected tests passes the step, and the evidence record accepts an empty or missing report

Criterion: AVE-REQ-097 AC-4 (no-op scripts; the requirement's title) and AC-1

Reproduction:

```text
End to end on a clean tree:
  ./scripts/dev-container.sh bash -c 'PYTEST_ADDOPTS=--collect-only ./scripts/verify.sh'
  ./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-012 AVE-REQ-097 --require-fresh
Unit-test step command of 20-backend.sh in the container:
  backend/tests/unit/test_a_rt_exit.py with `def test_rt_precondition() -> None: pytest.exit("precondition unavailable", returncode=0)` plus the failing tagged probe file of the previous finding;
  the same file with os._exit(0);
  PYTEST_ADDOPTS=--setup-plan, --setup-only, --markers.
```

Observed:

```text
End to end: '112/196 tests collected (84 deselected) in 2.86s', '<== PASS: Backend unit tests (4s)', 'Evidence: PASS — 2 criteria tagged', 'verify.sh: PASS — tier fast (9 of 9 steps passed)'; manifest result PASS with tests {}; show: FRESH, AVE-REQ-012 AC-1 to AC-4 'missing', exit 0.
pytest.exit: '84 deselected in 4.88s', '!!! _pytest.outcomes.Exit: precondition unavailable !!!', exit 0, report with exitstatus 0 and no test (114 selected tests, among them the failing one, never ran).
os._exit(0): exit 0, no report file.
--setup-plan and --setup-only: '84 deselected', exit 0, report without tests. --markers: exit 0, no report.
The recorder drops every item whose outcome stays 'not-run' (evidence_plugin.py:154), scripts/evidence.py collect() reads only the pytest-*.json files that exist and never reads their exitstatus.
```

Expected:

```text
The plugin's own rule ('a test that did not run proves nothing, so verification never lets one through as green') holds for a selected test that never started: the step fails, and a passed pytest step without a report with at least one test fails the Evidence manifest step.
```

Fix:

```text
backend/tests/evidence_plugin.py: under --forbid-skips, pytest_sessionfinish fails the session when a selected item still has the outcome not-run or when the session ran with --collect-only, --setup-only or --setup-plan; the module that declares the options raises pytest.UsageError when the name ave-evidence-recorder is blocked. scripts/evidence.py record: exit 1 when steps.tsv holds a passed backend test step whose pytest-*.json is missing, has exitstatus other than 0, or lists no test. Suite cases: backend/tests/unit/test_evidence_plugin.py ('pytest.exit(returncode=0) in a test fails a --forbid-skips session', '--collect-only fails a --forbid-skips session', 'a blocked recorder is a usage error'); scripts/tests/test_evidence.py ('record fails for a passed pytest step without a report', 'record fails for a report without tests').
```

Lead's disposition: fixed. A selected test that never ran fails a `--forbid-skips` session (`pytest.exit` with status 0, `--collect-only`, `--setup-plan`), blocking the recorder is a usage error, and each pytest step ends with `evidence.py check-report` (no report, no executed test or a non-zero session fails the step).

### Finding 097-F-5 (blocking) — Bytecode caches in the ignored __pycache__ directories decide the unit-test step: a broken source with unchanged size and modification time passes on stale bytecode

Criterion: AVE-REQ-097 AC-2 and AC-4

Reproduction:

```text
In the container, unit-test step command of 20-backend.sh, caches kept between runs as the real step keeps them:
  find backend -name __pycache__ -type d -prune -exec rm -rf {} +
  <step command>                                   # warm: writes backend/src/ave/domain/__pycache__/rates.cpython-311.pyc
  F=backend/src/ave/domain/rates.py; M="$(stat -c %Y "$F")"
  sed -i "s/RateResolution(PROVISIONAL_FPS, True, None/RateResolution(PROVISIONAL_FPS, 0==1, None/" "$F"; touch -d "@$M" "$F"
  <step command>                                   # broken source, stale cache
  find backend -name __pycache__ -type d -prune -exec rm -rf {} +
  <step command>                                   # broken source, no cache
```

Observed:

```text
After the edit: size 3771 (was 3771), mtime 1791256225 (was 1791256225); git diff shows the changed line. Broken source with the stale cache: '112 passed, 84 deselected', exit 0, tests/unit/test_rates.py::test_no_source_gives_a_provisional_30 recorded passed. After deleting the caches: 'FAILED tests/unit/test_rates.py::test_no_source_gives_a_provisional_30', '2 failed, 110 passed, 84 deselected', exit 1. The precondition is an edit that keeps both size and modification time (a restore that preserves times, or a deliberate touch); WF-004 covers this for manual mutation runs only, the steps themselves read the caches.
```

Expected:

```text
A verification run compiles the sources of the tree it fingerprints; results never come from bytecode of an older tree.
```

Fix:

```text
scripts/verify.sh: export PYTHONPYCACHEPREFIX="$AVE_EVIDENCE_DIR/pycache" before the steps (each run directory is new). I ran the test file with the stale cache present and PYTHONPYCACHEPREFIX set to a fresh directory: '2 failed, 1 passed', exit 1, where the default gave '3 passed', exit 0. Suite case: scripts/tests/test-verify-tiers.sh ('every step sees PYTHONPYCACHEPREFIX inside the run directory').
```

Lead's disposition: fixed with 097-E-6.

### Finding 097-F-6 (blocking) — An extraneous pytest plugin in the project environment loads by itself and rewrites outcomes; uv run --frozen leaves it in place and the manifest's toolchain does not cover installed packages

Criterion: AVE-REQ-097 AC-2 (toolchain and configuration) and AC-4

Reproduction:

```text
In the container, with the environment inside the clone's ignored var/ (the layout CI and Linux hosts have with backend/.venv):
  export UV_PROJECT_ENVIRONMENT=/workspace/var/rt/venv; uv sync --frozen --quiet --directory backend
  <unit-test step command of 20-backend.sh>, failing tagged probe file present     # control
  SP=$UV_PROJECT_ENVIRONMENT/lib/python3.11/site-packages
  $SP/rt_flaky_helper.py: a pytest_runtest_makereport hook wrapper that sets every non-passed report to passed
  $SP/rt_flaky_helper-0.0.1.dist-info/{METADATA, INSTALLER, RECORD, entry_points.txt with '[pytest11]\nrt_flaky_helper = rt_flaky_helper'}
  git status --short
  <unit-test step command>
  ls $SP | grep -c rt_flaky_helper; uv sync --frozen --quiet --directory backend; ls $SP | grep -c rt_flaky_helper
```

Observed:

```text
Control in the fresh environment: '1 failed, 113 passed, 84 deselected', exit 1. With the plugin: '114 passed, 84 deselected', exit 0, tests/unit/test_rt_probe.py::test_rt_behaviour_is_violated recorded passed ['AVE-REQ-075 AC-2']; git status lists the probe test only. Both entries were still present after the step's uv run --frozen and after a further uv sync --frozen. scripts/evidence.py toolchain() records the versions of python3, uv, ffmpeg and ffprobe, and configuration() the hash of uv.lock; neither reads the installed environment. This path needs write access to the environment, which lies outside every diff.
```

Expected:

```text
The backend steps load the evidence plugin and pytester and no plugin the lock file does not name; the manifest ties the results to the installed environment.
```

Fix:

```text
scripts/verify.d/20-backend.sh: PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 for both pytest steps (the unit suite ran unchanged with it in the sanity run of the configuration finding; conftest.py loads the two plugins it needs by name), and the recorder raises pytest.UsageError when config.pluginmanager.list_plugin_distinfo() names a distribution outside an allow-list that is empty today. scripts/evidence.py toolchain(): add a hash of `uv pip freeze` for the project environment. Suite cases: backend/tests/unit/test_evidence_plugin.py ('an entry-point plugin outside the allow-list stops the session'); scripts/tests/test_evidence.py ('the manifest toolchain holds the environment hash').
```

Lead's disposition: fixed: no pytest plugin loads by itself, and the manifest's toolchain carries a digest of the installed backend packages. A replaced package of the environment stays toolchain trust (ASM-023).

### Finding 097-F-7 (boundary) — The Stop gate takes its state records and its attempt limit as given: a written last-pass skips verification, a written attempts count or an out-of-range limit releases at once, and a large limit blocks without a practical bound

Criterion: AVE-REQ-097 AC-3

Reproduction:

```text
Fixture repository in the container (scripts/tests/make-fixture.sh <dir> with-reqs, committed, a broken Markdown link in docs/ARCHITECTURE.md as the failing change), hook called as scripts/tests/test-stop-hook.sh calls it:
  printf '%s\n' "$(. scripts/lib/verify-state.sh && vstate_fingerprint)" > .git/claude-verify/last-pass; hook with stop_hook_active false
  printf '99\n' > .git/claude-verify/attempts; hook with stop_hook_active true
  CLAUDE_VERIFY_MAX_ATTEMPTS=0, then =99999999999999999999, hook with stop_hook_active false
  CLAUDE_VERIFY_MAX_ATTEMPTS=1000000000, one fresh stop and four continued stops
  attempts file at 2, input '{"stop_hook_active":true,"nested":{"stop_hook_active":false}}'
  rm -rf .git/claude-verify; printf 'x\n' > .git/claude-verify; TMPDIR=/proc/rt-no-such-dir, hook with stop_hook_active false
```

Observed:

```text
Written last-pass: 'exit=0  verify NOT run' on the failing tree. attempts=99 with a continued stop: exit=0, '{"systemMessage": "Verification gate released after 100 consecutive failed attempts...', no block. MAX_ATTEMPTS=0 and the overflowing value: exit=0, 'released after 1 consecutive failed attempts' (the first failure releases). MAX_ATTEMPTS=1000000000: exit=2 five times, 'gate attempt 5 of 1000000000'. Nested key: the last occurrence wins, the count restarts ('gate attempt 1 of 3' from attempts=2). State path a file with an unusable TMPDIR: exit=0, '{"systemMessage": "Verification gate skipped: no writable state directory for the log."}', verify not run. No diff shows .git/claude-verify/ or the environment, so the inspection the Edge cases name cannot see these.
```

Expected:

```text
The documents state these limits, or the gate bounds them: a limit outside a small range falls back to the default, and the count restarts only on a top-level explicit false.
```

Fix:

```text
.claude/hooks/stop-verify.sh: max_attempts accepts 1 to 10 and uses the default 3 for every other value, an overflowing one included; json_bool takes the first top-level occurrence of the key. AVE-REQ-097 § Edge cases: one line that names .git/claude-verify/*, CLAUDE_VERIFY_GATE and CLAUDE_VERIFY_MAX_ATTEMPTS as inputs outside the mechanical gate. Suite cases in scripts/tests/test-stop-hook.sh: 'CLAUDE_VERIFY_MAX_ATTEMPTS=0 and an overflowing value fall back to 3', 'a limit above 10 falls back to 3', 'a nested stop_hook_active key does not restart the count'.
```

Lead's disposition: fixed: the attempt limit accepts 1 to 10 and the outermost `stop_hook_active` key decides. State records under `.git/claude-verify/` and the gate variables are named in § Edge cases as local state.

### Finding 097-F-8 (boundary) — The Edge-case list of gate files omits files that decide the gates: .claude/settings.json (check 12 accepts a settings file without the Stop gate or with a release run on every stop) and the pytest wiring (conftest.py files, pytest configuration)

Criterion: AVE-REQ-097 AC-3 and AC-4 (§ Edge cases, 'A change to the gate itself')

Reproduction:

```text
In the container, each mutation of .claude/settings.json followed by ./scripts/check-project-control.sh, then the file restored: delete hooks.Stop; add "disableAllHooks": true; add "env": {"CLAUDE_VERIFY_GATE": "off"}; set the Stop command to "true"; append a second Stop hook with the command "$CLAUDE_PROJECT_DIR"/scripts/verify.sh --tier release; add "env": {"CLAUDE_VERIFY_MAX_ATTEMPTS": "1"}.
Unit-test step command with backend/tests/unit/conftest.py holding `collect_ignore = ["test_rt_probe.py"]` and the failing tagged probe file present.
```

Observed:

```text
All six settings mutations: 'checker exit=0  OK: 49 required files, 6 executable scripts, ...'. Check 12 requires the SessionStart registration only (scripts/check-project-control.sh, 'no SessionStart hook runs ...'); nothing requires the Stop entry or rejects a Stop command that runs a heavier tier. conftest with collect_ignore: '112 passed, 84 deselected', exit 0, the failing file never collected and no evidence for its tag. The Edge-case line names scripts/verify.sh, scripts/verify.d/, scripts/evidence.py, scripts/tests/run.sh, backend/tests/evidence_plugin.py, the hooks and the CI workflow; it names neither .claude/settings.json, backend/tests/conftest.py and nested conftest.py files, the pytest configuration, scripts/lib/verify-state.sh nor scripts/dev-container.sh.
```

Expected:

```text
Every file that can switch a gate off is either checked mechanically or named in the Edge-case line that sends it to inspection.
```

Fix:

```text
Smallest: extend the Edge-case line with .claude/settings.json, every conftest.py under backend/tests, the pytest configuration in backend/pyproject.toml, scripts/lib/verify-state.sh, scripts/dev-container.sh and .devcontainer/Dockerfile. Mechanical alternative for the settings file, in check 12: exactly one Stop command and it is the stop-verify.sh hook, no disableAllHooks, no env key that starts with CLAUDE_VERIFY_; suite cases in scripts/tests/test-checker.sh, one per mutation above.
```

Lead's disposition: fixed: check 12 requires exactly one Stop command, the Stop gate, and rejects `disableAllHooks` and `CLAUDE_VERIFY_` settings; § Edge cases names every file that decides a gate.

### Finding 097-F-9 (boundary) — The contract rule rests on a marker the test author sets: a provider test on a fake without the marker evidences its criterion alone

Criterion: AVE-REQ-097 AC-4 (§ Edge cases, 'A provider test that runs on a fake → never evidences a criterion alone')

Reproduction:

```text
backend/tests/unit/test_rt_probe.py with a class FakeTranscriptionProvider and two tests that call it: test_rt_fake_provider_unmarked tagged AVE-REQ-075 AC-2, and test_rt_fake_provider_marked tagged AVE-REQ-075 AC-4 with @pytest.mark.contract. Unit-test step command of 20-backend.sh in the container, then in python3 -B with scripts/ on the path: evidence.collect(<run dir>) and evidence.criterion_state(...) for both tags.
```

Observed:

```text
'114 passed, 84 deselected', exit 0; 'AVE-REQ-075 AC-2 -> passed', 'AVE-REQ-075 AC-4 -> contract-only'. The Edge-case line states the rule without the condition; docs/ARCHITECTURE.md:246 states it for 'tests marked contract'. No provider test exists yet at this commit.
```

Expected:

```text
The Edge case states what the gate reads (the marker) and which inspection judges an unmarked test on a fake, or the flag follows from the fake itself.
```

Fix:

```text
Smallest: reword the Edge case to 'A provider test marked contract → never evidences a criterion alone; whether a test on a fake carries the marker is judged by verify-requirement § 8 (Real unit under test)'. Mechanical alternative once fakes exist: they are reached through one fixture, and the plugin sets the contract flag for every test that requests it; suite case in backend/tests/unit/test_evidence_plugin.py ('a test that requests the fake-provider fixture is recorded as contract').
```

Lead's disposition: documented with 097-E-11.

### Finding 097-F-10 (boundary) — The Verification strategy cites ASM-003 as hook smoke-test evidence; ASM-003 covers CI hosting, and ASM-001 records the SessionStart hook only

Criterion: AVE-REQ-097 AC-3 (§ Verification strategy, 'hooks were smoke-tested before use (ASM-001, ASM-003)')

Reproduction:

```text
sed -n '44,75p' docs/ASSUMPTIONS.md
git grep -n -i 'smoke' -- docs/PROGRESS.md docs/ASSUMPTIONS.md docs/WORKFLOW_LOG.md docs/decisions
cat <repository>/.git/claude-verify/last-result     # read-only look at the main checkout's Stop-gate record
```

Observed:

```text
ASM-001: 'confirmed — 2026-10-01 — the resumed session showed the "Project state" block injected by .claude/hooks/session-start.sh (source: resume)'. ASM-003: 'GitHub hosts the repository and runs CI ... confirmed — first CI run green on commit f605c6c'. The grep finds one line, about worktree isolation. No document records a live Stop-hook run (a block with exit 2, a release message). The main checkout's record reads 'PASS 2026-10-06T03:23:21Z cfaf58aff77b2e98bbfa0466f1c43a18e493b773', and only stop-verify.sh writes that file, so the hook does run in live sessions; the cited evidence does not say so.
```

Expected:

```text
The inspection part of AC-3 cites a record of the Stop hook's own smoke test.
```

Fix:

```text
docs/ASSUMPTIONS.md ASM-001: add the Stop hook's confirmation (date, what was observed: a blocked stop with the log tail, an allowed stop, the last-result record). AVE-REQ-097 § Verification strategy: cite ASM-001 for the hooks and keep ASM-003 for 'CI runs the release tier' under AC-1. No suite case; scripts/check-project-control.sh already resolves the links.
```

Lead's disposition: fixed: ASM-001 records the Stop hook's live record, and the Verification strategy cites ASM-001 for the hooks and ASM-003 for CI.

### Probes the gates rejected

```text
- Skips under --forbid-skips, one generated module per variant with the plugin options of the step, each exit 1 and recorded skipped: @pytest.mark.skip, skipif, pytest.skip in the body, in fixture setup and in fixture teardown, raise unittest.SkipTest, @unittest.skip on a method and on a class, self.skipTest, setUpClass raising SkipTest, class-level and module-level skip marks, setup_module skip, pytest.importorskip in the body, empty parametrize, pytest.param with a skip mark, module-level unittest.SkipTest (collector recorded skipped).
- Expected failures under --forbid-skips, each exit 1 and recorded xfailed or xpassed: xfail mark failing, passing (xpassed), strict, run=False, raises=, with a setup error, added through request.applymarker, pytest.param with an xfail mark, pytest.xfail() in the body, unittest.expectedFailure.
- Subtests (pytest 9.1.1): a skipped subtest, a skipped subtest after a passed one, an xfail in a subtest and a unittest subTest skip each gave exit 1 with the parent recorded skipped or xfailed; a failing subtest gave failed.
- Failures that pytest could swallow: an assertion in a thread, a test that returns a value, an async def test and sys.exit(0) in a test were recorded failed, exit 1; a teardown error was recorded error, exit 1.
- Collection errors: a yield test, a test class with __init__, an unknown marker (@pytest.mark.contracts) and pytest.exit(returncode=0) at module import each gave exit 2; a module with an import error under PYTEST_ADDOPTS=--continue-on-collection-errors gave exit 1.
- Tags: 'AVE-REQ-012 AC-99', req(tag=...) with a keyword, and a wrong tag on a media-marked test in the fast step each stopped the run with exit 4 before any test ran (the recorder validates before the -m deselection).
- A class with __test__ = False was not collected: exit 0 and no evidence, as the Edge case states ('gives no evidence').
- PYTEST_ADDOPTS values the step rejected: --lf (exit 4, the cache plugin is off), --noconftest (exit 4), -p no:tests.evidence_plugin (exit 4), --runxfail (the xfail-marked test failed, exit 1), -p no:skipping (collection error, exit 2), -x (exit 1).
- PYTHONOPTIMIZE=1: pytest stopped with PytestConfigWarning raised as an error, exit 1.
- Inner pytester sessions of test_evidence_plugin.py leave no entry in the outer report: the baseline manifest holds no test_generated.py result.
- Tier partition: 112 fast plus 84 media tests equal the 196 collected, locally and in the CI log.
- Stop gate tier: the real hook on the Windows host with VERIFY_TIER=release ran 'verify.sh: PASS — tier fast (9 of 9 steps passed)' in 86 s; the fixture run with a failing tree logged 'tier fast' as well.
- Stop gate controls in the fixture: a visible broken link blocked with exit 2 'gate attempt 1 of 3'; the repaired tree was a cache hit; after a release the next fresh stop blocked again at attempt 1.
- Stop gate input parsing: an escaped key inside last_assistant_message, a capital False and the string "false" each counted as a continued stop.
- Stop gate environment: CLAUDE_VERIFY_GATE=OFF (capitals) ran the gate; CLAUDE_VERIFY_MAX_ATTEMPTS=-1 and ' 5' fell back to 3; a state path that is a file with the default TMPDIR fell back to the temporary directory and blocked with exit 2.
- Host and container compute the same fingerprint for the clone (378cf5a1364a821068f227f71a0aab5634289bd9 from Git for Windows and in the manifest written inside the container).
- CI: the tag actions/checkout v7 exists (git ls-remote); run 37104671935 on 35f99c5 ended in success with 'verify.sh: PASS — tier release (12 of 12 steps passed)', 84 media tests and all six tooling suites; the workflow has no continue-on-error, no step condition and no environment block.
```

### Cleanup

```text
Clone restored before removal (git status --short empty, no flagged index entry, .git/info/exclude identical to its saved copy, HEAD 35f99c5). `./scripts/dev-container.sh --stop` ran in the clone: container ave-dev-3084842326-1737874068 went from running to absent. `rm -rf .claude/worktrees/redteam-097-f` ran from C:/dev/AI-Video-Editor: the clone is gone and the worktree ave-req-094-probe-evidence is still listed. No commit, no push, no `git worktree prune`. In the main checkout I ran the initial clone, one read of .git/claude-verify/ (last-result, attempts, a directory listing) and the final status check, and wrote nothing. Its `git status --short` is empty at f894bbf now, where the session-start snapshot showed modified files at 5650249; that change is not mine. Left behind by design of scripts/dev-container.sh: the clone's backend environment on the shared state volume (/state/venvs/1737874068), which I did not alter (the plugin probe used an environment inside the clone's var/ and went with the clone). Probe logs stay outside the repository in <session scratchpad>\rt097f.
```
