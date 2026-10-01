---
id: AVE-REQ-015
title: Undo, redo, autosave, and revisions
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M2
origins: [U20, U24, D01]
dependencies: [AVE-REQ-001, AVE-REQ-011]
scenarios: [AT-12, AT-22, AT-17]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-015.md
---

# AVE-REQ-015 — Undo, redo, autosave, and revisions

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-015](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-015.md) (package v1.0); primary gate M2, scope v1.

## Description
All user and AI editing mutations shall be versioned, undoable, and recoverable after interruption.

## Acceptance criteria
- [ ] AC-1 A multi-operation AI edit can be undone as one transaction and redone without changing unrelated edits.
- [ ] AC-2 Autosave does not mark an edit durable until its atomic persistence succeeds; restart recovers the last durable revision.
- [ ] AC-3 History records actor, timestamp, affected objects, previous revision, and a human-readable change summary.
- [ ] AC-4 An export is pinned to one immutable revision even while the user continues editing.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-015 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
