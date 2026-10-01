---
id: AVE-REQ-080
title: "Storage quotas and safe derived-file cleanup"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M7
origins: ["U24", "D01", "D02"]
dependencies: ["AVE-REQ-003", "AVE-REQ-077"]
scenarios: ["AT-22", "AT-23", "AT-20"]
---

# AVE-REQ-080 - Storage quotas and safe derived-file cleanup

## Requirement

The application shall manage derived media storage with quotas, preflight checks, safe temporary directories, and recoverable cleanup.

## Acceptance criteria

- [ ] **AC-1:** Low disk space prevents unsafe work or cancels it with a clear error while preserving originals and durable edits.
- [ ] **AC-2:** Cache cleanup removes only identified unreferenced derived files within application-owned roots.
- [ ] **AC-3:** Failed or cancelled jobs clean temporary outputs without deleting unrelated files or other jobs artifacts.
- [ ] **AC-4:** Users can inspect media, proxy, model-cache, and render storage separately.

## Dependencies

[AVE-REQ-003](AVE-REQ-003.md); [AVE-REQ-077](AVE-REQ-077.md)

## Verification plan

[AT-22](../ACCEPTANCE_TESTS.md#at-22); [AT-23](../ACCEPTANCE_TESTS.md#at-23); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
