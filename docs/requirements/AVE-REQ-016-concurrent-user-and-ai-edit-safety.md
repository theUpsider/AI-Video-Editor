---
id: AVE-REQ-016
title: Concurrent user and AI edit safety
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M5
origins: [U20, U24]
dependencies: [AVE-REQ-015, AVE-REQ-048]
scenarios: [AT-12, AT-16]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-016.md
---

# AVE-REQ-016 — Concurrent user and AI edit safety

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-016](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-016.md) (package v1.0); primary gate M5, scope v1.

## Description
An AI proposal shall not overwrite newer user changes or locked timeline objects without an explicit resolution policy.

## Acceptance criteria
- [ ] AC-1 Every proposal references the project revision it read and the assets or objects it intends to change.
- [ ] AC-2 A proposal based on a stale revision is rejected with a structured conflict, safely rebased with renewed validation, or presented for user resolution.
- [ ] AC-3 Locked objects are protected by the domain service, not only by UI controls.
- [ ] AC-4 Users can scope a prompt to selected clips or sections; edits outside the scope are rejected unless explicitly authorized.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](AVE-REQ-015-undo-redo-autosave-and-revisions.md)
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-016 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12), [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
