---
id: AVE-REQ-085
title: Observable jobs and reproducible diagnostics
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: derived
scope: v1
primary_gate: M7
origins: [D02]
dependencies: [AVE-REQ-077]
scenarios: [AT-17, AT-18, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-085.md
---

# AVE-REQ-085 — Observable jobs and reproducible diagnostics

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-085](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-085.md) (package v1.0); primary gate M7, scope v1.

## Description
Provide structured diagnostics that identify the state and provenance of media and AI processing without exposing secrets.

## Acceptance criteria
- [ ] AC-1 Record job ID, project revision, relevant asset IDs, engine/model versions, settings, actual device path, and redacted errors.
- [ ] AC-2 Users can inspect progress and export a redacted diagnostic report.
- [ ] AC-3 Log noisy media-process output in bounded files rather than filling the UI or agent context.
- [ ] AC-4 An exported manifest identifies enough configuration to reproduce a rendering decision on compatible software.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-085 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17), [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
