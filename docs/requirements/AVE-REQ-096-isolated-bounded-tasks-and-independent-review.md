---
id: AVE-REQ-096
title: Isolated bounded tasks and independent review
type: constraint
status: ready
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
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-096 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
