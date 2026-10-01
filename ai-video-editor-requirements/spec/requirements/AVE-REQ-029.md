---
id: AVE-REQ-029
title: "Linked edits preserve synchronization"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U20"]
dependencies: ["AVE-REQ-013", "AVE-REQ-026"]
scenarios: ["AT-05", "AT-11", "AT-12"]
---

# AVE-REQ-029 - Linked edits preserve synchronization

## Requirement

Timeline edits on a synchronized group shall preserve relative timing unless the user explicitly chooses to slip or unlink one source.

## Acceptance criteria

- [ ] **AC-1:** Moving, splitting, ripple-deleting, or trimming a linked group updates all affected video, audio, and overlay mappings as specified.
- [ ] **AC-2:** A deliberate single-source slip warns that alignment changes and creates an undoable operation.
- [ ] **AC-3:** Locked linked members prevent a conflicting group edit rather than leaving the group partially updated.
- [ ] **AC-4:** Undo and redo restore both visible arrangement and synchronization transforms.

## Dependencies

[AVE-REQ-013](AVE-REQ-013.md); [AVE-REQ-026](AVE-REQ-026.md)

## Verification plan

[AT-05](../ACCEPTANCE_TESTS.md#at-05); [AT-11](../ACCEPTANCE_TESTS.md#at-11); [AT-12](../ACCEPTANCE_TESTS.md#at-12). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
