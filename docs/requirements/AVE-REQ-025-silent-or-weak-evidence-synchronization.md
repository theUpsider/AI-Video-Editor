---
id: AVE-REQ-025
title: Silent or weak-evidence synchronization
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U16]
dependencies: [AVE-REQ-023]
scenarios: [AT-06, AT-07]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-025.md
---

# AVE-REQ-025 — Silent or weak-evidence synchronization

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.

Imported from the immutable baseline [AVE-REQ-025](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-025.md) (package v1.0); primary gate M2, scope v1.

## Description
For sources without usable shared audio, the system shall attempt available timestamp or explicit visual-event alignment and otherwise offer manual anchors.

## Acceptance criteria
- [ ] AC-1 A visible shared flash or marked event may establish an offset; object tracking is not required.
- [ ] AC-2 Coarse camera timestamps alone are labeled approximate, especially when clocks or timezones differ.
- [ ] AC-3 When neither shared audio, reliable timestamps, nor a common event exists, return insufficient evidence rather than a fabricated exact alignment.
- [ ] AC-4 A manual anchor can complete synchronization without requiring the silent source to gain an audio track.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-023 — Synchronization candidate matching](AVE-REQ-023-synchronization-candidate-matching.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-025 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-06](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-06), [AT-07](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-07) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
