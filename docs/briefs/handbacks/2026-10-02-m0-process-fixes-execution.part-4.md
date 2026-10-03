# Handback — M0 process fixes, part 4 (procedures and concurrency): items 4, 5, 8, 9, 14, 16, 17, 18, 26

Brief: `docs/briefs/2026-10-02-m0-process-fixes-execution.md` (part 4) with the findings of
`docs/briefs/2026-10-02-m0-process-verification-fixes.md`, plus the lead decisions of 2026-10-03 after part 3:
(a) the commit rule of item 15, (b) the drafts directory for the unlaunched M1 and M2 briefs, (c) asynchronous
hooks in check 12, (d) part 3's other open questions answered. Branch `m0-process-fixes` (worktree
`.claude/worktrees/m0-process-fixes`), built on parts 1 (`fb61875`), 2 (`3f7c44d`) and 3 (`a62e197`).
Commit: the commit that adds this file, subject "AVE-REQ-094, AVE-REQ-096, AVE-REQ-098: require persisted
briefs and handbacks, enforce one heavy media job"
(`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-4.md`).

Result: COMPLETE. Every item of part 4 and the three lead decisions are done; item 26 is a set of proposals
for the lead (the execution brief's decision).

Resumed from the uncommitted edits of an interrupted agent. Every hunk was judged against the briefs; the
suites passed on them before any change (checker 189/0, verify tiers 23/0, `check-project-control.sh` OK on
the worktree), and none was a leftover mutation. Kept: the heavy-media lock in `scripts/verify.sh` and its
tiers-suite cases, check 7's PROGRESS.md claim rule and check 11's handback names with their cases, the
procedure edits (CLAUDE.md, develop, resume-project, verify-requirement, delivery skill, agent inputs), the
WORKFLOW_LOG and ENVIRONMENT_CAPABILITIES corrections and `docs/briefs/README.md` § Handbacks. Repaired: the
tiers suite checked the lock state inside verify.sh's own shell, so a mutation that never exported
`AVE_HEAVY_LOCK_HELD` survived (L6 below); the check now runs in a child process. Narrowed: CLAUDE.md
§ Delegation named "every delegated task the lead composes", which also caught the setup skills; it now names
the tasks the `develop` loop delegates and states what the setup skills do, and the committed-brief rule names
its one exception (a brief written inside an uncommitted merge joins the merge commit). Added: everything
under items 8, 14 and 26, WF-005, ARCHITECTURE.md § Testing strategy item 6, the requirement sections and the
lead decisions.

Mutations: `var/mutations/part4.py` (gitignored) applies each mutation to one file, deletes `__pycache__`
directories, runs one suite inside the development container, restores the file from its in-memory copy and
asserts the restored SHA-256 (`scripts/verify.sh` `b3cd465b437d…`, `scripts/check-project-control.sh`
`a10f67627601…`). `git diff` after the runs holds the intended change only.

## Items

### Item 4 — AVE-REQ-096 AC-1: a committed brief before every delegated task (done)
- Change: `CLAUDE.md` § Delegation — every task the `develop` loop delegates (implementer, tester, researcher,
  architect, workflow run, review workflows included) starts from a brief written from the template and
  committed before the launch (inside an uncommitted merge it joins the merge commit), whose input revision
  names a commit and "isolated worktree" or "main working tree"; the prompt passes the brief path and the base
  commit; `verify-requirement` and `architecture-review` take no brief; the setup skills give their agents the
  task text the skill defines. `.claude/skills/develop/SKILL.md` § 3 steps 4–5 (researcher, architect through a
  brief), § 4 "Brief first" (template, input revision with the current commit plus the self-reference, drafts,
  commit before the launch, the prompt template naming the brief), § 5 step 2 (tester brief: main working tree
  plus the uncommitted implementation), § 7 (architect brief at non-convergence). Agent inputs:
  `.claude/agents/implementer.md`, `tester.md`, `researcher.md`, `architect.md` (brief path first; none through
  `architecture-review`), `reviewer.md` (ad hoc reviews during development name their brief).
  `.claude/skills/ai-video-editor-delivery/SKILL.md` step 4. `docs/briefs/README.md` (who needs a brief, the
  input-revision template line, the commit rule). `docs/ENVIRONMENT_CAPABILITIES.md` § Limits item 3 corrected:
  concurrent writers run in worktrees, a single main-tree task (the tester, a repair inside an uncommitted
  merge) keeps its partial work in the main working tree. `docs/workflows/README.md`: runs since 2026-10-02
  start from a committed brief; the three earlier runs predate the rule. AVE-REQ-096 § Edge cases,
  § Verification strategy AC-1, § Implementation evidence.
- Test: inspection — `grep -n "Brief first" .claude/skills/develop/SKILL.md`, `grep -n "Brief before delegating"
  CLAUDE.md`, `grep -n "brief" .claude/agents/*.md`; mechanical part: check 11's commit rule (lead decision a,
  below) and handback names (item 17).
- Mutation: not applicable to the procedure text; the mechanical parts have their own (C1–C7).

### Item 5 — AVE-REQ-096 AC-4: one heavy media job at a time, enforced (done)
- Change: `scripts/verify.sh` — `hold_heavy_lock`: the media and release tiers take an exclusive `flock` on
  `${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}` (file descriptor 9) before the first step and hold
  it to the summary; a held lock prints one line `verify.sh: waiting for the heavy-media lock <file> (…)` and
  waits; `AVE_HEAVY_LOCK_HELD=1` is exported to the steps; a caller that sets it gets no second lock; the fast
  tier takes no lock; without `flock` the media and release tiers fail before any step; `run_step` closes
  descriptor 9 for each step, so no process a step leaves behind keeps the lock. Header comment.
  `docs/ARCHITECTURE.md` § Testing strategy item 6 (lock file, waiting line, `AVE_HEAVY_LOCK_HELD`, the
  `flock <lock file> <command>` form inside and outside the development container) and the media command under
  the lock. `.claude/skills/develop/SKILL.md` § 4 Concurrency limits (two writing agents counted across every
  workflow and subagent, one heavy media job, heavy jobs queue on the lock, heavy review lenses in sequence
  within a workflow, raising a limit needs a measurement); `CLAUDE.md` § Delegation (Concurrency);
  `.claude/skills/ai-video-editor-delivery/SKILL.md` step 4; `.claude/skills/verify-requirement/SKILL.md`
  step 5.2; `.claude/agents/reviewer.md`, `tester.md`; `docs/briefs/README.md` template (constraints).
  `docs/WORKFLOW_LOG.md`: WF-003's measured result corrected (two heavy media jobs at once and four media-heavy
  agents on 2026-10-02 broke the limit; nothing was measured), operating baseline points to the enforcement,
  new WF-005 records the enforcement and its test. `docs/ENVIRONMENT_CAPABILITIES.md` § Limits item 2.
  `scripts/tests/run.sh` suite list. AVE-REQ-096 § Edge cases, § Verification strategy AC-4,
  § Implementation evidence.
- Test: `scripts/tests/test-verify-tiers.sh` § "one heavy media job at a time: the heavy-media lock"
  (`AVE-REQ-096 AC-4`; every run uses a lock file in the suite's temp dir): "media tier steps run while the
  run holds the lock", "release tier steps run while the run holds the lock" (a child process sees
  `AVE_HEAVY_LOCK_HELD=1` and cannot take the lock), "fast tier takes no lock (runs while another process
  holds it)", "a caller that holds the lock sets AVE_HEAVY_LOCK_HELD=1: no second lock", "a media run while
  the lock is held prints one waiting line", "it runs no step while the lock is held (no output for 2 s,
  process alive)", "after the release it runs the media tier under the lock", "default lock file:
  $TMPDIR/ave-heavy-media.lock", "a process a step leaves behind keeps no lock after the run", "without flock
  the media tier fails before any step", "without flock the fast tier still runs".
- Mutations (tiers suite, 23 cases): L1 (`hold_heavy_lock` never called): 11 FAIL (both lock-held cases, the
  waiting line, no step while held, after the release, default lock file, leftover process, no flock, and
  the three tier-membership cases whose media step now fails). L2 (`AVE_HEAVY_LOCK_HELD` ignored): 1 FAIL ("a
  caller that holds the lock …", the run waits until its 60 s limit). L3 (the fast tier takes the lock): 2
  FAIL ("fast tier takes no lock …", "without flock the fast tier still runs"). L4 (steps inherit descriptor
  9): 1 FAIL ("a process a step leaves behind keeps no lock …"). L5 (no waiting line): 1 FAIL. L6
  (`AVE_HEAVY_LOCK_HELD` set but not exported): survived with the interrupted agent's suite (the check ran as
  a shell function inside verify.sh); with the check in a child process 8 FAIL. L7 (no `flock` check): 1 FAIL
  ("without flock the media tier fails before any step").

### Item 8 — AVE-REQ-098 AC-3: PROGRESS.md names only what the remote holds (done)
- Change: `CLAUDE.md` § Git — before PROGRESS.md names a commit, branch or file, push it as far as the
  session's push permission allows: the working branch after each commit, each worktree branch after its
  handback (merged into the working branch, or pushed alongside it while unmerged); without push permission
  § Blockers lists the local-only refs with the push command; scratchpad files stay unnamed until committed and
  pushed. `.claude/skills/develop/SKILL.md` § Parallel work (step 4.4 pushes the working branch after each
  integration, step 4.6 pushes a blocked branch before PROGRESS.md names it, the reachability paragraph) and
  § 13. AVE-REQ-098 § Edge cases (the lead's own session ends), § Verification strategy AC-3 (the inspection
  command below), § Implementation evidence.
- Test: inspection, as the finding asks — `grep -oE '[0-9a-f]{7,40}' docs/PROGRESS.md | sort -u | while read
  -r h; do git cat-file -e "$h^{commit}" 2>/dev/null || continue; git branch -r --contains "$h" | grep -q . ||
  echo "not on the remote: $h"; done` prints nothing on this tree (all nine commits PROGRESS.md names are on
  `origin/ccr-af7078da-q8r8mf`), and `git branch -r` lists every branch it names: `m0-process-fixes` and
  `m0-media-follow-ups` are local only (proposed update below).
- Mutation: not applicable (procedure text and an inspection).

### Item 9 — AVE-REQ-098 AC-3: no claim of ongoing execution (done)
- Change: `.claude/skills/develop/SKILL.md` § 13 — delegated work in flight is recorded stop-safe
  ("launched <date>; verdict not recorded; on resume without a recorded verdict, re-run <exact command>", with
  the brief path); PROGRESS.md never says work is running. `.claude/skills/resume-project/SKILL.md` step 5
  "Delegated work": nothing an earlier session launched is running; an unrecorded verdict means interrupted
  work, re-run from the brief, the handback and the branch; a review without a recorded verdict counts as not
  done. `scripts/check-project-control.sh` check 7 (`AWK_PROGRESS_CLAIMS`): outside fenced blocks, HTML
  comments and code spans, a PROGRESS.md line with the word "running", "underway" or "in flight"/"in-flight"
  fails with its line number; "nothing is running", "not running" and "no longer running" pass;
  `strip_comments`, `strip_code_spans` and `backtick_run_at` moved into the shared `AWK_LIB`. The PROGRESS.md
  header comment already carries the stop-safe form. AVE-REQ-098 § Edge cases, § Verification strategy AC-3,
  § Implementation evidence.
- Test: `scripts/tests/test-checker.sh` (`AVE-REQ-098 AC-3`): "PROGRESS: review running" (line 7), five
  "PROGRESS claim: …" cases (Running:, in flight, in-flight, underway, RUNNING), "PROGRESS: stop-safe in-flight
  line accepted", "PROGRESS: claim words in comments, fences and code spans accepted", "PROGRESS: rerunning
  and not running accepted".
- Mutations: C8 (the claim check never runs): 6 FAIL (every claim case). C9 (negations not exempted): 2 FAIL
  (stop-safe line, "rerunning and not running"). C10 (claims read inside comments and code spans): 1 FAIL.

### Item 14 — AVE-REQ-094 AC-4: independent review without subagents (done)
- Change: `CLAUDE.md` § Delegation (fallback: the main session runs the lifecycle sequentially; independent
  review in a fresh session, or a context holding nothing of the implementation work, that follows
  `verify-requirement` from the repository alone; recorded as a sequential review; the requirement stays
  `verification` until it is recorded). `.claude/skills/develop/SKILL.md` § 6 step 3 (the same, with the
  Status-log note `sequential review in a fresh session`). `.claude/skills/ai-video-editor-delivery/SKILL.md`
  step 6. AVE-REQ-094 § Edge cases, § Verification strategy AC-4, § Implementation evidence.
- Test: inspection — `grep -n "Fallback without workflows" CLAUDE.md`, `grep -n "Without subagents"
  .claude/skills/develop/SKILL.md .claude/skills/ai-video-editor-delivery/SKILL.md`.
- Mutation: not applicable (procedure text).

### Item 16 — AVE-REQ-096 AC-2: base commit checked by equality (done)
- Change: `.claude/skills/develop/SKILL.md` § 4 prompt template (`Worktree: yes — base commit <full hash>;
  before changing anything confirm that git rev-parse HEAD prints exactly that hash, else return BLOCKED`) and
  § Parallel work step 2; `.claude/agents/implementer.md` § Worktrees (the same check, BLOCKED with both
  hashes). AVE-REQ-096 § Edge cases and § Verification strategy AC-2.
- Test: inspection — `git grep -n -e is-ancestor -e merge-base -- .claude CLAUDE.md` prints only the
  `Bash(git merge-base *)` permission of `.claude/settings.json`; `git grep -n "rev-parse HEAD" .claude`
  shows the equality check in develop § 4 and the implementer agent.
- Mutation: not applicable (procedure text).

### Item 17 — AVE-REQ-096 AC-1: handbacks persist; WF-001 corrected (done; the reviews are the lead's)
- Change: `docs/briefs/README.md` § Handbacks (`handbacks/<brief-slug>.md`, `.part-<n>.md` for parts; the
  task or the lead writes it; committed with the work; unchanged afterwards); `CLAUDE.md` § Delegation;
  `.claude/skills/develop/SKILL.md` § 4 (persist the report first) and § Parallel work (the handback joins
  the integration or blocked commit); `.claude/agents/implementer.md` § Boundaries (it may write the handback
  file its brief names). `scripts/check-project-control.sh` `check_handbacks` (check 11): a file in
  `docs/briefs/handbacks/` is named `<brief-slug>.md` or `<brief-slug>.part-<n>.md` (n ≥ 1, no leading zero)
  after an existing `docs/briefs/<brief-slug>.md`. `docs/WORKFLOW_LOG.md` WF-001: the mutation runs lived in
  session-only handbacks, the round-3 reviewers repeated them, handbacks persist since 2026-10-02; WF-001 to
  WF-004 (and the new WF-005) say "Review of this log entry: pending (the lead records it)".
- Test: `scripts/tests/test-checker.sh` (`AVE-REQ-096 AC-1`): "handback and part handback of a brief
  accepted", "handback without its brief", "handback part without a number", "handback that is no Markdown
  file", "handback named after the README".
- Mutations: C6 (`check_handbacks` never runs): 4 FAIL (every rejected handback). C7 (part number never
  checked): 1 FAIL ("handback part without a number").

### Item 18 — AVE-REQ-096 AC-2, AC-4: concurrent writers in worktrees only (done)
- Change: the option "disjoint path ownership for concurrent writers in the main tree" is removed.
  `docs/WORKFLOW_LOG.md` operating baseline (concurrent writers in worktrees; one writing task in the main
  tree only while no other agent writes; read-only reviews need no worktree; `wf_5493b930-f7c` ran two writers
  in the main tree before AVE-REQ-096 ended that option). `.claude/skills/develop/SKILL.md` § 4 Concurrency
  limits; `docs/ENVIRONMENT_CAPABILITIES.md` § Limits item 3. AVE-REQ-096 § Edge cases.
- Test: inspection — `git grep -n -i "disjoint" -- .claude CLAUDE.md docs/WORKFLOW_LOG.md
  docs/ENVIRONMENT_CAPABILITIES.md` names disjoint files only together with worktrees (CLAUDE.md § Delegation,
  develop § Parallel work, the implementer description) and the historical `wf_5493b930-f7c` run.
- Mutation: not applicable (procedure text).

### Item 26 — all five: Test evidence inspection lines and the evidence tier (proposed; the lead's)
- The tooling suites (`scripts/tests/*.sh`) run only in the release tier (step "Verification tooling regression
  suites"), so their criterion evidence comes from a release-tier manifest: run `./scripts/verify.sh --tier
  release`, then `python3 -B scripts/evidence.py show AVE-REQ-093 AVE-REQ-094 AVE-REQ-096 AVE-REQ-097
  AVE-REQ-098 --require-fresh`. A fast-tier manifest holds only the `scripts/tests/test_*.py` results.
- Proposed `## Test evidence` lines (the lead adds the result after its own check; criteria with tagged tests
  take `- AC-n → <test location> — pass` from the manifest):
  - AVE-REQ-093 AC-2 → inspection: PRODUCT, ARCHITECTURE, ROADMAP, PROGRESS, ASSUMPTIONS and TRACEABILITY hold
    the baseline content and keep their bootstrap sections (`git log -p --follow <file>` since `f605c6c`).
  - AVE-REQ-094 AC-1 → inspection: the Claude Code rows of `docs/ENVIRONMENT_CAPABILITIES.md` (workflow tool,
    subagents, worktrees, hooks, Permissions, Models) checked against the session (version by `claude
    --version` on the host, the deny rule by the refused force push, the model override by a completed run).
  - AVE-REQ-094 AC-2 → inspection: completed runs `wf_5493b930-f7c` (two writers; `486b3a0`, `24499a6`) and
    `wf_1a23bf0d-2a0` (three lenses; PASS) with structured handbacks and dependency-aware parallelism
    (`docs/workflows/`).
  - AVE-REQ-094 AC-3 → inspection: every script in `docs/workflows/` ran on the installed runtime (run IDs
    recorded); none calls an API outside the runtime's documented calls.
  - AVE-REQ-094 AC-4 → inspection: `CLAUDE.md` § Delegation fallback, `develop` § 6 step 3 (fresh-session
    review recorded as sequential), delivery skill steps 3 and 6; WF-002 records a real sequential fallback.
  - AVE-REQ-096 AC-1 → inspection: `CLAUDE.md` § Delegation and `develop` § 3–5 require a committed brief
    before every delegated task; the briefs in `docs/briefs/` match their tasks; the handbacks of this task
    lie in `docs/briefs/handbacks/`.
  - AVE-REQ-096 AC-2 → inspection: `.claude/settings.json` `worktree.baseRef: "head"`; `develop` § 4 and
    `.claude/agents/implementer.md` check `git rev-parse HEAD` by equality; worktree `m0-process-fixes`
    started at `6736401` as briefed.
  - AVE-REQ-096 AC-3 → inspection: `verify-requirement` and the reviewer start from the requirement, the brief
    and the diff; media-critical claims were checked on real rendered outputs in three rounds (WF-001).
  - AVE-REQ-096 AC-4 → inspection: `develop` § 4 Concurrency limits, the WORKFLOW_LOG operating baseline and
    WF-005; subagents cannot spawn subagents.
  - AVE-REQ-097 AC-3 → inspection: the hooks were smoke-tested before use (ASM-001, ASM-003).
  - AVE-REQ-098 AC-1 → inspection: `git log -p docs/PROGRESS.md` shows an update after each coherent unit;
    each unit's commit records its changed files (`git log --stat`).
  - AVE-REQ-098 AC-3 → inspection: WF-002; `docs/ENVIRONMENT_CAPABILITIES.md` § External gaps (one unblock
    action per gap); PROGRESS.md § Blockers; the remote holds every commit PROGRESS.md names (the command of
    § Verification strategy AC-3 prints nothing) and every branch it names.
  - AVE-REQ-098 AC-4 → inspection: `.claude/hooks/*.sh` hold no loop or daemon; `.claude/settings.json`
    passes check 12.
- Order of the moves to `done`: AVE-REQ-093 → AVE-REQ-094 → AVE-REQ-096, AVE-REQ-097, AVE-REQ-098 (each
  after its `verify-requirement` PASS on the release-tier evidence).

## Lead decisions of 2026-10-03

### (a) Item 15's commit rule — AVE-REQ-096 AC-1, AC-2 (done)
- Change: `scripts/check-project-control.sh` check 11 (`AWK_BRIEF`, `names_commit`, `word_char`): the
  `## Input revision` section of a brief names a commit — a token of 7 to 40 lowercase hex digits with no
  letter, digit, `_` or `-` on either side, or the self-reference `git log -1 --format=%h -- <path of this
  brief>`; otherwise "section '## Input revision' names no commit (…)". Written without regex intervals, so
  mawk, gawk, original-awk and busybox agree. Header comments; `docs/briefs/README.md` § Template;
  `.claude/skills/develop/SKILL.md` § 4. Every brief in `docs/briefs/` passes (hashes in the 2026-10-01 and
  round-3 briefs, the self-reference in the four others).
- Test: `scripts/tests/test-checker.sh` (`AVE-REQ-096 AC-1`, `AVE-REQ-096 AC-2`): "input revision without a
  commit", "input revision: branch name only", "input revision: six hex digits", "input revision: 41 hex
  digits", "input revision: abbreviated hash accepted", "input revision: full hash accepted", "input revision:
  self-reference accepted", "input revision: self-reference to another brief".
- Mutations: C1 (rule off): 5 FAIL (every rejected case). C2 (delimiters ignored): 2 FAIL (branch name only,
  self-reference to another brief, both carrying `af7078da` inside `ccr-af7078da-q8r8mf`). C3 (length bounds
  ignored): 2 FAIL (six and 41 digits). C4 (self-reference ignored): 1 FAIL ("self-reference accepted").

### (b) Drafts for the unlaunched M1 and M2 briefs (done)
- Change: `git mv` of `docs/briefs/2026-10-02-m1-backend-core.md` and `docs/briefs/2026-10-02-m2-synchronization.md`
  into `docs/briefs/drafts/`; in the M2 draft the relative link to ASSUMPTIONS.md gains one `../` (check 6
  would fail otherwise; the only content change). `docs/briefs/README.md` § Drafts: a draft names no input
  revision yet, check 11 leaves it alone, and at launch the lead fills the input revision and moves it to
  `docs/briefs/` in the commit before the launch. `docs/PROGRESS.md` § In progress: the two links point to the
  drafts (the only PROGRESS.md edit). `.claude/skills/develop/SKILL.md` § 4 names the drafts directory.
- Test: `./scripts/dev-container.sh ./scripts/check-project-control.sh` — before the move the two briefs were
  the only errors ("section '## Input revision' names no commit"); after it OK (2351 links resolve).

### (c) Asynchronous hooks — AVE-REQ-098 AC-4 (done)
- Change: `scripts/check-project-control.sh` check 12 (`PY_SETTINGS_POLICY`): a hook entry whose `async` is
  set (any value other than absent or false) fails with "hooks.<event>[<n>] runs a hook asynchronously
  ("async": …), which escapes its timeout". Header comment; `docs/ENVIRONMENT_CAPABILITIES.md` Project hooks
  and Permissions rows; AVE-REQ-098 § Edge cases, § Verification strategy AC-4, § Implementation evidence.
- Test: `scripts/tests/test-checker.sh` (`AVE-REQ-098 AC-4`): "hook entry with async true", "hook entry with
  async false accepted".
- Mutation: C5 (async accepted): 1 FAIL ("hook entry with async true").

### (d) Part 3's other open questions
Recorded as answered with no change: open question 2 is decision (c); 3 (check 12 reads
`.claude/settings.json` only) and 4 (the Codex unblock command joins with the AVE-REQ-052 adapter) stand as
part 3 described them.

## Commands and results
- `./scripts/dev-container.sh bash scripts/tests/test-verify-tiers.sh` — on the interrupted agent's edits
  `VERIFY TIERS TOTAL: pass=23 fail=0`; final `pass=23 fail=0`.
- `./scripts/dev-container.sh bash scripts/tests/test-checker.sh` — on the interrupted agent's edits
  `CHECKER TOTAL: pass=189 fail=0`; final `pass=199 fail=0`.
- `./scripts/dev-container.sh ./scripts/check-project-control.sh` — after rule (a) and before the move: FAIL,
  exactly the M1 and M2 briefs; after the move: `OK: 49 required files, 6 executable scripts, 5 agents, 9
  skills, 2351 links in 188 Markdown files, 132 requirement files, 9 ADRs; 0 warning(s)`.
- `./scripts/dev-container.sh python3 -B var/mutations/part4.py` — L1–L7 and C1–C10 each caught after the L6
  repair (results above); each file restored with its original SHA-256.
- Item 8 inspection command on `docs/PROGRESS.md` — no output; `git branch -r --list origin/m0-process-fixes`
  and `origin/m0-media-follow-ups` — empty.
- `./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks` — `scripts/tests/run.sh: PASS (6 suites)`
  (CHECKER 769/0 over mawk, gawk, original-awk and busybox; BASELINE 75/0; STOP HOOK 72/0; SESSION START 31/0;
  VERIFY TIERS 23/0; PROBE 28/0), 4 min 5 s.
- `./scripts/verify.sh` (fast tier, with this handback in the tree) — `verify.sh: PASS — tier fast (9 of 9
  steps passed)`.

## Proposed updates for the lead-owned documents
- `docs/PROGRESS.md` § In progress — the worktree branches `m0-process-fixes` and `m0-media-follow-ups` are
  local only: push them alongside the working branch (`git push origin m0-process-fixes m0-media-follow-ups`)
  or list them under § Blockers with that command (`CLAUDE.md` § Git, item 8). § Verification status after
  the release run: the commit and the tier.
- `docs/PROGRESS.md` — part 4 of the M0 process fixes committed on `m0-process-fixes`; next: release tier,
  re-verification in the order 093 → 094 → 096/097/098.
- `docs/TRACEABILITY.md` — AVE-REQ-094 row: Implementation adds `CLAUDE.md` § Delegation and
  `.claude/skills/develop/SKILL.md`. AVE-REQ-096 row: Implementation `docs/briefs/`, `docs/briefs/handbacks/`,
  `scripts/check-project-control.sh`, `scripts/verify.sh`, `.claude/skills/develop/SKILL.md`, `CLAUDE.md`,
  `.claude/settings.json`; Tests `scripts/tests/test-checker.sh` (AC-1, AC-2), `scripts/tests/test-verify-tiers.sh`
  (AC-4), inspection (AC-1–AC-4). AVE-REQ-098 row (with part 3's proposal): Implementation adds `CLAUDE.md`
  § Git, `.claude/skills/develop/SKILL.md`, `.claude/skills/resume-project/SKILL.md`,
  `scripts/check-project-control.sh`; Tests `scripts/tests/test-session-start.sh` (AC-1, AC-2),
  `scripts/tests/test-checker.sh` (AC-2, AC-3, AC-4), `scripts/tests/test-probe-environment.sh` (AC-3),
  `scripts/tests/test-stop-hook.sh` (AC-4), inspection (AC-1, AC-3, AC-4).
- `docs/WORKFLOW_LOG.md` — an independent review recorded for each entry WF-001 to WF-005 (item 17; AT-29
  needs a reviewed log): replace each "pending (the lead records it)" with the review's result.
- `docs/ASSUMPTIONS.md` — new entry: the heavy-media lock serializes jobs that share one lock file; agents in
  separate containers share it only when `AVE_HEAVY_LOCK` points at a file every container mounts (the
  working branch's `scripts/dev-container.sh` sets `/state/ave-heavy-media.lock` since `a55605b`, outside
  this worktree) — reason: `flock` works per file — impact: a host with another isolation scheme needs the
  same shared path; CI runs one job per runner.
- `docs/ASSUMPTIONS.md` — new entry: check 11 counts a commit as lowercase hex (git's output) and accepts an
  English word of 7 or more hex letters (for example "defaced") as a hash — reason: the rule stays mechanical
  (lead decision a) — impact: negligible; the brief's reviewer reads the input revision.
- `docs/ASSUMPTIONS.md` — new entry: check 7 rejects the words "running", "underway" and "in flight" in
  PROGRESS.md outside comments, fences and code spans, with "nothing is running", "not running" and "no longer
  running" allowed — reason: AVE-REQ-098 AC-3 forbids claiming ongoing execution — impact: other uses of
  the words need rephrasing.
- `docs/ARCHITECTURE.md` § Verification pipeline (outside this part's allowed section): the media and release
  tiers hold the heavy-media lock (§ Testing strategy item 6); after the merge with `a55605b`, item 6 can name
  the development container's shared lock path.
- Drafts at launch: `docs/briefs/drafts/2026-10-02-m1-backend-core.md` and `…-m2-synchronization.md` ask the
  task to confirm `git log --oneline -1`; at launch the lead can state the equality check of develop § 4
  (`git rev-parse HEAD` equals the base commit) with the input revision.
- AVE-REQ-094, AVE-REQ-096, AVE-REQ-098 § Status — optional log lines: Edge cases, Verification strategy and
  Implementation evidence updated for fix brief items 14 (094); 4, 5, 15 (commit rule), 16, 17, 18 (096); 8, 9,
  23 (async) (098); statuses stay `in-progress`.

## Open questions
None.
