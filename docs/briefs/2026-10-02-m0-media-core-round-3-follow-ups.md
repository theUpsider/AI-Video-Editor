# Brief — Media-core follow-ups from the round-3 review

## Requirements
AVE-REQ-012 AC-4, AVE-REQ-024 AC-3 (media core: exact source timing, audio placement, sync evidence gates).
Independent review of `dc89da2` (workflow `wf_1a23bf0d-2a0`, [script](../workflows/review-media-core-round3-wf_1a23bf0d-2a0.js);
three lenses, each in its own scratch copy): PASS on every lens, 0 blocking findings, `dc89da2` merged into
`ccr-af7078da-q8r8mf`. The reviewers confirmed by mutation that each round-3 test fails without its fix, and
measured 41 real container variants (0 approximate-origin warnings, exact origins), 11 jittered audio files (0
inserted silence runs, chirps exact in analysis) and 6,720 shared-grid sync pairs. Non-blocking findings in scope:

Oracles and probe:
1. `backend/tests/unit/test_compiler.py:202`: the "origin" case uses `source_in = 1/7`, where no mapped time lands
   on a frame time, so it passes when the probe returns the printed (µs-rounded) start and when the compiler
   rounds the origin (mutations kept 18 of 18 passing; the media test caught the compiler rounding). Make it a tie
   (`source_in = Fraction(2)` or any multiple of 1/60) so either rounding fails it.
2. `backend/tests/media/test_proc_media.py:81`: `"error" in tail.lower()` accepts any error text. Assert facts
   present on FFmpeg 4.2, 6.1 and 7.0 that name this failure: `"corrupt input packet" in tail` and
   `tail.rstrip().endswith("Conversion failed!")`.
3. `backend/src/ave/media/probe.py:412`: no test covers the guard that limits matching to streams with an exact
   start (`start_pts` and `time_base` present); removing it kept 29 of 29 passing. Add a parse case: printed
   `1.433333` and a stream with `start_time` `1.433333` and no `start_pts` → the printed value plus one warning.
4. `backend/tests/assets.py:57`: `fake_asset` hard-codes the audio `start_pts` to 0; derive the printed container
   start from the stream starts (round half away from zero to µs, six decimals) or assert consistency.

Audio placement:
5. Render placement of a jittered source: an accurate-seek render clip sits up to the jitter of its seek packet
   from the analysis placement (measured up to +400 samples, 8.33 ms, for ±4 ms alternating MKV jitter; 0 to 10
   samples for MPEG-TS). Add a render jitter test asserting no zero runs and a chirp error at most the tolerance
   (ASM-008 now states the bound). Optional: anchor render placement on a robust fit of packet timestamps.
6. `backend/tests/media/test_source_timing.py:266-299`: filter thresholds of 5 ms and 40 ms pass both media tests
   (at 40 ms a 21 ms gap, one lost AAC frame, stays uncorrected); a 100 ms constant fails only the precondition
   assert. Parametrize the gap test over 5 ms (uncorrected, error equals the gap, no zero run), 12 ms, 21 ms and
   50 ms (corrected in full), with an MPEG-TS/AAC variant.
7. `backend/src/ave/sync/audio.py:283-284`, `backend/src/ave/render/ffmpeg.py:16-17`: docstrings say every
   timestamp gap stays a gap; qualify them (gaps of 10 ms or more; smaller deviations are jitter).
8. `backend/src/ave/media/audio_timing.py:27-28`: the constant's docstring calls 10 ms the largest deviation
   left uncorrected; FFmpeg corrects exactly 10 ms (float option). Reword to "below 10 ms" as ASM-008 does.
9. Optional: `extract_analysis_audio` (`backend/src/ave/sync/audio.py:296-310`) ends at the last packet's
   jittered timestamp, which can cut up to the tolerance of audio at the end; compute the end from the sample
   count or document the shortfall.

Seek index:
10. `backend/src/ave/media/probe.py:19-24,139-140`, `backend/src/ave/render/compiler.py:28-31`: docstrings predate
    the intra-only change; state that an intra-only stream stores no index and its seek point follows the
    indexed-container formula.
11. `backend/src/ave/media/probe.py:573`: `len(keys) < len(packets)` treats a stream with no PTS-bearing packets as
    intra-only; use `if not packets or len(keys) < len(packets)`. The reviewer also found that a raw H.264
    elementary stream (no presentation timestamps) is accepted by `describe_asset` and renders only background at
    every cut while the render reports success: report it to the lead as a proposed requirement (or an AVE-REQ-009
    edge case) for a clear probe error.
12. `backend/tests/media/test_source_timing.py:232-242`: the intra-only test checks one cut on a file with a
    µs-exact origin; parametrize the cut (0, 59/60, 1999/100) and add a variant with
    `-output_ts_offset 0.033333` (origin 43/30, exact only through `_exact_container_start`).

Recorded by the lead, outside this task: ASM-007 and the M2 synchronization brief carry the measured scope of the
shared-grid weakness (22 of 6,720 wrong) and the rename of the grid population test; ASM-008 carries the 10 ms
boundary and the seek-packet bound.

## Input revision
`ccr-af7078da-q8r8mf` at the commit that adds this brief (`git log -1 --format=%h -- docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md`)
or later; main working tree or an isolated worktree from that commit. Add commits; never amend.

## Allowed paths
`backend/src/ave/media/**`, `backend/src/ave/render/**`, `backend/src/ave/sync/audio.py`, `backend/tests/assets.py`,
`backend/tests/media/**`, `backend/tests/unit/test_compiler.py`, `backend/tests/unit/test_probe_parse.py`.

## Forbidden paths
`docs/**`, `scripts/**`, `.github/**`, `.claude/**`, `CLAUDE.md`, `ai-video-editor-requirements/**`,
`backend/pyproject.toml`, `backend/uv.lock`; files owned by a concurrently running M1 or M2 task (check its brief).

## Dependencies and constraints
ADR-004, ADR-005, ASM-007, ASM-008; independent oracles; no loosened tolerance or skipped test; each change gets a
test confirmed to fail without it (mutation, `__pycache__` cleared first, WF-004); one heavy media job at a time.

## Test commands
`./scripts/verify.sh --tier media` must pass.

## Handback schema
Per item 1–12: change (file), test, mutation result; commands with results; proposed requirement text for item 11.
