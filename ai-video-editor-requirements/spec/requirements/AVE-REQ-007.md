---
id: AVE-REQ-007
title: "Proxies, thumbnails, and waveforms"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M1
origins: ["U20", "U24", "D02"]
dependencies: ["AVE-REQ-003", "AVE-REQ-004"]
scenarios: ["AT-03", "AT-22", "AT-27"]
---

# AVE-REQ-007 - Proxies, thumbnails, and waveforms

## Requirement

The system shall generate bounded, cacheable preview proxies, thumbnails, and audio waveforms while preserving exact links to original source time.

## Acceptance criteria

- [ ] **AC-1:** Proxy generation is a visible asynchronous job and can be cancelled or retried.
- [ ] **AC-2:** Preview proxies preserve duration, orientation, aspect ratio, and a mapping to original presentation timestamps, including variable-rate inputs.
- [ ] **AC-3:** Final exports use originals unless the user explicitly selects a clearly labeled draft/proxy export.
- [ ] **AC-4:** Derived caches can be evicted and regenerated without losing edits, source files, or synchronization anchors.

## Dependencies

[AVE-REQ-003](AVE-REQ-003.md); [AVE-REQ-004](AVE-REQ-004.md)

## Verification plan

[AT-03](../ACCEPTANCE_TESTS.md#at-03); [AT-22](../ACCEPTANCE_TESTS.md#at-22); [AT-27](../ACCEPTANCE_TESTS.md#at-27). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U20](../../intake/USER_BRIEF.md#u20); [U24](../../intake/USER_BRIEF.md#u24); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
