---
id: AVE-REQ-043
title: "Color consistency across outputs"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-008
epic: AVE-EPIC-04
primary_gate: M7
origins: ["U21", "D03"]
dependencies: ["AVE-REQ-022", "AVE-REQ-041", "AVE-REQ-042"]
scenarios: ["AT-10", "AT-18", "AT-26"]
---

# AVE-REQ-043 - Color consistency across outputs

## Requirement

Project and camera looks shall remain consistent across full exports, section exports, shorts, and available CPU/GPU encoding paths.

## Acceptance criteria

- [ ] **AC-1:** All outputs inherit the intended grade unless an explicit per-output override is set.
- [ ] **AC-2:** Color tags and pixel format in the encoded file match the selected output policy.
- [ ] **AC-3:** Reference tests compare color patches with documented lossy-codec tolerances and detect double transforms or full/limited-range errors.
- [ ] **AC-4:** Hardware encoding availability does not imply every grading filter executes on the GPU.

## Dependencies

[AVE-REQ-022](AVE-REQ-022.md); [AVE-REQ-041](AVE-REQ-041.md); [AVE-REQ-042](AVE-REQ-042.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-26](../ACCEPTANCE_TESTS.md#at-26). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U21](../../intake/USER_BRIEF.md#u21); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-008](../EPICS_AND_FEATURES.md#ave-feat-008).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
