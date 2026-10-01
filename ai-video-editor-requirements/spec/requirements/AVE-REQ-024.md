---
id: AVE-REQ-024
title: "Audio-based offset estimation"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U16"]
dependencies: ["AVE-REQ-023", "AVE-REQ-012"]
scenarios: ["AT-04", "AT-05"]
---

# AVE-REQ-024 - Audio-based offset estimation

## Requirement

When recordings contain sufficiently correlated audio, the system shall estimate their temporal offset from the original audio signals.

## Acceptance criteria

- [ ] **AC-1:** Use audio from a camera for synchronization even when that camera will be muted in the final edit.
- [ ] **AC-2:** Test positive and negative known offsets, gain changes, background noise, different audio sample rates, and partial overlaps.
- [ ] **AC-3:** Report the estimation method, residual error or equivalent confidence evidence, and aligned source intervals.
- [ ] **AC-4:** On the qualified synthetic fixtures in AT-04, alignment error is at most one project output frame; do not generalize this bound to arbitrary real footage.

## Dependencies

[AVE-REQ-023](AVE-REQ-023.md); [AVE-REQ-012](AVE-REQ-012.md)

## Verification plan

[AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-05](../ACCEPTANCE_TESTS.md#at-05). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
