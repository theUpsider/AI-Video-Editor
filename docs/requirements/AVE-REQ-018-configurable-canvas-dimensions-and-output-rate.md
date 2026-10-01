---
id: AVE-REQ-018
title: Configurable canvas, dimensions, and output rate
type: functional
status: ready
priority: must
parent: AVE-FEAT-003
source: human
scope: v1
primary_gate: M1
origins: [U02, U03]
dependencies: [AVE-REQ-001, AVE-REQ-004, AVE-REQ-012]
scenarios: [AT-02, AT-03, AT-18]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-018.md
---

# AVE-REQ-018 — Configurable canvas, dimensions, and output rate

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-003 — Canvas and mixed layouts](AVE-FEAT-003-canvas-and-mixed-layouts.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03) — Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.

Imported from the immutable baseline [AVE-REQ-018](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-018.md) (package v1.0); primary gate M1, scope v1.

## Description
Projects and export presets shall define output aspect ratio, exact pixel dimensions, and frame rate independently of individual inputs.

## Acceptance criteria
- [ ] AC-1 The initial canvas defaults to 16:9 and 1920x1080; 1:1, 9:16, and validated custom dimensions are selectable.
- [ ] AC-2 An Auto frame-rate setting resolves from the selected reference or dominant source on first draft; 60/1 input remains 60/1 and 60000/1001 remains distinct.
- [ ] AC-3 If no source exists, display a provisional 30 fps default; once resolved, do not silently change project timing after another import.
- [ ] AC-4 Validate encoder constraints such as even dimensions and explain any requested adjustment rather than silently stretching media.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-018 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
