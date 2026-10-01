# Claude Code implementation workflow

## Contents

- Environment audit and authority
- Dynamic task execution
- Verification and hooks
- Controlled self-improvement
- Context, budgets, and resumption
- Handover contract

## Environment audit and authority

Use the already-bootstrapped repository. Do not replace its `CLAUDE.md`, agents, skills, hooks, or documentation wholesale. Read the active repository rules and integrate missing product-specific guidance. Keep this package immutable and map AVE-REQ IDs to working files.

Create `docs/ENVIRONMENT_CAPABILITIES.md` with actual observations: tool/workflow support; current runtime/model choices; subagents and writer isolation; installed language tools and FFmpeg codecs; browser automation; CPU/RAM/disk; device access; network allowlists; secrets/credentials availability; and cloud process/command limits. Do not print secret values. Report the installed version and tested behavior rather than infer availability from a website.

Anthropic documents native dynamic workflows, isolated subagents, skills, and hooks [SRC-01 through SRC-05]. Availability and configuration still need checking in this particular cloud session [SRC-07]. This package deliberately does not ship speculative workflow API calls or assume a specific paid model.

## Dynamic task execution

The lead owns product coherence, requirements, architecture, integration, and final truthfulness. It may implement small work directly. Use a workflow only when it improves isolation or throughput; not every function edit needs several agents.

For each ready requirement or tightly coupled group:

1. Read only the relevant requirement files, dependencies, code, timing/API contracts, and known failures.
2. Choose a small task graph: direct implementation, research then implement, parallel independent modules, or competing diagnostic hypotheses for a difficult bug.
3. Keep the test oracle/acceptance constraints fixed. Assign critical timing/media checks to a reviewer who did not generate the implementation.
4. Give each task bounded inputs, allowed paths, dependencies, tests, resource limits, and a structured handback.
5. Implement and run focused checks. Merge only from the intended base revision; test integrated behavior again.
6. Record criterion-level evidence, update traceability/progress, commit a coherent unit under repository policy, and select the next unblocked task.

### Native workflows

When the current tool surface supports native dynamic workflows, ask Claude Code to build a task-specific workflow and use its actual documented runtime. Start with a small non-destructive smoke test. Let it orchestrate bounded subagents and structured results, with dependency barriers before integration and independent acceptance review. Save only reusable workflow patterns that have proved useful.

Do not hard-code JavaScript helpers, option names, model names, global directories, nesting rules, or unlimited continuation behavior based on an older example. Check the available tool schema or installed official documentation. Use model choices available in the account; select more reasoning capacity for time-model/architecture/security work and lower-cost capacity only where measured results remain adequate.

### Fallback

If native workflows are not available, run the same lifecycle using existing subagents or sequential execution. Initially allow at most two concurrent code-writing tasks and one media-heavy job, reducing this when the actual environment allows less. Increase only after observing isolation, resource headroom, test stability and quota behavior. Read-only reviews need not create extra worktrees.

No separate homegrown CEO/PM/agent orchestration service is required. Do not build that instead of the video editor. Do not bypass cloud concurrency or permission limits.

### Task handback

Use a concise structure such as:

```json
{
  "requirement_ids": ["AVE-REQ-024"],
  "base_revision": "record-the-real-integration-commit",
  "changed_paths": [],
  "criteria_results": [],
  "commands_run": [],
  "artifact_paths": [],
  "unresolved_findings": [],
  "status": "implemented_not_yet_independently_verified"
}
```

The handback is an example schema, not permission to claim commands were executed. Reviewers inspect actual diffs, fixture outputs and logs.

## Verification and hooks

Evolve the bootstrap's verification entry point into three useful tiers:

- Fast: schemas, formatting/lint/type checks, small unit/contract checks and changed-component tests.
- Media integration: real small renders, known-offset/drift tests, caption timing, composition boundaries and browser journeys.
- Release: all required checks, output matrix, security/resource/recovery tests, full clause coverage, and separately reported live provider/device checks.

Keep a documented `./scripts/verify.sh` entry point, with an explicit full/release mode if needed. Bootstrap file-existence checks must never masquerade as product success. CI should independently run applicable verification; prompt instructions are not enforcement.

Use supported hooks only after validating their schema and a small observed trigger. Avoid a Stop hook that re-renders the whole project on every conversational reply or blocks forever on unavailable credentials. Handle stop-hook reentry, bounded retries and genuine external blockers. A final status must be able to report failure honestly without a hook forcing an endless attempt.

Tie reports to a code/tree fingerprint, fixture/config hashes and environment. Any relevant source/test/schema change invalidates stale results. Add failure injection: break one expected result and demonstrate that the gate fails. Test the tester, not just the application.

## Controlled self-improvement

Self-improvement means improving **how the coding agent works**, not changing the product definition until its code appears correct, and not enabling the application to rewrite itself in production.

After repeated concrete failures or a milestone, record a small retrospective in `docs/WORKFLOW_LOG.md`:

```text
Observed failure and evidence
Root-cause hypothesis
One proposed workflow/skill/context change
Expected metric and fixed evaluation set
Independent review result
Measured before/after result
Keep or revert, with reason
```

Useful changes include narrower task scope, a better source-time fixture, a targeted media-debugging skill, fewer parallel encoders, smaller context bundles, or a reliable setup check. Preserve failing examples as regression fixtures and use separate held-out scenarios to avoid merely optimizing to one test.

Workflow changes can update repository-local skills, task templates and test scheduling after review. They must not reduce acceptance coverage, loosen tolerances, rewrite golden expectations to match a bug, hide exceptions, disable security rules, demote requested features, broaden permissions, or introduce paid dependencies without authorization. If a test oracle is demonstrably wrong, document the independent evidence and obtain review rather than silently rewriting it.

Keep the improvement cycle proportionate. One useful validated adjustment is better than a large untested agent hierarchy. Discard obsolete instructions and duplicate skills rather than endlessly appending them to `CLAUDE.md`.

## Context, budgets, and resumption

Keep `CLAUDE.md` short: authority links, invariants, verified commands and escalation rules. Detailed procedures live in skills/references and project files. A working requirement file must say what remains unverified, not just what code was written.

Persist the active objective, task dependency state, current branch/commit, test failures, provider/device gaps and next exact action in `docs/PROGRESS.md`. Store only bounded redacted logs and artifact references; do not put entire transcripts, binaries or every FFmpeg log into the lead context.

Use bounded retries and adapt task size after repeated failure. For media timing, compare independent hypotheses against fixed fixtures rather than repeatedly rewriting the renderer. Respect existing account budgets. Do not invent unlimited tokens, runtime, GPU resources, internet access, credentials or always-running background sessions.

On compaction or restart: read the repository rules, progress, current milestone and affected requirements; inspect Git state and current checks; resume the next unblocked unit. At a genuine external/session limit, commit or otherwise safely checkpoint allowed work, report the exact blocked action and leave a concise resume instruction. Do not say unfinished work is still running after the session stops.

## Handover contract

Give a working run path, real-media demo evidence, tested commands, requirement/criterion results and explicit gaps. Distinguish product feature implemented, contract tested, actually live tested, and externally unverified. A screenshot of a UI is not an export test; a valid render is not proof that conversational editing works; a CPU test is not a GPU test.

Continue past early milestones while work is unblocked. Stop only at the full applicable release gate or a genuine boundary, never merely because the scaffold or first split-screen demo looks plausible.
