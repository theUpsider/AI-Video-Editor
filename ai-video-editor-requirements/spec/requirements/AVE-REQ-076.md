---
id: AVE-REQ-076
title: "Capability-tested hardware acceleration"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U22"]
dependencies: ["AVE-REQ-075"]
scenarios: ["AT-18", "AT-23", "AT-24"]
---

# AVE-REQ-076 - Capability-tested hardware acceleration

## Requirement

Detect and use available hardware acceleration for supported processing stages, with explicit CPU fallback and truthful capability reporting.

## Acceptance criteria

- [ ] **AC-1:** Probe compiled encoders, device access, and a short real encode before declaring a GPU path usable; an encoder name alone is insufficient.
- [ ] **AC-2:** Provide an NVIDIA NVENC acceleration profile when available on the reference Linux deployment; other hardware backends may be added through the same capability layer.
- [ ] **AC-3:** Report acceleration separately for decode, filters/composition, encode, and AI inference.
- [ ] **AC-4:** If acceleration fails, offer or perform the configured CPU retry without changing project content; report which path actually produced the output.
- [ ] **AC-5:** GPU integration tests are conditional on real hardware and reported as not run when unavailable, never as CPU-tested GPU success.

## Dependencies

[AVE-REQ-075](AVE-REQ-075.md)

## Verification plan

[AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-23](../ACCEPTANCE_TESTS.md#at-23); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U22](../../intake/USER_BRIEF.md#u22). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
