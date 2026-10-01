---
id: AVE-REQ-023
title: Synchronization candidate matching
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U16, U17]
dependencies: [AVE-REQ-004, AVE-REQ-005, AVE-REQ-006]
scenarios: [AT-04, AT-07, AT-09]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-023.md
---

# AVE-REQ-023 — Synchronization candidate matching

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.
- [U17](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u17) — Extract recording date, time, and location when available in metadata.

Imported from the immutable baseline [AVE-REQ-023](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-023.md) (package v1.0); primary gate M2, scope v1.

## Description
The system shall propose likely simultaneous recordings and camera pairs using available capture metadata, audio similarity, and user camera labels.

## Acceptance criteria
- [ ] AC-1 Display candidate pairings, evidence, estimated overlap, and confidence; the user can override or create a group manually.
- [ ] AC-2 Do not pair unrelated recordings merely because filenames or coarse timestamps are similar.
- [ ] AC-3 Handle different start and end times and recording segments split into multiple files without assuming one-to-one filenames.
- [ ] AC-4 Retain the pairing decision independently from layout and final audio routing.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-005 — Capture date, timezone, and location metadata](AVE-REQ-005-capture-date-timezone-and-location-metadata.md)
- [AVE-REQ-006 — Library organization and filtering](AVE-REQ-006-library-organization-and-filtering.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-023 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-07](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-07), [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
