---
id: AVE-REQ-001
title: "Persistent projects and project settings"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M1
origins: ["U01", "U24", "D01"]
dependencies: []
scenarios: ["AT-01", "AT-22"]
---

# AVE-REQ-001 - Persistent projects and project settings

## Requirement

The application shall create, name, reopen, duplicate, and persist editing projects, including their media references, timeline, output settings, and revisions.

## Acceptance criteria

- [ ] **AC-1:** A new project opens an empty collection and timeline without requiring an AI account.
- [ ] **AC-2:** After saving and restarting the application, timeline content, output settings, selected profiles, and project metadata are unchanged.
- [ ] **AC-3:** Project duplication produces an independent edit history while safely reusing immutable source media.
- [ ] **AC-4:** Project deletion clearly distinguishes deleting editing data from deleting original media; originals are not deleted by default.

## Dependencies

No requirement dependencies.

## Verification plan

[AT-01](../ACCEPTANCE_TESTS.md#at-01); [AT-22](../ACCEPTANCE_TESTS.md#at-22). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U01](../../intake/USER_BRIEF.md#u01); [U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
