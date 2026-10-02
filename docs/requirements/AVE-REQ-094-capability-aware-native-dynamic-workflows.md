---
id: AVE-REQ-094
title: Capability-aware native dynamic workflows
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27]
dependencies: [AVE-REQ-093]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-094.md
---

# AVE-REQ-094 — Capability-aware native dynamic workflows

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.

Imported from the immutable baseline [AVE-REQ-094](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-094.md) (package v1.0); primary gate M0, scope v1.

## Description
Claude Code shall use task-specific native dynamic workflows where actually available, with a documented bounded fallback to subagents or sequential execution.

## Acceptance criteria
- [ ] AC-1 Probe the current environment for workflow tools, available models, subagents, worktree isolation, permissions, hooks, network, browser tools, CPU/RAM, and accelerator access.
- [ ] AC-2 When native workflows are available, compose requirement-specific investigation, implementation, testing, and independent review with structured handoffs and dependency-aware parallelism.
- [ ] AC-3 Validate native workflow syntax against the installed runtime; do not invent APIs or assume a published feature is enabled in this cloud session.
- [ ] AC-4 When unavailable, perform the same lifecycle through bounded subagent/sequential tasks; do not build a custom orchestration platform instead of the editor.

## Edge cases
- Workflow tool, subagents or worktrees unavailable → documented sequential or subagent fallback (AC-4).
- A capability that changes between sessions (network policy, credentials, tools) → re-probed with
  `scripts/probe-environment.sh` and recorded (AC-1).
- Workflow syntax or a feature not present in the installed runtime → never assumed (AC-3).
- Built-in FFmpeg hardware encoders without a device → reported as no accelerator (AC-1).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-094 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-02 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-02 — in-progress — M0 delivery-process gates implemented; criterion evidence under review (lead)
