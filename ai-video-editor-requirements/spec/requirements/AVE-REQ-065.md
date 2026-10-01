---
id: AVE-REQ-065
title: "Timestamped keyframes and shot summaries"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-014
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U07", "U24"]
dependencies: ["AVE-REQ-004", "AVE-REQ-007"]
scenarios: ["AT-19", "AT-23"]
---

# AVE-REQ-065 - Timestamped keyframes and shot summaries

## Requirement

Create a bounded source index of representative timestamped frames, scene boundaries, metadata, and available transcript excerpts for AI retrieval.

## Acceptance criteria

- [ ] **AC-1:** Extraction samples the whole source progressively with configurable limits instead of decoding every frame into memory.
- [ ] **AC-2:** Each frame or shot record includes asset ID, exact source interval, extraction method, and derived-asset provenance.
- [ ] **AC-3:** The AI can retrieve relevant subsets for an edit request and inspect where coverage is incomplete.
- [ ] **AC-4:** Basic metadata/transcript-driven drafting remains available when a visual model is not configured.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md); [AVE-REQ-007](AVE-REQ-007.md)

## Verification plan

[AT-19](../ACCEPTANCE_TESTS.md#at-19); [AT-23](../ACCEPTANCE_TESTS.md#at-23). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U07](../../intake/USER_BRIEF.md#u07); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-014](../EPICS_AND_FEATURES.md#ave-feat-014).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
