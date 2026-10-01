---
id: AVE-REQ-013
title: "Manual editing and precision controls"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U20"]
dependencies: ["AVE-REQ-011", "AVE-REQ-012"]
scenarios: ["AT-11", "AT-05"]
---

# AVE-REQ-013 - Manual editing and precision controls

## Requirement

Users shall be able to manually drag, arrange, trim, split, extend within available handles, and delete clip instances using familiar timeline interactions.

## Acceptance criteria

- [ ] **AC-1:** Dragging either clip edge changes its visible interval with snapping and precise numeric in/out controls.
- [ ] **AC-2:** Split-at-playhead, move, reorder, insert, overwrite, and ripple-delete have documented effects on linked items and downstream material.
- [ ] **AC-3:** Users can zoom and scroll the timeline, select a range, step frames, and navigate with keyboard controls.
- [ ] **AC-4:** Invalid trims beyond source handles are prevented or require an explicit freeze/gap effect; the editor never invents source frames.

## Dependencies

[AVE-REQ-011](AVE-REQ-011.md); [AVE-REQ-012](AVE-REQ-012.md)

## Verification plan

[AT-11](../ACCEPTANCE_TESTS.md#at-11); [AT-05](../ACCEPTANCE_TESTS.md#at-05). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
