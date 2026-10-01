---
id: AVE-REQ-059
title: Language detection and source-language control
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U09, U10]
dependencies: [AVE-REQ-057]
scenarios: [AT-13, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-059.md
---

# AVE-REQ-059 — Language detection and source-language control

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U09](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u09) — Extract speech and generate automatic transcript/subtitle information.
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.

Imported from the immutable baseline [AVE-REQ-059](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-059.md) (package v1.0); primary gate M4, scope v1.

## Description
The transcription workflow shall support detected or user-selected source languages and preserve language metadata.

## Acceptance criteria
- [ ] AC-1 Users can override a wrong detected language per asset or transcript.
- [ ] AC-2 Original-language text is retained rather than silently replaced by a translation.
- [ ] AC-3 Mixed-language content is represented using the selected model capabilities and flagged where detection is uncertain.
- [ ] AC-4 The UI reports actual model-supported language capabilities rather than claiming every language is supported equally.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-057 — Speech extraction and local transcription](AVE-REQ-057-speech-extraction-and-local-transcription.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-059 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
