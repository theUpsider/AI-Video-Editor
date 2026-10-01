---
id: AVE-REQ-014
title: "Basic transitions and handles"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U20"]
dependencies: ["AVE-REQ-013"]
scenarios: ["AT-11", "AT-02"]
---

# AVE-REQ-014 - Basic transitions and handles

## Requirement

The editor shall support hard cuts, video cross-dissolves, fades to or from a background, and audio fades or crossfades with editable timing.

## Acceptance criteria

- [ ] **AC-1:** Transition start, end, and duration can be adjusted through the timeline and the editing API.
- [ ] **AC-2:** The editor validates available source handles and prevents accidental shortening, overlap corruption, or audio duplication.
- [ ] **AC-3:** Transitions between split-screen and full-width segments render consistently without leaving stale imagery from a previous layout.
- [ ] **AC-4:** Shortening or deleting a transition is undoable and updates dependent subtitle and section timing correctly when project time changes.

## Dependencies

[AVE-REQ-013](AVE-REQ-013.md)

## Verification plan

[AT-11](../ACCEPTANCE_TESTS.md#at-11); [AT-02](../ACCEPTANCE_TESTS.md#at-02). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
