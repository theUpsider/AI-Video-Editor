---
id: AVE-REQ-005
title: "Capture date, timezone, and location metadata"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M3
origins: ["U17", "U18"]
dependencies: ["AVE-REQ-004"]
scenarios: ["AT-09", "AT-20"]
---

# AVE-REQ-005 - Capture date, timezone, and location metadata

## Requirement

The application shall extract available capture date, time, timezone, location, and camera metadata, preserve provenance, and support user corrections.

## Acceptance criteria

- [ ] **AC-1:** Show raw metadata and normalized values separately, including whether capture time and timezone are known, assumed, or user-supplied.
- [ ] **AC-2:** Do not equate file modification time with recording time or silently treat timezone-free camera timestamps as UTC.
- [ ] **AC-3:** Missing GPS or location remains unknown; manual city and timezone labels are supported and retained.
- [ ] **AC-4:** An optional reverse-geocoding request requires consent before coordinates leave the system, and exported metadata can omit location.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md)

## Verification plan

[AT-09](../ACCEPTANCE_TESTS.md#at-09); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U17](../../intake/USER_BRIEF.md#u17); [U18](../../intake/USER_BRIEF.md#u18). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
