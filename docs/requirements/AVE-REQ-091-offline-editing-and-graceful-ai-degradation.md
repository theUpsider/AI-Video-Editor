---
id: AVE-REQ-091
title: Offline editing and graceful AI degradation
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M7
origins: [U22, U26, D02]
dependencies: [AVE-REQ-075, AVE-REQ-053]
scenarios: [AT-21, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-091.md
---

# AVE-REQ-091 — Offline editing and graceful AI degradation

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [U22](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u22) — Support CPU-only rendering and GPU acceleration when available.
- [U26](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u26) — Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-091](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-091.md) (package v1.0); primary gate M7, scope v1.

## Description
Once installed, manual editing and supported CPU export shall work without an external model connection, and cached local analysis shall work where its dependencies are present.

## Acceptance criteria
- [ ] AC-1 Disconnected operation still permits project load, preview, manual edits, and render to supported local formats.
- [ ] AC-2 Cached speech models operate offline; missing uncached models produce a clear download requirement.
- [ ] AC-3 A deterministic metadata-based draft may be offered but is explicitly labeled rule-based and does not count as a successful generative-AI integration.
- [ ] AC-4 Provider or model failures preserve accepted project state and leave alternative manual workflows usable.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-075 — CPU-only reference rendering](AVE-REQ-075-cpu-only-reference-rendering.md)
- [AVE-REQ-053 — Hugging Face model registry and downloads](AVE-REQ-053-hugging-face-model-registry-and-downloads.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-091 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-21](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-21), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
