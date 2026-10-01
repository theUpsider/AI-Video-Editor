---
id: AVE-REQ-083
title: Real-media automated verification suite
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M7
origins: [D03, U03, U15]
dependencies: [AVE-REQ-072]
scenarios: [AT-29, AT-04, AT-03]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-083.md
---

# AVE-REQ-083 — Real-media automated verification suite

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.
- [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03) — Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.

Imported from the immutable baseline [AVE-REQ-083](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-083.md) (package v1.0); primary gate M7, scope v1.

## Description
Implement layered automated verification with real generated media fixtures, independent expected outcomes, and traceability to acceptance criteria.

## Acceptance criteria
- [ ] AC-1 Include unit tests for time mappings, contract tests for editing tools, integration tests using the real renderer, and browser end-to-end journeys.
- [ ] AC-2 Generate small fixtures with known timestamps, event markers, audio impulses, aspect ratios, and rate/offset/drift variations.
- [ ] AC-3 At least one regression exercises approximately 2K input at 60 fps and validates actual output content and synchronization.
- [ ] AC-4 Mocks are limited to provider/network isolation and cannot alone satisfy media, AI quality, or hardware integration claims.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-083 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-04](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-04), [AT-03](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-03) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
