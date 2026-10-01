---
id: AVE-REQ-002
title: Collection-based batch ingestion
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M1
origins: [U01, U24]
dependencies: [AVE-REQ-001]
scenarios: [AT-01, AT-23]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-002.md
---

# AVE-REQ-002 — Collection-based batch ingestion

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u01) — Import the user's clips into a collection rather than requiring a hand-built timeline.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-002](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-002.md) (package v1.0); primary gate M1, scope v1.

## Description
The collection shall accept batches of video, audio, and image files, including large camera recordings, with visible import progress and recoverable failures.

## Acceptance criteria
- [ ] AC-1 Users can add multiple files through a file picker and drag-and-drop, then see per-file queued, importing, ready, or failed states.
- [ ] AC-2 An interrupted large upload can resume or retry without duplicating the media asset or exhausting server memory.
- [ ] AC-3 A failed or unsupported file does not prevent valid files in the same batch from importing.
- [ ] AC-4 Local file references, when offered, are limited to explicitly configured import roots; browser filenames are never treated as trusted server paths.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-002 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-01](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-01), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
