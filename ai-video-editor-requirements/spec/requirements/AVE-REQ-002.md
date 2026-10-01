---
id: AVE-REQ-002
title: "Collection-based batch ingestion"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M1
origins: ["U01", "U24"]
dependencies: ["AVE-REQ-001"]
scenarios: ["AT-01", "AT-23"]
---

# AVE-REQ-002 - Collection-based batch ingestion

## Requirement

The collection shall accept batches of video, audio, and image files, including large camera recordings, with visible import progress and recoverable failures.

## Acceptance criteria

- [ ] **AC-1:** Users can add multiple files through a file picker and drag-and-drop, then see per-file queued, importing, ready, or failed states.
- [ ] **AC-2:** An interrupted large upload can resume or retry without duplicating the media asset or exhausting server memory.
- [ ] **AC-3:** A failed or unsupported file does not prevent valid files in the same batch from importing.
- [ ] **AC-4:** Local file references, when offered, are limited to explicitly configured import roots; browser filenames are never treated as trusted server paths.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md)

## Verification plan

[AT-01](../ACCEPTANCE_TESTS.md#at-01); [AT-23](../ACCEPTANCE_TESTS.md#at-23). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U01](../../intake/USER_BRIEF.md#u01); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
