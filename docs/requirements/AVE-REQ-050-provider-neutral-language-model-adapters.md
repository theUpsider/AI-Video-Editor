---
id: AVE-REQ-050
title: Provider-neutral language-model adapters
type: functional
status: ready
priority: must
parent: AVE-FEAT-011
source: human
scope: v1
primary_gate: M5
origins: [U25, U26]
dependencies: [AVE-REQ-048]
scenarios: [AT-24, AT-14]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-050.md
---

# AVE-REQ-050 — Provider-neutral language-model adapters

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-011 — Providers and downloadable models](AVE-FEAT-011-providers-and-downloadable-models.md). Origin clauses in the user brief:
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.
- [U26](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u26) — Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.

Imported from the immutable baseline [AVE-REQ-050](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-050.md) (package v1.0); primary gate M5, scope v1.

## Description
The runtime shall support configurable Anthropic and OpenAI-compatible endpoints through explicit provider capabilities rather than one hard-coded model.

## Acceptance criteria
- [ ] AC-1 Users configure server-side credentials, endpoint, model ID, and capability settings; a bounded connection test reports actual support.
- [ ] AC-2 Handle differences in tool calling, structured output, vision, streaming, timeouts, and context limits instead of assuming all OpenAI-compatible servers behave identically.
- [ ] AC-3 Text-only models remain usable for transcript-grounded editing; absent capabilities are clearly disabled or routed to another selected provider.
- [ ] AC-4 Use an available account-configured model by default; do not depend on a model name or subscription entitlement that has not been verified.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-050 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24), [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
