# Handback — Execute the media-core follow-ups and fix the background color matrix

Brief: [2026-10-02-m0-media-core-follow-ups-execution.md](../2026-10-02-m0-media-core-follow-ups-execution.md)
(item 13) with [2026-10-02-m0-media-core-round-3-follow-ups.md](../2026-10-02-m0-media-core-round-3-follow-ups.md)
(items 1–12). Worktree `.claude/worktrees/m0-media-follow-ups`, branch `m0-media-follow-ups`, from `6736401`.

## Result
COMPLETE. Items 1–8 and 10–13 are implemented, each with a test confirmed to fail without it; item 9 (optional)
is documented, as the follow-up brief allows; item 5's optional robust anchor stays out (ASM-008 states the
bound). The run resumed an interrupted attempt: its edits were judged hunk by hunk; its item 9 code change was
replaced by documentation (reason under item 9); everything else was kept, completed and re-verified by
mutation. No inherited hunk was a leftover mutation.

## Commits
- `9be8ef5` — `AVE-REQ-012, AVE-REQ-024: tighten the media-core oracles and keep audio gaps and jitter apart`
  (items 1–12).
- The commit that adds this file — `AVE-REQ-019, AVE-REQ-020: code the background with the BT.709 matrix the
  output is tagged with` (item 13); its hash is in the structured report.
- Trailer: both commits end with the `Co-Authored-By` line of the session's own attribution instruction, which
  names the model that wrote them; the launch prompt's trailer pair named another model and a session line, so
  it was left out (see Open questions).

## Items
Mutation runs delete every `__pycache__` first (WF-004); each mutation was reverted with the inverse edit and
`git diff` was checked against the checksum taken before the run.

1. Origin tie — `backend/tests/unit/test_compiler.py`: the `origin` case uses `source_in = Fraction(2)` on the
   origin 1/3 s (a tie on every output frame) and asserts frames 120, 121, 122 first.
   Test: `test_timestamp_map_reproduces_the_frame_rule[origin]`.
   Mutations: probe returns the printed start (`_exact_container_start` → `printed`) → FAIL; compiler rounds the
   origin to microseconds (`_timestamp_map`) → FAIL.
2. Diagnostic tail facts — `backend/tests/media/test_proc_media.py`: asserts `"corrupt input packet" in tail` and
   `tail.rstrip().endswith("Conversion failed!")`. Measured on FFmpeg 6.1 (the line sits 814 bytes before the
   end of the 4000-byte tail); the sources of 4.2 (`fftools/ffmpeg.c`: `process_input`, `ffmpeg_cleanup`) and
   7.0 (`fftools/ffmpeg_demux.c`, `fftools/ffmpeg.c`) hold both messages (source read; the runs used 6.1 only).
   Test: `test_failing_streamed_tool_reports_a_bounded_diagnostic_tail`.
   Mutations: `_STDERR_TAIL = 600` (the tail keeps "Error retrieving a packet …" and "Conversion failed!", which
   satisfied the old `"error"` assertion, and loses the corrupt-packet line 814 bytes from the end) → FAIL;
   the tail keeps the head of the diagnostics → FAIL.
3. Exact-start guard — `backend/tests/unit/test_probe_parse.py`: parametrized case, printed `1.433333` and a
   stream with `start_time` `1.433333` lacking `start_pts` or `time_base` → the printed value plus one
   approximate-origin warning. Test: `test_stream_start_known_only_as_printed_never_defines_the_origin[start_pts]`,
   `[time_base]`. Mutations: guard removed → both FAIL; only the `time_base` part removed → `[time_base]` FAIL.
4. Consistent planning fixture — `backend/tests/assets.py`: `fake_asset` takes `audio_start_pts` and derives the
   printed container start from the stream starts (`printed_start_time`: earliest start, half away from zero to
   µs, six decimals); `start_time` parameter removed (no caller used it). Test:
   `test_fake_asset_prints_the_container_start_the_way_ffmpeg_does` (`test_compiler.py`). Mutations: audio
   `start_pts` hard-coded to 0 → FAIL; printed start from the video stream alone → FAIL; truncation in place of
   rounding → FAIL.
5. Render placement of a jittered source — `backend/tests/media/test_source_timing.py`:
   `test_render_of_a_jittered_source_inserts_no_silence[7.5]`, `[16.5]`: the render's float PCM audio stage (kept
   work directory) holds no zero run of 8 samples, every chirp of the decoded export lies within the file's
   largest packet deviation (208 samples) plus two samples and below 10 ms (measured: 112 and 192 samples).
   Mutations: `AUDIO_TIMESTAMP_TOLERANCE_S = 1 ms` → both FAIL (zero runs); render placement biased by 5 ms →
   both FAIL (7.3 ms and 9.0 ms > 4.4 ms). Optional robust anchor: out (cost and risk; ASM-008 states the bound).
6. Gap thresholds — `backend/tests/media/derived.py` (`audio_gap_media`: PCM in Matroska, AAC in MPEG-TS),
   `test_source_timing.py`: `test_audio_gaps_of_10_ms_or_more_stay_gaps_and_smaller_ones_are_jitter`,
   `[5ms|12ms|21ms|50ms]-[mkv|ts]`. The expectation comes from the case (5 ms uncorrected, the rest corrected),
   never from the code's constant; the oracle reads the gap from the file's packet table in exact ticks.
   Measured: 5 ms → chirps after the gap exactly 240 samples early, no zero run; 12/21/50 ms → chirps exact,
   one zero run of 576/1008/2400 samples; MPEG-TS shows the gap at the next PES packet (8.107 s).
   Mutations: tolerance 5 ms → `5ms-mkv`, `5ms-ts` FAIL; 40 ms → `12ms`, `21ms` (both containers) FAIL;
   100 ms → every corrected case FAILS on missing chirps (no precondition assert remains).
7. Docstrings — `backend/src/ave/sync/audio.py` (`extract_analysis_audio`), `backend/src/ave/render/ffmpeg.py`
   (module doc), plus the same wording in `backend/src/ave/render/compiler.py` (module doc) and
   `test_compiler.py` (`test_inputs_are_opened_literally…` docstring): gaps of 10 ms or more stay gaps; smaller
   deviations are jitter. Test: none (documentation). Mutation: not applicable.
8. Constant docstring — `backend/src/ave/media/audio_timing.py`: deviations below 10 ms are jitter; exactly
   10 ms is corrected (float option); the module doc adds the anchor rule of item 5. Test: none
   (documentation). Mutation: not applicable.
9. Optional end of the analysis extraction — documented in `extract_analysis_audio`: a stream without its own
   duration (Matroska) ends at the container duration; when jitter puts the last timestamp earlier than the
   sample count implies, the difference (below 10 ms) is cut. The interrupted attempt read such streams to the
   last decoded sample; that can keep codec end padding which the container-duration end trims (lossy audio
   such as AAC in Matroska), a behavior change for every Matroska source and beyond a cheap, safe fix, so the
   code stays as it was. Test: none. Mutation: not applicable.
10. Intra-only docstrings — `backend/src/ave/media/probe.py` (module doc, `keyframe_pts`),
    `backend/src/ave/render/compiler.py` (seek rule): an intra-only stream stores no index and its seek point
    follows the indexed-container formula. Test: none (documentation). Mutation: not applicable.
11. Empty index without timestamps — `backend/src/ave/media/probe.py`: `if not packets or len(keys) <
    len(packets)`. Test: `test_stream_without_presentation_timestamps_gets_an_empty_keyframe_index`
    (`test_source_timing.py`, a generated raw H.264 stream: 120 packets, all without PTS, keyframes among them →
    `keyframe_pts == ()`, a cut at 2.5 s seeks to 0). Mutation: old condition → FAIL (`None == ()`). Proposed
    requirement below.
12. Intra-only cuts — `derived.py` (`intra_ts` now 21 s; new `intra_ts_offset` with `-output_ts_offset
    0.033333`, origin 129000/90000 s), `test_intra_only_mpegts_needs_no_keyframe_index`, cuts `0`, `59-60`,
    `19.99` × `start-1.4`, `start-43-30`; asserts the file's own start, the exact probe origin without warning,
    no index and floor(60 t) on all 30 frames. Mutations: probe returns the printed start → the three
    `start-43-30` cases FAIL; compiler rounds the origin → `0-start-43-30` and `59-60-start-43-30` FAIL (the
    19.99 cut is no tie).
13. Background matrix — `backend/src/ave/render/ffmpeg.py`: `background_ycbcr` computes 8-bit BT.709
    limited-range Y'CbCr by spec math (exact rationals, rounded half up); `build_segment_command` draws the
    background as `color=c=black,…,format=yuv420p,lutyuv=y=…:u=…:v=…`. Stored values measured: `#204060` →
    67/145/113 (was 66/147/112), `#C03020` → 83/106/192, `#30A040` → 127/97/83, `#E0C020` → 177/55/148, each
    equal to the spec values. Tests: `backend/tests/media/test_render_timing.py::
    test_background_decodes_to_its_color_under_the_tagged_bt709_matrix[#204060|#C03020|#30A040|#E0C020]`
    (output tagged bt709/tv; the gap segment and both contain bars decode, through the exact scaler path with the
    tagged matrix, to the spec round trip within 1 level — measured: equal on every channel), and
    `backend/tests/unit/test_compiler.py::test_background_is_filled_with_its_bt709_limited_range_values`
    (reference values black, white, red 63/102/240, `#204060`, and the filter text). Mutation: the old source
    restored → all four media cases FAIL (3, 13, 17 and 9 levels off), the unit test FAILS; the existing
    `test_gaps_and_bars_show_the_configured_background` passed under the mutation (its tolerance is 4 levels).

## Fixture-matrix finding (item 13)
`backend/src/ave/fixtures/generate.py` converts its RGB drawing with `scale=out_color_matrix=bt709:out_range=tv`
before `format=yuv420p` and tags BT.709 limited range. Measured on FFmpeg 6.1 (first frame, raw yuv420p at a
background pixel): A (200,50,50) → 86/113/194, B (50,90,200) → 93/180/106, C (50,170,70) → 134/96/79, `rate-60`
(90,90,90) → 93/128/128, `vfr` (150,60,150) → 90/158/164, `rotated` (60,60,160) → 74/172/124, `anamorphic`
(100,140,100) → 126/114/112: every value equals the BT.709 spec value (BT.601 would give, for example, A 97/106/194
and C 121/102/82). The fixtures encode with the matrix their streams declare; the PNG still is RGB. No change.

## Commands
- `./scripts/dev-container.sh uv run --frozen --directory backend pytest -q tests/unit/test_compiler.py tests/unit/test_probe_parse.py` — PASS (33).
- `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock uv run --frozen --directory backend pytest -q tests/media/test_source_timing.py -k "intra_only or empty_keyframe or gaps_of_10 or jittered or jitter_never"` — PASS (18).
- `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock uv run --frozen --directory backend pytest -q tests/media/test_render_timing.py -k background` — PASS (5).
- Mutation runs above — each FAIL as listed, each reverted.
- `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier media` on the items 1–12
  tree (commit `9be8ef5`) — PASS: 10 of 10 steps, unit tests 107 passed, media and population tests 77 passed
  in 328 s, evidence run `20261002T113952Z-128441`.
- `./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier media` on the final
  tree (items 1–13 and this file) — run before the item 13 commit; its result is in the structured report.

## Proposed requirement (item 11)
Next free ID at the time of writing: AVE-REQ-103 (the lead allocates).

```markdown
---
id: AVE-REQ-103
title: Clear probe error for video without presentation timestamps
type: functional
status: proposed
priority: should
parent: AVE-FEAT-001
source: derived
scope: v1
primary_gate: M1
origins: []
dependencies: [AVE-REQ-004, AVE-REQ-009, AVE-REQ-012]
scenarios: []
---

# AVE-REQ-103 — Clear probe error for video without presentation timestamps

## Intent
Serves GOAL-001 through AVE-FEAT-001: a source whose frames cannot be placed in time is reported when it is
added. Found by the round-3 review of the M0 media core (2026-10-02): a raw H.264 elementary stream (format
`h264`, no packet carries a presentation timestamp) is accepted by `describe_asset` and renders only background
at every cut while the render reports success.

## Description
Probing recognizes a video stream whose packets carry no presentation timestamp (raw H.264 or HEVC elementary
streams and similar formats). Describing such a file fails with a structured probe error that names the file
and the stream and suggests remuxing into a container with timestamps (MP4, Matroska, MPEG-TS); no asset
record is created. A render never publishes an export whose video clip decoded to no frame.

## Acceptance criteria
- [ ] AC-1 Probing a raw H.264 elementary stream raises a structured probe error naming the file, the stream index and the missing presentation timestamps; no asset is registered.
- [ ] AC-2 Video streams whose packets carry timestamps (MP4, Matroska, MPEG-TS, intra-only MPEG-TS, VFR) probe as before.
- [ ] AC-3 A render in which a placed video clip delivers no decoded frame fails with a structured error naming the clip; nothing is published.

## Edge cases
- Elementary stream with a frame-rate hint supplied by the user — out of scope: no user-supplied timing exists in v1.
- Audio elementary streams (ADTS AAC, raw PCM) — timestamps follow from the sample count; outside this requirement.

## Dependencies
- AVE-REQ-004 — probing; AVE-REQ-009 — broken-media reporting; AVE-REQ-012 — the frame rule needs timestamps.

## Verification strategy
- AC-1, AC-2 — integration (media) — a generated raw H.264 stream and the existing fixture matrix.
- AC-3 — integration (media) — a plan built from a probe record of such a stream.
- Acceptance scenarios: None.
```

Alternative: an edge case of AVE-REQ-004 ("video without presentation timestamps → clean probe error naming the
file, no partial record (AC-4)"), with AC-3 above as an edge case of AVE-REQ-072.

## Proposed lead updates
- `docs/ASSUMPTIONS.md` ASM-008 — add the measurements: gap cases 5 ms (uncorrected, chirps 240 samples early,
  no zero run) and 12/21/50 ms (corrected exactly, zero runs of 576/1008/2400 samples) in Matroska/PCM and
  MPEG-TS/AAC; render placement of the ±2 ms jitter fixture 112 and 192 samples from the analysis placement,
  within the file's largest deviation of 208 samples; Impact: a stream without its own duration can lose up to
  its end-packet jitter (below 10 ms) at the end of the analysis extraction (documented, item 9).
- `docs/ASSUMPTIONS.md` — new entry: Sequence background colors are BT.709 R'G'B' at full 8-bit scale
  (`#RRGGBB` / 255 = E'); the renderer codes them with the BT.709 limited-range matrix it tags, rounded half up
  (`ave.render.ffmpeg.background_ycbcr`) — reason: FFmpeg's `color` source codes BT.601 under a BT.709 tag —
  impact: decoded backgrounds equal the spec round trip; other output matrices (BT.2020, full range) need the
  same conversion when a profile adds them.
- `docs/requirements/AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md` § Implementation evidence —
  add the tests of items 5, 6, 11, 12 (`backend/tests/media/test_source_timing.py`) under AC-4.
- `docs/requirements/AVE-REQ-020-two-perspective-split-screen-layout.md` (AC-3) and
  `docs/requirements/AVE-REQ-019-aspect-preserving-composition-and-transforms.md` (AC-1) § Implementation
  evidence — `backend/src/ave/render/ffmpeg.py` (`background_ycbcr`, `build_segment_command`); tests
  `backend/tests/media/test_render_timing.py::test_background_decodes_to_its_color_under_the_tagged_bt709_matrix`,
  `backend/tests/unit/test_compiler.py::test_background_is_filled_with_its_bt709_limited_range_values`.
- `docs/TRACEABILITY.md` — AVE-REQ-019 and AVE-REQ-020 rows: Implementation `backend/src/ave/render/ffmpeg.py`,
  Tests `backend/tests/media/test_render_timing.py`, `backend/tests/unit/test_compiler.py` (when not listed).
- New requirement for item 11 (above).

## Open questions
- Item 9: should the analysis extraction read Matroska audio to its last decoded sample (no end cut, end padding
  of lossy codecs kept) or keep the container-duration end (documented cut below 10 ms)? Recommended default:
  keep the current end until a requirement needs the last 10 ms.
- Item 5 optional anchor (robust fit of packet timestamps for render placement): recommended default: none
  until a source with jitter near the 10 ms bound matters to a user.
- Commit trailers: the launch prompt asked for a `Co-Authored-By` line naming another model plus a
  `Claude-Session` line; the session's attribution instruction asks for one `Co-Authored-By` line naming the
  model that wrote the commits and no further attribution lines. The commits follow the session instruction.
  Recommended: the workflow script derives the trailer from the model it launches.
