---
id: AVE-REQ-047
title: Grounded editorial reasoning
type: functional
status: ready
priority: must
parent: AVE-FEAT-009
source: human
scope: v1
primary_gate: M5
origins: [U07, U12, U13, U24]
dependencies: [AVE-REQ-058, AVE-REQ-065]
scenarios: [AT-14, AT-19, AT-25]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-047.md
---

# AVE-REQ-047 — Grounded editorial reasoning

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-009 — AI draft and conversational editing](AVE-FEAT-009-ai-draft-and-conversational-editing.md). Origin clauses in the user brief:
- [U07](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u07) — Prepare for identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models; richer understanding was described as future-facing.
- [U12](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u12) — Automatically identify useful approximately 15-20-second highlights and export editable shorts, including square 1:1 outputs.
- [U13](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u13) — Generate copyable keywords and related SEO/publication text.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-047](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-047.md) (package v1.0); primary gate M5, scope v1.

## Description
AI recommendations shall be grounded in identified assets, source intervals, transcripts, metadata, or explicitly labeled visual inference.

## Acceptance criteria
- [ ] AC-1 Every suggested cut, title fact, highlight, or content summary references the relevant asset and source range or a user instruction.
- [ ] AC-2 Unsupported claims about location, people, dialogue, or events are omitted or labeled uncertain.
- [ ] AC-3 Media analysis is retrieved in bounded chunks rather than sending every original video into every model request.
- [ ] AC-4 Candidate scores describe editorial estimates, not guaranteed correctness, engagement, or virality.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-058 — Editable searchable source transcripts](AVE-REQ-058-editable-searchable-source-transcripts.md)
- [AVE-REQ-065 — Timestamped keyframes and shot summaries](AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-047 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14), [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-25](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-25) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
