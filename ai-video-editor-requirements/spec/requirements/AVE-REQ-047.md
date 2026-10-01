---
id: AVE-REQ-047
title: "Grounded editorial reasoning"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-009
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U07", "U12", "U13", "U24"]
dependencies: ["AVE-REQ-058", "AVE-REQ-065"]
scenarios: ["AT-14", "AT-19", "AT-25"]
---

# AVE-REQ-047 - Grounded editorial reasoning

## Requirement

AI recommendations shall be grounded in identified assets, source intervals, transcripts, metadata, or explicitly labeled visual inference.

## Acceptance criteria

- [ ] **AC-1:** Every suggested cut, title fact, highlight, or content summary references the relevant asset and source range or a user instruction.
- [ ] **AC-2:** Unsupported claims about location, people, dialogue, or events are omitted or labeled uncertain.
- [ ] **AC-3:** Media analysis is retrieved in bounded chunks rather than sending every original video into every model request.
- [ ] **AC-4:** Candidate scores describe editorial estimates, not guaranteed correctness, engagement, or virality.

## Dependencies

[AVE-REQ-058](AVE-REQ-058.md); [AVE-REQ-065](AVE-REQ-065.md)

## Verification plan

[AT-14](../ACCEPTANCE_TESTS.md#at-14); [AT-19](../ACCEPTANCE_TESTS.md#at-19); [AT-25](../ACCEPTANCE_TESTS.md#at-25). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U07](../../intake/USER_BRIEF.md#u07); [U12](../../intake/USER_BRIEF.md#u12); [U13](../../intake/USER_BRIEF.md#u13); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-009](../EPICS_AND_FEATURES.md#ave-feat-009).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
