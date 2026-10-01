---
id: AVE-REQ-023
title: "Synchronization candidate matching"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U16", "U17"]
dependencies: ["AVE-REQ-004", "AVE-REQ-005", "AVE-REQ-006"]
scenarios: ["AT-04", "AT-07", "AT-09"]
---

# AVE-REQ-023 - Synchronization candidate matching

## Requirement

The system shall propose likely simultaneous recordings and camera pairs using available capture metadata, audio similarity, and user camera labels.

## Acceptance criteria

- [ ] **AC-1:** Display candidate pairings, evidence, estimated overlap, and confidence; the user can override or create a group manually.
- [ ] **AC-2:** Do not pair unrelated recordings merely because filenames or coarse timestamps are similar.
- [ ] **AC-3:** Handle different start and end times and recording segments split into multiple files without assuming one-to-one filenames.
- [ ] **AC-4:** Retain the pairing decision independently from layout and final audio routing.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md); [AVE-REQ-005](AVE-REQ-005.md); [AVE-REQ-006](AVE-REQ-006.md)

## Verification plan

[AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-07](../ACCEPTANCE_TESTS.md#at-07); [AT-09](../ACCEPTANCE_TESTS.md#at-09). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16); [U17](../../intake/USER_BRIEF.md#u17). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
