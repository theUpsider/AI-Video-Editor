---
id: AVE-REQ-063
title: Subtitle sidecars and supported embedded tracks
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M6
origins: [U10, U11]
dependencies: [AVE-REQ-062]
scenarios: [AT-13, AT-18]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-063.md
---

# AVE-REQ-063 — Subtitle sidecars and supported embedded tracks

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.
- [U11](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u11) — Provide separately usable caption/metadata outputs for external platforms such as YouTube, rather than forcing permanent captions into every export.

Imported from the immutable baseline [AVE-REQ-063](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-063.md) (package v1.0); primary gate M6, scope v1.

## Description
Export per-language UTF-8 SRT and WebVTT subtitle files and offer compatible embedded subtitle tracks when the selected container supports them.

## Acceptance criteria
- [ ] AC-1 One selected language produces a separately named, valid subtitle file with rebased output timing and language metadata.
- [ ] AC-2 Burn-in is optional and clearly distinguished from toggleable captions; original-language and translated files can be exported together.
- [ ] AC-3 Unsupported codec/container subtitle combinations are rejected or redirected to sidecars with an explanation.
- [ ] AC-4 Document uploading subtitle files to external platforms; do not claim that embedding tracks automatically creates selectable platform captions.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-062 — Subtitle retiming through edits and synchronization](AVE-REQ-062-subtitle-retiming-through-edits-and-synchronization.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-063 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
