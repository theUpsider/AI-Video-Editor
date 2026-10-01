---
id: AVE-REQ-034
title: Timed text and image overlays
type: functional
status: ready
priority: must
parent: AVE-FEAT-006
source: human
scope: v1
primary_gate: M3
origins: [U04]
dependencies: [AVE-REQ-011, AVE-REQ-019, AVE-REQ-048]
scenarios: [AT-10, AT-16]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-034.md
---

# AVE-REQ-034 — Timed text and image overlays

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-006 — Overlays and titles](AVE-FEAT-006-overlays-and-titles.md). Origin clauses in the user brief:
- [U04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u04) — Both the user and AI can place images or text over the video for explicit start/end intervals.

Imported from the immutable baseline [AVE-REQ-034](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-034.md) (package v1.0); primary gate M3, scope v1.

## Description
Users and AI shall add, edit, remove, and time text and image overlays through the same project editing model.

## Acceptance criteria
- [ ] AC-1 Each overlay has explicit start and end, position, size, z-order, opacity, and applicable style settings.
- [ ] AC-2 A fixture overlay from 3 to 6 seconds appears at 3 seconds and disappears at 6 seconds under half-open interval semantics.
- [ ] AC-3 Image transparency, scaling, and text wrapping are represented in both preview and export.
- [ ] AC-4 Overlay edits are undoable and invalid timing or unknown image assets are rejected.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-019 — Aspect-preserving composition and transforms](AVE-REQ-019-aspect-preserving-composition-and-transforms.md)
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-034 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
