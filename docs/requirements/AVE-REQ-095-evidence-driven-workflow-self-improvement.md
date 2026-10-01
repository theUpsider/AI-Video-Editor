---
id: AVE-REQ-095
title: Evidence-driven workflow self-improvement
type: constraint
status: ready
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M7
origins: [U27, D05]
dependencies: [AVE-REQ-094]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-095.md
---

# AVE-REQ-095 — Evidence-driven workflow self-improvement

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-095](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-095.md) (package v1.0); primary gate M7, scope v1.

## Description
The coding workflow shall improve its repository-local procedures based on observed failures and measured outcomes, without weakening product or verification constraints.

## Acceptance criteria
- [ ] AC-1 Record repeated failure, proposed improvement, affected workflow, measurement, and rollback plan in a concise workflow log.
- [ ] AC-2 Apply small reviewed changes to skills, task decomposition, context retrieval, or test scheduling and verify them against fixed regression fixtures.
- [ ] AC-3 Do not loosen acceptance criteria, skip tests, raise tolerances, remove security gates, or rewrite expected results to make an implementation pass.
- [ ] AC-4 Keep improvements only when they show useful evidence; avoid permanent agent proliferation and recurring harness rewrites.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-095 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
