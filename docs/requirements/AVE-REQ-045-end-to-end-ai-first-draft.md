---
id: AVE-REQ-045
title: End-to-end AI first draft
type: functional
status: ready
priority: must
parent: AVE-FEAT-009
source: human
scope: v1
primary_gate: M5
origins: [U24, U01, U15, U05]
dependencies: [AVE-REQ-006, AVE-REQ-008, AVE-REQ-023, AVE-REQ-035, AVE-REQ-038, AVE-REQ-047, AVE-REQ-057, AVE-REQ-065]
scenarios: [AT-14, AT-02, AT-09]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-045.md
---

# AVE-REQ-045 — End-to-end AI first draft

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-009 — AI draft and conversational editing](AVE-FEAT-009-ai-draft-and-conversational-editing.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [U01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u01) — Import the user's clips into a collection rather than requiring a hand-built timeline.
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u05) — Place contextual titles such as locations near the start and optional credits/references near the end, not continuously.

Imported from the immutable baseline [AVE-REQ-045](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-045.md) (package v1.0); primary gate M5, scope v1.

## Description
From a populated collection and a high-level brief, the AI shall produce a playable first-draft timeline, not merely editing advice.

## Acceptance criteria
- [ ] AC-1 The workflow examines available metadata and analysis, proposes camera groups and synchronization, organizes sections, and selects coherent source intervals.
- [ ] AC-2 It assembles split-screen and full-width segments, routes reference audio, applies the chosen look, and adds bounded titles and requested captions.
- [ ] AC-3 It reports uncertain alignment, exclusions, missing metadata, and assumptions without presenting them as verified facts.
- [ ] AC-4 An initial empty-project draft may apply automatically as a reversible transaction; replacing an existing edit requires a diff or explicit scoped authorization.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-006 — Library organization and filtering](AVE-REQ-006-library-organization-and-filtering.md)
- [AVE-REQ-008 — Reviewable accidental-recording detection](AVE-REQ-008-reviewable-accidental-recording-detection.md)
- [AVE-REQ-023 — Synchronization candidate matching](AVE-REQ-023-synchronization-candidate-matching.md)
- [AVE-REQ-035 — Contextual opening titles and end references](AVE-REQ-035-contextual-opening-titles-and-end-references.md)
- [AVE-REQ-038 — Editable date and location sections](AVE-REQ-038-editable-date-and-location-sections.md)
- [AVE-REQ-047 — Grounded editorial reasoning](AVE-REQ-047-grounded-editorial-reasoning.md)
- [AVE-REQ-057 — Speech extraction and local transcription](AVE-REQ-057-speech-extraction-and-local-transcription.md)
- [AVE-REQ-065 — Timestamped keyframes and shot summaries](AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-045 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14), [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
