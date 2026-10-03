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
- Workflow tool, subagents or worktrees unavailable → documented sequential or subagent fallback (AC-4);
  without subagents the independent review runs in a fresh session (or a context holding nothing of the
  implementation work) from the repository alone, the Status log records it as a sequential review, and the
  requirement stays `verification` until that review is recorded (AC-4).
- A capability that changes between sessions (network policy, credentials, tools) → re-probed with
  `scripts/probe-environment.sh` and recorded (AC-1).
- Workflow syntax or a feature not present in the installed runtime → never assumed (AC-3).
- Built-in FFmpeg hardware encoders without a device → reported as no accelerator (AC-1): the probe prints
  `accelerator: none (no device)` whenever no device node exists and `nvidia-smi` reports no GPU.
- No `claude` command where the probe runs (the development container) → reported as not installed; the
  version row comes from `claude --version` on the host (AC-1).
- A deny rule of the project settings → recorded as enforced only after an attempted denied command was
  refused (AC-1).
- A media tool or toolchain absent from PATH → its line reads `not installed` (AC-1).
- The probe started outside the repository → the disk and Git lines still measure the repository (AC-1).
- A host that answers with any status, a 4xx or 5xx to the HEAD request included → `HTTP <code>`; no response
  within 10 s (refused, unresolved, TLS failure, timeout) → `unreachable`; the request is header-only, so a large
  body such as the pypi simple index never decides the verdict (AC-1). No `curl` → `curl not installed`;
  `--offline` → the probes are skipped and `curl` is never invoked (AC-1).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/tests/test-probe-environment.sh` runs `scripts/probe-environment.sh` from a directory outside the repository and compares these lines with values the suite measures itself in the same run: CPUs equal `getconf _NPROCESSORS_ONLN`; memory equals MemTotal of `/proc/meminfo` in GiB with one decimal; disk equals the Avail and Size fields of `df -h` on the repository, also through a fake `df` that answers differently for every other directory; the ffmpeg, ffprobe, python3, uv and git lines equal the first line of their own version output, read `not installed` when hidden from PATH and follow a fake placed first on PATH; `PLAYWRIGHT_BROWSERS_PATH` reads `unset`, or its directory with the directory's entries listed; a browser binary on PATH (fake `chromium` and `google-chrome`) is reported with the first line of its `--version`; the worktree count and branch equal `git worktree list | wc -l` and `git rev-parse --abbrev-ref HEAD`, for the repository and for a fixture repository with three worktrees; the accelerator verdict (`accelerator: none (no device)` without a device node and `nvidia-smi`; present with a device node); the Claude Code version (reported when `claude` is on PATH, "not installed" otherwise); the OS user and repository writability; credential variables by name only; network: `--offline` skips the probes and never invokes `curl`, a missing `curl` reads `curl not installed`, and in two scenarios a fake `curl` with scripted answers shows that each of the seven hosts reads `HTTP <code>` for any status and `unreachable` without a response, that every request fetches no body (HEAD, a bounded range or `--max-filesize`) and carries a time limit of at most 10 s, that only the seven hosts are requested and that no credential value reaches `curl`. The probe also prints the kernel, OS and CPU model, the `/dev/nvidia*` and `/dev/dri` device lists, FFmpeg's built-in hwaccels, hardware encoders, libx264/aac and filters, and the node, pnpm and docker lines; the suite compares none of them, and they enter `docs/ENVIRONMENT_CAPABILITIES.md` by inspection of the live run. The live run (`./scripts/dev-container.sh ./scripts/probe-environment.sh`) stays outside the suite; its results are the § Network policy rows of `docs/ENVIRONMENT_CAPABILITIES.md`. The Claude Code rows of that document are observations a shell cannot make, inspected against the session: workflow tool, subagents, worktrees, hooks, permissions (permission mode, project allow and deny rules with a denied rule checked by an attempted command, launcher-level settings, OS user and writability, sandbox and network), browser tools (the browser tools the session's tool list exposes; the probe reports only browser binaries and the Playwright directory) and models (how the session's model and the default model of subagent and workflow runs are observed, which overrides the Agent and Workflow tools accept, checked by a run).
- AC-2 — inspection — completed workflow runs with structured handbacks and dependency-aware parallelism: M0 build workflow `wf_5493b930-f7c` (two writers; integrated as `486b3a0`, `24499a6`), review workflow `wf_1a23bf0d-2a0` (three lenses, adversarial refutation; PASS), persisted briefs in `docs/briefs/`; the run of [the probe-evidence brief](../briefs/2026-10-03-ave-req-094-probe-evidence.md) composes the investigation (researcher, part 1) in parallel with the testing (tester, part 2), the implementation from both structured handbacks (part 3) and the independent review, with each part's handback in `docs/briefs/handbacks/`; only a run of the real runtime can show this.
- AC-3 — inspection — every workflow script used here ran on the installed runtime (run IDs above); no API outside the runtime's documented hooks.
- AC-4 — inspection — CLAUDE.md § Delegation, `.claude/skills/develop/SKILL.md` § 6 step 3 and `.claude/skills/ai-video-editor-delivery/SKILL.md` describe the subagent and sequential fallback, including how independent review happens without subagents (a fresh session working from the repository alone, recorded as a sequential review; the requirement stays `verification` until it is recorded); WF-002 records a real fallback (the lead finished an interrupted task sequentially).
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/ENVIRONMENT_CAPABILITIES.md` — measured capabilities and limits of the environment, including the Permissions, Browser tools and Models rows, the § Network policy results of the probe's HEAD requests (2026-10-03) and the external gaps with their unblock actions (AC-1)
- `scripts/probe-environment.sh` — repeatable probe of the shell-observable environment: resources, accelerator verdict from device nodes, media tools, toolchains, browsers, the repository's disk and Git worktrees and branch from any working directory, Claude Code version, OS user and repository writability, credential variables by name, and network reachability through one HEAD request per host with a 10 s limit (`HTTP <code>` for any status, `unreachable` without a response); never prints credential values (AC-1)
- `.claude/skills/resume-project/SKILL.md` step 6 — re-probes at every resume and updates ENVIRONMENT_CAPABILITIES.md when a value differs (AC-1)
- `docs/WORKFLOW_LOG.md` (operating baseline, WF-001–WF-004), `docs/briefs/` (including `docs/briefs/2026-10-03-ave-req-094-probe-evidence.md` and its part handbacks) — workflow composition, handoffs and measured behavior (AC-2, AC-3)
- `CLAUDE.md` § Delegation, `.claude/skills/develop/SKILL.md` § 6 step 3, `.claude/skills/ai-video-editor-delivery/SKILL.md` step 6 — bounded subagent/sequential fallback, with independent review in a fresh session recorded as sequential (AC-4)
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
- 2026-10-03 — in-progress — verify-requirement PASS at `d4d3883` (workflow `wf_ed1f5104-63a`) refuted by its skeptic: the probe suite checked only headings and a number format for most AC-1 items, the pypi probe depended on bandwidth, browser tools were unrecorded at that commit, and no completed run composed the investigation and testing stages of AC-2; repair through [the probe-evidence brief](../briefs/2026-10-03-ave-req-094-probe-evidence.md), a run that composes those stages (lead)
