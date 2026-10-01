---
id: AVE-REQ-049
title: "MCP editing interface and external agent clients"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-010
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U08", "U25"]
dependencies: ["AVE-REQ-048", "AVE-REQ-056"]
scenarios: ["AT-16", "AT-24", "AT-20"]
---

# AVE-REQ-049 - MCP editing interface and external agent clients

## Requirement

Expose the supported editor operations through a standards-based MCP server so externally configured Claude Code and Codex clients can inspect and edit a project.

## Acceptance criteria

- [ ] **AC-1:** Provide working tool discovery, validated tool calls, concise descriptions, structured results, and references to paginated project resources.
- [ ] **AC-2:** Provide a local stdio connection and, when remote access is enabled, an authenticated Streamable HTTP configuration using the supported protocol/SDK version.
- [ ] **AC-3:** Long-running analysis and export calls return job identifiers with status and cancellation operations instead of holding a tool call open indefinitely.
- [ ] **AC-4:** Document and test a read -> propose -> validate -> apply -> export workflow from an MCP client; distinguish protocol-level tests from a live Claude/Codex integration test.

## Dependencies

[AVE-REQ-048](AVE-REQ-048.md); [AVE-REQ-056](AVE-REQ-056.md)

## Verification plan

[AT-16](../ACCEPTANCE_TESTS.md#at-16); [AT-24](../ACCEPTANCE_TESTS.md#at-24); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U08](../../intake/USER_BRIEF.md#u08); [U25](../../intake/USER_BRIEF.md#u25). Parent: [AVE-FEAT-010](../EPICS_AND_FEATURES.md#ave-feat-010).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
