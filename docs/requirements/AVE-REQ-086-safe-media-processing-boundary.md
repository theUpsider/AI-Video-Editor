---
id: AVE-REQ-086
title: Safe media processing boundary
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: derived
scope: v1
primary_gate: M7
origins: [D04]
dependencies: [AVE-REQ-002, AVE-REQ-048]
scenarios: [AT-20, AT-23]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-086.md
---

# AVE-REQ-086 — Safe media processing boundary

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d04) — Derived security requirement: untrusted-media boundaries, least privilege, protected credentials, and private-by-default processing.

Imported from the immutable baseline [AVE-REQ-086](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-086.md) (package v1.0); primary gate M7, scope v1.

## Description
Process uploaded media and images as untrusted input with constrained subprocesses, paths, protocols, and resource usage.

## Acceptance criteria
- [ ] AC-1 Build subprocess argument arrays without shell interpolation; validate or safely serialize any generated filter expressions.
- [ ] AC-2 Prevent path traversal, symlink escape, decompression/resource abuse, unapproved protocols, and unauthorized network fetches.
- [ ] AC-3 Use supported patched dependencies, per-job working directories, timeouts, cancellation, and least-privilege workers.
- [ ] AC-4 Security tests cover malicious filenames, overlay text, project bundles, subtitles, and oversized or malformed media.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-002 — Collection-based batch ingestion](AVE-REQ-002-collection-based-batch-ingestion.md)
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-086 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20), [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
