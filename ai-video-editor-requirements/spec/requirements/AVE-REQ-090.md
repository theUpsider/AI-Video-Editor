---
id: AVE-REQ-090
title: "Crash recovery and safe migrations"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["D01"]
dependencies: ["AVE-REQ-001", "AVE-REQ-015", "AVE-REQ-077"]
scenarios: ["AT-22", "AT-17"]
---

# AVE-REQ-090 - Crash recovery and safe migrations

## Requirement

Project persistence and schema migrations shall recover safely from crashes and preserve existing user edits.

## Acceptance criteria

- [ ] **AC-1:** Transactions interrupted before commit leave the previous revision intact; interrupted jobs can be inspected and retried.
- [ ] **AC-2:** Back up or otherwise safely checkpoint project data before destructive schema migration.
- [ ] **AC-3:** Version checks reject unsupported states instead of guessing at missing fields.
- [ ] **AC-4:** Recovery tests restart the application during autosave, analysis, and export and verify originals and accepted edits remain intact.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md); [AVE-REQ-015](AVE-REQ-015.md); [AVE-REQ-077](AVE-REQ-077.md)

## Verification plan

[AT-22](../ACCEPTANCE_TESTS.md#at-22); [AT-17](../ACCEPTANCE_TESTS.md#at-17). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
