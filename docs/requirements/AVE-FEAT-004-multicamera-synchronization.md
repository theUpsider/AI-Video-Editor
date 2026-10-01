---
id: AVE-FEAT-004
title: Multicamera synchronization
status: ready
priority: must
parent: AVE-EPIC-03
---

# AVE-FEAT-004 — Multicamera synchronization

## Intent
Baseline feature [AVE-FEAT-004 — Multicamera synchronization](../../ai-video-editor-requirements/spec/EPICS_AND_FEATURES.md#ave-feat-004) of [AVE-EPIC-03 — Synchronized perspectives and sound](AVE-EPIC-03-synchronized-perspectives-and-sound.md), serving [GOAL-003](../PRODUCT.md#product-goals). User-brief clauses covered by its requirements: [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15), [U16](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u16), [U17](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u17), [U19](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u19), [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20), [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03).

## User journey
- [UJ-002](../PRODUCT.md#core-user-journeys)
- Acceptance scenarios: [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05), [AT-06](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-06), [AT-07](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-07), [AT-08](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-08), [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13).

## Requirements
- [AVE-REQ-023 — Synchronization candidate matching](AVE-REQ-023-synchronization-candidate-matching.md)
- [AVE-REQ-024 — Audio-based offset estimation](AVE-REQ-024-audio-based-offset-estimation.md)
- [AVE-REQ-025 — Silent or weak-evidence synchronization](AVE-REQ-025-silent-or-weak-evidence-synchronization.md)
- [AVE-REQ-026 — Persistent synchronization transforms](AVE-REQ-026-persistent-synchronization-transforms.md)
- [AVE-REQ-027 — Unequal coverage and missing-perspective policy](AVE-REQ-027-unequal-coverage-and-missing-perspective-policy.md)
- [AVE-REQ-028 — Clock-drift detection and correction](AVE-REQ-028-clock-drift-detection-and-correction.md)
- [AVE-REQ-029 — Linked edits preserve synchronization](AVE-REQ-029-linked-edits-preserve-synchronization.md)
- [AVE-REQ-030 — Manual synchronization tools](AVE-REQ-030-manual-synchronization-tools.md)

## Out of scope
- Object and motion tracking and advanced continuous video understanding, deferred to a later version ([scope](../../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md)).

## Feature acceptance
- [ ] Every version-one requirement above is `done`, and its acceptance scenarios pass on real rendered output in milestone-review.

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
