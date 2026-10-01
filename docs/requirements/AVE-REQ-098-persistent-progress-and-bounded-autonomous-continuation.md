---
id: AVE-REQ-098
title: Persistent progress and bounded autonomous continuation
type: constraint
status: ready
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
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-098 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30), [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
