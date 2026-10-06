# Current project state
_Last updated: 2026-10-06 — M0 open: the fixes of the final review are integrated on `m0-final-integration`; the five M0 requirements are in `verification`._

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

Finish M0: review AVE-REQ-093/094/096/097/098 on the integration branch (reviewer and skeptic per requirement),
move the five to `done` in the order 093 → 094 → 096/097/098, bring the branch into the working branch and
`main`, run the M0 milestone-review. Then M1 backend core ‖ M2 synchronization from the drafts.

## In progress

- Integration branch `m0-final-integration` (this file's branch): the working branch with the three tracks of
  the fix round `wf_5cd13360-464` ([brief](briefs/2026-10-06-m0-final-review-fixes.md), handback parts 1 to 3
  in `docs/briefs/handbacks/`) and the AVE-REQ-094 task branch merged in. The 13 blocking findings of the first
  round are closed: characters and headings of requirement files by allow-list and container-aware reading, an
  exact milestone Status line, steps that start from a named set of variables, a fingerprint made of the bytes
  the steps read, media stand-ins first on `PATH`, tags only in files a runner runs, the exact Stop command,
  GPU nodes counted as character devices that open; each non-blocking finding is fixed or stated as a limit.
- AVE-REQ-093/094/096/097/098 `verification`. Review run from
  [its brief](briefs/2026-10-06-m0-final-review-2b.md) at `f996c17`: launched 2026-10-06 as workflow
  `wf_b18a5f3e-54e` ([script](workflows/m0-final-review-2.js)); verdicts not recorded; on resume without a
  recorded verdict, re-run the Workflow tool with that script and
  `{commit: 'f996c170a4e75ad25b06f36babf8699843012c92'}` plus the model arguments. The working branch receives
  this branch after the reviews pass (`CLAUDE.md` § Delegation).
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).

## Recently completed

- 2026-10-06 — Red-team pass and critics on the AVE-REQ-093/097 gates: 69 findings fixed (`4413e4a`…`863c7c2`).
- 2026-10-03 — Test tags converted to markers; AVE-REQ-103 and AVE-REQ-104 proposed from the reviews.
- 2026-10-03 — M0 process fixes integrated (`c084f7c`): pinned baseline, suite results, briefs, heavy-media lock.
- 2026-10-03 — Media-core follow-ups integrated (`31e22f7`); two review lenses PASS (`wf_df2de811-039`).
- 2026-10-02 — Development container for Windows and macOS hosts (ADR-009).

## Next recommended work

1. Launch the review run from its brief; file each report as a handback part; on every upheld PASS tick the
   ACs, fill § Test evidence, set `done`, update TRACEABILITY.md, commit, push.
2. Merge this branch into the working branch, then `git push origin <commit>:main` after green CI.
3. `milestone-review` M0; record the result in ROADMAP.md.
4. Launch M1 backend core ‖ M2 synchronization from `docs/briefs/drafts/` in isolated worktrees from the commit
   that closes M0 (each draft becomes a brief with that hash first).

## Blockers

Host disk: drive C: held 5.2 GB free of 237 GB on 2026-10-06 (98 % used). A clone with its run data takes
about 60 MB and its backend environment 24 MB, so reviews proceed; the human frees space before M1 adds render
outputs (Docker's build cache holds about 9 GB that `docker builder prune` reclaims). External gaps, each with
its unblock action:
[ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § External gaps (provider credentials, a GPU device
visible to the container, downloaded speech and vision models).

## Known failures

None.

## Important recent decisions

- [ASM-020](ASSUMPTIONS.md) — a resumed parallel workflow continues through a continuation script with the completed stages as facts.
- [ASM-017](ASSUMPTIONS.md) — the heavy-media lock file lives on the shared state volume, so private clones serialize too.
- [ASM-011](ASSUMPTIONS.md) — the baseline is anchored by the pinned SHA-256 of its manifest.
- [ASM-008](ASSUMPTIONS.md) — revised: jitter stays uncorrected while its peak-to-peak spread is below 10 ms; AVE-REQ-104 proposed.
- [ADR-009](decisions/ADR-009-linux-development-container-for-other-hosts.md) — Windows and macOS hosts verify inside a Linux development container.

## Verification status

`./scripts/verify.sh --tier release` PASS on the integration tree before its first commit (development container,
arm64; 13 of 13 steps); CI (x86_64) release tier green at `b573d65` on `m0-final-integration`, after the one
failure at `fc66eb3` ([WF-009](WORKFLOW_LOG.md)); GitHub holds the state of later pushes. The fast tier (11
steps) passes on the working tree at every stop (Stop gate); the committed tree of `56e5864` failed it
([WF-006](WORKFLOW_LOG.md)).
