---
id: AVE-REQ-054
title: AI budgets, retries, caching, and cancellation
type: functional
status: ready
priority: must
parent: AVE-FEAT-011
source: human
scope: v1
primary_gate: M5
origins: [U24, U26, D02]
dependencies: [AVE-REQ-044, AVE-REQ-050, AVE-REQ-077]
scenarios: [AT-17, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-054.md
---

# AVE-REQ-054 — AI budgets, retries, caching, and cancellation

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-011 — Providers and downloadable models](AVE-FEAT-011-providers-and-downloadable-models.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [U26](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u26) — Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-054](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-054.md) (package v1.0); primary gate M5, scope v1.

## Description
AI and media-analysis workflows shall have configurable budgets, bounded retries, caching, cancellation, and persistent stage state.

## Acceptance criteria
- [ ] AC-1 Users can bound duration, model calls, token or cost limits when available, and local concurrency; unknown costs remain labeled unknown.
- [ ] AC-2 Cache analysis by source checksum, model revision, prompt/schema version, language, and relevant settings; invalidate stale entries.
- [ ] AC-3 Retry transient failures with limits and backoff, but do not blindly repeat a mutating operation or an authorization failure.
- [ ] AC-4 Cancellation stops queued work and terminates or safely detaches active processing, preserving already accepted project edits.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-044 — Natural-language editing interface](AVE-REQ-044-natural-language-editing-interface.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](AVE-REQ-050-provider-neutral-language-model-adapters.md)
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-054 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
