# ADR-001 — Specification-driven development workflow

## Status
Accepted — 2026-10-01

## Context

- Claude Code develops this repository autonomously across many sessions. The human supplies
  product goals and important constraints and expects no micromanagement.
- Conversation context ends with each session and shrinks at compaction. Product intent,
  requirements, decisions, progress and verification state must survive both.
- Completion claims need enforcement independent of model memory: deterministic verification,
  independent review, and traceability from product goals to evidence.
- At bootstrap the product and the technology stack are unknown. The workflow must fit any
  stack and rely only on baseline tooling (ASM-002 in [docs/ASSUMPTIONS.md](../ASSUMPTIONS.md)).
- Parallel subagent work must leave shared state consistent.

## Decision

Adopt a specification-driven workflow whose state lives in the repository and whose rules are
enforced by native Claude Code mechanisms, scripts and CI.

1. **Canonical state in repository-native Markdown**: [docs/PRODUCT.md](../PRODUCT.md),
   [docs/requirements/](../requirements/README.md) (epics, features, requirements),
   [docs/decisions/](README.md) (ADRs), [docs/ARCHITECTURE.md](../ARCHITECTURE.md),
   [docs/ROADMAP.md](../ROADMAP.md), [docs/PROGRESS.md](../PROGRESS.md),
   [docs/TRACEABILITY.md](../TRACEABILITY.md) and [docs/ASSUMPTIONS.md](../ASSUMPTIONS.md).
   [CLAUDE.md](../../CLAUDE.md) holds the shared rules. Git history is the audit trail;
   commits reference requirement IDs.
2. **Pipeline**: `product-definition` → `technical-foundation` → `develop` (per requirement:
   `implement-requirement` → `./scripts/verify.sh` → `verify-requirement` → evidence,
   traceability, progress → commit) → `milestone-review` (with `architecture-review`) → next
   milestone. `resume-project` runs at every session start and after compaction. A
   requirement reaches `done` only through the Definition of Done in
   [docs/requirements/README.md](../requirements/README.md).
3. **Native Claude Code mechanisms**:
   - Subagents in `.claude/agents/`: [architect](../../.claude/agents/architect.md),
     [implementer](../../.claude/agents/implementer.md),
     [reviewer](../../.claude/agents/reviewer.md), [tester](../../.claude/agents/tester.md),
     [researcher](../../.claude/agents/researcher.md).
   - Skills in `.claude/skills/`: `product-definition`, `technical-foundation`, `develop`,
     `implement-requirement`, `verify-requirement` (forked into the reviewer),
     `architecture-review` (forked into the architect), `milestone-review`, `resume-project`.
   - Hooks in [.claude/settings.json](../../.claude/settings.json): SessionStart runs
     [session-start.sh](../../.claude/hooks/session-start.sh); Stop runs
     [stop-verify.sh](../../.claude/hooks/stop-verify.sh). Both are thin adapters over
     [scripts/lib/verify-state.sh](../../scripts/lib/verify-state.sh), which verify.sh also uses.
   - Permissions in the same file: allow the verification scripts and read-only Git commands;
     deny reading `.env` files and the common force-push command forms (a guard on command text;
     CLAUDE.md § Git states the rule).
4. **Single verification entry point**: [scripts/verify.sh](../../scripts/verify.sh) runs every
   check for humans, Claude, the Stop hook and CI. Its first step,
   [scripts/check-project-control.sh](../../scripts/check-project-control.sh), enforces the
   document invariants. `technical-foundation` adds the stack checks.
5. **Stop-hook verification gate with bounded retries**: when the working tree differs from the
   last passing tree (content fingerprint in `.git/claude-verify/`), `stop-verify.sh` runs
   verify.sh. A failure blocks stopping and feeds the log tail back to Claude. After
   `CLAUDE_VERIFY_MAX_ATTEMPTS` (default 3) consecutive failures the gate releases with a
   warning. `CLAUDE_VERIFY_GATE=off` disables it for humans.
6. **SessionStart recovery context**: `session-start.sh` injects branch, HEAD, uncommitted
   paths, the last verification result, recent commits and docs/PROGRESS.md, then points
   Claude to `resume-project`.
7. **CI runs the same entry point**: [.github/workflows/verify.yml](../../.github/workflows/verify.yml)
   runs `./scripts/verify.sh` on push, pull request and manual dispatch.
8. **Worktree isolation for parallel work**: implementer subagents run with
   `isolation: worktree` on disjoint files; the lead merges each branch without committing,
   runs verify.sh and `verify-requirement`, and commits the merge only after a PASS. Worktrees
   branch from the current `HEAD` (`worktree.baseRef: "head"` in `.claude/settings.json`) and
   live under `.claude/worktrees/` (gitignored).

## Alternatives considered

- **External issue tracker as the state store**: adds an external dependency, keeps state
  outside the versioned code, and hides it from the agent when offline.
- **Database or YAML traceability store**: overkill at current scale; Markdown, IDs and grep
  cover the needs ([docs/TRACEABILITY.md](../TRACEABILITY.md) § Scale).
- **Custom orchestration daemon**: fragile and adds infrastructure to maintain; native
  subagents, skills and hooks cover orchestration.
- **Instruction-only discipline without hooks or CI**: unenforced; verification would depend
  on model memory.

## Consequences

- State is versioned with the code, reviewable in diffs and available offline to every
  session. Any session resumes from the repository alone, and the workflow fits any stack.
- The documents need upkeep. `check-project-control.sh` enforces the mechanical parts;
  `milestone-review` audits the rest.
- Strict Markdown conventions (frontmatter subset, exact headings, ID formats) bind every
  author.
- Project hooks activate only after workspace trust. Hooks created mid-session take effect
  from the next session, so the bootstrap session could not exercise them (ASM-001). Until
  they are active, CLAUDE.md instructions and CI carry the verification and recovery duties.
- The Stop gate adds verify.sh latency to turns that changed the tree; the fingerprint skips
  unchanged trees.
- Revisit this decision when requirements exceed a few hundred or several humans collaborate
  concurrently.

## Related requirements

None (process-level). Related assumptions: ASM-001, ASM-002, ASM-003 in
[docs/ASSUMPTIONS.md](../ASSUMPTIONS.md).
