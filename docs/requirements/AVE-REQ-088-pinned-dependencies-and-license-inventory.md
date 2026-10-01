---
id: AVE-REQ-088
title: Pinned dependencies and license inventory
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: derived
scope: v1
primary_gate: M7
origins: [D02, D04]
dependencies: [AVE-REQ-082]
scenarios: [AT-21, AT-29]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-088.md
---

# AVE-REQ-088 — Pinned dependencies and license inventory

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.
- [D04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d04) — Derived security requirement: untrusted-media boundaries, least privilege, protected credentials, and private-by-default processing.

Imported from the immutable baseline [AVE-REQ-088](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-088.md) (package v1.0); primary gate M7, scope v1.

## Description
Deliver reproducible dependency configuration and a documented inventory of software, model, codec, and font licensing considerations.

## Acceptance criteria
- [ ] AC-1 Pin supported stable dependency versions and model revisions in lockfiles or equivalent reproducible manifests.
- [ ] AC-2 Use permissively usable defaults where feasible; do not introduce paid SDKs or subscription-gated editing components without approval.
- [ ] AC-3 Document the actual FFmpeg build and enabled codecs rather than claiming all possible codec distributions have identical licensing.
- [ ] AC-4 Provide dependency-update and vulnerability-check commands and report unresolved issues honestly.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-082 — Self-hostable browser application and CPU reference setup](AVE-REQ-082-self-hostable-browser-application-and-cpu-reference-setup.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-088 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-21](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-21), [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
