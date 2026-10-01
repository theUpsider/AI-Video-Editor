---
id: AVE-REQ-035
title: "Contextual opening titles and end references"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-006
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U05", "U17", "U18"]
dependencies: ["AVE-REQ-034", "AVE-REQ-005", "AVE-REQ-038"]
scenarios: ["AT-10", "AT-09", "AT-14"]
---

# AVE-REQ-035 - Contextual opening titles and end references

## Requirement

The editor shall support brief opening titles, location/date labels, and ending references or credits without displaying them throughout the video by default.

## Acceptance criteria

- [ ] **AC-1:** Initial suggestions use a configurable approximately 3-second opening title and 4-second ending card, bounded by the actual segment length.
- [ ] **AC-2:** Location and date wording comes from verified metadata or user labels; unknown locations are omitted or left for confirmation.
- [ ] **AC-3:** Users can choose project-level or section-level title placement and suppress repeated titles.
- [ ] **AC-4:** End references and credits accept user-supplied content and sources; the AI does not fabricate attribution.

## Dependencies

[AVE-REQ-034](AVE-REQ-034.md); [AVE-REQ-005](AVE-REQ-005.md); [AVE-REQ-038](AVE-REQ-038.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-09](../ACCEPTANCE_TESTS.md#at-09); [AT-14](../ACCEPTANCE_TESTS.md#at-14). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U05](../../intake/USER_BRIEF.md#u05); [U17](../../intake/USER_BRIEF.md#u17); [U18](../../intake/USER_BRIEF.md#u18). Parent: [AVE-FEAT-006](../EPICS_AND_FEATURES.md#ave-feat-006).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
