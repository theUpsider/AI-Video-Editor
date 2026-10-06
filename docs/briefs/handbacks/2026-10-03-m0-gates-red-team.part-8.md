# Handback — M0 gates red-team, part 8: review of AVE-REQ-098 after the fixes

Run `wf_7d9d015c-906` ([script](../../workflows/verify-m0-final-wf_7d9d015c-906.js)), the final review round of M0 launched 2026-10-06: `verify-requirement` for AVE-REQ-098 at `2df637f` by an independent reviewer in a private clone. The report is the reviewer's, unedited apart from local paths. The run had no brief of its own ([WF-008](../../WORKFLOW_LOG.md)); the report is filed with the brief whose work it reviews. The fixes follow in [the fix brief](../2026-10-06-m0-final-review-fixes.md).

## Review

Verdict: **FAIL** — AVE-REQ-098 — Persistent progress and bounded autonomous continuation (reviewed at commit 2df637f in a private clone; repository root C:/dev/AI-Video-Editor)

### AC-1 Update the current objective, requirement statuses, blockers, failed checks, changed files, and next command after coherent work units — PASS

```text
Test: scripts/tests/test-session-start.sh, checks 'uncommitted list names the modified and the untracked file' and 'uncommitted list capped at 20 lines with the remainder counted' (release run 31/31, direct run 31/31; mutants S1 cap 21, S2 no list, S3 no remainder all fail the suite). Checker: my own fixture probe removed each of the ten PROGRESS.md headings in turn; every removal exits 1 with "missing heading '<heading>'". Inspection of `git log -p docs/PROGRESS.md`: 24 of the 59 commits up to 2df637f update the file, including the last two work units (13c1b7a, 863c7c2). At 2df637f the objective, the 15 in-progress requirements it names, AVE-REQ-103/104 proposed, the blockers and 'Known failures: None' agree with the repository (frontmatter statuses, my release PASS, CI green for 2df637f). My own fixture probe of the hook lists staged, modified, renamed and untracked paths; 19 and 20 files give no remainder line, 21 gives '[1 more…]', 45 gives '[25 more…]'. Three disagreements inside PROGRESS.md are reported as non-blocking (stale pointer in § Next recommended work, the 'fast tier passes on every commit' sentence, 94 lines).
```

### AC-2 Reconstruct state from repository files and Git after compaction or a new session rather than relying on conversational memory — FAIL

```text
The behaviour is present, but the test evidence the requirement names does not show it for resume and compaction (blocking finding 2). Present: my fixture probe of .claude/hooks/session-start.sh with source startup, resume, compact and clear prints the same block each time (branch, HEAD, uncommitted count and list, last verification, 8 commits, PROGRESS.md between delimiters, resume-project instruction); the real hook on the reviewed tree with source=compact exits 0 with 109 lines. Check 12 rejects every matcher that excludes startup, resume or compact (14 own matcher forms; suite cases pass; mutants C1–C3 fail the suite). .claude/skills/resume-project/SKILL.md reconstructs from the repository (fast path and steps 2–7). Not shown: scripts/tests/test-session-start.sh asserts the state content for source=startup only. Mutants S10 (compact injects no state), S11 (resume injects no state) and S12 (only startup injects state) each pass the suite 31/31; with S12 the hook prints 2 lines on resume and compact.
```

### AC-3 At a genuine permission, resource, credential, or session limit, preserve partial results and report the exact unblock action without claiming ongoing execution — PASS

```text
Tests: scripts/tests/test-checker.sh check 7 cases (review running, five claim lines, stop-safe line accepted, words in comments, fences and code spans accepted, negations accepted) and 'missing .env.example' (release run 822/822 over four awks, direct run 211/211; mutants C15–C20 fail the suite); scripts/tests/test-probe-environment.sh 'every reported credential variable is listed in .env.example' (28/28; mutants P1, P2 fail). Own probe of check 7 with 18 lines. Inspections performed: ENVIRONMENT_CAPABILITIES.md § External gaps has six rows with one unblock action each, and its variables ANTHROPIC_API_KEY, OPENAI_API_KEY, OPENAI_BASE_URL are in .env.example; PROGRESS.md § Blockers names the host-disk limit with its action and points to the gaps; the Verification-strategy command, run on `git show 2df637f:docs/PROGRESS.md` in the main checkout, prints no 'not on the remote' line, all 16 named commits are ancestors of a live remote head (`git ls-remote --heads origin`), and the three named branches are listed by `git branch -r`; history shows the stop-safe form at real limits (bb94bf7 usage-limit pause, 4413e4a). WF-002 shows that the worktree kept the partial edits and the lead completed the task. It does not show the 'persisted brief' the Verification strategy states (blocking finding 1); the PASS of this row rests on the other evidence.
```

### AC-4 Do not use infinite loops, arbitrary sleep daemons, or permission bypass flags to simulate unlimited autonomy — PASS

```text
Tests: scripts/tests/test-stop-hook.sh sections 'escalation and release', 'reset on a fresh stop', 'stop_hook_active absent', 'max attempts override' (98/98 in the release run and directly; mutants M1 never release, M2 reset at every stop, M3 one late, M4 one early, M5 open limit range, M6 nested key counts, M7 missing key is fresh, M8 no failure record, M9 silent release all fail the suite); scripts/tests/test-checker.sh check 12 cases for bypassPermissions, dontAsk, skipped prompts, seven hook commands and async (mutants C4–C14 fail the suite). Own fixture probe (make-fixture.sh with-reqs, broken link): exit codes 2, 2, 0 with 'gate attempt 1 of 3', '2 of 3', then {"systemMessage": "Verification gate released after 3 consecutive failed attempts…"} and last-result FAIL; 12 continued stops give 2 blocks; limits 0, 11, word, -1, 03, 1e1, 100 and empty behave as 3; limit 10 blocks 9 times then releases; a nested, listed or quoted stop_hook_active never restarts the count; CLAUDE_VERIFY_GATE=off exits 0 without running verify, and check 12 rejects env.CLAUDE_VERIFY_GATE, env.CLAUDE_VERIFY_MAX_ATTEMPTS, a Stop command that sets a gate variable and disableAllHooks. Check 12 own constructions under PreToolUse, PostToolUse, UserPromptSubmit and SessionStart reject every listed form. Inspection: .claude/hooks/*.sh and scripts/lib/verify-state.sh hold only awk scans bounded by the input length and one read loop over a finite list, with no sleep, background job or daemon; .claude/settings.json has no defaultMode, no skip key, no async hook, and a 1800 s Stop timeout; the only 'sleep' in the tooling is the container keep-alive `sleep infinity` of scripts/dev-container.sh:64, which ADR-009 documents.
```

### Verification runs

```text
- Clone: `git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/verify-ave-req-098` then `checkout -q 2df637f`; HEAD 2df637fbc30b, `git status --porcelain` empty before and after every reported run. No file of the clone was ever changed: all mutants and fixtures lived in the container's /tmp.
- `./scripts/verify.sh --tier release` (development container, arm64) → exit 0, 'verify.sh: PASS — tier release (13 of 13 steps passed)'. Backend unit tests 124 passed; media and population tests 84 passed (354 s); tooling suites test-checker 822/0 (four awks), test-check-baseline 213/0, test-stop-hook 98/0, test-session-start 31/0, test-verify-tiers 48/0, test-probe-environment 28/0; 'Working tree unchanged by verification' PASS; 'Evidence manifest' PASS.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-098 --require-fresh --tier release` → exit 0; 'tier release, PASS, commit 2df637fbc30b'; 'Freshness: FRESH'; AC-1 passed (test-session-start.sh), AC-2 passed (test-checker.sh, test-session-start.sh), AC-3 passed (test-checker.sh, test-probe-environment.sh), AC-4 passed (test-checker.sh, test-stop-hook.sh). Repeated after all probes: same output, still FRESH.
- `grep -rl "AVE-REQ-098" scripts/tests backend/tests` → test-checker.sh, test-probe-environment.sh, test-session-start.sh, test-stop-hook.sh. Direct runs with `./scripts/dev-container.sh bash scripts/tests/<suite>`: test-stop-hook.sh 98/0 exit 0; test-session-start.sh 31/0 exit 0; test-probe-environment.sh 28/0 exit 0; test-checker.sh (system awk) 211/0 exit 0. No skipped or expected-to-fail case in any of them.
- Probe A, Stop gate in a fixture from scripts/tests/make-fixture.sh with-reqs: passing tree exit 0; failing tree 2 ('attempt 1 of 3'), 2 ('attempt 2 of 3'), 0 with systemMessage and 'last-result: FAIL <stamp> <fingerprint>'; further continued stops 0; 12 continued stops → 2 blocks; limits 0, 11, word, -1, 03, ' 3', '3 ', 1e1, empty, 100, 0x3, +3 → 'of 3'; limit 1 releases at the first failure; limit 2 → 2, 0; limit 9 → 'of 9'; limit 10 → 22222222200; 19 stop_hook_active inputs: only an outermost literal false starts a fresh count; CLAUDE_VERIFY_GATE=off → exit 0, no log; OFF and 0 do not disable; counter values abc, -5 and an overflowing number stay bounded; a counter path that is a directory → 2222 (non-blocking finding).
- Probe A, check 12 on a settings file that changes the gate: env.CLAUDE_VERIFY_GATE=off, env.CLAUDE_VERIFY_MAX_ATTEMPTS=1, a Stop command prefixed with CLAUDE_VERIFY_GATE=off (bare and through env), disableAllHooks, Stop removed or empty → exit 1 with the matching error each; a Stop command with ' || true' appended and a Stop handler of type prompt → exit 0 (non-blocking finding, AVE-REQ-097 scope).
- Probe B, check 12 and check 7 with own constructions: all listed AC-4 forms rejected under four hook events; redirects, &&, |& and || accepted; `until false`, `for ((;;))`, `while [ 1 ]`, `--permission-mode bypassPermissions` accepted (outside the listed forms); async true, 'yes' and 1 rejected, false accepted; 14 matcher forms and two-group combinations behave as stated; each of ten PROGRESS.md headings removed → exit 1; 18 claim lines: running, RUNNING, in flight, in-flight, underway rejected; the stop-safe line, negations, comments and code spans accepted.
- Probe D, SessionStart hook in a fixture: sources startup, resume, compact, clear → exit 0, empty stderr, identical state block, 8 commits, compact-specific last line; staged, renamed, deleted and untracked paths listed; 19 and 20 files without remainder, 21 → '[1 more; run git status --short]', 45 → '[25 more; …]'; last verification PASS 'matches the current tree', 'stale: the tree changed since', 'match with the current tree unknown' for a skip-worktree edit, FAIL with the log path. Real hook on the reviewed tree with source=compact → exit 0, 109 lines, 'Last verification: none recorded' although the release run had just passed.
- Mutation, copies of `git archive HEAD` in the container's /tmp, one mutant per suite run, 46 mutants: stop-verify.sh M1–M9 all fail test-stop-hook.sh; session-start.sh S1–S9 fail test-session-start.sh; S10, S11, S12 (no state on compact, on resume, on anything but startup) PASS it 31/31; .env.example and probe mutants P1, P2 fail test-probe-environment.sh; check-project-control.sh C1–C20 and C22 fail test-checker.sh; C21 ('## Known failures' not required) and C23 ('## Next recommended work' not required) PASS it 211/211. Controls: 98/0, 31/0, 28/0, 211/0.
- Remote inspection (read-only, main checkout): the Verification-strategy command on `git show 2df637f:docs/PROGRESS.md` → no 'not on the remote' line; `git ls-remote --heads origin` → main bd12fe8, ccr-af7078da-q8r8mf 547754e, ave-req-094-probe-evidence 8dd0004; eb73896 (12:50) was the task branch head before 2df637f (14:25) and is an ancestor of 8dd0004. `gh run list` → 2df637f success, f894bbf success, 56e5864 failure, bd12fe8 (main) success.
- WF-002 inspection: `git ls-tree -r --name-only 90a1f2e | grep -c '^docs/briefs/'` → 0; `git log --diff-filter=A -- docs/briefs` → the round-2 brief enters with 31e8b84 at 2026-10-02T07:41:56Z, 26 minutes after the completion commit 90a1f2e (07:15:36Z); `git log -S'persisted brief kept the partial work'` → 4d9ef9a; `git log -S'session-local brief plus the worktree diff' -- docs/WORKFLOW_LOG.md` → 0e4f8d9.
- `./scripts/check-project-control.sh` on `git archive 56e5864` → exit 1 ('broken link to ../briefs/2026-10-03-m0-gates-red-team.md'); on 35f99c5 → exit 0.
- Cleanup: `./scripts/dev-container.sh --stop` → container state absent; `rm -rf .claude/worktrees/verify-ave-req-098`; main checkout `git status --porcelain` empty, HEAD 547754e; own scratch files removed.
```

### Blocking findings (2)

1.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:64 (§ Verification strategy, AC-3, at 2df637f; unchanged at 547754e)
defect: A statement of § Verification strategy is false at this commit: 'inspection: WF-002 (an account limit stopped a delegated agent; its worktree and persisted brief kept the partial work and the lead completed it)'. No brief was persisted in the repository at that interruption; the brief was a session-local scratchpad file.
evidence: docs/WORKFLOW_LOG.md WF-002 at 2df637f: 'the round-2 brief was in the session scratchpad when the agent stopped and entered the repository in `31e8b84` (07:41 UTC), after the lead's completion commit `90a1f2e` (07:15 UTC), so that resumption used a session-local brief plus the worktree diff', and its review note 'UNSUPPORTED as first written (the evaluation named an interruption that predates the persisted brief …); corrected in this version'. Git confirms it: `git ls-tree -r --name-only 90a1f2e | grep -c '^docs/briefs/'` → 0, and docs/briefs/2026-10-01-m0-media-core-review-fixes-round-2.md is added by 31e8b84 at 07:41:56Z. The requirement sentence dates from 4d9ef9a; the log was corrected in 0e4f8d9, after the last review at d4d3883, and the requirement was not reworded. docs/ENVIRONMENT_CAPABILITIES.md:105 already says only 'its worktree kept the partial work'.
fix: Reword the inspection item to what WF-002 shows, for example: 'WF-002 (an account limit stopped a delegated agent; its worktree kept the partial edits and the lead completed the task from the session-local brief and the worktree diff; the held-out interruption of run wf_164de68e-23b resumed as wf_df2de811-039 from the committed briefs)'. Log the change in § Status. No code change is needed.
```

2.

```text
location: scripts/tests/test-session-start.sh:79-85 and :103-104, with docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:63 (§ Verification strategy, AC-2)
defect: § Verification strategy states that test-session-start.sh shows 'every session start, resume and compaction injects branch, commits, the uncommitted paths (count and bounded list), last verification and PROGRESS.md'. The suite asserts that content for source=startup only. For compact it asserts the header line and the last line, for resume the last line. The resume and compaction half of AC-2 therefore has no test that fails without the behaviour.
evidence: Three mutants of .claude/hooks/session-start.sh, each in a copy under the container's /tmp: S10 wraps the four print_* calls of main() in `if [ "$source" != compact ]`, S11 in `!= resume`, S12 in `= startup`. Each gives 'SESSION START TOTAL: pass=31 fail=0', exit 0. With S12 the hook prints 2 lines for source=resume and for source=compact (header and instruction, no branch line, no PROGRESS.md block), and the checks 'compact header and re-anchor instruction', 'resume uses the standard instruction' and 'no commits + compact' still pass. The unmutated hook does inject the full block for every source (my probe), so the implementation is correct; the named evidence is what is missing.
fix: In scripts/tests/test-session-start.sh, under the AVE-REQ-098 AC-2 tag, repeat the content assertions for the compact and resume outputs: the '- Branch: … | HEAD: … | Uncommitted paths: N' line, the 8 commit lines, the '- Last verification:' line, the PROGRESS.md delimiters with one heading between them, and the uncommitted list on a dirty tree. A loop over startup, resume and compact around the existing checks does it. Confirm that S10–S12 then fail.
```

### Non-blocking findings (13)

1.

```text
location: docs/PROGRESS.md:60 (at 2df637f)
defect: § Next recommended work item 1 reads 'Record the pending verdicts (§ In progress names each re-run command)', but at this commit § In progress records no launched run, no pending verdict and no re-run command. The pointer has been stale since 13c1b7a removed the stop-safe lines.
evidence: `git log -S'Record the pending verdicts' -- docs/PROGRESS.md` → a10e2df. The diff of 13c1b7a replaces the two 'launched 2026-10-06; verdict not recorded; … re-run …' entries by completed results, and 863c7c2 leaves line 60 untouched. The actual next steps are in § In progress ('Next: one review each with a skeptic at the final commit'; 'Next: count GPU devices only on the task branch …'), so a resuming session is not misled into a wrong action.
fix: Reword item 1 to the state of the commit, for example 'Launch the reviews of AVE-REQ-093/096/097/098 at the final commit (`/verify-requirement AVE-REQ-NNN`, with a skeptic per PASS) and repair AVE-REQ-094 on its branch; on every upheld PASS …'. Keep the parenthesis only while § In progress holds stop-safe lines.
```

2.

```text
location: docs/PROGRESS.md:93-94 (at 2df637f)
defect: 'The fast tier … passes on every commit of this branch (Stop gate)' disagrees with the repository: the committed tree of 56e5864 fails the fast tier's first step. The sentence before it and WF-006 record that failure.
evidence: `./scripts/check-project-control.sh` on `git archive 56e5864` → exit 1, 'ERROR: docs/requirements/AVE-REQ-097-…md: line 87: broken link to ../briefs/2026-10-03-m0-gates-red-team.md'; `gh run list` shows 56e5864 with conclusion failure.
fix: Write 'passes on the working tree at every stop (Stop gate); the committed tree of `56e5864` failed it (WF-006)'.
```

3.

```text
location: docs/PROGRESS.md (at 2df637f)
defect: The file has 94 lines; CLAUDE.md § Context and state and the file's own comment ask for under about 80.
evidence: `wc -l docs/PROGRESS.md` → 94. The SessionStart block is not truncated (cap 120).
fix: Shorten the AVE-REQ-093/097 entry of § In progress to its result and links, and trim § Recently completed entries to one line each.
```

4.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:5 and :12
defect: The review ran while frontmatter status is `in-progress` (verify-requirement § 9 expects `verification`), and the dependencies AVE-REQ-093 and AVE-REQ-094 are `in-progress`, not `done`.
evidence: Frontmatter 'status: in-progress'; the newest Status-log line is '2026-10-06 — in-progress — red-team lens 097-F …'; the TRACEABILITY.md row says in-progress (consistent with the frontmatter); AVE-REQ-093 and AVE-REQ-094 are `in-progress` at 2df637f.
fix: Record the `verification` transition (frontmatter, Status log, TRACEABILITY.md) before the next review, as develop § 6 step 2 states. Move the requirement to `done` only after AVE-REQ-093 and AVE-REQ-094.
```

5.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:62-65
defect: The inspected parts of AC-1, AC-3 and AC-4 state what is inspected but not why no test can judge it, and AC-2 is labelled 'integration' while it also cites an inspection of resume-project/SKILL.md.
evidence: docs/requirements/README.md gives the inspection line as '- AC-n — inspection — <why no test can judge it>'; verify-requirement § 2 asks for a stated reason. Every criterion has tagged tests, so nothing is unevidenced by this alone.
fix: Add the reason to each inspected item (for example 'whether PROGRESS.md matches the work done is a judgment over history that no script can make') and name the AC-2 level 'integration and inspection'.
```

6.

```text
location: scripts/tests/test-checker.sh:134
defect: Only '## Blockers' has a regression case among the PROGRESS.md headings the Verification strategy of AC-1 names; dropping other headings from PROGRESS_HEADINGS goes unnoticed by the suite.
evidence: Mutants C21 ('## Known failures' removed from PROGRESS_HEADINGS) and C23 ('## Next recommended work' removed) pass test-checker.sh 211/211; C22 ('## Blockers') fails it. The checker itself enforces all ten headings (own probe).
fix: Loop the 'missing PROGRESS heading' case over all ten headings, as the brief-heading cases do, and tag it AVE-REQ-098 AC-1.
```

7.

```text
location: .claude/hooks/stop-verify.sh:110-121 (count_failed_attempt)
defect: The fallback that keeps the gate bounded when the counter cannot be stored relies on vstate_set failing. A counter that is written but cannot be read back is counted as 1 at every stop, so the gate blocks without releasing.
evidence: Own construction: with `.git/claude-verify/attempts` as a directory, `mv` puts the temp file inside it, vstate_set returns 0, vstate_get returns nothing; four stops (fresh, continued, continued, continued) → exit codes 2222. The construction is artificial, but it is the one path found where the continuation is unbounded.
fix: After vstate_set, read the value back and treat a mismatch as 'not stored' (fresh stop → 1, else the limit). Add a suite case with the counter path as a directory expecting 2 then 0.
```

8.

```text
location: .claude/hooks/stop-verify.sh:85-94 (max_attempts)
defect: The comment rejects a limit of 0 because it 'would release at the first failure', but the accepted limit 1 also releases at the first failure.
evidence: Own probe: CLAUDE_VERIFY_MAX_ATTEMPTS=1 with a fresh stop on the failing fixture → exit 0, 'released after 1 consecutive failed attempts'. The suite asserts that as intended ('CLAUDE_VERIFY_MAX_ATTEMPTS=1 releases on the first failure'). The gate stays bounded, so this belongs to AVE-REQ-097 AC-3, not to AC-4.
fix: Either accept 2 to 10 only, or reword the comment to 'the N-th consecutive failure releases; 1 never blocks'.
```

9.

```text
location: scripts/check-project-control.sh:538-558 (check 12, Stop command rule)
defect: A settings file can still switch the Stop gate off without failing check 12: the gate command with ' || true' appended, and a Stop handler of type prompt that keeps the command text.
evidence: Own probe in the fixture: both mutations → checker exit 0. The requirement's statements about check 12 (exactly one Stop command, no disableAllHooks, no gate variables) are all true; this gap belongs to AVE-REQ-097 AC-3 ('nothing in the settings file switches it off').
fix: Require type 'command' for the Stop handler and compare the command with the exact registered form (quoted "$CLAUDE_PROJECT_DIR"/.claude/hooks/stop-verify.sh, nothing after it); add both cases to test-checker.sh.
```

10.

```text
location: scripts/check-project-control.sh:484-487 and :1033-1044 (check 12), :357-372 (check 7)
defect: Forms outside the listed ones pass. Hook commands: `until false; do …`, `for ((;;))`, `while [ 1 ]`, `claude --permission-mode bypassPermissions`. PROGRESS.md wording: 'under way', 'still executing', 'ongoing', 'runs now'. The gitignored .claude/settings.local.json is not checked at all.
evidence: Own probe: each form → checker exit 0. Every form § Edge cases lists is rejected, so no statement of the requirement is false. docs/ASSUMPTIONS.md:285 records the three-word rule of check 7. The local settings file is absent on this host.
fix: Either extend the patterns (until, for ((;;)), --permission-mode, 'under way') and run check 12 on settings.local.json when it exists, or state these limits in § Edge cases.
```

11.

```text
location: .claude/hooks/session-start.sh:56-82 and scripts/verify.sh (no vstate_record call)
defect: The 'Last verification' line of the SessionStart block reflects Stop-gate runs only; a manual run of any tier is not recorded, although scripts/lib/verify-state.sh describes last-result as the outcome 'of the last run'.
evidence: After `./scripts/verify.sh --tier release` passed on the reviewed tree, the real hook printed '- Last verification: none recorded (run ./scripts/verify.sh)'. The direction is safe (it never claims a pass that did not happen), and scripts/evidence.py holds the run.
fix: Let verify.sh record its result through vstate_record, or add a line to the block from var/verify/latest-<tier>.json (tier, result, FRESH or STALE), or reword the header of verify-state.sh to 'the last Stop-gate run'.
```

12.

```text
location: docs/ENVIRONMENT_CAPABILITIES.md § External gaps, row 'No Codex credential'
defect: The unblock action defers its exact command to the M5 adapter brief, so it is not yet an exact unblock action in the sense of AC-3.
evidence: 'The human signs the test machine in with the authentication the Codex SDK documents; the adapter's brief (M5) names the exact command'. The gap blocks M5 work only and the row says so.
fix: Name the exact command and variable in this row and in .env.example when the adapter is specified (M5).
```

13.

```text
location: Acceptance scenarios AT-29 and AT-30 (final review, AVE-REQ-100)
defect: Nothing at this commit contradicts either scenario for this requirement. Two observations will matter there.
evidence: AT-30 requires an 'exact resume action'; the stale pointer of PROGRESS.md:60 is the kind of defect it would catch. AT-29 requires that 'forbidden gate weakening is rejected'; the ' || true' Stop command passes check 12.
fix: Close the two findings above before the final review; no action for this requirement beyond that.
```

### Test quality

```text
Checklist of verify-requirement § 8 per criterion. 46 mutants, each in a copy outside the clone; 41 fail their suite, 5 survive.

AC-1: test-session-start.sh, tag at line 60. Assertions are specific (exact list lines, exactly 20 listed, '[6 more; …]', count 26); they fail without the behaviour (S1, S2, S3); the hook under test is the real script in a real Git fixture; nothing is skipped; no timing dependence. Gap: the heading enforcement the strategy names has one case only ('## Blockers'); C21 and C23 survive. The checker itself is correct for all ten headings (own probe). The update of PROGRESS.md after coherent units is verifiable by inspection only; I performed it.

AC-2: test-session-start.sh, tags at lines 36 and 60; test-checker.sh, tag at line 295. Startup content assertions are strong (S4–S9 fail, including 8 commits against 7). Matcher cases are strong (C1, C2, C3 fail; the expected error text is checked, not only the exit code). Blocking gap: the compact and resume checks assert only the header and the last line, so S10, S11 and S12 survive. The compaction half of the criterion has no test that fails without the behaviour, while § Verification strategy says the suite shows it.

AC-3: test-checker.sh, tags at lines 243 and 304; test-probe-environment.sh, tag at line 76. Every word and form of check 7 has a case that fails when its rule is removed (C15 underway, C16 running, C17 in flight, C18 negations, C19 case); the accepted forms are controls that fail when the negation rule is removed. The .env.example cases are independent of the code under test: the probe's reported names are compared with the file (P1, P2 fail), and the required-file case fails under C20. The inspection of WF-002 does not show what the strategy says (blocking finding 1); the other inspections do.

AC-4: test-stop-hook.sh, tag at line 169; test-checker.sh, tag at line 266. The bounded continuation is asserted by exit codes, attempt numbers in the message, valid JSON on release and the recorded FAIL; M1–M9 all fail, including off-by-one in both directions. Each listed hook-command form has its own case and its own failing mutant (C4–C10); async, both modes and skipped prompts likewise (C11–C14). The suites use real scripts in fixture repositories; mocks are limited to stand-in step files. The `check` helpers run strings through eval, yet each prints FAIL and counts; run.sh rejects a suite with zero checks or a failed total. No check depends on timing (one prints a duration without asserting it). Three runs of each suite (release tier, direct, mutation control) gave identical totals.

Executed: all four suites appear in the release run's output with their totals, and evidence.py credits them from that run with the tree FRESH.
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
