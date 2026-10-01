---
id: AVE-REQ-046
title: Reviewable and atomic AI edit proposals
type: functional
status: ready
priority: must
parent: AVE-FEAT-009
source: human
scope: v1
primary_gate: M5
origins: [U20, U24, D01]
dependencies: [AVE-REQ-015, AVE-REQ-016, AVE-REQ-048]
scenarios: [AT-12, AT-16, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-046.md
---

# AVE-REQ-046 — Reviewable and atomic AI edit proposals

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-009 — AI draft and conversational editing](AVE-FEAT-009-ai-draft-and-conversational-editing.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-046](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-046.md) (package v1.0); primary gate M5, scope v1.

## Description
AI outputs shall be validated structured edit proposals with a readable diff, dry run, scoped application, and undo.

## Acceptance criteria
- [ ] AC-1 Users can inspect affected clips, source ranges, layout changes, audio changes, captions, and estimated expensive operations before acceptance.
- [ ] AC-2 A transaction either applies completely against the expected revision or leaves the project unchanged.
- [ ] AC-3 Repeating an idempotent request does not duplicate clips, captions, or export jobs.
- [ ] AC-4 Clear-all, overwrite, media deletion, external uploads, and spending actions are not silently authorized by a general editing prompt.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](AVE-REQ-015-undo-redo-autosave-and-revisions.md)
- [AVE-REQ-016 — Concurrent user and AI edit safety](AVE-REQ-016-concurrent-user-and-ai-edit-safety.md)
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-046 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12), [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
