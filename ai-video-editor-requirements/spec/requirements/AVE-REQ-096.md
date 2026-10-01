---
id: AVE-REQ-096
title: "Isolated bounded tasks and independent review"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M0
origins: ["U27", "D05"]
dependencies: ["AVE-REQ-094"]
scenarios: ["AT-29", "AT-30"]
---

# AVE-REQ-096 - Isolated bounded tasks and independent review

## Requirement

Delegate bounded tasks with explicit context and deliverables, using verified worktree isolation for concurrent writers and a fresh review context for acceptance.

## Acceptance criteria

- [ ] **AC-1:** Task briefs include requirement IDs, acceptance criteria, allowed paths, dependencies, input revision, test commands, and handback schema.
- [ ] **AC-2:** Initialize isolated tasks from the intended integration commit; do not assume the native worktree default matches the current branch.
- [ ] **AC-3:** A reviewer receives requirements and the diff rather than relying on the implementer claim of success; media-critical tests inspect real rendered outputs.
- [ ] **AC-4:** Respect actual concurrency and resource limits; never recursively multiply coding agents or bypass a cloud limit.

## Dependencies

[AVE-REQ-094](AVE-REQ-094.md)

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27); [D05](../../intake/USER_BRIEF.md#d05). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
