---
id: AVE-REQ-064
title: Caption formatting and manual cue editor
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U10, U20]
dependencies: [AVE-REQ-034, AVE-REQ-058]
scenarios: [AT-13, AT-10]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-064.md
---

# AVE-REQ-064 — Caption formatting and manual cue editor

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-064](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-064.md) (package v1.0); primary gate M4, scope v1.

## Description
Provide editable caption text, cue timings, line breaks, style, and readability checks suitable for different canvas ratios and languages.

## Acceptance criteria
- [ ] AC-1 Users can correct text, split or merge cues, and adjust timings without regenerating the whole transcript.
- [ ] AC-2 Check safe-area overflow, excessive lines, and configurable reading-speed concerns without discarding speech automatically.
- [ ] AC-3 Title and primary/secondary caption regions can be adjusted to avoid collisions.
- [ ] AC-4 Caption styles remain consistent in authoritative preview and optional burn-in export.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-034 — Timed text and image overlays](AVE-REQ-034-timed-text-and-image-overlays.md)
- [AVE-REQ-058 — Editable searchable source transcripts](AVE-REQ-058-editable-searchable-source-transcripts.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-064 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
