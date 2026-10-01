# Current project state
_Last updated: 2026-10-01 — M0: spec integrated, media core committed; evidence gates and M0 process reviews next._

<!-- Fast-recovery snapshot. Update after every requirement transition; keep under ~80 lines,
with the five newest entries in § Recently completed and § Important recent decisions; history
lives in Git and requirement Status logs. When this file and the repository disagree, the
repository wins: fix this file. scripts/check-project-control.sh checks the headings. -->

## Current milestone

M0 — Adopt the contract and prove the environment ([ROADMAP.md](ROADMAP.md)), in progress.
Branch `ccr-af7078da-q8r8mf`; baseline package committed at `6160278`.

## Current objective

Finish M0: verification evidence tied to tree fingerprints and requirement tags (AVE-REQ-097), persisted task
briefs (AVE-REQ-096), independent reviews of AVE-REQ-093/094/096/097/098, M0 milestone-review. Then M1 backend in
parallel with M2 synchronization.

## In progress

- Media core (`backend/`, package `ave`) committed; AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress`
  (partial ACs; remaining ACs need persistence, command service, UI, transitions and fades in M1/M2).
- Evidence gates (AVE-REQ-097): pytest `req`/`scenario` markers, evidence manifest, `scripts/evidence.py`.

## Recently completed

- 2026-10-01 — First real CPU split/full/split render (1920x1080 60/1, 22 s) with audio-estimated sync a_B = 2 s:
  17 decoded-output checks pass; 84 unit + 36 media tests; CI runs `verify.sh --tier release` with FFmpeg and uv.
- 2026-10-01 — Spec integration committed (`486b3a0`): 131 working requirement files, IMPORT_MAPPING.md,
  `check_baseline.py`, verify.sh tiers, PRODUCT/ROADMAP/ARCHITECTURE, ADR-002 to ADR-008.
- 2026-10-01 — Environment audit: [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) (no GPU, no product
  credentials, Hugging Face blocked, PocketSphinx local ASR works, worktree isolation verified).
- 2026-10-01 — Baseline package committed unchanged (`6160278`).
- 2026-10-01 — Repository bootstrapped (ADR-001).

## Next recommended work

1. AVE-REQ-097 evidence gates, then verify-requirement for AVE-REQ-093/094/096/097/098; `milestone-review` M0.
2. M1 backend (persistence, command service, uploads, jobs/worker, FastAPI, CLI) ‖ M2 sync (drift, visual and
   manual anchors, coverage) in isolated worktrees from the committed HEAD.
3. M1 frontend (React/TS: collection, timeline, preview, export) ‖ M2 timeline operations.

## Blockers

None for local work. External gaps (no blocker for independent work): provider credentials, Hugging Face access,
GPU device — see [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) § Limits.

## Known failures

None.

## Important recent decisions

- [ADR-003](decisions/ADR-003-requirements-baseline-import.md) — AVE IDs as working IDs over an immutable baseline.
- [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) — exact rational time, one typed composition.
- [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) — segmented CPU renderer with decoded validation.
- [ADR-002](decisions/ADR-002-technology-stack.md) — Python/FastAPI, SQLite, FFmpeg, React/TypeScript.
- [ADR-008](decisions/ADR-008-local-speech-recognition.md) — PocketSphinx offline floor, faster-whisper when cached.

## Verification status

`./scripts/verify.sh --tier release` PASS on 2026-10-01 (9 of 9 steps: control files, baseline, ruff, mypy strict,
84 unit tests, 36 media tests, tooling suites on every installed awk).
