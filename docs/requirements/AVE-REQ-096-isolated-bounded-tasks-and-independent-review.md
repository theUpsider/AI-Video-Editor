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
- A task the `develop` loop delegates without a brief → against the rule: the lead writes and commits its brief
  first and passes the path in the prompt. Two kinds of task take none (`CLAUDE.md` § Delegation): the skills
  that fork their own agent (`verify-requirement`, `architecture-review`), and the one-time setup skills
  `product-definition` and `technical-foundation`, which give their agents the task text the skill defines. A
  review run scripted as a workflow, its skeptic stage included, takes one (`develop` § 6). No gate sees a
  launch, so the rows of `docs/workflows/README.md` are inspected: seven review runs between 2026-10-03 and
  2026-10-06 started without a brief ([WF-008](../WORKFLOW_LOG.md)) (AC-1).
- The criteria in scope of a brief → judged by the reader of the brief: check 11 requires a requirement ID
  under Requirements and no criterion number, and one brief of 2026-10-02 names its criteria through the fix
  brief it links (AC-1, inspection).
- A brief whose input revision names no commit (a branch name only) → fails check 11; a brief written before
  its starting commit exists waits in `docs/briefs/drafts/` (AC-1, AC-2).
- A handback that would live only in the session → persisted in `docs/briefs/handbacks/` and committed with
  the work; a handback named after no brief fails check 11 (AC-1).
- A heading, a requirement ID, a commit or the only text of a section inside an HTML comment → absent for
  check 11, which removes HTML comments outside fenced blocks and code spans before it judges a section
  (AC-1, AC-2).
- Content that a Markdown renderer shows as nothing and that is no HTML comment (other raw HTML, a link
  reference definition, an empty fenced block, a character that renders blank, a thematic break) → counts as
  the text of a section for check 11, and an ID or a hash inside it counts. Check 11 reads fence lines by its
  own rule (three or more backticks or tildes behind any indentation, the closing line at most three spaces
  deeper than the opening one), which differs from CommonMark for a fence line indented four or more spaces.
  The reader of the brief judges these forms ([ASM-018](../ASSUMPTIONS.md)) (AC-1, AC-2, inspection).
- An entry of `docs/briefs/` that is neither a visible `*.md` brief, `README.md`, the directory `drafts/` nor
  the directory `handbacks/` (another extension, a hidden file, another subdirectory, a file named `drafts`, a
  directory named like a brief) → fails check 11; an entry of `handbacks/` that is hidden or is a directory
  fails too; the folder files of an operating system (`.DS_Store`, `Thumbs.db`) are passed over (AC-1).
- An input revision whose hex token is no commit → outside check 11, a syntactic rule
  ([ASM-018](../ASSUMPTIONS.md)): the reader of the brief and the task's own base check (`git rev-parse HEAD`
  equals the base commit) judge it (AC-2, inspection).
- A worktree created from a different commit than intended → detected by the task's revision check:
  `git rev-parse HEAD` equals the base commit (an ancestor check would accept a later commit, a branch-name
  check any commit); the check applies in every linked worktree, whoever created it. Three workflow runs before
  2026-10-06 confirmed the branch name only ([WF-008](../WORKFLOW_LOG.md)); Git confirms their bases (AC-2).
- A reviewer given only the implementer's claims → rejected; reviews start from requirements and the diff (AC-3).
- More writing agents than the limit of two writers → against the rule: the lead counts them across every
  workflow and subagent before a launch, and the lead's own code work (production code, tests, scripts, hooks)
  counts as one of the two. No gate sees a launch, so the records are inspected; they hold one overlap: the
  lead repaired AVE-REQ-094 code (`b4f503f`) while two writers of the first fix round worked
  ([WF-011](../WORKFLOW_LOG.md)) (AC-4, inspection).
- More reviewer clones than two → against the rule: at most two private clones exist at a time, and each
  removes its backend environment, its container and itself (`develop` § 4 Concurrency limits). The limit
  follows from the measured footprint in `docs/ENVIRONMENT_CAPABILITIES.md` § Limits that shape the plan,
  item 5; before 2026-10-07 that item let one clone at a time and three runs used two
  ([WF-011](../WORKFLOW_LOG.md)) (AC-4, inspection).
- Concurrent writers → each in its own worktree; a writing task uses the main working tree only while no
  other agent writes (AC-2, AC-4).
- A second heavy media job while one runs → waits on the heavy-media lock with one waiting line and starts
  after the first ends; the fast tier takes no lock (AC-4).
- A run started with `AVE_HEAVY_LOCK_HELD=1` → confirms that some process holds the lock and takes no second
  one. That the holder is its caller rests on the caller, as does the rule that every other heavy command runs
  under `flock`: a process that sets the variable while a stranger holds the lock overlaps with that job
  (AC-4, inspection of the commands a brief names).

## Dependencies
- [AVE-REQ-094 — Capability-aware native dynamic workflows](AVE-REQ-094-capability-aware-native-dynamic-workflows.md)

## Verification strategy
- AC-1 — integration and inspection — `scripts/check-project-control.sh` check 11 rejects a task brief that lacks any of the seven template headings (requirements, input revision, allowed and forbidden paths, dependencies and constraints, test commands, handback schema), repeats one or breaks their order, leaves a section empty, names no AVE-REQ ID under Requirements, or names no commit under Input revision (a delimited hash of 7 to 40 hex digits, or the self-reference `git log -1 --format=%h -- <the brief's path>`), and a handback in `docs/briefs/handbacks/` named after no brief; `scripts/tests/test-checker.sh` covers each heading's absence and emptiness, the order, a heading repeated at the end and directly, a section emptied by a foreign H2 or an H1, the requirement ID, the input-revision commit (none, a branch name only, too few or too many digits, an abbreviated or full hash, the self-reference, one to another brief and one followed by further path characters, a branch name that ends in hex, a hash with a suffix, a commit named under Requirements only), the handback names (part 0 and part 01 fail, part 10 passes), HTML comments (a section holding only a comment, an ID or a commit only in a comment, a heading or section text inside a multi-line comment; text beside a comment, a comment marker inside a code span and a fence marker inside a comment are read as text), the entries of `docs/briefs/` (another extension, another subdirectory, a hidden file, a file named `drafts`, a directory named like a brief; a draft and the folder files of an operating system pass) and hidden or directory entries of `handbacks/`; inspection: `CLAUDE.md` § Delegation and `.claude/skills/develop/SKILL.md` § 3–5 require the committed brief before every task the `develop` loop delegates and pass its path, the agent definitions read it first, and the content of each brief in `docs/briefs/` matches its task, the criteria in scope included (check 11 requires no criterion number).
- AC-2 — integration and inspection — `.claude/settings.json` sets `worktree.baseRef: "head"` (measured in ENVIRONMENT_CAPABILITIES.md); check 11 requires a commit in each brief's input revision (`scripts/tests/test-checker.sh`); the rule: a writer in a linked worktree confirms that `git rev-parse HEAD` equals the base commit of its prompt before changing anything (`.claude/skills/develop/SKILL.md` § 4, § Worktrees of `.claude/agents/implementer.md`, `.claude/agents/tester.md` and `.claude/agents/architect.md`). Inspection of the records, because a launch and its prompt exist only there: the prompts of `wf_164de68e-23b`, `wf_df2de811-039` and `wf_d57d9cab-829` confirmed the branch name ([WF-008](../WORKFLOW_LOG.md)), the prompts of the fix run of [the final-review fix brief](../briefs/2026-10-06-m0-final-review-fixes.md) carry the equality line, and Git confirms the base of every task branch: the first commit of each has the briefed commit as its parent (`548c8ca` on `24499a6`, `90a1f2e` on `548c8ca`, `dc89da2` on `90a1f2e`, `fb61875` on `6736401`, `9be8ef5` on `6736401`, `49ecb21` on `4e607de`, `6ee69da`, `faa9efb` and `9da0ea9` on `41973c5`, `574cc37`, `61b5ae4`, `bde7989` and `ee4ca95` on `07eceb1`).
- AC-3 — inspection — reviewers start from the requirement files, the brief and `git diff` in their own scratch copies (`.claude/skills/verify-requirement/SKILL.md`, the review prompts recorded with the workflow runs); media-critical claims were checked on real rendered outputs (three review rounds, WF-001). Inspection because the reviewer's inputs are a property of the review workflow and its recorded prompts, which no repository test can execute.
- AC-4 — integration and inspection — `scripts/tests/test-verify-tiers.sh` (one heavy media job at a time): the media and release tiers hold the heavy-media lock through their steps, a second media run prints one waiting line and runs no step until the lock is released, the fast tier takes no lock, a caller holding the lock sets `AVE_HEAVY_LOCK_HELD=1` and takes no second one, the same variable while nobody holds the lock fails the run before any step, and so does that variable without `flock`, with a lock file that cannot be opened and with a lock that `flock` cannot test, the default lock file, no process a step leaves behind keeps the lock, and the media tier fails without `flock`; inspection: `.claude/skills/develop/SKILL.md` § 4 Concurrency limits (at most two writing agents counted across every workflow and subagent, the lead's own code work among them, plus one heavy media job; at most two reviewer clones; concurrent writers in worktrees), `docs/ENVIRONMENT_CAPABILITIES.md` § Limits that shape the plan (item 5: the measured footprint of a clone and the limit of two that follows), the launch records of `docs/workflows/README.md` (each row names the agents of its run), the WORKFLOW_LOG operating baseline and the recorded deviations: WF-005 (heavy media jobs of two concurrent runs, which led to the lock) and WF-011 (a clone limit that three runs exceeded and one overlap of three code writers, which led to the two counting rules); no recursive agent spawning (subagents cannot spawn subagents).
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `docs/briefs/README.md` (template, handbacks, drafts), `docs/briefs/*.md` (persisted briefs), `docs/briefs/handbacks/` (persisted handbacks), `scripts/check-project-control.sh` check 11: headings present, once and in order, sections non-empty, a requirement ID under Requirements, a commit under Input revision, handbacks named after their briefs, sections judged without HTML comments, no other entry in `docs/briefs/`, hidden handbacks rejected (AC-1, AC-2)
- `CLAUDE.md` § Delegation, `.claude/skills/develop/SKILL.md` § 3–5 (brief first, handback persisted), `.claude/agents/*.md` (the brief path as the first input), `.claude/skills/ai-video-editor-delivery/SKILL.md` step 4 — the rule that every task the `develop` loop delegates starts from a brief, review runs scripted as workflows included; the skills that fork their own agent and the two one-time setup skills take none (AC-1)
- `.claude/settings.json` (`worktree.baseRef`), brief § Input revision, `.claude/skills/develop/SKILL.md` § 4, § Worktrees of `.claude/agents/implementer.md`, `.claude/agents/tester.md` and `.claude/agents/architect.md` (base commit confirmed by equality in every linked worktree) (AC-2)
- `.claude/skills/verify-requirement/SKILL.md`, `.claude/agents/reviewer.md`, review rounds recorded in `docs/WORKFLOW_LOG.md` WF-001 (AC-3)
- `scripts/verify.sh` (heavy-media lock), `docs/ARCHITECTURE.md` § Testing strategy item 6, `.claude/skills/develop/SKILL.md` § 4 Concurrency limits, `CLAUDE.md` § Delegation, `docs/WORKFLOW_LOG.md` operating baseline, WF-005 and WF-011, `docs/ENVIRONMENT_CAPABILITIES.md` § Limits that shape the plan (AC-4)
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
- 2026-10-06 — in-progress — red-team lens 097-D (finding 12, [handback part 2](../briefs/handbacks/2026-10-03-m0-gates-red-team.part-2.md)): a run started with `AVE_HEAVY_LOCK_HELD=1` took the caller's word, so two media-tier runs overlapped when nobody held the lock; `scripts/verify.sh` now confirms the lock is held and fails before any step otherwise (`scripts/tests/test-verify-tiers.sh`); the review PASS at `d4d3883` predates this change, so AC-4 is verified again with the other M0 requirements (lead)
- 2026-10-06 — in-progress — the review at `d4d3883` (2026-10-03, workflow `wf_ed1f5104-63a`) had returned PASS and its skeptic upheld it; the requirement stayed `in-progress` because the red-team fixes then changed files it relies on (lead)
- 2026-10-06 — in-progress — verify-requirement FAIL at `2df637f` (workflow `wf_7d9d015c-906`; [handback part 7](../briefs/handbacks/2026-10-03-m0-gates-red-team.part-7.md)): AC-2 — no recorded writer prompt carried the base-commit equality check the strategy named (three runs confirmed the branch name), and seven review runs since the brief rule started without a brief while an Edge case said such a task is never launched. `develop` § 4 and § 6 and the implementer and tester definitions now state both rules for the cases that occurred, the Edge cases and the strategy state what the records show, and [WF-008](../WORKFLOW_LOG.md) records the deviation; the non-blocking items go through [the fix brief](../briefs/2026-10-06-m0-final-review-fixes.md) (lead)
- 2026-10-06 — in-progress — fixes of the final review merged on branch `m0-final-integration` ([fix brief](../briefs/2026-10-06-m0-final-review-fixes.md), handback parts [2](../briefs/handbacks/2026-10-06-m0-final-review-fixes.part-2.md) and [3](../briefs/handbacks/2026-10-06-m0-final-review-fixes.part-3.md)): an inherited `AVE_HEAVY_LOCK_HELD=1` fails closed without `flock` or a usable lock file; check 11 judges a section without its HTML comments and fails any other entry of `docs/briefs/`; ASM-018 names the forms that count as a commit; the writers of the fix run confirmed their base commit by equality, as their prompts in `docs/workflows/m0-final-review-fixes.js` ask (lead)
- 2026-10-06 — verification — fixes of the final review integrated on branch `m0-final-integration`; independent verification with a skeptic requested from [the review brief](../briefs/2026-10-06-m0-final-review-2.md) (lead)
- 2026-10-07 — in-progress — verify-requirement PASS at `f996c17` (workflow `wf_b18a5f3e-54e`, briefed in [the review brief](../briefs/2026-10-06-m0-final-review-2b.md); [handback part 3](../briefs/handbacks/2026-10-06-m0-final-review-2b.part-3.md)) refuted by the skeptic: AC-4 — `docs/ENVIRONMENT_CAPABILITIES.md` § Limits item 5 let reviewer clones go one at a time, and the three runs since that line used two, so the record named as evidence stated a limit the runs exceeded; AC-1 to AC-3 upheld. The lead restates the limit from the measured footprint, counts reviewer clones and the lead's own code work in `develop` § 4 ([WF-011](../WORKFLOW_LOG.md)) and closes the six non-blocking items; the checker cases go through [the fix brief](../briefs/2026-10-07-m0-review-2-fixes.md), track B2 (lead)
- 2026-10-07 — in-progress — fixes of the second review round merged on branch `m0-final-integration` ([the fix brief](../briefs/2026-10-07-m0-review-2-fixes.md), [handback part 4](../briefs/handbacks/2026-10-07-m0-review-2-fixes.part-4.md)): the seven sub-rules of check 11 that had no case have one each; the lead closed the refuted AC-4 and the other non-blocking items in the documents (`5afa701`): the brief rule with the two kinds of task that take none, the counting rules for reviewer clones and the lead's own code work, and the limits of check 11 and of the inherited lock claim (lead)
