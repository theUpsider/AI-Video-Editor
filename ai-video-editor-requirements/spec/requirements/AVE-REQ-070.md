---
id: AVE-REQ-070
title: "Short preview and batch delivery"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-015
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U12", "U23"]
dependencies: ["AVE-REQ-069", "AVE-REQ-072", "AVE-REQ-063"]
scenarios: ["AT-19", "AT-18", "AT-17"]
---

# AVE-REQ-070 - Short preview and batch delivery

## Requirement

Users shall preview, adjust, and export selected short sequences with associated subtitles and publication metadata.

## Acceptance criteria

- [ ] **AC-1:** Validate actual output duration, ratio, resolution, and audio after rendering; do not merely trust preset labels.
- [ ] **AC-2:** Provide per-short naming, thumbnail/reference frame, caption choices, and export job status.
- [ ] **AC-3:** Batch export isolates failures and uses bounded worker concurrency.
- [ ] **AC-4:** Platform presets are editable recommendations, dated when tied to external guidance, and not guarantees of platform acceptance.

## Dependencies

[AVE-REQ-069](AVE-REQ-069.md); [AVE-REQ-072](AVE-REQ-072.md); [AVE-REQ-063](AVE-REQ-063.md)

## Verification plan

[AT-19](../ACCEPTANCE_TESTS.md#at-19); [AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-17](../ACCEPTANCE_TESTS.md#at-17). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U12](../../intake/USER_BRIEF.md#u12); [U23](../../intake/USER_BRIEF.md#u23). Parent: [AVE-FEAT-015](../EPICS_AND_FEATURES.md#ave-feat-015).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
