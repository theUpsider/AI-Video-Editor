---
name: develop
description: Runs the autonomous implementation loop. Selects the highest-priority unblocked requirement, implements it directly or through subagents, verifies it with ./scripts/verify.sh and verify-requirement, records evidence, traceability and progress, commits, and repeats through milestone reviews until the product is complete.
when_to_use: Default skill once the product is defined and the technical foundation exists, whenever incomplete requirements remain. An optional argument limits the run to one requirement (AVE-REQ-NNN) or one milestone (M<n>).
argument-hint: "[AVE-REQ-NNN | M<n>]"
---

# develop — implementation loop

You are the lead (main session): product lead, architect, tech lead, orchestrator and integration owner. This loop turns Ready requirements into verified, traceable, committed increments until the scope is complete. Paths are relative to the repository root; dates come from `date -u +%F`.

Scope argument: `$ARGUMENTS`
- empty: the current milestone, then each following milestone until the product is complete;
- `AVE-REQ-NNN`: that requirement, its unfinished dependencies first; stop when it is `done`;
- `M<n>`: that milestone; stop after its `milestone-review`.

Shared rules live in `CLAUDE.md`, `docs/requirements/README.md` (format, lifecycle, Definitions of Ready and Done, changing requirements), `docs/decisions/README.md` (ADR format, acceptance, superseding) and `docs/TRACEABILITY.md` (update rules). Load sections of them as needed.

## The loop

```text
while incomplete requirements exist:
    determine highest-priority unblocked requirement
    understand requirement and acceptance criteria
    inspect related architecture
    if research is needed: delegate research (researcher)
    if a significant architecture decision is needed: consult architect; create/update ADR
    if implementation is bounded and delegatable: delegate implementation (implementer)
    else: implement directly (implement-requirement)
    add/update tests
    run relevant verification (./scripts/verify.sh)
    independently review requirement (verify-requirement)
    if review or verification fails: diagnose; repair; repeat verification
    update implementation evidence
    update traceability
    update requirement status
    update progress
    create coherent commit when appropriate
    continue
```

The numbered sections below expand these lines and the rules around them; quoted section titles name the loop lines they cover.

## Recording a transition

The lead sets every requirement status. Each transition updates, in one edit set:
1. frontmatter `status` (canonical);
2. one Status-log line, newest last: `- <date> — <status> — <reason> (<actor>)`;
3. the `docs/TRACEABILITY.md` row per its § Update rules (the row is added at `in-progress`);
4. the parent FEAT/EPIC status, with its own Status-log line, when the derivation rule in `docs/requirements/README.md` § Status lifecycle changes it;
5. `docs/PROGRESS.md`: § In progress, § Recently completed, § Blockers as applicable, and the `_Last updated_` line.

```text
- 2026-10-02 — ready — Definition of Ready met (lead)
- 2026-10-02 — in-progress — selected from M1; delegated to implementer (lead)
- 2026-10-03 — verification — implementation complete; verify.sh PASS (lead)
- 2026-10-03 — in-progress — verify-requirement FAIL, cycle 1: AC-2 test asserts only on a mock (lead)
- 2026-10-03 — verification — AC-2 test repaired; verify.sh PASS (lead)
- 2026-10-04 — done — verify-requirement PASS (lead)
```

## 1. Preconditions

Check once per run and after every resume:
1. **Product defined:** `grep -m1 '^\*\*Status:\*\*' docs/PRODUCT.md` reads `defined`, `grep -n '^_TBD' docs/PRODUCT.md` prints nothing, and `docs/requirements/` holds REQ files. Otherwise run `product-definition` when the human's product prompt is available (in the conversation or `docs/product-inputs/`); without it, tell the human the repository is ready for the product prompt and stop.
2. **Foundation present:** the `**Status:**` line of `docs/ARCHITECTURE.md` no longer reads `placeholder`, § Technology stack lists the selected stack, and `./scripts/verify.sh` runs real stack checks (its stack-pending NOTICE is gone). Otherwise run `technical-foundation`.
3. **Baseline green:** `git status` shows only changes you can explain, and `./scripts/verify.sh` passes. A failing baseline is the first task: repair it (section 7). When the repair needs the human, record it in `docs/PROGRESS.md` § Known failures and continue with work it does not affect.
4. **Current milestone:** `docs/PROGRESS.md` § Current milestone names it and its `docs/ROADMAP.md` entry has status `in-progress`. When none is in progress, set the first `planned` milestone whose `Depends on` milestones are `done` to `in-progress` and update PROGRESS.md.

## 2. Select — "determine highest-priority unblocked requirement"

```sh
grep -H -E '^(status|priority):' docs/requirements/AVE-REQ-*.md
```

1. Finish started work first: a requirement in `in-progress` resumes at section 3 step 2, or at section 7 step 2 when PROGRESS.md § In progress lists open findings under it; one in `verification` resumes at section 6 step 3.
2. Candidates: requirements in the current milestone's "Requirements (dependency order)" list with status `ready` whose every `## Dependencies` requirement is `done` (a superseded dependency counts through the requirement its `superseded_by` chain ends at).
3. Order: priority `must` > `should` > `could`; ties follow roadmap order.
4. No candidate while `proposed` requirements remain in the milestone: refine the next ones in roadmap order to Ready. Apply the Definition of Ready, complete missing sections, resolve missing information as `docs/ASSUMPTIONS.md` entries, record the `ready` transition, and commit the batch (`AVE-REQ-NNN, AVE-REQ-NNN: refine to ready`).
5. Only `blocked` requirements remain in the milestone and the scope argument is empty: take requirements from the following `planned` milestones, in roadmap order, whose every `## Dependencies` requirement is `done`; a milestone's `Depends on` line does not bar them. First refine the `proposed` ones to Ready as in step 4, then select among them by steps 2–3. The current milestone stays `in-progress`, and those milestones stay `planned`. With scope `M<n>`, or when nothing is selectable or refinable anywhere, go to section 14.
6. Every non-superseded requirement in the milestone is `done`: go to section 11.

## 3. Start and understand — "understand requirement…", "inspect related architecture"

1. Record the transition `ready → in-progress`.
2. Read the requirement file completely, its parent FEAT/EPIC, the requirements under its Dependencies, and the ADRs it cites or that cite it (`grep -rl "AVE-REQ-NNN" docs/decisions/`).
3. Read the `docs/ARCHITECTURE.md` sections that govern the affected components; locate the code involved (`git grep -n -w --untracked "AVE-REQ-NNN"`, entry points, existing tests).
4. **Research needed** (unfamiliar library, API, format or standard; fast-changing technology): delegate to the `researcher` through a brief (section 4) holding the question, the decision it feeds and the constraints. Record a result that drives a decision as an assumption or ADR.
5. **Significant architecture decision needed** (architecture, data model, integration boundary, infrastructure, major dependency, long-term maintainability): consult the `architect` through a brief (section 4) holding the decision, the IDs it serves and the constraints. Review its Proposed ADR and the updates it proposes. Accept it per `docs/decisions/README.md` § Who writes (plus § Superseding when it replaces an ADR) and cite it in the requirement's `## Dependencies`, or return it with reasons. Escalate only under the criteria in section 14.

## 4. Implement — delegate or implement directly

**Delegate to the `implementer`** when the work is bounded (one Ready requirement or a tight set under one parent, unambiguous ACs) and isolatable (clear ownership of a set of files), or when the work is substantial enough to crowd your own context, or your context is already heavy.
**Implement directly** by invoking the `implement-requirement` skill with `AVE-REQ-NNN` when the change is small, cross-cutting, touches files other work also touches, or needs design iteration.

**Brief first.** Before spawning any delegated task (implementer, tester, researcher, architect, workflow run), write its brief `docs/briefs/YYYY-MM-DD-<slug>.md` from the template in `docs/briefs/README.md`: requirement IDs and the ACs in scope, allowed and forbidden paths (the files of parallel work are forbidden), constraints, test commands, handback schema, and the input revision: the current commit (`git rev-parse --short HEAD`) plus the commit that adds the brief (`git log -1 --format=%h -- docs/briefs/<this file's name>`), followed by "isolated worktree" or "main working tree" (naming any uncommitted changes the task builds on); check 11 of `scripts/check-project-control.sh` fails on an input revision that names no commit. A brief written ahead of its launch waits in `docs/briefs/drafts/` (`docs/briefs/README.md` § Drafts). Commit the brief before the launch, without the task's work (`docs: brief <task>`; with the transitions of § Parallel work step 1; inside an uncommitted merge of § Parallel work step 4 it joins the merge commit), then note `git rev-parse HEAD` as the task's base commit. The prompt passes the brief path and the base commit and adds nothing the brief lacks; subagents read the files themselves. Never paste requirement text, documents or conversation history. Skills that fork their own agent (`verify-requirement`, `architecture-review`) take no brief.

```text
Implement AVE-REQ-NNN as briefed in docs/briefs/YYYY-MM-DD-<slug>.md; read the brief first.
Worktree: <no — main working tree | yes — base commit <full hash>; before changing anything confirm that `git rev-parse HEAD` prints exactly that hash, else return BLOCKED>.
Commit: <no | yes, after ./scripts/verify.sh passes, message "AVE-REQ-NNN: <imperative summary>">.
Return the implement-requirement report.
```

A writer that a workflow run places in a worktree the lead created gets the same `Worktree: yes — base commit <full hash>` line; a later stage that continues in that worktree confirms that `git rev-parse HEAD` equals the commit the previous stage handed over. A branch name confirms nothing about the base.

When the report returns, persist it first as the task's handback, `docs/briefs/handbacks/<brief-slug>.md` (`<brief-slug>.part-<n>.md` for a task run in parts), unless the task wrote that file itself because its brief's handback schema names it; it is committed with the work it reports. Then:
1. `COMPLETE`: inspect the diff yourself (`git diff`, or `git diff HEAD...<branch>` for a worktree branch); apply the "Shared-document updates for the lead" you agree with (proposed assumptions and follow-up requirements go through section 10); run `./scripts/verify.sh`. The status stays `in-progress` until section 6 step 2.
2. `PARTIAL` or `BLOCKED`: classify the cause (section 7), resolve it (decide the ambiguity, consult the architect, remove the blocker), then re-delegate with the resolution as a constraint or finish directly.
3. The report is a claim; `verify-requirement` decides.

### Parallel work

Use it when two or more selected requirements are independent of each other and touch disjoint files.
1. Record the `in-progress` transition of each, write each implementer's brief (Brief first above), and commit them together (`AVE-REQ-NNN, AVE-REQ-NNN: start implementation`). Worktrees branch from the current `HEAD` (`worktree.baseRef: "head"` in `.claude/settings.json`) and carry no uncommitted changes; note `git rev-parse HEAD` as the base commit.
2. Spawn one implementer per requirement in a single message: Agent tool with `subagent_type: implementer` and `isolation: "worktree"`, each prompt with its brief, `Worktree: yes — base commit <full hash>` and `Commit: yes`; each brief's Forbidden paths name the files of the others.
3. While they run, touch none of their files.
4. Integrate one branch at a time, in priority order, keeping each merge uncommitted until its review passes:
   1. `git merge --no-ff --no-commit <branch>`; resolve conflicts yourself, preserving the behavior of both sides;
   2. run `./scripts/verify.sh`;
   3. record the `verification` transition and run `verify-requirement` (section 6) on the uncommitted merge;
   4. on PASS complete it (section 8), then commit the merge with its evidence, traceability, progress updates and handback (section 9, message `AVE-REQ-NNN: integrate <branch>`) and push the working branch (`CLAUDE.md` § Git) before merging the next branch;
   5. on FAIL repair it in the main working tree (section 7); a re-delegated implementer gets `Worktree: no` and `Commit: no`, since a new worktree starts from the pre-merge `HEAD` and any commit concludes the merge;
   6. when it ends `blocked`: note its findings, run `git merge --abort` (this also discards the merge's uncommitted document updates), record the `blocked` transition with the findings and the branch name, commit those document updates with the handback, keep the branch, and push it alongside the working branch before PROGRESS.md names it.
5. After integrating a branch, remove its worktree and branch: `git worktree remove <path>` and `git branch -d <branch>`. For a blocked branch, remove only the worktree.

Every commit and file that PROGRESS.md names is reachable from the remote first (`CLAUDE.md` § Git): a worktree branch reaches it through the merged and pushed working branch, or, while it stays unmerged after its handback (blocked, interrupted, awaiting review), through its own push (`git push origin <branch>`).

When an implementer reports that the base check failed (its worktree did not start from the base commit, e.g. a local settings override of `worktree.baseRef`), implement the remaining requirements sequentially in the main working tree.

### Concurrency limits

At most two writing agents (implementer, tester, architect, writing workflow agents) run at once, counted across every workflow and subagent the lead has launched, plus one heavy media job (a media or release tier run, a targeted `-m "media or slow"` pytest run, a reviewer's or tester's media reproduction). Concurrent writers always run in worktrees; one writing task may use the main working tree only while no other agent writes (the tester of section 5, a repair inside an uncommitted merge); read-only reviews need no worktree.
- Writing agents: the lead counts them before every launch, workflows included, and launches a third only after one has returned.
- Heavy media jobs: they serialize on the heavy-media lock (`docs/ARCHITECTURE.md` § Testing strategy). `./scripts/verify.sh --tier media|release` holds it for its whole run and waits while another job holds it; every other heavy command runs as `flock <lock file> <command>`, and each brief that runs one names that form. Concurrent workflows therefore queue their heavy jobs; within one workflow, heavy review lenses run in sequence, since a queued job keeps its agent idle.
- Raising a limit needs a measurement first (WORKFLOW_LOG entry: CPU time, wall time and test stability with the higher count).

## 5. Tests — "add/update tests"

1. The implementer or `implement-requirement` writes tests for every AC, tagged `AVE-REQ-NNN AC-n`.
2. For complex or risky requirements (parsing, state machines, concurrency, security, data integrity, media and file-format edge cases), delegate to the `tester` before verification. Write its brief first (section 4): requirement ID, implementation paths, risk areas; input revision `<HEAD>` plus the brief's commit and the uncommitted implementation, main working tree. Spawn it in the main working tree (no `isolation`): the implementation stays uncommitted until section 9, and a worktree holds only committed code. Handle its `DEFECTS FOUND` items through section 7 and keep the failing tests it adds.

## 6. Verify — "run relevant verification", "independently review requirement"

1. Stage new files (`git add -A`: the tree fingerprint names an unstaged new file as untracked, so evidence recorded before staging reads stale after the commit), then run `./scripts/verify.sh --tier release`; it must pass (Definition of Done item 4: the release tier runs every tagged test). Repair failures through section 7.
2. Record the transition `in-progress → verification` (TRACEABILITY.md Implementation and Tests from the requirement's Implementation evidence).
3. Invoke the `verify-requirement` skill with argument `AVE-REQ-NNN` (Skill tool, or `/verify-requirement AVE-REQ-NNN`). It forks the `reviewer` with clean context and returns the verdict report. Add no briefing: the requirement and the repository are its inputs.
   - As a workflow run (several requirements, reviewers in private clones, a skeptic stage): the run is a delegated task and starts from a brief (section 4) that names the requirements and their criteria, the commit, the clone rule as its allowed paths, the commands and the report schema; its script is copied to `docs/workflows/`. Each reviewer follows `.claude/skills/verify-requirement/SKILL.md` from the repository. A skeptic, given the same brief and the reviewer's report, tries to refute each PASS with evidence from a run or a file; a refuted PASS counts as FAIL. Reviewer and skeptic reports persist as the brief's handback parts.
   - Without subagents (the sequential fallback of `CLAUDE.md` § Delegation): the requirement stays `verification` and the lead continues other work. The review runs in a fresh session, or a context holding nothing of the implementation work, that follows `.claude/skills/verify-requirement/SKILL.md` from the repository alone (the requirement file, its brief, `git diff`). Its verdict is recorded with the note `sequential review in a fresh session` in the Status-log line; until then the requirement stays `verification`.
4. Read the verdict. It counts as PASS only when the first line is `VERDICT: PASS`, every AC row is PASS with evidence, and § Blocking says "None."; treat everything else as FAIL.
5. PASS → section 8. FAIL → section 7.

## 7. Diagnose and repair — "if review or verification fails"

1. On a FAIL verdict, record the transition `verification → in-progress` with `verify-requirement FAIL, cycle <n>: <main finding>`, and persist every blocking finding under the requirement's line in PROGRESS.md § In progress, one indented bullet per finding (`path:line — defect — fix`), replacing any earlier list. Repair from this list.
2. Classify every blocking finding or failure:

| Class | Signal | Repair |
|---|---|---|
| Implementation defect | Code violates an AC, an edge case, an Accepted ADR or a module boundary; a check fails because of the change | Fix the code directly, or re-delegate with the findings as constraints; keep the test that exposed it |
| Test defect | A test is wrong, flaky, untagged, never collected, passes without the behavior, or needs a credential or live service | Fix or strengthen the test so it asserts the AC exactly; never loosen an assertion to get green. A test that needs a credential runs against the integration fake; the live check moves to the live-service command in `docs/ARCHITECTURE.md` § Testing strategy |
| Requirement ambiguity | An AC admits several readings, is untestable, or conflicts with another AC or an ADR | `source: derived`: decide, edit the requirement with a logged reason, record the assumption. `source: human` and the change alters product intent: escalate, record `blocked`, continue other work |

3. Fix root causes. Never skip, weaken or delete a check or test to make verification pass.
4. Re-run the targeted tests, then `./scripts/verify.sh`, then section 6 from step 2. Each `verify-requirement` run is a fresh fork.

**Non-convergence.** After 3 failed cycles on one requirement (count the `cycle <n>` log lines since the last step-back or reopening), or 3 failed repair attempts on the same `./scripts/verify.sh` failure, stop repairing and step back:
1. Write the `architect`'s brief (section 4): requirement ID, the blocking findings of each cycle (its `cycle <n>` Status-log lines and the current list in PROGRESS.md § In progress), the paths involved; ask whether the requirement or the design is at fault.
2. Decide: redesign (ADR accepted per section 3 step 5, then re-implement); change the requirement (logged change, split or supersede as needed, escalation for `source: human` intent changes); or record `blocked` when the cause lies outside your control.
3. Record the outcome as a Status-log line `- <date> — <status> — non-convergence review: <outcome> (lead)`, where `<status>` is the status after the review: `in-progress` when work continues (`docs/requirements/README.md` § Status lifecycle rule 2), or `blocked` with the prior state when the outcome is a block (§ Blocked below). Add an ADR or `docs/ASSUMPTIONS.md` entry when the outcome carries a decision.
4. Continue the requirement (the cycle count restarts) or, when blocked, return to section 2.

**Blocked.** Log the reason and the prior state, add the blocker to PROGRESS.md § Blockers, move the requirement's § In progress line, with its findings list, into that blocker entry, and update the TRACEABILITY.md status. On resolution, record the return to the prior state and remove the blocker.

## 8. Complete on PASS — "update implementation evidence / traceability / requirement status / progress"

- [ ] Tick every AC: `- [x] AC-n …`.
- [ ] Replace the `## Test evidence` placeholder with the report's "Evidence for the requirement file" block.
- [ ] Confirm `## Implementation evidence` lists the final files, tests and decisions; no `_TBD` remains in the file.
- [ ] Record the transition `verification → done` (`verify-requirement PASS`). The TRACEABILITY.md row gets status `done`, complete Implementation, Tests and ADRs cells, and the Evidence cell in the format of `docs/TRACEABILITY.md` § Update rules.
- [ ] Turn non-blocking findings into follow-ups (section 10) or entries in `docs/ARCHITECTURE.md` § Risks and technical debt.
- [ ] PROGRESS.md: move the requirement to § Recently completed and delete its findings list; keep only the five newest entries in § Recently completed and § Important recent decisions; refresh § Current objective, § Next recommended work and § Verification status.
- [ ] Run `./scripts/verify.sh --tier release`: the checkers validate the `done` invariants, and the step "Done requirements evidenced by this run" fails a `done` requirement with a criterion that this run does not evidence.

## 9. Commit — "create coherent commit when appropriate"

1. Inspect `git status` and `git diff`: every change belongs to this unit; no secret, debug output or stray file.
2. Commit the requirement's code, tests, evidence, traceability and progress together: `AVE-REQ-NNN: <imperative summary>`.
3. Commit other coherent units on their own: refinement batches, accepted ADRs, re-planning (`docs: …`), refactors (`refactor: …`). Never bundle unrelated changes.
4. A commit made from a subset of the working tree (a pathspec, a partly staged index, untracked files left for a later commit) holds a tree no local check saw. A file a later commit adds is linked only from that later commit or after it, and the committed tree is checked before the push (WF-006):

   ```sh
   git worktree add -q --detach .claude/worktrees/commit-check HEAD
   (cd .claude/worktrees/commit-check && ./scripts/check-project-control.sh); git worktree remove --force .claude/worktrees/commit-check
   ```

   On a host that verifies in the development container the check runs as `./scripts/dev-container.sh ./scripts/check-project-control.sh`.

## 10. Discovered work

Never expand the current requirement silently. For each discovery:
- **Missing behavior or a new need:** create a `proposed` requirement with the next free ID (command in `docs/requirements/README.md`), an existing parent, and the Status-log line `proposed — discovered during AVE-REQ-NNN (lead)`; list it in the parent; place it in a `docs/ROADMAP.md` milestone with a Re-planning log row.
- **Missing information with a reasonable default:** add a `docs/ASSUMPTIONS.md` entry.
- **Product-intent question meeting an escalation criterion:** add it to `docs/PRODUCT.md` § Open product questions and escalate (section 14).
- **Technical debt:** add it to `docs/ARCHITECTURE.md` § Risks and technical debt.

When the current requirement cannot pass without the new work, add the new requirement to its dependencies (frontmatter `dependencies` and the § Dependencies link, which name the same requirements) with a logged reason, refine the new one to Ready and complete it first; the current requirement stays `in-progress`.

## 11. Continue — milestones and product completion

1. After each completed requirement, return to section 2.
2. Every non-superseded requirement of the current milestone is `done`: run `milestone-review`. It records the verdict in the milestone's Review line and identifies the next milestone. On PASS, make sure ROADMAP.md shows the milestone `done` and the next one `in-progress` and PROGRESS.md § Current milestone names it (set whatever the review left unset), then continue. On FAIL continue with the follow-up requirements it added to the current milestone. With scope `M<n>`, stop after the review and report.
3. Every milestone is `done`: check each item of `docs/PRODUCT.md` § Definition of product completion; create requirements for unmet items and continue. When all hold, run a final `milestone-review` over the whole product, then report completion to the human: delivered milestones and user journeys, verification status, open assumptions, known technical debt, recommended next steps.

## 12. Architecture review before large refactors

Before a refactor that moves a module boundary, changes a shared interface, the data model or a persistence format, or spans several components, invoke `architecture-review` on that scope. Apply the recommendations you accept through ADRs accepted per section 3 step 5; keep `./scripts/verify.sh` green before and after; commit the refactor alone or under the requirement that needs it.

## 13. Context hygiene

- Update PROGRESS.md at every transition; the SessionStart hook and `resume-project` recover from it after compaction.
- Record delegated work in flight stop-safe in PROGRESS.md: `launched <date>; verdict not recorded; on resume without a recorded verdict, re-run <exact command>` (with the brief path). A later session cannot see a task of this one, so PROGRESS.md never says that work is running; `scripts/check-project-control.sh` check 7 rejects "running", "underway", "under way", "in flight", "ongoing", "still executing" and "runs now" there.
- PROGRESS.md names only commits, branches and files the remote holds (`CLAUDE.md` § Git, § Parallel work above).
- Persist decisions the moment you make them: ADRs, assumptions, Status-log lines. Conversation context is volatile.
- Load only what the current step needs: the current milestone entry, the requirement, its parent and dependencies, the governing ADRs and ARCHITECTURE.md sections. Prefer `grep` and single sections to whole documents.
- Delegate exploration and long investigations to subagents and keep only their reports.
- Read long command output through its tail or `grep`.
- After compaction or a new session, run `resume-project`; it re-enters this loop at the step the requirement status indicates.

## 14. When to stop

Continue autonomously. Stop only when:
1. the scope argument is satisfied (the requirement is `done`, or the milestone is reviewed);
2. the product is complete (section 11);
3. a decision meets an escalation criterion in `CLAUDE.md` § Autonomy and escalation: genuinely irreversible, materially changes the intended product, needs legal, business or product information unknowable from the repository, or carries significant destructive risk. First finish all work that does not depend on the answer, then ask once: one batched message, each question with its impact and a recommended default;
4. nothing is selectable because every remaining requirement waits on the human.

Credentials, secrets or access: state exactly what is needed (name, purpose, where it goes, e.g. a variable in `.env.example`), record it in PROGRESS.md § Blockers, record `blocked` on the dependent requirements, and continue all independent work.

When stopping, report in at most 15 lines: completed work, verification status, blockers, questions with recommended defaults, and the next step. Before ending any turn, leave `./scripts/verify.sh` passing and PROGRESS.md current; the Stop gate enforces the first.
