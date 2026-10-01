---
id: AVE-REQ-004
title: "Media probing, exact dimensions, and source timing"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M1
origins: ["U02", "U03", "U23"]
dependencies: ["AVE-REQ-002"]
scenarios: ["AT-01", "AT-03", "AT-26"]
---

# AVE-REQ-004 - Media probing, exact dimensions, and source timing

## Requirement

Ingestion shall probe actual video and audio stream properties rather than infer resolution, frame rate, or camera capabilities from names.

## Acceptance criteria

- [ ] **AC-1:** Persist actual width and height, sample/display aspect ratio, rotation, duration, time base, frame-rate metadata, codec, pixel format, color tags, and audio stream properties when available.
- [ ] **AC-2:** Distinguish 60/1 from 60000/1001 and inspect presentation timestamps when constant versus variable frame rate is uncertain.
- [ ] **AC-3:** Accept a real or synthetic approximately 2K, 60 fps input; display its exact pixel dimensions instead of treating the label 2K as a specification.
- [ ] **AC-4:** Handle multiple audio streams, no audio, portrait rotation metadata, and missing optional tags without inventing values.

## Dependencies

[AVE-REQ-002](AVE-REQ-002.md)

## Verification plan

[AT-01](../ACCEPTANCE_TESTS.md#at-01); [AT-03](../ACCEPTANCE_TESTS.md#at-03); [AT-26](../ACCEPTANCE_TESTS.md#at-26). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U03](../../intake/USER_BRIEF.md#u03); [U23](../../intake/USER_BRIEF.md#u23). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
