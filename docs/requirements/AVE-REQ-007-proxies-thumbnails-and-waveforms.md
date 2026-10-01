---
id: AVE-REQ-007
title: Proxies, thumbnails, and waveforms
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M1
origins: [U20, U24, D02]
dependencies: [AVE-REQ-003, AVE-REQ-004]
scenarios: [AT-03, AT-22, AT-27]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-007.md
---

# AVE-REQ-007 — Proxies, thumbnails, and waveforms

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-007](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-007.md) (package v1.0); primary gate M1, scope v1.

## Description
The system shall generate bounded, cacheable preview proxies, thumbnails, and audio waveforms while preserving exact links to original source time.

## Acceptance criteria
- [ ] AC-1 Proxy generation is a visible asynchronous job and can be cancelled or retried.
- [ ] AC-2 Preview proxies preserve duration, orientation, aspect ratio, and a mapping to original presentation timestamps, including variable-rate inputs.
- [ ] AC-3 Final exports use originals unless the user explicitly selects a clearly labeled draft/proxy export.
- [ ] AC-4 Derived caches can be evicted and regenerated without losing edits, source files, or synchronization anchors.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-003 — Immutable originals and stable asset identities](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-007 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-27](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-27) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
