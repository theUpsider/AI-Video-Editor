---
id: AVE-REQ-013
title: Manual editing and precision controls
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M2
origins: [U20]
dependencies: [AVE-REQ-011, AVE-REQ-012]
scenarios: [AT-11, AT-05]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-013.md
---

# AVE-REQ-013 — Manual editing and precision controls

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-013](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-013.md) (package v1.0); primary gate M2, scope v1.

## Description
Users shall be able to manually drag, arrange, trim, split, extend within available handles, and delete clip instances using familiar timeline interactions.

## Acceptance criteria
- [ ] AC-1 Dragging either clip edge changes its visible interval with snapping and precise numeric in/out controls.
- [ ] AC-2 Split-at-playhead, move, reorder, insert, overwrite, and ripple-delete have documented effects on linked items and downstream material.
- [ ] AC-3 Users can zoom and scroll the timeline, select a range, step frames, and navigate with keyboard controls.
- [ ] AC-4 Invalid trims beyond source handles are prevented or require an explicit freeze/gap effect; the editor never invents source frames.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-013 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
