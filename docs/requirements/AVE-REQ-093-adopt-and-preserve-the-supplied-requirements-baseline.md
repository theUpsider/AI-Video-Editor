---
id: AVE-REQ-093
title: Adopt and preserve the supplied requirements baseline
type: constraint
status: ready
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D05]
dependencies: []
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-093.md
---

# AVE-REQ-093 — Adopt and preserve the supplied requirements baseline

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-093](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-093.md) (package v1.0); primary gate M0, scope v1.

## Description
The implementing agent shall integrate this specification into the existing bootstrapped repository without re-running or replacing the bootstrap.

## Acceptance criteria
- [ ] AC-1 Preserve this input package as an immutable baseline and map every AVE-REQ ID to its canonical working requirement file.
- [ ] AC-2 Populate the existing PRODUCT, ARCHITECTURE, ROADMAP, PROGRESS, ASSUMPTIONS, and TRACEABILITY documents without losing meaningful existing content.
- [ ] AC-3 Explicit user requirements and exclusions cannot be demoted or rewritten merely to fit an easier implementation.
- [ ] AC-4 Requirement implementation status starts unverified; package validation is not product verification.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
None.

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-093 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
