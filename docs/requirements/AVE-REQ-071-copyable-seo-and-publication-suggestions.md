---
id: AVE-REQ-071
title: Copyable SEO and publication suggestions
type: functional
status: ready
priority: must
parent: AVE-FEAT-016
source: human
scope: v1
primary_gate: M6
origins: [U13]
dependencies: [AVE-REQ-047, AVE-REQ-058, AVE-REQ-038]
scenarios: [AT-25, AT-19]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-071.md
---

# AVE-REQ-071 — Copyable SEO and publication suggestions

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-016 — Publication metadata](AVE-FEAT-016-publication-metadata.md). Origin clauses in the user brief:
- [U13](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u13) — Generate copyable keywords and related SEO/publication text.

Imported from the immutable baseline [AVE-REQ-071](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-071.md) (package v1.0); primary gate M6, scope v1.

## Description
The AI shall generate editable keyword, tag, title, and description suggestions for the whole video, a section, or a short.

## Acceptance criteria
- [ ] AC-1 Suggestions are grounded in available content, locations, language, and user instructions, without invented claims.
- [ ] AC-2 Users can copy individual fields or export a text/JSON metadata bundle in a selected language.
- [ ] AC-3 Suggested keywords and hashtags are distinguished from technical container metadata and subtitle tracks.
- [ ] AC-4 The interface makes no promise of search ranking, reach, or virality and does not upload to a platform automatically.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-047 — Grounded editorial reasoning](AVE-REQ-047-grounded-editorial-reasoning.md)
- [AVE-REQ-058 — Editable searchable source transcripts](AVE-REQ-058-editable-searchable-source-transcripts.md)
- [AVE-REQ-038 — Editable date and location sections](AVE-REQ-038-editable-date-and-location-sections.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-071 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-25](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-25), [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
