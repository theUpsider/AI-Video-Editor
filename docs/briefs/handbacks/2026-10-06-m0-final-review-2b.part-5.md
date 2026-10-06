# Handback — M0 final review, second round, part 5: AVE-REQ-098

Report of the reviewer (and of the skeptic, when the reviewer returned PASS) for AVE-REQ-098 from workflow run `wf_b18a5f3e-54e` at `f996c17`, briefed in [the review brief](../2026-10-06-m0-final-review-2b.md). The lead filed the report as returned, with local paths shortened to repository paths.

## Review

Verdict: **PASS** — AVE-REQ-098 — Persistent progress and bounded autonomous continuation

### AC-1 Update the current objective, requirement statuses, blockers, failed checks, changed files, and next command after coherent work units — PASS

```text
Tests in the release run (13 of 13 steps, evidence FRESH): scripts/tests/test-checker.sh, ten cases `PROGRESS without '<heading>'` (once per awk, four awks); scripts/tests/test-session-start.sh, `uncommitted list names the modified and the untracked file` and `uncommitted list capped at 20 lines with the remainder counted`, each for startup, resume and compact. Mutants that fail their suite: a heading dropped from the checker's list (two sampled), list cap 19, cap 21 on resume, remainder off by one, no list on compact. Own probe: each of the ten headings removed gives exit 1 with its message; 19 and 20 paths print no remainder line, 21 print `[1 more; ...]`, 45 print `[25 more; ...]`; staged, modified, deleted, renamed and untracked paths are listed. Inspection of `git log -p docs/PROGRESS.md`: 29 of 82 commits change the file; of the seven first-parent commits since the first review five do (launches in the stop-safe form at d309ca4 and c15c0df, verdicts and next steps at 41973c5, the integration at fc66eb3, the CI result at f996c17). At f996c17 the file agrees with the repository: its ten in-progress and five verification requirements match the frontmatter, `main` is bd12fe8 on the remote, CI is green at b573d65 and failed at fc66eb3 (`gh run list`), `Known failures: None` matches my release PASS, and § Next recommended work names the next action.
```

### AC-2 Reconstruct state from repository files and Git after compaction or a new session rather than relying on conversational memory — PASS

```text
Tests in the release run: scripts/tests/test-session-start.sh asserts the branch line, the 8 commit lines, the last verification, PROGRESS.md between its delimiters and the uncommitted list once per source (startup, resume, compact; 56 checks); scripts/tests/test-checker.sh, four `SessionStart matcher ...` failure cases, three accepted forms and `SessionStart hook removed`. The three mutants of the first round now fail the suite: no state on compact (9 failing checks), no state on resume (9), state on startup only (18). Eight further own mutants that drop or shorten one part of the block for one source fail too, and so do the checker mutants that stop requiring one source, ignore the matcher or stop reporting a missing hook. Own probe: the hook prints an identical block for startup, resume, compact and clear, with PROGRESS.md equal to the file; on a clone of f996c17 it exits 0 with 98 lines and all 83 lines of PROGRESS.md for each source. Check 12 with 16 own matcher forms: every matcher that excludes startup, resume or compact gives exit 1. Inspection: .claude/skills/resume-project/SKILL.md rebuilds state from the injected block, ROADMAP.md, requirement frontmatter and Git; its fast-path commands run on this tree and agree with PROGRESS.md (M0 in-progress, the same open requirements).
```

### AC-3 At a genuine permission, resource, credential, or session limit, preserve partial results and report the exact unblock action without claiming ongoing execution — PASS

```text
Tests in the release run: scripts/tests/test-checker.sh, `PROGRESS: review running`, eleven `PROGRESS claim: ...` cases, the accepted stop-safe line, negations, comments, fences and code spans, and `missing .env.example`; scripts/tests/test-probe-environment.sh, `every reported credential variable is listed in .env.example`. Mutants that fail their suite: each of the seven wordings removed, three hyphen forms, the negations, case folding, code spans, comments and fences read as text, `.env.example` no longer required, a credential the file lacks (three forms). Own probe of check 7: 28 lines with the listed wordings give exit 1, 13 accepted forms give exit 0. Inspections performed: WF-002 agrees with Git (90a1f2e holds no file under docs/briefs/; the two execution briefs enter with 6736401, the base of the continuation run wf_df2de811-039); docs/ENVIRONMENT_CAPABILITIES.md § External gaps holds six rows with one unblock action each, and its three variables are in .env.example; PROGRESS.md § Blockers names the disk limit with its action; PROGRESS.md at f996c17, read in full, claims no ongoing execution in any wording, and its history records launches in the stop-safe form (d309ca4, c15c0df, and fc068d8 for this run); the nine commits it names are ancestors of a live remote head (`git ls-remote --heads origin`), and its three branches are listed by `git branch -r` in the main checkout. An interruption at a real limit cannot be staged, as the strategy says; the Codex row of § External gaps is the one action that is not yet exact (non-blocking finding 7).
```

### AC-4 Do not use infinite loops, arbitrary sleep daemons, or permission bypass flags to simulate unlimited autonomy — PASS

```text
Tests in the release run: scripts/tests/test-stop-hook.sh, sections `escalation and release`, `reset on a fresh stop`, `stop_hook_active absent`, `max attempts override` and `a counter that cannot be read back` (145 checks); scripts/tests/test-checker.sh, the `settings: ...` cases, seven `hook command: ...` cases, thirteen `tool hook command: ...` cases, the two accepted controls and the async cases. Mutants that fail their suite: never release, release one late, one early, no read-back, count reset at every stop, missing key read as fresh, no FAIL record, fallback always 1, open limit range, silent release, default limit 4; and each listed form removed from check 12 (while, until, `for ((`, sleep, nohup, disown, setsid, background `&`, both flags, async, both modes, skipped prompts, loop words read inside names). Own probe of the gate in a fixture: exit codes 2, 2, 0 with `gate attempt 1 of 3`, `2 of 3`, then the systemMessage and last-result FAIL; twelve further continued stops release; limits 1, 2, 3, 9 and 10 block 0, 1, 2, 8 and 9 times; eleven invalid limits behave as 3; 17 forms of the hook input start a fresh count only with a literal false at the outermost level; fifteen counter contents and five kinds of counter path end in a release after at most three blocks; a counter file that cannot be replaced gives 2, 0, 0 and a counter path that is a directory gives 2, 0, 0, 0. Own probe of check 12: 79 constructions of the listed forms under eight hook events all give exit 1. Inspection: .claude/hooks/*.sh and scripts/lib/verify-state.sh hold loops over finite input only, no sleep and no background job; .claude/settings.json has no default mode, no skipped prompt and no async hook; no agent or skill frontmatter sets a permission mode or a hook; .claude/settings.local.json is absent on this host; the workflow scripts loop over finite lists or at most three rounds; CI has no schedule trigger; the one `sleep` in the tooling is the container keep-alive of scripts/dev-container.sh:64, which ADR-009 documents.
```

### Verification runs

```text
- Clone in C:/dev/AI-Video-Editor (paths in this report are relative to that root): `git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/verify-ave-req-098`, then `checkout -q f996c170...`; `git rev-parse HEAD` printed f996c170a4e75ad25b06f36babf8699843012c92. `git status --porcelain` was empty before and after every reported run. Every fixture and mutant lived in the container's /tmp; no file of the clone was changed, and the main checkout was only read.
- `./scripts/verify.sh --tier release` (development container, arm64; it waited for the heavy-media lock first) -> exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`: 37 tooling unit tests; backend 125 passed (fast) and 84 passed (media and population, 396 s); suites test-checker 1090/0 over four awks, test-check-baseline 305/0, test-stop-hook 145/0, test-session-start 56/0, test-verify-tiers 65/0, test-probe-environment 155/0; `Working tree unchanged by verification` PASS; `Evidence manifest` PASS.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-098 --require-fresh --tier release` -> exit 0: tier release, PASS, commit f996c170a4e7, recorded 2026-10-06T14:12:35Z, `Freshness: FRESH`; AC-1 passed (test-checker.sh, test-session-start.sh), AC-2 passed (the same two), AC-3 passed (test-checker.sh, test-probe-environment.sh), AC-4 passed (test-checker.sh, test-stop-hook.sh). With `--require-complete` -> exit 0. Repeated after all probes: same output, still FRESH.
- `grep -rl "AVE-REQ-098" scripts/tests backend/tests` -> test-checker.sh, test-probe-environment.sh, test-session-start.sh, test-stop-hook.sh. Direct runs with `./scripts/dev-container.sh bash scripts/tests/<suite>`: test-checker.sh 278/0 (system awk, 74 s), test-stop-hook.sh 145/0, test-session-start.sh 56/0, test-probe-environment.sh 155/0, each exit 0. No case is skipped or expected to fail; in the release log every tagged case appears as `ok` (the checker cases once per awk).
- Probe A, Stop gate in a fixture from scripts/tests/make-fixture.sh with-reqs and a broken link: passing tree exit 0; then fresh, continued, continued -> 2 (`gate attempt 1 of 3`), 2 (`2 of 3`), 0 with `{"systemMessage": "Verification gate released after 3 consecutive failed attempts..."}`, attempts 3, last-result FAIL; twelve further continued stops -> 0 each; fresh plus twelve continued -> 2, 2, then 0; limits 1, 2, 3, 9, 10 -> 0, 1, 2, 8, 9 blocks; limits 0, 11, -1, 03, ' 3', 1e1, 100, 0x3, +3, abc and empty -> as 3; counter contents ' 2', '2 ', +1, -0, -5, 1e1, 0x2, abc, empty -> 2, 2, 0, 0; 08, 09, 007, 2 and a 23-digit number -> 0 at once; 9223372036854775807 -> 2, 2, 2, 0; counter path as directory or non-empty directory -> 2, 0, 0, 0; as symlink, dangling symlink or FIFO -> 2, 2, 0, 0; state directory replaced by a file -> 2, 2, 0, 0 from the temporary directory; no state directory at all -> exit 0 with `Verification gate skipped`.
- Probe A2, a counter that cannot be stored: sticky state directory with a counter file of another owner, hook run as `nobody` through setpriv (creating a file there works, replacing the counter fails) -> fresh, continued, continued give 2, 0, 0; the counter file keeps 0.
- Probe B, check 12 in a fixture: 37 own constructions of the listed forms under PreToolUse and 42 under SessionStart, PostToolUse, UserPromptSubmit, PreCompact, SubagentStop, SessionEnd and Notification -> exit 1 with the loop message each; 14 accepted forms (redirects, `&&`, `|&`, a list loop, `wait-until-ready.sh`, `--meanwhile`, `until.sh`, `--until=5`) -> exit 0; `x --mode=until`, `scripts/a+until+b.sh`, `cat 'wait until ready.txt'`, `x --run:while` -> exit 1; async true, 1 and 'true' -> exit 1, false, null and 0 -> exit 0; default modes bypassPermissions and dontAsk -> exit 1; a skipped prompt at the top level and nested -> exit 1; 16 matcher forms and two-group combinations behave as § Edge cases states; five SessionStart commands that name the hook without running it or discard its output -> exit 0 (finding 1); forms outside the list (`coproc`, `yes |`, `tail -f`, `select`, `--allow-dangerously-skip-permissions`) -> exit 0.
- Probe B, check 7 in a fixture: 28 own lines with the listed wordings in other cases, separators and Markdown positions -> exit 1; 13 accepted forms (the three negations, the stop-safe line, comments, fences, code spans, words that only contain a claim word) -> exit 0; four two-word wordings split by a line wrap -> exit 0 (finding 3); each of the ten headings removed -> exit 1 with `missing heading '<heading>'`; `.env.example` removed -> exit 1.
- Probe D, SessionStart hook in a fixture with twelve commits: sources startup, resume, compact, clear -> exit 0, empty stderr, 27 lines, 8 commits, identical state block, PROGRESS.md equal to the file; staged, modified, deleted, renamed and untracked paths listed; 19 and 20 paths without a remainder line, 21 -> `[1 more; run git status --short]`, 45 -> `[25 more; ...]`, the same for startup and compact. The real hook on a clone of f996c17: exit 0, 98 lines, 83 lines of PROGRESS.md, no truncation, for startup, resume and compact.
- Probe E: Stop command with ` || true` appended and a Stop handler of type prompt -> exit 1 (non-blocking finding 9 of the first round is closed); `.claude/settings.local.json` with bypassPermissions and a loop -> exit 0 (limit stated in § Edge cases); `permissionMode: bypassPermissions` in an agent's frontmatter and a looping Stop hook in a skill's frontmatter -> exit 0 (finding 4).
- Mutation, 69 one-change mutants, each in a fresh copy of `git archive HEAD` under the container's /tmp, controls 56/0, 145/0 and 68/0 (the checker cases of lines 134-142, 287-341 and 370-380 run verbatim; the two checker survivors repeated against the full suite, 278/0): session-start.sh 13 mutants, 12 fail test-session-start.sh; stop-verify.sh 11 mutants, all fail test-stop-hook.sh; check-project-control.sh 42 mutants, 40 fail; probe-environment.sh and .env.example 3 mutants, all fail test-probe-environment.sh. Survivors: the hyphen form of `still executing`, the hyphen form of `runs now`, and a remainder line printed at exactly 20 paths (finding 6).
- Remote inspection (main checkout, read-only): `git ls-remote --heads origin` -> main bd12fe8, ccr-af7078da-q8r8mf 8a7ed2a, m0-final-integration fc068d8, ave-req-094-probe-evidence b4f503f; the § Verification strategy command on `git show f996c17:docs/PROGRESS.md` prints no `not on the remote` line; the nine commits the file names and f996c17 itself are ancestors of fc068d8; `git branch -r` lists the three branches the file names. `gh run list` -> f996c17 success, b573d65 success, fc66eb3 failure.
- WF-002 inspection: `git ls-tree -r --name-only 90a1f2e | grep -c '^docs/briefs/'` -> 0; `git log --diff-filter=A` -> docs/briefs/2026-10-02-m0-process-fixes-execution.md and 2026-10-02-m0-media-core-follow-ups-execution.md enter with 6736401; the header of docs/workflows/m0-fix-tracks-continue-wf_df2de811-039.js names base 6736401 and the session restart. The reworded strategy sentence matches both.
- First-round blocking findings repeated: 1 (WF-002 sentence) closed by the rewording above; 2 (state asserted for startup only) closed, the mutants S10, S11 and S12 fail the suite with 9, 9 and 18 checks. Removed test lines since 2df637f read in `git diff 2df637f HEAD -- scripts/tests/`: each removed check returns in a stronger form, none is weakened.
- Cleanup: `./scripts/dev-container.sh --stop` -> container state absent; `rm -rf .claude/worktrees/verify-ave-req-098`; main checkout `git status --porcelain` empty; own scratch files removed.
```

### Blocking findings (0)

### Non-blocking findings (10)

1.

```text
location: scripts/check-project-control.sh:581 (check 12, SessionStart registration), with docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:72 (§ Verification strategy, AC-2)
defect: Check 12 counts a SessionStart command as registered when its text contains `.claude/hooks/session-start.sh`. A settings file can therefore stop the state injection without failing the check. The Stop command got an exact comparison in this fix round; the SessionStart command did not, and § Edge cases states no limit for it.
evidence: Own probe in a fixture, each gives exit 0 with no error line: the registered command followed by ` >/dev/null`; followed by ` | head -n 1`; preceded by `false && `; `true # .claude/hooks/session-start.sh`; `echo .claude/hooks/session-start.sh`. A handler of type prompt, an empty hooks list and `disableAllHooks` give exit 1. At f996c17 the settings file holds the plain command with no matcher and the hook prints the full block for every source, so AC-2 holds today; the gap is a later edit that the gate would let through, which AT-29 (forbidden gate weakening is rejected) will ask about.
fix: Compare the SessionStart command with the exact registered form `"$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh`, as lines 603-615 do for the Stop gate; add the five forms as cases of scripts/tests/test-checker.sh under the AVE-REQ-098 AC-2 tag; name the rule in § Edge cases.
```

2.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:57-58 (§ Edge cases), with scripts/check-project-control.sh:533
defect: The sentence says a loop word inside a file name or an option is no shell word `while` or `until`. The rule exempts a loop word only when a letter, a digit, `_`, `.`, `/` or `-` stands directly beside it; with any other character beside it check 12 fails the command. The check is stricter than the sentence for such names. Every listed form fails and both named examples pass, so no criterion and no evidence depends on it; I class it as a wording fix because the gate is understated, not overstated.
evidence: Own probe, each gives exit 1 with `starts a loop, a sleep, a background job or a permission bypass`: `x --mode=until`, `scripts/a+until+b.sh`, `cat 'wait until ready.txt'`, `x --run:while`. Accepted with exit 0: `scripts/wait-until-ready.sh`, `x --meanwhile`, `scripts/until.sh`, `./while`, `x --until=5`, `x --while`, `run_until_ready`. `sleep` also fails inside a name (`scripts/sleep-check.sh`, `x --no-sleep`); the sentence exempts no such name, so that part is consistent.
fix: Reword the parenthesis to the rule: a loop word with a letter, a digit, `_`, `.`, `/` or `-` directly before or after it, as in `wait-until-ready.sh` or `--meanwhile`, is none; after `=`, `+`, `:`, a quote or a space it counts. The same wording fits ASM-030 and the comment above check 12.
```

3.

```text
location: scripts/check-project-control.sh:402-411 (check 7), with docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:48-50
defect: Check 7 reads one line at a time, so a listed wording of two words that a hard line wrap splits passes. PROGRESS.md is wrapped at about 120 columns, which makes the split possible without intent. § Edge cases says `line` and states no limit for a wrapped wording.
evidence: Own probe, each gives exit 0: `- The review of AVE-REQ-001 is still` followed by `  executing in the workflow.`; `under` then `way`; `in` then `flight`; `runs` then `now`. docs/ASSUMPTIONS.md:303-304 wraps `still` and `executing` over two lines in exactly this way. PROGRESS.md at f996c17 holds no such claim (read in full).
fix: Join the lines of a paragraph or list item before matching (or carry the last word of the previous line), and add the four cases to the claim loop of scripts/tests/test-checker.sh; or state in § Edge cases that the rule reads single lines and that the commit review judges a wrapped wording.
```

4.

```text
location: scripts/check-project-control.sh:482-492 (scope of check 12) and :328-343 (checks 4 and 5), with docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:60-62
defect: Check 12 reads `.claude/settings.json`. Two kinds of tracked file can carry the same bypass or loop and are named by no rule and by no stated limit: agent frontmatter (`permissionMode`) and agent or skill frontmatter with a `hooks` block. Among the flags, `--allow-dangerously-skip-permissions` passes.
evidence: Own probe, each gives exit 0: `permissionMode: bypassPermissions` added to .claude/agents/implementer.md; a `hooks:` block with the command `while true; do sleep 5; done &` added to .claude/skills/develop/SKILL.md; a PreToolUse command `claude -p go --allow-dangerously-skip-permissions`. At f996c17 the five agents hold only the keys name, description, tools, model, color (implementer also skills) and no skill holds a hooks key, so AC-4 holds. Also passing, and covered by the stated limit `written another way`: `coproc x`, `yes | x`, `tail -f /dev/null`, `select ...`, `usleep 100`, and `permissions.allow` entries `Bash` and `Bash(*)`.
fix: Let checks 4 and 5 fail a `permissionMode` of `bypassPermissions` or `dontAsk` and a `hooks` key in agent and skill frontmatter, and match `dangerously-skip-permissions` without its leading dashes, each with a suite case; or add the agent and skill files to the limit sentence of § Edge cases.
```

5.

```text
location: scripts/check-project-control.sh:536 (SESSION_SOURCES)
defect: Check 12 requires the SessionStart hook for startup, resume and compact. A matcher that leaves `clear` out passes, although the context after `/clear` is as empty as after a new session, which AC-2 names.
evidence: Own probe: matcher `startup|resume|compact` -> exit 0. The hook prints the same block for source `clear` (probe D), and the settings file at f996c17 has no matcher, so `clear` is covered today.
fix: Add `clear` to SESSION_SOURCES with a suite case, or state in § Edge cases that `clear` lies outside the rule.
```

6.

```text
location: scripts/tests/test-checker.sh:292-299; scripts/tests/test-session-start.sh:78-79; scripts/tests/test-stop-hook.sh:310-317
defect: Three details that § Edge cases states have no case that fails without them: the hyphen form of `still executing` and of `runs now`; the boundary of the 20-line list (exactly 20 paths print no remainder line); a counter that cannot be stored (the suite stages the read-back mismatch only, which runs the same fallback). The implementation is correct in all three.
evidence: Surviving mutants: the hyphen taken out of the separator class of `still executing`, and of `runs now`, in check 7 -> test-checker.sh 278/0; `NR > max` changed to `NR >= max` in print_uncommitted_paths -> test-session-start.sh 56/0. Own probes on the unchanged code: `- Still-Executing` and `- runs-now` give exit 1; 20 paths print no remainder line and 21 print `[1 more; ...]`; a counter file that cannot be replaced gives exit codes 2, 0, 0.
fix: Add `- The review is still-executing.` and `- The release tier runs-now.` to the claim loop; add a case with exactly 20 and one with 21 uncommitted paths; for the unstorable counter either stage it with a second user where the suite runs as root, or say in the suite comment that the directory case stands for both.
```

7.

```text
location: docs/ENVIRONMENT_CAPABILITIES.md:151 (§ External gaps, row `No Codex credential`)
defect: Non-blocking finding 12 of the first round is unchanged: the row defers the exact command to the M5 adapter brief, and § Edge cases of the requirement states no limit for it. The lead's summary that each non-blocking finding is fixed or stated as a limit does not hold for this one inside the requirement file.
evidence: Row text: `The human signs the test machine in with the authentication the Codex SDK documents; the adapter's brief (M5) names the exact command`. .env.example: `its variable joins this file with the adapter (M5)`. The gap blocks M5 work only, and no task has met it.
fix: Add one sentence to § Edge cases now (the Codex row names its exact command and variable when the adapter is specified, M5), and fill the row and .env.example with AVE-REQ-052.
```

8.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:102 and :12; docs/TRACEABILITY.md:212
defect: Three document details. (a) The newest Status-log line requests the review from 2026-10-06-m0-final-review-2.md, a brief no run used; this run is briefed in 2026-10-06-m0-final-review-2b.md. (b) The Tests cell of the matrix row lists `inspection (AC-1, AC-3, AC-4)`, while § Verification strategy names inspection for AC-2 as well. (c) The dependencies AVE-REQ-093 and AVE-REQ-094 are `verification`, not `done`.
evidence: Brief 2b § Input revision: `This brief replaces 2026-10-06-m0-final-review-2.md, which no run used`. Requirement line 72: `AC-2 — integration and inspection`. `grep -H '^status:'` on the two dependency files prints `verification`.
fix: Name brief 2b in the Status-log line that records this verdict; write `inspection (AC-1, AC-2, AC-3, AC-4)` in the row; move the requirement to `done` after AVE-REQ-093 and AVE-REQ-094, in the order PROGRESS.md states.
```

9.

```text
location: docs/PROGRESS.md:49 and the file as a whole
defect: § Next recommended work item 1 reads `Launch the review run from its brief` and names neither the workflow script nor its arguments. The file has 83 lines against the target of under about 80.
evidence: docs/workflows/m0-final-review-2.js exists at f996c17 and its header names the launch arguments; the next commit fc068d8 records script, run ID and re-run arguments in the stop-safe form. `wc -l docs/PROGRESS.md` -> 83; the SessionStart block shows all of them (cap 120).
fix: Name the script and its arguments in the item while a launch is pending; trim three lines at the next update.
```

10.

```text
location: .claude/hooks/stop-verify.sh:116-120 (count_failed_attempt)
defect: A counter file written by hand is read with the shell's number rules: `08` and `09` end the arithmetic with an error, so every continued stop releases at once, and `9223372036854775807` overflows and gives three blocks before the release where the limit of 3 allows two. The gate stays bounded in every case, and the gate itself never writes such a value.
evidence: Own probe, four continued stops each: `08` -> 0, 0, 0, 0; `09` -> 0, 0, 0, 0; `007` -> 0, 0, 0, 0; `9223372036854775807` -> 2, 2, 2, 0; eleven other contents (signs, spaces, hex, exponent, a word, empty, two lines) -> at most two blocks.
fix: Optional: read the value as decimal (`$((10#$attempts + 1))`) and count a value of more than two digits as 0.
```

### Test quality

```text
Checklist of verify-requirement § 8 per criterion. 69 mutants, each in a copy outside the clone; 66 fail their suite, 3 survive (finding 6). The suites run the real hooks and the real checker in fixture repositories; stand-ins replace only the component step files. A shell suite is credited per suite result, so I confirmed in the release log that the cases under each tag ran.

AC-1: test-checker.sh, tag at line 135; test-session-start.sh, tag at line 75. The heading cases take their ten headings from a list written in the suite, apart from the checker's own, and assert the exact error line; dropping a heading from the checker fails its case. The list cases assert exact lines, exactly 20 listed paths, `[6 more; ...]` and the count 26, once per source; cap 19, cap 21 on resume, a wrong remainder and no list on compact all fail. Gap: no case at exactly 20 paths, so a remainder line printed at the boundary survives. Whether PROGRESS.md matches the work is judged by inspection; I performed it.

AC-2: test-session-start.sh, tags at lines 35, 49 and 75; test-checker.sh, tag at line 370. The blocking gap of the first round is closed: every content check runs for startup, resume and compact through `every`, and the three earlier mutants fail with 9, 9 and 18 checks. Eight further mutants that drop or shorten one part of the block for one source fail (8 commits against 7 included). The matcher cases assert the error text with the excluded sources; dropping a source from the rule, ignoring the matcher and not reporting a missing hook all fail. Gap: the registration is judged by containment and no case covers a command that names the hook without running it (finding 1).

AC-3: test-checker.sh, tags at lines 287 and 379; test-probe-environment.sh, tag at line 285. Each of the seven wordings has a case that fails when its pattern is removed, and the cases assert the line number. The accepted forms are controls that fail when the negation rule, the code-span rule, the comment rule or the fence rule is removed. The .env.example check compares the names the probe prints with the file, two independent sources; three mutants fail. Gaps: the hyphen forms of `still executing` and `runs now` have no case, and no case holds a wording split by a line wrap (finding 3). The inspections show what the strategy says they show; the WF-002 sentence now agrees with the log and with Git.

AC-4: test-stop-hook.sh, tags at lines 257 and 310; test-checker.sh, tag at line 315. The bounded continuation is asserted by exit codes, the attempt numbers in the message, valid JSON on release and the recorded FAIL; eleven mutants fail, off-by-one in both directions among them. The read-back case (counter path as a directory, expecting 2, 0, 0) fails without the read-back and without the bounded fallback. Each listed hook-command form has a case and a failing mutant; the nohup, disown and setsid cases sit on the Stop command, where the exact-command rule fails too, and they hold because they assert the loop message, which the mutants remove. The control `hook command with a list loop and loop words inside names accepted` fails when loop words are read inside names. No check depends on timing.

Executed: the four suites appear in the release run with their totals, none skipped, and evidence.py credits them from that run with the tree FRESH. Three runs of each suite (release tier, direct, mutation control) gave the same totals.

AT-29 and AT-30: nothing at this commit contradicts either scenario for this requirement; finding 1 is the one that AT-29 would meet.
```

### Evidence for the requirement file

```text
- verify-requirement: PASS — 2026-10-06 — no blocking findings
- ./scripts/verify.sh: PASS — 2026-10-06
- AC-1 → `scripts/tests/test-checker.sh` (ten cases `PROGRESS without '<heading>'`), `scripts/tests/test-session-start.sh` (uncommitted list, at most 20 lines with the remainder counted, per source) — pass
- AC-1 → inspection: `git log -p docs/PROGRESS.md` read; 29 of 82 commits update the file, and at f996c17 its objective, requirement statuses, blockers, known failures and next work agree with the frontmatter, the remote and CI — pass
- AC-2 → `scripts/tests/test-session-start.sh` (state block asserted for startup, resume and compact), `scripts/tests/test-checker.sh` (SessionStart matcher cases, hook removed) — pass
- AC-2 → inspection: `.claude/skills/resume-project/SKILL.md` read and its fast path run on the tree; it rebuilds state from PROGRESS.md, ROADMAP.md, requirement frontmatter and Git — pass
- AC-3 → `scripts/tests/test-checker.sh` (check 7 wordings and accepted forms, `.env.example` required), `scripts/tests/test-probe-environment.sh` (every reported credential variable is listed in `.env.example`) — pass
- AC-3 → inspection: WF-002 compared with Git history; `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps (six rows, one unblock action each); PROGRESS.md § Blockers; every commit PROGRESS.md names is an ancestor of a live remote head and its branches are listed by `git branch -r` — pass
- AC-4 → `scripts/tests/test-stop-hook.sh` (bounded attempts, release with a recorded failure, counter read back), `scripts/tests/test-checker.sh` (check 12: default modes, skipped prompts, hook-command forms, async) — pass
- AC-4 → inspection: `.claude/hooks/*.sh`, `scripts/lib/verify-state.sh`, `.claude/settings.json` and the agent and skill frontmatter read: loops over finite input only, no sleep, no background job, no permission bypass — pass
- Non-blocking findings: check 12 accepts a SessionStart command that names the hook without running it or discards its output; the loop-word sentence of § Edge cases is exact only for names made of letters, digits, `_`, `.`, `/` and `-`; check 7 misses a two-word wording split by a line wrap; agent and skill frontmatter lie outside check 12; `clear` is no required source; three suite gaps (two hyphen forms, the 20-path boundary, the unstorable counter); the Codex row of § External gaps names its exact command at M5; details of the Status log, the matrix row, PROGRESS.md and the counter arithmetic.
```

## Challenge

Outcome: **REFUTED**

### Reasoning

```text
**Verdict: refuted, on AC-2 only.** The clone was at f996c170a4e75ad25b06f36babf8699843012c92, `git status --porcelain` stayed empty, the container is stopped and the clone removed; the main checkout was only read.

**What stands.** The four tagged suites pass as reported (56/0, 145/0, 155/0; `test-checker.sh` 278/0 on the unchanged tree copy). The release tier was not re-run; the reviewer's run and CI stand for it. AC-1, AC-3 and AC-4 withstood my own constructions. AC-2's behaviour is present today: `.claude/settings.json` registers the plain command with no matcher, and the hook prints the full block for all three sources.

**Why AC-2 is refuted.** The brief counts as blocking a statement of the requirement file that is false at this commit. The first round failed this same criterion when edits that removed the injection passed the suite. Both conditions hold again, shown by runs on a copy of the reviewed tree:

- **Hook named but never run.** With the SessionStart command `true # .claude/hooks/session-start.sh`, the checker, the fast tier (11 of 11) and all four tagged suites pass. No test or check fails when the injection is removed for startup, resume and compaction.
- **Settings file that is no JSON object.** With `[]` or `null`, check 3 and check 12 both stay silent and the fast tier passes 11 of 11. The requirement says `check 12 fails when the SessionStart hook is missing`; here it is missing and check 12 prints nothing. The checker's own comment says check 3 reports this case; it does not. Only `test-checker.sh` goes red, through 60 setup failures, not through a case that asserts the rule.

The reviewer saw the first form's checker result and classed it non-blocking because AC-2 holds today. That reasoning would also have cleared the first round's blocking finding 2, where the unmutated hook was correct too. The reviewer did not try the non-object file.

**Where the reviewer was stricter than needed.** The regex-dialect difference and the optional `clear` source are recorded in ASM-014, so I do not count them, and the reviewer's finding 5 is covered there.

**Outside this requirement, for the lead.** The same non-object file switches the Stop gate off while check 12 and the fast tier pass. That contradicts the AVE-REQ-097 § Edge cases line `A settings file without the Stop gate … fails check 12 (AC-3)` at docs/requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md:61.

**Fix.**
- In `scripts/check-project-control.sh`, make check 12 (or check 3) fail a settings file whose top-level value is no object.
- Compare the SessionStart command with the exact registered form `"$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh`, as lines 603-615 do for the Stop command.
- Add cases to `scripts/tests/test-checker.sh` under the AVE-REQ-098 AC-2 tag: `[]`, `null`, a command that names the hook in a comment, and one that discards its output.
- Correct the comment at :483-484 and state the rule in § Edge cases of the requirement.
```

### AC-2 Reconstruct state from repository files and Git after compaction or a new session rather than relying on conversational memory — FAIL

```text
The behaviour holds at f996c17; what fails is the evidence the requirement names for it. All runs were on a copy of `git archive HEAD` (f996c17) in the container's /tmp, with one change to `.claude/settings.json` each.

(1) SessionStart command set to `true # .claude/hooks/session-start.sh` (a shell runs `true`: 0 bytes of output, so no state block for any source). Results: `./scripts/check-project-control.sh` exit 0 with its `OK:` line; `./scripts/verify.sh --tier fast` PASS, 11 of 11 steps; `test-session-start.sh` 56/0; `test-checker.sh` 278/0; `test-stop-hook.sh` 145/0; `test-probe-environment.sh` 155/0. Every check tagged AVE-REQ-098 AC-2 stays green with the injection switched off at startup, resume and compaction alike. The reviewer reported the checker's exit 0 for this form (non-blocking finding 1) but not that the whole tagged evidence stays green.

(2) Settings file replaced by `[]`, `null`, `"hooks"` or `[{"hooks":{}}]` (valid JSON, no object, so no SessionStart hook and no Stop gate). Results: checker exit 0 with `OK:` and no line naming settings.json; with `[]`, `./scripts/verify.sh --tier fast` PASS, 11 of 11; `test-session-start.sh` 56/0; `test-stop-hook.sh` 145/0. `test-checker.sh` ends 218/60, all 60 being `SETUP FAIL` because the suite's edit helper cannot edit a list; no case asserts an error for such a file. Controls: the unchanged tree gives exit 0; deleting `hooks.SessionStart` gives exit 1 with `no SessionStart hook runs .claude/hooks/session-start.sh (AVE-REQ-098 AC-2)`; `{}` gives exit 1.

Cause: `scripts/check-project-control.sh:504-505` leaves check 12 silently when the value is no object, and the comment at :483-484 says `check 3 reports that`, but check 3 (:964-980) validates syntax only. Line :581 counts the hook as registered when the command text contains the path.

Statements this contradicts: requirement file line 72 (§ Verification strategy, AC-2), `check 12 fails when the SessionStart hook is missing`, and line 80 (§ Implementation evidence), check 12 as what keeps SessionStart on startup, resume and compact. § Edge cases and docs/ASSUMPTIONS.md state no limit for either form; ASM-014 covers only the regex dialect and `clear`.

Precedent: the first round failed this same criterion at 2df637f because mutants that dropped the injection passed the suite while the unmutated hook was correct (docs/briefs/handbacks/2026-10-03-m0-gates-red-team.part-8.md, blocking finding 2). Form (1) is such a mutant, in the registration instead of the hook script, and it removes the injection for all three sources.
```

### AC-1 Update the current objective, requirement statuses, blockers, failed checks, changed files, and next command after coherent work units — PASS

```text
Not refuted. `grep '^status:'` on the requirement files gives 10 in-progress and 5 verification, the same IDs PROGRESS.md names, and none blocked or done. `git rev-list --count HEAD` is 82 and 29 commits touch docs/PROGRESS.md; 5 of the 7 first-parent commits since 2df637f do, as the reviewer reported. The real hook on the host shell and in the container lists the state for startup, resume and compact (98 lines, about 6,800 characters, PROGRESS.md byte-identical to the file). § Next recommended work item 1 names no command or script (the reviewer's non-blocking finding 9); I leave that as a judgment call and did not count it.
```

### AC-3 At a genuine permission, resource, credential, or session limit, preserve partial results and report the exact unblock action without claiming ongoing execution — PASS

```text
Not refuted. Check 7 in a fixture: 25 own lines with the listed wordings (bold, italics, table cell, slash, tab, CRLF, after a comment, beside code spans, stray backtick, mixed with a negation) all give exit 1 at line 7. The § Verification strategy command on `git show f996c17:docs/PROGRESS.md` in the main checkout prints no `not on the remote` line; `git ls-remote --heads origin` shows main bd12fe8 and m0-final-integration fc068d8; `git branch -r` lists the three named branches. WF-002 in docs/WORKFLOW_LOG.md matches the reworded strategy sentence. § External gaps has six rows with one action each and its three variables are in .env.example. The history of PROGRESS.md holds no claim of ongoing execution after 4d9ef9a.
```

### AC-4 Do not use infinite loops, arbitrary sleep daemons, or permission bypass flags to simulate unlimited autonomy — PASS

```text
Not refuted. Check 12 in a fixture: 31 own constructions of the listed forms under PreToolUse all give exit 1 (newline, tab, pipe, subshell, backtick and `bash -c` before `while`/`until`; `for((`, `for  ((`, tab before `((`; `/bin/sleep`, `command sleep`; eight background `&` forms; `setsid`, `disown`, `nohup`; both flags). `async` true, both default modes and a skipped prompt give exit 1. `test-stop-hook.sh` 145/0. `git grep` finds no permission mode or bypass flag in agents, skills, workflow scripts, CI or the devcontainer; `.claude/settings.local.json` is absent in the main checkout. The hooks and scripts/lib/verify-state.sh hold loops over finite input only; the `while :` at scripts/verify.sh:288 walks up parent directories and ends at the root. Forms outside the list pass and fall under the stated limit: a PowerShell `While`, a `statusLine` command with a loop, a handler without a type.
```
