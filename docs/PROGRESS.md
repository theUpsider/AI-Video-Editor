# Current project state
_Last updated: 2026-10-06 — M0 open: the fixes of the final review are integrated on branch `m0-final-integration`, where the second review round was launched._

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

Finish M0: close the findings of the final review round on AVE-REQ-093/094/096/097/098, review again (brief
first, status `verification` first), move the five to `done` in the order 093 → 094 → 096/097/098, run the M0
milestone-review. Then M1 backend core ‖ M2 synchronization from the drafts.

## In progress

- The state of M0 lives on branch `m0-final-integration` (pushed; `fc068d8` when this file was written): this
  branch with the three tracks of the fix round `wf_5cd13360-464`
  ([brief](briefs/2026-10-06-m0-final-review-fixes.md)) and the AVE-REQ-094 task branch merged in, the five M0
  requirements in `verification`, CI green at `b573d65`. Its `docs/PROGRESS.md` holds the details.
- Second review round, launched 2026-10-06 as workflow `wf_b18a5f3e-54e` at `f996c17` of that branch (reviewer
  and skeptic per requirement, from the brief `docs/briefs/2026-10-06-m0-final-review-2b.md` there); verdicts not
  recorded; on resume without a recorded verdict, check out that branch and re-run the Workflow tool with
  `docs/workflows/m0-final-review-2.js` and `{commit: 'f996c170a4e75ad25b06f36babf8699843012c92'}` plus the
  model arguments.
- This branch receives the integration branch after the reviews pass (`CLAUDE.md` § Delegation); until then it
  holds the state before the fix round (reports of the first round: handback parts 5 to 8 of the gates brief
  and part 6 of the probe brief).
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).

## Recently completed

- 2026-10-06 — Red-team pass and critics on the AVE-REQ-093/097 gates: 69 findings fixed (`4413e4a`…`863c7c2`).
- 2026-10-03 — Test tags converted to markers; AVE-REQ-103 and AVE-REQ-104 proposed from the reviews.
- 2026-10-03 — M0 process fixes integrated (`c084f7c`): pinned baseline, suite results, briefs, heavy-media lock.
- 2026-10-03 — Media-core follow-ups integrated (`31e22f7`); two review lenses PASS (`wf_df2de811-039`).
- 2026-10-02 — Development container for Windows and macOS hosts (ADR-009).

## Next recommended work

1. Record the verdicts of `wf_b18a5f3e-54e` on the integration branch (handback parts of its brief); on every
   upheld PASS tick the ACs, fill § Test evidence, set `done`, update TRACEABILITY.md, commit, push.
2. Merge the integration branch into this branch, then `git push origin <commit>:main` after green CI.
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

`./scripts/verify.sh --tier release` PASS at `d4147d8` on the AVE-REQ-094 task branch and in four reviewer
clones at `2df637f` (development container, arm64; 13 of 13 steps). CI (x86_64) release tier green at `2df637f`,
the newest commit CI had verified when this file was written; GitHub holds the state of later pushes. The fast
tier (11 steps) passes on the working tree at every stop (Stop gate); the committed tree of `56e5864` failed it
([WF-006](WORKFLOW_LOG.md)).
