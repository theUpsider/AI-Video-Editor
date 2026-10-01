---
id: AVE-REQ-095
title: "Evidence-driven workflow self-improvement"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M7
origins: ["U27", "D05"]
dependencies: ["AVE-REQ-094"]
scenarios: ["AT-29", "AT-30"]
---

# AVE-REQ-095 - Evidence-driven workflow self-improvement

## Requirement

The coding workflow shall improve its repository-local procedures based on observed failures and measured outcomes, without weakening product or verification constraints.

## Acceptance criteria

- [ ] **AC-1:** Record repeated failure, proposed improvement, affected workflow, measurement, and rollback plan in a concise workflow log.
- [ ] **AC-2:** Apply small reviewed changes to skills, task decomposition, context retrieval, or test scheduling and verify them against fixed regression fixtures.
- [ ] **AC-3:** Do not loosen acceptance criteria, skip tests, raise tolerances, remove security gates, or rewrite expected results to make an implementation pass.
- [ ] **AC-4:** Keep improvements only when they show useful evidence; avoid permanent agent proliferation and recurring harness rewrites.

## Dependencies

[AVE-REQ-094](AVE-REQ-094.md)

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27); [D05](../../intake/USER_BRIEF.md#d05). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
