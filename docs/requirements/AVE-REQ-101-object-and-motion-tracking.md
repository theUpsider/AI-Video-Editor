---
id: AVE-REQ-101
title: Object and motion tracking
type: functional
status: deferred
priority: could
parent: AVE-FEAT-020
source: human
scope: future
primary_gate: FUTURE
origins: [U06]
dependencies: [AVE-REQ-019, AVE-REQ-034, AVE-REQ-065]
scenarios: [AT-31]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-101.md
---

# AVE-REQ-101 — Object and motion tracking

## Intent
Serves [GOAL-010](../PRODUCT.md#product-goals) through [AVE-FEAT-020 — Future tracking](AVE-FEAT-020-future-tracking.md). Origin clauses in the user brief:
- [U06](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u06) — Object tracking and motion tracking are future features, explicitly excluded from the first version.

Imported from the immutable baseline [AVE-REQ-101](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-101.md) (package v1.0); primary gate FUTURE, scope future.

## Description
A future release may add motion/object tracking and automatically moving overlays or crops; version one explicitly excludes these capabilities.

## Acceptance criteria
- [ ] AC-1 Version one supports static crop/position controls and manual keyframes without a tracking dependency.
- [ ] AC-2 No tracking models, moving-object identity system, or subject-following feature is required for any version-one acceptance gate.
- [ ] AC-3 Keep this capability in the future roadmap and do not claim it is implemented by static keyframe extraction or shared-event synchronization.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-019 — Aspect-preserving composition and transforms](AVE-REQ-019-aspect-preserving-composition-and-transforms.md)
- [AVE-REQ-034 — Timed text and image overlays](AVE-REQ-034-timed-text-and-image-overlays.md)
- [AVE-REQ-065 — Timestamped keyframes and shot summaries](AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md)

## Verification strategy
- AC-1–AC-3 — criterion-level tests tagged `AVE-REQ-101 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-31](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-31) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.
- Deferred: version one keeps this capability excluded (GOAL-010).

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — deferred — future scope in baseline (lead)
