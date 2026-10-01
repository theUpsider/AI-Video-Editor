---
id: AVE-REQ-064
title: "Caption formatting and manual cue editor"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U10", "U20"]
dependencies: ["AVE-REQ-034", "AVE-REQ-058"]
scenarios: ["AT-13", "AT-10"]
---

# AVE-REQ-064 - Caption formatting and manual cue editor

## Requirement

Provide editable caption text, cue timings, line breaks, style, and readability checks suitable for different canvas ratios and languages.

## Acceptance criteria

- [ ] **AC-1:** Users can correct text, split or merge cues, and adjust timings without regenerating the whole transcript.
- [ ] **AC-2:** Check safe-area overflow, excessive lines, and configurable reading-speed concerns without discarding speech automatically.
- [ ] **AC-3:** Title and primary/secondary caption regions can be adjusted to avoid collisions.
- [ ] **AC-4:** Caption styles remain consistent in authoritative preview and optional burn-in export.

## Dependencies

[AVE-REQ-034](AVE-REQ-034.md); [AVE-REQ-058](AVE-REQ-058.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-10](../ACCEPTANCE_TESTS.md#at-10). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U10](../../intake/USER_BRIEF.md#u10); [U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
