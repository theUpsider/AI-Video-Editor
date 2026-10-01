---
id: AVE-REQ-082
title: Self-hostable browser application and CPU reference setup
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M1
origins: [U24, D02]
dependencies: []
scenarios: [AT-21, AT-23, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-082.md
---

# AVE-REQ-082 — Self-hostable browser application and CPU reference setup

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.

Imported from the immutable baseline [AVE-REQ-082](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-082.md) (package v1.0); primary gate M1, scope v1.

## Description
Deliver a working desktop-browser editor backed by a local or self-hosted media-processing service, with a documented CPU-first reference deployment.

## Acceptance criteria
- [ ] AC-1 Provide repeatable installation/start commands, persistent storage configuration, migrations, and health checks.
- [ ] AC-2 A reference Linux environment can run without Docker when cloud-development policy prevents nested containers; container deployment is also documented.
- [ ] AC-3 Do not depend on Claude Code Cloud as a permanent production host, storage service, or GPU provider.
- [ ] AC-4 Bind local-only deployments safely by default; remote exposure requires the documented authentication and transport settings.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
None.

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-082 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-21](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-21), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
