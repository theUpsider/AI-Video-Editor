---
id: AVE-REQ-062
title: Subtitle retiming through edits and synchronization
type: functional
status: ready
priority: must
parent: AVE-FEAT-013
source: human
scope: v1
primary_gate: M4
origins: [U10, U15, U20, D03]
dependencies: [AVE-REQ-012, AVE-REQ-026, AVE-REQ-058]
scenarios: [AT-13, AT-08, AT-09]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-062.md
---

# AVE-REQ-062 — Subtitle retiming through edits and synchronization

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-013 — Speech, translation, and captions](AVE-FEAT-013-speech-translation-and-captions.md). Origin clauses in the user brief:
- [U10](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u10) — Allow selectable subtitle languages and an optional second simultaneously displayed language.
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-062](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-062.md) (package v1.0); primary gate M4, scope v1.

## Description
Subtitle cues shall be derived from source-aligned text through the same time mappings used by video and audio.

## Acceptance criteria
- [ ] AC-1 Trims, cuts, repeated source uses, synchronization offsets, drift correction, and section/short exports produce correct output cue timing.
- [ ] AC-2 Cues are split or clipped at removed regions rather than spanning unrelated footage.
- [ ] AC-3 No exported cue has negative duration, invalid ordering, or times beyond the selected output interval.
- [ ] AC-4 Editing a timeline does not corrupt the original source transcript timestamps.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-026 — Persistent synchronization transforms](AVE-REQ-026-persistent-synchronization-transforms.md)
- [AVE-REQ-058 — Editable searchable source transcripts](AVE-REQ-058-editable-searchable-source-transcripts.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-062 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-08](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-08), [AT-09](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-09) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
