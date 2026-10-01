---
id: AVE-REQ-004
title: Media probing, exact dimensions, and source timing
type: functional
status: in-progress
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M1
origins: [U02, U03, U23]
dependencies: [AVE-REQ-002]
scenarios: [AT-01, AT-03, AT-26]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-004.md
---

# AVE-REQ-004 — Media probing, exact dimensions, and source timing

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03) — Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

Imported from the immutable baseline [AVE-REQ-004](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-004.md) (package v1.0); primary gate M1, scope v1.

## Description
Ingestion shall probe actual video and audio stream properties rather than infer resolution, frame rate, or camera capabilities from names.

## Acceptance criteria
- [ ] AC-1 Persist actual width and height, sample/display aspect ratio, rotation, duration, time base, frame-rate metadata, codec, pixel format, color tags, and audio stream properties when available.
- [ ] AC-2 Distinguish 60/1 from 60000/1001 and inspect presentation timestamps when constant versus variable frame rate is uncertain.
- [ ] AC-3 Accept a real or synthetic approximately 2K, 60 fps input; display its exact pixel dimensions instead of treating the label 2K as a specification.
- [ ] AC-4 Handle multiple audio streams, no audio, portrait rotation metadata, and missing optional tags without inventing values.

## Edge cases
- Corrupt, truncated or missing file → clean probe error naming the file, no partial record (AC-4).
- Rotation metadata (90/270) → display dimensions swap; stored coded dimensions stay as probed (AC-1, AC-4).
- Non-square SAR (anamorphic) → SAR/DAR kept exactly as rationals (AC-1).
- Container rate tags that disagree with timestamps, or VFR → timing comes from presentation timestamps (AC-2).
- Audio-only file, still image, multiple audio streams, no audio stream (AC-4).
- Missing optional tags (color, rotation, language) stay unknown, never defaulted (AC-4).
- Filenames are untrusted: a label such as "2K" or "60fps" in a name never sets a property (AC-3).

## Dependencies
- [AVE-REQ-002 — Collection-based batch ingestion](AVE-REQ-002-collection-based-batch-ingestion.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-004 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-01](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-01), [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-26](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-26) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-01 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-01 — in-progress — M0 media core implements part of the ACs (timebase, probe, layout, segmented CPU renderer, audio offset); remaining ACs follow in their gate milestone (lead)
