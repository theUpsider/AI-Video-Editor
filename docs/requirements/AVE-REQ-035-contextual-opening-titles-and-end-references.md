---
id: AVE-REQ-035
title: Contextual opening titles and end references
type: functional
status: ready
priority: must
parent: AVE-FEAT-006
source: human
scope: v1
primary_gate: M3
origins: [U05, U17, U18]
dependencies: [AVE-REQ-034, AVE-REQ-005, AVE-REQ-038]
scenarios: [AT-10, AT-09, AT-14]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-035.md
---

# AVE-REQ-035 — Contextual opening titles and end references

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-006 — Overlays and titles](AVE-FEAT-006-overlays-and-titles.md). Origin clauses in the user brief:
- [U05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u05) — Place contextual titles such as locations near the start and optional credits/references near the end, not continuously.
- [U17](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u17) — Extract recording date, time, and location when available in metadata.
- [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18) — Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.

Imported from the immutable baseline [AVE-REQ-035](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-035.md) (package v1.0); primary gate M3, scope v1.

## Description
The editor shall support brief opening titles, location/date labels, and ending references or credits without displaying them throughout the video by default.

## Acceptance criteria
- [ ] AC-1 Initial suggestions use a configurable approximately 3-second opening title and 4-second ending card, bounded by the actual segment length.
- [ ] AC-2 Location and date wording comes from verified metadata or user labels; unknown locations are omitted or left for confirmation.
- [ ] AC-3 Users can choose project-level or section-level title placement and suppress repeated titles.
- [ ] AC-4 End references and credits accept user-supplied content and sources; the AI does not fabricate attribution.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-034 — Timed text and image overlays](AVE-REQ-034-timed-text-and-image-overlays.md)
- [AVE-REQ-005 — Capture date, timezone, and location metadata](AVE-REQ-005-capture-date-timezone-and-location-metadata.md)
- [AVE-REQ-038 — Editable date and location sections](AVE-REQ-038-editable-date-and-location-sections.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-035 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09), [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
