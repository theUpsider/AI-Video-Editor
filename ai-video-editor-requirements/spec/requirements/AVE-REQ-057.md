---
id: AVE-REQ-057
title: "Speech extraction and local transcription"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U09", "U26"]
dependencies: ["AVE-REQ-004", "AVE-REQ-053"]
scenarios: ["AT-13", "AT-24", "AT-15"]
---

# AVE-REQ-057 - Speech extraction and local transcription

## Requirement

Extract speech-bearing audio for automatic transcription with source-aligned timestamps and a functional CPU-capable local model path.

## Acceptance criteria

- [ ] **AC-1:** Transcribe the selected audible source or explicit analysis source, retaining asset identity and source-time word or segment timestamps.
- [ ] **AC-2:** A multilingual small-model CPU profile is available; larger or GPU profiles are optional and resource-checked.
- [ ] **AC-3:** Silence and non-speech fixtures do not produce accepted invented dialogue; uncertain text is flagged and editable.
- [ ] **AC-4:** Transcription errors or unavailable models are visible and never replaced by fabricated transcript text.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md); [AVE-REQ-053](AVE-REQ-053.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-24](../ACCEPTANCE_TESTS.md#at-24); [AT-15](../ACCEPTANCE_TESTS.md#at-15). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U09](../../intake/USER_BRIEF.md#u09); [U26](../../intake/USER_BRIEF.md#u26). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
