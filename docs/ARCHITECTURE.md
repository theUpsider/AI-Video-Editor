# Architecture

**Status:** placeholder — no technology is selected yet. The `technical-foundation` skill
([SKILL.md](../.claude/skills/technical-foundation/SKILL.md)) populates this file after product
definition; `product-definition` supplies § Architectural drivers. § Verification pipeline is
in effect now.

## Principles

1. Choose the simplest architecture that satisfies the current requirements.
2. Avoid speculative infrastructure: add a component, layer or service only when a
   requirement needs it.
3. Record every significant decision as an ADR in `docs/decisions/`
   ([format](decisions/README.md)) and link it here. This file describes the current
   architecture; ADRs record why it looks this way.
4. Update this file in the same commit as any change that alters the architecture, and delete
   obsolete content. `architecture-review`
   ([SKILL.md](../.claude/skills/architecture-review/SKILL.md)) checks for drift at every
   milestone review.

## Overview

_TBD: three to five sentences — architectural style, main components, and how a core user journey flows through them._

## Architectural drivers

_TBD: populated by product-definition. One bullet per quality attribute, constraint or risk that shapes the design, with its source (`GOAL-NNN`, `REQ-NNN` or `ASM-NNN`)._

## System context

_TBD: users, the system, external systems and the data flowing between them, with a diagram in a fenced code block (Mermaid or ASCII)._

## Components and boundaries

_TBD: one subsection per component — responsibility, owned data, public interface, allowed dependencies. State the dependency direction; components interact only through public interfaces._

## Data model and persistence

_TBD: core entities and relationships, data ownership, storage technology (ADR), schema migration approach, retention and deletion._

## Integration points

_TBD: each external service, API or library that crosses a process or network boundary — purpose, contract, failure handling, required credentials (listed in `.env.example`), ADR._

## Technology stack

Selection rules, applied by `technical-foundation`:

1. Derive technical requirements from the actual product requirements.
2. Research uncertain or fast-changing technologies first (researcher subagent): versions,
   maintenance status, licenses.
3. Select the simplest appropriate option, optimizing for correctness, maintainability,
   development speed, testability, ecosystem maturity, deployment practicality and the
   actual workload.
4. Never select a technology because it is fashionable.
5. Record each significant choice as an ADR before scaffolding.

_TBD: one row per concern (language, runtime, frameworks, storage, test tooling, build, deployment)._

| Concern | Choice | ADR |
|---|---|---|

## Cross-cutting concerns

### Security

_TBD: authentication, authorization, input validation, data protection, dependency and vulnerability scanning (as a verify.sh step)._

In effect: never commit secrets; never weaken a security check to make tests pass.

### Error handling

_TBD: error model, propagation across component boundaries, user-facing messages, retries and timeouts._

### Observability

_TBD: logging format and levels, metrics, tracing and health checks, sized to the actual deployment._

### Configuration and secrets

_TBD: configuration sources, precedence and per-environment values._

In effect: credentials come from environment variables. `.env.example` lists every variable
with placeholder values (created by `technical-foundation` when the first one is needed).
[.claude/settings.json](../.claude/settings.json) denies Claude reads of local `.env` files.

## Deployment and environments

_TBD: environments (local, CI, staging, production as needed), build artifacts, deployment procedure, per-environment configuration; decisions as ADRs._

Current: local development and CI on GitHub Actions
([verify.yml](../.github/workflows/verify.yml); [ASM-003](ASSUMPTIONS.md)).

## Testing strategy

_TBD: test levels and tools for the selected stack (unit, integration, end-to-end/smoke of core user journeys), fixtures and test data, what runs at which level, and the commands that run each level, one test file, the tests for one `REQ-NNN`, and the live-service checks._

In effect:

1. Every acceptance criterion has at least one automated test, or a documented verification
   when automation is impractical.
2. Tests carry `REQ-NNN AC-n` in their name or description (an adjacent comment when the
   framework forbids it), so `git grep -n -w --untracked "REQ-NNN"` finds them; see
   [TRACEABILITY.md](TRACEABILITY.md).
3. Tests are deterministic and run non-interactively. Fix flaky tests at the root; never
   skip them to get green.
4. `./scripts/verify.sh` runs every test level; core user journeys run as end-to-end or smoke
   tests.
5. `./scripts/verify.sh` never needs credentials or paid services. External services run on
   their fakes; live-service checks run through a separate command documented here.

## Verification pipeline

In effect since bootstrap
([ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)).

1. **Single entry point.** [scripts/verify.sh](../scripts/verify.sh) is the one command
   humans, Claude, the Stop hook and CI run. It runs every step, prints a summary, and exits
   non-zero when any step fails.
2. **Current steps.** Bootstrap checks only: "Project control files" runs
   [scripts/check-project-control.sh](../scripts/check-project-control.sh), which enforces
   document invariants (required files, agent and skill frontmatter, relative links,
   PROGRESS.md headings, requirement and ADR formats, traceability consistency). The final
   step, "Working tree unchanged by verification", fails when any step changed the working
   tree outside .gitignore-d paths, which would otherwise invalidate the Stop-gate cache.
   verify.sh prints a NOTICE until `technical-foundation` adds the stack checks.
3. **Target step order** once the stack exists: formatting check (read-only), lint, static
   analysis and security scan, type checking, unit tests, integration tests, build,
   end-to-end/smoke tests of core user journeys, other stack-specific validation.
4. **Stop gate.** [.claude/hooks/stop-verify.sh](../.claude/hooks/stop-verify.sh) runs
   verify.sh when Claude finishes a turn and the working tree differs from the last passing
   tree. A failure blocks stopping and feeds the log tail back to Claude; after
   `CLAUDE_VERIFY_MAX_ATTEMPTS` (default 3) consecutive failures the gate releases with a
   warning. `CLAUDE_VERIFY_GATE=off` disables it for humans. Results and the full log live in
   `.git/claude-verify/` (one per worktree).
5. **Session start.** [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh)
   reports the last verification result and whether it matches the current tree. Both hooks
   activate after workspace trust ([ASM-001](ASSUMPTIONS.md)) and are thin adapters over
   [scripts/lib/verify-state.sh](../scripts/lib/verify-state.sh), which holds the working-tree
   fingerprint and the state records; verify.sh uses the same fingerprint.
6. **CI.** [.github/workflows/verify.yml](../.github/workflows/verify.yml) runs
   `./scripts/verify.sh` on push, pull request and manual dispatch; `technical-foundation`
   adds toolchain setup.
7. **Rules.** verify.sh stays non-interactive, deterministic, read-only toward the working tree
   (outputs go to gitignored paths) and identical locally and in CI. Add commands only for
   selected technologies, each as a `run_step`. Never weaken, skip or suppress a check to get
   green; fix the root cause.

## Risks and technical debt

_TBD: one bullet per risk or debt item — description, impact, mitigation or follow-up (`REQ-NNN`/`ADR-NNN`), status. milestone-review updates this list._
