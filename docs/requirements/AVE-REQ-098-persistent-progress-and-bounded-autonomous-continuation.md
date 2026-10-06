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
- Session compaction or restart → state reconstructed from PROGRESS.md, the repository and Git (AC-2); a
  SessionStart matcher that excludes startup, resume or compact fails `scripts/check-project-control.sh`
  check 12 (AC-2).
- Uncommitted files at a session start → listed by path, at most 20 lines, with the remainder counted (AC-1,
  AC-2).
- A usage limit, permission denial or missing credential mid-task → partial work kept (worktree, commit or
  brief) and the exact unblock action recorded (AC-3); every external gap has one unblock line in
  `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps, with the variables in `.env.example` (AC-3).
- The lead's own session ends (limit, restart) → every commit, branch and file PROGRESS.md names is already
  on the remote: the working branch is pushed after each commit and a worktree branch after its handback;
  without push permission PROGRESS.md § Blockers lists the local-only refs with the exact push command (AC-3).
- Delegated work in flight when the session stops → PROGRESS.md records it stop-safe ("launched `<date>`;
  verdict not recorded; on resume without a recorded verdict, re-run `<exact command>`"); check 7 fails on a
  PROGRESS.md line with one of the wordings `running`, `underway`, `under way`, `in flight`, `ongoing`,
  `still executing` or `runs now` (any letter case; spaces or hyphens between the words; `nothing is running`,
  `not running` and `no longer running` pass). The rule knows this list: the commit review and
  `verify-requirement` judge any other wording of the same claim, and `resume-project` treats an unrecorded
  verdict as work that is not running (AC-3).
- A failing verification gate → bounded retries, then a release with a recorded failure (AC-4).
- No infinite loops, sleep daemons or permission bypass flags in settings or hooks (AC-4): check 12 fails on a
  `bypassPermissions` or `dontAsk` default mode, a skipped permission prompt, a hook command with
  the shell word `while` or `until` (a loop word inside a file name or an option, as in `wait-until-ready.sh`
  or `--meanwhile`, is none), a `for ((` loop, `sleep`, `nohup`, `disown`, `setsid`, a background `&`,
  `--dangerously-skip-permissions` or `--permission-mode`, and a hook entry with `"async": true` (it runs in the
  background and escapes its timeout). The rule knows this list and reads `.claude/settings.json`: a loop or a
  bypass written another way, a script the command calls, `.claude/settings.local.json` and the user-level
  settings are judged by the commit review and the inspection of `.claude/hooks/*.sh`.
- A failed-attempt counter of the Stop gate that cannot be stored, or that is stored and reads back as another
  value → the gate still releases: a fresh stop blocks once and a continued stop releases (AC-4).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/check-project-control.sh` enforces the PROGRESS.md headings (current objective, in progress, blockers, known failures, next work, verification status), and `scripts/tests/test-checker.sh` fails check 7 for each of the ten headings when it is missing; changed files: each coherent unit's commit records them (`git log --stat`), and every session start lists the uncommitted paths (`scripts/tests/test-session-start.sh`: the `git status --short` list, bounded at 20 lines); the PROGRESS.md content after each coherent unit is inspected in Git history (`git log -p docs/PROGRESS.md`): whether the file matches the work done is a judgment over history that no script makes.
- AC-2 — integration and inspection — `scripts/tests/test-session-start.sh`: every session start, resume and compaction injects branch, commits, the uncommitted paths (count and bounded list), last verification and PROGRESS.md; `scripts/tests/test-checker.sh`: check 12 fails when the SessionStart hook is missing or its matcher excludes startup, resume or compact; inspection: `.claude/skills/resume-project/SKILL.md` reconstructs from the repository (a procedure a session follows, which no repository test runs).
- AC-3 — integration and inspection — `.env.example` is a required file (`scripts/tests/test-checker.sh`) and lists every credential variable the probe reports (`scripts/tests/test-probe-environment.sh`); `scripts/tests/test-checker.sh`: check 7 fails on a PROGRESS.md line with one of the wordings `running`, `underway`, `under way`, `in flight`, `ongoing`, `still executing` or `runs now`, and accepts the stop-safe form, negations and the words inside comments, fences and code spans; inspection, because an interruption at a real limit cannot be staged by a test: WF-002 (an account limit stopped a delegated agent; its worktree kept the partial edits and the lead completed the task from the session-local brief and the worktree diff; the interruption of run `wf_164de68e-23b` resumed as `wf_df2de811-039` from the committed briefs), `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps (one unblock action per gap), PROGRESS.md § Blockers; the lead's own session limit: the remote holds every commit PROGRESS.md names, checked with `grep -oE '[0-9a-f]{7,40}' docs/PROGRESS.md | sort -u | while read -r h; do git cat-file -e "$h^{commit}" 2>/dev/null || continue; git branch -r --contains "$h" | grep -q . || echo "not on the remote: $h"; done` (no output), and every branch it names is listed by `git branch -r`.
- AC-4 — integration and inspection — `scripts/tests/test-stop-hook.sh` (bounded gate attempts, release with a recorded failure, a counter that is stored and reads back as another value still ends in a release); `scripts/tests/test-checker.sh`: check 12 fails on a `bypassPermissions` or `dontAsk` default mode, a skipped permission prompt, a hook command with the shell word `while` or `until`, a `for ((` loop, `sleep`, `nohup`, `disown`, `setsid`, a background `&`, `--dangerously-skip-permissions` or `--permission-mode`, and a hook entry with `"async": true`; inspection of `.claude/hooks/*.sh` for loops and daemons, because check 12 knows a list of forms and a reader judges any other.
- Acceptance scenarios [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30), [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/PROGRESS.md`, `scripts/check-project-control.sh` check 7 — actionable progress after each coherent unit (AC-1)
- `.claude/hooks/session-start.sh` (uncommitted paths as a bounded `git status --short` list) — changed files visible at every session start (AC-1, AC-2)
- `.claude/hooks/session-start.sh`, `.claude/skills/resume-project/SKILL.md`, `scripts/lib/verify-state.sh`, `scripts/check-project-control.sh` check 12 (SessionStart on startup, resume and compact) — state reconstructed from the repository and Git (AC-2)
- `docs/briefs/`, worktree isolation, `docs/WORKFLOW_LOG.md` WF-002, PROGRESS.md § Blockers, `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps, `.env.example` (required file) — partial results kept and exact unblock actions recorded (AC-3)
- `CLAUDE.md` § Git, `.claude/skills/develop/SKILL.md` § Parallel work and § 13 (PROGRESS.md names only what the remote holds; in-flight work recorded stop-safe), `.claude/skills/resume-project/SKILL.md` step 5 (an unrecorded verdict is work that is not running), `scripts/check-project-control.sh` check 7 (no PROGRESS.md line claims ongoing execution) — no claim of ongoing execution, partial results reachable after the lead's session ends (AC-3)
- `.claude/hooks/stop-verify.sh` (bounded attempts), `.claude/settings.json` and `scripts/check-project-control.sh` check 12 (no permission bypass, no skipped prompt, hook commands without loops, sleeps or background jobs, no asynchronous hook) — no unbounded loops or permission bypass (AC-4)
- Tests: `scripts/tests/test-session-start.sh` — AVE-REQ-098 AC-1, AVE-REQ-098 AC-2; `scripts/tests/test-checker.sh` — AVE-REQ-098 AC-1, AVE-REQ-098 AC-2, AVE-REQ-098 AC-3, AVE-REQ-098 AC-4; `scripts/tests/test-probe-environment.sh` — AVE-REQ-098 AC-3; `scripts/tests/test-stop-hook.sh` — AVE-REQ-098 AC-4
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md), [ASM-001](../ASSUMPTIONS.md)

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
