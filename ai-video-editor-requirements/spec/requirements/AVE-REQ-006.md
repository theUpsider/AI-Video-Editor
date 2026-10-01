---
id: AVE-REQ-006
title: "Library organization and filtering"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M3
origins: ["U17", "U18", "U24"]
dependencies: ["AVE-REQ-003", "AVE-REQ-005"]
scenarios: ["AT-09", "AT-14"]
---

# AVE-REQ-006 - Library organization and filtering

## Requirement

The collection shall support stable labels and filters for camera or perspective, recording day, location, pairing, duration, and analysis status.

## Acceptance criteria

- [ ] **AC-1:** Users can tag or correct camera A/B, left/right preference, trip day, and city in bulk or per asset.
- [ ] **AC-2:** Sorting by capture time respects declared timezone handling and exposes unknown or conflicting timestamps.
- [ ] **AC-3:** Users can preview and select assets using combinations of text, date, location, camera, and analysis filters.
- [ ] **AC-4:** Changing a label updates suggestions without silently rewriting existing manual timeline edits.

## Dependencies

[AVE-REQ-003](AVE-REQ-003.md); [AVE-REQ-005](AVE-REQ-005.md)

## Verification plan

[AT-09](../ACCEPTANCE_TESTS.md#at-09); [AT-14](../ACCEPTANCE_TESTS.md#at-14). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U17](../../intake/USER_BRIEF.md#u17); [U18](../../intake/USER_BRIEF.md#u18); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
