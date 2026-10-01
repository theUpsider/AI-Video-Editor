---
id: AVE-REQ-021
title: "Mixed split-screen and full-width segments"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-003
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U19"]
dependencies: ["AVE-REQ-020", "AVE-REQ-031"]
scenarios: ["AT-02", "AT-11"]
---

# AVE-REQ-021 - Mixed split-screen and full-width segments

## Requirement

A sequence shall switch between simultaneous split-screen recordings and single full-width recordings, then return to split-screen without creating separate projects.

## Acceptance criteria

- [ ] **AC-1:** A split/full/split fixture displays both perspectives, then the full 16:9 shot, then both perspectives again at the specified boundaries.
- [ ] **AC-2:** The full-width segment can use its own audio while adjacent split segments use their designated reference audio.
- [ ] **AC-3:** Cuts and transitions retain the intended total duration, synchronization, and subtitle mapping.
- [ ] **AC-4:** Users and AI can change the layout per segment rather than only globally.

## Dependencies

[AVE-REQ-020](AVE-REQ-020.md); [AVE-REQ-031](AVE-REQ-031.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-11](../ACCEPTANCE_TESTS.md#at-11). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U19](../../intake/USER_BRIEF.md#u19). Parent: [AVE-FEAT-003](../EPICS_AND_FEATURES.md#ave-feat-003).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
