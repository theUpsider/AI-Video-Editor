---
id: AVE-REQ-037
title: Basic overlay animation without tracking
type: functional
status: ready
priority: must
parent: AVE-FEAT-006
source: human
scope: v1
primary_gate: M3
origins: [U04, U05, U06]
dependencies: [AVE-REQ-034]
scenarios: [AT-10, AT-31]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-037.md
---

# AVE-REQ-037 — Basic overlay animation without tracking

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-006 — Overlays and titles](AVE-FEAT-006-overlays-and-titles.md). Origin clauses in the user brief:
- [U04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u04) — Both the user and AI can place images or text over the video for explicit start/end intervals.
- [U05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u05) — Place contextual titles such as locations near the start and optional credits/references near the end, not continuously.
- [U06](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u06) — Object tracking and motion tracking are future features, explicitly excluded from the first version.

Imported from the immutable baseline [AVE-REQ-037](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-037.md) (package v1.0); primary gate M3, scope v1.

## Description
Overlays shall support simple timed opacity fades and explicit user-defined position or scale keyframes without following detected objects.

## Acceptance criteria
- [ ] AC-1 Fade-in and fade-out durations can be edited and do not exceed the overlay duration without validation.
- [ ] AC-2 Keyframed values use defined interpolation and are identical in the composition contract for preview and rendering.
- [ ] AC-3 Static overlay operation does not depend on a tracking model.
- [ ] AC-4 No object- or motion-tracking implementation is introduced as a prerequisite for version one.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-034 — Timed text and image overlays](AVE-REQ-034-timed-text-and-image-overlays.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-037 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-31](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-31) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
