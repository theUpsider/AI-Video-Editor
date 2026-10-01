---
id: AVE-REQ-048
title: One typed editing command service
type: functional
status: ready
priority: must
parent: AVE-FEAT-010
source: human
scope: v1
primary_gate: M1
origins: [U04, U08, U20, D03]
dependencies: [AVE-REQ-001, AVE-REQ-012]
scenarios: [AT-16, AT-12]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-048.md
---

# AVE-REQ-048 — One typed editing command service

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-010 — Typed editing API and MCP](AVE-FEAT-010-typed-editing-api-and-mcp.md). Origin clauses in the user brief:
- [U04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u04) — Both the user and AI can place images or text over the video for explicit start/end intervals.
- [U08](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u08) — Expose editing capabilities through a standardized AI interface, preferably MCP or equivalent integration.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-048](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-048.md) (package v1.0); primary gate M1, scope v1.

## Description
The UI, internal AI, and external integrations shall use one versioned, typed editing service with shared validation.

## Acceptance criteria
- [ ] AC-1 Support project inspection, asset search, analysis requests, timeline reads, validated batch edits, synchronization, profiles, subtitles, sections, and render-job operations.
- [ ] AC-2 Use stable identifiers, schema validation, expected revisions, idempotency keys, and structured errors.
- [ ] AC-3 Do not expose arbitrary shell commands, arbitrary filesystem writes, or raw unvalidated FFmpeg filter graphs as editing operations.
- [ ] AC-4 Unit and contract tests demonstrate that equivalent UI and AI requests yield equivalent project state.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-048 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16), [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
