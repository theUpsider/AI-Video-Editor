---
id: AVE-REQ-008
title: "Reviewable accidental-recording detection"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M4
origins: ["U14"]
dependencies: ["AVE-REQ-004", "AVE-REQ-007"]
scenarios: ["AT-15", "AT-14"]
---

# AVE-REQ-008 - Reviewable accidental-recording detection

## Requirement

The system shall flag likely accidental or unusable recordings as reviewable suggestions, never delete or discard them irreversibly.

## Acceptance criteria

- [ ] **AC-1:** At minimum inspect decode failure, unusually short duration, prolonged near-black imagery, frozen frames, and silence, with configurable thresholds and reasons.
- [ ] **AC-2:** A silent scenic shot and a dark but usable night scene remain available; absence of speech is not proof of no content.
- [ ] **AC-3:** Users can include or exclude flagged clips and override the classification; overrides survive reanalysis.
- [ ] **AC-4:** AI draft generation reports which assets were excluded and why, and can restore them into another proposal.

## Dependencies

[AVE-REQ-004](AVE-REQ-004.md); [AVE-REQ-007](AVE-REQ-007.md)

## Verification plan

[AT-15](../ACCEPTANCE_TESTS.md#at-15); [AT-14](../ACCEPTANCE_TESTS.md#at-14). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U14](../../intake/USER_BRIEF.md#u14). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
