# Brief — Fix the third media-core review findings

## Requirements
Same requirements as [round 2](2026-10-01-m0-media-core-review-fixes-round-2.md) (AVE-REQ-012 AC-4,
AVE-REQ-024 AC-3). Independent re-review of `90a1f2e`: verdict FAIL with one blocking finding; items 1, 2, 4–9 of
round 2 confirmed fixed on the reviewer's own real-media constructions (TS/PS with AAC, MP2 and AC-3, gaps of
20–80 ms, open GOPs, 2,700 adversarial sync pairs).

Blocking:
1. The unit "origin" oracle still reuses the rounded value (`tests/unit/test_compiler.py:201,246`,
   `tests/assets.py:37`): `fake_asset` gives the video `start_pts=0` with a printed format start of 0.333333, so
   `_exact_container_start` falls back to 333333/1000000 and the oracle reads the code's own output; no unit test
   covers `_exact_container_start`. Required: a consistent fake stream (start_pts 30000 at 1/90000), an independent
   `Fraction(1, 3)` in the oracle, parse tests for the rounding match, a tie between two streams and the fallback.

Also in scope (non-blocking findings):
2. The fallback to the printed start is silent (`media/probe.py:406`): record it as a probe warning.
3. The 1 ms hard-compensation threshold (`media/audio_timing.py:27`) turns timestamp jitter into dropouts: MKV PCM
   with ±2 ms per-packet jitter gives 329 inserted silence runs in 30 s. Required: a threshold above realistic
   jitter that still compensates real gaps (one lost AAC frame is 21 ms at 48 kHz), and a jitter test with no
   inserted silence.
4. The strong-lattice population cannot tell the rival gate apart by wrong offsets (`tests/unit/test_sync_populations.py`):
   add an unrelated same-tempo beat-train family that yields wrong offsets without the gate and none with it.
5. `tests/media/test_proc_media.py:81` matches FFmpeg-version-specific strings; assert version-independent facts.
6. `keyframe_pts` for an intra-only TS would hold one entry per frame: store no index when every packet is a
   keyframe (any landing packet is then a keyframe).

Recorded by the lead, outside this task: the rival gate's sensitivity cost on music-like scenes (assumption and an
M2 synchronization item) and gradual-decoder-refresh sources (a proposed requirement).

## Input revision
Branch `worktree-agent-ace5eb07e8aecbfbf` at `90a1f2e`, in its worktree; implemented by the lead. Add a commit;
never amend.

## Allowed paths
`backend/src/ave/**`, `backend/tests/**`.

## Forbidden paths
`docs/**`, `scripts/**`, `.github/**`, `.claude/**`, `CLAUDE.md`, `ai-video-editor-requirements/**`,
`backend/pyproject.toml`, `backend/uv.lock`.

## Dependencies and constraints
ADR-004/ADR-005; independent oracles; no loosened tolerance or skipped test; each change gets a test confirmed to
fail without it (mutation).

## Test commands
`./scripts/verify.sh --tier media` in the worktree must pass.

## Handback schema
Per item 1–6: change (file), test, mutation result; commands with results.
