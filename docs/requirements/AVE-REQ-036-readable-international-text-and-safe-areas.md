---
id: AVE-REQ-036
title: Readable international text and safe areas
type: functional
status: ready
priority: must
parent: AVE-FEAT-006
source: human
scope: v1
primary_gate: M3
origins: [U04, U05, U10]
dependencies: [AVE-REQ-034]
scenarios: [AT-10, AT-13, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-036.md
---

# AVE-REQ-036 — Readable international text and safe areas

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-006 — Overlays and titles](AVE-FEAT-006-overlays-and-titles.md). Origin clauses in the user brief:
- [U04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u04) — Both the user and AI can place images or text over the video for explicit start/end intervals.
- [U05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u05) — Place contextual titles such as locations near the start and optional credits/references near the end, not continuously.
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.

Imported from the immutable baseline [AVE-REQ-036](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-036.md) (package v1.0); primary gate M3, scope v1.

## Description
Text overlays and captions shall support Unicode, configurable typography, readable contrast, and aspect-ratio-aware safe areas.

## Acceptance criteria
- [ ] AC-1 Validate Latin and CJK sample strings with appropriately licensed font fallback and no missing-glyph boxes in reference renders.
- [ ] AC-2 Changing between 16:9, 1:1, and 9:16 exposes overflow and permits independent layout adjustments.
- [ ] AC-3 Text is passed to rendering libraries safely; punctuation and control-like strings do not become commands or filter expressions.
- [ ] AC-4 Font and text-style choices are persisted and exported with appropriate dependency or font-license documentation.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-034 — Timed text and image overlays](AVE-REQ-034-timed-text-and-image-overlays.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-036 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
