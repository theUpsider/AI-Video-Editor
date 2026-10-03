# Current project state
_Last updated: 2026-10-03 — M0: AVE-REQ-093 re-verification FAIL fixed (the checker verifies the baseline hashes itself); reviews of 094/096/097/098 launched, verdicts not recorded._

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

- AVE-REQ-093 `verification`: the re-verification at `d4d3883` (`wf_ed1f5104-63a`) FAILED on one blocking finding
  (the file hashes were verified only by a package file); fixed on this branch (the checker verifies the inventory
  and every hash itself; suite cases for an edited validator) and queued for a re-review.
- AVE-REQ-094 `in-progress`: its re-review PASS at `d4d3883` was refuted by the skeptic (probe suite checks
  headings and formats, bandwidth-dependent network probe, browser tools unrecorded, no run with investigation
  and testing stages). Repair from [the probe-evidence brief](briefs/2026-10-03-ave-req-094-probe-evidence.md)
  in worktree `ave-req-094-probe-evidence`: researcher ‖ tester → implementer → review with a skeptic; the
  persisted script in [docs/workflows/](workflows/README.md) names the re-run command.
- AVE-REQ-096/097/098 `in-progress`: the fix brief (items 1–26) is implemented and integrated (`c084f7c`;
  handbacks under [docs/briefs/handbacks/](briefs/handbacks/)); their reviews in `wf_ed1f5104-63a` at `d4d3883`:
  launched 2026-10-03; verdict not recorded; on resume without a recorded verdict, re-run the script in
  [docs/workflows/](workflows/README.md) with `{commit: 'd4d3883'}`. The same run reviewed
  WORKFLOW_LOG.md: WF-004 and WF-005 supported; WF-001 to WF-003 corrected from its findings.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).
- Next delegated tasks, drafts persisted: [M1 backend core](briefs/drafts/2026-10-02-m1-backend-core.md) ‖
  [M2 synchronization](briefs/drafts/2026-10-02-m2-synchronization.md); each becomes a brief with the closing M0
  commit at launch.

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

1. `verify-requirement` for AVE-REQ-093 → 094 → 096/097/098 in private clones with a skeptic per PASS; on PASS tick
   the ACs, fill § Test evidence (tests from the release manifest, inspection lines from the part-4 handback), set
   `done`, update TRACEABILITY.md, commit, push; fast-forward `main` after green CI.
2. `milestone-review` M0; record the result in ROADMAP.md.
3. Launch M1 backend core ‖ M2 synchronization in isolated worktrees from the commit that closes M0 (finalize the
   drafts with that hash first).

## Blockers

None for local work. External gaps, each with its unblock action:
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

`./scripts/verify.sh --tier release` PASS at `cd21812` in the development container (arm64; 12 of 12 steps; 108
unit, 84 media and population tests; 6 tooling suites on every installed awk); CI (x86_64) release tier green
through `cd21812`. The fast tier passes on the AVE-REQ-093 fix (Stop gate).
