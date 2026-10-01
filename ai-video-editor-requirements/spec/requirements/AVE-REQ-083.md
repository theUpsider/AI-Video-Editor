---
id: AVE-REQ-083
title: "Real-media automated verification suite"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["D03", "U03", "U15"]
dependencies: ["AVE-REQ-072"]
scenarios: ["AT-29", "AT-04", "AT-03"]
---

# AVE-REQ-083 - Real-media automated verification suite

## Requirement

Implement layered automated verification with real generated media fixtures, independent expected outcomes, and traceability to acceptance criteria.

## Acceptance criteria

- [ ] **AC-1:** Include unit tests for time mappings, contract tests for editing tools, integration tests using the real renderer, and browser end-to-end journeys.
- [ ] **AC-2:** Generate small fixtures with known timestamps, event markers, audio impulses, aspect ratios, and rate/offset/drift variations.
- [ ] **AC-3:** At least one regression exercises approximately 2K input at 60 fps and validates actual output content and synchronization.
- [ ] **AC-4:** Mocks are limited to provider/network isolation and cannot alone satisfy media, AI quality, or hardware integration claims.

## Dependencies

[AVE-REQ-072](AVE-REQ-072.md)

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-03](../ACCEPTANCE_TESTS.md#at-03). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D03](../../intake/USER_BRIEF.md#d03); [U03](../../intake/USER_BRIEF.md#u03); [U15](../../intake/USER_BRIEF.md#u15). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
