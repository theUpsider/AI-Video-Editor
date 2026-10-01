---
id: AVE-REQ-048
title: "One typed editing command service"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-010
epic: AVE-EPIC-05
primary_gate: M1
origins: ["U04", "U08", "U20", "D03"]
dependencies: ["AVE-REQ-001", "AVE-REQ-012"]
scenarios: ["AT-16", "AT-12"]
---

# AVE-REQ-048 - One typed editing command service

## Requirement

The UI, internal AI, and external integrations shall use one versioned, typed editing service with shared validation.

## Acceptance criteria

- [ ] **AC-1:** Support project inspection, asset search, analysis requests, timeline reads, validated batch edits, synchronization, profiles, subtitles, sections, and render-job operations.
- [ ] **AC-2:** Use stable identifiers, schema validation, expected revisions, idempotency keys, and structured errors.
- [ ] **AC-3:** Do not expose arbitrary shell commands, arbitrary filesystem writes, or raw unvalidated FFmpeg filter graphs as editing operations.
- [ ] **AC-4:** Unit and contract tests demonstrate that equivalent UI and AI requests yield equivalent project state.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md); [AVE-REQ-012](AVE-REQ-012.md)

## Verification plan

[AT-16](../ACCEPTANCE_TESTS.md#at-16); [AT-12](../ACCEPTANCE_TESTS.md#at-12). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U04](../../intake/USER_BRIEF.md#u04); [U08](../../intake/USER_BRIEF.md#u08); [U20](../../intake/USER_BRIEF.md#u20); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-010](../EPICS_AND_FEATURES.md#ave-feat-010).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
