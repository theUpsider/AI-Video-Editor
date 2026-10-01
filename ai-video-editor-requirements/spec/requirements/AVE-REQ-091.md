---
id: AVE-REQ-091
title: "Offline editing and graceful AI degradation"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["U22", "U26", "D02"]
dependencies: ["AVE-REQ-075", "AVE-REQ-053"]
scenarios: ["AT-21", "AT-24"]
---

# AVE-REQ-091 - Offline editing and graceful AI degradation

## Requirement

Once installed, manual editing and supported CPU export shall work without an external model connection, and cached local analysis shall work where its dependencies are present.

## Acceptance criteria

- [ ] **AC-1:** Disconnected operation still permits project load, preview, manual edits, and render to supported local formats.
- [ ] **AC-2:** Cached speech models operate offline; missing uncached models produce a clear download requirement.
- [ ] **AC-3:** A deterministic metadata-based draft may be offered but is explicitly labeled rule-based and does not count as a successful generative-AI integration.
- [ ] **AC-4:** Provider or model failures preserve accepted project state and leave alternative manual workflows usable.

## Dependencies

[AVE-REQ-075](AVE-REQ-075.md); [AVE-REQ-053](AVE-REQ-053.md)

## Verification plan

[AT-21](../ACCEPTANCE_TESTS.md#at-21); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U22](../../intake/USER_BRIEF.md#u22); [U26](../../intake/USER_BRIEF.md#u26); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
