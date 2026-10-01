---
id: AVE-REQ-008
title: Reviewable accidental-recording detection
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M4
origins: [U14]
dependencies: [AVE-REQ-004, AVE-REQ-007]
scenarios: [AT-15, AT-14]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-008.md
---

# AVE-REQ-008 — Reviewable accidental-recording detection

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U14](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u14) — Identify accidental or content-poor recordings so they can be omitted from a draft.

Imported from the immutable baseline [AVE-REQ-008](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-008.md) (package v1.0); primary gate M4, scope v1.

## Description
The system shall flag likely accidental or unusable recordings as reviewable suggestions, never delete or discard them irreversibly.

## Acceptance criteria
- [ ] AC-1 At minimum inspect decode failure, unusually short duration, prolonged near-black imagery, frozen frames, and silence, with configurable thresholds and reasons.
- [ ] AC-2 A silent scenic shot and a dark but usable night scene remain available; absence of speech is not proof of no content.
- [ ] AC-3 Users can include or exclude flagged clips and override the classification; overrides survive reanalysis.
- [ ] AC-4 AI draft generation reports which assets were excluded and why, and can restore them into another proposal.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-007 — Proxies, thumbnails, and waveforms](AVE-REQ-007-proxies-thumbnails-and-waveforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-008 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-15](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-15), [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
