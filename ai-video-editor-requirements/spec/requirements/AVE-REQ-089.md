---
id: AVE-REQ-089
title: "Accessible, discoverable editing interface"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["U20", "U24"]
dependencies: ["AVE-REQ-017", "AVE-REQ-044"]
scenarios: ["AT-11", "AT-21", "AT-27"]
---

# AVE-REQ-089 - Accessible, discoverable editing interface

## Requirement

Deliver a usable desktop editing layout with a collection, preview, timeline, inspector, AI panel, and job/output views.

## Acceptance criteria

- [ ] **AC-1:** Core actions have labels, keyboard access, focus visibility, useful empty states, and actionable errors.
- [ ] **AC-2:** Provide numeric alternatives to pointer-only trim, crop, synchronization, and overlay-position controls.
- [ ] **AC-3:** Test current Chromium and Firefox desktop paths supported by the chosen proxy formats and document any browser limitations.
- [ ] **AC-4:** Editing and export remain available when AI analysis is busy or disabled; no dead primary buttons or decorative-only timeline.

## Dependencies

[AVE-REQ-017](AVE-REQ-017.md); [AVE-REQ-044](AVE-REQ-044.md)

## Verification plan

[AT-11](../ACCEPTANCE_TESTS.md#at-11); [AT-21](../ACCEPTANCE_TESTS.md#at-21); [AT-27](../ACCEPTANCE_TESTS.md#at-27). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
