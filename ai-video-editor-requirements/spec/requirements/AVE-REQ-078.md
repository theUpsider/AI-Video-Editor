---
id: AVE-REQ-078
title: "Export preflight and decoded-output validation"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M7
origins: ["U23", "D03"]
dependencies: ["AVE-REQ-072", "AVE-REQ-077"]
scenarios: ["AT-18", "AT-04", "AT-10", "AT-17"]
---

# AVE-REQ-078 - Export preflight and decoded-output validation

## Requirement

Preflight exports and verify the produced files against the selected immutable revision and output contract.

## Acceptance criteria

- [ ] **AC-1:** Before rendering, validate source availability, intervals, capabilities, free disk space, audio routing, font availability, and relevant subtitle choices.
- [ ] **AC-2:** After rendering, probe dimensions, exact rate, streams, codecs, duration, color metadata, and decode representative or complete small-test outputs.
- [ ] **AC-3:** Check reference frames and audio for critical fixtures, detecting black outputs, missing overlays, doubled audio, or truncated endings.
- [ ] **AC-4:** Validation failure leaves the job failed with diagnostics and never presents an invalid file as a completed delivery.

## Dependencies

[AVE-REQ-072](AVE-REQ-072.md); [AVE-REQ-077](AVE-REQ-077.md)

## Verification plan

[AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-04](../ACCEPTANCE_TESTS.md#at-04); [AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-17](../ACCEPTANCE_TESTS.md#at-17). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U23](../../intake/USER_BRIEF.md#u23); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
