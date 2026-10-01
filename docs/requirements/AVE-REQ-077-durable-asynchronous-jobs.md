---
id: AVE-REQ-077
title: Durable asynchronous jobs
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M1
origins: [U22, U24, D02]
dependencies: [AVE-REQ-001]
scenarios: [AT-17, AT-23]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-077.md
---

# AVE-REQ-077 — Durable asynchronous jobs

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U22](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u22) — Support CPU-only rendering and GPU acceleration when available.
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-077](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-077.md) (package v1.0); primary gate M1, scope v1.

## Description
Import analysis, proxies, AI drafts, and exports shall run as durable jobs with observable state, bounded concurrency, cancellation, and safe retry.

## Acceptance criteria
- [ ] AC-1 Jobs have queued, running, succeeded, failed, and cancelled states, input revision, progress, timestamps, and structured failure details.
- [ ] AC-2 A process crash recovers queued work and marks interrupted work for safe restart; partially written outputs are not published.
- [ ] AC-3 Retrying a job with the same idempotency key does not duplicate an accepted project transaction or completed output.
- [ ] AC-4 Long jobs run outside HTTP request handlers and preserve a responsive application; resource limits prevent unbounded parallel encoders/models.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-077 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
