---
id: AVE-REQ-056
title: "Tool authorization and credential boundaries"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-012
epic: AVE-EPIC-05
primary_gate: M5
origins: ["D04", "U08", "U25"]
dependencies: ["AVE-REQ-048", "AVE-REQ-087"]
scenarios: ["AT-20", "AT-24"]
---

# AVE-REQ-056 - Tool authorization and credential boundaries

## Requirement

Tool access shall be scoped by project and operation, with secrets held outside browser-visible data and project bundles.

## Acceptance criteria

- [ ] **AC-1:** Read, edit, render, external-analysis, and administrative capabilities are separable; project A credentials cannot edit project B.
- [ ] **AC-2:** Remote MCP/API access is authenticated and follows a documented transport-security deployment profile.
- [ ] **AC-3:** Configurable local model endpoints are supported through explicit allowlists; arbitrary media URLs cannot become an SSRF route to private services.
- [ ] **AC-4:** Application logs, exported projects, AI context, error messages, and browser state do not contain raw secrets.

## Dependencies

[AVE-REQ-048](AVE-REQ-048.md); [AVE-REQ-087](AVE-REQ-087.md)

## Verification plan

[AT-20](../ACCEPTANCE_TESTS.md#at-20); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D04](../../intake/USER_BRIEF.md#d04); [U08](../../intake/USER_BRIEF.md#u08); [U25](../../intake/USER_BRIEF.md#u25). Parent: [AVE-FEAT-012](../EPICS_AND_FEATURES.md#ave-feat-012).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
