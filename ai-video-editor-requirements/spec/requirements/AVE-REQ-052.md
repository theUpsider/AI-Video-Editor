---
id: AVE-REQ-052
title: "Codex runtime adapter"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-011
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U25"]
dependencies: ["AVE-REQ-049", "AVE-REQ-050", "AVE-REQ-056"]
scenarios: ["AT-24", "AT-20"]
---

# AVE-REQ-052 - Codex runtime adapter

## Requirement

Provide a first-class optional server-side Codex integration using the current supported SDK or app-server interface and the same constrained editing tools.

## Acceptance criteria

- [ ] **AC-1:** The adapter starts or resumes an editing request, reports streamed progress and cancellation, and returns validated proposals.
- [ ] **AC-2:** It does not assume Codex is a raw language model or implement against a removed CLI command.
- [ ] **AC-3:** Authentication, process isolation, and writable workspace are explicitly configured and do not expose original media or unrelated files to general coding tools.
- [ ] **AC-4:** Contract fixtures and a documented credentialed live smoke test distinguish adapter implementation from externally verified operation.

## Dependencies

[AVE-REQ-049](AVE-REQ-049.md); [AVE-REQ-050](AVE-REQ-050.md); [AVE-REQ-056](AVE-REQ-056.md)

## Verification plan

[AT-24](../ACCEPTANCE_TESTS.md#at-24); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U25](../../intake/USER_BRIEF.md#u25). Parent: [AVE-FEAT-011](../EPICS_AND_FEATURES.md#ave-feat-011).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
