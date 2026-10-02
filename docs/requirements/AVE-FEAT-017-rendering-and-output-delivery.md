---
id: AVE-FEAT-017
title: Rendering and output delivery
status: in-progress
priority: must
parent: AVE-EPIC-07
---

# AVE-FEAT-017 — Rendering and output delivery

## Intent
Baseline feature [AVE-FEAT-017 — Rendering and output delivery](../../ai-video-editor-requirements/spec/EPICS_AND_FEATURES.md#ave-feat-017) of [AVE-EPIC-07 — Short-form content and delivery](AVE-EPIC-07-short-form-content-and-delivery.md), serving [GOAL-007](../PRODUCT.md#product-goals). User-brief clauses covered by its requirements: [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02), [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03), [U11](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u11), [U12](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u12), [U13](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u13), [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18), [U22](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u22), [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23), [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24), [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01), [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02), [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03).

## User journey
- [UJ-005](../PRODUCT.md#core-user-journeys)
- Acceptance scenarios: [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24), [AT-25](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-25), [AT-28](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-28).

## Requirements
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-073 — Multiple containers and codec choices](AVE-REQ-073-multiple-containers-and-codec-choices.md)
- [AVE-REQ-074 — Mixed-rate input and controlled output timing](AVE-REQ-074-mixed-rate-input-and-controlled-output-timing.md)
- [AVE-REQ-075 — CPU-only reference rendering](AVE-REQ-075-cpu-only-reference-rendering.md)
- [AVE-REQ-076 — Capability-tested hardware acceleration](AVE-REQ-076-capability-tested-hardware-acceleration.md)
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)
- [AVE-REQ-078 — Export preflight and decoded-output validation](AVE-REQ-078-export-preflight-and-decoded-output-validation.md)
- [AVE-REQ-079 — Editable output presets and quality guidance](AVE-REQ-079-editable-output-presets-and-quality-guidance.md)
- [AVE-REQ-080 — Storage quotas and safe derived-file cleanup](AVE-REQ-080-storage-quotas-and-safe-derived-file-cleanup.md)
- [AVE-REQ-081 — Complete output delivery bundle](AVE-REQ-081-complete-output-delivery-bundle.md)
- [AVE-REQ-102 — Seek-safe decoding of gradual-refresh sources](AVE-REQ-102-seek-safe-decoding-of-gradual-refresh-sources.md)

## Out of scope
- Object and motion tracking and advanced continuous video understanding, deferred to a later version ([scope](../../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md)).

## Feature acceptance
- [ ] Every version-one requirement above is `done`, and its acceptance scenarios pass on real rendered output in milestone-review.

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — in-progress — AVE-REQ-072 and AVE-REQ-075 entered in-progress (lead)
