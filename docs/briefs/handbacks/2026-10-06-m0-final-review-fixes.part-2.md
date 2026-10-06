# Handback — M0 final review fixes, part 2: track B1, run environment, fingerprint and hooks (AVE-REQ-097, AVE-REQ-096, AVE-REQ-098)

Brief: [2026-10-06-m0-final-review-fixes.md](../2026-10-06-m0-final-review-fixes.md). Run `wf_5cd13360-464` ([script](../../workflows/m0-final-review-fixes.js)), branch `m0-final-fixes-b1` from `41973c5`. The report below is the writer's, unedited apart from local paths and the level of its headings. The lead confirmed the executable bit in the fingerprint entry ([ASM-024](../../ASSUMPTIONS.md)) and the named set ([ASM-025](../../ASSUMPTIONS.md)), applied the proposed texts, and added `--no-env-file` to the package listing of `scripts/evidence.py`. CI ran the environment cleaning for the first time on the push of the integration branch.

## Report

### Result: PARTIAL

Every finding of track B1 is implemented, has a named suite case and is committed; `./scripts/verify.sh --tier release` passes on the committed tree. The result is PARTIAL, not COMPLETE, for these reasons, each detailed under "Deviations and discovered work":

1. One decision of the brief is implemented in an extended form that the lead has not confirmed: the fingerprint entry also holds the executable bit of the working file (the brief names the index mode alone).
2. The named environment is unverified in CI: this task cannot push, so no GitHub run has started `verify.sh` natively with the new cleaning.
3. Lead-owned documents and the `.gitignore` comment disagree with the code on this branch until the proposed texts below are applied.
4. Two one-line mutants survive (the sort, the two `-c` settings), and one case I added is killed by no mutant.
5. I overwrote a file in the shared session scratchpad that was not mine (`mutate.py`) and cannot restore it.

### Branch and commit

- Branch `m0-final-fixes-b1`, commit `faa9efba0b97761ec93a6ec3fcb68dfde1ca12fe`, parent `41973c503730a0d017fc2d319e8cd33cd02e8c60` (the base commit; `git rev-parse HEAD` printed exactly that hash before any change).
- Nine files, all inside the B1 allowed paths: `scripts/verify.sh`, `scripts/verify.d/20-backend.sh`, `scripts/lib/verify-state.sh`, `scripts/lib/media-tier-only.sh`, `.claude/hooks/stop-verify.sh`, `.claude/hooks/session-start.sh`, `scripts/tests/test-verify-tiers.sh`, `scripts/tests/test-stop-hook.sh`, `scripts/tests/test-session-start.sh`.
- Untouched: `scripts/dev-container.sh`, `.github/workflows/verify.yml`, `scripts/tests/make-fixture.sh`, `scripts/tests/test_evidence.py` (no case broke).
- No push, merge, rebase or branch switch. The shared development container was left running.

### Requirements

- AVE-REQ-097 — Verification gates that cannot pass as placeholders — B1 part of AC-2, AC-3, AC-4 done; open on this branch: part 6 blocking 1 (track B2) — proposed status `in-progress` until the three tracks are merged.
- AVE-REQ-096 — Isolated bounded tasks and independent review — B1 part of AC-4 done — proposed status `in-progress` (blocking findings 1 and 2 of part 7 are the lead's).
- AVE-REQ-098 — Persistent progress and bounded autonomous continuation — B1 part of AC-2, AC-4 done — proposed status `in-progress` (blocking 1 of part 8 is the lead's).

### Dispositions per finding

| Finding | Disposition | Files | Named case (suite) |
|---|---|---|---|
| Part 6 blocking 2 (caller variables: `PYTHONUSERBASE`, `UV_ENV_FILE`) | fixed | `scripts/verify.sh` (`in_named_set`, `clean_environment`, `environment_is_named`), `scripts/verify.d/20-backend.sh` (`--no-env-file`) | tiers: "the steps see the named set, the run's own variables and no other name"; "the run sets its own Python and pytest variables and passes on the values of the named set"; "an exported function of the caller stands in for no command of a step"; "no step loads a module from a user site directory" (with its control case); "an environment entry that the shell cannot unset fails the run before any step"; "every uv call of the backend steps passes --no-env-file" |
| Part 6 blocking 3 (`ident`, fsmonitor) | fixed, with an extension of the brief's decision (deviation 1) | `scripts/lib/verify-state.sh` (`vstate_listing`, `vstate_entry`, `vstate_fingerprint`; `vstate_blind` removed) | stop-hook, section "local Git states leave an edit visible in the fingerprint": seven states (skip-worktree, assume-unchanged, `.git/info/exclude`, `core.excludesFile`, clean filter, ident attribute, fsmonitor hook), five checks each; section "the fingerprint reads bytes, executable bits and index modes" |
| Part 6 blocking 4 (stand-in covers `ave.proc` only) | fixed in code; the sentence is the lead's (text below). A tool named by an absolute path is stated as a limit | `scripts/verify.d/20-backend.sh` (`fast_pytest`), `scripts/lib/media-tier-only.sh` (header) | tiers: "the fast tier's tests resolve ffmpeg on PATH to a stand-in that exits 1" (and ffprobe); "the media tier's tests resolve ffmpeg on PATH outside the stand-ins" (and ffprobe) |
| Part 6 non-blocking 2, variables (survivors V9, V10, V10c, V18, V19) | fixed | `scripts/tests/test-verify-tiers.sh` | tiers: the name comparison; each of the five names passed by the caller (mutants V2d to V2h) |
| Part 6 non-blocking 2, line ends (survivor S8) | fixed | `scripts/tests/test-stop-hook.sh` | stop-hook: "one CRLF line end among LF line ends changes the fingerprint" |
| Part 6 non-blocking 3, the step | fixed | `scripts/verify.sh` (`check_no_ignored_sources`) | tiers: "a repository that Git cannot read fails the ignored-file step"; "a listing that Git cannot produce fails the ignored-file step"; "a directory without a repository skips the ignored-file step" |
| Part 7 non-blocking 1 (inherited `AVE_HEAVY_LOCK_HELD=1` fails open) | fixed | `scripts/verify.sh` (`hold_heavy_lock`) | tiers: "AVE_HEAVY_LOCK_HELD=1 without flock fails before any step"; "... with a lock file that cannot be opened fails before any step"; "... with a lock that flock cannot test fails before any step" |
| Part 8 blocking 2 (state content asserted for startup only) | fixed | `scripts/tests/test-session-start.sh` (`every`) | session-start: every content check runs per source `startup`, `resume`, `compact` (branch line, 8 commit lines, last verification, PROGRESS.md block, uncommitted list, capped list) |
| Part 8 non-blocking 7 (counter not read back) | fixed | `.claude/hooks/stop-verify.sh` (`count_failed_attempt`) | stop-hook: "the counter path is a directory: a fresh stop blocks once, a continued stop releases" |
| Part 8 non-blocking 8 (comment on a limit of 1) | fixed (comment and header line) | `.claude/hooks/stop-verify.sh` | none: a comment |
| Part 8 non-blocking 11 (whose runs `last-result` records) | fixed (header); the injected line for the empty record now reads "none recorded by the Stop gate" (deviation 6) | `scripts/lib/verify-state.sh`, `.claude/hooks/session-start.sh` | session-start: "no verification recorded" asserts the full line |

### Mutation list

Harness: one fresh copy of the tree per mutant under the container's `/tmp`, one string swap, the suite named below. Run 1: 58 mutants against the three suites. Run 2: the 24 mutants of `verify-state.sh` and `stop-verify.sh` again, against the final `test-stop-hook.sh`. Controls on the final tree: tiers 65/0, stop hook 145/0, session start 56/0. After run 2 I changed comment lines only in `scripts/lib/verify-state.sh` and `scripts/tests/test-stop-hook.sh`; a comparison of the non-comment lines before and after shows them identical.

Killed, with the first failing case:

- `scripts/verify.sh` against `test-verify-tiers.sh`: V1 functions of the caller stay → "an exported function of the caller stands in for no command of a step". V2a `PYTHONUSERBASE`, V2b `UV_ENV_FILE`, V2d `PYTHONOPTIMIZE`, V2e `PYTHONHOME`, V2f `GIT_INDEX_FILE`, V2g `GIT_COMMON_DIR`, V2h `ENV`, V2i an arbitrary name joins the named set → "the steps see the named set, the run's own variables and no other name". V2c `AVE_FFMPEG`/`AVE_FFPROBE` join → that case and "the media tier's tests see the real media tools, whatever the caller named". V3a `TZ`, V3b `UV_CACHE_DIR` leave → the name comparison. V3c `AVE_HEAVY_LOCK_HELD` leaves → "a caller that holds the lock sets AVE_HEAVY_LOCK_HELD=1: no second lock". V3d the shell's own names leave → 56 cases. V4 nothing unset → 56 cases. V5 `OLDPWD` stays → the name comparison. V6a no `PYTHONNOUSERSITE` → "no step loads a module from a user site directory". V6b no `PYTHONSAFEPATH`, V6c no `PYTEST_DISABLE_PLUGIN_AUTOLOAD` → "the run sets its own Python and pytest variables ...". V7 `VERIFY_TIER` reaches the steps → "VERIFY_TIER selects the tier". V8 no check of the names → "an environment entry that the shell cannot unset fails the run before any step". V9 read-only variables stay exported → the name comparison. V10a claim never tested → "AVE_HEAVY_LOCK_HELD=1 while nobody holds the lock fails before any step". V10b untestable lock counts as held → "... with a lock that flock cannot test ...". V10c missing flock unreported → "... without flock ...". V10d unopenable lock unreported → "... with a lock file that cannot be opened ...". V11a failing Git is a skip → "a repository that Git cannot read fails the ignored-file step". V11b failed listing passes → "a listing that Git cannot produce fails the ignored-file step". V12 never cleaned → 56 cases.
- `scripts/verify.d/20-backend.sh` against `test-verify-tiers.sh`: B1 no `--no-env-file` → "every uv call of the backend steps passes --no-env-file". B2 no stand-in on `PATH` → "the fast tier's tests resolve ffmpeg on PATH to a stand-in that exits 1". B3 stand-ins outlive the step (three lines) → "the media tier's tests resolve ffmpeg on PATH outside the stand-ins". B4 the two variables unset → "the fast tier's tests see media tools that refuse to run".
- `scripts/lib/verify-state.sh` against `test-stop-hook.sh`: S1 no `--no-filters` → "clean filter ...: the edit changes the fingerprint" (six cases, ident and line ends among them). S2 no untracked files → "untracked file invalidates the cache". S3 `--exclude-standard` → "file hidden by .git/info/exclude: the edit changes the fingerprint". S4 executable bit unread → "a file that lost its executable bit changes the fingerprint". S5 index mode unread → "another mode in the index changes the fingerprint". S6 missing file gives no fingerprint → "a deleted tracked file changes the fingerprint". S7 link text unread → "another link text changes the fingerprint". S8 gitlink fingerprinted → "a tree with a gitlink in its index has no fingerprint". S9 embedded repository fingerprinted → "a tree holding an embedded repository has no fingerprint". S10, S11, S12 (leading quote, line feed, final carriage return) → "a path that no line can name leaves the tree without a fingerprint (...)", one each. S13a, S13b incomplete or failed listing accepted → "a repository whose index Git cannot read has no fingerprint". S14a, S14b → "GIT_CONFIG_COUNT of the caller changes no fingerprint", "GIT_CONFIG_PARAMETERS ...". S17 no change to the root → "the fingerprint is the whole tree's from a directory below the root". S18 Windows branch removed → "on a host without mode bits every regular file counts as executable". S19 content unhashed → 46 cases. S20 `GIT_DIR` kept → "GIT_DIR and GIT_WORK_TREE of another repository do not redirect the gate".
- `.claude/hooks/stop-verify.sh`: H1 no read-back → "the counter path is a directory ... (222)".
- `.claude/hooks/session-start.sh` against `test-session-start.sh`, the three mutants of part 8: SS10 (no state on compact) → 9 cases, SS11 (no state on resume) → 9 cases, SS12 (state on startup only) → 18 cases.

Survived, 2 of 58, in both runs:

- S15, `| LC_ALL=C sort -z` removed. Git emits both listings in path order, so one Git gives one order with and without the sort. I have no construction that separates them.
- S16, `-c core.fsmonitor=false -c core.untrackedCache=false` removed. Measured: under an fsmonitor hook that reports no change plus the untracked cache, `git status --porcelain` is empty after a new untracked file appears and after a tracked edit, and `git ls-files --others` lists the file with and without the two settings. Measured on Git 2.55.0 (container) and Git 2.55.0.windows.3 (host). CI's Git is unmeasured.

Both stay in the code because the brief's decision names them. Under the rule "every rule gets a named case that fails without it" they are uncovered.

A case killed by no mutant: "untracked cache under an fsmonitor hook that reports no change" (five checks, stop-hook suite). It passes on the fingerprint of the base commit too. It records Git's behavior and evidences no rule; its comment says so. The lead may drop it.

Baseline, no one-line mutant: `scripts/lib/verify-state.sh` of the base commit against the final suite fails 17 checks. Reading them: ident (2) and fsmonitor (2) reproduce blocking finding 3 (fingerprint unchanged, gate reuses its pass). `GIT_CONFIG_COUNT` and `GIT_CONFIG_PARAMETERS` (2) show a real difference. The five index-flag, ignore-rule and filter cases fail there because the base commit gave no fingerprint, which already kept evidence stale: for those the contract changed, no hole closed. The rest (index mode, three odd paths, subdirectory, Windows stand-in) are behavior this commit adds.

### Commands run and results

- `git rev-parse HEAD` before any change → `41973c503730a0d017fc2d319e8cd33cd02e8c60`.
- `./scripts/verify.sh --tier release` on the committed tree → exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`; `124 passed, 84 deselected`; `84 passed, 124 deselected in 274.20s`; CHECKER 822/0, BASELINE 213/0, STOP HOOK 145/0, SESSION START 56/0, VERIFY TIERS 65/0, PROBE 28/0; run `20261006T103256Z-3876879`. An earlier release run passed on the tree before a last comment correction; that correction changed the fingerprint, so I ran the tier again before the commit.
- `./scripts/verify.sh` (fast) → exit 0, 11 of 11.
- `./scripts/dev-container.sh bash scripts/tests/test-verify-tiers.sh` → 65/0; `test-stop-hook.sh` → 145/0; `test-session-start.sh` → 56/0.
- Fingerprint of the worktree, `. scripts/lib/verify-state.sh && vstate_fingerprint`: Git Bash `5807ea318f07b5ec57822ccda800eb066c3b9ee8`, container the same, manifest of the release run the same; unchanged after the commit. Also equal on both sides with a temporary untracked file present (removed afterwards) and on the main checkout (read only).
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --tier release` → exit 0, `Freshness: FRESH`, before and after the commit.
- The same with `--require-complete` → exit 1: `AC-4 ... scripts/tests/run.sh ... — 1 tagged test(s) did not run`. This is part 6 blocking 1, track B2, open on this branch.
- `git diff --check` → exit 0; no CR in the diff; `git status --porcelain` empty after the commit.
- Timing of the fingerprint on this checkout: 2.1 s under Git Bash (base commit 2.2 s), 3.9 s in the container (base commit 7.9 s).

### Proposed text for lead-owned documents

`docs/requirements/AVE-REQ-097-*.md` § Edge cases:

- Line 47 → "A local state of the repository that hides an edit from Git (an index flag such as assume-unchanged, skip-worktree or fsmonitor-valid, a filter or ident attribute, a line-end conversion, an ignore rule outside the `.gitignore` files, an fsmonitor hook, Git configuration that the caller adds through `GIT_CONFIG_COUNT` or `GIT_CONFIG_PARAMETERS`) → changes no entry of the fingerprint: an entry holds the mode of the index entry or `untracked`, the executable bit and the raw bytes of the working file, for every index entry and every untracked file that no `.gitignore` file ignores. The edit changes the fingerprint, the Stop gate runs `verify.sh` and recorded evidence reads stale. A tree with a gitlink, an embedded repository, a listed path that begins with a double quote, holds a line feed or ends with a carriage return, a listed file that cannot be read, or a failing Git listing → keeps no fingerprint: the Stop gate runs `verify.sh` there and no evidence is fresh. A symbolic link enters with its link text; the file it points to outside the listed paths is local state (AC-2, AC-3)."
- Line 52 → "A test without the `media` marker that calls FFmpeg or FFprobe through `ave.proc` or by name on `PATH` → fails in the fast tier: the fast tier's pytest step points `AVE_FFMPEG` and `AVE_FFPROBE` at a stand-in that exits 1 and puts a directory with `ffmpeg` and `ffprobe` stand-ins first on `PATH`. A test that names a media tool by an absolute path reaches the real tool: `verify-requirement` § 8 judges that form (AC-3, inspection)."
- Line 55, first clause → "A variable of the caller outside the named set (`PATH`, `HOME`, `USER`, `LOGNAME`, `TMPDIR`, `LANG`, `LC_ALL`, `TZ`, `UV_PROJECT_ENVIRONMENT`, `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR`, `AVE_HEAVY_LOCK`, `AVE_HEAVY_LOCK_HELD`) or an exported shell function → reaches no step: `verify.sh` removes them before its steps, sets `PYTHONSAFEPATH`, `PYTHONNOUSERSITE` and `PYTEST_DISABLE_PLUGIN_AUTOLOAD`, and starts `uv` with `--no-env-file`; `GIT_DIR`, `GIT_CONFIG_COUNT`, `PYTHONPATH`, `PYTHONUSERBASE`, `PYTEST_ADDOPTS`, `UV_ENV_FILE`, `AVE_FFMPEG`, `AVE_FFPROBE`, `AVE_VAR_DIR` and `BASH_ENV` are among them. An environment entry whose name is no shell identifier → fails the run before any step." The rest of the line (caches, shadow configuration, plugin, selection) stands.
- Line 58, add → "a limit of 1 releases at the first failure".
- Line 66, add to the list of local state → "the files under `HOME` (the user's Git and uv configuration), the values of the variables of the named set, and the shell with what acts before the first line of `verify.sh` (`SHELLOPTS`, `BASHOPTS`, `BASH_ENV`, a function exported under the name of a shell builtin)".

§ Verification strategy: AC-2, `test-stop-hook.sh` → "index flags, local ignore rules, a clean filter, an ident attribute and an fsmonitor hook each leave an edit visible in the fingerprint while Git takes the tree for the committed one; CRLF and mixed line ends, the executable bit, the index mode, a deleted file and a link text change it; a gitlink, an embedded repository, a path that no line of `git hash-object --stdin-paths` names and an unreadable index leave no fingerprint"; `test-verify-tiers.sh` → "the names a step sees equal the named set plus the run's own variables, under a caller that sets 33 other variables and an exported function". AC-3 → "the fast tier's pytest step resolves `ffmpeg` and `ffprobe` on `PATH` to stand-ins that exit 1; the media tier's step resolves them outside the stand-ins". AC-4 → "a Git command that fails inside a work tree fails the ignored-file step; a directory without a repository is the one skip".

§ Implementation evidence: line 79 → "the steps start from a named set of variables (every other exported variable and every function of the caller removed, a name the shell cannot unset fails the run)"; line 82 → add "and stand-ins named `ffmpeg` and `ffprobe` first on `PATH`"; line 83 → "the tree fingerprint: one entry per index entry and per untracked file that no `.gitignore` file ignores, with index mode, executable bit and raw content hash; none for a tree with a gitlink, an embedded repository or a path that no line names"; line 84 → add "the failed-attempt counter is read back".

`docs/requirements/AVE-REQ-096-*.md` § Verification strategy AC-4, after "fails the run before any step" → "and so does the same variable without `flock`, with a lock file that cannot be opened, and with a lock that `flock` cannot test".

`docs/requirements/AVE-REQ-098-*.md` § Verification strategy: AC-2 stands as written and now holds (each content check runs for `startup`, `resume` and `compact`). AC-4, add → "a counter that is stored and reads back as another value still ends in a release".

`docs/ARCHITECTURE.md`: § Testing strategy item 6, last sentence → "the run first confirms that the lock is held and fails before any step when nobody holds it, when `flock` is missing, or when it cannot open or test the lock file." § Verification pipeline item 2 → "unit tests (their media tools, through `ave.proc` and by name on `PATH`, are stand-ins that exit 1, so the fast tier renders nothing)" and "A run starts its steps from a named set of variables (header of `scripts/verify.sh`), loads no pytest plugin by itself, ...". Item 3 → "The fingerprint is made of the bytes, the executable bit and the index mode of every listed path, so no index flag, attribute, local ignore rule or fsmonitor state hides an edit from it; a tree with a gitlink, an embedded repository or a path that no line of `git hash-object --stdin-paths` names keeps no fingerprint, so nothing is fresh there." Item 5 → "the result of the last Stop-gate verification".

`docs/ASSUMPTIONS.md`: ASM-023, sentence on variables → "`verify.sh` starts its steps from a named set of variables and reads no cache from the tree". New entries proposed:
- Fingerprint entry — assumption: an entry holds the executable bit of the working file beside the index mode, and a Windows host counts every regular file as executable — reason: on Linux the index mode alone leaves `chmod -x` of a script outside the fingerprint; the container reads a Windows checkout with every file executable — impact: one value on host and container; on a Linux checkout a mode change reruns the gate.
- Staging — assumption: staging a new file changes its entry from `untracked` to its index mode — reason: the brief's decision — impact: a pass recorded with an unstaged new file is stale after `git add`; stage new files before the run that should outlive the commit.
- Named set — assumption: `AVE_VAR_DIR`, proxy variables, `XDG_*`, `CI` and `GITHUB_*` reach no step — reason: outside the three files the set derives from — impact: the locked backend environment exists before `verify.sh` runs wherever the network needs a proxy; a host that needs the var root elsewhere adds the variable to the set and to the tiers suite.

`.gitignore` lines 6-7 (lead-owned, false after this commit) → "It is ignored here, in the tree: with a rule in .git/info/exclude or a global ignore file its files would enter the fingerprint (scripts/lib/verify-state.sh)."

### Deviations and discovered work

Deviations from the brief or from my operating rules:

1. Executable bit in the fingerprint entry (brief item 2 names the index mode alone). With the index mode alone, `chmod -x` on a tracked script leaves the fingerprint unchanged on Linux while `verify.sh` fails, and the existing case "FAIL shows the log path (tree differs again after the fix)" of the session-start suite breaks. I added the bit as a superset. Recommended resolution: confirm it, or name the rule that should cover a lost executable bit.
2. Further trees without a fingerprint beyond gitlink and embedded repository: a listed path with a leading double quote, a line feed or a final carriage return; an unreadable listed file; a failing Git listing. Each fails closed.
3. `environment_is_named` is an addition: bash passes on environment entries whose names are no shell identifiers and cannot unset them (measured), so the run fails before any step when one is present.
4. Placement: the function purge and `clean_environment` run at the top of `verify.sh`, before the file assigns a variable, on every host except a Windows host (which passes the run to the container). The brief describes one function.
5. `scripts/lib/verify-state.sh` also unsets `GIT_CONFIG_COUNT` and `GIT_CONFIG_PARAMETERS` at source time, for the hooks and `evidence.py show`.
6. `.claude/hooks/session-start.sh` prints "none recorded by the Stop gate (run ./scripts/verify.sh)" for an empty record; the brief asked for the header of `verify-state.sh` only.
7. Skill precondition 3: the dependencies AVE-REQ-093 and AVE-REQ-094 are `in-progress`. I proceeded because the brief assigns this fix round with that state recorded in the review reports.
8. No edit to `## Implementation evidence`: the brief forbids the three requirement files; the text is above.

Unverified:

- CI. No GitHub run has executed the new environment cleaning. My expectation that `PATH` and `HOME` suffice for uv on the runner is reasoning from the workflow file, not an observation. Watch the first run of the merge.
- bash 3.2. The header of `verify-state.sh` keeps its claim "Compatible with bash 3.2". I tested bash 5.2 (container) and 5.3 (Git Bash) only.
- The statement that host and container print one value rests on this host: its container reads the checkout through a mount that shows every file as mode 777.

A correction of my own earlier reasoning: I assumed the change to the tree root preserved the behavior of the base commit. The baseline run shows the base-commit fingerprint fails the subdirectory case. The new code gives the whole tree's value from a subdirectory (tested); I did not investigate the old behavior.

Side effects outside the task:

- I overwrote `mutate.py` in the session scratchpad. The Write tool reported "updated", so a file of that name existed, and it was not mine (`mutate.sh`, `mutate.log`, `mutate2.log` beside it suggest an earlier harness). Its earlier content is gone and I cannot restore it; the file now holds the B1 harness. I also wrote `mutants-1.log`, `mutants-2.log`, `release-1.log` and `release-2.log` there by redirection; I cannot rule out that one of those names existed before.
- One log went to Git Bash's `/tmp` early on and was deleted.

Discovered work, proposed follow-ups (parent AVE-FEAT-019):

- Symbolic links: a link among the sources that points outside the listed paths lets its target change with the fingerprint unchanged. Follows the brief; the header states it. Proposal: fail the step "No ignored file among sources, tests and scripts" on such a link, or give the tree no fingerprint.
- `scripts/evidence.py` `_environment_digest` starts `uv run` without `--no-env-file` (track B2's file). Inside `verify.sh` the variable is gone; `evidence.py show` by hand still reads `UV_ENV_FILE`.
- The Git configuration of the repository and of the user (`core.ignoreCase`, for one) still shapes which untracked files the listing names; only configuration added through the environment is excluded.
- Files that a `.gitignore` file ignores outside `backend/src`, `backend/tests`, `scripts` and `.claude/hooks` stay outside the fingerprint and outside the ignored-file step, as before this commit.
- `backend/tests/unit/test_fast_tier_media_tools.py` (outside my paths): its docstring names the two variables only.

Pre-existing, unrelated: the suites print Git's CRLF warning for `docs/ASSUMPTIONS.md` of the fixture on stderr.
