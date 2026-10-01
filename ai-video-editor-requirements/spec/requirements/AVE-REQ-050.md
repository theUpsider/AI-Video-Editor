---
id: AVE-REQ-050
title: "Provider-neutral language-model adapters"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-011
epic: AVE-EPIC-05
primary_gate: M5
origins: ["U25", "U26"]
dependencies: ["AVE-REQ-048"]
scenarios: ["AT-24", "AT-14"]
---

# AVE-REQ-050 - Provider-neutral language-model adapters

## Requirement

The runtime shall support configurable Anthropic and OpenAI-compatible endpoints through explicit provider capabilities rather than one hard-coded model.

## Acceptance criteria

- [ ] **AC-1:** Users configure server-side credentials, endpoint, model ID, and capability settings; a bounded connection test reports actual support.
- [ ] **AC-2:** Handle differences in tool calling, structured output, vision, streaming, timeouts, and context limits instead of assuming all OpenAI-compatible servers behave identically.
- [ ] **AC-3:** Text-only models remain usable for transcript-grounded editing; absent capabilities are clearly disabled or routed to another selected provider.
- [ ] **AC-4:** Use an available account-configured model by default; do not depend on a model name or subscription entitlement that has not been verified.

## Dependencies

[AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-24](../ACCEPTANCE_TESTS.md#at-24); [AT-14](../ACCEPTANCE_TESTS.md#at-14). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U25](../../intake/USER_BRIEF.md#u25); [U26](../../intake/USER_BRIEF.md#u26). Parent: [AVE-FEAT-011](../EPICS_AND_FEATURES.md#ave-feat-011).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
