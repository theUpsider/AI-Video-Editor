---
id: AVE-REQ-020
title: "Two-perspective split-screen layout"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-003
epic: AVE-EPIC-02
primary_gate: M1
origins: ["U02", "U15", "U16"]
dependencies: ["AVE-REQ-019"]
scenarios: ["AT-02", "AT-04"]
---

# AVE-REQ-020 - Two-perspective split-screen layout

## Requirement

The editor shall provide a reusable left/right split-screen layout for synchronized sources of arbitrary aspect ratios.

## Acceptance criteria

- [ ] **AC-1:** For a 1920x1080 canvas and two square sources in contain mode, each image is 960x960 with 60 pixels of vertical background above and below; sources remain undistorted.
- [ ] **AC-2:** Cover mode fills each 960x1080 region by cropping; the user can inspect and adjust the crop rather than accepting hidden loss of content.
- [ ] **AC-3:** Users can swap perspectives, resize the divider, configure a gap or background, and save a layout preset.
- [ ] **AC-4:** The layout binds clip instances and synchronization-group membership without changing the selected final audio source.

## Dependencies

[AVE-REQ-019](AVE-REQ-019.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-04](../ACCEPTANCE_TESTS.md#at-04). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U15](../../intake/USER_BRIEF.md#u15); [U16](../../intake/USER_BRIEF.md#u16). Parent: [AVE-FEAT-003](../EPICS_AND_FEATURES.md#ave-feat-003).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
