---
id: AVE-REQ-097
title: "Verification gates that cannot pass as placeholders"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M0
origins: ["U27", "D03"]
dependencies: ["AVE-REQ-093"]
scenarios: ["AT-29", "AT-30"]
---

# AVE-REQ-097 - Verification gates that cannot pass as placeholders

## Requirement

Replace bootstrap-only verification with staged real checks and independently verifiable release gates as implementation begins.

## Acceptance criteria

- [ ] **AC-1:** Keep a fast feedback tier, real-media integration tier, and full release tier behind documented repository commands.
- [ ] **AC-2:** Tie verification evidence to a commit/tree fingerprint, configuration, requirement IDs, and test results; stale evidence cannot certify changed code.
- [ ] **AC-3:** Use supported hooks only after a small smoke test; avoid recursive Stop-hook loops and repeated full renders on every conversational response.
- [ ] **AC-4:** No-op scripts, skipped integration tests, caught exceptions returning success, or provider mocks cannot establish completed product requirements.

## Dependencies

[AVE-REQ-093](AVE-REQ-093.md)

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
