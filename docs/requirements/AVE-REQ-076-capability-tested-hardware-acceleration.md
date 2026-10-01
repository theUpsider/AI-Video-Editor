---
id: AVE-REQ-076
title: Capability-tested hardware acceleration
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M6
origins: [U22]
dependencies: [AVE-REQ-075]
scenarios: [AT-18, AT-23, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-076.md
---

# AVE-REQ-076 — Capability-tested hardware acceleration

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U22](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u22) — Support CPU-only rendering and GPU acceleration when available.

Imported from the immutable baseline [AVE-REQ-076](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-076.md) (package v1.0); primary gate M6, scope v1.

## Description
Detect and use available hardware acceleration for supported processing stages, with explicit CPU fallback and truthful capability reporting.

## Acceptance criteria
- [ ] AC-1 Probe compiled encoders, device access, and a short real encode before declaring a GPU path usable; an encoder name alone is insufficient.
- [ ] AC-2 Provide an NVIDIA NVENC acceleration profile when available on the reference Linux deployment; other hardware backends may be added through the same capability layer.
- [ ] AC-3 Report acceleration separately for decode, filters/composition, encode, and AI inference.
- [ ] AC-4 If acceleration fails, offer or perform the configured CPU retry without changing project content; report which path actually produced the output.
- [ ] AC-5 GPU integration tests are conditional on real hardware and reported as not run when unavailable, never as CPU-tested GPU success.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-075 — CPU-only reference rendering](AVE-REQ-075-cpu-only-reference-rendering.md)

## Verification strategy
- AC-1–AC-5 — criterion-level tests tagged `AVE-REQ-076 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
