---
id: AVE-REQ-039
title: Section and whole-project export
type: functional
status: ready
priority: must
parent: AVE-FEAT-007
source: human
scope: v1
primary_gate: M6
origins: [U18]
dependencies: [AVE-REQ-038, AVE-REQ-072, AVE-REQ-063]
scenarios: [AT-09, AT-13, AT-17]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-039.md
---

# AVE-REQ-039 — Section and whole-project export

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-007 — Sections and chapters](AVE-FEAT-007-sections-and-chapters.md). Origin clauses in the user brief:
- [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18) — Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.

Imported from the immutable baseline [AVE-REQ-039](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-039.md) (package v1.0); primary gate M6, scope v1.

## Description
Users shall export one section, selected sections, or the entire project through the same render pipeline.

## Acceptance criteria
- [ ] AC-1 Individual section exports start at output time zero and correctly rebase overlays, audio, and subtitle cues.
- [ ] AC-2 Whole-project export preserves chosen section order and can include supported chapter metadata and a text chapter list.
- [ ] AC-3 Transitions crossing a section boundary have an explicit clip, include-handle, or rerender policy shown before export.
- [ ] AC-4 Batch section export reports independent job status and does not corrupt successful outputs if another section fails.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-038 — Editable date and location sections](AVE-REQ-038-editable-date-and-location-sections.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-063 — Subtitle sidecars and supported embedded tracks](AVE-REQ-063-subtitle-sidecars-and-supported-embedded-tracks.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-039 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
