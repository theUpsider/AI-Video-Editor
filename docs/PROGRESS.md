# Current project state
_Last updated: 2026-10-02 — M0: process requirements failed independent verification (fix brief ready); media-core round-3 review verdict pending._

<!-- Fast-recovery snapshot. Update after every requirement transition; keep under ~80 lines,
with the five newest entries in § Recently completed and § Important recent decisions; history
lives in Git and requirement Status logs. When this file and the repository disagree, the
repository wins: fix this file. scripts/check-project-control.sh checks the headings.
In-flight delegated work is recorded stop-safe: "launched <date>; verdict not recorded; on resume
without a recorded verdict, re-run <exact command>"; an unrecorded verdict means nothing is running. -->

## Current milestone

M0 — Adopt the contract and prove the environment ([ROADMAP.md](ROADMAP.md)), in progress.
Working branch `ccr-af7078da-q8r8mf`; integration branch `main` at `4d9ef9a` (CI green); baseline package at `6160278`.

## Current objective

Finish M0: land the media-core review fixes, fix the M0 process-requirement findings and re-verify
AVE-REQ-093/094/096/097/098, convert test tags to `req`/`scenario` markers, run the M0 milestone-review. Then
M1 backend core ‖ M2 synchronization from the persisted briefs.

## In progress

- Media-core review fixes (AVE-REQ-012 AC-4, AVE-REQ-024 AC-3): commits `548c8ca`, `90a1f2e`, `dc89da2` on branch
  `worktree-agent-ace5eb07e8aecbfbf` ([round-3 brief](briefs/2026-10-02-m0-media-core-review-fixes-round-3.md)).
  Focused review `wf_1a23bf0d-2a0` ([script](workflows/review-media-core-round3-wf_1a23bf0d-2a0.js)) launched
  2026-10-02 08:57; verdict not recorded. On resume without a recorded verdict: re-run that review against
  `dc89da2`; on PASS `git merge --no-commit --no-ff` the branch, keep this branch's `scripts/verify.d/20-backend.sh`
  and `backend/pyproject.toml` (marker `slow`), run `./scripts/verify.sh --tier media`, commit, push.
- AVE-REQ-093/094/096/097/098 `in-progress`: verify-requirement FAIL at `4d9ef9a` (`wf_b0c34bba-a20`); 9 blocking
  and 17 non-blocking findings with required fixes in
  [the fix brief](briefs/2026-10-02-m0-process-verification-fixes.md). Next: implement the brief, release tier,
  re-verify in dependency order 093 → 094 → 096/097/098.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).
- Next delegated tasks, briefs persisted: [M1 backend core](briefs/2026-10-02-m1-backend-core.md) ‖
  [M2 synchronization](briefs/2026-10-02-m2-synchronization.md); both start from the commit that closes M0.

## Recently completed

- 2026-10-02 — M0 delivery-process gates (`31e8b84`): evidence manifests and markers, `--forbid-skips`, check-done,
  fast-tier Stop gate, task briefs, `scripts/probe-environment.sh`; workflow records in [docs/workflows/](workflows/README.md).
- 2026-10-01 — First real CPU split/full/split render (1920x1080 60/1, 22 s) with audio-estimated sync a_B = 2 s
  (`24499a6`); CI runs `verify.sh --tier release` with FFmpeg and uv.
- 2026-10-01 — Spec integration committed (`486b3a0`): 131 working requirement files, IMPORT_MAPPING.md,
  `check_baseline.py`, verify.sh tiers, PRODUCT/ROADMAP/ARCHITECTURE, ADR-002 to ADR-008.
- 2026-10-01 — Environment audit: [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md).
- 2026-10-01 — Baseline package committed unchanged (`6160278`).

## Next recommended work

1. Record the media-core round-3 verdict (or re-run the review) and merge on PASS; on FAIL brief round 4.
2. Implement [the M0 process fix brief](briefs/2026-10-02-m0-process-verification-fixes.md); release tier;
   verify-requirement per requirement; record Test evidence; move each to `done` after its PASS.
3. Convert docstring tags in `backend/tests` to `@pytest.mark.req(...)` (tags come from each test's docstring
   prefix `AVE-REQ-NNN AC-n[, AC-m]: …` and its `# AVE-REQ-NNN AC-n` body comments) and add `scenario` markers
   (AT-02, AT-04); then `milestone-review` M0.
4. Launch M1 backend core ‖ M2 synchronization in isolated worktrees with the closing M0 commit as the base.

## Blockers

None for local work. External gaps: provider credentials, Hugging Face access, GPU device — see
[ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § Limits. An account usage limit (HTTP 429) stopped one
delegated agent on 2026-10-02 ([WF-002](WORKFLOW_LOG.md)); work resumed from its brief and worktree.

## Known failures

None.

## Important recent decisions

- [ADR-003](decisions/ADR-003-requirements-baseline-import.md) — AVE IDs as working IDs over an immutable baseline.
- [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) — exact rational time, one typed composition.
- [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) — segmented CPU renderer with decoded validation.
- [ADR-002](decisions/ADR-002-technology-stack.md) — Python/FastAPI, SQLite, FFmpeg, React/TypeScript.
- [ADR-008](decisions/ADR-008-local-speech-recognition.md) — PocketSphinx offline floor, faster-whisper when cached.

## Verification status

CI (`./scripts/verify.sh --tier release`, 12 of 12 steps) green at `4d9ef9a`; local fast tier PASS at `4d9ef9a`.
Fix branch `dc89da2`: media tier PASS in its worktree (round-3 handback).
