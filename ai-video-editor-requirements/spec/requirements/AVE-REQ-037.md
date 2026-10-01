---
id: AVE-REQ-037
title: "Basic overlay animation without tracking"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-006
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U04", "U05", "U06"]
dependencies: ["AVE-REQ-034"]
scenarios: ["AT-10", "AT-31"]
---

# AVE-REQ-037 - Basic overlay animation without tracking

## Requirement

Overlays shall support simple timed opacity fades and explicit user-defined position or scale keyframes without following detected objects.

## Acceptance criteria

- [ ] **AC-1:** Fade-in and fade-out durations can be edited and do not exceed the overlay duration without validation.
- [ ] **AC-2:** Keyframed values use defined interpolation and are identical in the composition contract for preview and rendering.
- [ ] **AC-3:** Static overlay operation does not depend on a tracking model.
- [ ] **AC-4:** No object- or motion-tracking implementation is introduced as a prerequisite for version one.

## Dependencies

[AVE-REQ-034](AVE-REQ-034.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-31](../ACCEPTANCE_TESTS.md#at-31). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U04](../../intake/USER_BRIEF.md#u04); [U05](../../intake/USER_BRIEF.md#u05); [U06](../../intake/USER_BRIEF.md#u06). Parent: [AVE-FEAT-006](../EPICS_AND_FEATURES.md#ave-feat-006).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
