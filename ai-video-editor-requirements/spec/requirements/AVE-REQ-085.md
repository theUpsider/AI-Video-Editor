---
id: AVE-REQ-085
title: "Observable jobs and reproducible diagnostics"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["D02"]
dependencies: ["AVE-REQ-077"]
scenarios: ["AT-17", "AT-18", "AT-20"]
---

# AVE-REQ-085 - Observable jobs and reproducible diagnostics

## Requirement

Provide structured diagnostics that identify the state and provenance of media and AI processing without exposing secrets.

## Acceptance criteria

- [ ] **AC-1:** Record job ID, project revision, relevant asset IDs, engine/model versions, settings, actual device path, and redacted errors.
- [ ] **AC-2:** Users can inspect progress and export a redacted diagnostic report.
- [ ] **AC-3:** Log noisy media-process output in bounded files rather than filling the UI or agent context.
- [ ] **AC-4:** An exported manifest identifies enough configuration to reproduce a rendering decision on compatible software.

## Dependencies

[AVE-REQ-077](AVE-REQ-077.md)

## Verification plan

[AT-17](../ACCEPTANCE_TESTS.md#at-17); [AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
