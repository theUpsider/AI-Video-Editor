---
id: AVE-REQ-030
title: "Manual synchronization tools"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-004
epic: AVE-EPIC-03
primary_gate: M2
origins: ["U15", "U20"]
dependencies: ["AVE-REQ-017", "AVE-REQ-026"]
scenarios: ["AT-06", "AT-08", "AT-11"]
---

# AVE-REQ-030 - Manual synchronization tools

## Requirement

Users shall be able to inspect and refine synchronization using waveform views, reference-frame comparisons, anchors, and precise nudges.

## Acceptance criteria

- [ ] **AC-1:** Provide one-frame video nudges and numeric offsets with finer audio precision where supported.
- [ ] **AC-2:** Allow setting at least two corresponding event anchors for drift inspection or correction.
- [ ] **AC-3:** Play an aligned preview with one reference audio source and expose the predicted residual or manual status.
- [ ] **AC-4:** Manual overrides remain stable during subsequent automatic draft or analysis operations unless explicitly reset.

## Dependencies

[AVE-REQ-017](AVE-REQ-017.md); [AVE-REQ-026](AVE-REQ-026.md)

## Verification plan

[AT-06](../ACCEPTANCE_TESTS.md#at-06); [AT-08](../ACCEPTANCE_TESTS.md#at-08); [AT-11](../ACCEPTANCE_TESTS.md#at-11). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U15](../../intake/USER_BRIEF.md#u15); [U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-004](../EPICS_AND_FEATURES.md#ave-feat-004).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
