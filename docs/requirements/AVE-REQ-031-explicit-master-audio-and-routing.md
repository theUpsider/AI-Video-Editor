---
id: AVE-REQ-031
title: Explicit master audio and routing
type: functional
status: ready
priority: must
parent: AVE-FEAT-005
source: human
scope: v1
primary_gate: M1
origins: [U02, U15, U19]
dependencies: [AVE-REQ-011, AVE-REQ-012]
scenarios: [AT-04, AT-02, AT-28]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-031.md
---

# AVE-REQ-031 — Explicit master audio and routing

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-005 — Audio routing and mixing](AVE-FEAT-005-audio-routing-and-mixing.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U19](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u19) — Mix two-perspective split-screen footage with full-width 16:9 footage of both people and then return to split-screen.

Imported from the immutable baseline [AVE-REQ-031](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-031.md) (package v1.0); primary gate M1, scope v1.

## Description
A segment or synchronization group shall be able to use one selected source audio track as the final audio while displaying multiple video perspectives.

## Acceptance criteria
- [ ] AC-1 Selecting camera A as reference audio mutes camera B in the final mix without removing B audio needed for analysis.
- [ ] AC-2 A silent secondary video is supported without generating a synthetic duplicate audio stream.
- [ ] AC-3 Switching between split-screen and full-width segments follows explicit segment-level audio routing and fade rules.
- [ ] AC-4 An unavailable reference audio stream triggers a visible fallback decision, not an unnoticed substitute.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-011 — Non-destructive multitrack timeline](AVE-REQ-011-non-destructive-multitrack-timeline.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-031 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-28](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-28) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
