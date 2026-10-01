---
id: AVE-REQ-074
title: Mixed-rate input and controlled output timing
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M6
origins: [U03]
dependencies: [AVE-REQ-012, AVE-REQ-018, AVE-REQ-072]
scenarios: [AT-03, AT-04, AT-18]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-074.md
---

# AVE-REQ-074 — Mixed-rate input and controlled output timing

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03) — Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.

Imported from the immutable baseline [AVE-REQ-074](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-074.md) (package v1.0); primary gate M6, scope v1.

## Description
Inputs with different frame rates shall play at their intended real-time speed within one configurable output rate.

## Acceptance criteria
- [ ] AC-1 Validate combinations of 24, 25, 30, 60, 30000/1001, 60000/1001, and a variable-frame-rate fixture.
- [ ] AC-2 Default frame-rate conversion uses documented frame selection/repetition where necessary; optical-flow interpolation is not required.
- [ ] AC-3 Duration, audio timing, synchronization, and overlays remain aligned after conversion.
- [ ] AC-4 Exports record the exact rational output rate and do not relabel 59.94 material as 60 without an explicit conversion.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-018 — Configurable canvas, dimensions, and output rate](AVE-REQ-018-configurable-canvas-dimensions-and-output-rate.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-074 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
