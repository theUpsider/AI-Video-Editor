---
id: AVE-REQ-077
title: "Durable asynchronous jobs"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M1
origins: ["U22", "U24", "D02"]
dependencies: ["AVE-REQ-001"]
scenarios: ["AT-17", "AT-23"]
---

# AVE-REQ-077 - Durable asynchronous jobs

## Requirement

Import analysis, proxies, AI drafts, and exports shall run as durable jobs with observable state, bounded concurrency, cancellation, and safe retry.

## Acceptance criteria

- [ ] **AC-1:** Jobs have queued, running, succeeded, failed, and cancelled states, input revision, progress, timestamps, and structured failure details.
- [ ] **AC-2:** A process crash recovers queued work and marks interrupted work for safe restart; partially written outputs are not published.
- [ ] **AC-3:** Retrying a job with the same idempotency key does not duplicate an accepted project transaction or completed output.
- [ ] **AC-4:** Long jobs run outside HTTP request handlers and preserve a responsive application; resource limits prevent unbounded parallel encoders/models.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md)

## Verification plan

[AT-17](../ACCEPTANCE_TESTS.md#at-17); [AT-23](../ACCEPTANCE_TESTS.md#at-23). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U22](../../intake/USER_BRIEF.md#u22); [U24](../../intake/USER_BRIEF.md#u24); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
