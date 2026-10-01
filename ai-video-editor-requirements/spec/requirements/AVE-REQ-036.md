---
id: AVE-REQ-036
title: "Readable international text and safe areas"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-006
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U04", "U05", "U10"]
dependencies: ["AVE-REQ-034"]
scenarios: ["AT-10", "AT-13", "AT-20"]
---

# AVE-REQ-036 - Readable international text and safe areas

## Requirement

Text overlays and captions shall support Unicode, configurable typography, readable contrast, and aspect-ratio-aware safe areas.

## Acceptance criteria

- [ ] **AC-1:** Validate Latin and CJK sample strings with appropriately licensed font fallback and no missing-glyph boxes in reference renders.
- [ ] **AC-2:** Changing between 16:9, 1:1, and 9:16 exposes overflow and permits independent layout adjustments.
- [ ] **AC-3:** Text is passed to rendering libraries safely; punctuation and control-like strings do not become commands or filter expressions.
- [ ] **AC-4:** Font and text-style choices are persisted and exported with appropriate dependency or font-license documentation.

## Dependencies

[AVE-REQ-034](AVE-REQ-034.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U04](../../intake/USER_BRIEF.md#u04); [U05](../../intake/USER_BRIEF.md#u05); [U10](../../intake/USER_BRIEF.md#u10). Parent: [AVE-FEAT-006](../EPICS_AND_FEATURES.md#ave-feat-006).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
