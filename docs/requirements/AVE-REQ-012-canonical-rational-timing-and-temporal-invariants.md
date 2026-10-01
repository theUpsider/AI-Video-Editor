---
id: AVE-REQ-012
title: Canonical rational timing and temporal invariants
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M1
origins: [U03, U15, D03]
dependencies: [AVE-REQ-004]
scenarios: [AT-03, AT-04, AT-13]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-012.md
---

# AVE-REQ-012 — Canonical rational timing and temporal invariants

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03) — Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-012](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-012.md) (package v1.0); primary gate M1, scope v1.

## Description
All editing, synchronization, subtitles, and rendering shall share a canonical timing model with exact rational values or integer ticks and explicit time domains.

## Acceptance criteria
- [ ] AC-1 Distinguish source presentation time, synchronization-group time, project time, section time, and export time.
- [ ] AC-2 Use half-open intervals [start, end) and reject negative durations, invalid source bounds, NaN values, and unsupported time transforms.
- [ ] AC-3 At 60000/1001 fps, repeated edits and long timelines do not accumulate errors from rounding the rate to 60 or storing frame counts as approximate seconds.
- [ ] AC-4 Variable-frame-rate inputs are mapped by presentation timestamps; output frame-rate conversion does not change intended playback speed.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-012 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
