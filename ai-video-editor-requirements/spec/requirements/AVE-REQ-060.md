---
id: AVE-REQ-060
title: "Translated subtitle language tracks"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U10"]
dependencies: ["AVE-REQ-058", "AVE-REQ-059", "AVE-REQ-050"]
scenarios: ["AT-13", "AT-24"]
---

# AVE-REQ-060 - Translated subtitle language tracks

## Requirement

The system shall generate editable translated subtitle tracks in user-selected target languages while preserving timing and original text.

## Acceptance criteria

- [ ] **AC-1:** Translation is a distinct capability from speech recognition and may use the configured text provider or an explicitly installed translation model.
- [ ] **AC-2:** Preserve names and proper nouns where appropriate, keep source links, and mark translations as machine-generated until reviewed.
- [ ] **AC-3:** Changing a source cue marks affected translations stale without deleting user corrections silently.
- [ ] **AC-4:** When translation is unavailable, original-language captions still work and the missing capability is explained.

## Dependencies

[AVE-REQ-058](AVE-REQ-058.md); [AVE-REQ-059](AVE-REQ-059.md); [AVE-REQ-050](AVE-REQ-050.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U10](../../intake/USER_BRIEF.md#u10). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
