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
- A failing verification gate → bounded retries, then a release with a recorded failure (AC-4).
- No infinite loops, sleep daemons or permission bypass flags in settings or hooks (AC-4): check 12 fails on a
  `bypassPermissions` or `dontAsk` default mode, a skipped permission prompt, and a hook command with
  `while true`, `sleep`, `nohup`, `disown`, `setsid`, a background `&` or `--dangerously-skip-permissions`.

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/check-project-control.sh` enforces the PROGRESS.md headings (current objective, in progress, blockers, known failures, next work, verification status); changed files: each coherent unit's commit records them (`git log --stat`), and every session start lists the uncommitted paths (`scripts/tests/test-session-start.sh`: the `git status --short` list, bounded at 20 lines); the PROGRESS.md content after each coherent unit is inspected in Git history (`git log -p docs/PROGRESS.md`).
- AC-2 — integration — `scripts/tests/test-session-start.sh`: every session start, resume and compaction injects branch, commits, the uncommitted paths (count and bounded list), last verification and PROGRESS.md; `scripts/tests/test-checker.sh`: check 12 fails when the SessionStart hook is missing or its matcher excludes startup, resume or compact; `.claude/skills/resume-project/SKILL.md` reconstructs from the repository.
- AC-3 — integration and inspection — `.env.example` is a required file (`scripts/tests/test-checker.sh`) and lists every credential variable the probe reports (`scripts/tests/test-probe-environment.sh`); inspection: WF-002 (an account limit stopped a delegated agent; its worktree and persisted brief kept the partial work and the lead completed it), `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps (one unblock action per gap), PROGRESS.md § Blockers.
- AC-4 — integration and inspection — `scripts/tests/test-stop-hook.sh` (bounded gate attempts, release with a recorded failure); `scripts/tests/test-checker.sh`: check 12 fails on a `bypassPermissions` or `dontAsk` default mode, a skipped permission prompt, and a hook command with `while true`, `sleep`, `nohup`, `disown`, `setsid`, a background `&` or `--dangerously-skip-permissions`; inspection of `.claude/hooks/*.sh` for loops and daemons.
- Acceptance scenarios [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30), [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/PROGRESS.md`, `scripts/check-project-control.sh` check 7 — actionable progress after each coherent unit (AC-1)
- `.claude/hooks/session-start.sh` (uncommitted paths as a bounded `git status --short` list) — changed files visible at every session start (AC-1, AC-2)
- `.claude/hooks/session-start.sh`, `.claude/skills/resume-project/SKILL.md`, `scripts/lib/verify-state.sh`, `scripts/check-project-control.sh` check 12 (SessionStart on startup, resume and compact) — state reconstructed from the repository and Git (AC-2)
- `docs/briefs/`, worktree isolation, `docs/WORKFLOW_LOG.md` WF-002, PROGRESS.md § Blockers, `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps, `.env.example` (required file) — partial results kept and exact unblock actions recorded (AC-3)
- `.claude/hooks/stop-verify.sh` (bounded attempts), `.claude/settings.json` and `scripts/check-project-control.sh` check 12 (no permission bypass, no skipped prompt, hook commands without loops, sleeps or background jobs) — no unbounded loops or permission bypass (AC-4)
- Tests: `scripts/tests/test-session-start.sh` — AVE-REQ-098 AC-1, AVE-REQ-098 AC-2; `scripts/tests/test-checker.sh` — AVE-REQ-098 AC-2, AVE-REQ-098 AC-3, AVE-REQ-098 AC-4; `scripts/tests/test-probe-environment.sh` — AVE-REQ-098 AC-3; `scripts/tests/test-stop-hook.sh` — AVE-REQ-098 AC-4
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
