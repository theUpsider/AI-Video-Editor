---
id: AVE-REQ-079
title: "Editable output presets and quality guidance"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U02", "U12", "U23"]
dependencies: ["AVE-REQ-018", "AVE-REQ-072", "AVE-REQ-073"]
scenarios: ["AT-18", "AT-19"]
---

# AVE-REQ-079 - Editable output presets and quality guidance

## Requirement

Offer sensible editable export presets, with visible tradeoffs between dimensions, rate, quality, bitrate, speed, and estimated file size.

## Acceptance criteria

- [ ] **AC-1:** Provide landscape 16:9, square 1:1, and portrait 9:16 starting profiles using the selected content and platform-independent defaults.
- [ ] **AC-2:** Preserve the user-selected output ratio and rate when recommending bitrate or encoder choices.
- [ ] **AC-3:** Label size and time estimates as estimates, and warn about avoidable upscaling or unsupported combinations.
- [ ] **AC-4:** Encoder-specific controls are mapped explicitly; do not assume software CRF and hardware quality numbers have identical meaning.

## Dependencies

[AVE-REQ-018](AVE-REQ-018.md); [AVE-REQ-072](AVE-REQ-072.md); [AVE-REQ-073](AVE-REQ-073.md)

## Verification plan

[AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-19](../ACCEPTANCE_TESTS.md#at-19). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U12](../../intake/USER_BRIEF.md#u12); [U23](../../intake/USER_BRIEF.md#u23). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
