---
id: AVE-REQ-057
title: Speech extraction and local transcription
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U09, U26]
dependencies: [AVE-REQ-004, AVE-REQ-053]
scenarios: [AT-13, AT-24, AT-15]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-057.md
---

# AVE-REQ-057 — Speech extraction and local transcription

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U09](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u09) — Extract speech and generate automatic transcript/subtitle information.
- [U26](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u26) — Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.

Imported from the immutable baseline [AVE-REQ-057](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-057.md) (package v1.0); primary gate M4, scope v1.

## Description
Extract speech-bearing audio for automatic transcription with source-aligned timestamps and a functional CPU-capable local model path.

## Acceptance criteria
- [ ] AC-1 Transcribe the selected audible source or explicit analysis source, retaining asset identity and source-time word or segment timestamps.
- [ ] AC-2 A multilingual small-model CPU profile is available; larger or GPU profiles are optional and resource-checked.
- [ ] AC-3 Silence and non-speech fixtures do not produce accepted invented dialogue; uncertain text is flagged and editable.
- [ ] AC-4 Transcription errors or unavailable models are visible and never replaced by fabricated transcript text.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-053 — Hugging Face model registry and downloads](AVE-REQ-053-hugging-face-model-registry-and-downloads.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-057 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24), [AT-15](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-15) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
