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
- Built-in FFmpeg hardware encoders without a device → reported as no accelerator (AC-1): the probe prints
  `accelerator: none (no device)` whenever no device node exists and `nvidia-smi` reports no GPU.
- No `claude` command where the probe runs (the development container) → reported as not installed; the
  version row comes from `claude --version` on the host (AC-1).
- A deny rule of the project settings → recorded as enforced only after an attempted denied command was
  refused (AC-1).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/tests/test-probe-environment.sh` runs `scripts/probe-environment.sh` and checks its measurements: CPUs equal `getconf _NPROCESSORS_ONLN`, memory in GiB, disk, the accelerator verdict (`accelerator: none (no device)` without a device node and `nvidia-smi`; present with a device node), the Claude Code version (reported when `claude` is on PATH, "not installed" otherwise), the OS user and repository writability, credential variables by name only, offline network handling. The Claude Code rows of `docs/ENVIRONMENT_CAPABILITIES.md` are observations a shell cannot make, inspected against the session: workflow tool, subagents, worktrees, hooks, permissions (permission mode, project allow and deny rules with a denied rule checked by an attempted command, launcher-level settings, OS user and writability, sandbox and network) and models (how the session's model and the default model of subagent and workflow runs are observed, which overrides the Agent and Workflow tools accept, checked by a run).
- AC-2 — inspection — completed workflow runs with structured handbacks and dependency-aware parallelism: M0 build workflow `wf_5493b930-f7c` (two writers; integrated as `486b3a0`, `24499a6`), review workflow `wf_1a23bf0d-2a0` (three lenses, adversarial refutation; PASS), persisted briefs in `docs/briefs/`; only a run of the real runtime can show this.
- AC-3 — inspection — every workflow script used here ran on the installed runtime (run IDs above); no API outside the runtime's documented hooks.
- AC-4 — inspection — CLAUDE.md § Delegation and `.claude/skills/ai-video-editor-delivery/SKILL.md` describe the subagent and sequential fallback; WF-002 records a real fallback (the lead finished an interrupted task sequentially).
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/ENVIRONMENT_CAPABILITIES.md` — measured capabilities and limits of the environment, including the Permissions and Models rows and the external gaps with their unblock actions (AC-1)
- `scripts/probe-environment.sh` — repeatable probe of the shell-observable environment: resources, accelerator verdict from device nodes, Claude Code version, OS user and repository writability; never prints credential values (AC-1)
- `.claude/skills/resume-project/SKILL.md` step 6 — re-probes at every resume and updates ENVIRONMENT_CAPABILITIES.md when a value differs (AC-1)
- `docs/WORKFLOW_LOG.md` (operating baseline, WF-001–WF-004), `docs/briefs/` — workflow composition, handoffs and measured behavior (AC-2, AC-3)
- `CLAUDE.md` § Delegation, `.claude/skills/ai-video-editor-delivery/SKILL.md` — bounded subagent/sequential fallback (AC-4)
- Tests: `scripts/tests/test-probe-environment.sh` — AVE-REQ-094 AC-1
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md), [ASM-006](../ASSUMPTIONS.md)

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-02 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-02 — in-progress — M0 delivery-process gates implemented; criterion evidence under review (lead)
- 2026-10-02 — in-progress — verification levels recorded per criterion; AT-29/AT-30 run at the final review (lead)
- 2026-10-02 — verification — implementation evidence complete; independent verification requested (lead)
- 2026-10-02 — in-progress — verify-requirement FAIL at `4d9ef9a` (workflow `wf_b0c34bba-a20`); blocking findings and fixes in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) (lead)
