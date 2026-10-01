---
id: AVE-REQ-099
title: "Honest completion and conditional verification"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M7
origins: ["U27", "D03"]
dependencies: ["AVE-REQ-097"]
scenarios: ["AT-29", "AT-30"]
---

# AVE-REQ-099 - Honest completion and conditional verification

## Requirement

Requirements shall be marked complete only with applicable acceptance evidence; missing external resources shall remain visible verification gaps.

## Acceptance criteria

- [ ] **AC-1:** Distinguish planned, in progress, implemented, verified, blocked, and deferred states in the working project tracker.
- [ ] **AC-2:** A real credentialed provider smoke test is required to claim that provider path verified; an actual device encode is required to claim a hardware path verified.
- [ ] **AC-3:** Absence of optional hardware can yield a documented conditional capability, not a claim that it was tested or a silent scope reduction.
- [ ] **AC-4:** Release reporting enumerates all remaining unverified criteria and never describes a mock interface or partial milestone as the whole requested product.

## Dependencies

[AVE-REQ-097](AVE-REQ-097.md)

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
