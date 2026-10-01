---
id: AVE-REQ-051
title: "Claude Agent runtime adapter"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-011
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U25"]
dependencies: ["AVE-REQ-049", "AVE-REQ-050", "AVE-REQ-056"]
scenarios: ["AT-24", "AT-20"]
---

# AVE-REQ-051 - Claude Agent runtime adapter

## Requirement

Provide a first-class optional server-side Claude Agent integration using the currently supported Claude Agent SDK and a constrained editor tool surface.

## Acceptance criteria

- [ ] **AC-1:** Treat Claude Code or Claude Agent as an agent runtime, not a model ID or an OpenAI-compatible endpoint.
- [ ] **AC-2:** The adapter can start or resume a scoped editing request, stream progress, return a proposal, and cancel using supported SDK mechanisms.
- [ ] **AC-3:** Credentials and product authentication use supported provider mechanisms; do not copy developer-session tokens or assume a Claude subscription authorizes an embedded application.
- [ ] **AC-4:** Without the required installation or credentials, expose an actionable unavailable state and retain external MCP and other provider paths; do not label a stub verified.

## Dependencies

[AVE-REQ-049](AVE-REQ-049.md); [AVE-REQ-050](AVE-REQ-050.md); [AVE-REQ-056](AVE-REQ-056.md)

## Verification plan

[AT-24](../ACCEPTANCE_TESTS.md#at-24); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U25](../../intake/USER_BRIEF.md#u25). Parent: [AVE-FEAT-011](../EPICS_AND_FEATURES.md#ave-feat-011).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
