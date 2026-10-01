---
id: AVE-REQ-040
title: Non-destructive color and tonal controls
type: functional
status: ready
priority: must
parent: AVE-FEAT-008
source: human
scope: v1
primary_gate: M3
origins: [U21]
dependencies: [AVE-REQ-011, AVE-REQ-019]
scenarios: [AT-10, AT-26]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-040.md
---

# AVE-REQ-040 — Non-destructive color and tonal controls

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-008 — Color and reusable looks](AVE-FEAT-008-color-and-reusable-looks.md). Origin clauses in the user brief:
- [U21](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u21) — Offer color grading, shadows/highlights/contrast and related controls, with reusable looks applied across a trip/project.

Imported from the immutable baseline [AVE-REQ-040](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-040.md) (package v1.0); primary gate M3, scope v1.

## Description
The editor shall expose non-destructive exposure, contrast, saturation, white balance or temperature/tint, shadows, highlights, and tonal adjustments.

## Acceptance criteria
- [ ] AC-1 Controls operate on a defined working color representation, have bounded values, and can be reset or bypassed.
- [ ] AC-2 The selected clip or project look can be inspected before and after adjustment without changing source bytes.
- [ ] AC-3 The grading model is exposed through validated editing operations rather than arbitrary filter-string injection.
- [ ] AC-4 Known color-ramp fixtures produce the documented tonal change in reference rendering.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-019 — Aspect-preserving composition and transforms](AVE-REQ-019-aspect-preserving-composition-and-transforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-040 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-26](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-26) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
