---
id: AVE-REQ-039
title: "Section and whole-project export"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-007
epic: AVE-EPIC-04
primary_gate: M6
origins: ["U18"]
dependencies: ["AVE-REQ-038", "AVE-REQ-072", "AVE-REQ-063"]
scenarios: ["AT-09", "AT-13", "AT-17"]
---

# AVE-REQ-039 - Section and whole-project export

## Requirement

Users shall export one section, selected sections, or the entire project through the same render pipeline.

## Acceptance criteria

- [ ] **AC-1:** Individual section exports start at output time zero and correctly rebase overlays, audio, and subtitle cues.
- [ ] **AC-2:** Whole-project export preserves chosen section order and can include supported chapter metadata and a text chapter list.
- [ ] **AC-3:** Transitions crossing a section boundary have an explicit clip, include-handle, or rerender policy shown before export.
- [ ] **AC-4:** Batch section export reports independent job status and does not corrupt successful outputs if another section fails.

## Dependencies

[AVE-REQ-038](AVE-REQ-038.md); [AVE-REQ-072](AVE-REQ-072.md); [AVE-REQ-063](AVE-REQ-063.md)

## Verification plan

[AT-09](../ACCEPTANCE_TESTS.md#at-09); [AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-17](../ACCEPTANCE_TESTS.md#at-17). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U18](../../intake/USER_BRIEF.md#u18). Parent: [AVE-FEAT-007](../EPICS_AND_FEATURES.md#ave-feat-007).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
