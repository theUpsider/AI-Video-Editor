---
id: AVE-REQ-027
title: "Unequal coverage and missing-perspective policy"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U16", "U19"]
dependencies: ["AVE-REQ-026", "AVE-REQ-021"]
scenarios: ["AT-05", "AT-02"]
---

# AVE-REQ-027 - Unequal coverage and missing-perspective policy

## Requirement

The editor shall explicitly handle unequal recording coverage rather than repeat stale frames or silently discard material.

## Acceptance criteria

- [ ] **AC-1:** Default auto-draft split-screen segments use the common overlap and preserve unused material in the collection.
- [ ] **AC-2:** Users may instead retain the union using an explicit full-width fallback, background gap, or separately selected freeze policy.
- [ ] **AC-3:** For A covering master time 0..30 and B covering 2..27, default split coverage is 2..27, not 0..30.
- [ ] **AC-4:** The UI shows which time spans lose a perspective or reference audio and explains the selected policy.

## Dependencies

[AVE-REQ-026](AVE-REQ-026.md); [AVE-REQ-021](AVE-REQ-021.md)

## Verification plan

[AT-05](../ACCEPTANCE_TESTS.md#at-05); [AT-02](../ACCEPTANCE_TESTS.md#at-02). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16); [U19](../../intake/USER_BRIEF.md#u19). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
