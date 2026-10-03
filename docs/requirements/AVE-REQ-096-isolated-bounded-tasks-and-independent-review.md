---
id: AVE-REQ-096
title: Isolated bounded tasks and independent review
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D05]
dependencies: [AVE-REQ-094]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-096.md
---

# AVE-REQ-096 — Isolated bounded tasks and independent review

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-096](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-096.md) (package v1.0); primary gate M0, scope v1.

## Description
Delegate bounded tasks with explicit context and deliverables, using verified worktree isolation for concurrent writers and a fresh review context for acceptance.

## Acceptance criteria
- [ ] AC-1 Task briefs include requirement IDs, acceptance criteria, allowed paths, dependencies, input revision, test commands, and handback schema.
- [ ] AC-2 Initialize isolated tasks from the intended integration commit; do not assume the native worktree default matches the current branch.
- [ ] AC-3 A reviewer receives requirements and the diff rather than relying on the implementer claim of success; media-critical tests inspect real rendered outputs.
- [ ] AC-4 Respect actual concurrency and resource limits; never recursively multiply coding agents or bypass a cloud limit.

## Edge cases
- A task interrupted by a usage, session or permission limit → resumable from its persisted brief and worktree
  (AC-1, AC-2).
- A delegated task without a brief → never launched: the lead writes and commits its brief first and passes the
  path in the prompt; the skills that fork their own agent (`verify-requirement`, `architecture-review`) take
  none (AC-1).
- A brief whose input revision names no commit (a branch name only) → fails check 11; a brief written before
  its starting commit exists waits in `docs/briefs/drafts/` (AC-1, AC-2).
- A handback that would live only in the session → persisted in `docs/briefs/handbacks/` and committed with
  the work; a handback named after no brief fails check 11 (AC-1).
- A worktree created from a different commit than intended → detected by the task's revision check:
  `git rev-parse HEAD` equals the base commit (an ancestor check would accept a later commit) (AC-2).
- A reviewer given only the implementer's claims → rejected; reviews start from requirements and the diff (AC-3).
- More writing agents than the measured limit → never started; the lead counts them across every workflow
  and subagent (AC-4).
- Concurrent writers → each in its own worktree; a writing task uses the main working tree only while no
  other agent writes (AC-2, AC-4).
- A second heavy media job while one runs → waits on the heavy-media lock with one waiting line and starts
  after the first ends; the fast tier takes no lock (AC-4).

## Dependencies
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/check-project-control.sh` check 11 rejects a task brief that lacks any of the seven template headings (requirements, input revision, allowed and forbidden paths, dependencies and constraints, test commands, handback schema), repeats one or breaks their order, leaves a section empty, names no AVE-REQ ID under Requirements, or names no commit under Input revision (a delimited hash of 7 to 40 hex digits, or the self-reference `git log -1 --format=%h -- <the brief's path>`), and a handback in `docs/briefs/handbacks/` named after no brief; `scripts/tests/test-checker.sh` covers each heading's absence and emptiness, the order, a repeated heading, the requirement ID, the input-revision commit (none, a branch name only, too few or too many digits, an abbreviated or full hash, the self-reference and one to another brief) and the handback names; inspection: `CLAUDE.md` § Delegation and `.claude/skills/develop/SKILL.md` § 3–5 require the committed brief before every delegated task and pass its path, the agent definitions read it first, and the content of each brief in `docs/briefs/` matches its task.
- AC-2 — integration and inspection — `.claude/settings.json` sets `worktree.baseRef: "head"` (measured in ENVIRONMENT_CAPABILITIES.md); check 11 requires a commit in each brief's input revision (`scripts/tests/test-checker.sh`); every implementer prompt has the task confirm that `git rev-parse HEAD` equals the base commit before changing anything (`.claude/skills/develop/SKILL.md` § 4, `.claude/agents/implementer.md` § Worktrees); the fix worktree started at `24499a6` as briefed.
- AC-3 — inspection — reviewers start from the requirement files, the brief and `git diff` in their own scratch copies (`.claude/skills/verify-requirement/SKILL.md`, the review prompts recorded with the workflow runs); media-critical claims were checked on real rendered outputs (three review rounds, WF-001).
- AC-4 — integration and inspection — `scripts/tests/test-verify-tiers.sh` (one heavy media job at a time): the media and release tiers hold the heavy-media lock through their steps, a second media run prints one waiting line and runs no step until the lock is released, the fast tier takes no lock, a caller holding the lock sets `AVE_HEAVY_LOCK_HELD=1` and takes no second one, the default lock file, no process a step leaves behind keeps the lock, and the media tier fails without `flock`; inspection: `.claude/skills/develop/SKILL.md` § 4 Concurrency limits (at most two writing agents counted across every workflow and subagent, plus one heavy media job; concurrent writers in worktrees), the WORKFLOW_LOG operating baseline and WF-005, no recursive agent spawning (subagents cannot spawn subagents).
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/briefs/README.md` (template, handbacks, drafts), `docs/briefs/*.md` (persisted briefs), `docs/briefs/handbacks/` (persisted handbacks), `scripts/check-project-control.sh` check 11: headings present, once and in order, sections non-empty, a requirement ID under Requirements, a commit under Input revision, handbacks named after their briefs (AC-1, AC-2)
- `CLAUDE.md` § Delegation, `.claude/skills/develop/SKILL.md` § 3–5 (brief first, handback persisted), `.claude/agents/*.md` (the brief path as the first input), `.claude/skills/ai-video-editor-delivery/SKILL.md` step 4 — every delegated task starts from a brief (AC-1)
- `.claude/settings.json` (`worktree.baseRef`), brief § Input revision, `.claude/skills/develop/SKILL.md` § 4 and `.claude/agents/implementer.md` § Worktrees (base commit confirmed by equality) (AC-2)
- `.claude/skills/verify-requirement/SKILL.md`, `.claude/agents/reviewer.md`, review rounds recorded in `docs/WORKFLOW_LOG.md` WF-001 (AC-3)
- `scripts/verify.sh` (heavy-media lock), `docs/ARCHITECTURE.md` § Testing strategy item 6, `.claude/skills/develop/SKILL.md` § 4 Concurrency limits, `CLAUDE.md` § Delegation, `docs/WORKFLOW_LOG.md` operating baseline and WF-005, `docs/ENVIRONMENT_CAPABILITIES.md` § Limits (AC-4)
- Tests: `scripts/tests/test-checker.sh` — AVE-REQ-096 AC-1, AVE-REQ-096 AC-2; `scripts/tests/test-verify-tiers.sh` — AVE-REQ-096 AC-4
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md)

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
