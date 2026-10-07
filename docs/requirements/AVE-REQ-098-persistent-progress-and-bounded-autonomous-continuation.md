---
id: AVE-REQ-098
title: Persistent progress and bounded autonomous continuation
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D05]
dependencies: [AVE-REQ-093, AVE-REQ-094]
scenarios: [AT-30, AT-29]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-098.md
---

# AVE-REQ-098 — Persistent progress and bounded autonomous continuation

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-098](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-098.md) (package v1.0); primary gate M0, scope v1.

## Description
Claude Code shall persist actionable progress and continue unblocked work within actual session limits, then leave an exact resumable state.

## Acceptance criteria
- [ ] AC-1 Update the current objective, requirement statuses, blockers, failed checks, changed files, and next command after coherent work units.
- [ ] AC-2 Reconstruct state from repository files and Git after compaction or a new session rather than relying on conversational memory.
- [ ] AC-3 At a genuine permission, resource, credential, or session limit, preserve partial results and report the exact unblock action without claiming ongoing execution.
- [ ] AC-4 Do not use infinite loops, arbitrary sleep daemons, or permission bypass flags to simulate unlimited autonomy.

## Edge cases
- Session compaction or restart → state reconstructed from PROGRESS.md, the repository and Git (AC-2). Check 12
  of `scripts/check-project-control.sh` holds the registration of the SessionStart hook to one written form:
  each group of `hooks.SessionStart` is an object with the keys `hooks` and optionally `matcher`, `hooks` is a
  list, and each handler in it is an object of type `command` with the keys `type`, `command` and optionally
  `timeout` whose command reads exactly `"$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh`. Every other
  form of the registration fails: another key, another handler type, a handler with another command, a
  command that names the script in a comment or as an argument, text before or after the command
  (`false &&`, a redirect, a pipe), a group or a handler that is no object, a matcher that excludes startup,
  resume, clear or compact, and a settings file without such a handler; `disableAllHooks` set to `true` fails
  too (AC-2).
- A `.claude/settings.json` whose top-level value is a list, `null`, a string, a number or a boolean → valid
  JSON for check 3 and no settings object: check 12 fails it with a line of its own (AC-2).
- What check 12 leaves to a reader of the SessionStart registration: the value of `timeout`, a matcher
  written as a regular expression that Claude Code and Python read differently
  ([ASM-014](../ASSUMPTIONS.md)), an `env` entry of the settings file that changes what the command starts
  (`PATH`, `CLAUDE_PROJECT_DIR`), and whether Claude Code accepts the settings file as a whole; the commit
  review judges them, and the state block of a live session start shows the result
  ([ASM-001](../ASSUMPTIONS.md)) (AC-2, inspection).
- Uncommitted files at a session start → listed as `git status --short` prints them: its first 20 lines, and
  from 21 lines on one more line that counts the remainder (AC-1, AC-2).
- A usage limit, permission denial or missing credential mid-task → partial work kept (worktree, commit or
  brief) and the exact unblock action recorded (AC-3); every external gap has one unblock line in
  `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps, with the variables in `.env.example`; the row of the
  Codex credential names its exact command and variable when the adapter is specified (M5, AVE-REQ-052)
  (AC-3).
- The lead's own session ends (limit, restart) → every commit, branch and file PROGRESS.md names is already
  on the remote: the working branch is pushed after each commit and a worktree branch after its handback;
  without push permission PROGRESS.md § Blockers lists the local-only refs with the exact push command (AC-3).
- Delegated work in flight when the session stops → PROGRESS.md records it stop-safe ("launched `<date>`;
  verdict not recorded; on resume without a recorded verdict, re-run `<exact command>`"); check 7 fails on
  PROGRESS.md text with one of the wordings `running`, `underway`, `under way`, `in flight`, `ongoing`,
  `still executing` or `runs now` (any letter case; spaces, tabs, hyphens or a line wrap between the words;
  `nothing is running`, `not running` and `no longer running` pass, also across a line wrap). The check joins
  consecutive lines up to a blank line (a line that holds nothing but spaces, tabs and quote markers) or a
  fenced block, without quote markers, indentation and a closing backslash, so a wrapped paragraph or list
  item is read whole and a wording split over two list items fails too; the error names the line on which
  the wording begins. It reads the text outside fenced blocks, HTML comments and code spans as the checker
  reads those: a fence at any indentation, a comment from its opening marker to the next closing marker over
  any number of lines (to the end of the file when none follows), a code span within one line (a code span
  that a line wrap splits counts as text). The rule knows this list: the commit review and
  `verify-requirement` judge any other wording of the same claim, a listed wording with other characters
  between its words (emphasis marks, a tag, an entity) and text that a Markdown renderer shows while the
  checker takes it for a fence, a comment or a code span; `resume-project` treats an unrecorded verdict as
  work that is not running (AC-3).
- A PROGRESS.md heading that stands only inside a fenced block or an HTML comment → missing for check 7, which
  reads the ten headings as exact lines outside both (AC-1).
- A failing verification gate → bounded retries, then a release with a recorded failure (AC-4).
- No infinite loops, sleep daemons or permission bypass flags in settings, hooks, agents or skills (AC-4):
  check 12 fails on `permissions.defaultMode` set to `bypassPermissions` or `dontAsk`, on
  `skipDangerousModePermissionPrompt` or `skipAutoPermissionPrompt` set to `true`, on a hook command with the
  shell word `while` or `until` (a letter, a digit, `_`, `.`, `/` or `-` directly before or after the word
  makes it part of a name, as in `wait-until-ready.sh` or `--meanwhile`; after `=`, `+`, `:` or a space it
  counts), with the word `for` before `((`, with the word `sleep`, `nohup`, `disown` or `setsid`
  (also inside a file name such as `sleep-check.sh`; a letter, a digit or `_` beside it makes another word,
  as in `usleep`), with an `&` outside `&&`, `|&`, `>&`, `<&` and `&>`, with the text
  `dangerously-skip-permissions` (so `--allow-dangerously-skip-permissions` too) or with `--permission-mode`,
  and on a hook entry with `"async": true` (it runs in the background and escapes its timeout). Checks 4 and
  5 fail agent and skill frontmatter with a key outside a written list (agents: `name`, `description`,
  `tools`, `model`, `color`, `skills`; skills: `name`, `description`, `when_to_use`, `argument-hint`,
  `context`, `agent`, `background`), so `permissionMode`, a `hooks` block and a key of a later Claude Code
  version fail until the list names them; a frontmatter line that is no `key: value` line at column 0, no
  indented continuation of the key above it and no blank line fails too, and so do an indented `---` line
  inside the block and a `README.md` in `.claude/agents/`, which Claude Code would read as an agent. The
  rules know these lists and read `.claude/settings.json`, `.claude/agents/*.md` and
  `.claude/skills/*/SKILL.md`, names that open with a dot included: a loop or a bypass written another way,
  a script the command calls, a hook of another type than `command` under another event, a command of
  another setting than a hook, an `env` entry that changes what a hook command starts, and the other files
  Claude Code takes settings, hooks or permissions from (`.claude/settings.local.json`, the user-level and
  managed settings, a plugin, a command file, an agent file in a subdirectory) are judged by the commit
  review and the inspection of `.claude/hooks/*.sh`.
- A failed-attempt counter of the Stop gate that cannot be stored, or that is stored and reads back as another
  value → the gate still releases: a fresh stop blocks once and a continued stop releases. A counter file counts when it holds a decimal number of one or two digits, read as decimal also with a leading zero; every other content counts as 0, and the counter stops at 99 (AC-4).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/check-project-control.sh` check 7 requires the ten PROGRESS.md headings (current objective, in progress, blockers, known failures, next work and verification status among them) as exact lines outside fenced blocks and HTML comments; `scripts/tests/test-checker.sh` removes each of the ten in turn and places one inside a fenced block and inside a comment; changed files: each coherent unit's commit records them (`git log --stat`), and a session start from each of the four sources (startup, resume, clear, compact) lists the uncommitted paths (`scripts/tests/test-session-start.sh`: the `git status --short` list, 20 lines at most, with cases at 20, 21 and 26 paths); the PROGRESS.md content after each coherent unit is inspected in Git history (`git log -p docs/PROGRESS.md`): whether the file matches the work done is a judgment over history that no script makes.
- AC-2 — integration and inspection — `scripts/tests/test-session-start.sh`: a session start from each of the four sources (startup, resume, clear, compact) injects branch, commits, the uncommitted paths (count and bounded list), last verification and PROGRESS.md; `scripts/tests/test-checker.sh`: check 12 fails a settings file whose top-level value is no object (a list, `null`, a string, a number, a boolean, a list that holds the settings object), a settings file without the SessionStart handler (the event, its groups or the `hooks` object removed), a SessionStart command other than the registered one (output discarded, a pipe, `false &&` before it, the script named in a comment or printed, the path without the project directory, a second command), a handler of another type, a group or a handler with a key outside the written form, a group or a handler that is no object, a group whose handlers are no list, and a matcher that excludes startup, resume, clear or compact, and accepts the four sources as a list, as a regular expression, as `*` and spread over two groups; inspection: `.claude/skills/resume-project/SKILL.md` reconstructs from the repository (a procedure a session follows, which no repository test runs).
- AC-3 — integration and inspection — `.env.example` is a required file (`scripts/tests/test-checker.sh`) and lists every credential variable the probe reports (`scripts/tests/test-probe-environment.sh`); `scripts/tests/test-checker.sh`: check 7 fails on PROGRESS.md text with one of the wordings `running`, `underway`, `under way`, `in flight`, `ongoing`, `still executing` or `runs now`, with a hyphen or a tab between the words and when a line wrap splits the wording (in a list item, a paragraph, a quote, behind a hard line break or a hyphen, over two list items), names the line on which the wording begins, and accepts the stop-safe form, the negations (also in capitals and across a line wrap), the words inside comments, fences and code spans, and words that a blank line or a fenced block separates; inspection, because an interruption at a real limit cannot be staged by a test: WF-002 (an account limit stopped a delegated agent; its worktree kept the partial edits and the lead completed the task from the session-local brief and the worktree diff; the interruption of run `wf_164de68e-23b` resumed as `wf_df2de811-039` from the committed briefs), `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps (one unblock action per gap), PROGRESS.md § Blockers; the lead's own session limit: the remote holds every commit PROGRESS.md names, checked with `grep -oE '[0-9a-f]{7,40}' docs/PROGRESS.md | sort -u | while read -r h; do git cat-file -e "$h^{commit}" 2>/dev/null || continue; git branch -r --contains "$h" | grep -q . || echo "not on the remote: $h"; done` (no output), and every branch it names is listed by `git branch -r`.
- AC-4 — integration and inspection — `scripts/tests/test-stop-hook.sh` (bounded gate attempts, release with a recorded failure, a counter that is stored and reads back as another value, or that cannot be stored, still ends in a release; a counter file written by hand counts as a decimal number of one or two digits and as 0 otherwise); `scripts/tests/test-checker.sh`: check 12 fails on a `bypassPermissions` or `dontAsk` default mode, on `skipDangerousModePermissionPrompt` or `skipAutoPermissionPrompt` set to `true`, on a hook command with the shell word `while` or `until`, the word `for` before `((`, the word `sleep`, `nohup`, `disown` or `setsid`, an `&` that starts a background job, the text `dangerously-skip-permissions` or `--permission-mode`, and on a hook entry with `"async": true`, and accepts loop words inside names, `sleep` inside longer words and the `&` forms of lists and redirects; checks 4 and 5 fail agent and skill frontmatter with `permissionMode`, a `hooks` block, a key of the other kind's list, a line that holds no key or an indented `---` line, also in an agent file and a skill directory whose names open with a dot, and a `README.md` among the agent files, and accept each listed key; inspection of `.claude/hooks/*.sh` for loops and daemons, because the checks know lists of forms and a reader judges any other.
- Acceptance scenarios [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30), [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/PROGRESS.md`, `scripts/check-project-control.sh` check 7 (the ten headings as exact lines outside fenced blocks and HTML comments) — actionable progress after each coherent unit (AC-1)
- `.claude/hooks/session-start.sh` (uncommitted paths as a bounded `git status --short` list) — changed files visible at a session start from each of the four sources (AC-1, AC-2)
- `.claude/hooks/session-start.sh`, `.claude/skills/resume-project/SKILL.md`, `scripts/lib/verify-state.sh`, `scripts/check-project-control.sh` check 12 (the settings file is one JSON object; the SessionStart hook is registered in one written form, with exactly the registered command, for startup, resume, clear and compact) — state reconstructed from the repository and Git (AC-2)
- `docs/briefs/`, worktree isolation, `docs/WORKFLOW_LOG.md` WF-002, PROGRESS.md § Blockers, `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps, `.env.example` (required file) — partial results kept and exact unblock actions recorded (AC-3)
- `CLAUDE.md` § Git, `.claude/skills/develop/SKILL.md` § Parallel work and § 13 (PROGRESS.md names only what the remote holds; in-flight work recorded stop-safe), `.claude/skills/resume-project/SKILL.md` step 5 (an unrecorded verdict is work that is not running), `scripts/check-project-control.sh` check 7 (PROGRESS.md claims no ongoing execution in a listed wording, a wording that a line wrap splits included) — no claim of ongoing execution, partial results reachable after the lead's session ends (AC-3)
- `.claude/hooks/stop-verify.sh` (bounded attempts), `.claude/settings.json` and `scripts/check-project-control.sh` check 12 (permission bypass, skipped prompts, hook commands with loops, sleeps or background jobs and asynchronous hooks fail in the forms § Edge cases lists) and checks 4 and 5 (agent and skill frontmatter holds the listed keys) — no unbounded loops or permission bypass (AC-4)
- Tests: `scripts/tests/test-session-start.sh` — AVE-REQ-098 AC-1, AVE-REQ-098 AC-2; `scripts/tests/test-checker.sh` — AVE-REQ-098 AC-1, AVE-REQ-098 AC-2, AVE-REQ-098 AC-3, AVE-REQ-098 AC-4; `scripts/tests/test-probe-environment.sh` — AVE-REQ-098 AC-3; `scripts/tests/test-stop-hook.sh` — AVE-REQ-098 AC-4
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md), [ASM-001](../ASSUMPTIONS.md), [ASM-014](../ASSUMPTIONS.md), [ASM-019](../ASSUMPTIONS.md), [ASM-030](../ASSUMPTIONS.md)

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-02 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-02 — in-progress — M0 delivery-process gates implemented; criterion evidence under review (lead)
- 2026-10-02 — in-progress — verification levels recorded per criterion; AT-29/AT-30 run at the final review (lead)
- 2026-10-02 — verification — implementation evidence complete; independent verification requested (lead)
- 2026-10-02 — in-progress — verify-requirement FAIL at `4d9ef9a` (workflow `wf_b0c34bba-a20`); blocking findings and fixes in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) (lead)
- 2026-10-06 — in-progress — red-team lens 097-F ([handback part 2](../briefs/handbacks/2026-10-03-m0-gates-red-team.part-2.md)) changed files this requirement relies on: the Stop gate keeps its attempt limit between 1 and 10 and reads the outermost `stop_hook_active` key, check 12 requires exactly one Stop command and rejects `disableAllHooks` and gate variables in the settings file, and the SessionStart block reports no match for a tree the fingerprint cannot see; the review PASS at `d4d3883` predates these changes, so the criteria are verified again with the other M0 requirements (lead)
- 2026-10-06 — in-progress — the review at `d4d3883` (2026-10-03, workflow `wf_ed1f5104-63a`) had returned PASS and its skeptic upheld it; the requirement stayed `in-progress` because the red-team fixes then changed files it relies on (lead)
- 2026-10-06 — in-progress — verify-requirement FAIL at `2df637f` (workflow `wf_7d9d015c-906`; [handback part 8](../briefs/handbacks/2026-10-03-m0-gates-red-team.part-8.md)): AC-2 — the session-start suite asserted the injected content for a startup only, so three mutants that drop it at resume or compaction passed; and the AC-3 strategy cited a persisted brief for the interruption of WF-002, whose brief was session-local. The strategy now states what WF-002 shows and why each inspected item is inspected; the suite cases and the non-blocking items (counter read-back, the exact Stop command in check 12, further loop and wording forms) go through [the fix brief](../briefs/2026-10-06-m0-final-review-fixes.md) (lead)
- 2026-10-06 — in-progress — fixes of the final review merged on branch `m0-final-integration` ([fix brief](../briefs/2026-10-06-m0-final-review-fixes.md), handback parts [2](../briefs/handbacks/2026-10-06-m0-final-review-fixes.part-2.md) and [3](../briefs/handbacks/2026-10-06-m0-final-review-fixes.part-3.md)): the session-start suite asserts the injected content for startup, resume and compact; the failed-attempt counter is read back; check 12 holds the exact Stop command and further loop and bypass forms, check 7 further wordings, each rule stated with the list it knows; the two placeholders of the stop-safe form stand in code spans, as the canonical form now asks (lead)
- 2026-10-06 — verification — fixes of the final review integrated on branch `m0-final-integration`; independent verification with a skeptic requested from [the review brief](../briefs/2026-10-06-m0-final-review-2.md) (lead)
- 2026-10-07 — in-progress — verify-requirement PASS at `f996c17` (workflow `wf_b18a5f3e-54e`, briefed in [the review brief](../briefs/2026-10-06-m0-final-review-2b.md); [handback part 5](../briefs/handbacks/2026-10-06-m0-final-review-2b.part-5.md)) refuted by the skeptic: AC-2 — a SessionStart command that names the hook without running it, and a settings file whose top-level value is no object, pass check 12 and every tagged suite, so the evidence the strategy names stays green with the injection switched off; AC-1, AC-3 and AC-4 upheld. The fixes go through [the fix brief](../briefs/2026-10-07-m0-review-2-fixes.md), track B2 (lead)
- 2026-10-07 — in-progress — fixes of the second review round merged on branch `m0-final-integration` ([the fix brief](../briefs/2026-10-07-m0-review-2-fixes.md), handback parts [4](../briefs/handbacks/2026-10-07-m0-review-2-fixes.part-4.md) and [3](../briefs/handbacks/2026-10-07-m0-review-2-fixes.part-3.md)): a settings file that is no JSON object fails check 12, both hook registrations follow one written form with the exact commands and `clear` among the sources, check 7 joins wrapped lines, agent and skill frontmatter holds listed keys only, and the failed-attempt counter reads one or two decimal digits (lead)
