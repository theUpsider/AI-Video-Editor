---
id: AVE-REQ-019
title: "Aspect-preserving composition and transforms"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-003
epic: AVE-EPIC-02
primary_gate: M2
origins: ["U02"]
dependencies: ["AVE-REQ-011", "AVE-REQ-018"]
scenarios: ["AT-02", "AT-10"]
---

# AVE-REQ-019 - Aspect-preserving composition and transforms

## Requirement

Clip instances shall support position, scale, crop, rotation, opacity, z-order, and explicit contain or cover fitting inside layout regions.

## Acceptance criteria

- [ ] **AC-1:** Contain preserves the complete source image with an explicit background; cover fills the region with visible crop controls.
- [ ] **AC-2:** No default operation stretches a source to change its aspect ratio.
- [ ] **AC-3:** Users and AI can specify transforms in normalized canvas or region coordinates, with preview and export using the same semantics.
- [ ] **AC-4:** Per-clip focal position or crop can be set manually or as a static AI suggestion; this does not require object tracking.

## Dependencies

[AVE-REQ-011](AVE-REQ-011.md); [AVE-REQ-018](AVE-REQ-018.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-10](../ACCEPTANCE_TESTS.md#at-10). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02). Parent: [AVE-FEAT-003](../EPICS_AND_FEATURES.md#ave-feat-003).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
