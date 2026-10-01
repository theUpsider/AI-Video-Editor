---
id: AVE-REQ-038
title: Editable date and location sections
type: functional
status: ready
priority: must
parent: AVE-FEAT-007
source: human
scope: v1
primary_gate: M3
origins: [U17, U18]
dependencies: [AVE-REQ-005, AVE-REQ-011]
scenarios: [AT-09, AT-11]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-038.md
---

# AVE-REQ-038 — Editable date and location sections

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-007 — Sections and chapters](AVE-FEAT-007-sections-and-chapters.md). Origin clauses in the user brief:
- [U17](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u17) — Extract recording date, time, and location when available in metadata.
- [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18) — Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.

Imported from the immutable baseline [AVE-REQ-038](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-038.md) (package v1.0); primary gate M3, scope v1.

## Description
The project shall support named sections or chapters with explicit timeline boundaries, optionally suggested from recording days or locations.

## Acceptance criteria
- [ ] AC-1 Users can create, rename, move, split, and delete sections and correct automatic day/city groupings.
- [ ] AC-2 Suggestions record whether grouping derives from metadata, user labels, or uncertain inference.
- [ ] AC-3 Section boundaries remain valid after timeline edits using a documented anchoring policy.
- [ ] AC-4 A trip can contain multiple sections for one city or date; unknown metadata does not prevent manual organization.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-005 — Capture date, timezone, and location metadata](AVE-REQ-005-capture-date-timezone-and-location-metadata.md)
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-038 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
