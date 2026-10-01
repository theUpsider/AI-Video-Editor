---
id: AVE-REQ-024
title: Audio-based offset estimation
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U16]
dependencies: [AVE-REQ-023, AVE-REQ-012]
scenarios: [AT-04, AT-05]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-024.md
---

# AVE-REQ-024 — Audio-based offset estimation

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.

Imported from the immutable baseline [AVE-REQ-024](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-024.md) (package v1.0); primary gate M2, scope v1.

## Description
When recordings contain sufficiently correlated audio, the system shall estimate their temporal offset from the original audio signals.

## Acceptance criteria
- [ ] AC-1 Use audio from a camera for synchronization even when that camera will be muted in the final edit.
- [ ] AC-2 Test positive and negative known offsets, gain changes, background noise, different audio sample rates, and partial overlaps.
- [ ] AC-3 Report the estimation method, residual error or equivalent confidence evidence, and aligned source intervals.
- [ ] AC-4 On the qualified synthetic fixtures in AT-04, alignment error is at most one project output frame; do not generalize this bound to arbitrary real footage.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-023 — Synchronization candidate matching](AVE-REQ-023-synchronization-candidate-matching.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-024 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
