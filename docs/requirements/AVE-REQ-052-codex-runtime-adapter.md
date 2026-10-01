---
id: AVE-REQ-052
title: Codex runtime adapter
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
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-052.md
---

# AVE-REQ-052 — Codex runtime adapter

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-011 — Providers and downloadable models](AVE-FEAT-011-providers-and-downloadable-models.md). Origin clauses in the user brief:
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.

Imported from the immutable baseline [AVE-REQ-052](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-052.md) (package v1.0); primary gate M5, scope v1.

## Description
Provide a first-class optional server-side Codex integration using the current supported SDK or app-server interface and the same constrained editing tools.

## Acceptance criteria
- [ ] AC-1 The adapter starts or resumes an editing request, reports streamed progress and cancellation, and returns validated proposals.
- [ ] AC-2 It does not assume Codex is a raw language model or implement against a removed CLI command.
- [ ] AC-3 Authentication, process isolation, and writable workspace are explicitly configured and do not expose original media or unrelated files to general coding tools.
- [ ] AC-4 Contract fixtures and a documented credentialed live smoke test distinguish adapter implementation from externally verified operation.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-049 — MCP editing interface and external agent clients](AVE-REQ-049-mcp-editing-interface-and-external-agent-clients.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](AVE-REQ-050-provider-neutral-language-model-adapters.md)
- [AVE-REQ-056 — Tool authorization and credential boundaries](AVE-REQ-056-tool-authorization-and-credential-boundaries.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-052 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
