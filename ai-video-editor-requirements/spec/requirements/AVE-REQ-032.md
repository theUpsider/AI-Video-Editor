---
id: AVE-REQ-032
title: "Independent audio tracks and basic mixing"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-005
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U02"]
dependencies: ["AVE-REQ-031"]
scenarios: ["AT-28", "AT-04"]
---

# AVE-REQ-032 - Independent audio tracks and basic mixing

## Requirement

The timeline shall support independent audio clips and basic mixing controls for source audio, voice, music, and other imported audio.

## Acceptance criteria

- [ ] **AC-1:** Users can add audio-only assets, trim and move them, adjust gain, mute or solo, and apply fades or crossfades.
- [ ] **AC-2:** Provide level metering and clipping warnings; optional loudness normalization remains an explicit, reversible choice.
- [ ] **AC-3:** Audio sample-rate conversion and encoder delay handling do not introduce a growing video/audio offset.
- [ ] **AC-4:** Unselected camera audio is not accidentally doubled into the mix.

## Dependencies

[AVE-REQ-031](AVE-REQ-031.md)

## Verification plan

[AT-28](../ACCEPTANCE_TESTS.md#at-28); [AT-04](../ACCEPTANCE_TESTS.md#at-04). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02). Parent: [AVE-FEAT-005](../EPICS_AND_FEATURES.md#ave-feat-005).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
