---
id: AVE-REQ-003
title: "Immutable originals and stable asset identities"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M1
origins: ["U24", "D01"]
dependencies: ["AVE-REQ-002"]
scenarios: ["AT-01", "AT-22"]
---

# AVE-REQ-003 - Immutable originals and stable asset identities

## Requirement

Each imported asset shall have a stable identifier and provenance, and editing shall never modify the original media bytes.

## Acceptance criteria

- [ ] **AC-1:** Checksums before and after trim, synchronization, grading, subtitle generation, and export match for every original.
- [ ] **AC-2:** Re-importing the same bytes identifies an existing asset or deliberately creates another reference without silent storage duplication.
- [ ] **AC-3:** Timeline references survive filename changes and supported relinking without silently substituting different content.
- [ ] **AC-4:** Derived proxies, thumbnails, transcripts, and renders record their source asset, source revision or checksum, and generation settings.

## Dependencies

[AVE-REQ-002](AVE-REQ-002.md)

## Verification plan

[AT-01](../ACCEPTANCE_TESTS.md#at-01); [AT-22](../ACCEPTANCE_TESTS.md#at-22). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
