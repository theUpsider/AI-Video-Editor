---
id: AVE-REQ-058
title: Editable searchable source transcripts
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U07, U09]
dependencies: [AVE-REQ-057]
scenarios: [AT-13, AT-19]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-058.md
---

# AVE-REQ-058 — Editable searchable source transcripts

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U07](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u07) — Prepare for identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models; richer understanding was described as future-facing.
- [U09](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u09) — Extract speech and generate automatic transcript/subtitle information.

Imported from the immutable baseline [AVE-REQ-058](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-058.md) (package v1.0); primary gate M4, scope v1.

## Description
Users shall inspect, correct, and search transcripts linked to source intervals without changing original recordings.

## Acceptance criteria
- [ ] AC-1 Search results jump to the relevant source or timeline occurrence and show asset identity.
- [ ] AC-2 Corrections preserve source timing or allow explicit timing adjustment and invalidate affected derived translations or summaries.
- [ ] AC-3 A source appearing multiple times on a timeline retains a single source transcript with separate timeline mappings.
- [ ] AC-4 Imported or manually written transcripts remain labeled as such, distinct from model-generated text.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-057 — Speech extraction and local transcription](AVE-REQ-057-speech-extraction-and-local-transcription.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-058 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
