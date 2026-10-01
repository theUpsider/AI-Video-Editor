---
id: AVE-REQ-032
title: Independent audio tracks and basic mixing
type: functional
status: ready
priority: must
parent: AVE-FEAT-005
source: human
scope: v1
primary_gate: M2
origins: [U02]
dependencies: [AVE-REQ-031]
scenarios: [AT-28, AT-04]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-032.md
---

# AVE-REQ-032 — Independent audio tracks and basic mixing

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-005 — Audio routing and mixing](AVE-FEAT-005-audio-routing-and-mixing.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.

Imported from the immutable baseline [AVE-REQ-032](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-032.md) (package v1.0); primary gate M2, scope v1.

## Description
The timeline shall support independent audio clips and basic mixing controls for source audio, voice, music, and other imported audio.

## Acceptance criteria
- [ ] AC-1 Users can add audio-only assets, trim and move them, adjust gain, mute or solo, and apply fades or crossfades.
- [ ] AC-2 Provide level metering and clipping warnings; optional loudness normalization remains an explicit, reversible choice.
- [ ] AC-3 Audio sample-rate conversion and encoder delay handling do not introduce a growing video/audio offset.
- [ ] AC-4 Unselected camera audio is not accidentally doubled into the mix.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-031 — Explicit master audio and routing](AVE-REQ-031-explicit-master-audio-and-routing.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-032 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-28](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-28), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
