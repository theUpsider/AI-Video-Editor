---
id: AVE-REQ-087
title: "Private-by-default media and secrets handling"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M5
origins: ["D04", "U25", "U26"]
dependencies: ["AVE-REQ-001"]
scenarios: ["AT-20", "AT-24"]
---

# AVE-REQ-087 - Private-by-default media and secrets handling

## Requirement

Keep original recordings, location metadata, transcripts, and credentials private by default and require clear configuration before external processing.

## Acceptance criteria

- [ ] **AC-1:** Local import, manual editing, and CPU export do not upload source media to model providers.
- [ ] **AC-2:** Before enabling remote analysis, show which data types and approximate payloads leave the system and allow text-only or reduced-frame policies.
- [ ] **AC-3:** Secrets are server-side and redacted; they are excluded from repositories, browser responses, project exports, prompts, and logs.
- [ ] **AC-4:** Provide retention and deletion controls for derived analysis without deleting originals by default.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md)

## Verification plan

[AT-20](../ACCEPTANCE_TESTS.md#at-20); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D04](../../intake/USER_BRIEF.md#d04); [U25](../../intake/USER_BRIEF.md#u25); [U26](../../intake/USER_BRIEF.md#u26). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
