---
id: AVE-REQ-043
title: Color consistency across outputs
type: functional
status: ready
priority: must
parent: AVE-FEAT-008
source: human
scope: v1
primary_gate: M7
origins: [U21, D03]
dependencies: [AVE-REQ-022, AVE-REQ-041, AVE-REQ-042]
scenarios: [AT-10, AT-18, AT-26]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-043.md
---

# AVE-REQ-043 — Color consistency across outputs

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-008 — Color and reusable looks](AVE-FEAT-008-color-and-reusable-looks.md). Origin clauses in the user brief:
- [U21](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u21) — Offer color grading, shadows/highlights/contrast and related controls, with reusable looks applied across a trip/project.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-043](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-043.md) (package v1.0); primary gate M7, scope v1.

## Description
Project and camera looks shall remain consistent across full exports, section exports, shorts, and available CPU/GPU encoding paths.

## Acceptance criteria
- [ ] AC-1 All outputs inherit the intended grade unless an explicit per-output override is set.
- [ ] AC-2 Color tags and pixel format in the encoded file match the selected output policy.
- [ ] AC-3 Reference tests compare color patches with documented lossy-codec tolerances and detect double transforms or full/limited-range errors.
- [ ] AC-4 Hardware encoding availability does not imply every grading filter executes on the GPU.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-022 — Preview and export composition parity](AVE-REQ-022-preview-and-export-composition-parity.md)
- [AVE-REQ-041 — Reusable project, camera, and clip color profiles](AVE-REQ-041-reusable-project-camera-and-clip-color-profiles.md)
- [AVE-REQ-042 — Input color interpretation and SDR normalization](AVE-REQ-042-input-color-interpretation-and-sdr-normalization.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-043 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-26](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-26) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
