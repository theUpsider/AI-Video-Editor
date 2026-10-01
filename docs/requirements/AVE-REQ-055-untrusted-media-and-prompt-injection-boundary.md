---
id: AVE-REQ-055
title: Untrusted media and prompt-injection boundary
type: functional
status: ready
priority: must
parent: AVE-FEAT-012
source: human
scope: v1
primary_gate: M5
origins: [D04, U08, U24]
dependencies: [AVE-REQ-048]
scenarios: [AT-20, AT-16]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-055.md
---

# AVE-REQ-055 — Untrusted media and prompt-injection boundary

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-012 — AI trust and tool authorization](AVE-FEAT-012-ai-trust-and-tool-authorization.md). Origin clauses in the user brief:
- [D04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d04) — Derived security requirement: untrusted-media boundaries, least privilege, protected credentials, and private-by-default processing.
- [U08](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u08) — Expose editing capabilities through a standardized AI interface, preferably MCP or equivalent integration.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-055](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-055.md) (package v1.0); primary gate M5, scope v1.

## Description
Filenames, transcripts, subtitles, metadata, OCR text, and model-generated captions shall be treated as untrusted content rather than executable instructions.

## Acceptance criteria
- [ ] AC-1 A clip containing text that requests deleting files or leaking credentials cannot override the editing policy.
- [ ] AC-2 Provider outputs are parsed against schemas and authorized operations before any project mutation.
- [ ] AC-3 User-authored instructions are distinguished from quoted content inside media and retrieved analysis.
- [ ] AC-4 Prompt-injection regression fixtures are included for transcripts, filenames, and MCP tool results.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-055 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20), [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
