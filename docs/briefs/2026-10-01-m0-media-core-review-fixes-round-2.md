# Brief — Fix the second media-core review findings

## Requirements
Same requirements as [round 1](2026-10-01-m0-media-core-review-fixes.md) (AVE-REQ-004, 012, 024, 031, 072; edge
cases "container start time other than zero", "VFR sources with irregular gaps", "unrelated or periodic audio →
never a fabricated offset"). Independent re-review of `548c8ca`: verdict FAIL. Findings 2, 3, 4, 5–8 and 10 of
round 1 were confirmed fixed on independent real-media constructions; the findings below remain. Each was reproduced
on real media by the reviewer.

Blocking:
1. **MPEG-TS/PS audio placement** (`render/ffmpeg.py:227`, `sync/audio.py:278`). For TS-type formats the FFmpeg CLI
   re-bases timestamps on the start of the streams it uses ("Correcting start time of Input #0 by 778667 us"), so
   `first_pts=0` aligns to the audio stream's own start again. Evidence: std-a remuxed to TS with audio
   `-itsoffset 0.8` (container start 1.433333, audio start 2.212): extraction puts chirps 778.7 ms early;
   `estimate_offset(A, ts)` returns OK a = −0.0213 (expected −0.8); render errors 0.22–2.18 s at source_in 0, 0.75,
   2.5, 6.5. Reviewer's suggested direction: `-copyts` on audio-render and analysis inputs and an explicit
   subtraction of the probed origin (+S0).
2. **Audio gaps under 100 ms** are not compensated (aresample `min_hard_comp` defaults to 0.1 s). Evidence: MKV PCM
   with a 50 ms gap at 8.0 s: every later chirp −50.0 ms off in extraction and render; `estimate_offset(A, gap)`
   returns OK a = +0.050 (expected 0). Reviewer verified `min_comp=0.001:min_hard_comp=0.001` gives 0.0 ms error.
3. **Rounded container start causes a one-frame error on TS sources** (`media/probe.py:380-383`,
   `render/compiler.py:454`; predates `548c8ca`). The video path uses `-copyts` and the compiler subtracts the
   6-decimal origin; a TS start of 129000/90000 prints as 1.433333, so every frame is 1/3 µs late and shows frame
   n−1 (60/60 mismatches at source_in 2.5). Required: the origin is exact (for example the minimum over streams of
   `start_pts × time_base` as a Fraction); the misleading comment is corrected; the unit "origin" oracle stops reusing
   the rounded value.
4. **Hang regression** (`sync/audio.py:224` via `proc.py:121`): `stream_tool` pipes stderr without draining it, so
   FFmpeg blocks once stderr exceeds 64 KB. Evidence: 20-minute ADTS AAC with 0.5 % corrupted bytes hangs (old code:
   clean `MediaToolError` in 1.3 s). Required: drain stderr concurrently (keep a bounded tail for the error message)
   and a test that would hang or time out without it (bounded by a short timeout).

Also in scope:
5. **Long-GOP MPEG-TS seek** (reviewer N3, predates both commits): `render/compiler.py:21-22` claims FFmpeg seeks to a
   keyframe ≤ S0, which is false for TS. A 20 s-GOP TS cut at 9.39 s shows the future keyframe on all 90 frames.
   Required: the frame rule holds on long-GOP TS input (for example by seeking to a keyframe known to precede S0 from
   a keyframe index, or by a margin derived from probed keyframe spacing), with a real-media test; keep MP4 behavior
   and decode cost unchanged.
6. **Periodic-lattice false positives** (reviewer N2, pre-existing, reduced by round 1): when both recordings carry
   block-amplitude noise on the same 2400-sample lattice, 4/200 unrelated pairs return OK and 5/200 positive pairs
   return OK with a wrong offset; the binomial null assumes independent onsets. Required: zero confident wrong
   offsets on a seeded lattice population of at least 200 positive and 200 unrelated pairs (reported as ambiguous or
   insufficient instead), while every existing positive case keeps its accuracy. If no bounded fix exists, stop and
   report the measured trade-off.
7. **Unknown-duration extraction** (reviewer N4, `sync/audio.py:225-230`) holds a bytearray plus a float32 copy;
   grow one float32 buffer instead.
8. **Coverage** (reviewer N5): real-media tests for late audio in AAC (MP4) and TS containers, source_in below and
   at or above 1 s, and an audio gap under 100 ms, in both render and analysis paths.
9. Move the 400-pair unrelated-audio property test (about 40 s) and any new population tests out of the fast tier:
   mark them `@pytest.mark.media` until the lead adds a dedicated `slow` marker (pyproject is lead-owned).

Not in scope: streaming onset extraction (follow-up for AVE-REQ-084 AC-4); sensitivity on few-event positives
(reviewer N1: 3–4 shared transients are often reported insufficient; no wrong offsets) — the lead records it.

## Input revision
Continue on branch `worktree-agent-ace5eb07e8aecbfbf` at `548c8ca` in the same worktree. Add a new commit; never
amend, push, merge or rebase.

## Allowed paths
`backend/src/ave/**`, `backend/tests/**` except the forbidden paths, `backend/README.md`.

## Forbidden paths
`backend/pyproject.toml`, `backend/uv.lock`, `backend/tests/conftest.py`, `backend/tests/evidence_plugin.py`,
`scripts/**`, `docs/**`, `.github/**`, `.claude/**`, `CLAUDE.md`.

## Dependencies and constraints
As in round 1: ADR-004/ADR-005, argv-only subprocesses, independent oracles, no loosened tolerances or skips, one
full `AVE-REQ-NNN AC-n` string per criterion in test docstrings, one heavy media job at a time.

## Test commands
`./scripts/verify.sh --tier media` must pass. Report the fast-tier unit-test runtime after item 9.

## Handback schema
As in round 1: result line; branch and commit; per item (1–9) root cause, change (file:line), the test that fails
without the fix and how that was confirmed, measured numbers; commands and results; deviations; proposed
assumptions; shared-document updates for the lead.
