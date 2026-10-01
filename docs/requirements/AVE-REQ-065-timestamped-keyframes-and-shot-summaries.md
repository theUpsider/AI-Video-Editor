---
id: AVE-REQ-065
title: Timestamped keyframes and shot summaries
type: functional
status: ready
priority: must
parent: AVE-FEAT-014
source: human
scope: v1
primary_gate: M4
origins: [U07, U24]
dependencies: [AVE-REQ-004, AVE-REQ-007]
scenarios: [AT-19, AT-23]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-065.md
---

# AVE-REQ-065 — Timestamped keyframes and shot summaries

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-014 — Visual indexing and understanding](AVE-FEAT-014-visual-indexing-and-understanding.md). Origin clauses in the user brief:
- [U07](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u07) — Prepare for identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models; richer understanding was described as future-facing.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-065](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-065.md) (package v1.0); primary gate M4, scope v1.

## Description
Create a bounded source index of representative timestamped frames, scene boundaries, metadata, and available transcript excerpts for AI retrieval.

## Acceptance criteria
- [ ] AC-1 Extraction samples the whole source progressively with configurable limits instead of decoding every frame into memory.
- [ ] AC-2 Each frame or shot record includes asset ID, exact source interval, extraction method, and derived-asset provenance.
- [ ] AC-3 The AI can retrieve relevant subsets for an edit request and inspect where coverage is incomplete.
- [ ] AC-4 Basic metadata/transcript-driven drafting remains available when a visual model is not configured.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-007 — Proxies, thumbnails, and waveforms](AVE-REQ-007-proxies-thumbnails-and-waveforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-065 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
