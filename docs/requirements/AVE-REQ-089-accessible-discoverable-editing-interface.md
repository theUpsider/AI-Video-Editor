---
id: AVE-REQ-089
title: Accessible, discoverable editing interface
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M7
origins: [U20, U24]
dependencies: [AVE-REQ-017, AVE-REQ-044]
scenarios: [AT-11, AT-21, AT-27]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-089.md
---

# AVE-REQ-089 — Accessible, discoverable editing interface

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.

Imported from the immutable baseline [AVE-REQ-089](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-089.md) (package v1.0); primary gate M7, scope v1.

## Description
Deliver a usable desktop editing layout with a collection, preview, timeline, inspector, AI panel, and job/output views.

## Acceptance criteria
- [ ] AC-1 Core actions have labels, keyboard access, focus visibility, useful empty states, and actionable errors.
- [ ] AC-2 Provide numeric alternatives to pointer-only trim, crop, synchronization, and overlay-position controls.
- [ ] AC-3 Test current Chromium and Firefox desktop paths supported by the chosen proxy formats and document any browser limitations.
- [ ] AC-4 Editing and export remain available when AI analysis is busy or disabled; no dead primary buttons or decorative-only timeline.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-017 — Usable synchronized preview](AVE-REQ-017-usable-synchronized-preview.md)
- [AVE-REQ-044 — Natural-language editing interface](AVE-REQ-044-natural-language-editing-interface.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-089 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-21](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-21), [AT-27](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-27) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
