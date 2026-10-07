# Current project state
_Last updated: 2026-10-07 — M0 open: the third review round returned FAIL for all five; its fix round was launched, and the fourth round classifies by the skill alone._

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

Finish M0: close the nine findings of the third review round on AVE-REQ-093/094/096/097/098
([fix brief](briefs/2026-10-07-m0-review-3-fixes.md)), then verify the five a fourth time with findings classed
by `verify-requirement` § 10 as written ([WF-013](WORKFLOW_LOG.md)), move them to `done` in the order
093 → 094 → 096/097/098, bring this branch into the working branch and `main`, run the M0 milestone-review.

## In progress

- Integration branch `m0-final-integration` (this file's branch): the working branch with the two fix rounds
  merged in (`9fc1579`); the working branch receives it after the reviews.
- Third review round `wf_268ea4f6-bad` at `d7d5604`: FAIL for all five with nine blocking findings (handback
  parts 1 to 5 of [its brief](briefs/2026-10-07-m0-final-review-3.md)); 14 of 20 criterion rows passed, and
  every sampled row of the statement audits held. The five are `in-progress`.
- Decision after three rounds without a downward trend (13, 8 and 9 findings, [WF-013](WORKFLOW_LOG.md)): the
  fix round closes all nine findings, by grammar or allow-list where a pattern stood; the fourth review round
  classes findings by `verify-requirement` § 10 as written, and hardening beyond the criteria goes to the
  proposed AVE-REQ-105 (M7).
- Fix round from [the fix brief](briefs/2026-10-07-m0-review-3-fixes.md) at `88a2d92`: tracks A (AVE-REQ-093),
  C (AVE-REQ-094), B2a (evidence tool, session-start hook) and B2b (project checker) in worktrees on branches
  `m0-r3-fixes-a`, `-c`, `-b2a`, `-b2b`. Launched 2026-10-07 as workflow `wf_e30692cb-6de`; results not
  recorded; on resume without a recorded result, look for a commit on each branch and re-run the Workflow tool
  with `docs/workflows/m0-review-3-fixes.js` and `{base: '88a2d9289878f87802bdea20638b7dbd2055ba88', only: [the
  open tracks]}` plus the trailer and model arguments.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).

## Recently completed

- 2026-10-06 — Red-team pass and critics on the AVE-REQ-093/097 gates: 69 findings fixed (`4413e4a`…`863c7c2`).
- 2026-10-03 — Test tags converted to markers; AVE-REQ-103 and AVE-REQ-104 proposed from the reviews.
- 2026-10-03 — M0 process fixes integrated (`c084f7c`): pinned baseline, suite results, briefs, heavy-media lock.
- 2026-10-03 — Media-core follow-ups integrated (`31e22f7`); two review lenses PASS (`wf_df2de811-039`).
- 2026-10-02 — Development container for Windows and macOS hosts (ADR-009).

## Next recommended work

1. File the handbacks of the fix round; merge its four branches here with `--no-commit`, apply the
   proposed document text, pass `./scripts/verify.sh --tier release`, commit, push, wait for green CI.
2. Fourth review round from a new brief (status `verification` first; two reviewer clones at most; findings
   classed by `verify-requirement` § 10); on every upheld PASS tick the ACs, fill § Test evidence, set `done`.
3. Merge this branch into the working branch, then `git push origin <commit>:main` after green CI.
4. `milestone-review` M0; then M1 backend core ‖ M2 synchronization from `docs/briefs/drafts/`.

## Blockers

None for M0. Host disk: 16 GB free of 237 GB on 2026-10-07. External gaps with their unblock actions (provider
credentials, a GPU device visible to the container, speech and vision models):
[ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § External gaps. A long run needs the host awake
(§ Limits item 8 there).

## Known failures

None.

## Important recent decisions

- [WF-013](WORKFLOW_LOG.md) — a review brief classes findings by `verify-requirement` § 10 and adds no blocking class.
- [ASM-041](ASSUMPTIONS.md) — gate hardening beyond the criteria is collected in the proposed AVE-REQ-105.
- [ASM-036](ASSUMPTIONS.md) — outside the fingerprint only listed paths pass; the step walks the tree.
- [WF-011](WORKFLOW_LOG.md) — reviewer clones and the lead's own code work count toward the concurrency limits.
- [WF-010](WORKFLOW_LOG.md) — a fix track ends with a statement audit of its requirement file.

## Verification status

`./scripts/verify.sh --tier release` PASS on the tree of the merge `9fc1579` (development container, arm64; 13 of
13 steps; checker 1477, baseline 424, Stop hook 174, session start 77, tiers 133, probe 256 checks). CI (x86_64)
release tier green at `9fc1579`; GitHub holds the state of later pushes. The fast tier (11 steps) passes on the
working tree at every stop (Stop gate).
