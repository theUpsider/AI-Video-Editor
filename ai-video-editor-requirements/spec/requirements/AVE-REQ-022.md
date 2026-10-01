---
id: AVE-REQ-022
title: "Preview and export composition parity"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-003
epic: AVE-EPIC-02
primary_gate: M7
origins: ["U02", "U20", "D03"]
dependencies: ["AVE-REQ-017", "AVE-REQ-019", "AVE-REQ-040", "AVE-REQ-072"]
scenarios: ["AT-10", "AT-13", "AT-18"]
---

# AVE-REQ-022 - Preview and export composition parity

## Requirement

Preview and final rendering shall derive from the same validated composition model and share testable rendering semantics.

## Acceptance criteria

- [ ] **AC-1:** Compare reference frames around cuts, overlays, crops, subtitles, grades, and layout transitions against the final encoded result.
- [ ] **AC-2:** Any browser approximation is explicitly labeled and a backend reference-frame preview is available for authoritative inspection.
- [ ] **AC-3:** Define numerical or image-mask tolerances suitable for lossy codecs rather than requiring byte-identical GPU and CPU outputs.
- [ ] **AC-4:** No effect is advertised as supported in final export solely because it appears in the browser preview.

## Dependencies

[AVE-REQ-017](AVE-REQ-017.md); [AVE-REQ-019](AVE-REQ-019.md); [AVE-REQ-040](AVE-REQ-040.md); [AVE-REQ-072](AVE-REQ-072.md)

## Verification plan

[AT-10](../ACCEPTANCE_TESTS.md#at-10); [AT-13](../ACCEPTANCE_TESTS.md#at-13); [AT-18](../ACCEPTANCE_TESTS.md#at-18). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U02](../../intake/USER_BRIEF.md#u02); [U20](../../intake/USER_BRIEF.md#u20); [D03](../../intake/USER_BRIEF.md#d03). Parent: [AVE-FEAT-003](../EPICS_AND_FEATURES.md#ave-feat-003).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
