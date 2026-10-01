---
id: AVE-REQ-031
title: "Explicit master audio and routing"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-005
epic: AVE-EPIC-03
primary_gate: M1
origins: ["U02", "U15", "U19"]
dependencies: ["AVE-REQ-011", "AVE-REQ-012"]
scenarios: ["AT-04", "AT-02", "AT-28"]
---

# AVE-REQ-031 - Explicit master audio and routing

## Requirement

A segment or synchronization group shall be able to use one selected source audio track as the final audio while displaying multiple video perspectives.

## Acceptance criteria

- [ ] **AC-1:** Selecting camera A as reference audio mutes camera B in the final mix without removing B audio needed for analysis.
- [ ] **AC-2:** A silent secondary video is supported without generating a synthetic duplicate audio stream.
- [ ] **AC-3:** Switching between split-screen and full-width segments follows explicit segment-level audio routing and fade rules.
- [ ] **AC-4:** An unavailable reference audio stream triggers a visible fallback decision, not an unnoticed substitute.

## Dependencies

[AVE-REQ-011](AVE-REQ-011.md); [AVE-REQ-012](AVE-REQ-012.md)

## Verification plan

[AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-28](../ACCEPTANCE_TESTS.md#at-28). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U15](../../intake/USER_BRIEF.md#u15); [U19](../../intake/USER_BRIEF.md#u19). Parent: [AVE-FEAT-005](../EPICS_AND_FEATURES.md#ave-feat-005).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
