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
  concurrently on this 4-vCPU host). Enforcement of the heavy media limit: WF-005.
- Isolation: concurrent writers run in worktrees (`isolation: worktree`; smoke-tested: worktrees branch from
  local HEAD; each task checks its base commit by equality). One writing task may use the main tree only
  while no other agent writes; read-only reviews need no worktree. The first build run, `wf_5493b930-f7c`
  (2026-10-01), ran two writers in the main tree on disjoint paths; AVE-REQ-096 requires verified worktree
  isolation for concurrent writers, so that option ended with it (corrected 2026-10-02).
- Verification: `./scripts/verify.sh`; independent review through `verify-requirement` (forked reviewer).

## Entries

### WF-001 — 2026-10-02 — Adversarial real-media review with the reviewer's own constructions
- Observed failure and evidence: the M0 media core passed its implementer's suite (87 test functions at
  `24499a6`, 8 of them parametrized) and the 17 decoded-output checks named in that commit's message, yet the
  first independent review of `24499a6` reproduced 4 blocking defects on real media (late audio start, VFR gap
  beyond the seek margin, confident offsets on unrelated audio, `%` image names); the review of the fix `548c8ca`
  reproduced 4 more (MPEG-TS re-basing, sub-100 ms gaps, microsecond-rounded TS origin, stderr hang). Briefs:
  [round 1](briefs/2026-10-01-m0-media-core-review-fixes.md),
  [round 2](briefs/2026-10-01-m0-media-core-review-fixes-round-2.md).
- Root-cause hypothesis: tests written by the implementer exercise the constructions the implementer had in
  mind (MP4/MOV, PCM, container start 0); containers and timestamp anomalies outside that set stay untested.
- One proposed workflow/skill/context change: every media-core review prompt asks the reviewer to rebuild each
  claimed fix with its own constructions (other containers, codecs, seek points, populations) in a scratch copy,
  and to mutation-check at least two new tests; each fix round gets its own brief quoting the evidence. The rule
  is persisted in the review prompts ([round 3](workflows/review-media-core-round3-wf_1a23bf0d-2a0.js),
  [M0 fix tracks](workflows/m0-fix-tracks-wf_164de68e-23b.js)) and, since 2026-10-03, in
  [verify-requirement](../.claude/skills/verify-requirement/SKILL.md) § 8 and
  [reviewer](../.claude/agents/reviewer.md), so every review carries it.
- Expected metric and fixed evaluation set (plus held-out cases): blocking findings per review round on the
  media core; held-out: the reviewer's constructions are unknown to the implementer.
- Independent review result: review of `24499a6` FAIL (4 blocking), of `548c8ca` FAIL (4 blocking), of
  `90a1f2e` FAIL (1 blocking: the unit origin oracle read the probe's own rounded value;
  [round-3 brief](briefs/2026-10-02-m0-media-core-review-fixes-round-3.md) item 1), of `dc89da2` PASS
  (0 blocking, 12 non-blocking items in the [follow-up brief](briefs/2026-10-02-m0-media-core-round-3-follow-ups.md)).
  Review of this log entry: 2026-10-03, workflow `wf_ed1f5104-63a`: UNSUPPORTED as first written (the FAIL
  review of `90a1f2e` was omitted, the test count and the reviewer time had no repository record, the rule
  lived only in prompts); corrected in this version.
- Measured before/after result: blocking findings per round 4 → 4 → 1 → 0; 9 real defects found that the
  implementer's suite passed; each fix now has a real-media test confirmed to fail without it. The implementers
  reported their mutation runs in handbacks that lived only in the session; the round-3 reviewers repeated the
  mutations ([follow-up brief](briefs/2026-10-02-m0-media-core-round-3-follow-ups.md)). Handbacks persist in
  `docs/briefs/handbacks/` since `fb61875` (2026-10-02).
- Keep or revert, with reason: keep; the recorded cost is 53 min for the round-3 review workflow
  ([workflows/README.md](workflows/README.md); rounds 1 and 2 ran as agent calls without a recorded duration),
  far below the cost of shipping wrong synchronization or frames.

### WF-002 — 2026-10-02 — Account limit during a delegated fix round
- Observed failure and evidence: the round-2 implementer stopped with HTTP 429 (weekly account limit) after
  editing five files in its worktree and before testing or committing them. The only record is
  [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § Account usage limits, a session observation: the
  agent ran as an Agent call without a workflow record or handback.
- Root-cause hypothesis: an external usage limit; nothing in the repository could prevent it, but the worktree
  kept the partial edits and the brief kept the full task.
- One proposed workflow/skill/context change: persist every task brief in `docs/briefs/` before the task starts
  (template in [briefs/README.md](briefs/README.md)), so the lead or a new session can finish an interrupted
  task from the repository: brief + worktree diff.
- Expected metric and fixed evaluation set (plus held-out cases): an interrupted task is resumable from the
  repository alone without re-deriving its scope. This interruption does not evaluate the change: the round-2
  brief was in the session scratchpad when the agent stopped and entered the repository in `31e8b84`
  (07:41 UTC), after the lead's completion commit `90a1f2e` (07:15 UTC), so that resumption used a
  session-local brief plus the worktree diff. Held-out case: the run `wf_164de68e-23b`, stopped by a session
  restart, resumed as `wf_df2de811-039` from the committed briefs
  [process fixes](briefs/2026-10-02-m0-process-fixes-execution.md) and
  [media follow-ups](briefs/2026-10-02-m0-media-core-follow-ups-execution.md)
  ([workflows/README.md](workflows/README.md); handbacks part 1 to part 4 under [briefs/handbacks/](briefs/handbacks/)).
- Independent review result: review of the resumed work `90a1f2e` FAIL (1 blocking, the unit origin oracle;
  round-3 brief item 1); review of `dc89da2` PASS (`wf_1a23bf0d-2a0`). Review of this log entry: 2026-10-03,
  workflow `wf_ed1f5104-63a`: UNSUPPORTED as first written (the evaluation named an interruption that predates
  the persisted brief; the mutation count had no record); corrected in this version.
- Measured before/after result: before, the lead completed items 1–9 of the round-2 brief from the session-local
  brief and the worktree diff (commit `90a1f2e` and its tests). After, the held-out resumption above completed
  both tracks from the committed briefs alone, with their handbacks persisted.
- Keep or revert, with reason: keep; the briefs cost minutes and also serve as review input (AVE-REQ-096 AC-1).

### WF-003 — 2026-10-02 — Background agents and lead idle time
- Observed failure and evidence: two delegated reviews requested in the background, `wf_1a23bf0d-2a0` (53 min)
  and `wf_b0c34bba-a20` (37 min; durations in [workflows/README.md](workflows/README.md)), returned only on
  completion; PROGRESS.md at `4d9ef9a` records both as running at 08:59 UTC on 2026-10-02.
- Root-cause hypothesis: runtime behavior outside the repository; it is not predictable from the request.
- One proposed workflow/skill/context change: start a delegated run in the same message as independent lead work
  (parallel tool calls), so a blocking call still overlaps with useful work. Adopted in no skill: Workflow runs
  return through task notifications while the lead continues, so the change has no procedure to carry it; the
  observation stays in [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § Background agents.
- Expected metric and fixed evaluation set (plus held-out cases): lead idle time while agents run; unmeasured
  (no measurement of lead tool activity during a run was taken).
- Independent review result: review of this log entry: 2026-10-03, workflow `wf_ed1f5104-63a`: UNSUPPORTED as
  first written (the durations and the run kinds were misreported, the metric was never measured, the change
  lived in no skill); corrected in this version.
- Measured before/after result: lead idle time: unmeasured. On 2026-10-02 at 09:00 four agents ran media-heavy
  work at once across the two runs ([fix brief](briefs/2026-10-02-m0-process-verification-fixes.md) item 5),
  which broke the limit of one heavy media job; CPU time, wall time and test stability under two heavy jobs were
  never measured (corrected 2026-10-02; the earlier text recorded the overlap as a gain).
- Keep or revert, with reason: revert as a procedure change (no skill carries it); the heavy-media limit the
  overlap broke is enforced by WF-005, and the observation remains in ENVIRONMENT_CAPABILITIES.md.

### WF-004 — 2026-10-02 — Mutation checks must not run stale bytecode
- Observed failure and evidence: a mutation of `_exact_container_start` in `backend/src/ave/media/probe.py`
  (`return min(exact)` → `max`) reported
  `tests/unit/test_probe_parse.py::test_container_start_takes_the_earliest_matching_stream` as passing; rerun
  after deleting `__pycache__` it failed as expected. A same-size source edit
  within one second keeps the cached `.pyc` valid (Python checks size and whole-second mtime).
- Root-cause hypothesis: the mutation helper reran pytest right after an equal-length edit.
- One proposed workflow/skill/context change: every run of mutated Python deletes the `__pycache__` directories
  first; reviewer prompts say so explicitly, and since 2026-10-03
  [verify-requirement](../.claude/skills/verify-requirement/SKILL.md) § 8 and
  [reviewer](../.claude/agents/reviewer.md) carry the rule for every review.
- Expected metric and fixed evaluation set (plus held-out cases): no mutation reported as surviving because of a
  stale cache; re-run of the mutation above (the test passes on the stale `.pyc`, fails after the directories
  are deleted, passes after the restore).
- Independent review result: the round-3 review prompt carries the rule. Review of this log entry: 2026-10-03,
  workflow `wf_ed1f5104-63a`: SUPPORTED (the reviewer reproduced the stale-cache pass and the failure after
  deleting `__pycache__` at `d4d3883`).
- Measured before/after result: the `min`/`max` mutation went from a false "passed" to "failed" (caught).
- Keep or revert, with reason: keep; it costs a cache rebuild of a few seconds.

### WF-005 — 2026-10-03 — One heavy media job at a time, enforced by a lock
- Observed failure and evidence: the limit of one heavy media job was a rule in prose only. The round-2
  re-review ran media tests during a media-tier run of the merge, and on 2026-10-02 at 09:00 four agents ran
  media-heavy work at once across `wf_1a23bf0d-2a0` and `wf_b0c34bba-a20` (WF-003;
  [fix brief](briefs/2026-10-02-m0-process-verification-fixes.md) item 5). No entry measured the headroom
  for a second heavy job.
- Root-cause hypothesis: every agent and workflow starts its heavy commands on its own, and nobody counted
  heavy jobs across concurrent workflows.
- One proposed workflow/skill/context change: enforce the limit
  ([execution brief](briefs/2026-10-02-m0-process-fixes-execution.md), decision on item 5).
  `./scripts/verify.sh` holds an exclusive `flock` on the heavy-media lock
  `${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}` for the whole run of the media and release tiers,
  prints one line while it waits and exports `AVE_HEAVY_LOCK_HELD=1` to its steps; the fast tier takes no
  lock. Every other heavy media command runs as `flock <lock file> <command>` (`docs/ARCHITECTURE.md`
  § Testing strategy item 6). `develop` § 4 Concurrency limits and the delivery skill say how the lead counts
  writing agents and heavy jobs across concurrent workflows.
- Expected metric and fixed evaluation set (plus held-out cases): at most one heavy media job runs at a time.
  Evaluation set: `scripts/tests/test-verify-tiers.sh` § "one heavy media job at a time" (the media and
  release tiers hold the lock through their steps; a second media run prints one waiting line, runs no step
  until the first releases the lock, then passes; the fast tier takes no lock; a caller holding the lock
  takes none; no process a step leaves behind keeps the lock; without `flock` the media tier fails before any
  step). Held-out: the media and release runs of the next concurrent workflows, whose logs show the waiting
  line when they overlap.
- Independent review result: review of this log entry: 2026-10-03, workflow `wf_ed1f5104-63a`: SUPPORTED (suite
  23 of 23 with every lock case; mutations L1 and L5 reproduced). The re-verification of AVE-REQ-096 AC-4:
  PASS at `d4d3883` in the same run (suite 23 of 23, the lock removed → 11 failures, one waiting line observed
  live while four reviewer clones queued on the shared lock); the skeptic's challenge was upheld.
- Measured before/after result: before, nothing stopped a second heavy job (four at once on 2026-10-02).
  After, in the suite, a media run started while the lock was held printed the waiting line, gave no
  output for 2 s and ran its steps after the release. Seven mutations of the lock in `scripts/verify.sh`
  (no lock, the variable ignored or not exported, the fast tier locked, the descriptor inherited by steps,
  no waiting line, no `flock` check) each failed the suite; the variable-not-exported mutation (L6) survived
  the first version of the suite and fails since the lock-state check runs in a child process
  ([handback part 4](briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-4.md) § Item 5 records the
  seven). CPU time and wall time under two heavy jobs stay unmeasured: the limit stays at one, so no headroom
  measurement is needed.
- Keep or revert, with reason: keep; a queued run costs its agent waiting time, and the limit holds on every
  host where the agents share one lock file. Raising the limit needs the measurement `develop` § 4 names.

### WF-006 — 2026-10-06 — A partial commit holds a tree no local check saw
- Observed failure and evidence: commit `56e5864` (2026-10-03) changed AVE-REQ-097's Status log to link
  [the gates brief](briefs/2026-10-03-m0-gates-red-team.md) while the brief stayed untracked for the next
  commit. The fast tier passed locally, because the file existed in the working tree; CI's release tier failed
  for that commit in step "Project control files" (a broken link to the brief). The next commit `35f99c5`
  added the brief and CI passed from there on. `main` was untouched.
- Root-cause hypothesis: `./scripts/verify.sh` checks the working tree; a commit made from a subset of it
  (here a pathspec exclusion) creates a tree that no local check saw.
- One proposed workflow/skill/context change: `develop` § 9 step 4: a file a later commit adds is linked only
  from that commit or after it, and after a partial commit the lead checks the committed tree in a detached
  worktree before the push (the command stands there).
- Expected metric and fixed evaluation set (plus held-out cases): red CI commits caused by a partial commit;
  evaluation set: the committed trees of `56e5864` and `35f99c5` checked with the step-4 command. Held-out: the
  partial commits of the following milestones.
- Independent review result: pending (the next review of this log; the lead records it).
- Measured before/after result: before, one red CI commit on the working branch (`56e5864`). With the step-4
  command, measured on 2026-10-06: the tree of `56e5864` fails with the same broken-link error CI reported,
  the tree of `35f99c5` passes.
- Keep or revert, with reason: keep; the check takes under a minute and the working branch stays green commit
  by commit, which the fast-forward rule for `main` relies on.

### WF-007 — 2026-10-06 — The path to `done` ran the fast tier only
- Observed failure and evidence: red-team lens 097-E (finding 8,
  [handback part 2](briefs/handbacks/2026-10-03-m0-gates-red-team.part-2.md)) set a requirement to `done` with one
  criterion untested and one evidenced by a contract test only; `./scripts/verify.sh` passed (fast tier, 9 of 9
  steps), because `evidence.py check-done` ran in the release tier alone, and `develop` § 6 and § 8,
  `verify-requirement` and `milestone-review` named no tier, so their runs were fast-tier runs.
- Root-cause hypothesis: the Definition of Done said "`./scripts/verify.sh` passes" while only the release tier
  runs every tagged test and judges `done` requirements.
- One proposed workflow/skill/context change: Definition of Done item 4 (CLAUDE.md, requirements README) and the
  three skills name `./scripts/verify.sh --tier release`; the done step runs in every tier and fails failed,
  contract-only and missing evidence there, so the Stop gate holds a wrongly finished requirement at once.
- Expected metric and fixed evaluation set (plus held-out cases): `done` requirements whose criteria lack
  evidence in the run that precedes the transition; evaluation set: the lens's reproduction (AVE-REQ-018 set to
  `done` with AC-3 untagged and AC-2 contract-only) in the fast tier. Held-out: the `done` transitions of M0 and
  of the following milestones.
- Independent review result: pending (the next review of this log; the lead records it).
- Measured before/after result: before, the reproduction passed the fast tier. After, measured through
  `scripts/tests/test_evidence.py::test_the_done_gate_judges_every_tier`: the fast and media tiers fail on the
  missing criterion, and the release tier also fails on a tagged test that did not run.
- Keep or revert, with reason: keep; the step adds seconds to the fast tier and removes the one path on which a
  requirement could reach `done` without a run that judged it.

### WF-008 — 2026-10-06 — Review runs started without a brief; worktree writers confirmed a branch name
- Observed failure and evidence: the review of AVE-REQ-096 at `2df637f`
  ([handback part 7](briefs/handbacks/2026-10-03-m0-gates-red-team.part-7.md)) found seven review workflow runs
  since the brief rule of `a5c81d3` that started without a brief (`wf_ed1f5104-63a`, `wf_e3b34e48-f7e`,
  `wf_eabbb2f5-6a0`, `wf_b5fa6671-c21`, `wf_7d239bd1-b31`, `wf_db16f332-fdf`, `wf_7d9d015c-906`), although
  `CLAUDE.md` § Delegation names review workflows; no rule defined their skeptic stage, and the reports of
  `wf_ed1f5104-63a` persist only as summaries. The same review found that the three runs with writers in
  worktrees the lead created (`wf_164de68e-23b`, `wf_df2de811-039`, `wf_d57d9cab-829`) had the task confirm
  the branch name, where the rule asks for equality with the base commit.
- Root-cause hypothesis: the lead read the exemption of the skills that fork their own agent as covering a
  review run scripted as a workflow, and `develop` § 4 stated the base check for worktrees of the runtime only.
- One proposed workflow/skill/context change: `develop` § 6 defines the review run as a delegated task (brief,
  reviewers following `verify-requirement`, skeptic stage, reports as handback parts); `develop` § 4 and the
  implementer and tester definitions apply the equality check to every linked worktree.
- Expected metric and fixed evaluation set (plus held-out cases): review runs without a brief, and writer
  prompts without the equality line; evaluation set: the fix run and the review run that follow this entry
  (their rows in `docs/workflows/README.md` link a brief; their scripts hold `git rev-parse HEAD` against a
  hash). Held-out: the runs of M1.
- Independent review result: pending (the next review of this log; the lead records it).
- Measured before/after result: before, 7 of 7 review runs without a brief and 3 of 3 worktree-writer runs with
  a branch-name check; no task started from a wrong base (the first commit of each of the six task branches has
  the briefed commit as its parent). After: measured on the two runs of the evaluation set once recorded.
- Keep or revert, with reason: keep; a brief gives every review report a named home, and the equality check is
  the one that fails for a worktree made from another commit.

### WF-009 — 2026-10-06 — A merge on the Windows host dropped an executable bit that only CI could see
- Observed failure and evidence: CI failed the release tier at `fc66eb3` (`scripts/tests/run.sh: Permission
  denied`). The merge of four branches on the Windows host had written the file's index mode as 100644; the
  local release tier passed, because the development container sees every file of the mount as executable.
- Root-cause hypothesis: check 2 read the executable bit from the file system only, and only for `scripts/*.sh`
  and the hooks, so neither the index mode nor the suite runner was checked anywhere before CI.
- One proposed workflow/skill/context change: check 2 of `scripts/check-project-control.sh` covers every entry
  point (scripts, hooks, tooling suites with their runner, the media stand-in) and, for a tracked file, requires
  mode 100755 in the Git index.
- Expected metric and fixed evaluation set (plus held-out cases): CI failures caused by a lost executable bit;
  evaluation set: the tree of `fc66eb3` (the checker now fails it by name) and six suite cases. Held-out: the
  merges of M1 and M2.
- Independent review result: pending (the next review of this log; the lead records it).
- Measured before/after result: before, the local release tier passed and CI failed. After: the checker fails the
  tree of `fc66eb3` in its first step; three mutants of the rule each fail a named case.
- Keep or revert, with reason: keep; the check costs one Git call per entry point.

### WF-010 — 2026-10-07 — Two review rounds found requirement-file statements that no check pins
- Observed failure and evidence: the second round of the final M0 review (`wf_b18a5f3e-54e` at `f996c17`)
  returned FAIL for AVE-REQ-093, AVE-REQ-094 and AVE-REQ-097 and a refuted PASS for AVE-REQ-096 and AVE-REQ-098,
  after the 13 blocking findings of the first round were closed. Each of the six blocking findings and both
  refutations is a sentence of § Edge cases, § Verification strategy or § Implementation evidence (or of a
  record it cites) that holds for the forms a fix listed and fails for a neighbouring form: a footnote as a
  container, raw HTML other than a comment in the roadmap, a device name with a line feed, an ignored file
  outside four directories, a cache in the tree, a hook named in a comment, a limit the runs exceeded
  ([handback parts 1 to 5](briefs/handbacks/2026-10-06-m0-final-review-2b.part-1.md)).
- Root-cause hypothesis: a fix closes the reported form and adds a sentence about its class; nothing compares
  each sentence with a case that fails without it, so the reviewer is the first to test the sentence.
- One proposed workflow/skill/context change: a fix track ends with a statement audit of its requirement's three
  sections. Per sentence that states a behavior it names the suite case and the mutant that fails it, adds the
  case, rewords the sentence, or words it as a limit with its inspection; a sentence with "every", "no other",
  "only", "never" or "whenever" holds through an allow-list or names its forms. The table goes into the handback
  ([fix brief](briefs/2026-10-07-m0-review-2-fixes.md) § Dependencies and constraints).
- Expected metric and fixed evaluation set (plus held-out cases): blocking findings per review round that cite a
  requirement-file statement; evaluation set: the third review round of the five M0 requirements. Held-out: the
  first reviews of M1 requirements.
- Independent review result: pending (the next review of this log; the lead records it).
- Measured before/after result: before, 13 in round one and 8 in round two (6 blocking findings, 2 refutations).
  After: measured at the third round.
- Keep or revert, with reason: keep until measured; the audit costs one pass per requirement file.

### WF-011 — 2026-10-07 — A recorded resource limit that three runs exceeded
- Observed failure and evidence: `docs/ENVIRONMENT_CAPABILITIES.md` § Limits item 5 said since `d4147d8` that
  reviewer clones go one at a time while drive `C:` is 98 % full. The three runs launched after it
  (`wf_7d9d015c-906`, `wf_5cd13360-464`, `wf_b18a5f3e-54e`) worked two at a time, 31 backend environments had
  gathered on the state volume (744 MiB), and the lead repaired AVE-REQ-094 code (`b4f503f`) while two writers
  of the fix round ran. The skeptic refuted the PASS of AVE-REQ-096 AC-4 with these records
  ([handback part 3](briefs/handbacks/2026-10-06-m0-final-review-2b.part-3.md)).
- Root-cause hypothesis: the limit was written from the free-space figure without a measurement of a clone's
  footprint, and `develop` § 4 counted launched writing agents only: neither clones nor the lead's own code
  work, which the baseline's limit of two concurrent code-writing tasks includes.
- One proposed workflow/skill/context change: `develop` § 4 Concurrency limits counts reviewer clones (at most
  two; each removes its backend environment, its container and itself) and the lead's own code work among the
  two writers; item 5 states the measured footprint and the limit that follows from it.
- Expected metric and fixed evaluation set (plus held-out cases): runs whose records exceed a stated limit;
  evaluation set: the fix round from the brief of 2026-10-07 and the third review round. Held-out: the launches
  of M1 and M2.
- Independent review result: pending (the next review of this log; the lead records it).
- Measured before/after result: before, 3 of 3 runs above the stated clone limit and one overlap of three code
  writers. After: measured on the two runs of the evaluation set.
- Keep or revert, with reason: keep; the count is one line of the launch record, and the cleanup returned
  577 MiB of the state volume.
