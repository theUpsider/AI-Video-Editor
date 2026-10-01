---
id: AVE-REQ-094
title: "Capability-aware native dynamic workflows"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M0
origins: ["U27"]
dependencies: ["AVE-REQ-093"]
scenarios: ["AT-29", "AT-30"]
---

# AVE-REQ-094 - Capability-aware native dynamic workflows

## Requirement

Claude Code shall use task-specific native dynamic workflows where actually available, with a documented bounded fallback to subagents or sequential execution.

## Acceptance criteria

- [ ] **AC-1:** Probe the current environment for workflow tools, available models, subagents, worktree isolation, permissions, hooks, network, browser tools, CPU/RAM, and accelerator access.
- [ ] **AC-2:** When native workflows are available, compose requirement-specific investigation, implementation, testing, and independent review with structured handoffs and dependency-aware parallelism.
- [ ] **AC-3:** Validate native workflow syntax against the installed runtime; do not invent APIs or assume a published feature is enabled in this cloud session.
- [ ] **AC-4:** When unavailable, perform the same lifecycle through bounded subagent/sequential tasks; do not build a custom orchestration platform instead of the editor.

## Dependencies

[AVE-REQ-093](AVE-REQ-093.md)

## Verification plan

[AT-29](../ACCEPTANCE_TESTS.md#at-29); [AT-30](../ACCEPTANCE_TESTS.md#at-30). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
