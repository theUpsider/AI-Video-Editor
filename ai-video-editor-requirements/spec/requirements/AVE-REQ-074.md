---
id: AVE-REQ-074
title: "Mixed-rate input and controlled output timing"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U03"]
dependencies: ["AVE-REQ-012", "AVE-REQ-018", "AVE-REQ-072"]
scenarios: ["AT-03", "AT-04", "AT-18"]
---

# AVE-REQ-074 - Mixed-rate input and controlled output timing

## Requirement

Inputs with different frame rates shall play at their intended real-time speed within one configurable output rate.

## Acceptance criteria

- [ ] **AC-1:** Validate combinations of 24, 25, 30, 60, 30000/1001, 60000/1001, and a variable-frame-rate fixture.
- [ ] **AC-2:** Default frame-rate conversion uses documented frame selection/repetition where necessary; optical-flow interpolation is not required.
- [ ] **AC-3:** Duration, audio timing, synchronization, and overlays remain aligned after conversion.
- [ ] **AC-4:** Exports record the exact rational output rate and do not relabel 59.94 material as 60 without an explicit conversion.

## Dependencies

[AVE-REQ-012](AVE-REQ-012.md); [AVE-REQ-018](AVE-REQ-018.md); [AVE-REQ-072](AVE-REQ-072.md)

## Verification plan

[AT-03](../ACCEPTANCE_TESTS.md#at-03); [AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-18](../ACCEPTANCE_TESTS.md#at-18). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U03](../../intake/USER_BRIEF.md#u03). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
