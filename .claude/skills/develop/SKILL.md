---
name: develop
description: Runs the autonomous implementation loop. Selects the highest-priority unblocked requirement, implements it directly or through subagents, verifies it with ./scripts/verify.sh and verify-requirement, records evidence, traceability and progress, commits, and repeats through milestone reviews until the product is complete.
when_to_use: Default skill once the product is defined and the technical foundation exists, whenever incomplete requirements remain. An optional argument limits the run to one requirement (REQ-NNN) or one milestone (M<n>).
argument-hint: "[REQ-NNN | M<n>]"
---

# develop — implementation loop

You are the lead (main session): product lead, architect, tech lead, orchestrator and integration owner. This loop turns Ready requirements into verified, traceable, committed increments until the scope is complete. Paths are relative to the repository root; dates come from `date -u +%F`.

Scope argument: `$ARGUMENTS`
- empty: the current milestone, then each following milestone until the product is complete;
- `REQ-NNN`: that requirement, its unfinished dependencies first; stop when it is `done`;
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
grep -H -E '^(status|priority):' docs/requirements/REQ-*.md
```

1. Finish started work first: a requirement in `in-progress` resumes at section 3 step 2, or at section 7 step 2 when PROGRESS.md § In progress lists open findings under it; one in `verification` resumes at section 6 step 3.
2. Candidates: requirements in the current milestone's "Requirements (dependency order)" list with status `ready` whose every `## Dependencies` requirement is `done`.
3. Order: priority `must` > `should` > `could`; ties follow roadmap order.
4. No candidate while `proposed` requirements remain in the milestone: refine the next ones in roadmap order to Ready. Apply the Definition of Ready, complete missing sections, resolve missing information as `docs/ASSUMPTIONS.md` entries, record the `ready` transition, and commit the batch (`REQ-NNN, REQ-NNN: refine to ready`).
5. Only `blocked` requirements remain in the milestone and the scope argument is empty: take requirements from the following `planned` milestones, in roadmap order, whose every `## Dependencies` requirement is `done`; a milestone's `Depends on` line does not bar them. First refine the `proposed` ones to Ready as in step 4, then select among them by steps 2–3. The current milestone stays `in-progress`, and those milestones stay `planned`. With scope `M<n>`, or when nothing is selectable or refinable anywhere, go to section 14.
6. Every non-superseded requirement in the milestone is `done`: go to section 11.

## 3. Start and understand — "understand requirement…", "inspect related architecture"

1. Record the transition `ready → in-progress`.
2. Read the requirement file completely, its parent FEAT/EPIC, the requirements under its Dependencies, and the ADRs it cites or that cite it (`grep -rl "REQ-NNN" docs/decisions/`).
3. Read the `docs/ARCHITECTURE.md` sections that govern the affected components; locate the code involved (`git grep -n -w --untracked "REQ-NNN"`, entry points, existing tests).
4. **Research needed** (unfamiliar library, API, format or standard; fast-changing technology): delegate to the `researcher` with the question, the decision it feeds and the constraints. Record a result that drives a decision as an assumption or ADR.
5. **Significant architecture decision needed** (architecture, data model, integration boundary, infrastructure, major dependency, long-term maintainability): consult the `architect` with the decision, the IDs it serves and the constraints. Review its Proposed ADR and the updates it proposes. Accept it per `docs/decisions/README.md` § Who writes (plus § Superseding when it replaces an ADR) and cite it in the requirement's `## Dependencies`, or return it with reasons. Escalate only under the criteria in section 14.

## 4. Implement — delegate or implement directly

**Delegate to the `implementer`** when the work is bounded (one Ready requirement or a tight set under one parent, unambiguous ACs) and isolatable (clear ownership of a set of files), or when the work is substantial enough to crowd your own context, or your context is already heavy.
**Implement directly** by invoking the `implement-requirement` skill with `REQ-NNN` when the change is small, cross-cutting, touches files other work also touches, or needs design iteration.

Brief every subagent with the requirement ID, file paths and constraints only. Subagents read the files themselves; never paste requirement text, documents or conversation history.

```text
Implement REQ-NNN.
Files in scope: <paths or globs>. Leave untouched: <paths owned by parallel work, or "none">.
Constraints: <ADR-NNN, interfaces to honor, decisions already made, or "none">.
Worktree: <no | yes — base commit <hash>; confirm `git merge-base --is-ancestor <hash> HEAD` first, else return BLOCKED>.
Commit: <no | yes, after ./scripts/verify.sh passes, message "REQ-NNN: <imperative summary>">.
Return the implement-requirement report.
```

When the report returns:
1. `COMPLETE`: inspect the diff yourself (`git diff`, or `git diff HEAD...<branch>` for a worktree branch); apply the "Shared-document updates for the lead" you agree with (proposed assumptions and follow-up requirements go through section 10); run `./scripts/verify.sh`. The status stays `in-progress` until section 6 step 2.
2. `PARTIAL` or `BLOCKED`: classify the cause (section 7), resolve it (decide the ambiguity, consult the architect, remove the blocker), then re-delegate with the resolution as a constraint or finish directly.
3. The report is a claim; `verify-requirement` decides.

### Parallel work

Use it when two or more selected requirements are independent of each other and touch disjoint files.
1. Record the `in-progress` transition of each and commit it (`REQ-NNN, REQ-NNN: start implementation`). Worktrees branch from the current `HEAD` (`worktree.baseRef: "head"` in `.claude/settings.json`) and carry no uncommitted changes; note `git rev-parse HEAD` as the base commit.
2. Spawn one implementer per requirement in a single message: Agent tool with `subagent_type: implementer` and `isolation: "worktree"`, brief with `Worktree: yes` and `Commit: yes`; each brief's "Leave untouched" names the files of the others.
3. While they run, touch none of their files.
4. Integrate one branch at a time, in priority order, keeping each merge uncommitted until its review passes:
   1. `git merge --no-ff --no-commit <branch>`; resolve conflicts yourself, preserving the behavior of both sides;
   2. run `./scripts/verify.sh`;
   3. record the `verification` transition and run `verify-requirement` (section 6) on the uncommitted merge;
   4. on PASS complete it (section 8), then commit the merge with its evidence, traceability and progress updates (section 9, message `REQ-NNN: integrate <branch>`) before merging the next branch;
   5. on FAIL repair it in the main working tree (section 7); a re-delegated implementer gets `Worktree: no` and `Commit: no`, since a new worktree starts from the pre-merge `HEAD` and any commit concludes the merge;
   6. when it ends `blocked`: note its findings, run `git merge --abort` (this also discards the merge's uncommitted document updates), record the `blocked` transition with the findings and the branch name, commit those document updates, and keep the branch.
5. After integrating a branch, remove its worktree and branch: `git worktree remove <path>` and `git branch -d <branch>`. For a blocked branch, remove only the worktree.

When an implementer reports that the base check failed (its worktree did not start from the base commit, e.g. a local settings override of `worktree.baseRef`), implement the remaining requirements sequentially in the main working tree.

## 5. Tests — "add/update tests"

1. The implementer or `implement-requirement` writes tests for every AC, tagged `REQ-NNN AC-n`.
2. For complex or risky requirements (parsing, state machines, concurrency, security, data integrity, media and file-format edge cases), delegate to the `tester` before verification. Brief: requirement ID, implementation paths, risk areas. Spawn it in the main working tree (no `isolation`): the implementation stays uncommitted until section 9, and a worktree holds only committed code. Handle its `DEFECTS FOUND` items through section 7 and keep the failing tests it adds.

## 6. Verify — "run relevant verification", "independently review requirement"

1. Run `./scripts/verify.sh`; it must pass. Repair failures through section 7.
2. Record the transition `in-progress → verification` (TRACEABILITY.md Implementation and Tests from the requirement's Implementation evidence).
3. Invoke the `verify-requirement` skill with argument `REQ-NNN` (Skill tool, or `/verify-requirement REQ-NNN`). It forks the `reviewer` with clean context and returns the verdict report. Add no briefing: the requirement and the repository are its inputs.
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
1. Brief the `architect`: requirement ID, the blocking findings of each cycle (its `cycle <n>` Status-log lines and the current list in PROGRESS.md § In progress), the paths involved; ask whether the requirement or the design is at fault.
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
- [ ] Run `./scripts/verify.sh`; the checker validates the `done` invariants.

## 9. Commit — "create coherent commit when appropriate"

1. Inspect `git status` and `git diff`: every change belongs to this unit; no secret, debug output or stray file.
2. Commit the requirement's code, tests, evidence, traceability and progress together: `REQ-NNN: <imperative summary>`.
3. Commit other coherent units on their own: refinement batches, accepted ADRs, re-planning (`docs: …`), refactors (`refactor: …`). Never bundle unrelated changes.

## 10. Discovered work

Never expand the current requirement silently. For each discovery:
- **Missing behavior or a new need:** create a `proposed` requirement with the next free ID (command in `docs/requirements/README.md`), an existing parent, and the Status-log line `proposed — discovered during REQ-NNN (lead)`; list it in the parent; place it in a `docs/ROADMAP.md` milestone with a Re-planning log row.
- **Missing information with a reasonable default:** add a `docs/ASSUMPTIONS.md` entry.
- **Product-intent question meeting an escalation criterion:** add it to `docs/PRODUCT.md` § Open product questions and escalate (section 14).
- **Technical debt:** add it to `docs/ARCHITECTURE.md` § Risks and technical debt.

When the current requirement cannot pass without the new work, add the new requirement to its Dependencies with a logged reason, refine the new one to Ready and complete it first; the current requirement stays `in-progress`.

## 11. Continue — milestones and product completion

1. After each completed requirement, return to section 2.
2. Every non-superseded requirement of the current milestone is `done`: run `milestone-review`. It records the verdict in the milestone's Review line and identifies the next milestone. On PASS, make sure ROADMAP.md shows the milestone `done` and the next one `in-progress` and PROGRESS.md § Current milestone names it (set whatever the review left unset), then continue. On FAIL continue with the follow-up requirements it added to the current milestone. With scope `M<n>`, stop after the review and report.
3. Every milestone is `done`: check each item of `docs/PRODUCT.md` § Definition of product completion; create requirements for unmet items and continue. When all hold, run a final `milestone-review` over the whole product, then report completion to the human: delivered milestones and user journeys, verification status, open assumptions, known technical debt, recommended next steps.

## 12. Architecture review before large refactors

Before a refactor that moves a module boundary, changes a shared interface, the data model or a persistence format, or spans several components, invoke `architecture-review` on that scope. Apply the recommendations you accept through ADRs accepted per section 3 step 5; keep `./scripts/verify.sh` green before and after; commit the refactor alone or under the requirement that needs it.

## 13. Context hygiene

- Update PROGRESS.md at every transition; the SessionStart hook and `resume-project` recover from it after compaction.
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
