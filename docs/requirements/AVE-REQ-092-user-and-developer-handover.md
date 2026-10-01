---
id: AVE-REQ-092
title: User and developer handover
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M7
origins: [U24, D02]
dependencies: [AVE-REQ-082, AVE-REQ-083]
scenarios: [AT-21, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-092.md
---

# AVE-REQ-092 — User and developer handover

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-092](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-092.md) (package v1.0); primary gate M7, scope v1.

## Description
Deliver complete instructions for operating, extending, testing, and deploying the implemented editor.

## Acceptance criteria
- [ ] AC-1 Include a quick start, example split/full/split project, provider setup, CPU/GPU configuration, subtitle/section/short export, and recovery guide.
- [ ] AC-2 Document the project schema, typed editing API, MCP setup, model registry, renderer assumptions, and known limitations.
- [ ] AC-3 Provide screenshots or a recorded walkthrough from the actual running application and generated test media, not a mock design.
- [ ] AC-4 List exact verified commands and distinguish tested features from implemented but externally unverified integrations.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-082 — Self-hostable browser application and CPU reference setup](AVE-REQ-082-self-hostable-browser-application-and-cpu-reference-setup.md)
- [AVE-REQ-083 — Real-media automated verification suite](AVE-REQ-083-real-media-automated-verification-suite.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-092 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-21](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-21), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
