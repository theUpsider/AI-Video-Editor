---
id: AVE-REQ-069
title: Independent short sequences and reframing
type: functional
status: ready
priority: must
parent: AVE-FEAT-015
source: human
scope: v1
primary_gate: M6
origins: [U12, U02]
dependencies: [AVE-REQ-068, AVE-REQ-019, AVE-REQ-015]
scenarios: [AT-19, AT-13, AT-02]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-069.md
---

# AVE-REQ-069 — Independent short sequences and reframing

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-015 — Shorts](AVE-FEAT-015-shorts.md). Origin clauses in the user brief:
- [U12](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u12) — Automatically identify useful approximately 15-20-second highlights and export editable shorts, including square 1:1 outputs.
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.

Imported from the immutable baseline [AVE-REQ-069](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-069.md) (package v1.0); primary gate M6, scope v1.

## Description
Shorts shall be derived editable sequences that reuse originals without destructively changing the main edit.

## Acceptance criteria
- [ ] AC-1 Default short canvas is 1:1 as requested; 9:16, 16:9, and custom ratios remain selectable.
- [ ] AC-2 Derived shorts preserve intended sync, audio routing, grades, overlays, and subtitle time mappings.
- [ ] AC-3 Provide static split, stacked, full-width, or cropped composition options suitable for the chosen output; no tracking is required.
- [ ] AC-4 Editing a short does not mutate the parent sequence unless the user explicitly applies a supported shared change.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-068 — Grounded short-form highlight suggestions](AVE-REQ-068-grounded-short-form-highlight-suggestions.md)
- [AVE-REQ-019 — Aspect-preserving composition and transforms](AVE-REQ-019-aspect-preserving-composition-and-transforms.md)
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](AVE-REQ-015-undo-redo-autosave-and-revisions.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-069 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
