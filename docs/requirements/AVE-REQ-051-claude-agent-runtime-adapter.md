---
id: AVE-REQ-051
title: Claude Agent runtime adapter
type: functional
status: ready
priority: must
parent: AVE-FEAT-011
source: human
scope: v1
primary_gate: M5
origins: [U25]
dependencies: [AVE-REQ-049, AVE-REQ-050, AVE-REQ-056]
scenarios: [AT-24, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-051.md
---

# AVE-REQ-051 — Claude Agent runtime adapter

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-011 — Providers and downloadable models](AVE-FEAT-011-providers-and-downloadable-models.md). Origin clauses in the user brief:
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.

Imported from the immutable baseline [AVE-REQ-051](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-051.md) (package v1.0); primary gate M5, scope v1.

## Description
Provide a first-class optional server-side Claude Agent integration using the currently supported Claude Agent SDK and a constrained editor tool surface.

## Acceptance criteria
- [ ] AC-1 Treat Claude Code or Claude Agent as an agent runtime, not a model ID or an OpenAI-compatible endpoint.
- [ ] AC-2 The adapter can start or resume a scoped editing request, stream progress, return a proposal, and cancel using supported SDK mechanisms.
- [ ] AC-3 Credentials and product authentication use supported provider mechanisms; do not copy developer-session tokens or assume a Claude subscription authorizes an embedded application.
- [ ] AC-4 Without the required installation or credentials, expose an actionable unavailable state and retain external MCP and other provider paths; do not label a stub verified.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-049 — MCP editing interface and external agent clients](AVE-REQ-049-mcp-editing-interface-and-external-agent-clients.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](AVE-REQ-050-provider-neutral-language-model-adapters.md)
- [AVE-REQ-056 — Tool authorization and credential boundaries](AVE-REQ-056-tool-authorization-and-credential-boundaries.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-051 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
