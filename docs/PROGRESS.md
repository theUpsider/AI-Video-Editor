# Current project state
_Last updated: 2026-10-07 — M0 open: the second review round returned no upheld PASS; the fix round for its findings is briefed._

<!-- Fast-recovery snapshot. Update after every requirement transition; keep under ~80 lines,
with the five newest entries in § Recently completed and § Important recent decisions; history
lives in Git and requirement Status logs. When this file and the repository disagree, the
repository wins: fix this file. scripts/check-project-control.sh checks the headings.
In-flight delegated work is recorded stop-safe: "launched <date>; verdict not recorded; on resume
without a recorded verdict, re-run <exact command>"; an unrecorded verdict means nothing is running. -->

## Current milestone

M0 — Adopt the contract and prove the environment ([ROADMAP.md](ROADMAP.md)), in progress.
Working branch `ccr-af7078da-q8r8mf`; integration branch `main` at `bd12fe8` (CI green); baseline package at `6160278`.
Host: Windows 11 ARM64; every check runs in the development container (`scripts/dev-container.sh`,
[ADR-009](decisions/ADR-009-linux-development-container-for-other-hosts.md)).

## Current objective

Finish M0: close the findings of the second review round on AVE-REQ-093/094/096/097/098
([fix brief](briefs/2026-10-07-m0-review-2-fixes.md)), review again (brief first, status `verification` first),
move the five to `done` in the order 093 → 094 → 096/097/098, bring this branch into the working branch and
`main`, run the M0 milestone-review. Then M1 backend core ‖ M2 synchronization from the drafts.

## In progress

- Integration branch `m0-final-integration` (this file's branch): the working branch with the fix round
  `wf_5cd13360-464` and the AVE-REQ-094 task branch merged in; the working branch receives it after the reviews.
- Second review round `wf_b18a5f3e-54e` at `f996c17`, verdicts recorded 2026-10-07 (handback parts 1 to 5 of
  [its brief](briefs/2026-10-06-m0-final-review-2b.md)): AVE-REQ-093, AVE-REQ-094 and AVE-REQ-097 FAIL with two
  blocking findings each; AVE-REQ-096 PASS refuted on AC-4 and AVE-REQ-098 PASS refuted on AC-2. All five are
  `in-progress` (Status logs hold each finding); the 13 blocking findings of the first round are closed.
- Fix round briefed in [the fix brief](briefs/2026-10-07-m0-review-2-fixes.md): tracks A (AVE-REQ-093),
  C (AVE-REQ-094), B1 (run environment, hooks) and B2 (checker, evidence tool), each with a statement audit
  ([WF-010](WORKFLOW_LOG.md)). Not launched when this file was written: create a worktree per track from the
  brief's commit (`git worktree add .claude/worktrees/m0-r2-fixes-<track> -b m0-r2-fixes-<track> <commit>`),
  then run the Workflow tool with `docs/workflows/m0-review-2-fixes.js` and the arguments its header names.
  The lead closes AVE-REQ-096 and the lead-owned documents beside it.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).

## Recently completed

- 2026-10-06 — Red-team pass and critics on the AVE-REQ-093/097 gates: 69 findings fixed (`4413e4a`…`863c7c2`).
- 2026-10-03 — Test tags converted to markers; AVE-REQ-103 and AVE-REQ-104 proposed from the reviews.
- 2026-10-03 — M0 process fixes integrated (`c084f7c`): pinned baseline, suite results, briefs, heavy-media lock.
- 2026-10-03 — Media-core follow-ups integrated (`31e22f7`); two review lenses PASS (`wf_df2de811-039`).
- 2026-10-02 — Development container for Windows and macOS hosts (ADR-009).

## Next recommended work

1. Launch the fix round as § In progress states; merge its four branches here with `--no-commit`, apply the
   proposed document text, pass `./scripts/verify.sh --tier release`, commit, push, wait for green CI.
2. Third review round from a new brief (status `verification` first; two reviewer clones at most); on every
   upheld PASS tick the ACs, fill § Test evidence, set `done`, update TRACEABILITY.md, commit, push.
3. Merge this branch into the working branch, then `git push origin <commit>:main` after green CI.
4. `milestone-review` M0; then M1 backend core ‖ M2 synchronization from `docs/briefs/drafts/`.

## Blockers

Host disk: drive C: held 5.5 GB free of 237 GB on 2026-10-07; reviews proceed two clones at a time
([ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § Limits item 5), and the human frees space before
M1 adds render outputs (`docker builder prune` reclaims about 9 GB). External gaps with their unblock actions
(provider credentials, a GPU device visible to the container, speech and vision models): § External gaps there.

## Known failures

None.

## Important recent decisions

- [WF-011](WORKFLOW_LOG.md) — reviewer clones and the lead's own code work count toward the concurrency limits.
- [WF-010](WORKFLOW_LOG.md) — a fix track ends with a statement audit of its requirement file.
- [ASM-030](ASSUMPTIONS.md) — check 12 fails every loop word in a hook command.
- [ASM-026](ASSUMPTIONS.md) — requirement files hold the characters of an allow-list.
- [ASM-025](ASSUMPTIONS.md) — the steps of verify.sh start from a named set of variables.

## Verification status

`./scripts/verify.sh --tier release` PASS on the integration tree before its first commit and in the reviewer
clones at `f996c17` (development container, arm64; 13 of 13 steps); CI (x86_64) release tier green at `fc068d8`
on `m0-final-integration`, after the one failure at `fc66eb3` ([WF-009](WORKFLOW_LOG.md)); GitHub holds the
state of later pushes. The fast tier (11 steps) passes on the working tree at every stop (Stop gate).
