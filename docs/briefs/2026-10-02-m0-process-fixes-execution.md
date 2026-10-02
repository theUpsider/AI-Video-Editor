# Brief — Execute the M0 process fix brief in four parts on the development container

## Requirements
AVE-REQ-093, AVE-REQ-094, AVE-REQ-096, AVE-REQ-097, AVE-REQ-098: items 1–26 of
[the fix brief](2026-10-02-m0-process-verification-fixes.md), whose findings, evidence and required fixes stay
the contract. This brief adds the execution plan, the decisions the fix brief left open and the facts of the
new host.

Parts, run in sequence in one worktree, one commit per part:
1. Baseline checker — items 1, 2, 10.
2. Evidence tooling — items 6, 7, 11, 19, 20, 21.
3. Checker, hooks and probe — items 3, 12, 13, 15, 22, 23, 24, 25.
4. Procedures and concurrency — items 4, 5, 8, 9, 14, 16, 17, 18, 26.

Decisions:
- Item 5: enforce the limit (option b). `./scripts/verify.sh` holds an exclusive `flock` on
  `${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}` for the whole run of the media and release tiers,
  prints one line while it waits, and exports `AVE_HEAVY_LOCK_HELD=1` to its steps; a caller that already holds
  the lock sets that variable and verify.sh takes no second lock. The fast tier takes no lock. Every heavy media
  command outside verify.sh (a targeted `pytest -m "media or slow"` run, a reviewer's media reproduction) runs
  as `flock <lock file> <command>`. The limit stays two concurrent writing agents plus one heavy media job; the
  develop and delivery skills say how the lead counts heavy jobs across concurrent workflows (the lock
  serializes them; the lead launches at most two writing agents). WF-003's measured result is corrected and a
  new WF entry records the enforcement with its test.
- Item 17: handbacks persist as `docs/briefs/handbacks/<brief-slug>[.part-<n>].md` (a subdirectory, outside the
  heading check of `docs/briefs/*.md`); briefs/README.md, the develop skill and CLAUDE.md § Delegation name the
  convention. Each part of this task writes its own handback there.
- Items 3 and 13, facts measured by the lead in this session (2026-10-02): Claude Code 2.1.282, desktop app on
  Windows 11 ARM64; the `claude` command exists on the host and is absent inside the development container, so
  the probe reports the version when the command is on PATH and "not installed" otherwise. Permission mode: an
  automatic mode in which a classifier reviews tool calls; it denied one call of this session with a stated
  reason and the session continued. Project rules: the allow and deny lists of `.claude/settings.json`; a denied
  rule is checked by attempting `git push --force --dry-run origin HEAD:refs/heads/permission-probe` and
  recording whether the permission system blocks it. Launcher-level settings: none visible to the session
  beyond the project file and the gitignored `.claude/settings.local.json`. OS user and writability are
  shell-observable in the probe. Models: the session's model is named only in the session's system context;
  subagents and workflow agents inherit it by default; the Agent tool accepts a `model` override from a fixed
  list of tier aliases and the Workflow `agent()` call accepts `opts.model`; a workflow agent launched with an
  override on 2026-10-02 completed (the lead records the run ID in the Models row after the run). Repository
  text describes how models are observed and overridden and carries no model identifier.
- Item 26: the lead writes the `## Test evidence` sections after the reviews; part 4 proposes the
  `- AC-n → inspection: …` lines in its handback.

## Input revision
`ccr-af7078da-q8r8mf` at the commit that adds this brief
(`git log -1 --format=%h -- docs/briefs/2026-10-02-m0-process-fixes-execution.md`); isolated worktree
`.claude/worktrees/m0-process-fixes` on branch `m0-process-fixes`, created by the lead from that commit. Add
commits; never amend.

## Allowed paths
The allowed paths of the fix brief, plus `docs/briefs/handbacks/**` (new) and `docs/workflows/README.md`.

## Forbidden paths
The forbidden paths of the fix brief, plus `.devcontainer/**` and `scripts/dev-container.sh` (the lead's), and
every file outside the worktree.

## Dependencies and constraints
- [ADR-009](../decisions/ADR-009-linux-development-container-for-other-hosts.md): the host is Windows; edit
  files with the file tools, and run every check through the development container. `./scripts/verify.sh`
  enters it by itself; other commands take the prefix `./scripts/dev-container.sh`.
- Files keep LF line endings. A new script gets its executable bit with `git update-index --chmod=+x <path>`
  after `git add`.
- One heavy media job at a time across every agent: until item 5 lands in the worktree, a media or release
  tier run is `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier <tier>`.
- Each fix gets a test confirmed to fail without it (mutation; delete `__pycache__` first, WF-004). Revert a
  mutation with the inverse edit or `git checkout -- <file>` inside the worktree.
- Commit messages: `AVE-REQ-NNN[, AVE-REQ-NNN]: <imperative summary>` with the session trailers the launch
  prompt names. Never push, merge or switch branches; never run `git worktree prune`.
- Style: affirmative statements (the fix brief's style rule); no model identifiers in repository files.

## Test commands
- Per part: `./scripts/verify.sh` (fast tier) passes, and
  `./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks` passes when the part touched
  `scripts/**` or `.claude/hooks/**`.
- After part 4: `./scripts/verify.sh --tier release` passes;
  `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 AVE-REQ-094 AVE-REQ-096 AVE-REQ-097 AVE-REQ-098 --require-fresh`
  reports the per-criterion states.

## Handback schema
Per item: change (files), test (node or case name), mutation result. Commands with results, the part's commit
hash, proposed updates for the lead-owned documents, open questions. Written to
`docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-<n>.md` and returned as the final report.
