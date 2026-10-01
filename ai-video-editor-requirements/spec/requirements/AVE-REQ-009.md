---
id: AVE-REQ-009
title: "Broken media and relinking"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M1
origins: ["U24", "D01"]
dependencies: ["AVE-REQ-003", "AVE-REQ-004"]
scenarios: ["AT-01", "AT-22"]
---

# AVE-REQ-009 - Broken media and relinking

## Requirement

Missing, corrupted, unsupported, or inaccessible media shall produce recoverable errors rather than fabricated successful analysis or export.

## Acceptance criteria

- [ ] **AC-1:** The collection and affected timeline items display the specific problem and retain their edit metadata.
- [ ] **AC-2:** Relinking validates identity or asks for explicit replacement confirmation when the content differs.
- [ ] **AC-3:** Exports using broken media fail preflight or require an explicit, recorded gap policy; they never silently omit clips.
- [ ] **AC-4:** Errors identify the failing asset and actionable diagnostics without exposing secrets.

## Dependencies

[AVE-REQ-003](AVE-REQ-003.md); [AVE-REQ-004](AVE-REQ-004.md)

## Verification plan

[AT-01](../ACCEPTANCE_TESTS.md#at-01); [AT-22](../ACCEPTANCE_TESTS.md#at-22). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
