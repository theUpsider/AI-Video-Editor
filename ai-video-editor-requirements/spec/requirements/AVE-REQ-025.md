---
id: AVE-REQ-025
title: "Silent or weak-evidence synchronization"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U16"]
dependencies: ["AVE-REQ-023"]
scenarios: ["AT-06", "AT-07"]
---

# AVE-REQ-025 - Silent or weak-evidence synchronization

## Requirement

For sources without usable shared audio, the system shall attempt available timestamp or explicit visual-event alignment and otherwise offer manual anchors.

## Acceptance criteria

- [ ] **AC-1:** A visible shared flash or marked event may establish an offset; object tracking is not required.
- [ ] **AC-2:** Coarse camera timestamps alone are labeled approximate, especially when clocks or timezones differ.
- [ ] **AC-3:** When neither shared audio, reliable timestamps, nor a common event exists, return insufficient evidence rather than a fabricated exact alignment.
- [ ] **AC-4:** A manual anchor can complete synchronization without requiring the silent source to gain an audio track.

## Dependencies

[AVE-REQ-023](AVE-REQ-023.md)

## Verification plan

[AT-06](../ACCEPTANCE_TESTS.md#at-06); [AT-07](../ACCEPTANCE_TESTS.md#at-07). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
