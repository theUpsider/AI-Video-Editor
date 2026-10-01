---
id: AVE-REQ-012
title: "Canonical rational timing and temporal invariants"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M1
origins: ["U03", "U15", "D03"]
dependencies: ["AVE-REQ-004"]
scenarios: ["AT-03", "AT-04", "AT-13"]
---

# AVE-REQ-012 - Canonical rational timing and temporal invariants

## Requirement

All editing, synchronization, subtitles, and rendering shall share a canonical timing model with exact rational values or integer ticks and explicit time domains.

## Acceptance criteria

- [ ] **AC-1:** Distinguish source presentation time, synchronization-group time, project time, section time, and export time.
- [ ] **AC-2:** Use half-open intervals [start, end) and reject negative durations, invalid source bounds, NaN values, and unsupported time transforms.
- [ ] **AC-3:** At 60000/1001 fps, repeated edits and long timelines do not accumulate errors from rounding the rate to 60 or storing frame counts as approximate seconds.
- [ ] **AC-4:** Variable-frame-rate inputs are mapped by presentation timestamps; output frame-rate conversion does not change intended playback speed.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md)

## Verification plan

[AT-03](../ACCEPTANCE_TESTS.md#at-03); [AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-13](../ACCEPTANCE_TESTS.md#at-13). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U03](../../intake/USER_BRIEF.md#u03); [U15](../../intake/USER_BRIEF.md#u15); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
