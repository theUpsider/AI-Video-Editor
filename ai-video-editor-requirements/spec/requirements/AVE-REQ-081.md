---
id: AVE-REQ-081
title: "Complete output delivery bundle"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U11", "U13", "U18", "U23"]
dependencies: ["AVE-REQ-039", "AVE-REQ-063", "AVE-REQ-071", "AVE-REQ-072"]
scenarios: ["AT-18", "AT-25", "AT-20"]
---

# AVE-REQ-081 - Complete output delivery bundle

## Requirement

Deliver a coherent output bundle containing the rendered video and the selected supporting artifacts.

## Acceptance criteria

- [ ] **AC-1:** Bundle selected per-language captions, chapter list, editable publication metadata, and a render manifest with source/project revision and output settings.
- [ ] **AC-2:** Artifacts use consistent names and match the same exported time range.
- [ ] **AC-3:** No credentials, private filesystem paths, or unintended GPS data leak into publication bundles.
- [ ] **AC-4:** Users can download an individual artifact or the complete bundle.

## Dependencies

[AVE-REQ-039](AVE-REQ-039.md); [AVE-REQ-063](AVE-REQ-063.md); [AVE-REQ-071](AVE-REQ-071.md); [AVE-REQ-072](AVE-REQ-072.md)

## Verification plan

[AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-25](../ACCEPTANCE_TESTS.md#at-25); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U11](../../intake/USER_BRIEF.md#u11); [U13](../../intake/USER_BRIEF.md#u13); [U18](../../intake/USER_BRIEF.md#u18); [U23](../../intake/USER_BRIEF.md#u23). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
