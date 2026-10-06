# Handback — M0 final review, second round, part 4: AVE-REQ-097

Report of the reviewer (and of the skeptic, when the reviewer returned PASS) for AVE-REQ-097 from workflow run `wf_b18a5f3e-54e` at `f996c17`, briefed in [the review brief](../2026-10-06-m0-final-review-2b.md). The lead filed the report as returned, with local paths shortened to repository paths.

## Review

Verdict: **FAIL** — AVE-REQ-097 — Verification gates that cannot pass as placeholders (reviewed at f996c170a4e75ad25b06f36babf8699843012c92, repository root the main checkout)

### AC-1 Keep a fast feedback tier, real-media integration tier, and full release tier behind documented repository commands. — PASS

```text
Release run in the private clone: `verify.sh: PASS — tier release (13 of 13 steps passed)`. scripts/tests/test-verify-tiers.sh (65 checks, 0 failed, in the release run and by hand): default tier fast, `--tier media`, `--tier=release`, VERIFY_TIER, usage errors exit 2, a step file that cannot be loaded or carries CRLF fails the tier, an unregistered step file is never sourced. scripts/tests/test-checker.sh check 2 cases (runner, suite, media stand-in, index mode; 1090 checks over four awk implementations). scripts/tests/test_evidence.py::EvidenceTests::test_the_suite_runner_stops_when_its_temp_dir_lies_inside_a_work_tree passed. Own runs: `./scripts/verify.sh --tier bogus` exit 2 `unknown tier: bogus`; `extra` gives `unexpected argument`. Mutants T1 (media steps in every tier), C1 (index mode 100644 accepted) and C4 (stand-in outside check 2) each fail a named case. Commands are documented in docs/ARCHITECTURE.md (Testing strategy, Verification pipeline item 2), CLAUDE.md § Verification and the usage text; .github/workflows/verify.yml runs `--tier release`.
```

### AC-2 Tie verification evidence to a commit/tree fingerprint, configuration, requirement IDs, and test results; stale evidence cannot certify changed code. — FAIL

```text
Verified: the release manifest names commit f996c170a4e7, fingerprint 51df3ab54aaa… (the same value under Git Bash on the host and in the container), the toolchain with the environment digest, the configuration hashes, 7 suite results and 58 criteria; `show AVE-REQ-097 --require-fresh --tier release` exits 0 with FRESH. First-round blocking 2 and 3 are closed by their reproductions (PYTHONUSERBASE and UV_ENV_FILE runs still FAIL; ident attribute and fsmonitor hook change the fingerprint) and by 14 own Git-state constructions. Not met: blocking finding 1 (a file a `.gitignore` file ignores outside the four listed directories replaces the product package or the tool configuration: a tree whose test fails is recorded `PASS`, `Freshness: FRESH`, against Edge case line 49) and blocking finding 2 (the linter cache lives in the tree and certifies an edited file, against Implementation evidence line 84).
```

### AC-3 Use supported hooks only after a small smoke test; avoid recursive Stop-hook loops and repeated full renders on every conversational response. — PASS

```text
scripts/tests/test-stop-hook.sh (145 checks, 0 failed, release run and by hand): fast tier under VERIFY_TIER=release, blocks 2, 2 and releases 0 without `stop_hook_active`, limit 1 to 10, outermost key, no cached pass over a recorded failure, counter read back. scripts/tests/test-verify-tiers.sh: the fast pytest step resolves ffmpeg and ffprobe to stand-ins through the two variables and on PATH. backend/tests/unit/test_fast_tier_media_tools.py (2 cases) passed. test-checker.sh check 12 cases passed. Own probe of first-round blocking 4: calls through `shutil.which`, by name, through a shell and through `/usr/bin/env` fail in the fast tier; an absolute path passes (stated limit). Mutants S1, S2, S4, S6, C2 each fail a named case. Inspection: .claude/settings.json registers one Stop command handler (timeout 1800) and SessionStart; ASM-001 records both hooks; the main checkout's `.git/claude-verify/last-result` (read only) reads `PASS 2026-10-06T13:07:31Z 23da9ece…` beside a log of the 11 fast-tier steps, so the Stop gate runs live with the fast tier only.
```

### AC-4 No-op scripts, skipped integration tests, caught exceptions returning success, or provider mocks cannot establish completed product requirements. — FAIL

```text
Verified: first-round blocking 1 is closed (`show AVE-REQ-097 --require-fresh --require-complete --tier release` exits 0; with the requirement marked done in a scratch copy `check-done --tier release` on a copy of the real release run prints `OK: every criterion of the 1 done requirements …`; without one suite result 3 errors, exit 1; a tag in run.sh again: exit 2 with `scripts/tests/run.sh:20`). Own probes: the real runner fails a suite that is `exit 0`, a suite with `pass=0`, a suite with `fail=1` and exit 0; a `skipif` media test fails the session under the media step's options and `check-report` exits 1. 21 plugin cases and 37 unit cases passed. Not met: blocking finding 1 (tests that run against a stand-in for the product package, and format, lint and type steps that read a hidden configuration, establish a PASS) and blocking finding 2 (format and lint steps that pass from a cached result without reading the edited file). Inspection items: no test on a provider fake exists at this commit; no inspection line exists in a working requirement file; section 8 is under Test quality.
```

### Verification runs

```text
- Private clone .claude/worktrees/verify-ave-req-097 at f996c170a4e75ad25b06f36babf8699843012c92 (`git rev-parse HEAD` printed exactly that hash); `git status --porcelain` empty before and after every evidence run; container stopped (`--status`: absent) and clone removed at the end; main checkout `git status --porcelain` empty; no commit, no push.
- `./scripts/verify.sh --tier release` -> exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`; `Ran 37 tests`; `125 passed, 84 deselected in 14.39s`; `84 passed, 125 deselected in 426.41s`; CHECKER TOTAL pass=1090 fail=0, BASELINE 305/0, STOP HOOK 145/0, SESSION START 56/0, VERIFY TIERS 65/0, PROBE 155/0; `OK: every criterion of the 0 done requirements …`; manifest var/verify/runs/20261006T131850Z-8.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --tier release` -> exit 0: `tier release, PASS, commit f996c170a4e7`, `Freshness: FRESH`, AC-1 passed (3 results), AC-2 passed (26), AC-3 passed (5), AC-4 passed (25); the same with `--require-complete` -> exit 0. Manifest: tests `passed: 209, deselected: 209`, no other outcome.
- By hand in the clone: `python3 -B scripts/evidence.py unittest scripts/tests` -> `Ran 37 tests`, `evidence.py unittest: PASS (1 file(s))`; pytest with `--forbid-skips` on test_evidence_plugin.py, test_fast_tier_media_tools.py, test_fixture_cache_key.py -> 25 PASSED (21 + 2 + 2); `bash scripts/tests/test-verify-tiers.sh` -> 65/0; `test-stop-hook.sh` -> 145/0; `test-checker.sh` -> `CHECKER TOTAL: pass=278 fail=0`.
- Environment of the clone's runs: /state/venvs/1669714700, created 2026-10-03 by an earlier clone of the same path. Its 19 distributions equal those of an environment built today from uv.lock; 4678 installed files match the hashes of their RECORD files; the only path files are `_virtualenv.pth` and `ave.pth` (/workspace/backend/src).
- First-round blocking findings repeated in scratch copies under the container's /tmp, each with its own environment. Blocking 2a (usercustomize with `os._exit(0)` under PYTHONUSERBASE, failing scripts/tests/test_zz_fail.py): control and run with the variable both `<== FAIL: Evidence tooling unit tests`, exit 1. Blocking 2b (UV_ENV_FILE with PYTHONPATH and a plugin that turns failed into passed): `1 failed, 125 passed`, exit 1 with and without the variable; the plugin itself works when loaded by hand (`4 passed`). Blocking 3: ident attribute through .git/info/attributes and through core.attributesFile (`git diff` empty, blob equal) and an fsmonitor hook that reports no change (`git status` empty): the fingerprint changes each time. Blocking 4: see AC-3. Blocking 1: see AC-4.
- Own fingerprint constructions in a fixture repository: skip-worktree with edit and with deletion, assume-unchanged, sparse checkout, eol=crlf attribute, core.autocrlf=input, working-tree-encoding, clean filter, core.fileMode=false with chmod, .git/info/exclude, core.excludesFile, a symbolic link in place of a file, a force-added file under an ignored directory: the fingerprint changes in each. Unchanged, by design or by the ignore rules: a staged-only change, `src/x.pyc`, a nested `.gitignore` that lists itself, `src/X.PYC` under a local core.ignoreCase.
- Sampled first-round non-blocking findings: 3 (`env GIT_CONFIG_COUNT=abc ./scripts/verify.sh` with an ignored backend/tests/unit/test-results/conftest.py -> `<== FAIL: No ignored file among sources, tests and scripts`, pytest exit 4); 2 (the survivors' classes are covered by mutants T5, T8 and the unit case for a failed lighter tier); 7 items 1 and 3 (unit cases ran); 1 (line 70 and ASM-023 now name CI as the cover; environment checked above).
- Probes for the findings below (scratch copies): backend/ave.pyc, a `.gitignore` that lists itself in backend/ and in docs/, the linter cache with a kept modification time; results under Findings. Control: a plain backend/conftest.py hidden the same way is stopped by the plugin (`ERROR: test files that Git ignores … backend/conftest.py`, exit 4).
- Mutation sample (fresh copy per mutant, bytecode directories removed, one string swap, the suite the Verification strategy names; controls unit, plugin, tiers, stop hook and checker pass): 34 valid mutants, 32 fail a named case (scripts/evidence.py 13 of 14, backend/tests/evidence_plugin.py 5 of 5, scripts/verify.sh and scripts/verify.d 7 of 7, .claude/hooks/stop-verify.sh 4 of 4, scripts/check-project-control.sh 3 of 3, scripts/lib/verify-state.sh 0 of 1). Survivors: U17 and S5 (non-blocking finding 3). One mutant of mine was equivalent and is not counted. Side effect: mutant S1 started a fixture release tier that waited 332 s for the shared heavy-media lock and held it for the fixture's marker steps.
- Documentation checks: frontmatter `verification` matches the newest Status line; ACs unticked; `_TBD` only under Test evidence; every file of § Implementation evidence exists; parent AVE-FEAT-019 lists the requirement; TRACEABILITY row status `verification`; ADR-001 and ADR-003 Accepted; `git log -1 --format=%h -- docs/briefs/2026-10-06-m0-final-review-2b.md` -> f996c17.
```

### Blocking findings (2)

1.

```text
location: scripts\verify.sh:285-309 (check_no_ignored_sources; path list at :300); scripts\lib\verify-state.sh:121; backend\tests\evidence_plugin.py:179-186; docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:49, :50, :57, :70
defect: A file that a `.gitignore` file ignores outside backend/src, backend/tests, scripts and .claude/hooks takes part in the steps and appears in no status, diff, fingerprint or ignored-file step. Three measured forms. (a) backend/ave.pyc, ignored by the rule `*.pyc` of the tracked .gitignore: pytest puts backend/ first on sys.path (root of the `tests` package), ahead of backend/src from `ave.pth`, so a sourceless module there stands in for the product package in every test. (b) A backend/.gitignore that lists itself hides backend/mypy.ini and backend/ruff.toml, which mypy and ruff read before pyproject.toml. (c) A docs/.gitignore that lists itself hides a link target that the checker then finds. A tree that fails is recorded PASS and reads FRESH. Edge case line 49 (`evidence comes only from files of the fingerprinted tree`) is false for (a); no line of § Edge cases states this limit (line 70 lists local state outside the tree, line 50 four directories); the B1 handback names it as discovered work (part 2, line 139) and no document took it up.
evidence: Scratch copies of f996c17 under the container's /tmp, own environment each. (a) `PROVISIONAL_FPS = Fraction(30)` changed to `Fraction(25)` in backend/src/ave/domain/rates.py. Control: `1 failed, 124 passed, 84 deselected`, `verify.sh: FAIL — tier fast (1 of 11 steps failed)`. With backend/ave.pyc (418 bytes, compiled from six lines that put a pristine copy of the package first on sys.path and import `ave` again): `git status --porcelain` shows only ` M backend/src/ave/domain/rates.py`; fingerprint 9a06ba8e… with and without the file; `<== PASS: No ignored file among sources, tests and scripts`; `125 passed, 84 deselected`; `verify.sh: PASS — tier fast (11 of 11 steps passed)`; `show AVE-REQ-018 --require-fresh --tier fast` -> `tier fast, PASS … Freshness: FRESH`, `AC-3 passed … test_no_source_gives_a_provisional_30`, exit 0. sys.path at collection: `['<tree>/backend', …, '<tree>/backend/src']`. (b) backend/.gitignore = `.gitignore`, `mypy.ini`, `ruff.toml`; mypy.ini = `[mypy] files = tests/__init__.py`; ruff.toml = `exclude = ["src", "tests"]`: `git status` empty, fingerprint 031495f5… unchanged, ignored-file listing empty. Then `import os` and a function typed `-> int` that returns a string appended to backend/src/ave/errors.py: `Success: no issues found in 1 source file`, `All checks passed!`, `verify.sh: PASS — tier fast (11 of 11 steps passed)`; without the three files `FAIL — tier fast (3 of 11 steps failed)` (format check, lint, type check). (c) docs/.gitignore = `.gitignore`, `hidden-note.md` and a link to it in docs/ARCHITECTURE.md: fingerprint unchanged by the two files; checker `OK: 51 required files …`; without the target `ERROR: docs/ARCHITECTURE.md: line 349: broken link to 'hidden-note.md'`. None of the files exists in a fresh clone, so the release run of this review is unaffected; the same holds for the ident and fsmonitor states of the first round.
fix: Make the ignored-file step cover the whole tree: fail on every path of `git ls-files --others --ignored --exclude-standard` outside a written list of paths that no step loads (var/, data/, .claude/worktrees/, .claude/settings.local.json, CLAUDE.local.md, .serena/, the `.env` files, the backend environment backend/.venv/, `__pycache__/`, the folder files). Start ruff with `--config pyproject.toml` and mypy with `--config-file pyproject.toml`. Cases in scripts/tests/test-verify-tiers.sh: an ignored backend/ave.pyc, a `.gitignore` that lists itself in backend/ and in docs/, each failing the run and named; a control for the listed paths. § Edge cases line 50 states the rule and names the listed paths as the local state that remains; line 49 keeps its clause only once it holds.
```

2.

```text
location: scripts\verify.d\20-backend.sh:28-29; docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:84 and :57; docs\ASSUMPTIONS.md (ASM-023, `reads no cache from the tree`)
defect: The steps "Backend format check" and "Backend lint" start ruff without `--no-cache`, so every run writes and reads backend/.ruff_cache/ inside the tree (ignored, outside the fingerprint and outside the ignored-file step). Implementation evidence line 84 (`the run keeps its caches in a scratch directory outside the tree`) and ASM-023 are false at this commit, and the cache changes a result: ruff 0.16.9 keys an entry by modification time and permissions, so an edited file with its earlier time stamp passes both steps unread. The smaller of the two findings: a false statement with a measured path. Time stamps through the container's mount have 100 ns steps, so the path needs a tool that keeps the time stamp (`cp -p`, `rsync -t`, an archive, `touch -r`); it is the sibling of the stale bytecode of WF-004.
evidence: The reviewer's clone after the release run: `git status --porcelain --ignored` -> `!! backend/.ruff_cache/`. Scratch copy: one `ruff check .` and `ruff format --check .` on the pristine tree; then `import os` and `x=1` appended to backend/src/ave/errors.py and the time stamp restored with `touch -r` (stat shows the same value and mode 644). The fingerprint changes, so the edit is visible and the run is new: `./scripts/verify.sh` -> `<== PASS: Backend format check`, `<== PASS: Backend lint`, `verify.sh: PASS — tier fast (11 of 11 steps passed)`. `ruff check --no-cache .` and `ruff format --check --no-cache .` exit 1. After `rm -rf backend/.ruff_cache`: `<== FAIL: Backend format check`, `<== FAIL: Backend lint`, `verify.sh: FAIL — tier fast (2 of 11 steps failed)`.
fix: `backend_uv ruff format --check --no-cache .` and `backend_uv ruff check --no-cache .` (or `--cache-dir "$AVE_RUN_SCRATCH/ruff-cache"`), and a case in scripts/tests/test-verify-tiers.sh beside "the type checker reads no cache from the tree" that reads the two ruff lines of the stub uv. With the whole-tree rule of finding 1 a cache left in backend/ fails the run by itself.
```

### Non-blocking findings (6)

1.

```text
location: scripts\evidence.py:817-818 and :860-862; scripts\tests\test_evidence.py:931; .claude\skills\milestone-review\SKILL.md:82; requirement file line 45; docs\ARCHITECTURE.md:312
defect: With `--tier T`, `show --require-complete` reads the manifest of that tier alone, so a failed fresh run of another tier on the same tree does not count. Edge case line 45 and ARCHITECTURE.md say `a failed fresh run of any tier counts`; the milestone review certifies with `--tier release`.
evidence: Code reading: `found = manifests(args.tier)` and `failed_runs` is built from `found`. The unit case asserts the narrowing: `self._show(*flags, "--tier", "fast")` returns 0 beside a failed fresh media run.
fix: Read the newest manifest of every tier for the failed-run rule also when `--tier` selects the one shown, with a unit case (`--tier release` beside a failed fresh fast run exits 1); or reword line 45 and ARCHITECTURE.md to the form without `--tier`.
```

2.

```text
location: requirement file line 53; scripts\verify.d\20-backend.sh:31-35; backend\tests\unit\test_fast_tier_media_tools.py:1-6
defect: A test that gives the child process a PATH of its own reaches the real tool, like the absolute path the sentence names; the docstring of the test module still names the two variables only.
evidence: Probe test in the fast tier: `subprocess.run(["ffmpeg", "-version"], env={**os.environ, "PATH": "/usr/bin:/bin"}, check=True)` passed, as did `/usr/bin/ffmpeg`; the four by-name forms failed.
fix: Line 53 and the comment in 20-backend.sh say `by an absolute path or with a PATH of its own`; the docstring names the stand-ins on PATH.
```

3.

```text
location: scripts\evidence.py:667; scripts\lib\verify-state.sh:49-50; scripts\tests\test-stop-hook.sh:168-171
defect: Two one-line mutants survive the suites the Verification strategy names: `_run` taking the output of a command that failed as its answer, and GIT_INDEX_FILE left out of the variables the fingerprint library unsets (the stop-hook suite sets GIT_DIR and GIT_WORK_TREE only).
evidence: U17 (`if completed.returncode != 0 or not text:` to `if not text:`) -> `evidence.py unittest: PASS`; S5 -> `STOP HOOK TOTAL: pass=145 fail=0`.
fix: A unit case in which a command prints text and exits 1 and `_run` returns `unavailable`; a stop-hook case that calls the hook with each remaining redirecting variable (GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY, GIT_COMMON_DIR, GIT_NAMESPACE) and expects the cache hit of this tree.
```

4.

```text
location: backend\src\ave\fixtures\generate.py:73-83 and :35-39; requirement file line 52
defect: The generator digest holds barcode.py, generate.py and standard.py. The modules the generator imports (`ave.proc`, `ave.timebase`, `ave.media.asset`, `ave.paths`) are outside it, so an edit to `run_tool` or `media_url` keeps the fixtures of the earlier code in the cache.
evidence: Code reading; backend/tests/unit/test_fixture_cache_key.py computes its expected digest from the same three names.
fix: Hash every `ave` module that generate.py imports, or state in line 52 that the digest covers the three files of `ave/fixtures`.
```

5.

```text
location: docs\TRACEABILITY.md:211; requirement file line 12
defect: The TRACEABILITY row names four of the seven test files (test-checker.sh, test_fixture_cache_key.py and test_fast_tier_media_tools.py are missing) and omits scripts/check-project-control.sh, scripts/lib/media-tier-only.sh and backend/src/ave/fixtures/generate.py. The dependency AVE-REQ-093 has status `verification`; the skill expects `done`.
evidence: Row text against the Tests line of § Implementation evidence; frontmatter of AVE-REQ-093.
fix: Complete the row; move AVE-REQ-093 to done before this requirement.
```

6.

```text
location: scripts\evidence.py:637-649; docs\requirements\README.md:189-191
defect: Carried over from the first round (non-blocking 7, item 2), without a disposition in the fix brief: for a strategy line that names a test level and inspection, as AC-3 and AC-4 of this requirement do, an inspection line alone satisfies the done gate when no test carries the tag.
evidence: `criterion_state([], True)` returns `inspected`; `done_problems` reports only failed, contract-only and missing.
fix: Credit `inspected` for a mixed line only beside a passing tagged test, or state the rule as a limit in § Edge cases.
```

### Test quality

```text
Section 8 per criterion. AC-1: test-verify-tiers.sh runs the real verify.sh on a fixture with one marker step per tier and asserts exit codes and step lines; test-checker.sh asserts exact error lines for check 2; tagged and executed (65 and 1090 checks in the release run); mutants T1, C1, C4 fail named cases. AC-2: test_evidence.py asserts concrete values (commit equals `git rev-parse HEAD`, file hashes computed in the test, fingerprint through the real library in a fixture repository); the plugin tests run real inner sessions; the stop-hook suite shows seven local Git states with Git's own view empty and the fingerprint changed; the tiers suite compares the names a step sees with a written list. My own constructions agree for every state Git can hide through the index, attributes, filters and local ignore rules. Gap: every case of the ignored-file step plants its file inside one of the four directories, and no case reads the ruff lines of the stub uv, which is why blocking findings 1 and 2 went unseen. AC-3: the stop-hook suite drives the real hook with real verify.sh runs and fixed expected codes (2, 2, 0); the stand-in is evidenced in three parts (the step sets variables and PATH, `tool_path` reads them, `run_tool` raises), and my probe test confirms the by-name forms end to end. AC-4: plugin and unit cases assert exit status and recorded outcomes for each way a test does not run; the real runner is exercised with stub suites, and my probe with six stubs gave the same verdicts. Module-level `pytestmark` in test_evidence_plugin.py gives all 21 cases both tags, and shell-suite tags count per file, as the Edge cases state. No test is skipped, focused or expected to fail: the manifest holds `passed` and `deselected` only, and the deselected tests of the fast report ran in the media report. Mutation sample: 32 of 34 valid mutants fail a named case, for example U1 -> test_stale_evidence_is_reported_and_refused_when_freshness_is_required, U5 -> test_manifest_ties_results_to_commit_fingerprint_and_configuration, U10 -> test_no_file_beside_the_script_stands_in_for_a_standard_module, P1 -> test_forbid_skips_fails_a_session_whose_selected_tests_never_ran, P3 -> test_a_test_file_that_git_ignores_stops_the_session, T7 -> `the fast tier fails a done requirement that this run does not evidence`, S2 -> `a cached pass never overrules the recorded failure of the same tree`. Survivors: U17 and S5 (non-blocking finding 3). The limits the Edge cases declare (vacuous tests, a fabricated TOTAL line, changes to the gate, local state under HOME and in the environment) are stated with their inspection; my stub suite that printed `TOTAL: pass=3 fail=0` passed the runner, as line 66 says it would.
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
