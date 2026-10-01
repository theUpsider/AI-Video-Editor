---
id: AVE-REQ-041
title: "Reusable project, camera, and clip color profiles"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-008
epic: AVE-EPIC-04
primary_gate: M3
origins: ["U21"]
dependencies: ["AVE-REQ-040"]
scenarios: ["AT-10", "AT-22"]
---

# AVE-REQ-041 - Reusable project, camera, and clip color profiles

## Requirement

Users shall save reusable color profiles and apply them project-wide, by camera/perspective, or to individual clips.

## Acceptance criteria

- [ ] **AC-1:** A project profile affects all applicable current clips and newly imported clips according to an explicit inheritance rule.
- [ ] **AC-2:** Camera-level and clip-level overrides have visible precedence and never accidentally apply the same input transform twice.
- [ ] **AC-3:** Profiles can be named, duplicated, imported, exported, previewed, and reset without altering originals.
- [ ] **AC-4:** A linked preset update has a documented effect; users can detach or freeze an individual clip look.

## Dependencies

[AVE-REQ-040](AVE-REQ-040.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-22](../ACCEPTANCE_TESTS.md#at-22). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U21](../../intake/USER_BRIEF.md#u21). Parent: [AVE-FEAT-008](../EPICS_AND_FEATURES.md#ave-feat-008).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
