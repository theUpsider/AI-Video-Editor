---
id: AVE-REQ-028
title: "Clock-drift detection and correction"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U16", "D03"]
dependencies: ["AVE-REQ-026"]
scenarios: ["AT-08", "AT-13"]
---

# AVE-REQ-028 - Clock-drift detection and correction

## Requirement

The synchronization subsystem shall inspect alignment at multiple points, identify evidence of clock drift, and support a recorded affine time correction when justified.

## Acceptance criteria

- [ ] **AC-1:** Distinguish a constant offset from progressive drift using more than one anchor on a sufficiently long recording.
- [ ] **AC-2:** A qualified synthetic offset-plus-drift fixture aligns at beginning, middle, and end to within one output frame after correction.
- [ ] **AC-3:** Apply the chosen mapping consistently to video, audio, and transcript times; preserve audio pitch when time-stretching audio.
- [ ] **AC-4:** Low-confidence or non-linear drift is flagged for manual review; a single uncertain match is not silently converted into a speed change.

## Dependencies

[AVE-REQ-026](AVE-REQ-026.md)

## Verification plan

[AT-08](../ACCEPTANCE_TESTS.md#at-08); [AT-13](../ACCEPTANCE_TESTS.md#at-13). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
