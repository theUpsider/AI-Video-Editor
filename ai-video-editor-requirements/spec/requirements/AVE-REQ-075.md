---
id: AVE-REQ-075
title: "CPU-only reference rendering"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M1
origins: ["U22"]
dependencies: ["AVE-REQ-072", "AVE-REQ-082"]
scenarios: ["AT-02", "AT-18", "AT-23"]
---

# AVE-REQ-075 - CPU-only reference rendering

## Requirement

All version-one editing and mandatory export operations shall have a functional CPU-only rendering path.

## Acceptance criteria

- [ ] **AC-1:** The application starts, imports, edits, and exports in the documented reference environment without a GPU.
- [ ] **AC-2:** The CPU renderer supports the same required composition semantics as accelerated profiles.
- [ ] **AC-3:** No visual analysis model or cloud provider is required merely to render an existing timeline.
- [ ] **AC-4:** Tests use real media and decoding of outputs; a mocked render job cannot satisfy this requirement.

## Dependencies

[AVE-REQ-072](AVE-REQ-072.md); [AVE-REQ-082](AVE-REQ-082.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-23](../ACCEPTANCE_TESTS.md#at-23). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U22](../../intake/USER_BRIEF.md#u22). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
