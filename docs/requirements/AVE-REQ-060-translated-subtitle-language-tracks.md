---
id: AVE-REQ-060
title: Translated subtitle language tracks
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U10]
dependencies: [AVE-REQ-058, AVE-REQ-059, AVE-REQ-050]
scenarios: [AT-13, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-060.md
---

# AVE-REQ-060 — Translated subtitle language tracks

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.

Imported from the immutable baseline [AVE-REQ-060](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-060.md) (package v1.0); primary gate M4, scope v1.

## Description
The system shall generate editable translated subtitle tracks in user-selected target languages while preserving timing and original text.

## Acceptance criteria
- [ ] AC-1 Translation is a distinct capability from speech recognition and may use the configured text provider or an explicitly installed translation model.
- [ ] AC-2 Preserve names and proper nouns where appropriate, keep source links, and mark translations as machine-generated until reviewed.
- [ ] AC-3 Changing a source cue marks affected translations stale without deleting user corrections silently.
- [ ] AC-4 When translation is unavailable, original-language captions still work and the missing capability is explained.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-058 — Editable searchable source transcripts](AVE-REQ-058-editable-searchable-source-transcripts.md)
- [AVE-REQ-059 — Language detection and source-language control](AVE-REQ-059-language-detection-and-source-language-control.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](AVE-REQ-050-provider-neutral-language-model-adapters.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-060 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
