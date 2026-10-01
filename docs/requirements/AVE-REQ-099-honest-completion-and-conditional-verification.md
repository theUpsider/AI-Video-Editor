---
id: AVE-REQ-099
title: Honest completion and conditional verification
type: constraint
status: ready
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M7
origins: [U27, D03]
dependencies: [AVE-REQ-097]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-099.md
---

# AVE-REQ-099 — Honest completion and conditional verification

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-099](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-099.md) (package v1.0); primary gate M7, scope v1.

## Description
Requirements shall be marked complete only with applicable acceptance evidence; missing external resources shall remain visible verification gaps.

## Acceptance criteria
- [ ] AC-1 Distinguish planned, in progress, implemented, verified, blocked, and deferred states in the working project tracker.
- [ ] AC-2 A real credentialed provider smoke test is required to claim that provider path verified; an actual device encode is required to claim a hardware path verified.
- [ ] AC-3 Absence of optional hardware can yield a documented conditional capability, not a claim that it was tested or a silent scope reduction.
- [ ] AC-4 Release reporting enumerates all remaining unverified criteria and never describes a mock interface or partial milestone as the whole requested product.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-097 — Verification gates that cannot pass as placeholders](AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-099 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
