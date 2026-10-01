# Workflow log

Measured changes to how the coding agent works (AVE-REQ-095). Each entry records evidence, one change,
its evaluation and a keep/revert decision. Product requirements, acceptance criteria, tolerances, security
rules and the immutable baseline are never changed through this log
([baseline rules](../ai-video-editor-requirements/spec/AGENT_WORKFLOW.md)).

## Entry format

```text
### WF-NNN — <date> — <short title>
- Observed failure and evidence:
- Root-cause hypothesis:
- One proposed workflow/skill/context change:
- Expected metric and fixed evaluation set (plus held-out cases):
- Independent review result:
- Measured before/after result:
- Keep or revert, with reason:
```

## Operating baseline (2026-10-01)

Not an improvement entry: the measured starting point that later entries compare against.

- Orchestration: native Workflow tool (verified available); the lead writes contracts for bounded tasks with
  requirement IDs, permitted paths, test commands and a structured handback
  ([ai-video-editor-delivery](../.claude/skills/ai-video-editor-delivery/SKILL.md),
  [develop](../.claude/skills/develop/SKILL.md)).
- Concurrency: at most two concurrent writing agents plus one heavy media job (baseline rule; 2–4 agents run
  concurrently on this 4-vCPU host).
- Isolation: disjoint path ownership for concurrent writers in the main tree, or `isolation: worktree`
  (smoke-tested: worktrees branch from local HEAD).
- Verification: `./scripts/verify.sh`; independent review through `verify-requirement` (forked reviewer).

## Entries

_No entries yet._
