---
id: AVE-REQ-055
title: "Untrusted media and prompt-injection boundary"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-012
epic: AVE-EPIC-05
primary_gate: M5
origins: ["D04", "U08", "U24"]
dependencies: ["AVE-REQ-048"]
scenarios: ["AT-20", "AT-16"]
---

# AVE-REQ-055 - Untrusted media and prompt-injection boundary

## Requirement

Filenames, transcripts, subtitles, metadata, OCR text, and model-generated captions shall be treated as untrusted content rather than executable instructions.

## Acceptance criteria

- [ ] **AC-1:** A clip containing text that requests deleting files or leaking credentials cannot override the editing policy.
- [ ] **AC-2:** Provider outputs are parsed against schemas and authorized operations before any project mutation.
- [ ] **AC-3:** User-authored instructions are distinguished from quoted content inside media and retrieved analysis.
- [ ] **AC-4:** Prompt-injection regression fixtures are included for transcripts, filenames, and MCP tool results.

## Dependencies

[AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-20](../ACCEPTANCE_TESTS.md#at-20); [AT-16](../ACCEPTANCE_TESTS.md#at-16). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D04](../../intake/USER_BRIEF.md#d04); [U08](../../intake/USER_BRIEF.md#u08); [U24](../../intake/USER_BRIEF.md#u24). Parent: [AVE-FEAT-012](../EPICS_AND_FEATURES.md#ave-feat-012).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
