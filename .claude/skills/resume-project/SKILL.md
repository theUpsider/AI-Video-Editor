---
name: resume-project
description: Reconstructs the current project state from the repository and continues the highest-priority unblocked work. Use at every session start, after context compaction or a session restart, when a "Project state" block was injected, or whenever the next step is unclear.
---

# Resume project

Rebuild working state from the repository in a few tool calls, then continue. Read only what the steps name. Never ask the human "what were we doing?" when the repository can answer.

## Fast path

Run these in one Bash call (skip lines the injected "Project state" block already answers):

```sh
grep -m1 '^\*\*Status:\*\*' docs/PRODUCT.md docs/ARCHITECTURE.md; ls docs/product-inputs 2>/dev/null
grep -H '^status:' docs/requirements/AVE-REQ-*.md 2>/dev/null | grep -v -e ': done$' -e ': superseded$'
grep -n -e '^## Phase' -e '^### M' docs/ROADMAP.md
git status --short; git worktree list; git log --oneline -8
cat "$(git rev-parse --git-path claude-verify)/last-result" 2>/dev/null
```

## Procedure

1. **CLAUDE.md** is already loaded; never reread it.
2. **PROGRESS.md**: use the "Project state" block that `.claude/hooks/session-start.sh` injected; it contains PROGRESS.md. Read `docs/PROGRESS.md` only when the block is missing or truncated.
   - Block present and ASM-001 still `open` in `docs/ASSUMPTIONS.md`: set its Status to `confirmed — YYYY-MM-DD — "Project state" block injected at session start`, and commit that file alone (`docs: confirm ASM-001`); when it holds other uncommitted edits, include the change in their commit.
3. **Roadmap**: read only the milestone entry that PROGRESS.md § Current milestone names (locate it with the `grep -n` line, then read that range).
4. **Requirements**: the status list shows every open requirement. Read in full only the `in-progress` and `verification` files (the active work); for `blocked` ones read the newest Status lines (`tail -n 4 <file>`). The next candidate is the one `develop` § 2 selects: a `ready` requirement in the current milestone entry whose `## Dependencies` are all `done`, ordered by priority `must` > `should` > `could` (`grep -H '^priority:'` on those files), then roadmap order.
5. **Git**: uncommitted changes are unfinished work from an earlier session; map them to the active requirement with `git diff --stat` and never discard them. Extra worktrees mean interrupted parallel work: inspect each branch (`git log --oneline HEAD..<branch>`) before merging or removing it. A merge in progress (`git rev-parse -q --verify MERGE_HEAD` prints a hash) is a parallel-work integration awaiting its review: continue `develop` § Parallel work step 4 for it.
   - **Delegated work:** nothing an earlier session launched is running now. Delegated work that PROGRESS.md records without a verdict (`launched <date>; verdict not recorded; …`) was interrupted: read its brief and its handback in `docs/briefs/handbacks/` (when one exists), inspect its branch (`git log --oneline HEAD..<branch>`), then re-run the command PROGRESS.md records for the unfinished part. A review without a recorded verdict counts as not done.
6. **Verification**: check PROGRESS.md § Known failures and the last result (block or `last-result`). Run `./scripts/verify.sh` when the result is FAIL, missing, or stale for the current tree. Full log: `$(git rev-parse --git-path claude-verify)/last.log` (`.git/claude-verify/last.log` in the main checkout).
   - **Environment**: run `./scripts/probe-environment.sh --offline` (on a host that verifies inside the development container, `./scripts/dev-container.sh ./scripts/probe-environment.sh --offline`, plus `claude --version` on the host, since the container has no `claude`). When a measured value differs from `docs/ENVIRONMENT_CAPABILITIES.md` (Claude Code version, CPUs, memory, the two cgroup limit lines, accelerator verdict, tool versions, OS user, writability, credential variables set), update that row with the date and commit the file alone (`docs: re-measure the environment`). When the host, the container image or the network changed since the measurement the document names (another machine, a cloud container, a proxy), run the probe once more without `--offline` (about 70 s at most for its seven hosts) and compare the rows of § Network policy as well.
7. **Reconstruct**: state the summary below, at most 10 lines. When PROGRESS.md disagrees with the repository (frontmatter statuses, ROADMAP.md, Git), the repository wins: fix PROGRESS.md now.

   ```text
   Milestone: <M<n> — name (status)> | <Phase n — name>
   Objective: <current objective>
   Active: <AVE-REQ-NNN (status) — next step> | none
   Tree: <clean | N uncommitted paths — belong to …>; HEAD <hash> <subject>
   Verification: <PASS|FAIL YYYY-MM-DD> — <matches tree | stale>; known failures: <… | none>
   Blockers: <… | none>
   Next: <skill> — <task>
   ```

8. **Continue** immediately with the first rule that matches:
   1. The human's newest message asks for work the repository does not yet reflect: do it on top of this state (new product input → [product-definition](../product-definition/SKILL.md), amendment mode once PRODUCT.md is defined). A message restated in a compaction summary is not new, and input already recorded verbatim in a committed `docs/product-inputs/` file is processed: continue with rules 2–6.
   2. PROGRESS.md § In progress has a checkpoint line starting `product-definition —`, `technical-foundation —`, `milestone-review M<n> —` or `milestone-review final —`: that skill was interrupted; resume it at the next step.
   3. PRODUCT.md status `placeholder`: with a file in `docs/product-inputs/`, resume [product-definition](../product-definition/SKILL.md); without one, tell the human the repository is ready for the product prompt, and stop.
   4. ARCHITECTURE.md status `placeholder`, or `scripts/verify.sh` still contains `print_stack_notice`: run [technical-foundation](../technical-foundation/SKILL.md); it resumes an interrupted run.
   5. Every remaining item is blocked on the human: send one batched message listing each blocker with its recommended default, and stop.
   6. Otherwise: run [develop](../develop/SKILL.md), finishing the active requirement first.
