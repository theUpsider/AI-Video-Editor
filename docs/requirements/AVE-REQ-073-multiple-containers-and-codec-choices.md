---
id: AVE-REQ-073
title: Multiple containers and codec choices
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M6
origins: [U23]
dependencies: [AVE-REQ-072]
scenarios: [AT-18, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-073.md
---

# AVE-REQ-073 — Multiple containers and codec choices

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

Imported from the immutable baseline [AVE-REQ-073](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-073.md) (package v1.0); primary gate M6, scope v1.

## Description
The editor shall offer validated export combinations beyond the default profile and show capability-dependent alternatives honestly.

## Acceptance criteria
- [ ] AC-1 The reference software build supports MP4/H.264/AAC, WebM/VP9/Opus, and a documented MKV profile with correct muxing and playback tests.
- [ ] AC-2 Additional HEVC, AV1, ProRes/MOV, or other choices are exposed only when installed encoders and output constraints permit them.
- [ ] AC-3 The UI distinguishes container, video codec, audio codec, pixel format, quality, and bitrate.
- [ ] AC-4 Changing a container revalidates audio/subtitle compatibility rather than only changing the filename extension.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-073 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
