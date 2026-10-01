---
id: AVE-REQ-079
title: Editable output presets and quality guidance
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M6
origins: [U02, U12, U23]
dependencies: [AVE-REQ-018, AVE-REQ-072, AVE-REQ-073]
scenarios: [AT-18, AT-19]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-079.md
---

# AVE-REQ-079 — Editable output presets and quality guidance

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U12](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u12) — Automatically identify useful approximately 15-20-second highlights and export editable shorts, including square 1:1 outputs.
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

Imported from the immutable baseline [AVE-REQ-079](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-079.md) (package v1.0); primary gate M6, scope v1.

## Description
Offer sensible editable export presets, with visible tradeoffs between dimensions, rate, quality, bitrate, speed, and estimated file size.

## Acceptance criteria
- [ ] AC-1 Provide landscape 16:9, square 1:1, and portrait 9:16 starting profiles using the selected content and platform-independent defaults.
- [ ] AC-2 Preserve the user-selected output ratio and rate when recommending bitrate or encoder choices.
- [ ] AC-3 Label size and time estimates as estimates, and warn about avoidable upscaling or unsupported combinations.
- [ ] AC-4 Encoder-specific controls are mapped explicitly; do not assume software CRF and hardware quality numbers have identical meaning.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-018 — Configurable canvas, dimensions, and output rate](AVE-REQ-018-configurable-canvas-dimensions-and-output-rate.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-073 — Multiple containers and codec choices](AVE-REQ-073-multiple-containers-and-codec-choices.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-079 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
