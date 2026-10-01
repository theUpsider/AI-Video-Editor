---
id: AVE-REQ-040
title: "Non-destructive color and tonal controls"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-008
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U21"]
dependencies: ["AVE-REQ-011", "AVE-REQ-019"]
scenarios: ["AT-10", "AT-26"]
---

# AVE-REQ-040 - Non-destructive color and tonal controls

## Requirement

The editor shall expose non-destructive exposure, contrast, saturation, white balance or temperature/tint, shadows, highlights, and tonal adjustments.

## Acceptance criteria

- [ ] **AC-1:** Controls operate on a defined working color representation, have bounded values, and can be reset or bypassed.
- [ ] **AC-2:** The selected clip or project look can be inspected before and after adjustment without changing source bytes.
- [ ] **AC-3:** The grading model is exposed through validated editing operations rather than arbitrary filter-string injection.
- [ ] **AC-4:** Known color-ramp fixtures produce the documented tonal change in reference rendering.

## Dependencies

[AVE-REQ-011](AVE-REQ-011.md); [AVE-REQ-019](AVE-REQ-019.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-26](../ACCEPTANCE_TESTS.md#at-26). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U21](../../intake/USER_BRIEF.md#u21). Parent: [AVE-FEAT-008](../EPICS_AND_FEATURES.md#ave-feat-008).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
