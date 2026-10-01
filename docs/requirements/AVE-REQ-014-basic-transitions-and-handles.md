---
id: AVE-REQ-014
title: Basic transitions and handles
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M2
origins: [U20]
dependencies: [AVE-REQ-013]
scenarios: [AT-11, AT-02]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-014.md
---

# AVE-REQ-014 — Basic transitions and handles

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-014](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-014.md) (package v1.0); primary gate M2, scope v1.

## Description
The editor shall support hard cuts, video cross-dissolves, fades to or from a background, and audio fades or crossfades with editable timing.

## Acceptance criteria
- [ ] AC-1 Transition start, end, and duration can be adjusted through the timeline and the editing API.
- [ ] AC-2 The editor validates available source handles and prevents accidental shortening, overlap corruption, or audio duplication.
- [ ] AC-3 Transitions between split-screen and full-width segments render consistently without leaving stale imagery from a previous layout.
- [ ] AC-4 Shortening or deleting a transition is undoable and updates dependent subtitle and section timing correctly when project time changes.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-013 — Manual editing and precision controls](AVE-REQ-013-manual-editing-and-precision-controls.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-014 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
