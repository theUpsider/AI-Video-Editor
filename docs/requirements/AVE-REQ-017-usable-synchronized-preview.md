---
id: AVE-REQ-017
title: Usable synchronized preview
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M2
origins: [U20]
dependencies: [AVE-REQ-007, AVE-REQ-011, AVE-REQ-012]
scenarios: [AT-02, AT-11, AT-27]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-017.md
---

# AVE-REQ-017 — Usable synchronized preview

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-017](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-017.md) (package v1.0); primary gate M2, scope v1.

## Description
The editor shall provide a preview canvas with play/pause, scrubbing, frame stepping, timeline selection, audio playback, and visible render status.

## Acceptance criteria
- [ ] AC-1 Preview presents all visible layers and the selected final audio routing, not one independent audio player per camera.
- [ ] AC-2 Proxy-backed playback and quality changes do not modify project frame rate, timing, or export quality.
- [ ] AC-3 The current playhead, clip selection, trim handles, waveforms, and overlay selection remain coordinated.
- [ ] AC-4 Scrubbing or frame inspection uses bounded work and displays pending reference frames rather than blocking the entire interface.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-007 — Proxies, thumbnails, and waveforms](AVE-REQ-007-proxies-thumbnails-and-waveforms.md)
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-017 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-27](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-27) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
