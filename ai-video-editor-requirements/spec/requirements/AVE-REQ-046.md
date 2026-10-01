---
id: AVE-REQ-046
title: "Reviewable and atomic AI edit proposals"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-009
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U20", "U24", "D01"]
dependencies: ["AVE-REQ-015", "AVE-REQ-016", "AVE-REQ-048"]
scenarios: ["AT-12", "AT-16", "AT-20"]
---

# AVE-REQ-046 - Reviewable and atomic AI edit proposals

## Requirement

AI outputs shall be validated structured edit proposals with a readable diff, dry run, scoped application, and undo.

## Acceptance criteria

- [ ] **AC-1:** Users can inspect affected clips, source ranges, layout changes, audio changes, captions, and estimated expensive operations before acceptance.
- [ ] **AC-2:** A transaction either applies completely against the expected revision or leaves the project unchanged.
- [ ] **AC-3:** Repeating an idempotent request does not duplicate clips, captions, or export jobs.
- [ ] **AC-4:** Clear-all, overwrite, media deletion, external uploads, and spending actions are not silently authorized by a general editing prompt.

## Dependencies

[AVE-REQ-015](AVE-REQ-015.md); [AVE-REQ-016](AVE-REQ-016.md); [AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-12](../ACCEPTANCE_TESTS.md#at-12); [AT-16](../ACCEPTANCE_TESTS.md#at-16); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20); [U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-009](../EPICS_AND_FEATURES.md#ave-feat-009).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
