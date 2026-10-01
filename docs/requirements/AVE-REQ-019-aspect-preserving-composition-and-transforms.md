---
id: AVE-REQ-019
title: Aspect-preserving composition and transforms
type: functional
status: in-progress
priority: must
parent: AVE-FEAT-003
source: human
scope: v1
primary_gate: M2
origins: [U02]
dependencies: [AVE-REQ-011, AVE-REQ-018]
scenarios: [AT-02, AT-10]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-019.md
---

# AVE-REQ-019 — Aspect-preserving composition and transforms

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-003 — Canvas and mixed layouts](AVE-FEAT-003-canvas-and-mixed-layouts.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.

Imported from the immutable baseline [AVE-REQ-019](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-019.md) (package v1.0); primary gate M2, scope v1.

## Description
Clip instances shall support position, scale, crop, rotation, opacity, z-order, and explicit contain or cover fitting inside layout regions.

## Acceptance criteria
- [ ] AC-1 Contain preserves the complete source image with an explicit background; cover fills the region with visible crop controls.
- [ ] AC-2 No default operation stretches a source to change its aspect ratio.
- [ ] AC-3 Users and AI can specify transforms in normalized canvas or region coordinates, with preview and export using the same semantics.
- [ ] AC-4 Per-clip focal position or crop can be set manually or as a static AI suggestion; this does not require object tracking.

## Edge cases
- Source aspect equal to the region aspect → contain and cover give identical, uncropped output (AC-1).
- Extreme aspect ratios (very wide or tall) and rounding to even pixels never change aspect beyond one pixel (AC-2).
- Focus point at the image edge clamps the crop inside the source (AC-4).
- Rotation, scale and opacity combined with fit; preview and export share normalized coordinates (AC-3).
- Stretch only when explicitly requested (AC-2).

## Dependencies
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-018 — Configurable canvas, dimensions, and output rate](AVE-REQ-018-configurable-canvas-dimensions-and-output-rate.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-019 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-01 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-01 — in-progress — M0 media core implements part of the ACs (timebase, probe, layout, segmented CPU renderer, audio offset); remaining ACs follow in their gate milestone (lead)
