---
id: AVE-REQ-061
title: Toggleable single- and dual-language captions
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U10, U11]
dependencies: [AVE-REQ-060, AVE-REQ-064]
scenarios: [AT-13, AT-10]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-061.md
---

# AVE-REQ-061 — Toggleable single- and dual-language captions

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.
- [U11](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u11) — Provide separately usable caption/metadata outputs for external platforms such as YouTube, rather than forcing permanent captions into every export.

Imported from the immutable baseline [AVE-REQ-061](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-061.md) (package v1.0); primary gate M4, scope v1.

## Description
Users shall choose no captions, one language, or a primary plus secondary language in the editor without permanently burning them into source video.

## Acceptance criteria
- [ ] AC-1 Caption visibility and selected language tracks can be changed during preview.
- [ ] AC-2 Dual-language display keeps the two languages distinguishable and avoids overlapping text.
- [ ] AC-3 Export settings independently choose sidecars, supported embedded tracks, or intentional burn-in.
- [ ] AC-4 Turning editor captions off does not delete the stored subtitle tracks or prohibit exporting sidecars.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-060 — Translated subtitle language tracks](AVE-REQ-060-translated-subtitle-language-tracks.md)
- [AVE-REQ-064 — Caption formatting and manual cue editor](AVE-REQ-064-caption-formatting-and-manual-cue-editor.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-061 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
