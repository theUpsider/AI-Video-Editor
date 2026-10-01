---
id: AVE-REQ-011
title: "Non-destructive multitrack timeline"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U02", "U20"]
dependencies: ["AVE-REQ-001", "AVE-REQ-003"]
scenarios: ["AT-02", "AT-11"]
---

# AVE-REQ-011 - Non-destructive multitrack timeline

## Requirement

The editor shall provide multiple simultaneous video, audio, image, and text tracks with non-destructive clip instances.

## Acceptance criteria

- [ ] **AC-1:** A project can contain at least four simultaneous video tracks, four audio tracks, and independent overlay tracks; this is a baseline test, not an artificial product limit.
- [ ] **AC-2:** Each clip instance has independent source in/out, timeline position, track, transform, and relevant audio or effect settings.
- [ ] **AC-3:** Layer order, track visibility, mute, solo, and lock have defined, consistent effects in preview and export.
- [ ] **AC-4:** Using the same asset twice creates independent clip instances rather than altering the source or the other instance.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md); [AVE-REQ-003](AVE-REQ-003.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-11](../ACCEPTANCE_TESTS.md#at-11). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
