---
id: AVE-REQ-056
title: Tool authorization and credential boundaries
type: functional
status: ready
priority: must
parent: AVE-FEAT-012
source: human
scope: v1
primary_gate: M5
origins: [D04, U08, U25]
dependencies: [AVE-REQ-048, AVE-REQ-087]
scenarios: [AT-20, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-056.md
---

# AVE-REQ-056 — Tool authorization and credential boundaries

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-012 — AI trust and tool authorization](AVE-FEAT-012-ai-trust-and-tool-authorization.md). Origin clauses in the user brief:
- [D04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d04) — Derived security requirement: untrusted-media boundaries, least privilege, protected credentials, and private-by-default processing.
- [U08](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u08) — Expose editing capabilities through a standardized AI interface, preferably MCP or equivalent integration.
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.

Imported from the immutable baseline [AVE-REQ-056](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-056.md) (package v1.0); primary gate M5, scope v1.

## Description
Tool access shall be scoped by project and operation, with secrets held outside browser-visible data and project bundles.

## Acceptance criteria
- [ ] AC-1 Read, edit, render, external-analysis, and administrative capabilities are separable; project A credentials cannot edit project B.
- [ ] AC-2 Remote MCP/API access is authenticated and follows a documented transport-security deployment profile.
- [ ] AC-3 Configurable local model endpoints are supported through explicit allowlists; arbitrary media URLs cannot become an SSRF route to private services.
- [ ] AC-4 Application logs, exported projects, AI context, error messages, and browser state do not contain raw secrets.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)
- [AVE-REQ-087 — Private-by-default media and secrets handling](AVE-REQ-087-private-by-default-media-and-secrets-handling.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-056 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
