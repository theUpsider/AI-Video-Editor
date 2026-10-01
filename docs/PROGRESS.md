# Current project state
_Last updated: 2026-10-01 — M0 in progress: baseline imported, environment audited, media core being built._

<!-- Fast-recovery snapshot. Update after every requirement transition; keep under ~80 lines,
with the five newest entries in § Recently completed and § Important recent decisions; history
lives in Git and requirement Status logs. When this file and the repository disagree, the
repository wins: fix this file. scripts/check-project-control.sh checks the headings. -->

## Current milestone

M0 — Adopt the contract and prove the environment ([ROADMAP.md](ROADMAP.md)), in progress.
Branch `ccr-af7078da-q8r8mf`; baseline package committed at `6160278`.

## Current objective

Finish M0: integrate the first real CPU split/full/split render with known-offset audio sync (AT-02, AT-04 core),
review it independently, wire verify.sh tiers and CI, commit. Then M1 (persistence, command service, assets,
jobs/worker, API) in parallel with M2 synchronization (drift, visual/manual anchors, coverage).

## In progress

- Media core (`backend/`, package `ave`): timebase, probe, composition model, layout, segmented renderer, decoded
  validation, audio offset estimation, synthetic fixtures — implementer running; contract in the lead's scratchpad,
  requirement focus AVE-REQ-004/012/018/019/020/021/024/031/072/075.
- verify.sh tiers (`--tier fast|media|release`, component steps in `scripts/verify.d/`) written; first run pending
  the media core.

## Recently completed

- 2026-10-01 — Requirements baseline imported: 131 working files with verbatim ACs, IMPORT_MAPPING.md,
  `scripts/check_baseline.py`, checker support for AVE IDs and `deferred`, tooling suites in `scripts/tests/`.
- 2026-10-01 — Environment audit: [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) (no GPU, no product
  credentials, Hugging Face blocked, PocketSphinx local ASR works, worktree isolation verified).
- 2026-10-01 — Product definition from the baseline: PRODUCT.md goals/journeys, ROADMAP M0–M7, ADR-002 to ADR-008.
- 2026-10-01 — Baseline package committed unchanged (`6160278`).
- 2026-10-01 — Repository bootstrapped (ADR-001).

## Next recommended work

1. Integrate and independently review the media core; commit M0 with verify.sh tiers and CI toolchain.
2. M1 backend (contract drafted: persistence, command service, uploads, jobs/worker, FastAPI, CLI) ‖ M2 sync.
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

Control files and baseline checks PASS on 2026-10-01; product tiers run after the media core lands.
