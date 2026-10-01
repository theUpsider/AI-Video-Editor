---
id: AVE-REQ-075
title: CPU-only reference rendering
type: functional
status: in-progress
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M1
origins: [U22]
dependencies: [AVE-REQ-072, AVE-REQ-082]
scenarios: [AT-02, AT-18, AT-23]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-075.md
---

# AVE-REQ-075 — CPU-only reference rendering

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U22](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u22) — Support CPU-only rendering and GPU acceleration when available.

Imported from the immutable baseline [AVE-REQ-075](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-075.md) (package v1.0); primary gate M1, scope v1.

## Description
All version-one editing and mandatory export operations shall have a functional CPU-only rendering path.

## Acceptance criteria
- [ ] AC-1 The application starts, imports, edits, and exports in the documented reference environment without a GPU.
- [ ] AC-2 The CPU renderer supports the same required composition semantics as accelerated profiles.
- [ ] AC-3 No visual analysis model or cloud provider is required merely to render an existing timeline.
- [ ] AC-4 Tests use real media and decoding of outputs; a mocked render job cannot satisfy this requirement.

## Edge cases
- No GPU and no hardware encoder present → the CPU path runs without probing for one (AC-1).
- No model weights or provider credentials present → rendering an existing timeline still succeeds (AC-3).
- Stills, silent sources and empty timeline stretches render on the CPU path (AC-2).
- Tests decode real output; a mocked job never counts (AC-4).

## Dependencies
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-082 — Self-hostable browser application and CPU reference setup](AVE-REQ-082-self-hostable-browser-application-and-cpu-reference-setup.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-075 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-01 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-01 — in-progress — M0 media core implements part of the ACs (timebase, probe, layout, segmented CPU renderer, audio offset); remaining ACs follow in their gate milestone (lead)
