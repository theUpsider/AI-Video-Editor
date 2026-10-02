# Current project state
_Last updated: 2026-10-02 — M0: process gates committed; media-core fixes (round 2) under independent review._

<!-- Fast-recovery snapshot. Update after every requirement transition; keep under ~80 lines,
with the five newest entries in § Recently completed and § Important recent decisions; history
lives in Git and requirement Status logs. When this file and the repository disagree, the
repository wins: fix this file. scripts/check-project-control.sh checks the headings. -->

## Current milestone

M0 — Adopt the contract and prove the environment ([ROADMAP.md](ROADMAP.md)), in progress.
Branch `ccr-af7078da-q8r8mf`; baseline package committed at `6160278`.

## Current objective

Finish M0: merge the reviewed media-core fixes, convert test tags to `req`/`scenario` markers, verify
AVE-REQ-093/094/096/097/098 independently, run the M0 milestone-review. Then M1 backend core ‖ M2 synchronization.

## In progress

- Media-core review fixes on branch `worktree-agent-ace5eb07e8aecbfbf` (`548c8ca`, `90a1f2e`; worktree
  `.claude/worktrees/agent-ace5eb07e8aecbfbf`): round-3 independent review running. Briefs in
  [docs/briefs/](briefs/README.md). On PASS: `git merge --no-commit --no-ff` that branch, resolve
  `scripts/verify.d/20-backend.sh` and `backend/pyproject.toml` in favor of the main tree, verify, commit.
- AVE-REQ-093/094/096/097/098 `in-progress`: gates and tests committed; independent verification next.
- AVE-REQ-004/012/018/019/020/021/024/031/072/075 `in-progress` (partial ACs; the rest needs M1/M2 work).
- Drafted briefs for the next tasks (lead's scratchpad; persist into docs/briefs with the base commit at launch):
  M1 backend core (AVE-REQ-001/002/003/009/015/048 + 004 AC-1, 018 AC-3, 020 AC-3) ‖ M2 sync (023–028, 030).

## Recently completed

- 2026-10-02 — M0 delivery-process gates: per-run evidence manifests (`scripts/evidence.py`, pytest evidence
  plugin with validated `req`/`scenario`/`contract` markers, `--forbid-skips`), done-requirement evidence check
  (release tier), Stop gate pinned to the fast tier, tier and probe suites, task briefs with a heading check,
  `scripts/probe-environment.sh`, WORKFLOW_LOG WF-001–WF-003.
- 2026-10-01 — First real CPU split/full/split render (1920x1080 60/1, 22 s) with audio-estimated sync a_B = 2 s
  (`24499a6`); CI runs `verify.sh --tier release` with FFmpeg and uv.
- 2026-10-01 — Spec integration committed (`486b3a0`): 131 working requirement files, IMPORT_MAPPING.md,
  `check_baseline.py`, verify.sh tiers, PRODUCT/ROADMAP/ARCHITECTURE, ADR-002 to ADR-008.
- 2026-10-01 — Environment audit: [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md).
- 2026-10-01 — Baseline package committed unchanged (`6160278`).

## Next recommended work

1. On the round-3 review verdict: merge (PASS) or brief round 4 (FAIL) for the media-core fixes.
2. Convert docstring tags to markers (script ready in the lead's scratchpad), then verify-requirement for
   AVE-REQ-093/094/096/097/098 and `milestone-review` M0.
3. M1 backend core ‖ M2 synchronization in isolated worktrees from the committed HEAD; then M1 jobs/worker/API
   and the M1 frontend.

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

`./scripts/verify.sh --tier release` PASS on 2026-10-02 (12 of 12 steps; evidence manifest recorded in
`var/verify/`). Fix branch `90a1f2e`: media tier PASS in its worktree (92 unit, 59 media and population tests).
