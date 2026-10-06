# Current project state
_Last updated: 2026-10-06 — M0 open: red-team and critic findings of AVE-REQ-093/097 fixed; the AVE-REQ-094 accelerator verdict next; then five reviews._

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

Finish M0: re-verify AVE-REQ-093/094/096/097/098 on release-tier evidence (order 093 → 094 → 096/097/098), record
their Test evidence, move them to `done`, run the M0 milestone-review. Then M1 backend core ‖ M2 synchronization
from the drafts.

## In progress

- AVE-REQ-093 and AVE-REQ-097 `in-progress`: the red-team pass ([brief](briefs/2026-10-03-m0-gates-red-team.md),
  runs `wf_98f469f7-ec5` and `wf_44376763-43f`) is complete: 55 findings from six lenses, all fixed on this branch
  with the disposition of each in [handback part 1](briefs/handbacks/2026-10-03-m0-gates-red-team.part-1.md)
  (AVE-REQ-093) and [part 2](briefs/handbacks/2026-10-03-m0-gates-red-team.part-2.md) (AVE-REQ-097), and a
  mutation check of the new rules (160 mutants, each caught by a named case). The critics returned four
  findings for AVE-REQ-093 ([part 3](briefs/handbacks/2026-10-03-m0-gates-red-team.part-3.md)) and ten for
  AVE-REQ-097 ([part 4](briefs/handbacks/2026-10-03-m0-gates-red-team.part-4.md)), all fixed here. Next: one
  review each with a skeptic at the final commit.
- AVE-REQ-094 `in-progress` here and `verification` on branch `ave-req-094-probe-evidence` (pushed, `eb73896`):
  the review `wf_db16f332-fdf` returned FAIL for AC-1
  ([handback part 5](briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-5.md)): the accelerator verdict
  counts names in `/dev`. Next: count GPU devices only on the task branch, add the reviewer's cases, release
  tier there, review again.
- AVE-REQ-096 and AVE-REQ-098 `in-progress`: review PASS at `d4d3883`, challenges upheld; the red-team fixes
  changed files both rely on (the heavy-media lock, the Stop gate, check 12), so both are verified again at the
  final commit together with AVE-REQ-093 and AVE-REQ-097.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).

## Recently completed

- 2026-10-03 — Test tags converted: 112 backend tests carry `@pytest.mark.req(...)`; the AT-02 export test and the
  sync media tests carry `scenario` markers; AVE-REQ-103 and AVE-REQ-104 proposed from the reviews.
- 2026-10-03 — M0 process fixes integrated (`c084f7c`, parts `fb61875`…`529deda`): baseline pinned by its manifest
  hash, tooling evidence per suite result with validated tags, permissions and models measured, checker, hooks and
  probe hardened, persisted briefs and handbacks, one heavy media job enforced by a lock; release tier PASS.
- 2026-10-03 — Media-core follow-ups integrated (`31e22f7`, commits `9be8ef5`, `b6a3e98`, `b832b01`): oracle
  tightening, gap and jitter boundary tests, BT.709 background coding; two review lenses PASS (`wf_df2de811-039`).
- 2026-10-02 — Development container for Windows and macOS hosts (ADR-009): `verify.sh` re-executes inside it on
  Windows; the frame oracle decodes with the exact color conversion, so measurements agree on arm64 and x86_64.
- 2026-10-02 — Media-core review fixes rounds 1–3 merged (`548c8ca`, `90a1f2e`, `dc89da2`): exact container
  start, 10 ms audio jitter tolerance, keyframe-index seeking, sync chance and rival gates; round-3 review PASS.

## Next recommended work

1. Record the pending verdicts (§ In progress names each re-run command); on every upheld PASS tick the ACs,
   fill § Test evidence, set `done` in the order 093 → 094 → 096/097/098, update TRACEABILITY.md, commit, push;
   then `git push origin <commit>:main` after green CI.
2. `milestone-review` M0; record the result in ROADMAP.md.
3. Launch [M1 backend core](briefs/drafts/2026-10-02-m1-backend-core.md) ‖
   [M2 synchronization](briefs/drafts/2026-10-02-m2-synchronization.md) in isolated worktrees from the commit that
   closes M0 (each draft becomes a brief with that hash first).

## Blockers

Host disk: drive C: held 5.1 GB free of 237 GB on 2026-10-06 (measured by the AVE-REQ-094 review). The human
frees space there; until then reviewer clones and release-tier runs go one at a time. External gaps, each with
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

`./scripts/verify.sh --tier release` PASS at `eb73896` on the AVE-REQ-094 task branch (development container,
arm64; 12 of 12 steps); CI (x86_64) release tier green at `f894bbf` on this branch, the newest commit CI had
verified when this file was written, and red for the one commit `56e5864` ([WF-006](WORKFLOW_LOG.md)). GitHub
holds the state of later pushes. The fast tier (11 steps since the ignored-file step joined it) passes on every commit
of this branch (Stop gate).
