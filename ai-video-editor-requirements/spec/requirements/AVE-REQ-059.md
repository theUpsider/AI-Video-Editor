---
id: AVE-REQ-059
title: "Language detection and source-language control"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U09", "U10"]
dependencies: ["AVE-REQ-057"]
scenarios: ["AT-13", "AT-24"]
---

# AVE-REQ-059 - Language detection and source-language control

## Requirement

The transcription workflow shall support detected or user-selected source languages and preserve language metadata.

## Acceptance criteria

- [ ] **AC-1:** Users can override a wrong detected language per asset or transcript.
- [ ] **AC-2:** Original-language text is retained rather than silently replaced by a translation.
- [ ] **AC-3:** Mixed-language content is represented using the selected model capabilities and flagged where detection is uncertain.
- [ ] **AC-4:** The UI reports actual model-supported language capabilities rather than claiming every language is supported equally.

## Dependencies

[AVE-REQ-057](AVE-REQ-057.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U09](../../intake/USER_BRIEF.md#u09); [U10](../../intake/USER_BRIEF.md#u10). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
