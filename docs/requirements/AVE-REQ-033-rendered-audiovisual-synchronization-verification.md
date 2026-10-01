---
id: AVE-REQ-033
title: Rendered audiovisual synchronization verification
type: functional
status: ready
priority: must
parent: AVE-FEAT-005
source: human
scope: v1
primary_gate: M7
origins: [U15, U16, D03]
dependencies: [AVE-REQ-028, AVE-REQ-031, AVE-REQ-072]
scenarios: [AT-04, AT-08, AT-28]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-033.md
---

# AVE-REQ-033 — Rendered audiovisual synchronization verification

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-005 — Audio routing and mixing](AVE-FEAT-005-audio-routing-and-mixing.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-033](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-033.md) (package v1.0); primary gate M7, scope v1.

## Description
Synchronization acceptance shall measure the exported media, not only the internal offset calculation.

## Acceptance criteria
- [ ] AC-1 A fixture with known visible events and audible impulses is decoded after export and checked at beginning, middle, and end.
- [ ] AC-2 The qualified test bound is at most one output video frame after accounting for container timestamps and audio encoder delay.
- [ ] AC-3 Conversion between 44.1 kHz and 48 kHz and between fractional and integer video rates does not silently change real-time duration.
- [ ] AC-4 Unverifiable real-world alignment remains labeled unverified or manual; the UI does not claim perfect lip synchronization without evidence.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-028 — Clock-drift detection and correction](AVE-REQ-028-clock-drift-detection-and-correction.md)
- [AVE-REQ-031 — Explicit master audio and routing](AVE-REQ-031-explicit-master-audio-and-routing.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-033 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-08](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-08), [AT-28](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-28) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
