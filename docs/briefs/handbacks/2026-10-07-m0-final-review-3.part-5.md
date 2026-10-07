# Handback — M0 final review, third round, part 5: AVE-REQ-098

Report of the reviewer for AVE-REQ-098 from workflow run `wf_268ea4f6-bad` at `d7d5604`, briefed in [the review brief](../2026-10-07-m0-final-review-3.md). The verdict is FAIL, so no skeptic ran. The lead filed the report as returned, with local paths shortened to repository paths.

## Review

Verdict: **FAIL** — AVE-REQ-098 — Persistent progress and bounded autonomous continuation (reviewed at d7d56049c98254192201b85cdcfce323adff024f in a private clone; paths below are relative to C:/dev/AI-Video-Editor)

### AC-1 Update the current objective, requirement statuses, blockers, failed checks, changed files, and next command after coherent work units — PASS

```text
Release run (13 of 13 steps, evidence FRESH): scripts/tests/test-checker.sh, ten cases `PROGRESS without '<heading>'` plus `PROGRESS heading only inside a fence` / `... inside an HTML comment` (each four times, once per awk); scripts/tests/test-session-start.sh, the uncommitted-list cases at 2, 20, 21 and 26 paths for startup, resume, clear and compact. Sampled mutants PH-3, PH-FENCE, PH-COMMENT, H-LIST-19, H-LIST-21 and H-REMAINDER-AT-20 all fail their suite. Own probes of check 7: five headings removed in turn give exit 1 with `missing heading`; a heading in a `~~~` fence, in an indented fence, in a multi-line comment, behind an unclosed comment, with one leading space, with a closing `##` and in a code span is missing; trailing spaces count. Inspection of `git log -p docs/PROGRESS.md`: 34 of 92 commits change the file, 5 of the 6 first-parent commits since f996c17 do. At d7d5604 the file agrees with the repository: its 10 in-progress and 5 verification requirements equal the frontmatter, remote `main` is bd12fe8, CI is green at 9fc1579 and d7d5604 (`gh run list`), the suite counts in § Verification status (1477, 424, 174, 77, 133, 256) equal my release run, § Known failures `None` matches it, and § In progress names the next command (workflow script and arguments). The next commit 1697e6e records the launch of this round in the stop-safe form.
```

### AC-2 Reconstruct state from repository files and Git after compaction or a new session rather than relying on conversational memory — FAIL

```text
The behaviour holds at this commit: the real hook on the clone gives, for startup, resume, clear and compact, exit 0, empty stderr, 97 lines, 8 commits and the lines between the PROGRESS.md delimiters equal to the file; both refutations of round 2 are closed (nine forms on a copy of the real tree each give exit 1 with the rule's line) and about 75 own registration forms behave as § Edge cases states. What fails is the evidence for the injected PROGRESS.md: the suite pins it by one heading line, so a hook that injects only headings (10 of 82 lines on the real file, for all four sources) keeps the checker and all four tagged suites green (blocking finding 1). `.claude/skills/resume-project/SKILL.md` step 2 takes PROGRESS.md from that block alone, so the inspected half of the strategy does not cover it either.
```

### AC-3 At a genuine permission, resource, credential, or session limit, preserve partial results and report the exact unblock action without claiming ongoing execution — PASS

```text
PASS for the criterion as written; blocking finding 2 concerns one sentence of its Edge case, not the behaviour the criterion asks for. Release run: test-checker.sh `PROGRESS: review running`, thirteen `PROGRESS claim: ...` cases, four tab cases, ten wrap cases, the accepted forms and `missing .env.example`; test-probe-environment.sh `every reported credential variable is listed in .env.example`. Sampled mutants PC-JOIN, PC-WORDING (ongoing), PC-HYPHEN (still executing), PC-TAB (runs now), PC-NEG-2, PC-QUOTE, PC-BACKSLASH, PC-BLANK, PC-LINE-FIRST, PC-CASE, PC-UNPAIRED, X-ENV and H-ENV-EXAMPLE all fail their suite. Own probe: 19 further constructions of the listed wordings (table cell, sub-heading, nested quote, two-space break, CRLF wrap, link text, emphasis around one word, comment-only line between the words) give exit 1; five accepted forms give exit 0. Inspections performed: PROGRESS.md at d7d5604 read in full, no claim of ongoing execution in any wording; its history holds none after 4d9ef9a and records the launches at fc068d8, b318f29 and 1697e6e stop-safe; WF-002 and WF-012 (host standby, 2026-10-07) show partial results kept in worktrees and resumed from committed briefs; `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps has six rows with one unblock action each and its three variables are in `.env.example`; the strategy's command on `git show d7d5604:docs/PROGRESS.md` prints no `not on the remote` line, the eight commits it names and d7d5604 are ancestors of live remote heads (`git ls-remote --heads origin`), and its three branches exist on the remote.
```

### AC-4 Do not use infinite loops, arbitrary sleep daemons, or permission bypass flags to simulate unlimited autonomy — PASS

```text
Release run: test-stop-hook.sh sections `escalation and release`, `reset on a fresh stop`, `stop_hook_active absent`, `max attempts override`, `a counter written by hand`, `a counter that cannot be read back or stored` (174 checks); test-checker.sh `settings: ...`, `hook command: ...`, `tool hook command: ...`, the accepted controls, the async cases and the frontmatter cases. Sampled mutants H-NEVER-RELEASE, H-NO-FAIL-RECORD, H-READ-BACK-ONLY, H-FALLBACK-ONE, S01, S04, MODE-DONTASK, SKIP-AUTO, U-UNTIL, U-LB-dash, U-FOR-SPACE, U-WORD-setsid, U-AMP-GONE, U-DSP, ASYNC, FM-NOKEY, FM-README, FM-INDENTED-CLOSE and FM-DOT-AGENTS all fail their suite; own mutants (release one late, limit range opened, a missing key read as a fresh stop, the command rule limited to one kind of event, skill frontmatter not judged) fail too. Own probe of the gate: fresh, continued, continued, continued gives 2, 2, 0, 0; limits 1, 2, 3, 9, 10 block 0, 1, 2, 8, 9 times and 0, 11, abc, 03, ' 3' behave as 3; a counter path that is a directory gives 2, 0, 0. Own probe of check 12: 31 constructions of the listed forms under seven hook events give exit 1, 21 accepted forms exit 0; `async` true, 1, 'true' fail and false, null pass under PostToolUse; both default modes and both prompt keys (top level and nested) fail. Checks 4 and 5: 25 foreign keys and 14 line forms fail, the listed keys pass. Inspection: `.claude/hooks/*.sh` and `scripts/lib/verify-state.sh` loop over finite input only and start no sleep or background job; `.claude/settings.json` holds no default mode, skipped prompt or async hook; agent and skill frontmatter hold listed keys only; no bypass word in tracked files outside docs, the checker and its suite; CI has no schedule trigger.
```

### Verification runs

```text
- Clone: `git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf` of the main checkout into .claude/worktrees/verify-ave-req-098, checkout d7d5604; `git rev-parse HEAD` printed d7d56049c98254192201b85cdcfce323adff024f. `git status --porcelain` was empty before and after the release run and at the end; every mutant, fixture and probe lived in the container's /tmp.
- `./scripts/verify.sh --tier release` (development container, arm64; waited for the heavy-media lock first) -> exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`: backend 132 passed (fast) and 84 passed (media and population, 481 s); test-checker.sh 1477 checks over four awks, test-check-baseline.sh 424, test-stop-hook.sh 174, test-session-start.sh 77, test-verify-tiers.sh 133, test-probe-environment.sh 256; `Working tree unchanged by verification` PASS; `Evidence manifest` PASS (58 criteria tagged). No skipped or expected-to-fail case; the tagged cases appear as `ok` in the log (checker cases four times).
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-098 --require-fresh --tier release` -> exit 0: tier release, PASS, commit d7d56049c982, `Freshness: FRESH`; AC-1 passed (test-checker.sh, test-session-start.sh), AC-2 passed (the same two), AC-3 passed (test-checker.sh, test-probe-environment.sh), AC-4 passed (test-checker.sh, test-stop-hook.sh). With `--require-complete` -> exit 0.
- Suites on a copy of `git archive HEAD` in the container's /tmp (controls of the mutation run): test-checker.sh 377/0 (system awk), test-stop-hook.sh 174/0, test-session-start.sh 77/0, test-probe-environment.sh 256/0.
- Mutation, 69 one-change mutants, each in a fresh copy with its own TMPDIR and `__pycache__` removed: 49 sampled from the fix handbacks (parts 4 and 3) -> 49 fail a named case; 20 own -> 10 fail, 10 survive: session-start.sh `NR <= max { print }` -> `NR <= max && /^#/ { print }`, -> `/^## Known failures$/ { print }`, -> `NR < max { print }`, and `git log ... --skip=1` (test-session-start.sh 77/0 each); check 12 `if form and handler.get("async") ...`, the recursion of skipped_prompts removed, a non-string matcher read as matching, an invalid regex read as matching, `re.search` -> `re.fullmatch`; check 7 headings `rtrim` -> `trim` (test-checker.sh 377/0 each).
- Headings-only mutant on a copy of the real tree: block of 18 lines with 10 of the 82 PROGRESS.md lines for startup, resume, clear and compact, no truncation note; `./scripts/check-project-control.sh` -> exit 0 `OK: 51 required files ...`; test-session-start.sh 77/0, test-stop-hook.sh 174/0, test-probe-environment.sh 256/0, test-checker.sh 377/0.
- Round-2 refutation repeated on a copy of the real tree: SessionStart command `true # .claude/hooks/session-start.sh`, the registered command with ` >/dev/null`, with ` | head -n 1`, behind `false && `, and `echo .claude/hooks/session-start.sh` -> exit 1 each with `must run the SessionStart hook ... it reads exactly ...` and `no SessionStart hook runs ...`; settings file `[]`, `null`, `"hooks"`, `[{"hooks":{}}]` -> exit 1 each with `the top-level value is <kind>; the settings file is one JSON object ...`. Round-2 non-blocking findings 3, 4, 5 repeated: matcher `startup|resume|compact`, `permissionMode` in implementer.md, a `hooks` block in develop/SKILL.md, four wrapped wordings and the two hyphen forms in PROGRESS.md -> exit 1 each. Control: unchanged tree exit 0.
- Probe of check 7 in a fixture (scripts/tests/make-fixture.sh with-reqs): 19 own wording constructions -> exit 1; `- ... still` / `- executing ...` -> exit 1 and the nested `-` form -> exit 1; the same split with `*`, with `+` and with `1.` / `2.` -> exit 0 (blocking finding 2); negations across a wrap, words that contain a claim word, a blank quote line and the stop-safe line -> exit 0.
- Probe of check 12 in a fixture: ten top-level values that are no object -> exit 1 with the rule's line; 16 command forms, six handler types, seven handler keys, three group keys -> exit 1; 20 matcher forms as § Edge cases states; `disableAllHooks` true, 'true', 1, '' -> exit 1 and false, null, 0 -> exit 0; matchers `s|r|c|,`, `start|resume|clear|compact|,`, `tart|esum|lea|ompac| ` -> exit 0 and `startup, resume, clear, compact` -> exit 1 (non-blocking finding 1); a PostToolUse handler with `"asyncRewake": true` -> exit 0 (non-blocking finding 3).
- Probe of the Stop gate in a fixture repository with a failing verify.sh: exit codes 2 (`gate attempt 1 of 3`), 2 (`2 of 3`), 0 (`released after 3 consecutive`), 0; counter contents with limit 10: `5`, `05` -> attempt 6, `08` -> attempt 9, `98` and `99` -> release at 99, `100`, `007`, ` 5`, `5 `, `+5`, `0x5`, `5.0`, empty -> attempt 1; `5\n6\n`, `5\nabc\n`, `5\r\n` -> attempt 6 and `9\n9\n` -> released after 10 (non-blocking finding 5).
- Real SessionStart hook on the clone: sources startup, resume, clear, compact -> exit 0, 0 bytes on stderr, 97 lines, 8 commits, PROGRESS.md between the delimiters equal to the file; block size 6,541 characters. In a fixture, an 80-line PROGRESS.md of 9,031 characters gives a block of 10,244 characters with no truncation note (non-blocking finding 2).
- Remote and CI inspection, read-only from the main checkout: `git ls-remote --heads origin` -> main bd12fe8, m0-final-integration d5e062c, ccr-af7078da-q8r8mf 7c9a6b4, ave-req-094-probe-evidence b4f503f; d7d5604 and the eight commits PROGRESS.md names are ancestors of those heads; `gh run list` -> success at 9fc1579, d7d5604, 1697e6e, d5e062c.
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py` -> `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`; no note names AVE-REQ-098.
- Public Claude Code references read as data on 2026-10-07 (code.claude.com/docs/en/hooks.md and the schemastore settings schema): matcher rule, the 10,000-character cap on hook stdout, the handler fields `async` and `asyncRewake`. No Claude Code session was started; host `claude --version` prints 2.1.282.
- Cleanup: backend environment removed (`rm -rf "$UV_PROJECT_ENVIRONMENT"`), `./scripts/dev-container.sh --stop` -> container state absent, clone removed; main checkout `git status --porcelain` empty.
```

### Blocking findings (2)

1.

```text
location: scripts/tests/test-session-start.sh:60 (also :112 and :59), with docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:115 and .claude/skills/resume-project/SKILL.md:25
defect: AC-2 is unevidenced for the injected PROGRESS.md. The suite's only assertion on it is that the line `## Known failures` stands between the two delimiters; the fixture file has 12 lines, ten of them headings. No check holds a body line, the number of lines or equality with the file, and the cap case asserts the truncation note and the absence of `line 109` without the presence of `line 108`. The hook can therefore stop injecting everything but headings, for all four sources, while the checker and every tagged suite stay green. The resume procedure takes PROGRESS.md from this block alone (`Read docs/PROGRESS.md only when the block is missing or truncated`), so the inspected half of the strategy does not cover the gap. This is the class of the first round's blocking finding: mutants that drop injected content pass the suite.
evidence: One change each to `.claude/hooks/session-start.sh:100` (`NR <= max { print }`) in a copy of `git archive d7d5604`: `NR <= max && /^#/ { print }` -> test-session-start.sh 77/0; `/^## Known failures$/ { print }` -> 77/0; `NR < max { print }` -> 77/0. Controls from the handback fail as stated (print_progress removed for resume -> 76/1; RECENT_COMMITS=7 -> 73/4). The headings-only mutant on the real tree: block of 18 lines holding 10 of 82 PROGRESS.md lines (no objective, in-progress entries, blockers or next work), no truncation note, identical for startup, resume, clear and compact; `./scripts/check-project-control.sh` exit 0; test-session-start.sh 77/0, test-stop-hook.sh 174/0, test-probe-environment.sh 256/0, test-checker.sh 377/0. The unmutated hook injects the file whole for the four sources, so the behaviour itself holds at this commit.
fix: In test-session-start.sh, inside `every`, compare the lines between the delimiters with the fixture's docs/PROGRESS.md byte for byte, and give the fixture file body lines under several headings; in the cap case assert exactly 120 lines between the delimiters, `line 108` present and `line 109` absent. Run the three mutants again and name them in the handback.
```

2.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:69-71 (§ Edge cases), with scripts/check-project-control.sh:469-482 and :494, docs/ASSUMPTIONS.md:309-310 (ASM-019), scripts/tests/test-checker.sh:431-433
defect: The sentence `a wording split over two list items fails too` is false for list items marked `*`, `+` or with a number. `join_line` removes quote markers and indentation, not list markers; the split fails with `-` only because the hyphen belongs to the separator class `[ \t-]+`. With any other marker the marker stands between the two words and check 7 passes. PROGRESS.md itself holds an ordered list (§ Next recommended work). The limit sentence names emphasis marks, a tag and an entity between the words, no list marker, and the sentence states the failure without restriction; ASM-019 and the checker comment at :445-447 repeat it.
evidence: Fixture probes, inserted under `## In progress`: `* The review of AVE-REQ-001 is still` / `* executing in the workflow.` -> exit 0; the same with `+` -> exit 0; `1. ...` / `2. ...` -> exit 0. Controls: `- ...` / `- ...` -> exit 1 `line 7: claims ongoing execution`; `- ...` / `  - ...` -> exit 1. The suite's one case (`PROGRESS claim split over two list items`) uses `-`. The criterion's behaviour is unaffected: PROGRESS.md holds no such claim.
fix: Either remove one list marker (`-`, `*`, `+`, or digits followed by `.` or `)`, then a space) from the start of each line in `join_line` and add the three cases beside test-checker.sh:431, or reword the sentence in § Edge cases, in ASM-019 and in the checker comment to `two list items marked -` and name the other markers in the limit sentence.
```

### Non-blocking findings (6)

1.

```text
location: scripts/check-project-control.sh:583-585 and :688-698 (matches), docs/ASSUMPTIONS.md:239-247 (ASM-014), scripts/tests/test-checker.sh:536
defect: Check 12 classifies a matcher by an older rule than the current hooks reference. The checker treats only letters, digits, `_`, `-` and `|` as a list of exact names and everything else as an unanchored regular expression. The reference now reads a matcher of letters, digits, `_`, `-`, spaces, `,` and `|` as a list of exact names split on `|` or `,`. A matcher with a stray comma or space is thus a regular expression for the checker and an exact list for Claude Code: it can pass check 12 while matching no source. In the other direction the suite case `SessionStart comma list is a regex matching nothing` encodes the old rule and check 12 rejects a comma list the reference accepts (safe). I class it non-blocking because the limit sentence leaves matchers that the two readers read differently to the commit review, and because no live session start could be run here to confirm the installed version (2.1.282).
evidence: Fixture probes: matcher `s|r|c|,` -> exit 0; `start|resume|clear|compact|,` -> exit 0; `tart|esum|lea|ompac| ` -> exit 0; `startup, resume, clear, compact` and `startup,resume,clear,compact` -> exit 1. Reference (code.claude.com/docs/en/hooks.md, read 2026-10-07): `Only letters, digits, _, -, spaces, ,, and | — Exact string, or list of exact strings separated by | or , with optional surrounding whitespace`; `Contains any other character — JavaScript regular expression, unanchored`.
fix: Classify by the reference: when the matcher holds only those characters, split on `|` and `,`, trim, and compare exact names; otherwise search as a regular expression. Change the comma case to an accepted one, add `s|r|c|,` as a failing case, and update ASM-014 and the comment above check 12.
```

2.

```text
location: .claude/hooks/session-start.sh:22 and :98-103, with § Edge cases of the requirement file (no sentence)
defect: Unstated limit: the hook bounds the block by lines (120 of PROGRESS.md), while Claude Code caps hook stdout at 10,000 characters and then passes a file path with a preview of the first 2,000 characters. A PROGRESS.md inside its own documented size (about 80 lines, wrapped near 120 columns) can push the block over the cap; the hook prints no truncation note then, and the session receives the header, the commits and the first lines of PROGRESS.md only. The Stop hook is sized for this cap (stop-verify.sh:32); the SessionStart hook is not. Today the block has room: 6,541 characters.
evidence: Real hook on the clone: 97 lines, 6,541 characters (PROGRESS.md 5,287). Fixture with eight commits and an 80-line PROGRESS.md: 7,281 characters -> block 8,494; 9,031 characters -> block 10,244, `[truncated` printed 0 times. Reference, read 2026-10-07: `A hook's additionalContext, systemMessage, and initialUserMessage strings, and its plain stdout, are capped at 10,000 characters` and `writes the text to a file ... with a preview of up to the first 2,000 characters`.
fix: Bound the block in characters as well (stop PROGRESS.md at a budget that keeps the whole block under 10,000 and print the hook's own truncation note), with a suite case at the boundary; or state the limit in § Edge cases and let check 7 fail a PROGRESS.md above a character count.
```

3.

```text
location: scripts/check-project-control.sh:727 and :677 (HANDLER_KEYS applies to SessionStart and Stop only)
defect: A command hook under any other event with `"asyncRewake": true` passes check 12. The field is the sibling of `async`: the hook runs in the background and wakes the model when it exits with code 2, also while the session is idle. That is a way to keep a session going from a hook, which AC-4 is about. § Edge cases names `async` only; the form falls under the limit `written another way`, and no hook of this tree uses it.
evidence: Fixture probe: `hooks.PostToolUse = [{hooks: [{type: command, command: scripts/note.sh, asyncRewake: true}]}]` -> exit 0, while `async: true` in the same place -> exit 1. Settings schema and hooks reference, read 2026-10-07: `asyncRewake — If true, runs in the background and wakes Claude on exit code 2`, `an asyncRewake hook that exits with code 2 wakes Claude immediately even when the session is idle`.
fix: Fail `asyncRewake` with any value other than false or null on every event, beside the `async` rule, with a suite case; or hold the handlers of every event to a list of keys, as the two registrations are.
```

4.

```text
location: scripts/tests/test-checker.sh:495-496
defect: No case holds `"async": true` under an event other than SessionStart and Stop. On those two events the key list already fails the key, so the async rule's own reach is the other events, and that reach has no failing case. The implementation is correct.
evidence: Mutant `if form and handler.get("async") not in (None, False):` (rule limited to the two registered events) -> test-checker.sh 377/0. On the unchanged code a PostToolUse handler with `async` true, 1 or 'true' gives exit 1.
fix: Add `tool hook entry with async true` on a PreToolUse handler, expecting `hooks.PreToolUse[0] runs a hook asynchronously`.
```

5.

```text
location: docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md:107 and :117, with scripts/lib/verify-state.sh:85-90 and .claude/hooks/stop-verify.sh:116-123
defect: `A counter file counts when it holds a decimal number of one or two digits ...; every other content counts as 0` is exact only for a one-line file. The gate reads the first line without a trailing carriage return, so a file whose first line is such a number counts by it whatever follows. The gate stays bounded in every case, so the criterion is untouched; with the record format in mind the sentence can be read as true, which is why I class it as wording.
evidence: Fixture probe, one continued stop with limit 10: `5\n6\n` -> `gate attempt 6 of 10`; `5\nabc\n` -> attempt 6; `5\r\n` -> attempt 6; `9\n9\n` -> `released after 10 consecutive`. One-line contents behave as the sentence says (`007`, `100`, ` 5`, `+5`, `0x5` -> attempt 1).
fix: Write `counts when its first line is a decimal number of one or two digits` in § Edge cases, in the AC-4 strategy line and in the suite comment at test-stop-hook.sh:367-369.
```

6.

```text
location: scripts/tests/test-session-start.sh:59; scripts/tests/test-checker.sh:535-538 and :157-164
defect: Further details without a failing case; the implementation is correct in each. (a) The commit list is counted, not identified: a list that leaves out the newest commit passes. (b) Matcher semantics: the two regular-expression cases are anchored, and no case holds a matcher that is no string or an invalid expression. (c) `exact lines` of the heading rule: no case with an indented heading. Also unstated for the heading rule: a heading inside a raw HTML block such as `<pre>` counts as present.
evidence: Surviving mutants: `git log ... --skip=1 -n "$RECENT_COMMITS"` -> test-session-start.sh 77/0; `re.search` -> `re.fullmatch`, a non-string matcher read as matching, an invalid expression read as matching -> test-checker.sh 377/0 each; headings `rtrim` -> `trim` -> 377/0. Probes on the unchanged code: matchers 123, a list, `[` -> exit 1; ` ## Blockers` -> exit 1 `missing heading`; `<pre>` / `## Blockers` / `</pre>` -> exit 0.
fix: Assert the subjects of the first and the last listed commit (`chore: commit 10`, `chore: commit 3`); add matcher cases for an unanchored expression that covers the four sources, a number and `[`; add a heading case with one leading space; name the HTML block in the limit sentence or leave it to the proposed canonical form of PROGRESS.md (ASM-041).
```

### Statement-audit samples

```text
Statement-audit table of AVE-REQ-098 (fix handback part 4, with part 3 for the counter): 13 of its 16 rows sampled by running mutants again, 49 mutants in all, every one fails a named case.
- Row 36-45 (registration in one written form): SS-EXACT (7 cases fail), SS-CONTAIN, GKEYS, HKEYS, SRC-clear, NO-HOOK, DISABLE — all fail.
- Row 46-47 (top-level value no object): S-OBJ — fails the six `settings: top-level ...` cases.
- Row 54-55 (uncommitted list): H-LIST-19, H-LIST-21, H-REMAINDER-AT-20 — fail.
- Row 56-60 (unblock action, .env.example): X-ENV, H-ENV-EXAMPLE — fail.
- Row 64-79 (check 7): PC-JOIN (12 cases), PC-WORDING ongoing, PC-HYPHEN still executing, PC-TAB runs now, PC-NEG-2, PC-QUOTE, PC-BACKSLASH, PC-BLANK, PC-LINE-FIRST (30 cases), PC-CASE, PC-UNPAIRED — all fail.
- Row 80-81 (heading in a fence or comment): PH-FENCE, PH-COMMENT — fail.
- Row 82 (bounded retries, recorded failure): H-NEVER-RELEASE (14 checks), H-NO-FAIL-RECORD — fail.
- Row 83-105 (check 12 forms, checks 4 and 5): MODE-DONTASK, SKIP-AUTO, U-UNTIL, U-LB-dash, U-FOR-SPACE, U-WORD-setsid, U-AMP-GONE, U-DSP, ASYNC, FM-NOKEY, FM-README, FM-INDENTED-CLOSE, FM-DOT-AGENTS — all fail.
- Row 106-107 (counter): H-READ-BACK-ONLY, H-FALLBACK-ONE, S01, S04 — fail.
- Row 114 (AC-1 strategy): PH-3 and the list mutants — fail.
- Row 115 (AC-2 strategy): H-NO-PROGRESS-resume, H-NO-GIT-STATE-clear, H-COMMITS-7 — fail. The row's claim holds for these mutants; the same row does not pin what PROGRESS.md content is injected (blocking finding 1).
- Rows 116 and 117 (AC-3 and AC-4 strategy): covered by the mutants above.
- Rows 48-53, 61-63 and 121-128 judged by inspection: the limits are worded as limits; the remote command prints nothing; the files, sections and tags of § Implementation evidence exist (resume-project step 5, develop § Parallel work line 127 and § 13 lines 223-224, CLAUDE.md § Git).

Sentences checked against the tree from scratch (own probes, not the suite's cases):
1. Edge cases 46-47, top-level list, null, string, number, boolean fail check 12 by a line of their own — true (ten values).
2. Edge cases 36-45, every other form of the registration fails — true for every form the sentence names (16 commands, six types, ten keys, 20 matchers); see non-blocking finding 1 for matchers with a comma or space.
3. Edge cases 69-71, `a wording split over two list items fails too` — false for `*`, `+` and numbered items (blocking finding 2); the rest of the check 7 sentences hold (letter case, tabs, hyphens, wraps, negations across a wrap, the named line, fences, comments, code spans).
4. Edge cases 80-81, a heading only inside a fence or a comment is missing — true.
5. Edge cases 83-105, the check 12 forms and the frontmatter lists — true: the six characters beside a loop word, `=`, `+`, `:` and a space, `for` before `((`, `sleep` in a file name and in longer words, the five `&` forms, both flag texts, async, both key lists, the line forms, the indented `---`, README.md, names that open with a dot.
6. Edge cases 106-107, the counter — true for one-line contents and for the unstorable counter; inexact for a file with further lines (non-blocking finding 5).
7. Edge cases 54-55 and 56-63 — true (real hook, § External gaps, .env.example, remote heads).
8. Verification strategy AC-3, the remote command — no output; WF-002 agrees with the log.
9. Verification strategy AC-2, `injects ... PROGRESS.md` — true of the hook, shown by the suite through one heading only (blocking finding 1).

Round-2 findings and dispositions sampled: the refutation (both forms) is closed, nine forms repeated on the real tree; non-blocking 1 (exact command), 3 (wraps), 4 (frontmatter, flag text), 5 (clear), 6 (hyphen forms, 20-path boundary, unstorable counter), 7 (Codex sentence), 8 (Status log names brief 2b, the matrix row lists inspection for AC-2), 9 (the next command names script and arguments; the file has 82 lines against about 80) and 10 (counter read as decimal) are applied as their dispositions say.
```

### Test quality

```text
Checklist of verify-requirement § 8 per criterion. The suites run the real hooks and the real checker in fixture repositories; a shell suite is credited per suite result, and I confirmed in the release log that the cases under each tag ran (checker cases once per awk, four awks). 69 mutants, each in a copy outside the clone: 59 fail their suite, 10 survive, all 10 from my own set of 20.

AC-1: test-checker.sh, tag at line 150; test-session-start.sh, tag at line 79. The heading cases take the ten headings from a list written in the suite and assert the exact error line; the list cases assert exact lines and counts at 2, 20, 21 and 26 paths for each source. Every sampled mutant fails. Gap: no case with an indented heading, so `exact lines` is pinned only by the fence and comment cases (non-blocking finding 6). Whether PROGRESS.md matches the work is judged by inspection; I performed it.

AC-2: test-session-start.sh, tags at lines 36, 50 and 79; test-checker.sh, tags at lines 527, 545, 558 and 572. The registration rules are strong: each case asserts the rule's own line, and seven sampled mutants plus the non-object mutant fail. The state block is asserted per source for the branch line, the verification record, the uncommitted list and the last line, with exact text. The PROGRESS.md part fails the checklist items `Assertion strength` and `Fails without the behavior`: one heading line stands for the whole file, the cap is asserted from one side, and three mutants that drop or shorten the injected file survive for all four sources (blocking finding 1). The commit list is counted, not identified, and matcher semantics have three surviving mutants (non-blocking finding 6).

AC-3: test-checker.sh, tags at lines 380, 397 and 582; test-probe-environment.sh, tag at line 312. Each wording, each separator and each joining rule has a case that fails when the rule is removed (eleven sampled mutants); the accepted forms are controls that fail when the negation, comment, fence or code-span rule goes. The `.env.example` check compares two independent sources. Gap: the split over two list items is asserted with `-` only, which is where the Edge-case sentence is wrong (blocking finding 2). The inspections show what the strategy says they show.

AC-4: test-stop-hook.sh, tags at lines 314, 367 and 388; test-checker.sh, tags at lines 181 and 460. The bound is asserted by exit codes, attempt numbers, valid JSON on release and the recorded FAIL; off-by-one in both directions, an opened limit range and a missing key read as a fresh stop all fail. Each listed hook-command form has a case under PreToolUse, where no rule on the Stop command takes part, and a failing mutant. Gaps: `async` true has a case on the Stop entry only (non-blocking finding 4); a nested prompt key has no case, and § Edge cases claims none. No check depends on timing.

Executed: the four suites appear in the release run with their totals, none skipped, and evidence.py credits them from that run with the tree FRESH. Release run, direct control run and the handback's totals agree (377 per awk, 174, 77, 256).

AT-29 and AT-30: nothing at this commit contradicts either scenario for this requirement beyond the findings above; non-blocking findings 1 and 3 are the ones AT-29 (a forbidden gate weakening is rejected) would meet.
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
