---
id: AVE-REQ-020
title: Two-perspective split-screen layout
type: functional
status: ready
priority: must
parent: AVE-FEAT-003
source: human
scope: v1
primary_gate: M1
origins: [U02, U15, U16]
dependencies: [AVE-REQ-019]
scenarios: [AT-02, AT-04]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-020.md
---

# AVE-REQ-020 — Two-perspective split-screen layout

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-003 — Canvas and mixed layouts](AVE-FEAT-003-canvas-and-mixed-layouts.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16) — Two manually started cameras can begin and end at different times; automatically estimate their overlap and timing where evidence permits.

Imported from the immutable baseline [AVE-REQ-020](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-020.md) (package v1.0); primary gate M1, scope v1.

## Description
The editor shall provide a reusable left/right split-screen layout for synchronized sources of arbitrary aspect ratios.

## Acceptance criteria
- [ ] AC-1 For a 1920x1080 canvas and two square sources in contain mode, each image is 960x960 with 60 pixels of vertical background above and below; sources remain undistorted.
- [ ] AC-2 Cover mode fills each 960x1080 region by cropping; the user can inspect and adjust the crop rather than accepting hidden loss of content.
- [ ] AC-3 Users can swap perspectives, resize the divider, configure a gap or background, and save a layout preset.
- [ ] AC-4 The layout binds clip instances and synchronization-group membership without changing the selected final audio source.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-019 — Aspect-preserving composition and transforms](AVE-REQ-019-aspect-preserving-composition-and-transforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-020 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
