---
id: AVE-REQ-021
title: Mixed split-screen and full-width segments
type: functional
status: ready
priority: must
parent: AVE-FEAT-003
source: human
scope: v1
primary_gate: M2
origins: [U19]
dependencies: [AVE-REQ-020, AVE-REQ-031]
scenarios: [AT-02, AT-11]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-021.md
---

# AVE-REQ-021 — Mixed split-screen and full-width segments

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-003 — Canvas and mixed layouts](AVE-FEAT-003-canvas-and-mixed-layouts.md). Origin clauses in the user brief:
- [U19](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u19) — Mix two-perspective split-screen footage with full-width 16:9 footage of both people and then return to split-screen.

Imported from the immutable baseline [AVE-REQ-021](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-021.md) (package v1.0); primary gate M2, scope v1.

## Description
A sequence shall switch between simultaneous split-screen recordings and single full-width recordings, then return to split-screen without creating separate projects.

## Acceptance criteria
- [ ] AC-1 A split/full/split fixture displays both perspectives, then the full 16:9 shot, then both perspectives again at the specified boundaries.
- [ ] AC-2 The full-width segment can use its own audio while adjacent split segments use their designated reference audio.
- [ ] AC-3 Cuts and transitions retain the intended total duration, synchronization, and subtitle mapping.
- [ ] AC-4 Users and AI can change the layout per segment rather than only globally.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-020 — Two-perspective split-screen layout](AVE-REQ-020-two-perspective-split-screen-layout.md)
- [AVE-REQ-031 — Explicit master audio and routing](AVE-REQ-031-explicit-master-audio-and-routing.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-021 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
