---
id: AVE-REQ-042
title: "Input color interpretation and SDR normalization"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-008
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U21", "U23", "D03"]
dependencies: ["AVE-REQ-004", "AVE-REQ-040"]
scenarios: ["AT-26", "AT-10"]
---

# AVE-REQ-042 - Input color interpretation and SDR normalization

## Requirement

The system shall distinguish technical input color transforms from creative looks and provide a validated SDR output path.

## Acceptance criteria

- [ ] **AC-1:** Inspect color primaries, transfer, matrix, range, and available bit-depth metadata, and allow user correction when tags are absent or wrong.
- [ ] **AC-2:** Do not assume a DJI recording is log or apply a camera-specific LUT without confirmed profile information.
- [ ] **AC-3:** Default output uses a documented SDR Rec.709 path; recognized HDR inputs require supported tone mapping or an explicit unsupported warning.
- [ ] **AC-4:** Unknown log/HDR material is not silently labeled color-accurate; optional LUT import validates format and records provenance.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md); [AVE-REQ-040](AVE-REQ-040.md)

## Verification plan

[AT-26](../ACCEPTANCE_TESTS.md#at-26); [AT-10](../ACCEPTANCE_TESTS.md#at-10). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U21](../../intake/USER_BRIEF.md#u21); [U23](../../intake/USER_BRIEF.md#u23); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-008](../EPICS_AND_FEATURES.md#ave-feat-008).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
