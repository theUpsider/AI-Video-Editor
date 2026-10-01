---
id: AVE-REQ-015
title: "Undo, redo, autosave, and revisions"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U20", "U24", "D01"]
dependencies: ["AVE-REQ-001", "AVE-REQ-011"]
scenarios: ["AT-12", "AT-22", "AT-17"]
---

# AVE-REQ-015 - Undo, redo, autosave, and revisions

## Requirement

All user and AI editing mutations shall be versioned, undoable, and recoverable after interruption.

## Acceptance criteria

- [ ] **AC-1:** A multi-operation AI edit can be undone as one transaction and redone without changing unrelated edits.
- [ ] **AC-2:** Autosave does not mark an edit durable until its atomic persistence succeeds; restart recovers the last durable revision.
- [ ] **AC-3:** History records actor, timestamp, affected objects, previous revision, and a human-readable change summary.
- [ ] **AC-4:** An export is pinned to one immutable revision even while the user continues editing.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md); [AVE-REQ-011](AVE-REQ-011.md)

## Verification plan

[AT-12](../ACCEPTANCE_TESTS.md#at-12); [AT-22](../ACCEPTANCE_TESTS.md#at-22); [AT-17](../ACCEPTANCE_TESTS.md#at-17). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20); [U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
