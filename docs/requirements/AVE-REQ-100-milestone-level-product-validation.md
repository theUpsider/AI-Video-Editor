---
id: AVE-REQ-100
title: Milestone-level product validation
type: constraint
status: ready
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M7
origins: [U27, U24]
dependencies: [AVE-REQ-093, AVE-REQ-097]
scenarios: [AT-30, AT-31]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-100.md
---

# AVE-REQ-100 — Milestone-level product validation

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-100](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-100.md) (package v1.0); primary gate M7, scope v1.

## Description
At every meaningful milestone, compare the running product with the original brief and the complete version-one requirement set.

## Acceptance criteria
- [ ] AC-1 Run integrated import -> draft -> manual/AI revision -> mixed-layout preview -> section/short/full export journeys.
- [ ] AC-2 Check that synchronization, final audio, captions, color profiles, and metadata still agree after integration.
- [ ] AC-3 Do not stop at the first playable MVP or a backend-only renderer while remaining version-one requirements are unimplemented.
- [ ] AC-4 Keep future tracking and advanced temporal understanding excluded; further scope additions require an explicit rationale and must not displace requested work.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-097 — Verification gates that cannot pass as placeholders](AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-100 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30), [AT-31](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-31) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
