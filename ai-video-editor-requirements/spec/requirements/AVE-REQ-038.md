---
id: AVE-REQ-038
title: "Editable date and location sections"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-007
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U17", "U18"]
dependencies: ["AVE-REQ-005", "AVE-REQ-011"]
scenarios: ["AT-09", "AT-11"]
---

# AVE-REQ-038 - Editable date and location sections

## Requirement

The project shall support named sections or chapters with explicit timeline boundaries, optionally suggested from recording days or locations.

## Acceptance criteria

- [ ] **AC-1:** Users can create, rename, move, split, and delete sections and correct automatic day/city groupings.
- [ ] **AC-2:** Suggestions record whether grouping derives from metadata, user labels, or uncertain inference.
- [ ] **AC-3:** Section boundaries remain valid after timeline edits using a documented anchoring policy.
- [ ] **AC-4:** A trip can contain multiple sections for one city or date; unknown metadata does not prevent manual organization.

## Dependencies

[AVE-REQ-005](AVE-REQ-005.md); [AVE-REQ-011](AVE-REQ-011.md)

## Verification plan

[AT-09](../ACCEPTANCE_TESTS.md#at-09); [AT-11](../ACCEPTANCE_TESTS.md#at-11). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U17](../../intake/USER_BRIEF.md#u17); [U18](../../intake/USER_BRIEF.md#u18). Parent: [AVE-FEAT-007](../EPICS_AND_FEATURES.md#ave-feat-007).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
