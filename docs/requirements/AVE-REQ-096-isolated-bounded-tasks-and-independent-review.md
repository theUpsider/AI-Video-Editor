---
id: AVE-REQ-096
title: Isolated bounded tasks and independent review
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D05]
dependencies: [AVE-REQ-094]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-096.md
---

# AVE-REQ-096 — Isolated bounded tasks and independent review

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-096](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-096.md) (package v1.0); primary gate M0, scope v1.

## Description
Delegate bounded tasks with explicit context and deliverables, using verified worktree isolation for concurrent writers and a fresh review context for acceptance.

## Acceptance criteria
- [ ] AC-1 Task briefs include requirement IDs, acceptance criteria, allowed paths, dependencies, input revision, test commands, and handback schema.
- [ ] AC-2 Initialize isolated tasks from the intended integration commit; do not assume the native worktree default matches the current branch.
- [ ] AC-3 A reviewer receives requirements and the diff rather than relying on the implementer claim of success; media-critical tests inspect real rendered outputs.
- [ ] AC-4 Respect actual concurrency and resource limits; never recursively multiply coding agents or bypass a cloud limit.

## Edge cases
- A task interrupted by a usage, session or permission limit → resumable from its persisted brief and worktree
  (AC-1, AC-2).
- A worktree created from a different commit than intended → detected by the task's revision check (AC-2).
- A reviewer given only the implementer's claims → rejected; reviews start from requirements and the diff (AC-3).
- More writing agents than the measured limit → never started (AC-4).

## Dependencies
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/check-project-control.sh` check 11 rejects a task brief that lacks any required heading (requirements, input revision, allowed and forbidden paths, dependencies, test commands, handback schema); `scripts/tests/test-checker.sh` covers it; the content of each brief in `docs/briefs/` is inspected.
- AC-2 — inspection — `.claude/settings.json` sets `worktree.baseRef: "head"` (measured in ENVIRONMENT_CAPABILITIES.md); each brief names its input revision and every implementer prompt confirms `git log --oneline -1` before changing anything; the fix worktree started at `24499a6` as briefed.
- AC-3 — inspection — reviewers start from the requirement files, the brief and `git diff` in their own scratch copies (`.claude/skills/verify-requirement/SKILL.md`, the review prompts recorded with the workflow runs); media-critical claims were checked on real rendered outputs (three review rounds, WF-001).
- AC-4 — inspection — WORKFLOW_LOG operating baseline (at most two writers plus one heavy media job), workflow concurrency measured at 2–4 agents, no recursive agent spawning (subagents cannot spawn subagents).
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/briefs/README.md` (template), `docs/briefs/*.md` (persisted briefs), `scripts/check-project-control.sh` check 11 (AC-1)
- `.claude/settings.json` (`worktree.baseRef`), brief § Input revision (AC-2)
- `.claude/skills/verify-requirement/SKILL.md`, `.claude/agents/reviewer.md`, review rounds recorded in `docs/WORKFLOW_LOG.md` WF-001 (AC-3)
- `docs/WORKFLOW_LOG.md` operating baseline, `docs/ENVIRONMENT_CAPABILITIES.md` § Limits (AC-4)
- Tests: `scripts/tests/test-checker.sh` — AVE-REQ-096 AC-1
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md)

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
