---
id: AVE-REQ-068
title: "Grounded short-form highlight suggestions"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-015
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U12"]
dependencies: ["AVE-REQ-047", "AVE-REQ-058", "AVE-REQ-065"]
scenarios: ["AT-19", "AT-14"]
---

# AVE-REQ-068 - Grounded short-form highlight suggestions

## Requirement

The AI shall propose short-form highlights with a default duration range of 15 to 20 seconds and editable editorial rationale.

## Acceptance criteria

- [ ] **AC-1:** Default target is 18 seconds within the user-configurable 15..20-second range; source duration and hard constraints are respected.
- [ ] **AC-2:** Candidates reference selected source/project intervals, relevant transcript or visual evidence, and an explanation of the proposed hook or subject.
- [ ] **AC-3:** Prefer coherent starts and endings; if no adequate candidate exists, report that rather than padding with invented footage or claiming guaranteed engagement.
- [ ] **AC-4:** Users can compare candidates, choose one or several, and adjust their ranges before export.

## Dependencies

[AVE-REQ-047](AVE-REQ-047.md); [AVE-REQ-058](AVE-REQ-058.md); [AVE-REQ-065](AVE-REQ-065.md)

## Verification plan

[AT-19](../ACCEPTANCE_TESTS.md#at-19); [AT-14](../ACCEPTANCE_TESTS.md#at-14). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U12](../../intake/USER_BRIEF.md#u12). Parent: [AVE-FEAT-015](../EPICS_AND_FEATURES.md#ave-feat-015).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
