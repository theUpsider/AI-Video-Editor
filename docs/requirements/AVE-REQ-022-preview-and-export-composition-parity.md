---
id: AVE-REQ-022
title: Preview and export composition parity
type: functional
status: ready
priority: must
parent: AVE-FEAT-003
source: human
scope: v1
primary_gate: M7
origins: [U02, U20, D03]
dependencies: [AVE-REQ-017, AVE-REQ-019, AVE-REQ-040, AVE-REQ-072]
scenarios: [AT-10, AT-13, AT-18]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-022.md
---

# AVE-REQ-022 — Preview and export composition parity

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-003 — Canvas and mixed layouts](AVE-FEAT-003-canvas-and-mixed-layouts.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-022](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-022.md) (package v1.0); primary gate M7, scope v1.

## Description
Preview and final rendering shall derive from the same validated composition model and share testable rendering semantics.

## Acceptance criteria
- [ ] AC-1 Compare reference frames around cuts, overlays, crops, subtitles, grades, and layout transitions against the final encoded result.
- [ ] AC-2 Any browser approximation is explicitly labeled and a backend reference-frame preview is available for authoritative inspection.
- [ ] AC-3 Define numerical or image-mask tolerances suitable for lossy codecs rather than requiring byte-identical GPU and CPU outputs.
- [ ] AC-4 No effect is advertised as supported in final export solely because it appears in the browser preview.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-017 — Usable synchronized preview](AVE-REQ-017-usable-synchronized-preview.md)
- [AVE-REQ-019 — Aspect-preserving composition and transforms](AVE-REQ-019-aspect-preserving-composition-and-transforms.md)
- [AVE-REQ-040 — Non-destructive color and tonal controls](AVE-REQ-040-non-destructive-color-and-tonal-controls.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-022 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-13](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-13), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
