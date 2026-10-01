---
id: AVE-REQ-069
title: "Independent short sequences and reframing"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-015
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U12", "U02"]
dependencies: ["AVE-REQ-068", "AVE-REQ-019", "AVE-REQ-015"]
scenarios: ["AT-19", "AT-13", "AT-02"]
---

# AVE-REQ-069 - Independent short sequences and reframing

## Requirement

Shorts shall be derived editable sequences that reuse originals without destructively changing the main edit.

## Acceptance criteria

- [ ] **AC-1:** Default short canvas is 1:1 as requested; 9:16, 16:9, and custom ratios remain selectable.
- [ ] **AC-2:** Derived shorts preserve intended sync, audio routing, grades, overlays, and subtitle time mappings.
- [ ] **AC-3:** Provide static split, stacked, full-width, or cropped composition options suitable for the chosen output; no tracking is required.
- [ ] **AC-4:** Editing a short does not mutate the parent sequence unless the user explicitly applies a supported shared change.

## Dependencies

[AVE-REQ-068](AVE-REQ-068.md); [AVE-REQ-019](AVE-REQ-019.md); [AVE-REQ-015](AVE-REQ-015.md)

## Verification plan

[AT-19](../ACCEPTANCE_TESTS.md#at-19); [AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-02](../ACCEPTANCE_TESTS.md#at-02). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U12](../../intake/USER_BRIEF.md#u12); [U02](../../intake/USER_BRIEF.md#u02). Parent: [AVE-FEAT-015](../EPICS_AND_FEATURES.md#ave-feat-015).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
