---
id: AVE-REQ-033
title: "Rendered audiovisual synchronization verification"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-005
epic: AVE-EPIC-03
primary_gate: M7
origins: ["U15", "U16", "D03"]
dependencies: ["AVE-REQ-028", "AVE-REQ-031", "AVE-REQ-072"]
scenarios: ["AT-04", "AT-08", "AT-28"]
---

# AVE-REQ-033 - Rendered audiovisual synchronization verification

## Requirement

Synchronization acceptance shall measure the exported media, not only the internal offset calculation.

## Acceptance criteria

- [ ] **AC-1:** A fixture with known visible events and audible impulses is decoded after export and checked at beginning, middle, and end.
- [ ] **AC-2:** The qualified test bound is at most one output video frame after accounting for container timestamps and audio encoder delay.
- [ ] **AC-3:** Conversion between 44.1 kHz and 48 kHz and between fractional and integer video rates does not silently change real-time duration.
- [ ] **AC-4:** Unverifiable real-world alignment remains labeled unverified or manual; the UI does not claim perfect lip synchronization without evidence.

## Dependencies

[AVE-REQ-028](AVE-REQ-028.md); [AVE-REQ-031](AVE-REQ-031.md); [AVE-REQ-072](AVE-REQ-072.md)

## Verification plan

[AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-08](../ACCEPTANCE_TESTS.md#at-08); [AT-28](../ACCEPTANCE_TESTS.md#at-28). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-005](../EPICS_AND_FEATURES.md#ave-feat-005).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
