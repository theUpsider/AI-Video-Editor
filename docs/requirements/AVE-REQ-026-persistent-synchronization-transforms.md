---
id: AVE-REQ-026
title: Persistent synchronization transforms
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U16, D03]
dependencies: [AVE-REQ-012, AVE-REQ-024, AVE-REQ-025]
scenarios: [AT-04, AT-05, AT-08]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-026.md
---

# AVE-REQ-026 — Persistent synchronization transforms

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-026](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-026.md) (package v1.0); primary gate M2, scope v1.

## Description
Persist synchronization as explicit reversible transforms between each source time domain and a chosen group reference.

## Acceptance criteria
- [ ] AC-1 Document the offset sign convention and store source anchors, method, confidence, and residuals.
- [ ] AC-2 The same real-world event maps to the same group time across sources, including sources that began earlier or later.
- [ ] AC-3 Changing the selected reference re-expresses transforms without altering established relative alignment.
- [ ] AC-4 Synchronization never overwrites or physically trims source files.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-024 — Audio-based offset estimation](AVE-REQ-024-audio-based-offset-estimation.md)
- [AVE-REQ-025 — Silent or weak-evidence synchronization](AVE-REQ-025-silent-or-weak-evidence-synchronization.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-026 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05), [AT-08](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-08) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
