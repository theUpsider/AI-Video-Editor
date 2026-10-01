---
id: AVE-REQ-005
title: Capture date, timezone, and location metadata
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M3
origins: [U17, U18]
dependencies: [AVE-REQ-004]
scenarios: [AT-09, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-005.md
---

# AVE-REQ-005 — Capture date, timezone, and location metadata

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U17](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u17) — Extract recording date, time, and location when available in metadata.
- [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18) — Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.

Imported from the immutable baseline [AVE-REQ-005](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-005.md) (package v1.0); primary gate M3, scope v1.

## Description
The application shall extract available capture date, time, timezone, location, and camera metadata, preserve provenance, and support user corrections.

## Acceptance criteria
- [ ] AC-1 Show raw metadata and normalized values separately, including whether capture time and timezone are known, assumed, or user-supplied.
- [ ] AC-2 Do not equate file modification time with recording time or silently treat timezone-free camera timestamps as UTC.
- [ ] AC-3 Missing GPS or location remains unknown; manual city and timezone labels are supported and retained.
- [ ] AC-4 An optional reverse-geocoding request requires consent before coordinates leave the system, and exported metadata can omit location.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-005 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
