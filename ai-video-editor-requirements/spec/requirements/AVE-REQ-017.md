---
id: AVE-REQ-017
title: "Usable synchronized preview"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-002
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U20"]
dependencies: ["AVE-REQ-007", "AVE-REQ-011", "AVE-REQ-012"]
scenarios: ["AT-02", "AT-11", "AT-27"]
---

# AVE-REQ-017 - Usable synchronized preview

## Requirement

The editor shall provide a preview canvas with play/pause, scrubbing, frame stepping, timeline selection, audio playback, and visible render status.

## Acceptance criteria

- [ ] **AC-1:** Preview presents all visible layers and the selected final audio routing, not one independent audio player per camera.
- [ ] **AC-2:** Proxy-backed playback and quality changes do not modify project frame rate, timing, or export quality.
- [ ] **AC-3:** The current playhead, clip selection, trim handles, waveforms, and overlay selection remain coordinated.
- [ ] **AC-4:** Scrubbing or frame inspection uses bounded work and displays pending reference frames rather than blocking the entire interface.

## Dependencies

[AVE-REQ-007](AVE-REQ-007.md); [AVE-REQ-011](AVE-REQ-011.md); [AVE-REQ-012](AVE-REQ-012.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-11](../ACCEPTANCE_TESTS.md#at-11); [AT-27](../ACCEPTANCE_TESTS.md#at-27). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-002](../EPICS_AND_FEATURES.md#ave-feat-002).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
