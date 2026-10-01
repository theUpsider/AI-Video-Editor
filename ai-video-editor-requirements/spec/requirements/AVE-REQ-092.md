---
id: AVE-REQ-092
title: "User and developer handover"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["U24", "D02"]
dependencies: ["AVE-REQ-082", "AVE-REQ-083"]
scenarios: ["AT-21", "AT-30"]
---

# AVE-REQ-092 - User and developer handover

## Requirement

Deliver complete instructions for operating, extending, testing, and deploying the implemented editor.

## Acceptance criteria

- [ ] **AC-1:** Include a quick start, example split/full/split project, provider setup, CPU/GPU configuration, subtitle/section/short export, and recovery guide.
- [ ] **AC-2:** Document the project schema, typed editing API, MCP setup, model registry, renderer assumptions, and known limitations.
- [ ] **AC-3:** Provide screenshots or a recorded walkthrough from the actual running application and generated test media, not a mock design.
- [ ] **AC-4:** List exact verified commands and distinguish tested features from implemented but externally unverified integrations.

## Dependencies

[AVE-REQ-082](AVE-REQ-082.md); [AVE-REQ-083](AVE-REQ-083.md)

## Verification plan

[AT-21](../ACCEPTANCE_TESTS.md#at-21); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
