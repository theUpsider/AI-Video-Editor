---
id: AVE-REQ-097
title: Verification gates that cannot pass as placeholders
type: constraint
status: ready
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D03]
dependencies: [AVE-REQ-093]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-097.md
---

# AVE-REQ-097 — Verification gates that cannot pass as placeholders

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-097](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-097.md) (package v1.0); primary gate M0, scope v1.

## Description
Replace bootstrap-only verification with staged real checks and independently verifiable release gates as implementation begins.

## Acceptance criteria
- [ ] AC-1 Keep a fast feedback tier, real-media integration tier, and full release tier behind documented repository commands.
- [ ] AC-2 Tie verification evidence to a commit/tree fingerprint, configuration, requirement IDs, and test results; stale evidence cannot certify changed code.
- [ ] AC-3 Use supported hooks only after a small smoke test; avoid recursive Stop-hook loops and repeated full renders on every conversational response.
- [ ] AC-4 No-op scripts, skipped integration tests, caught exceptions returning success, or provider mocks cannot establish completed product requirements.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-097 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
