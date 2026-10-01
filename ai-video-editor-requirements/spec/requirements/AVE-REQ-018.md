---
id: AVE-REQ-018
title: "Configurable canvas, dimensions, and output rate"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-003
epic: AVE-EPIC-02
primary_gate: M1
origins: ["U02", "U03"]
dependencies: ["AVE-REQ-001", "AVE-REQ-004", "AVE-REQ-012"]
scenarios: ["AT-02", "AT-03", "AT-18"]
---

# AVE-REQ-018 - Configurable canvas, dimensions, and output rate

## Requirement

Projects and export presets shall define output aspect ratio, exact pixel dimensions, and frame rate independently of individual inputs.

## Acceptance criteria

- [ ] **AC-1:** The initial canvas defaults to 16:9 and 1920x1080; 1:1, 9:16, and validated custom dimensions are selectable.
- [ ] **AC-2:** An Auto frame-rate setting resolves from the selected reference or dominant source on first draft; 60/1 input remains 60/1 and 60000/1001 remains distinct.
- [ ] **AC-3:** If no source exists, display a provisional 30 fps default; once resolved, do not silently change project timing after another import.
- [ ] **AC-4:** Validate encoder constraints such as even dimensions and explain any requested adjustment rather than silently stretching media.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md); [AVE-REQ-004](AVE-REQ-004.md); [AVE-REQ-012](AVE-REQ-012.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-03](../ACCEPTANCE_TESTS.md#at-03); [AT-18](../ACCEPTANCE_TESTS.md#at-18). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U03](../../intake/USER_BRIEF.md#u03). Parent: [AVE-FEAT-003](../EPICS_AND_FEATURES.md#ave-feat-003).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
