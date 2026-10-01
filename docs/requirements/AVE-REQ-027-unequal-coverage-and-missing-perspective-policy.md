---
id: AVE-REQ-027
title: Unequal coverage and missing-perspective policy
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U16, U19]
dependencies: [AVE-REQ-026, AVE-REQ-021]
scenarios: [AT-05, AT-02]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-027.md
---

# AVE-REQ-027 — Unequal coverage and missing-perspective policy

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.
- [U19](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u19) — Mix two-perspective split-screen footage with full-width 16:9 footage of both people and then return to split-screen.

Imported from the immutable baseline [AVE-REQ-027](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-027.md) (package v1.0); primary gate M2, scope v1.

## Description
The editor shall explicitly handle unequal recording coverage rather than repeat stale frames or silently discard material.

## Acceptance criteria
- [ ] AC-1 Default auto-draft split-screen segments use the common overlap and preserve unused material in the collection.
- [ ] AC-2 Users may instead retain the union using an explicit full-width fallback, background gap, or separately selected freeze policy.
- [ ] AC-3 For A covering master time 0..30 and B covering 2..27, default split coverage is 2..27, not 0..30.
- [ ] AC-4 The UI shows which time spans lose a perspective or reference audio and explains the selected policy.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-026 — Persistent synchronization transforms](AVE-REQ-026-persistent-synchronization-transforms.md)
- [AVE-REQ-021 — Mixed split-screen and full-width segments](AVE-REQ-021-mixed-split-screen-and-full-width-segments.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-027 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05), [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
