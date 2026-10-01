---
id: AVE-REQ-093
title: "Adopt and preserve the supplied requirements baseline"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M0
origins: ["U27", "D05"]
dependencies: []
scenarios: ["AT-29", "AT-30"]
---

# AVE-REQ-093 - Adopt and preserve the supplied requirements baseline

## Requirement

The implementing agent shall integrate this specification into the existing bootstrapped repository without re-running or replacing the bootstrap.

## Acceptance criteria

- [ ] **AC-1:** Preserve this input package as an immutable baseline and map every AVE-REQ ID to its canonical working requirement file.
- [ ] **AC-2:** Populate the existing PRODUCT, ARCHITECTURE, ROADMAP, PROGRESS, ASSUMPTIONS, and TRACEABILITY documents without losing meaningful existing content.
- [ ] **AC-3:** Explicit user requirements and exclusions cannot be demoted or rewritten merely to fit an easier implementation.
- [ ] **AC-4:** Requirement implementation status starts unverified; package validation is not product verification.

## Dependencies

No requirement dependencies.

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27); [D05](../../intake/USER_BRIEF.md#d05). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
