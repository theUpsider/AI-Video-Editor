---
id: AVE-REQ-080
title: Storage quotas and safe derived-file cleanup
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M7
origins: [U24, D01, D02]
dependencies: [AVE-REQ-003, AVE-REQ-077]
scenarios: [AT-22, AT-23, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-080.md
---

# AVE-REQ-080 — Storage quotas and safe derived-file cleanup

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-080](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-080.md) (package v1.0); primary gate M7, scope v1.

## Description
The application shall manage derived media storage with quotas, preflight checks, safe temporary directories, and recoverable cleanup.

## Acceptance criteria
- [ ] AC-1 Low disk space prevents unsafe work or cancels it with a clear error while preserving originals and durable edits.
- [ ] AC-2 Cache cleanup removes only identified unreferenced derived files within application-owned roots.
- [ ] AC-3 Failed or cancelled jobs clean temporary outputs without deleting unrelated files or other jobs artifacts.
- [ ] AC-4 Users can inspect media, proxy, model-cache, and render storage separately.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-003 — Immutable originals and stable asset identities](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-080 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
