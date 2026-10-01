---
id: AVE-REQ-034
title: "Timed text and image overlays"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-006
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U04"]
dependencies: ["AVE-REQ-011", "AVE-REQ-019", "AVE-REQ-048"]
scenarios: ["AT-10", "AT-16"]
---

# AVE-REQ-034 - Timed text and image overlays

## Requirement

Users and AI shall add, edit, remove, and time text and image overlays through the same project editing model.

## Acceptance criteria

- [ ] **AC-1:** Each overlay has explicit start and end, position, size, z-order, opacity, and applicable style settings.
- [ ] **AC-2:** A fixture overlay from 3 to 6 seconds appears at 3 seconds and disappears at 6 seconds under half-open interval semantics.
- [ ] **AC-3:** Image transparency, scaling, and text wrapping are represented in both preview and export.
- [ ] **AC-4:** Overlay edits are undoable and invalid timing or unknown image assets are rejected.

## Dependencies

[AVE-REQ-011](AVE-REQ-011.md); [AVE-REQ-019](AVE-REQ-019.md); [AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-16](../ACCEPTANCE_TESTS.md#at-16). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U04](../../intake/USER_BRIEF.md#u04). Parent: [AVE-FEAT-006](../EPICS_AND_FEATURES.md#ave-feat-006).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
