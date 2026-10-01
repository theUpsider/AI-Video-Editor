---
id: AVE-REQ-072
title: Real export pipeline and default delivery profile
type: functional
status: in-progress
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M1
origins: [U22, U23]
dependencies: [AVE-REQ-012, AVE-REQ-048]
scenarios: [AT-02, AT-18, AT-28]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-072.md
---

# AVE-REQ-072 — Real export pipeline and default delivery profile

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U22](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u22) — Support CPU-only rendering and GPU acceleration when available.
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

Imported from the immutable baseline [AVE-REQ-072](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-072.md) (package v1.0); primary gate M1, scope v1.

## Description
The product shall render real playable video files from the composition graph, with an initial MP4/H.264/AAC SDR delivery profile and configurable output parameters.

## Acceptance criteria
- [ ] AC-1 The initial delivery profile uses the project canvas/rate, normally 1920x1080 at resolved source-appropriate rate, with 48 kHz AAC audio.
- [ ] AC-2 Expose quality-based and target-bitrate controls with encoder-specific defaults; use a documented software starting point such as CRF 20 rather than claiming universal optimality.
- [ ] AC-3 Render video, selected audio, layouts, transforms, transitions, effects, and chosen captions; a downloaded project JSON is not a rendered video.
- [ ] AC-4 Outputs are written atomically and become downloadable only after validation succeeds.

## Edge cases
- Validation failure → no published file; an existing output at the target path is never overwritten by a failed render (AC-4).
- Interrupted render leaves no partial file at the published path (AC-4).
- Odd or unsupported output parameters are rejected before encoding (AC-2).
- Range exports and full exports share one compiler (AC-3).
- A project JSON download is never reported as a rendered video (AC-3).

## Dependencies
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-072 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-28](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-28) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-01 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-01 — in-progress — M0 media core implements part of the ACs (timebase, probe, layout, segmented CPU renderer, audio offset); remaining ACs follow in their gate milestone (lead)
