---
id: AVE-REQ-070
title: Short preview and batch delivery
type: functional
status: ready
priority: must
parent: AVE-FEAT-015
source: human
scope: v1
primary_gate: M6
origins: [U12, U23]
dependencies: [AVE-REQ-069, AVE-REQ-072, AVE-REQ-063]
scenarios: [AT-19, AT-18, AT-17]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-070.md
---

# AVE-REQ-070 — Short preview and batch delivery

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-015 — Shorts](AVE-FEAT-015-shorts.md). Origin clauses in the user brief:
- [U12](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u12) — Automatically identify useful approximately 15-20-second highlights and export editable shorts, including square 1:1 outputs.
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

Imported from the immutable baseline [AVE-REQ-070](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-070.md) (package v1.0); primary gate M6, scope v1.

## Description
Users shall preview, adjust, and export selected short sequences with associated subtitles and publication metadata.

## Acceptance criteria
- [ ] AC-1 Validate actual output duration, ratio, resolution, and audio after rendering; do not merely trust preset labels.
- [ ] AC-2 Provide per-short naming, thumbnail/reference frame, caption choices, and export job status.
- [ ] AC-3 Batch export isolates failures and uses bounded worker concurrency.
- [ ] AC-4 Platform presets are editable recommendations, dated when tied to external guidance, and not guarantees of platform acceptance.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-069 — Independent short sequences and reframing](AVE-REQ-069-independent-short-sequences-and-reframing.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-063 — Subtitle sidecars and supported embedded tracks](AVE-REQ-063-subtitle-sidecars-and-supported-embedded-tracks.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-070 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
