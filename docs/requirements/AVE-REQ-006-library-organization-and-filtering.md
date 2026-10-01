---
id: AVE-REQ-006
title: Library organization and filtering
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M3
origins: [U17, U18, U24]
dependencies: [AVE-REQ-003, AVE-REQ-005]
scenarios: [AT-09, AT-14]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-006.md
---

# AVE-REQ-006 — Library organization and filtering

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U17](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u17) — Extract recording date, time, and location when available in metadata.
- [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18) — Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-006](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-006.md) (package v1.0); primary gate M3, scope v1.

## Description
The collection shall support stable labels and filters for camera or perspective, recording day, location, pairing, duration, and analysis status.

## Acceptance criteria
- [ ] AC-1 Users can tag or correct camera A/B, left/right preference, trip day, and city in bulk or per asset.
- [ ] AC-2 Sorting by capture time respects declared timezone handling and exposes unknown or conflicting timestamps.
- [ ] AC-3 Users can preview and select assets using combinations of text, date, location, camera, and analysis filters.
- [ ] AC-4 Changing a label updates suggestions without silently rewriting existing manual timeline edits.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-003 — Immutable originals and stable asset identities](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)
- [AVE-REQ-005 — Capture date, timezone, and location metadata](AVE-REQ-005-capture-date-timezone-and-location-metadata.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-006 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09), [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
