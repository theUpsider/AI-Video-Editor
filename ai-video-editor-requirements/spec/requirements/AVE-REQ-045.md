---
id: AVE-REQ-045
title: "End-to-end AI first draft"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-009
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U24", "U01", "U15", "U05"]
dependencies: ["AVE-REQ-006", "AVE-REQ-008", "AVE-REQ-023", "AVE-REQ-035", "AVE-REQ-038", "AVE-REQ-047", "AVE-REQ-057", "AVE-REQ-065"]
scenarios: ["AT-14", "AT-02", "AT-09"]
---

# AVE-REQ-045 - End-to-end AI first draft

## Requirement

From a populated collection and a high-level brief, the AI shall produce a playable first-draft timeline, not merely editing advice.

## Acceptance criteria

- [ ] **AC-1:** The workflow examines available metadata and analysis, proposes camera groups and synchronization, organizes sections, and selects coherent source intervals.
- [ ] **AC-2:** It assembles split-screen and full-width segments, routes reference audio, applies the chosen look, and adds bounded titles and requested captions.
- [ ] **AC-3:** It reports uncertain alignment, exclusions, missing metadata, and assumptions without presenting them as verified facts.
- [ ] **AC-4:** An initial empty-project draft may apply automatically as a reversible transaction; replacing an existing edit requires a diff or explicit scoped authorization.

## Dependencies

[AVE-REQ-006](AVE-REQ-006.md); [AVE-REQ-008](AVE-REQ-008.md); [AVE-REQ-023](AVE-REQ-023.md); [AVE-REQ-035](AVE-REQ-035.md); [AVE-REQ-038](AVE-REQ-038.md); [AVE-REQ-047](AVE-REQ-047.md); [AVE-REQ-057](AVE-REQ-057.md); [AVE-REQ-065](AVE-REQ-065.md)

## Verification plan

[AT-14](../ACCEPTANCE_TESTS.md#at-14); [AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-09](../ACCEPTANCE_TESTS.md#at-09). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [U01](../../intake/USER_BRIEF.md#u01); [U15](../../intake/USER_BRIEF.md#u15); [U05](../../intake/USER_BRIEF.md#u05). Parent: [AVE-FEAT-009](../EPICS_AND_FEATURES.md#ave-feat-009).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
