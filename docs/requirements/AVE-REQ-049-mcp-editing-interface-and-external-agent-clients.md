---
id: AVE-REQ-049
title: MCP editing interface and external agent clients
type: functional
status: ready
priority: must
parent: AVE-FEAT-010
source: human
scope: v1
primary_gate: M5
origins: [U08, U25]
dependencies: [AVE-REQ-048, AVE-REQ-056]
scenarios: [AT-16, AT-24, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-049.md
---

# AVE-REQ-049 — MCP editing interface and external agent clients

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-010 — Typed editing API and MCP](AVE-FEAT-010-typed-editing-api-and-mcp.md). Origin clauses in the user brief:
- [U08](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u08) — Expose editing capabilities through a standardized AI interface, preferably MCP or equivalent integration.
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.

Imported from the immutable baseline [AVE-REQ-049](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-049.md) (package v1.0); primary gate M5, scope v1.

## Description
Expose the supported editor operations through a standards-based MCP server so externally configured Claude Code and Codex clients can inspect and edit a project.

## Acceptance criteria
- [ ] AC-1 Provide working tool discovery, validated tool calls, concise descriptions, structured results, and references to paginated project resources.
- [ ] AC-2 Provide a local stdio connection and, when remote access is enabled, an authenticated Streamable HTTP configuration using the supported protocol/SDK version.
- [ ] AC-3 Long-running analysis and export calls return job identifiers with status and cancellation operations instead of holding a tool call open indefinitely.
- [ ] AC-4 Document and test a read -> propose -> validate -> apply -> export workflow from an MCP client; distinguish protocol-level tests from a live Claude/Codex integration test.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)
- [AVE-REQ-056 — Tool authorization and credential boundaries](AVE-REQ-056-tool-authorization-and-credential-boundaries.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-049 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-16](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-16), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
