---
id: AVE-REQ-042
title: Input color interpretation and SDR normalization
type: functional
status: ready
priority: must
parent: AVE-FEAT-008
source: human
scope: v1
primary_gate: M3
origins: [U21, U23, D03]
dependencies: [AVE-REQ-004, AVE-REQ-040]
scenarios: [AT-26, AT-10]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-042.md
---

# AVE-REQ-042 — Input color interpretation and SDR normalization

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-008 — Color and reusable looks](AVE-FEAT-008-color-and-reusable-looks.md). Origin clauses in the user brief:
- [U21](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u21) — Offer color grading, shadows/highlights/contrast and related controls, with reusable looks applied across a trip/project.
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-042](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-042.md) (package v1.0); primary gate M3, scope v1.

## Description
The system shall distinguish technical input color transforms from creative looks and provide a validated SDR output path.

## Acceptance criteria
- [ ] AC-1 Inspect color primaries, transfer, matrix, range, and available bit-depth metadata, and allow user correction when tags are absent or wrong.
- [ ] AC-2 Do not assume a DJI recording is log or apply a camera-specific LUT without confirmed profile information.
- [ ] AC-3 Default output uses a documented SDR Rec.709 path; recognized HDR inputs require supported tone mapping or an explicit unsupported warning.
- [ ] AC-4 Unknown log/HDR material is not silently labeled color-accurate; optional LUT import validates format and records provenance.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-040 — Non-destructive color and tonal controls](AVE-REQ-040-non-destructive-color-and-tonal-controls.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-042 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-26](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-26), [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
