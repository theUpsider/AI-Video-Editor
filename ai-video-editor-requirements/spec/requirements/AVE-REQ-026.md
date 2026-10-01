---
id: AVE-REQ-026
title: "Persistent synchronization transforms"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U16", "D03"]
dependencies: ["AVE-REQ-012", "AVE-REQ-024", "AVE-REQ-025"]
scenarios: ["AT-04", "AT-05", "AT-08"]
---

# AVE-REQ-026 - Persistent synchronization transforms

## Requirement

Persist synchronization as explicit reversible transforms between each source time domain and a chosen group reference.

## Acceptance criteria

- [ ] **AC-1:** Document the offset sign convention and store source anchors, method, confidence, and residuals.
- [ ] **AC-2:** The same real-world event maps to the same group time across sources, including sources that began earlier or later.
- [ ] **AC-3:** Changing the selected reference re-expresses transforms without altering established relative alignment.
- [ ] **AC-4:** Synchronization never overwrites or physically trims source files.

## Dependencies

[AVE-REQ-012](AVE-REQ-012.md); [AVE-REQ-024](AVE-REQ-024.md); [AVE-REQ-025](AVE-REQ-025.md)

## Verification plan

[AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-05](../ACCEPTANCE_TESTS.md#at-05); [AT-08](../ACCEPTANCE_TESTS.md#at-08). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
