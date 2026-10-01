---
id: AVE-REQ-044
title: "Natural-language editing interface"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-009
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U24", "U25"]
dependencies: ["AVE-REQ-015", "AVE-REQ-048", "AVE-REQ-050"]
scenarios: ["AT-14", "AT-12", "AT-24"]
---

# AVE-REQ-044 - Natural-language editing interface

## Requirement

The editor shall offer a project-aware text interface for initial editing instructions and subsequent modifications.

## Acceptance criteria

- [ ] **AC-1:** Users can reference selected clips, named sections, visible timeline items, or a scoped time range in a prompt.
- [ ] **AC-2:** Show planning, analysis, proposal, application, and failure/cancel states rather than one indefinite spinner.
- [ ] **AC-3:** A request such as shorten the last section and move its title is converted to inspectable editing operations.
- [ ] **AC-4:** Provider errors or missing credentials do not masquerade as completed AI edits, and manual editing remains available.

## Dependencies

[AVE-REQ-015](AVE-REQ-015.md); [AVE-REQ-048](AVE-REQ-048.md); [AVE-REQ-050](AVE-REQ-050.md)

## Verification plan

[AT-14](../ACCEPTANCE_TESTS.md#at-14); [AT-12](../ACCEPTANCE_TESTS.md#at-12); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [U25](../../intake/USER_BRIEF.md#u25). Parent: [AVE-FEAT-009](../EPICS_AND_FEATURES.md#ave-feat-009).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
