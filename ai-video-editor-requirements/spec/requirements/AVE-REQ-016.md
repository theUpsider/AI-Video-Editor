---
id: AVE-REQ-016
title: "Concurrent user and AI edit safety"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M5
origins: ["U20", "U24"]
dependencies: ["AVE-REQ-015", "AVE-REQ-048"]
scenarios: ["AT-12", "AT-16"]
---

# AVE-REQ-016 - Concurrent user and AI edit safety

## Requirement

An AI proposal shall not overwrite newer user changes or locked timeline objects without an explicit resolution policy.

## Acceptance criteria

- [ ] **AC-1:** Every proposal references the project revision it read and the assets or objects it intends to change.
- [ ] **AC-2:** A proposal based on a stale revision is rejected with a structured conflict, safely rebased with renewed validation, or presented for user resolution.
- [ ] **AC-3:** Locked objects are protected by the domain service, not only by UI controls.
- [ ] **AC-4:** Users can scope a prompt to selected clips or sections; edits outside the scope are rejected unless explicitly authorized.

## Dependencies

[AVE-REQ-015](AVE-REQ-015.md); [AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-12](../ACCEPTANCE_TESTS.md#at-12); [AT-16](../ACCEPTANCE_TESTS.md#at-16). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
