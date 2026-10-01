---
id: AVE-REQ-067
title: Advanced continuous video understanding
type: functional
status: deferred
priority: could
parent: AVE-FEAT-014
source: human
scope: future
primary_gate: FUTURE
origins: [U07]
dependencies: [AVE-REQ-065, AVE-REQ-066]
scenarios: [AT-31]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-067.md
---

# AVE-REQ-067 — Advanced continuous video understanding

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-014 — Visual indexing and understanding](AVE-FEAT-014-visual-indexing-and-understanding.md). Origin clauses in the user brief:
- [U07](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u07) — Prepare for identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models; richer understanding was described as future-facing.

Imported from the immutable baseline [AVE-REQ-067](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-067.md) (package v1.0); primary gate FUTURE, scope future.

## Description
A later version may add richer continuous temporal video understanding and semantic retrieval beyond bounded frames, shots, and transcripts.

## Acceptance criteria
- [ ] AC-1 Preserve extensible analysis schemas and source-time references in version one.
- [ ] AC-2 Do not require a large video model, vector database, tracking, or full-video semantic comprehension to ship version one.
- [ ] AC-3 Keep this feature visibly deferred and do not advertise it as implemented based on frame captions alone.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-065 — Timestamped keyframes and shot summaries](AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md)
- [AVE-REQ-066 — Optional local or remote visual-caption adapter](AVE-REQ-066-optional-local-or-remote-visual-caption-adapter.md)

## Verification strategy
- AC-1–AC-3 — criterion-level tests tagged `AVE-REQ-067 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-31](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-31) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.
- Deferred: version one keeps this capability excluded (GOAL-010).

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — deferred — future scope in baseline (lead)
