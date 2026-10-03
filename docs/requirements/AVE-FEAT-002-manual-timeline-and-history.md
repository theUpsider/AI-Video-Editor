---
id: AVE-FEAT-002
title: Manual timeline and history
status: in-progress
priority: must
parent: AVE-EPIC-02
---

# AVE-FEAT-002 — Manual timeline and history

## Intent
Baseline feature [AVE-FEAT-002 — Manual timeline and history](../../ai-video-editor-requirements/spec/EPICS_AND_FEATURES.md#ave-feat-002) of [AVE-EPIC-02 — Editing and composition](AVE-EPIC-02-editing-and-composition.md), serving [GOAL-002](../PRODUCT.md#product-goals). User-brief clauses covered by its requirements: [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02), [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03), [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15), [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20), [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24), [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01), [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03).

## User journey
- [UJ-003](../PRODUCT.md#core-user-journeys)
- Acceptance scenarios: [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-27](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-27).

## Requirements
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-013 — Manual editing and precision controls](AVE-REQ-013-manual-editing-and-precision-controls.md)
- [AVE-REQ-014 — Basic transitions and handles](AVE-REQ-014-basic-transitions-and-handles.md)
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](AVE-REQ-015-undo-redo-autosave-and-revisions.md)
- [AVE-REQ-016 — Concurrent user and AI edit safety](AVE-REQ-016-concurrent-user-and-ai-edit-safety.md)
- [AVE-REQ-017 — Usable synchronized preview](AVE-REQ-017-usable-synchronized-preview.md)
- [AVE-REQ-104 — Robust audio placement for timestamp jitter of 5 ms or more](AVE-REQ-104-robust-audio-placement-for-timestamp-jitter.md)

## Out of scope
- Object and motion tracking and advanced continuous video understanding, deferred to a later version ([scope](../../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md)).

## Feature acceptance
- [ ] Every version-one requirement above is `done`, and its acceptance scenarios pass on real rendered output in milestone-review.

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — in-progress — AVE-REQ-012 entered in-progress (lead)
