# Handback — M0 gates red-team, part 6: review of AVE-REQ-097 after the fixes

Run `wf_7d9d015c-906` ([script](../../workflows/verify-m0-final-wf_7d9d015c-906.js)), the final review round of M0 launched 2026-10-06: `verify-requirement` for AVE-REQ-097 at `2df637f` by an independent reviewer in a private clone. The report is the reviewer's, unedited apart from local paths. The run had no brief of its own ([WF-008](../../WORKFLOW_LOG.md)); the report is filed with the brief whose work it reviews. The fixes follow in [the fix brief](../2026-10-06-m0-final-review-fixes.md).

## Review

Verdict: **FAIL** — AVE-REQ-097 — Verification gates that cannot pass as placeholders

### AC-1 Keep a fast feedback tier, real-media integration tier, and full release tier behind documented repository commands. — PASS

```text
My runs in a private clone at 2df637f: `./scripts/verify.sh` -> `verify.sh: PASS — tier fast (11 of 11 steps passed)`; `./scripts/verify.sh --tier release` -> `verify.sh: PASS — tier release (13 of 13 steps passed)` (124 unit tests, 84 media and population tests in 450 s, six tooling suites). scripts\tests\test-verify-tiers.sh (48 checks, 0 failed, in the release run and by hand): default tier fast, `--tier media`, `--tier=release`, VERIFY_TIER, usage errors exit 2, a step file that cannot be loaded or carries CRLF fails the tier, an unregistered step file is never sourced. scripts\tests\test_evidence.py::test_the_suite_runner_stops_when_its_temp_dir_lies_inside_a_work_tree passed. Mutants of tier membership, VERIFY_TIER, step-file loading and registration each failed a named case (V15, V7, V4, V5). Commands are documented in docs\ARCHITECTURE.md (Testing strategy, Verification pipeline), CLAUDE.md and the usage text of verify.sh; .github\workflows\verify.yml runs `--tier release`.
```

### AC-2 Tie verification evidence to a commit/tree fingerprint, configuration, requirement IDs, and test results; stale evidence cannot certify changed code. — FAIL

```text
Verified: the release manifest names commit 2df637fbc30b, fingerprint 8229f6cedf91…, the toolchain with the environment digest, eight configuration hashes, the pytest invocation, seven suite results and 58 criteria; `show AVE-REQ-097 --require-fresh --tier release` exits 0 with FRESH; a visible edit, index flags, a file hidden by .git/info/exclude, CRLF line ends and a second `record` of an old run are each refused (repeated findings 097-E-4, E-5, E-7, F-1). Not met: blocking finding 3 (an `ident` attribute or an fsmonitor hook leaves the fingerprint unchanged for an edited file: `show --require-fresh` prints `tier fast, PASS … Freshness: FRESH` and the Stop gate reuses its pass on a tree where verify.sh fails 4 of 11 steps) and blocking finding 2 (UV_ENV_FILE hands PYTHONPATH and PYTEST_ADDOPTS to the pytest step; a failing test is recorded as passed, the manifest reads PASS and FRESH and records nothing of it). Edge cases lines 47 and 55 state the opposite.
```

### AC-3 Use supported hooks only after a small smoke test; avoid recursive Stop-hook loops and repeated full renders on every conversational response. — PASS

```text
scripts\tests\test-stop-hook.sh (98 checks, 0 failed): the gate runs the fast tier under VERIFY_TIER=release (fast marker step only), blocks 2, 2 and releases 0 without `stop_hook_active`, keeps the limit in 1 to 10, reads the outermost key, runs again when a cached pass names a tree whose recorded run failed. test-verify-tiers.sh: the fast pytest step sees the stand-in, the media step the real tools; backend/tests/unit/test_fast_tier_media_tools.py (2 cases) passed in the release run; test-checker.sh check 12 cases (822 checks over four awk implementations). Ten mutants of the hook, four of check 12 and the stand-in mutant each failed a named case. Inspection: .claude\settings.json registers SessionStart and Stop as command hooks (one Stop command, timeout 1800); ASM-001 records the SessionStart block on 2026-10-01 and a Stop-hook PASS record on 2026-10-06; I read .git\claude-verify (read-only): `last-result: PASS 2026-10-06T05:49:18Z …` beside a log of the 11-step fast tier, so the Stop hook runs live with the fast tier only. The Edge-case sentence on the media stand-in is false as written (blocking finding 4), and the Stop-gate cache follows the fingerprint of blocking finding 3; the smoke-test record is thin (non-blocking).
```

### AC-4 No-op scripts, skipped integration tests, caught exceptions returning success, or provider mocks cannot establish completed product requirements. — FAIL

```text
Verified: skipped, xfailed, xpassed, module-skipped and never-run tests fail a `--forbid-skips` session; a missing report fails the step; a unit-test file that ends the interpreter, a generator or coroutine test, a tag above no test fail `evidence.py unittest`; a suite with `fail>=1` or no check fails run.sh; the fast tier fails a done requirement with contract-only and missing evidence (repeated findings 097-D-1, D-4, D-7, D-10, D-11, E-8, F-2, F-3, F-4, F-5, critic 1, 2, 9; 20 plugin tests, 32 unit tests). Not met: blocking finding 1 (scripts/tests/run.sh carries `AVE-REQ-097 AC-4` and never has a suite result: `show AVE-REQ-097 --require-fresh --require-complete --tier release` exits 1 on my passing release run, and `check-done --tier release` on that run fails once this requirement is `done`, so Definition of Done item 4 cannot hold) and blocking finding 2 (with PYTHONUSERBASE set by the caller the done step prints `ERROR: AVE-REQ-018 AC-2: contract-only in this run`, `AC-3: missing in this run` and ends `<== PASS`; `verify.sh: PASS — tier fast (11 of 11 steps passed)`). Inspection items performed: no test on a provider fake exists at this commit (the only contract marker is in the plugin's generated module; `fake_asset` is test data), no inspection line exists in any working requirement file, and section 8 of the skill is the review below.
```

### Verification runs

```text
- Private clone .claude\worktrees\verify-ave-req-097 at 2df637f (removed at the end; `git status --porcelain` empty before every evidence run; no index flag, no .git/info/attributes, no core.fsmonitor in the clone).
- `./scripts/verify.sh` -> exit 0, `verify.sh: PASS — tier fast (11 of 11 steps passed)`; 32 tooling unit tests, `124 passed, 84 deselected`, `Evidence: PASS — 58 criteria tagged`.
- `./scripts/verify.sh --tier release` -> exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`; `124 passed, 84 deselected in 14.07s`; `84 passed, 124 deselected in 450.52s`; CHECKER TOTAL pass=822 fail=0, BASELINE 213/0, STOP HOOK 98/0, SESSION START 31/0, VERIFY TIERS 48/0, PROBE 28/0; `OK: every criterion of the 0 done requirements …`; manifest var/verify/runs/20261006T055453Z-987.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --tier release` -> exit 0: `tier release, PASS, commit 2df637fbc30b`, `Freshness: FRESH`, AC-1 passed (2 results), AC-2 passed (25), AC-3 passed (5), `AC-4 passed 25 result(s): scripts/tests/run.sh, … — 1 tagged test(s) did not run`. The same with `--require-complete` -> exit 1.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests` -> exit 0, `Ran 32 tests`, `evidence.py unittest: PASS (1 file(s))`.
- `./scripts/dev-container.sh bash scripts/tests/test-verify-tiers.sh` -> exit 0, `VERIFY TIERS TOTAL: pass=48 fail=0`; `… test-stop-hook.sh` -> exit 0, `STOP HOOK TOTAL: pass=98 fail=0`; `… test-checker.sh` -> exit 0, `CHECKER TOTAL: pass=211 fail=0`.
- Environment of my runs: /state/venvs/1669714700 (created 2026-10-03 by an earlier clone of the same path); its 19 distributions equal those of an environment I built today from uv.lock, its only .pth files are _virtualenv.pth and ave.pth, no file outside a RECORD besides _virtualenv.py (same hash as in the fresh environment).
- Red-team findings repeated by their written reproduction in a scratch copy inside the container (/tmp, own environment), all rejected now: 097-D-1 (ignored-file step FAIL and pytest exit 4 `test files that Git ignores`), D-4a (`124 passed`, manifest lists the arguments), D-4b (`1 failed, 124 passed`, tier FAIL), D-7 (`the tag AVE-REQ-097 AC-2 stands above no test`, six lines), D-10 (`the test process ended without a result (exit 0)`), D-11 (two errors); 097-E-4 (no fingerprint, `Freshness: STALE`, hook exit 2), E-5 (fingerprint changes, `<== FAIL: Load scripts/verify.d/20-backend.sh`), E-6/F-5 (stale bytecode: step by hand `124 passed`, verify.sh `2 failed`), E-7 (`is recorded already`, exit 2; prepared run directory `cannot create the run directory`, exit 2; planted suite result refused), E-8 (`ERROR: AVE-REQ-018 AC-2: contract-only in this run`, `AC-3: missing in this run`, tier FAIL); 097-F-1, F-2, F-3 (shadow pytest.ini: `1 skipped` -> step FAIL; hidden by info/exclude -> no fingerprint), F-4 (`41 test(s) were selected and never ran`; `no report: the pytest session ended before it wrote one`); critic 1a, 1b, 2 (`backend/tests/unit/test-results/conftest.py` named, exit 4), 5 (`unknown requirement IDs: AVE-REQ-999`, exit 2 with and without IDs), 8 (planted last-pass after a recorded FAIL: hook exit 2, new log), 9 (shadow unittest.pyc: `FAIL: test_fails` reported, ignored-file step FAIL).
- Own probes (scratch copy): PYTHONUSERBASE, UV_ENV_FILE, `ident` attribute, fsmonitor hook, direct ffmpeg call, run.sh tag with the requirement marked done, GIT_CONFIG_COUNT=abc, SHELLOPTS=noexec — results under Findings.
- Mutation runs (scratch copy, fresh copy per mutant, no bytecode in the tree): 91 one-line mutants of scripts/evidence.py (27), scripts/verify.sh (24), scripts/verify.d (5), scripts/tests/run.sh (4), backend/tests/evidence_plugin.py (11), .claude/hooks/stop-verify.sh (9), scripts/lib/verify-state.sh (8) and check 12 (4), each against the suite the Verification strategy names; baselines unit PASS, tiers 48/0, stop hook 98/0, plugin 20 passed, checker 211/0. 84 failed a named case, 7 survived (Test quality).
- Cleanup: `./scripts/dev-container.sh --stop` (state absent), clone removed, main checkout `git status --porcelain` empty; no commit, no push.
```

### Blocking findings (4)

1.

```text
location: scripts\tests\run.sh:16; scripts\evidence.py:100 (TOOLING_PATTERNS) and :413-420
defect: The suite runner itself counts as a tooling test file that carries `AVE-REQ-097 AC-4` (its header comment, line 16, holds the tag) and it never has a suite result. This requirement's AC-4 therefore has a tagged test that `did not run` in every tier, the release tier included: evidence for AVE-REQ-097 never reads complete, and the release tier fails as soon as this requirement is `done`. Definition of Done item 4 cannot hold for it; Edge case line 37 (`the release tier, which runs every test`) and docs/requirements/README.md:351-352 are false for this tag.
evidence: Release run in the clone (PASS, 13 of 13): `show AVE-REQ-097 --require-fresh --tier release` -> `AC-4 passed 25 result(s): scripts/tests/run.sh, … — 1 tagged test(s) did not run`; with `--require-complete` exit 1. Scratch copy with the requirement marked done in canonical form (`check_baseline.py`: `OK: baseline intact`), `python3 -B scripts/evidence.py check-done --dir <copy of the real release run directory> --tier release` -> `ERROR: AVE-REQ-097 AC-4: 1 tagged test(s) did not run in this run`, `FAIL: 1 problem(s)`, exit 1. Control: line 16 reworded without the tag -> `OK: every criterion of the 1 done requirements has a passing test …`, exit 0.
fix: Reword run.sh:16 so that it holds no tag, and make the rule mechanical: a comment tag in a tooling file that neither run.sh lists nor `test_*.py` matches is an error at `record` and `check-done` (or leave run.sh and make-fixture.sh out of TOOLING_PATTERNS). Holding cases: test_evidence.py — on the real scripts/tests directory every file with a comment tag is a listed suite or a unit-test file; a done requirement whose every listed suite passed gives no `did not run` problem in the release tier.
```

2.

```text
location: scripts\verify.sh:189-196 (clean_environment); scripts\verify.d\20-backend.sh:15 (backend_uv); docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:55 and :79
defect: Variables of the caller that change what Python and pytest load still reach the steps and turn failing steps into PASS, against Edge case line 55 (`change no result: verify.sh clears the variables`), Implementation evidence line 79 and the header of verify.sh. (a) PYTHONUSERBASE: every `python3 -B scripts/evidence.py …` step imports the user-site module of the directory it names. (b) UV_ENV_FILE: uv loads the file after verify.sh cleared the environment, so PYTHONPATH and PYTEST_ADDOPTS themselves arrive in the pytest process.
evidence: (a) /tmp/ub/lib/python3.12/site-packages/usercustomize.py = `atexit.register(lambda: os._exit(0))`. Tree of finding 097-E-8 (AVE-REQ-018 done, AC-2 contract-only, AC-3 untagged): control `<== FAIL: Done requirements evidenced by this run`, `verify.sh: FAIL — tier fast (1 of 11 steps failed)`; `env PYTHONUSERBASE=/tmp/ub ./scripts/verify.sh` -> the step prints `ERROR: AVE-REQ-018 AC-2: contract-only in this run`, `ERROR: AVE-REQ-018 AC-3: missing in this run`, `FAIL: 2 problem(s)` and `<== PASS`; exit 0; manifest result PASS. Clean tree plus a failing scripts/tests/test_zz_fail.py: control `<== FAIL: Evidence tooling unit tests`, exit 1; with the variable exit 0. (b) /tmp/evil/env = `PYTHONPATH=/tmp/evil` and `PYTEST_ADDOPTS="-p rt_helper"`, rt_helper.py a makereport hook that turns failed into passed; test_rates.py with an appended `assert 1 + 1 == 3`: control `1 failed, 124 passed`, tier FAIL; `env UV_ENV_FILE=/tmp/evil/env ./scripts/verify.sh` -> `125 passed, 84 deselected`, `verify.sh: PASS — tier fast (11 of 11 steps passed)`, report `test_redteam_broken: passed`, `show AVE-REQ-018 --tier fast --require-fresh` -> `PASS … Freshness: FRESH`, exit 0; the recorded invocation shows the step's own arguments only. On this Windows host dev-container.sh forwards only VERIFY_TIER; the path is open where verify.sh runs natively (CI, Linux, cloud sessions) or from inside the container.
fix: clean_environment unsets PYTHONUSERBASE and exports PYTHONNOUSERSITE=1 (or every python3 step runs with `-s`), unsets UV_ENV_FILE and backend_uv passes `--no-env-file`; better, start the steps from an allow-list environment (PATH, HOME, TMPDIR, locale, UV_PROJECT_ENVIRONMENT, the uv cache, the heavy-lock variables). The plugin records PYTEST_ADDOPTS in the invocation and refuses a plugin outside an allow-list. Holding cases in test-verify-tiers.sh: the environment line shows PYTHONUSERBASE and UV_ENV_FILE unset and PYTHONNOUSERSITE=1; the stub uv sees `--no-env-file`; a usercustomize under a caller-named user base leaves no marker in a python3 step.
```

3.

```text
location: scripts\lib\verify-state.sh:89-99 (vstate_blind) and :125-131; docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:47 and :83
defect: Two further local Git states hide an edited file from the fingerprint, and the tree keeps its fingerprint: an `ident` attribute outside the tree (.git/info/attributes, core.attributesFile) on a file that holds `$Id$`, and the fsmonitor-valid index flag with a `core.fsmonitor` hook that reports no change. Stale evidence then reads FRESH for changed code and the Stop gate reuses its pass. Edge case line 47 states that such a tree (`an index flag such as …`, an attribute that rewrites what Git hashes) has no fingerprint; this is the class of findings 097-E-4 and 097-F-1.
evidence: ident: test_rates.py with an appended `_STAMP = "$Id$"` passes (hook exit 0, `PASS — tier fast (11 of 11)`, fingerprint b4bb844f…); then `backend/tests/unit/test_rates.py ident` in .git/info/attributes and the line edited to `_STAMP = "$Id: "; raise RuntimeError(…); _S = " $"`: fingerprint b4bb844f… (unchanged; `git ls-files -v` shows no flag), `show AVE-REQ-018 --tier fast --require-fresh` -> `tier fast, PASS … Freshness: FRESH`, Stop hook exit 0 without a run (no last.log), session-start `Last verification: PASS … (matches the current tree)`, while `./scripts/verify.sh` on that tree gives `121 test(s) were selected and never ran`, `FAIL — tier fast (4 of 11 steps failed)`. Control without the attribute: the fingerprint changes. fsmonitor (fixture repository with scripts/lib/verify-state.sh, hook printing a token and no path, `core.fsmonitorHookVersion 2`): fingerprint abbdb7c0… before and after f.txt changes from `one` to `two`, `git status` empty, `git ls-files -v` shows `H f.txt`, `git ls-files -f` shows `h f.txt`; with the setting removed the fingerprint changes.
fix: Root cause: fingerprint the bytes the steps read — hash mode, path and `git hash-object --no-filters` of every file that `git ls-files -z --cached --others --exclude-per-directory=.gitignore` lists, read from the working tree, so that no index flag, attribute or fsmonitor state takes part. Smaller change: vstate_blind also returns blind for a lowercase entry of `git ls-files -f`, a set `core.fsmonitor`, and any of `ident`, `working-tree-encoding` in `git check-attr --stdin`; the fingerprint's Git commands run with `-c core.fsmonitor=false` and without GIT_CONFIG_COUNT, GIT_CONFIG_GLOBAL and GIT_CONFIG_PARAMETERS of the caller. Two cases in test-stop-hook.sh, section `changes Git hides from the fingerprint`. Otherwise § Edge cases names the Git configuration and attributes of the local repository beyond the detected kinds as local state.
```

4.

```text
location: docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:52; scripts\verify.d\20-backend.sh:29-34
defect: The Edge case `A test without the media marker that calls FFmpeg or FFprobe → fails in the fast tier … so the Stop gate never renders` is false as written: the stand-in replaces AVE_FFMPEG and AVE_FFPROBE, which only calls through ave.proc read; PATH still holds the real tools. The smallest of the four findings: a false statement, not a failing behavior of the tree at this commit.
evidence: backend/tests/unit/test_direct_tool.py without a marker: `ffmpeg = shutil.which("ffmpeg")`, `subprocess.run([ffmpeg, "-hide_banner", "-version"], capture_output=True, check=True)`. `./scripts/verify.sh` -> format check, lint and type check PASS, `125 passed, 84 deselected`, `verify.sh: PASS — tier fast (11 of 11 steps passed)`; report: `tests/unit/test_direct_tool.py::test_starts_ffmpeg_without_the_media_marker passed`. (I ran `-version`, no render; ruff S607 flags only a partial-path literal.)
fix: fast_pytest puts a directory with `ffmpeg` and `ffprobe` stand-ins first on PATH beside the two variables, with a tiers-suite case that the fast step resolves `ffmpeg` to the stand-in; and the sentence (also docs/ARCHITECTURE.md § Verification pipeline item 2) says `through ave.proc or PATH` and names the review item that covers an absolute tool path.
```

### Non-blocking findings (8)

1.

```text
location: scripts\dev-container.sh:88; docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:66; docs\ASSUMPTIONS.md (ASM-023)
defect: The cover named for the backend environment, the reviewer's private clone, is not a fresh environment on the container host: the environment is keyed by the clone's path on the shared state volume and persists between reviews. `uv run --frozen` leaves extraneous files in place.
evidence: My clone used /state/venvs/1669714700 (cksum of the clone path), created 2026-10-03T04:06Z by the review of that day; every container of the host mounts the volume. I checked it before relying on the runs: same 19 distributions as an environment built today, no foreign .pth or unowned file.
fix: A private clone gets a new environment (key with a nonce or HEAD, or verify-requirement removes the directory first, or `uv sync --frozen --exact` plus a check for files no RECORD owns); or line 66 and ASM-023 say that on the container host only CI's fresh checkout covers the environment.
```

2.

```text
location: scripts\tests\test-verify-tiers.sh:114-122; scripts\tests\test_evidence.py:738-772; scripts\tests\test-stop-hook.sh:137-141
defect: Seven one-line mutants survive every suite the Verification strategy names: five entries of the cleared-variable list (PYTHONOPTIMIZE, PYTHONHOME, GIT_INDEX_FILE, GIT_COMMON_DIR, ENV — the environment case echoes 7 of the 18 cleared variables), the rule that a failed fresh run of a lighter tier counts for `--require-complete` (scripts/evidence.py:769), and `w/mixed` line ends in the fingerprint (scripts/lib/verify-state.sh:135).
evidence: Mutation runs: V9, V10, V10c, V18, V19 -> `VERIFY TIERS TOTAL: pass=48 fail=0` (V9, V10, V19 also `STOP HOOK TOTAL: pass=98 fail=0`); E21 -> `evidence.py unittest: PASS`; S8 -> `STOP HOOK TOTAL: pass=98 fail=0`.
fix: The fixture step echoes every cleared variable; a unit case with a passing fresh release manifest and a failed fresh fast manifest expects exit 1; a stop-hook case with a file of mixed line ends expects another fingerprint.
```

3.

```text
location: scripts\verify.sh:203-208; backend\tests\evidence_plugin.py:76-79
defect: Both ignored-file guards pass when Git itself fails inside a work tree: the step prints `Skipped: outside a Git work tree.` and the plugin returns no hidden file.
evidence: `env GIT_CONFIG_COUNT=abc ./scripts/verify.sh` with an ignored backend/tests/unit/test-results/conftest.py that removes a failing test: `<== PASS: No ignored file among sources, tests and scripts`, the conftest was loaded (the removed test did not fail). The run failed only through tests of the tooling that need Git, and the manifest has no fingerprint (`Freshness: STALE`), so nothing was certified.
fix: Tell a missing repository (.git absent) from a failing Git and fail the step and the session in the second case; clear or pin the Git configuration variables of the caller.
```

4.

```text
location: scripts\verify.sh; .claude\hooks\stop-verify.sh; scripts\check-project-control.sh:561-564
defect: `SHELLOPTS=noexec` from the caller makes verify.sh and the Stop hook exit 0 without running a command. It falls under the trusted shell of line 66, which names no variable of this kind, and check 12 would accept it in the `env` block of the settings file.
evidence: `env SHELLOPTS=noexec ./scripts/verify.sh` -> exit 0, no output, no run directory; the hook with the variable -> exit 0, no state file.
fix: Line 66 names SHELLOPTS, BASHOPTS and exported shell functions beside the gate variables; check 12 fails `env` keys SHELLOPTS, BASHOPTS, BASH_ENV and ENV.
```

5.

```text
location: docs\ASSUMPTIONS.md:52-55 (ASM-001); docs\briefs\handbacks\2026-10-03-m0-gates-red-team.part-4.md:372; requirement file line 74
defect: ASM-001 records one live Stop-hook PASS (2026-10-06). The handback's disposition of critic-097-10 says it records `pass, block and release`, and the strategy line says the hooks ran `before the work relied on them`; the Stop-hook record is five days younger than that reliance.
evidence: Text of ASM-001; my read of the main checkout's state shows a further live PASS (2026-10-06T05:49:18Z) and no record of a live block.
fix: Add the observed stderr header of a live block and of a release to ASM-001, or reword the disposition and the strategy line to what the record shows.
```

6.

```text
location: docs\requirements\AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:5, :12, :65, :66
defect: Documentation: the frontmatter status is `in-progress` during this review (the skill expects `verification`); the dependency AVE-REQ-093 is `in-progress`, not `done`; the list of gate files in line 65 omits scripts/check-project-control.sh (registry of the step files, check 12) and scripts/lib/media-tier-only.sh; line 66 omits .claude/settings.local.json and the user-level settings, which can switch the hooks off outside check 12.
evidence: Frontmatter and Status log of both files; check 12 reads `.claude/settings.json` only (check-project-control.sh:1034).
fix: Set `verification` with a log line before the next review; move AVE-REQ-093 to done first; add the three files to the two Edge cases.
```

7.

```text
location: scripts\evidence.py:480 and :501; :172-181; :679
defect: Minor: (1) the binding of a unit-test tag compares method names without the class, so a tag above a never-collected `Helper.test_x` passes when another class ran a `test_x`; (2) for a strategy line that names a test level and inspection, the inspection line alone satisfies the done gate (documented in README:175-177; AC-3 and AC-4 of this requirement are such lines); (3) `record` ends in a traceback when var/verify does not exist.
evidence: Code reading for (1) and (2); (3): `record --dir var/probe/g …` in a fresh copy -> `FileNotFoundError: … /var/verify/.latest-fast.json.54686.tmp`, exit 1.
fix: (1) store class-qualified test IDs; (2) credit `inspected` only when no test is tagged, or require a passing test as well for a mixed line; (3) create the directory or raise EvidenceError.
```

8.

```text
location: ai-video-editor-requirements\spec\ACCEPTANCE_TESTS.md (AT-29, AT-30)
defect: Scenario status (no finding): AT-29 and AT-30 run at the final review. Nothing at this commit contradicts them beyond blocking findings 2 and 3, which are the paths on which AT-29's `Current-tree evidence is required` does not hold.
evidence: Reading of both scenarios against the runs above.
fix: None beyond the blocking fixes.
```

### Test quality

```text
Section 8 per criterion. AC-1: test-verify-tiers.sh runs the real verify.sh on a fixture with one marker step per tier and asserts exit codes and step lines; mutants of membership, tier variable, step loading and registration fail named cases; tagged, executed (48 checks in the release run). AC-2: test_evidence.py asserts concrete values (commit equals `git rev-parse HEAD`, file hashes computed in the test, fingerprint through the real library in a fixture repository); plugin tests run real inner sessions; the stop-hook suite compares the manifest's fingerprint with the fixture tree's. Gap: no case for an attribute other than `filter` or for the fsmonitor flag (blocking finding 3), and 5 of 18 cleared variables without a case. AC-3: stop-hook suite on the real hook with real verify.sh runs; fixed expected codes (2, 2, 0); check 12 cases with exact messages. The media stand-in is evidenced in three parts (step sets the variables, tool_path reads them, run_tool raises); no case covers a tool started outside ave.proc (blocking finding 4). AC-4: plugin and unit cases assert exit status and recorded outcomes for each way a test does not run; run.sh is exercised with stub suites. Gap: no case runs the done gate over the real set of tooling files, which is why the tag in run.sh went unseen (blocking finding 1); no case starts a step with a hostile user-site or uv environment file (blocking finding 2). Mutation result: 84 of 91 mutants failed a named case — all 26 killed evidence.py mutants name the unit test (for example E4 -> test_the_done_gate_judges_every_tier, E5 -> test_no_file_beside_the_script_stands_in_for_a_standard_module, E16 -> test_a_run_without_a_step_log_is_recorded_as_failed), all 11 plugin mutants, all 9 hook mutants (H1 -> `gate ran the fast tier despite VERIFY_TIER=release`, H3 -> `a cached pass never overrules the recorded failure of the same tree`, H5 and H6 -> the 2, 2, 0 sequence), 7 of 8 fingerprint mutants, all 4 check-12 mutants, all 4 run.sh mutants, 19 of 24 verify.sh mutants and all 5 step-file mutants. Survivors: E21, V9, V10, V10c, V18, V19, S8 (non-blocking finding 2). No test is skipped, focused or expected to fail; the pytest tests of this requirement ran in the release run (20 plugin cases, 2 stand-in cases, 2 cache-key cases). Shell-suite tags count per file, as the Edge case states. Limits the Edge cases declare: vacuous tests, inspection lines and changes to the gate are stated honestly with their inspection; the local-state line omits the Git configuration of blocking finding 3 and the shared environment of non-blocking finding 1.
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
