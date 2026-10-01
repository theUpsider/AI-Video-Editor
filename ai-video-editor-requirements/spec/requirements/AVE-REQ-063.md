---
id: AVE-REQ-063
title: "Subtitle sidecars and supported embedded tracks"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-013
epic: AVE-EPIC-06
primary_gate: M6
origins: ["U10", "U11"]
dependencies: ["AVE-REQ-062"]
scenarios: ["AT-13", "AT-18"]
---

# AVE-REQ-063 - Subtitle sidecars and supported embedded tracks

## Requirement

Export per-language UTF-8 SRT and WebVTT subtitle files and offer compatible embedded subtitle tracks when the selected container supports them.

## Acceptance criteria

- [ ] **AC-1:** One selected language produces a separately named, valid subtitle file with rebased output timing and language metadata.
- [ ] **AC-2:** Burn-in is optional and clearly distinguished from toggleable captions; original-language and translated files can be exported together.
- [ ] **AC-3:** Unsupported codec/container subtitle combinations are rejected or redirected to sidecars with an explanation.
- [ ] **AC-4:** Document uploading subtitle files to external platforms; do not claim that embedding tracks automatically creates selectable platform captions.

## Dependencies

[AVE-REQ-062](AVE-REQ-062.md)

## Verification plan

[AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-18](../ACCEPTANCE_TESTS.md#at-18). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U10](../../intake/USER_BRIEF.md#u10); [U11](../../intake/USER_BRIEF.md#u11). Parent: [AVE-FEAT-013](../EPICS_AND_FEATURES.md#ave-feat-013).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
