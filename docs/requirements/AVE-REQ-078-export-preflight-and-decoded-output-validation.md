---
id: AVE-REQ-078
title: Export preflight and decoded-output validation
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M7
origins: [U23, D03]
dependencies: [AVE-REQ-072, AVE-REQ-077]
scenarios: [AT-18, AT-04, AT-10, AT-17]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-078.md
---

# AVE-REQ-078 — Export preflight and decoded-output validation

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-078](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-078.md) (package v1.0); primary gate M7, scope v1.

## Description
Preflight exports and verify the produced files against the selected immutable revision and output contract.

## Acceptance criteria
- [ ] AC-1 Before rendering, validate source availability, intervals, capabilities, free disk space, audio routing, font availability, and relevant subtitle choices.
- [ ] AC-2 After rendering, probe dimensions, exact rate, streams, codecs, duration, color metadata, and decode representative or complete small-test outputs.
- [ ] AC-3 Check reference frames and audio for critical fixtures, detecting black outputs, missing overlays, doubled audio, or truncated endings.
- [ ] AC-4 Validation failure leaves the job failed with diagnostics and never presents an invalid file as a completed delivery.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-078 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
