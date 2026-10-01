---
id: AVE-REQ-054
title: "AI budgets, retries, caching, and cancellation"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-011
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U24", "U26", "D02"]
dependencies: ["AVE-REQ-044", "AVE-REQ-050", "AVE-REQ-077"]
scenarios: ["AT-17", "AT-24"]
---

# AVE-REQ-054 - AI budgets, retries, caching, and cancellation

## Requirement

AI and media-analysis workflows shall have configurable budgets, bounded retries, caching, cancellation, and persistent stage state.

## Acceptance criteria

- [ ] **AC-1:** Users can bound duration, model calls, token or cost limits when available, and local concurrency; unknown costs remain labeled unknown.
- [ ] **AC-2:** Cache analysis by source checksum, model revision, prompt/schema version, language, and relevant settings; invalidate stale entries.
- [ ] **AC-3:** Retry transient failures with limits and backoff, but do not blindly repeat a mutating operation or an authorization failure.
- [ ] **AC-4:** Cancellation stops queued work and terminates or safely detaches active processing, preserving already accepted project edits.

## Dependencies

[AVE-REQ-044](AVE-REQ-044.md); [AVE-REQ-050](AVE-REQ-050.md); [AVE-REQ-077](AVE-REQ-077.md)

## Verification plan

[AT-17](../ACCEPTANCE_TESTS.md#at-17); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [U26](../../intake/USER_BRIEF.md#u26); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-011](../EPICS_AND_FEATURES.md#ave-feat-011).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
