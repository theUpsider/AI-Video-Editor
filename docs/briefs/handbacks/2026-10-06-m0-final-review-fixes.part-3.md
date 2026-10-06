# Handback — M0 final review fixes, part 3: track B2, evidence tool, suite runner, plugin and checker (AVE-REQ-097, AVE-REQ-096, AVE-REQ-098)

Brief: [2026-10-06-m0-final-review-fixes.md](../2026-10-06-m0-final-review-fixes.md). Run `wf_5cd13360-464` ([script](../../workflows/m0-final-review-fixes.js)), branch `m0-final-fixes-b2` from `41973c5`. The report below is the writer's, unedited apart from local paths and the level of its headings. The lead applied the proposed texts ([ASM-013](../../ASSUMPTIONS.md), [ASM-018](../../ASSUMPTIONS.md), [ASM-019](../../ASSUMPTIONS.md), [ASM-030](../../ASSUMPTIONS.md), [ASM-031](../../ASSUMPTIONS.md)) and moved the restart of `scripts/evidence.py` before its first import.

## Report

### Result: COMPLETE

Track B2 of `docs/briefs/2026-10-06-m0-final-review-fixes.md` (evidence tool, suite runner, plugin, checker). Every finding of the track is fixed with a named case, or stated as a limit where the brief decides so. The release tier passed on the final tree, and all 57 one-line mutants fail a named case.

### Branch and commit

- Branch: `m0-final-fixes-b2` — commit `9da0ea9b96af8eeba99512452595115150c4c9e6`; its parent is the base `41973c503730a0d017fc2d319e8cd33cd02e8c60`.
- `git rev-parse HEAD` printed exactly the base hash before the first change.
- Worktree: `.claude/worktrees/m0-final-fixes-b2`; the paths below are relative to it.
- The tree is clean after the commit. Nothing was pushed, merged or rebased.

### Requirements

- AVE-REQ-097 — Verification gates that cannot pass as placeholders — this track's part of AC-2, AC-3, AC-4 done; open: none in this track — proposed status `verification` once tracks A, B1 and B2 are merged and the release tier passes on the merge.
- AVE-REQ-096 — Isolated bounded tasks and independent review — this track's part of AC-1 (and one AC-2 case) done; open: none in this track — proposed status `verification` after the merge.
- AVE-REQ-098 — Persistent progress and bounded autonomous continuation — this track's part of AC-1, AC-3, AC-4 done; open: none in this track — proposed status `verification` after the merge.

### Findings (report part and number → disposition, files, named case)

Unit cases are in `scripts/tests/test_evidence.py` (class `EvidenceTests`), checker cases in `scripts/tests/test-checker.sh`, plugin cases in `backend/tests/unit/test_evidence_plugin.py`.

1. **Part 6, blocking 1 (the runner carries a tag and never has a suite result) — fixed.**
   - `scripts/tests/run.sh`: the header holds no criterion tag and says that its `run_suite <file>` lines are the list of suites.
   - `scripts/evidence.py`: `listed_suites()` reads those lines (one per line, at the start of the line). `tooling_files()` is the listed suites plus `test_*.py`. `unowned_tag_problems()` reports a comment tag in any other file of `scripts/tests/` (subdirectories included, `__pycache__` directories left out). `collect()` raises on such a tag, so `record` and `check-done` end with status 2 and `file:line`.
   - Cases, tagged AVE-REQ-097 AC-4:
     - `test_a_tag_in_a_file_no_runner_runs_stops_record_and_check_done` — the runner, a fixture builder, a suite named only in a comment of `run.sh`, a Python helper, a file in a subdirectory, a file that is no UTF-8 text; controls for text outside a comment line and a bytecode directory.
     - `test_every_comment_tag_of_the_real_tooling_directory_has_a_runner` — the case on the real `scripts/tests/`: `run.sh` has no tag, no unowned tag exists, the tooling files equal the listed suites plus the unit-test files, and with a passing result for each no problem says `did not run` in the release tier; without one result the problem appears.
     - `test_run_sh_records_each_listed_suite_and_a_tagged_file_it_never_runs_stops_the_tool` — the real runner copied with stub suites.
   - Effect on the working tree: `show AVE-REQ-097 --require-fresh --require-complete --tier release` exits 0 on the release run of the final tree (it exited 1 at `2df637f`).
2. **Part 6, non-blocking 2 (a failed fresh run of a lighter tier; mutant E21) — fixed by a case.** `test_a_failed_fresh_run_of_a_lighter_tier_refuses_completeness` (AVE-REQ-097 AC-4): a passing fresh release manifest beside a failed fresh fast manifest gives exit 1 with `Completeness: the run of tier fast FAILED`; `--require-fresh` alone stays 0; a failed fast run of another tree decides nothing.
3. **Part 6, non-blocking 3 (the plugin passes when Git fails) — fixed.** `backend/tests/evidence_plugin.py`: `_in_repository()` looks for a `.git` entry in the tree's directory or above it. Inside a repository, `git check-ignore` ending with a status other than 0 or 1, or a Git that does not start, raises a usage error. A tree without a repository is the one skip. Case: `test_a_git_that_fails_inside_a_repository_stops_the_session` (module mark AVE-REQ-097 AC-2, AC-4): `GIT_CONFIG_COUNT=abc` gives exit 128 and a usage error, a `PATH` without Git gives a usage error, and the same variable in a tree without a repository changes nothing.
4. **Part 6, non-blocking 4 (`SHELLOPTS` in the `env` block) — fixed for check 12.** `env` keys `SHELLOPTS`, `BASHOPTS`, `BASH_ENV`, `ENV` fail. Cases `settings env sets <KEY>` (four) and `settings env with other variables accepted` (AVE-REQ-097 AC-3). The Edge-case sentence that names these variables as trusted shell state for the caller is proposed below.
5. **Part 6, non-blocking 7, item 1 (unit-test tags bind by method name) — fixed.** `scripts/evidence.py`: `qualified_tests()` (from the syntax tree), `tagged_tests()` and `started_test()` bind a tag to `Class.test_x`; a started test is named by the class that defines the method. Cases in `test_the_unit_test_step_fails_on_every_test_that_did_not_pass`: `tag above a never-collected test whose name a test of another class carries`, `tag above a module-level function that no loader collects`, and the passing control `a tag above a test that a test class inherits and runs`.
6. **Part 6, non-blocking 7, item 3 (`record` without `var/verify`) — fixed.** `record()` creates the directory; when it cannot be created the command ends with status 2 (`evidence.py: cannot create the evidence directory …`) and writes no manifest; pruning tolerates a missing `runs/`. Case: `test_record_creates_the_evidence_directory_or_ends_with_a_tool_error` (AVE-REQ-097 AC-2).
7. **Part 5, blocking 3 (the hint in `scripts/evidence.py`) — fixed.** The canonical-form problem line ends `python3 -I -B scripts/check_baseline.py lists every problem`. Asserted in `test_a_spelling_that_hides_done_or_a_criterion_fails_the_done_gate` (AVE-REQ-097 AC-4, AVE-REQ-093 AC-4).
8. **Part 7, non-blocking 3 (check 11) — fixed, with the input-revision forms stated as a limit.**
   - HTML comments are removed before a section is judged, outside fenced blocks and code spans (`strip_comments_outside_spans` in `scripts/check-project-control.sh`). Cases (AVE-REQ-096 AC-1): `brief section holding only an HTML comment`, `brief requirement ID only in an HTML comment`, `brief requirement ID in a comment beside other text`, `brief heading inside a multi-line HTML comment`, `brief section text inside a multi-line HTML comment`, `input revision: commit only in an HTML comment`; controls `brief text beside an HTML comment counts`, `brief comment marker inside a code span opens no comment`, `brief fence marker inside an HTML comment opens no fence`.
   - Entries of `docs/briefs/`: cases `brief with another extension`, `brief in another subdirectory`, `hidden brief`, `file in place of the drafts directory`, `directory named like a brief`; controls `draft without sections left alone`, `folder files of an operating system passed over`.
   - `handbacks/`: cases `hidden handback of a brief`, `hidden handback without a slug`, `directory named like a handback`.
   - Input-revision forms that still count as a commit (probed on the final checker, each exit 0):
     - a hex token delimited by `/`, `.` or `:` inside a longer name (`feature/abcdef1`, `fix.1234567`, `a/abc1234/b`, `commit:abc1234`);
     - a branch named in hex (`deadbeef`);
     - a word of seven or more hex letters (`effaced`, `defaced`);
     - a compact date (`20261006`), any number of 7 to 40 digits (`1234567`), and `0000000`.
     - Still rejected: a branch name such as `ccr-af7078da-q8r8mf`, an uppercase hash, `abc1234_wip`.
     - Under Requirements an ID without a file (`AVE-REQ-999`) counts, and an ID inside a code span counts.
     - The rule is syntactic and checks no object in the repository; proposed text for ASM-018 is below.
9. **Part 8, non-blocking 6 (PROGRESS.md headings) — fixed.** Ten cases `PROGRESS without '<heading>'`, tagged AVE-REQ-098 AC-1, from a list written out in the suite.
10. **Part 8, non-blocking 9 (the Stop gate can be switched off) — fixed.** Check 12 requires type `command` and a command equal to `"$CLAUDE_PROJECT_DIR"/.claude/hooks/stop-verify.sh`. Cases (AVE-REQ-097 AC-3): `Stop command with || true appended`, `Stop command with a redirect appended`, `Stop command with text before it`, `Stop command without the project directory`, `Stop handler of type prompt`, `Stop handler without a type`.
11. **Part 8, non-blocking 10 — fixed for the forms, limit stated for the local settings file.**
    - Hook commands: 13 cases `tool hook command: <command>` on a `PreToolUse` hook, covering `while true`, `while :`, `while [ 1 ]`, `while [ -e x ]`, `until` (two forms), `for ((;;))`, `for (( i = 0; ; i++ ))`, `sleep`, `&`, `--dangerously-skip-permissions`, `--permission-mode x` and `--permission-mode=x`; controls `hook command with redirects and && accepted` and `hook command with a list loop and loop words inside names accepted` (AVE-REQ-098 AC-4).
    - Check 7: cases `PROGRESS claim: …` for `under way`, `under-way`, `still executing`, `Ongoing`, `on-going`, `runs now`; control `PROGRESS: words that only contain a claim word accepted` (AVE-REQ-098 AC-3).
    - `.claude/settings.local.json` stays unchecked; the comment above check 12 says so, and the sentence for the requirement is proposed below.

### Changes (file — purpose)

- `scripts/evidence.py` — list of suites from `run.sh`, unowned-tag rule in `collect()`, class-qualified tag binding, `record` creates `var/verify/` or ends with a tool error, hint with the isolated command, tag scan that tolerates bytes that are no UTF-8, docstring rules.
- `scripts/tests/run.sh` — header without a criterion tag; states where the list of suites is read.
- `scripts/tests/test_evidence.py` — 4 new tests, 5 new subcases, helper `_suite`; 36 tests (32 before).
- `backend/tests/evidence_plugin.py` — a failing Git inside a repository stops the session.
- `backend/tests/unit/test_evidence_plugin.py` — 1 new test; 21 tests (20 before).
- `scripts/check-project-control.sh` — check 7 wordings; check 11 comment removal, entries of `docs/briefs/`, hidden handbacks; check 12 Stop handler type and exact command, `env` keys, loop and permission-mode forms; header comments.
- `scripts/tests/test-checker.sh` — 61 new cases per awk; 272 checks on one awk (211 before), 1066 with `--all-awks` (822 before).
- `docs/PROGRESS.md` — unchanged: no line is flagged by the new wording rule.

### Mutation list (mutant → failing case)

Each mutant is one replacement in a fresh copy of the final tree under the container's `/tmp`, with its own Git repository and its own backend environment, followed by the suite. The three control runs passed (unit, checker, plugin); 57 of 57 mutants fail.

```text
scripts/tests/run.sh, scripts/evidence.py — suite: python3 -B scripts/evidence.py unittest scripts/tests
E1  run.sh carries the criterion tag again              → test_every_comment_tag_of_the_real_tooling_directory_has_a_runner; test_run_sh_records_each_listed_suite_and_a_tagged_file_it_never_runs_stops_the_tool
E2  `if unowned:` → `if False:`                          → test_a_tag_in_a_file_no_runner_runs_stops_record_and_check_done (every subcase); test_run_sh_records_…
E3  tooling_files() takes every *.sh again               → test_a_tag_in_a_file_no_runner_runs_… [the suite runner], [a fixture builder], …; test_every_comment_tag_of_the_real_…
E4  subdirectories are not scanned                       → test_a_tag_in_a_file_no_runner_runs_… [a file in a subdirectory]
E5  bytecode directories are scanned                     → test_a_tag_in_a_file_no_runner_runs_… (control after the subcases)
E6  failed fresh lighter tier ignored (reviewer's E21)   → test_a_failed_fresh_run_of_a_lighter_tier_refuses_completeness
E7  tags compared by method name only                    → test_the_unit_test_step_fails_on_every_test_that_did_not_pass [tag above a never-collected test whose name a test of another class carries], [tag above a module-level function that no loader collects]
E8  started test named by its runtime class              → test_the_unit_test_step_fails_… [a tag above a test that a test class inherits and runs]
E9  record creates no var/verify                         → test_record_creates_the_evidence_directory_or_ends_with_a_tool_error
E10 the mkdir failure is no tool error                   → test_record_creates_the_evidence_directory_or_ends_with_a_tool_error
E11 hint without -I -B                                   → test_a_spelling_that_hides_done_or_a_criterion_fails_the_done_gate (nine subcases)
E12 strict UTF-8 in the tag scan                         → test_a_tag_in_a_file_no_runner_runs_… [a file that is no UTF-8 text]
E13 pruning needs var/verify/runs                        → test_record_creates_the_evidence_directory_or_ends_with_a_tool_error
E14 `run_suite` matched anywhere in a line               → test_a_tag_in_a_file_no_runner_runs_… [a suite the runner names in a comment only]

backend/tests/evidence_plugin.py — suite: pytest tests/unit/test_evidence_plugin.py
P1  other exit statuses of git check-ignore return []    → test_a_git_that_fails_inside_a_repository_stops_the_session
P2  a Git that does not start returns []                 → test_a_git_that_fails_inside_a_repository_stops_the_session
P3  no repository test before Git is asked               → test_a_git_that_fails_inside_a_repository_stops_the_session
P4  only the tree's own directory marks a repository     → test_a_git_that_fails_inside_a_repository_stops_the_session
P5  repository test inverted                             → test_a_test_file_that_git_ignores_stops_the_session; test_a_git_that_fails_inside_a_repository_stops_the_session

scripts/check-project-control.sh — suite: bash scripts/tests/test-checker.sh
C1  check 7 without `under way`                          → PROGRESS claim: - Media-tier run under way.; … under-way since noon.
C2  check 7 without `still executing`                    → PROGRESS claim: - The review is still executing.
C3  check 7 without `ongoing`                            → PROGRESS claim: - Ongoing: the release tier of the merge.; - The on-going review of AVE-REQ-001.
C4  check 7 without `runs now`                           → PROGRESS claim: - The release tier runs now.
C5  check 11 keeps HTML comments                         → brief section holding only an HTML comment; brief requirement ID only in an HTML comment; … beside other text; brief heading inside a multi-line HTML comment; brief section text inside a multi-line HTML comment; brief fence marker inside an HTML comment opens no fence; input revision: commit only in an HTML comment
C6  comment opened inside a code span                    → brief comment marker inside a code span opens no comment
C7  no error for other entries of docs/briefs            → brief with another extension; brief in another subdirectory; hidden brief; file in place of the drafts directory; directory named like a brief
C8  a hidden *.md file read as a brief                   → hidden brief
C9  hidden entries of docs/briefs not listed             → hidden brief
C10 hidden entries of handbacks not listed               → hidden handback of a brief; hidden handback without a slug
C11 a directory named like a handback passes             → directory named like a handback
C12 folder files fail in docs/briefs                     → folder files of an operating system passed over
C13 folder files fail in handbacks                       → folder files of an operating system passed over
C14 only `while true` and `while :` known                → tool hook command: while [ 1 ]…; true; while [ -e x ]…; until false…; (until …); for ((;;))…; for (( i = 0; ; i++ ))…
C15 without `until`                                      → tool hook command: until false; do scripts/note.sh; done; (until scripts/note.sh; do :; done)
C16 without the `for ((` loop                            → tool hook command: for ((;;)); do scripts/note.sh; done; for (( i = 0; ; i++ )); …
C17 without `--permission-mode`                          → tool hook command: claude -p go --permission-mode bypassPermissions; … --permission-mode=acceptEdits
C18 loop words read inside names                         → hook command with a list loop and loop words inside names accepted
C19 type of the Stop handler unchecked                   → Stop handler of type prompt; Stop handler without a type
C20 Stop command compared by containment                 → Stop command with || true appended; … with a redirect appended; … with text before it; … without the project directory
C21 env keys matched by prefix                           → settings env with other variables accepted
C22 a file named drafts passes                           → file in place of the drafts directory
C23 a directory named like a brief read as a brief       → directory named like a brief
C24 fence opened inside an HTML comment                  → brief fence marker inside an HTML comment opens no fence
C-env-SHELLOPTS / -BASHOPTS / -BASH_ENV / -ENV (key removed from the list) → settings env sets SHELLOPTS / BASHOPTS / BASH_ENV / ENV
C-heading-1 … C-heading-10 (heading removed from PROGRESS_HEADINGS; the reviewer's C21 and C23 are numbers 8 and 6) → PROGRESS without '<that heading>' (number 7 also fails `missing PROGRESS heading`)
```

### Commands run (result)

- `git rev-parse HEAD` before changes — `41973c503730a0d017fc2d319e8cd33cd02e8c60`, equal to the base.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests` — PASS, `Ran 36 tests`, `evidence.py unittest: PASS (1 file(s))` (32 tests PASS before the change).
- `./scripts/dev-container.sh bash scripts/tests/test-checker.sh --all-awks` — PASS, `CHECKER TOTAL: pass=1066 fail=0` (mawk, gawk, original-awk, busybox); on the system awk `CHECKER TOTAL: pass=272 fail=0`.
- `./scripts/dev-container.sh bash -c 'cd backend && uv run --frozen --quiet pytest -c pyproject.toml -q -p no:cacheprovider tests/unit/test_evidence_plugin.py'` — `21 passed`; `ruff format --check`, `ruff check` and `mypy` clean.
- `./scripts/dev-container.sh ./scripts/check-project-control.sh` on the real tree — `OK: 51 required files, …, 2509 links in 208 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)`.
- `./scripts/verify.sh` — `verify.sh: PASS — tier fast (11 of 11 steps passed)`; `125 passed, 84 deselected`.
- `./scripts/verify.sh --tier release` on the final tree, before the commit — `verify.sh: PASS — tier release (13 of 13 steps passed)`:
  - 36 tooling unit tests; `125 passed, 84 deselected`; `84 passed, 125 deselected in 306.47s`;
  - CHECKER 1066/0, BASELINE 213/0, STOP HOOK 98/0, SESSION START 31/0, VERIFY TIERS 48/0, PROBE 28/0.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --require-complete --tier release` — exit 0, `Freshness: FRESH`, AC-1 to AC-4 `passed` with no `did not run` note; same result after the commit. The manifest names the base commit `41973c503730` with uncommitted changes, because the run preceded the commit; the fingerprint equals that of the committed tree.
- `… show AVE-REQ-098 AVE-REQ-096 --require-fresh --tier release` — exit 0; AVE-REQ-098 AC-1 to AC-4 `passed`; AVE-REQ-096 AC-1, AC-2, AC-4 `passed`, AC-3 `missing` (inspection only).
- Mutation driver (60 runs in the container's `/tmp`) — `SUMMARY: 60 of 60 as expected`.
- `git diff --check` — clean; every changed file `i/lf w/lf`; `git status --short` empty after the commit.

### Proposed text for lead-owned documents

`docs/requirements/AVE-REQ-097-…md`, § Edge cases:

```text
Replace "A tooling suite that `scripts/tests/run.sh` never runs → gives no evidence; a tooling suite or unit-test file that fails → counts against every criterion it tags (AC-4)." by:
- A comment tag in a file of `scripts/tests/` that is neither a suite `scripts/tests/run.sh` lists (one `run_suite <file>` line at the start of a line) nor a `test_*.py` file of that directory → stops `record` and `check-done` with the file and line, in every tier: the runner itself, a fixture builder, a suite named only in a comment of `run.sh`, a Python helper, a file in a subdirectory and a file that is no UTF-8 text have no suite result, so no run could evidence such a tag. Files inside a `__pycache__` directory are left out. A listed suite or a unit-test file that fails → counts against every criterion it tags (AC-4).

Add to "A test file or `conftest.py` that Git ignores → stops the pytest session …":
  Inside a repository (a `.git` entry in the tree's directory or in one above it) a Git that ends `git check-ignore` with another status than 0 or 1, or that does not start, stops the session too; a tree without a repository is the one case in which Git is asked nothing (AC-2, AC-4).

Replace "A settings file without the Stop gate, with a second Stop command, with `disableAllHooks` or with a `CLAUDE_VERIFY_` variable → fails check 12 (AC-3)." by:
- A settings file without the Stop gate, with a second Stop command, with a Stop handler of another type than `command`, with a Stop command that differs from `"$CLAUDE_PROJECT_DIR"/.claude/hooks/stop-verify.sh` (text before it, `|| true` or a redirect after it, another spelling of the path), with `disableAllHooks`, with a `CLAUDE_VERIFY_` variable, or with `SHELLOPTS`, `BASHOPTS`, `BASH_ENV` or `ENV` in its `env` block → fails check 12 (AC-3). Check 12 reads `.claude/settings.json`; the `timeout` of the Stop handler is judged by the diff review, and `.claude/settings.local.json` and the user-level settings are local state (last Edge case).

In the Edge case on vacuous tests, replace "tags of a unit-test file are bound to the test below them" by:
  tags of a unit-test file are bound, by class and name, to the test below them: a test of the same name in another class, or a function at module level, leaves the tag unbound and fails the file.

Add:
- `record` for a run directory outside `var/verify/` in a tree without that directory → creates it; where it cannot be created the command ends with status 2 and records nothing (AC-2).

In the last Edge case (local, unauthenticated state) add to the list: `.claude/settings.local.json` and the user-level settings, and the shell options of the caller (`SHELLOPTS`, `BASHOPTS`).
```

`docs/requirements/AVE-REQ-097-…md`, § Verification strategy and § Implementation evidence:

```text
AC-2, add to the `scripts/tests/test_evidence.py` list: `record` creates the evidence directory or ends with a tool error; add to the `backend/tests/unit/test_evidence_plugin.py` list: a Git that fails or does not start inside a repository stops the session, and a tree without a repository asks nothing.
AC-3, replace the check 12 clause by: `scripts/tests/test-checker.sh`: check 12 fails a settings file without the Stop gate, with a second Stop command, a Stop handler of another type, a Stop command with text before or after the registered one, `disableAllHooks`, a gate variable, or `SHELLOPTS`, `BASHOPTS`, `BASH_ENV` or `ENV` in `env`.
AC-4, add to the `scripts/tests/test_evidence.py` list: a comment tag in a file no runner runs stops `record` and `check-done` with file and line, and on the real `scripts/tests/` every tagged file is a listed suite or a unit-test file, so no tag reads `did not run` once each file has a passing result; a passing fresh release run beside a failed fresh fast run fails `show --require-complete`; a unit-test tag binds to its test by class and name.
Replace "a suite `run.sh` never runs gives no evidence" by "a tagged suite `run.sh` does not list stops the evidence tool".

Implementation evidence, `scripts/evidence.py` line: add "a comment tag outside the tooling test files stops `record` and `check-done`; `record` creates `var/verify/`"; plugin: add "a Git that fails inside a repository stops the session"; check 12 line: "the Stop gate is registered once, as a `command` handler with exactly the registered command, and no setting switches it off or changes the hooks' shell (AC-3)"; `scripts/tests/run.sh` line: add "the runner holds no tag, and its `run_suite` lines are the list of suites `scripts/evidence.py` reads; unit-test tags bound by class and name". The Tests line is unchanged.
```

`docs/requirements/AVE-REQ-096-…md`:

```text
§ Edge cases, add:
- A heading, a requirement ID, a commit or the only text of a section inside an HTML comment → absent for check 11, which removes HTML comments outside fenced blocks and code spans before it judges a section (AC-1, AC-2).
- An entry of `docs/briefs/` that is neither a visible `*.md` brief, `README.md`, the directory `drafts/` nor the directory `handbacks/` (another extension, a hidden file, another subdirectory, a file named `drafts`, a directory named like a brief) → fails check 11; an entry of `handbacks/` that is hidden or is a directory fails too; the folder files of an operating system (`.DS_Store`, `Thumbs.db`) are passed over (AC-1).
- An input revision whose hex token is no commit → outside check 11, a syntactic rule ([ASM-018](../ASSUMPTIONS.md)): the reader of the brief and the task's own base check (`git rev-parse HEAD` equals the base commit) judge it (AC-2, inspection).

§ Verification strategy AC-1, add to the cases `scripts/tests/test-checker.sh` covers: HTML comments (a section holding only a comment, an ID or a commit only in a comment, a heading or section text inside a multi-line comment; text beside a comment, a comment marker inside a code span and a fence marker inside a comment are read as text), the entries of `docs/briefs/` (another extension, another subdirectory, a hidden file, a file named `drafts`, a directory named like a brief; a draft and the folder files of an operating system pass), and hidden or directory entries of `handbacks/`.

§ Implementation evidence, check 11 line: add "sections judged without HTML comments, no other entry in `docs/briefs/`, hidden handbacks rejected".
```

`docs/requirements/AVE-REQ-098-…md`:

```text
§ Edge cases, replace "check 7 fails on a PROGRESS.md line that says work is running, underway or in flight" by:
  check 7 fails on a PROGRESS.md line with one of the wordings `running`, `underway`, `under way`, `in flight`, `ongoing`, `still executing` or `runs now` (any letter case; spaces or hyphens between the words; `nothing is running`, `not running` and `no longer running` pass); the rule knows this list, and the commit review and `verify-requirement` judge any other wording of the same claim

§ Edge cases, replace the list of hook-command forms by:
  a hook command with the shell word `while` or `until` (a loop word inside a file name or an option, as in `wait-until-ready.sh` or `--meanwhile`, is none), a `for ((` loop, `sleep`, `nohup`, `disown`, `setsid`, a background `&`, `--dangerously-skip-permissions` or `--permission-mode`, and a hook entry with `"async": true`; the rule knows this list and reads `.claude/settings.json`: a loop or a bypass written another way, a script the command calls, `.claude/settings.local.json` and the user-level settings are judged by the commit review and the inspection of `.claude/hooks/*.sh`

§ Verification strategy AC-1, add: `scripts/tests/test-checker.sh`: check 7 fails when any one of the ten PROGRESS.md headings is missing (one case per heading, from a list written out in the suite).
§ Verification strategy AC-3 and AC-4: use the two lists above.
§ Implementation evidence, Tests line: `scripts/tests/test-checker.sh` — AVE-REQ-098 AC-1, AVE-REQ-098 AC-2, AVE-REQ-098 AC-3, AVE-REQ-098 AC-4.
```

`docs/ASSUMPTIONS.md`:

```text
ASM-013, add to Assumption: A comment tag in any other file of `scripts/tests/` stops `record` and `check-done`; `scripts/evidence.py` reads the list of shell suites from the `run_suite <file>` lines of `scripts/tests/run.sh`. A unit-test tag binds to the test below it by class and name; an inherited test counts for the class that defines it.
ASM-013, add to Impact: A tagged suite is listed in `run.sh` in the commit that adds it; a suite called from an indented or commented `run_suite` line counts as unlisted.

ASM-018, replace the Assumption's last clause by: The rule is syntactic and checks no object of the repository: a hex token delimited by `/`, `.`, `:` or other punctuation inside a longer name (`feature/abcdef1`, `fix.1234567`), a branch named in hex (`deadbeef`), a word of seven or more hex letters (`effaced`), a compact date (`20261006`), any number of 7 to 40 digits and `0000000` count as a commit; under Requirements an ID without a file (`AVE-REQ-999`) counts. HTML comments are removed first, and `docs/briefs/` holds briefs, `README.md`, `drafts/` and `handbacks/` only (the folder files `.DS_Store` and `Thumbs.db` are passed over).
ASM-018, Impact: The reader of the brief and the task's base check judge whether the token is the intended commit.

ASM-019, replace the Assumption by: Check 7 rejects the wordings "running", "underway", "under way", "in flight", "ongoing", "still executing" and "runs now" in PROGRESS.md outside comments, fences and code spans, in any letter case and with spaces or hyphens between the words, and allows the negations "nothing is running", "not running" and "no longer running". The rule knows this list; the commit review judges any other wording.

New entry — Check 12 fails every `while`, `until` and `for ((` in a hook command
- Assumption: A hook command in `.claude/settings.json` with the shell word `while` or `until` or with a `for ((` loop fails check 12, whatever its condition; so does `--permission-mode` with any value.
- Reason: An always-true condition has unbounded spellings (`while [ 1 ]`, `while :`, `until false`); a hook command of this project is a script path.
- Impact: A hook that needs a loop keeps it inside its script, where the inspection of `.claude/hooks/*.sh` reads it.
- Links: AVE-REQ-098, AVE-REQ-097.

New entry — The evidence plugin takes a `.git` entry as the mark of a repository
- Assumption: `backend/tests/evidence_plugin.py` treats a tree as inside a repository when its directory or one above it holds a `.git` entry; there a Git that fails stops the session.
- Reason: Git's own answer is the thing that fails, so the test for a repository uses no Git command.
- Impact: With `GIT_CEILING_DIRECTORIES` between the tree and that entry the session fails; a source archive placed inside another checkout is judged by that checkout's ignore rules.
- Links: AVE-REQ-097.
```

`docs/ARCHITECTURE.md`:

```text
§ Testing strategy item 2, after "a tooling tag that names no existing criterion fails the "Evidence manifest" step with its file and line.": So does a comment tag in a file of `scripts/tests/` that is neither a suite `run.sh` lists nor a `test_*.py` file: no runner writes a result for it. Replace "in a unit-test file each tag stands directly above the test it names" by "in a unit-test file each tag stands directly above the test it names and binds to it by class and name".
§ Testing strategy item 3, replace "a test file Git ignores stops the session" by "a test file Git ignores stops the session, and so does a Git that fails inside a repository".
§ Verification pipeline item 4, replace the check 12 clause by: check 12 fails a settings file that sets a gate variable, removes the gate, adds a second Stop command, registers the gate with another handler type or with any text around the registered command, or sets `SHELLOPTS`, `BASHOPTS`, `BASH_ENV` or `ENV`.
```

Other lead-owned files that name the old lists:

```text
docs/TRACEABILITY.md — AVE-REQ-098 row, Tests cell: `scripts/tests/test-checker.sh` (AC-1, AC-2, AC-3, AC-4). § Conventions item 1: add "a comment tag in any other file of `scripts/tests/` stops the run with its file and line".
docs/briefs/README.md § Template: add "HTML comments are removed before a section is judged" and "this directory holds briefs, README.md, drafts/ and handbacks/ only; check 11 fails on any other entry"; § Handbacks: add "a hidden file or a directory there fails too".
.claude/skills/develop/SKILL.md § 13: check 7 rejects "running", "underway", "under way", "in flight", "ongoing", "still executing" and "runs now" there.
```

### Deviations and discovered work

Deviations:

- **Skill precondition 3.** The dependencies AVE-REQ-093 and AVE-REQ-094 are `in-progress`. The brief runs the fix tracks in parallel with them, so I proceeded and report it here.
- **Existing tests changed because the brief's decision 1 changes behaviour.**
  - `test_a_suite_that_run_sh_never_runs_gives_no_evidence` is now `test_run_sh_records_each_listed_suite_and_a_tagged_file_it_never_runs_stops_the_tool`: a tagged, unlisted suite used to read `not-run` and now stops `collect` and `done_problems`.
  - The expected text `stands above test_other` is now `stands above Helper.test_other`.
  - Five tests create their shell suites through the helper `_suite`, which lists them in a `run.sh` of the synthetic directory.
- **Existing checker cases changed because the Stop command is exact now.**
  - `hook command with redirects and && accepted` moved from the Stop command to a `PreToolUse` hook.
  - The `PROGRESS claim` cases now also expect the line number.
- **Files not edited.** No requirement file and no shared document was changed (forbidden paths); the texts are proposed above. `docs/PROGRESS.md` needed no change.

Decisions the brief left open (proposed assumptions above):

- Check 12 fails any `while`, `until` or `for ((`, bounded ones included.
- The folder files `.DS_Store` and `Thumbs.db` pass in `docs/briefs/` and `handbacks/`, as in the ignored-file step; a macOS host would otherwise fail the Stop gate on a file Git ignores.
- A hidden `*.md` file in `docs/briefs/` fails; it is not read as a brief.
- The unowned-tag scan covers subdirectories of `scripts/tests/` and leaves `__pycache__` out.
- A started unit test is named by the class that defines the method, so a tag above an inherited test binds.
- The plugin takes a `.git` entry in the tree's directory or above it as the repository mark.

Discovered work (proposed follow-ups, outside this brief):

- **The `timeout` of the Stop handler is unchecked.** A value of one second would end the gate before `verify.sh` finishes. Proposed: a check 12 rule for the handler's keys (`type`, `command`, `timeout` with a lower bound), or the limit stated as in the Edge-case text above. Parent AVE-REQ-097 AC-3.
- **`record` still ends in a traceback on other write failures** (for example a read-only `latest-<tier>.json`). It exits 1, so it fails closed; only the missing or uncreatable directory is a tool error now.
- **Tag line numbers** come from `str.splitlines`, which also splits on form feed and similar characters; a file with such characters reports shifted lines. This predates the change.

Notes for the merge:

- A new file in `scripts/tests/` with a comment tag must be a suite listed in `run.sh` or a `test_*.py` file; `scripts/tests/make-fixture.sh` (track B1) must stay free of comment tags, or `record` stops with its file and line.
- Track B1 may touch cases of `scripts/tests/test_evidence.py`; this track changed that file in 12 places.
- When this report is filed under `docs/briefs/handbacks/`, the comment marker `<!--` stays inside code spans or fenced blocks, as written here.
- The release evidence was recorded on the working tree before the commit. A release run on the merge commit gives the manifest that names it.
- The development container turned out to be shared with the other writer (its `/tmp` holds their files). My scratch copies under `/tmp/b2-mut` are removed; nothing of theirs was touched.
