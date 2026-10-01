---
id: AVE-REQ-061
title: "Toggleable single- and dual-language captions"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U10", "U11"]
dependencies: ["AVE-REQ-060", "AVE-REQ-064"]
scenarios: ["AT-13", "AT-10"]
---

# AVE-REQ-061 - Toggleable single- and dual-language captions

## Requirement

Users shall choose no captions, one language, or a primary plus secondary language in the editor without permanently burning them into source video.

## Acceptance criteria

- [ ] **AC-1:** Caption visibility and selected language tracks can be changed during preview.
- [ ] **AC-2:** Dual-language display keeps the two languages distinguishable and avoids overlapping text.
- [ ] **AC-3:** Export settings independently choose sidecars, supported embedded tracks, or intentional burn-in.
- [ ] **AC-4:** Turning editor captions off does not delete the stored subtitle tracks or prohibit exporting sidecars.

## Dependencies

[AVE-REQ-060](AVE-REQ-060.md); [AVE-REQ-064](AVE-REQ-064.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-10](../ACCEPTANCE_TESTS.md#at-10). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U10](../../intake/USER_BRIEF.md#u10); [U11](../../intake/USER_BRIEF.md#u11). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
