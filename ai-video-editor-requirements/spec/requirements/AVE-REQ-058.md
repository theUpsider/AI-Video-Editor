---
id: AVE-REQ-058
title: "Editable searchable source transcripts"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U07", "U09"]
dependencies: ["AVE-REQ-057"]
scenarios: ["AT-13", "AT-19"]
---

# AVE-REQ-058 - Editable searchable source transcripts

## Requirement

Users shall inspect, correct, and search transcripts linked to source intervals without changing original recordings.

## Acceptance criteria

- [ ] **AC-1:** Search results jump to the relevant source or timeline occurrence and show asset identity.
- [ ] **AC-2:** Corrections preserve source timing or allow explicit timing adjustment and invalidate affected derived translations or summaries.
- [ ] **AC-3:** A source appearing multiple times on a timeline retains a single source transcript with separate timeline mappings.
- [ ] **AC-4:** Imported or manually written transcripts remain labeled as such, distinct from model-generated text.

## Dependencies

[AVE-REQ-057](AVE-REQ-057.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-19](../ACCEPTANCE_TESTS.md#at-19). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U07](../../intake/USER_BRIEF.md#u07); [U09](../../intake/USER_BRIEF.md#u09). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
