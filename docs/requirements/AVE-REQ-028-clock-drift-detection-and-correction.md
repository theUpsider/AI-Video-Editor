---
id: AVE-REQ-028
title: Clock-drift detection and correction
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U16, D03]
dependencies: [AVE-REQ-026]
scenarios: [AT-08, AT-13]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-028.md
---

# AVE-REQ-028 — Clock-drift detection and correction

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-028](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-028.md) (package v1.0); primary gate M2, scope v1.

## Description
The synchronization subsystem shall inspect alignment at multiple points, identify evidence of clock drift, and support a recorded affine time correction when justified.

## Acceptance criteria
- [ ] AC-1 Distinguish a constant offset from progressive drift using more than one anchor on a sufficiently long recording.
- [ ] AC-2 A qualified synthetic offset-plus-drift fixture aligns at beginning, middle, and end to within one output frame after correction.
- [ ] AC-3 Apply the chosen mapping consistently to video, audio, and transcript times; preserve audio pitch when time-stretching audio.
- [ ] AC-4 Low-confidence or non-linear drift is flagged for manual review; a single uncertain match is not silently converted into a speed change.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-026 — Persistent synchronization transforms](AVE-REQ-026-persistent-synchronization-transforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-028 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-08](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-08), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
