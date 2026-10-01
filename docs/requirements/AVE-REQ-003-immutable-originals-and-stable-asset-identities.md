---
id: AVE-REQ-003
title: Immutable originals and stable asset identities
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M1
origins: [U24, D01]
dependencies: [AVE-REQ-002]
scenarios: [AT-01, AT-22]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-003.md
---

# AVE-REQ-003 — Immutable originals and stable asset identities

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-003](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-003.md) (package v1.0); primary gate M1, scope v1.

## Description
Each imported asset shall have a stable identifier and provenance, and editing shall never modify the original media bytes.

## Acceptance criteria
- [ ] AC-1 Checksums before and after trim, synchronization, grading, subtitle generation, and export match for every original.
- [ ] AC-2 Re-importing the same bytes identifies an existing asset or deliberately creates another reference without silent storage duplication.
- [ ] AC-3 Timeline references survive filename changes and supported relinking without silently substituting different content.
- [ ] AC-4 Derived proxies, thumbnails, transcripts, and renders record their source asset, source revision or checksum, and generation settings.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-002 — Collection-based batch ingestion](AVE-REQ-002-collection-based-batch-ingestion.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-003 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-01](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-01), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
