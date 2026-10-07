# Current project state
_Last updated: 2026-10-07 — M0 open: the fix round of the second review is merged on this branch; the third review round is next._

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

Finish M0: review AVE-REQ-093/094/096/097/098 a third time on this branch (brief first, status `verification`
first), move the five to `done` in the order 093 → 094 → 096/097/098, bring this branch into the working branch
and `main`, run the M0 milestone-review. Then M1 backend core ‖ M2 synchronization from the drafts.

## In progress

- Integration branch `m0-final-integration` (this file's branch): the working branch with both fix rounds merged
  in; the working branch receives it after the reviews.
- Second review round `wf_b18a5f3e-54e` at `f996c17`: three FAIL, two PASS refuted by the skeptic (handback parts
  1 to 5 of [its brief](briefs/2026-10-06-m0-final-review-2b.md)).
- Fix round `wf_6c06f19f-506` ([brief](briefs/2026-10-07-m0-review-2-fixes.md), handback parts 1 to 4): tracks A,
  C, B1 and B2 COMPLETE and merged here with their proposed document text. Requirement files and the roadmap
  follow written forms a Markdown renderer agrees with, every file outside the fingerprint fails unless a list
  admits its path, the tools read their configuration by name, hook registrations and frontmatter follow written
  forms, the probe judges device names as whole strings and creates nothing. Each track audited the statements of
  its requirement file ([WF-010](WORKFLOW_LOG.md)); new assumptions ASM-032 to ASM-041.
- AVE-REQ-093/094/096/097/098 `in-progress` until the brief of the third review round is committed.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).

## Recently completed

- 2026-10-06 — Red-team pass and critics on the AVE-REQ-093/097 gates: 69 findings fixed (`4413e4a`…`863c7c2`).
- 2026-10-03 — Test tags converted to markers; AVE-REQ-103 and AVE-REQ-104 proposed from the reviews.
- 2026-10-03 — M0 process fixes integrated (`c084f7c`): pinned baseline, suite results, briefs, heavy-media lock.
- 2026-10-03 — Media-core follow-ups integrated (`31e22f7`); two review lenses PASS (`wf_df2de811-039`).
- 2026-10-02 — Development container for Windows and macOS hosts (ADR-009).

## Next recommended work

1. Third review round: write its brief, set the five to `verification`, commit, push, wait for green CI, then
   launch reviewer and skeptic per requirement (two clones at most); on every upheld PASS tick the ACs, fill
   § Test evidence, set `done`, update TRACEABILITY.md, commit, push.
2. Merge this branch into the working branch, then `git push origin <commit>:main` after green CI.
3. `milestone-review` M0; then M1 backend core ‖ M2 synchronization from `docs/briefs/drafts/` (bring the drafts
   up to the gates of this tree first).

## Blockers

None for M0. Host disk: 16 GB free of 237 GB on 2026-10-07. External gaps with their unblock actions (provider
credentials, a GPU device visible to the container, speech and vision models):
[ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § External gaps. A long run needs the host awake
(§ Limits item 8 there).

## Known failures

None.

## Important recent decisions

- [ASM-041](ASSUMPTIONS.md) — gate hardening beyond the stated limits waits for a need.
- [ASM-036](ASSUMPTIONS.md) — outside the fingerprint only listed paths pass; the step walks the tree.
- [ASM-033](ASSUMPTIONS.md) — the roadmap is read by the letters a line opens with.
- [WF-011](WORKFLOW_LOG.md) — reviewer clones and the lead's own code work count toward the concurrency limits.
- [WF-010](WORKFLOW_LOG.md) — a fix track ends with a statement audit of its requirement file.

## Verification status

`./scripts/verify.sh --tier release` PASS on the integration tree before its first commit and in the reviewer
clones at `f996c17` (development container, arm64; 13 of 13 steps); CI (x86_64) release tier green at `fc068d8`
on `m0-final-integration`, after the one failure at `fc66eb3` ([WF-009](WORKFLOW_LOG.md)); GitHub holds the
state of later pushes. The fast tier (11 steps) passes on the working tree at every stop (Stop gate).
