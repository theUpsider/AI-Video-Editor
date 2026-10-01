---
id: AVE-REQ-001
title: Persistent projects and project settings
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M1
origins: [U01, U24, D01]
dependencies: []
scenarios: [AT-01, AT-22]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-001.md
---

# AVE-REQ-001 — Persistent projects and project settings

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u01) — Import the user's clips into a collection rather than requiring a hand-built timeline.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-001](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-001.md) (package v1.0); primary gate M1, scope v1.

## Description
The application shall create, name, reopen, duplicate, and persist editing projects, including their media references, timeline, output settings, and revisions.

## Acceptance criteria
- [ ] AC-1 A new project opens an empty collection and timeline without requiring an AI account.
- [ ] AC-2 After saving and restarting the application, timeline content, output settings, selected profiles, and project metadata are unchanged.
- [ ] AC-3 Project duplication produces an independent edit history while safely reusing immutable source media.
- [ ] AC-4 Project deletion clearly distinguishes deleting editing data from deleting original media; originals are not deleted by default.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
None.

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-001 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-01](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-01), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
