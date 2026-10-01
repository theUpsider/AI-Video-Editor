---
id: AVE-REQ-062
title: "Subtitle retiming through edits and synchronization"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U10", "U15", "U20", "D03"]
dependencies: ["AVE-REQ-012", "AVE-REQ-026", "AVE-REQ-058"]
scenarios: ["AT-13", "AT-08", "AT-09"]
---

# AVE-REQ-062 - Subtitle retiming through edits and synchronization

## Requirement

Subtitle cues shall be derived from source-aligned text through the same time mappings used by video and audio.

## Acceptance criteria

- [ ] **AC-1:** Trims, cuts, repeated source uses, synchronization offsets, drift correction, and section/short exports produce correct output cue timing.
- [ ] **AC-2:** Cues are split or clipped at removed regions rather than spanning unrelated footage.
- [ ] **AC-3:** No exported cue has negative duration, invalid ordering, or times beyond the selected output interval.
- [ ] **AC-4:** Editing a timeline does not corrupt the original source transcript timestamps.

## Dependencies

[AVE-REQ-012](AVE-REQ-012.md); [AVE-REQ-026](AVE-REQ-026.md); [AVE-REQ-058](AVE-REQ-058.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-08](../ACCEPTANCE_TESTS.md#at-08); [AT-09](../ACCEPTANCE_TESTS.md#at-09). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U10](../../intake/USER_BRIEF.md#u10); [U15](../../intake/USER_BRIEF.md#u15); [U20](../../intake/USER_BRIEF.md#u20); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
