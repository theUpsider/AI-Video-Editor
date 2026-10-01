---
name: technical-foundation
description: Selects the simplest technology stack for the defined product and builds the technical base — technical requirements, research, stack ADRs, ARCHITECTURE.md, walking-skeleton scaffold, real checks in scripts/verify.sh and CI, .gitignore, cloud dependency setup, .env.example. Use after product-definition while docs/ARCHITECTURE.md has placeholder status, or to resume an interrupted foundation.
---

# Technical foundation

Turn the defined product into a verified technical base: a decided stack, a documented architecture, a walking skeleton running through every layer, and `./scripts/verify.sh` running real checks locally and in CI. You act as architect and tech lead. Paths are relative to the repository root.

## Rules

- Optimize every technology choice for correctness, maintainability, development speed, testability, ecosystem maturity, deployment practicality and the actual workload. Never choose a technology because it is fashionable.
- Decide what M1 needs plus what is expensive to reverse later (language, persistence model, integration boundaries). Defer every other choice to the milestone that needs it and name that milestone in ARCHITECTURE.md.
- Start from one deployable unit and one language; add a process, service or language only when a driver requires it. Prefer mature, maintained, permissively licensed tools and the ecosystem's standard formatter, linter and test runner.
- Put every external service behind an interface with a fake implementation for tests.
- Escalate only under [CLAUDE.md](../../../CLAUDE.md) § Autonomy and escalation; ADR format and acceptance per [docs/decisions/README.md](../../../docs/decisions/README.md).
- Checkpoint: after each step through step 12, keep one line in PROGRESS.md § In progress reading `technical-foundation — step <N> of 13 done — <area: ADR-NNN Proposed|Accepted|deferred to M<n>, …>`. Step 13 deletes it (an emptied section reads `None.`).
- Before ending any turn, make `./scripts/verify.sh` pass; the Stop gate runs it.

## Preconditions

1. Determine the mode; the first match wins (`grep -m1 '^\*\*Status:\*\*' docs/PRODUCT.md docs/ARCHITECTURE.md`):
   - A `technical-foundation —` line in PROGRESS.md § In progress, or ARCHITECTURE.md past `placeholder` while `scripts/verify.sh` still contains `print_stack_notice`: an interrupted run. Keep its own pending changes, skip preconditions 2–4, and resume at the step after the one that line names (default: the first step whose output is missing: ADRs after ADR-001, ARCHITECTURE.md sections, scaffold files, verify.sh steps, CI setup).
   - ARCHITECTURE.md `placeholder`: a new run; check preconditions 2–4.
   - Otherwise the stack is already selected: stop; stack changes go through a superseding ADR with the architect inside [develop](../develop/SKILL.md).
2. PRODUCT.md is `defined`. Otherwise run [product-definition](../product-definition/SKILL.md) first.
3. ROADMAP.md has M1 with `ready` requirements.
4. Commit unrelated pending work separately first (`git status --short`); `./scripts/verify.sh` passes.

## Procedure

### Step 1 — Derive technical requirements
Read only:
- PRODUCT.md § Product boundaries, § Security and privacy expectations, § Performance expectations, § Deployment assumptions;
- ARCHITECTURE.md § Architectural drivers;
- non-functional and constraint requirements: `grep -l -e '^type: non-functional' -e '^type: constraint' docs/requirements/REQ-*.md`;
- the M1 entry in ROADMAP.md and its requirement files.

Derive: delivery form and platforms; data shapes, sizes and volumes; latency and throughput budgets; long-running work; external services; security and privacy constraints; mandated technologies. Append technical drivers that are missing to ARCHITECTURE.md § Architectural drivers with their source IDs. A testable technical need no requirement covers becomes a `proposed`, `source: derived` requirement (next free ID per [docs/requirements/README.md](../../../docs/requirements/README.md); first Status line `- YYYY-MM-DD — proposed — technical need derived by technical-foundation (lead)`). List it in an existing parent: the FEAT it serves, or the EPIC for a cross-cutting non-functional requirement. Place it in the ROADMAP.md milestone that needs it, ahead of its dependents in that milestone's dependency order, and add one Re-planning log row for the batch. When it lands in M1, refine it to the Definition of Ready now and record the `ready` transition. An unverifiable premise becomes an `ASM-NNN`.

### Step 2 — List the decisions
Consider each area; drop those the product does not need:
1. Delivery form and runtime topology.
2. Language and runtime.
3. Application frameworks (interface, server), only where needed.
4. Persistence and data model.
5. Domain processing libraries and tools (for example media processing).
6. External services and their integration boundaries (for example AI providers).
7. Test tooling per level: unit, integration, end-to-end or smoke.
8. Quality tooling: formatter, linter, static analysis and security scan, type checker.
9. Build, packaging and dependency management (lockfiles).
10. Deployment target and CI toolchain.

Mark each **needed now** (M1 depends on it, or reversal is expensive) or **deferred** (milestone and trigger).

### Step 3 — Research in parallel
Spawn one `researcher` subagent per needed-now area involving fast-changing technology (frameworks, AI services, media tooling, deployment platforms), all in one message so they run in parallel. Give each: the question, the decision it feeds, the criteria from § Rules, constraints with requirement IDs, candidate options if any, and the currency checks to make (latest stable version and date, maintenance activity, license, known vulnerabilities, platform support). Decide stable, well-understood areas without research. Keep only the conclusions in your context.

### Step 4 — Architect proposes the stack
Spawn the `architect` with the drivers, the technical requirements, the research conclusions and the decision list. Ask for: the simplest coherent stack covering every needed-now decision, the components and boundaries M1 needs, the walking-skeleton slice through them, the main risks, and one Proposed ADR draft per significant decision. Significant here means: runtime topology, language and runtime, each major framework, persistence, each external-service boundary, the test and quality toolchain (one ADR for the whole tool set), deployment. Trivial choices get no ADR. Each Context cites drivers and IDs; Alternatives considered states why each option lost on the criteria.

### Step 5 — Accept the decisions
For each Proposed draft:
1. Check it against the drivers and criteria, and challenge complexity: does a simpler option meet the same requirements?
2. When it meets an escalation criterion (genuinely irreversible, materially changes the product, paid vendor lock-in, licensing cost): keep it Proposed, queue one batched question with your recommended default, and continue behind an interface with a fake, built for that default. A reversible choice that only needs accounts or credentials the human must create needs no decision from the human: accept the ADR and request the credentials in step 11.
3. Otherwise set `Accepted — YYYY-MM-DD`, add the index row in docs/decisions/README.md, and mark assumptions the ADR replaces `superseded` with a link.

### Step 6 — Fill ARCHITECTURE.md
1. Replace the Status line with `**Status:** current — stack selected YYYY-MM-DD.`
2. Fill Overview, System context (diagram in a fenced block), Components and boundaries (dependency direction; external services behind interfaces), Data model and persistence, Integration points (contract, failure handling, credentials by variable name), Technology stack (one row per concern, with its ADR), Cross-cutting concerns, Deployment and environments, Testing strategy (levels, tools, test locations, `REQ-NNN AC-n` tagging, fakes, and the commands that run each level, one test file, the tests for one `REQ-NNN` (a test-name filter, or the files `git grep -l -w --untracked "REQ-NNN" -- ':!*.md'` lists when tags sit in comments), and the separate live-service checks of step 11).
3. Add `### Local development` under Deployment and environments: the setup and run commands, plus `./scripts/verify.sh` as the full check (targeted test commands live in § Testing strategy). Implementers, worktrees, the cloud setup and milestone-review's journey walk use it; README.md points to it in one line.
4. Replace every `_TBD` line; a deferred concern reads `Deferred to M<n> — <trigger>`.
5. Run `./scripts/verify.sh`, inspect `git diff`, and commit `docs: select technology stack (ADR-NNN–ADR-NNN)`: ADRs, index, ARCHITECTURE.md, requirements created in step 1 and their parents, ROADMAP.md, assumptions, README.md, PROGRESS.md.

### Step 7 — Scaffold the walking skeleton
The skeleton is M1's first requirement(s): the thinnest slice of a core journey through every layer.
1. Set M1 to `in-progress` in ROADMAP.md and PROGRESS.md § Current milestone. Record each skeleton requirement's transition to `in-progress` per [develop](../develop/SKILL.md) § Recording a transition.
2. Create the project structure from § Components and boundaries, with dependency manifests, lockfiles and pinned versions.
3. Implement the skeleton yourself through [implement-requirement](../implement-requirement/SKILL.md); its structure shapes every later file.
4. Write one real test per chosen test level (unit, integration, end-to-end or smoke), each exercising skeleton behavior and tagged `REQ-NNN AC-n`. Never add placeholder or always-passing tests.
5. Code external services against their interface; tests and verify.sh use the fake.

### Step 8 — Wire real checks into scripts/verify.sh
1. Between the "Project control files" step and the final "Working tree unchanged by verification" step, add one `run_step "<name>" <command…>` per check, in this order: formatting check (read-only), lint, static analysis and security scan, type checking, unit tests, integration tests, build, end-to-end or smoke tests of key journeys, other stack-specific validation. Omit a level only when the stack has nothing for it.
2. Keep every step non-interactive, deterministic and read-only toward the working tree: check modes only, no auto-fix, no lockfile rewrites. Build output, test reports, coverage, screenshots and rendered media go to directories you add to .gitignore now; the final "Working tree unchanged by verification" step fails on anything else. Keep that step last. A step that needs the running app starts it on a free ephemeral port with per-run temporary directories and database names, never reuses a server that is already running, and stops it itself, so parallel implementers can run verify.sh concurrently in sibling worktrees. A missing tool fails its step with an install hint; never skip a step silently.
3. Scope every step to the main checkout: configure each tool's file discovery (formatter ignore file, linter ignores, static analysis, type-checker include, test-runner include and exclude, coverage, build inputs) to exclude `.claude/worktrees/`, where the linked worktrees of parallel implementers live. Many tools ignore `.gitignore` by default (for example ESLint flat config, Jest and Vitest).
4. Delete the bootstrap NOTICE, update the header comment to list the current steps, and list them in ARCHITECTURE.md § Verification pipeline (Current steps).
5. Keep the full run within a few minutes; the Stop gate runs it whenever the tree changed.
6. Prove each step can fail: break one thing per step (a formatting violation, a failing assertion), confirm verify.sh exits 1 and names the step, revert, confirm it passes.
7. Prove the exclusion: `git worktree add --detach .claude/worktrees/probe`, add a failing test and a lint violation inside it, confirm `./scripts/verify.sh` still passes, then `git worktree remove --force .claude/worktrees/probe`.

### Step 9 — CI
In `.github/workflows/verify.yml`, replace the toolchain placeholder comment with setup steps: official setup actions at their current major versions (confirm on their release pages), dependency caching, a locked install. Keep the triggers, `permissions: contents: read`, the timeout and the final `./scripts/verify.sh` step. CI installs; verify.sh only checks.

### Step 10 — Repository hygiene and environment
1. `.gitignore`: add dependency directories, build output, caches, coverage reports, generated media and render outputs, and large local sample files that are not committed fixtures. Keep the existing entries: `.claude/worktrees/` and the environment files `.env`, `.env.local` and `.env.*.local`, which mirror the `Read` deny rules in `.claude/settings.json`. When the stack reads another environment file that can hold secrets (for example `.env.production` or `app/.env`), add its ignore entry and a matching `Read(./<path>)` deny rule in the same commit, so every ignored environment file is also read-denied. Keep `.env.example` tracked and readable. Never ignore lockfiles.
2. Cloud dependency installation: cloud sessions start in a fresh container. When the project needs installed dependencies, add an install block to `.claude/hooks/session-start.sh`, guarded by `[ "${CLAUDE_CODE_REMOTE:-}" = "true" ]`. Make it idempotent, non-interactive and locked; send its output to stderr (stdout enters Claude's context); print one stdout line with the result (and the failed command on failure); keep the script exiting 0. Run the block in its own subshell `( … )` and bound the install with `timeout <seconds>` well under the SessionStart hook timeout (600 s by default; when a cold install needs longer, add `"timeout": <seconds>` to the SessionStart entry in `.claude/settings.json`), so a slow or broken install never suppresses the Project state block. On timeout print `Dependency install: timed out after <N> s (<command>)`.
3. Optional formatter hook, only when the formatter is fast (well under a second per file) and deterministic: add `.claude/hooks/format-file.sh`, which reads `tool_input.file_path` from the PostToolUse JSON with grep and sed (no jq), formats that one file when it lies inside the project and matches the formatter's file types, and always exits 0. Register it in `.claude/settings.json` under `PostToolUse` with matcher `Edit|Write`. The read-only format check in verify.sh remains the gate.
4. When you add a file other files depend on (a hook script, a settings reference), add it to the required-file list in `scripts/check-project-control.sh`.
5. Permission rules: add `permissions.allow` entries to `.claude/settings.json` for the exact read-only test and check commands that `docs/ARCHITECTURE.md` § Testing strategy names for targeted runs (for example `Bash(<test runner> *)`), so the reviewer, tester and implementer run targeted tests without permission prompts. Allow only commands that run checks or tests; never allow broad prefixes such as `npm run *`, or install, migrate, deploy or publish commands. Keep the existing allow and deny entries.

### Step 11 — Credentials
1. Add every credential and environment value to `.env.example`: variable name, placeholder value, and a comment with purpose, where to obtain it, required scopes, and the requirement that needs it. Never write a real value.
2. Code reads them from the environment and fails with a message naming the missing variable when a feature needing it runs.
3. Tell the human exactly what is needed, in one batched message with any escalated decisions: variable name, purpose, how to obtain it, where it goes (local `.env`, CI secret, cloud environment settings). Record it in PROGRESS.md § Blockers only for work that fakes cannot carry.
4. Continue all work on fakes. verify.sh never needs credentials; live-service checks run through a separate command documented in ARCHITECTURE.md § Testing strategy.

### Step 12 — Finish the skeleton requirements
Take each skeleton requirement through [develop](../develop/SKILL.md) §§ 6–8: `./scripts/verify.sh`, `verify-requirement`, repair on FAIL, then evidence, traceability, status `done` and progress on PASS. Commit in step 13.

### Step 13 — Record and commit
1. ASSUMPTIONS.md: new assumptions (toolchain versions, environments); assumptions replaced by ADRs set to `superseded`.
2. PROGRESS.md: M1 `in-progress`, objective, decisions (ADR list), blockers, verification status.
3. Run `./scripts/verify.sh`; inspect `git status` and `git diff`.
4. Delete the `technical-foundation —` line from PROGRESS.md § In progress and commit at once, so an interrupted run never loses its checkpoint before the commit. Commit the skeleton and its toolchain as one coherent unit, since each needs the other: `REQ-NNN: <imperative summary>` (several: `REQ-NNN, REQ-NNN: …`) with manifests, configuration, code, tests, verify.sh, CI, .gitignore, hooks, .env.example, evidence, traceability and progress.
5. After the next push, check the CI run; when it is green, set ASM-003 to `confirmed`.

## Exit criteria

- [ ] Every needed-now decision has an Accepted ADR, or a Proposed ADR awaiting an escalated answer while work continues on fakes.
- [ ] ARCHITECTURE.md has no placeholder line (`grep -n '^_TBD' docs/ARCHITECTURE.md` prints nothing); every deferral names its milestone.
- [ ] verify.sh runs real checks in the required order, prints no bootstrap NOTICE, passes, was shown to fail, ignores `.claude/worktrees/`, and runs safely in parallel worktrees.
- [ ] CI sets up the toolchain and runs `./scripts/verify.sh`.
- [ ] The skeleton requirements are `done`, with one real test per chosen test level.
- [ ] `.gitignore`, `.env.example` (when credentials exist) and the cloud install block (when dependencies exist) are in place.
- [ ] ROADMAP.md, PROGRESS.md, ASSUMPTIONS.md and TRACEABILITY.md are current and committed.
- [ ] Every requirement created here is listed by its parent and placed in a ROADMAP.md milestone with a Re-planning log row; those in M1 are `ready` or later.

Then continue with [develop](../develop/SKILL.md) for the rest of M1.
