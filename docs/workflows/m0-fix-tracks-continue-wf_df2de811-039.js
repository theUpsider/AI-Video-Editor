// Record of workflow run wf_df2de811-039 (2026-10-03), launched with args {base: '6736401'}: the
// hand-authored continuation of wf_164de68e-23b after a session restart (its resume cache missed
// because the parallel tracks interleave differently per run). The session trailer line and the
// tier aliases are redacted: repository files carry no model identifier.
export const meta = {
  name: 'm0-fix-tracks-continue',
  description: 'Continuation of wf_164de68e-23b: process-fix part 4 and final check; media fix round and re-review',
  phases: [
    { title: 'Process fixes', detail: 'part 4, then the release-tier final check' },
    { title: 'Media follow-ups', detail: 'fix rounds on blocking review findings' },
    { title: 'Media review', detail: 'two independent lenses with mutation checks per round' },
  ],
}

// Hand-authored continuation of run wf_164de68e-23b after a session restart. Completed stages of that
// run are embedded as facts: parts 1-3 (fb61875, 3f7c44d, a62e197 on m0-process-fixes), the media
// implementer (9be8ef5, b6a3e98 on m0-media-follow-ups) and review round 1 (oracle lens PASS,
// real-media lens FAIL with one blocking finding, below).
const ROOT = 'C:/dev/AI-Video-Editor'
const BASE = args.base
const TRAILERS = 'Claude-Session: local-b60e388f-5909-48c0-aff3-61aac11b0998'
const IMPL = { model: '<tier alias>', effort: 'xhigh' }
const VERIFY = { model: '<tier alias>', effort: 'high' }
const R1 = {
  "reviews": [
    {
      "lens": "oracles",
      "review": {
        "verdict": "PASS",
        "blocking": [],
        "summary": "VERDICT: PASS\nRequirement: AVE-REQ-012, AVE-REQ-024 \u2014 media-core follow-ups, items 1 to 4, 6, 10, 11 and 12 (commits 6736401..m0-media-follow-ups, HEAD b6a3e98; oracle strength and mutation lens, round 1)\n\n## Acceptance criteria\n| Item | Verdict | Evidence |\n|---|---|---|\n| 1 Origin tie | PASS | `backend/tests/unit/test_compiler.py`: the `origin` case uses `source_in = Fraction(2)` on origin 1/3 and asserts frames 120, 121, 122. Both roundings fail it (U1, U2). |\n| 2 Error-text assertion | PASS | `backend/tests/media/test_proc_media.py`: asserts `\"corrupt input packet\" in tail` and `tail.rstrip().endswith(\"Conversion failed!\")`. A 600-byte tail fails it (M11). Measured on FFmpeg 6.1 only. |\n| 3 Exact-start guard | PASS | `backend/tests/unit/test_probe_parse.py::test_stream_start_known_only_as_printed_never_defines_the_origin[start_pts|time_base]`. Removing the guard fails both; removing only the `start_pts` part fails `[start_pts]` (U3, U6). |\n| 4 `fake_asset` consistency | PASS | `backend/tests/assets.py`: `printed_start_time` derives the printed start from the stream starts; `audio_start_pts` is a parameter. The removed `start_time` parameter has no remaining caller. Hard-coded 0 and truncation both fail the new test (U4, U5). |\n| 6 Gap thresholds | PASS | `test_audio_gaps_of_10_ms_or_more_stay_gaps_and_smaller_ones_are_jitter[5ms|12ms|21ms|50ms]-[mkv|ts]`: expectations come from the case and the file's packet table, not from the code's constant. Tolerances of 5, 40 and 100 ms each fail the expected cases (M1 to M3). |\n| 10 Intra-only docstrings | PASS | By inspection: `probe.py` module doc and `keyframe_pts` docstring, and the `compiler.py` seek rule, state that an intra-only stream stores no index and follows the indexed-container formula. |\n| 11 Empty index without PTS | PASS | `probe.py`: `if not packets or len(keys) < len(packets)`. The old condition fails `test_stream_without_presentation_timestamps_gets_an_empty_keyframe_index` (M4). The proposed requirement text is in the handback. |\n| 12 Intra-only cuts | PASS | Cuts 0, 59/60 and 1999/100 across `intra_ts` and `intra_ts_offset` (`-output_ts_offset 0.033333`, origin 43/30). Probe-printed origin, compiler rounding and shifted cut times each fail the expected cases (M5, M7 to M10). |\n\n## Verification runs\n- `pytest -q tests/unit` in the container: 113 passed.\n- `pytest -q tests/unit/test_compiler.py tests/unit/test_probe_parse.py`: 33 passed.\n- Under the lock, `pytest -q tests/media/test_source_timing.py tests/media/test_proc_media.py tests/media/test_render_timing.py -rs`: 47 passed, none skipped.\n- Under the lock, `./scripts/verify.sh --tier media` on b6a3e98: PASS, 10 of 10 steps (unit 108 passed, media and population 81 passed in 355 s, working tree unchanged, evidence run `20261002T121726Z-316110`).\n- `git diff --stat 6736401..m0-media-follow-ups`: 13 files, all under the allowed paths; the only `docs/` file is the handback, which the brief permits.\n- The scratch worktree was clean after every mutation and has been removed. Nothing was committed or pushed.\n\n## Findings\n### Blocking\nNone.\n\n### Non-blocking\n- A tolerance of 11 ms passes all gap and jitter tests (M3b): the cases 5 ms and 12 ms bracket the threshold but do not pin the 10 ms boundary.\n- The intra-only cuts cannot see a late shift of half a frame or less: the tie cuts catch early shifts and the 19.99 cut catches a late shift of 0.6 frame.\n- Item 2's claim for FFmpeg 4.2 and 7.0 rests on source reading; only 6.1 was run.\n- The handback left the final-tree verify result to a structured report I did not have; my own run on b6a3e98 passed.\n\n## Test quality\n- Oracles are independent: the unit `origin` case computes its expectation from the case's exact origin; the gap test reads the gap from the FFprobe packet table in exact ticks; the intra-only test checks the file's own stream start and floor(60 t).\n- No tolerance was loosened: the Matroska chirp tolerance is unchanged at 1 ms and the new MPEG-TS tolerance is 2 samples. The removed precondition assert is replaced by case-driven expectations, and 100 ms now fails six cases on behaviour.\n- No test is skipped or marked expected-to-fail.\n\n## Evidence for the requirement file\n- 2026-10-02 reviewer PASS (oracle and mutation lens, round 1) on b6a3e98; `./scripts/verify.sh --tier media` PASS 2026-10-02 (run `20261002T121726Z-316110`).\n- AVE-REQ-012 AC-4 \u2192 `backend/tests/unit/test_compiler.py::test_timestamp_map_reproduces_the_frame_rule[origin]`, `::test_fake_asset_prints_the_container_start_the_way_ffmpeg_does`, `backend/tests/unit/test_probe_parse.py::test_stream_start_known_only_as_printed_never_defines_the_origin`, `backend/tests/media/test_source_timing.py` (gap, intra-only and empty-index tests) \u2014 pass.\n- AVE-REQ-009 AC-4 \u2192 `backend/tests/media/test_proc_media.py::test_failing_streamed_tool_reports_a_bounded_diagnostic_tail` \u2014 pass.\n- Non-blocking: no 10 ms boundary gap case; FFmpeg 4.2 and 7.0 diagnostic text not run.",
        "mutations": [
          "U1 probe.py `_exact_container_start` returns the printed start: KILLED - test_timestamp_map_reproduces_the_frame_rule[origin], the fake_asset test and 2 probe parse tests fail (4 failed, 29 passed)",
          "U2 compiler.py `_timestamp_map` rounds the origin to microseconds: KILLED - test_timestamp_map_reproduces_the_frame_rule[origin] fails (1 failed, 32 passed)",
          "U3 probe.py exact-start guard removed (start_pts and time_base): KILLED - both test_stream_start_known_only_as_printed_never_defines_the_origin cases fail",
          "U6 probe.py guard, start_pts part only removed: KILLED - the [start_pts] case fails",
          "U4 tests/assets.py audio start_pts hard-coded to 0: KILLED - test_fake_asset_prints_the_container_start_the_way_ffmpeg_does fails",
          "U5 tests/assets.py printed_start_time truncates instead of rounding: KILLED - the same fake_asset test fails",
          "M1 AUDIO_TIMESTAMP_TOLERANCE_S = 5 ms: KILLED - 5ms-mkv and 5ms-ts fail (2 failed, 9 passed)",
          "M2 AUDIO_TIMESTAMP_TOLERANCE_S = 40 ms: KILLED - 12ms and 21ms fail in both containers (4 failed)",
          "M3 AUDIO_TIMESTAMP_TOLERANCE_S = 100 ms: KILLED - 12ms, 21ms and 50ms fail in both containers (6 failed)",
          "M3b AUDIO_TIMESTAMP_TOLERANCE_S = 11 ms (probe between the required cases): SURVIVED - 11 passed; non-blocking, the brief requires only the 5/12/21/50 ms cases",
          "M4 probe.py old intra-only condition `len(keys) < len(packets)`: KILLED - test_stream_without_presentation_timestamps_gets_an_empty_keyframe_index fails",
          "M5 probe.py index always stored (`if True`): KILLED - all 6 intra-only cases fail",
          "M6 probe.py index never stored (`if False`): KILLED - the long-GOP MPEG-TS test and the empty-index test fail",
          "M7 probe returns the printed start, media tests: KILLED - the 3 start-43-30 intra-only cases fail",
          "M8 compiler rounds the origin, media tests: KILLED - 0-start-43-30 and 59-60-start-43-30 fail (the 19.99 cut is no tie, as the handback states)",
          "M9 compiler cut one 90 kHz tick early: KILLED - cuts 0 and 59/60 fail on both variants (4 failed)",
          "M10 compiler cut 10 ms (0.6 frame) late: KILLED - the 19.99 cut fails on both variants (2 failed)",
          "M11 proc.py _STDERR_TAIL = 600: KILLED - test_failing_streamed_tool_reports_a_bounded_diagnostic_tail fails on the missing 'corrupt input packet'"
        ],
        "nonBlocking": [
          "backend/tests/media/test_source_timing.py (gap test): a tolerance of 11 ms passes all 11 gap and jitter tests, so the 10 ms boundary is not pinned. Follow-up: add gap cases near the boundary (for example 9 ms uncorrected, 10 ms corrected) if ASM-008's exact boundary is to be guarded.",
          "backend/tests/media/test_source_timing.py (intra-only test): the cuts cannot detect a late shift of half a frame or less; cuts 0 and 59/60 catch early shifts and 19.99 catches a late shift of 0.6 frame. Follow-up: a cut just below a frame time (for example 1 - 1/90000) would catch small late shifts.",
          "backend/tests/media/test_proc_media.py: the asserted FFmpeg messages were run on 6.1 only; the claim for 4.2 and 7.0 rests on source reading. Re-check when the container's FFmpeg version changes.",
          "docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md: the final-tree verify result is deferred to a structured report rather than stated. Verified independently: verify.sh --tier media PASS on b6a3e98, 10 of 10 steps, run 20261002T121726Z-316110.",
          "Items 5, 7, 8, 9 and 13 were outside this lens: their tests ran green in the targeted and full media runs but were not mutation-checked here."
        ]
      }
    },
    {
      "lens": "real-media",
      "review": {
        "verdict": "FAIL",
        "blocking": [
          {
            "location": "backend/src/ave/media/audio_timing.py (module docstring paragraph \"The first decoded packet anchors the placement ...\" and the AUDIO_TIMESTAMP_TOLERANCE_S docstring, both written on this branch); same wording in backend/tests/media/test_source_timing.py (JITTER_PLACEMENT_BOUND and the docstring of test_render_of_a_jittered_source_inserts_no_silence)",
            "defect": "Item 5: the documented jitter bound is contradicted by real media. The branch states that timestamp deviations below 10 ms are jitter and stay uncorrected, and that a rendered clip of a jittered source sits \"the difference between the two anchors' jitter (below the tolerance)\" from the analysis placement. In fact the 10 ms threshold is measured against the first decoded packet (the seek packet in a render), so the rule only holds while the peak-to-peak jitter is below 10 ms (amplitude below about 5 ms). Between 5 and 10 ms amplitude, the same source is contiguous in one path and gets silence inserted every other packet in the other. The new test only covers +-2 ms jitter, so nothing exercises this boundary.",
            "evidence": "Own constructions from fixture A, all measured in the Linux container (FFmpeg 6.1.1). (1) MPEG-TS/AAC, one frame per PES, packet timestamps alternating +-5.21 ms with the first packet exact (every packet 5.21 ms from its contiguous position, peak-to-peak 10.42 ms): extract_analysis_audio gives 0 zero runs and all 7 chirps exact; a 6 s render at source_in 2.0, 4.7, 12.03 and 20.01 each has 141 zero runs of 500 samples in the float PCM audio stage (140 at one seek point), and at 2.0 only 1 of 2 chirps is detectable. (2) Same construction at +-4.9 ms (peak-to-peak 9.8 ms): 0 zero runs, chirp error 235 samples at every seek point; +-4.5 ms: 0 zero runs, 216 samples. (3) Matroska/PCM alternating +-4.7 ms (peak-to-peak exactly 10.0 ms after millisecond rounding): the analysis extraction has 234 zero runs of 480 samples and 4 of 7 chirps 480 samples late, while the four renders have 0 zero runs. (4) Matroska/PCM +-5.5 ms and MPEG-TS +-5.6 ms with the first packet jittered: 701/702 zero runs in analysis, 140-141 in every render, one chirp lost. Below the boundary the claim holds: Matroska +-3 ms and +-4 ms alternating, random +-3.5 ms and +-4.5 ms, MPEG-TS +-2.5 ms and +-2.8 ms all give 0 zero runs and render errors no larger than the file's largest packet deviation (worst 400 samples, 8.33 ms, for +-4 ms Matroska).",
            "fix": "Either implement the optional robust anchor of item 5 (placement from a fit of packet timestamps, so analysis and render share one reference), or state the real bound and test it: correct both docstrings in audio_timing.py and the test docstring to say deviations are measured from the first decoded packet, so jitter is tolerated only while its peak-to-peak spread is below 10 ms; add a render and analysis jitter case just below the boundary (for example alternating +-4.5 ms: no zero runs, error at most the peak-to-peak spread). Report the corrected bound to the lead for ASM-008, whose Impact line should name the dropouts for sources with jitter amplitude of 5 ms or more."
          }
        ],
        "mutations": [
          "M1 (item 13) restore the old background source (color=c=0xRRGGBB, lutyuv removed) in backend/src/ave/render/ffmpeg.py: test_background_decodes_to_its_color_under_the_tagged_bt709_matrix fails for all four colors and test_background_is_filled_with_its_bt709_limited_range_values fails; the older test_gaps_and_bars_show_the_configured_background still passes (5 failed, 1 passed). Killed.",
          "M2a (items 5, 6) AUDIO_TIMESTAMP_TOLERANCE_S = 1 ms: 5ms-mkv, 5ms-ts, test_timestamp_jitter_never_inserts_silence and both test_render_of_a_jittered_source_inserts_no_silence cases fail (5 failed, 6 passed). Killed.",
          "M2b (item 6) tolerance 5 ms: 5ms-mkv and 5ms-ts fail (2 failed, 9 passed). Killed.",
          "M2c (item 6) tolerance 40 ms: 12ms-mkv, 12ms-ts, 21ms-mkv, 21ms-ts fail (4 failed, 7 passed). Killed.",
          "M2d (item 6) tolerance 8 ms: all 10 gap and jitter media tests pass; only the unit test test_inputs_are_opened_literally_and_video_keeps_frames_before_the_seek fails, on the filter text (1 failed, 11 passed). Killed by the unit test only; the media tests bracket the boundary between 5 and 12 ms, as the brief specified.",
          "M3 (item 12) _exact_container_start returns the printed start: the three start-43-30 intra-only cases, test_mpegts_video_follows_the_exact_container_start, test_timestamp_map_reproduces_the_frame_rule[origin] and test_fake_asset_prints_the_container_start_the_way_ffmpeg_does fail (6 failed, 5 passed). Killed.",
          "M4 (item 12) compiler rounds the origin to microseconds in _timestamp_map: 0-start-43-30, 59-60-start-43-30, test_mpegts_video_follows_the_exact_container_start and the unit origin case fail (4 failed, 4 passed); 19.99-start-43-30 passes, as the handback states (no tie). Killed.",
          "M5 (item 11) old condition `if len(keys) < len(packets)`: test_stream_without_presentation_timestamps_gets_an_empty_keyframe_index fails (1 failed, 6 passed). Killed.",
          "M6 (item 5) render placement biased by +3 ms in build_audio_command: both jittered render cases pass (2 passed). Survives by design: the test bound is the file's largest packet deviation (4.33 ms); exact placement of unjittered sources is covered by other tests. Non-blocking.",
          "Every mutation ran in the scratch worktree with all __pycache__ directories deleted first and was reverted with git checkout; git status was clean before the final media-tier run."
        ],
        "nonBlocking": [
          "Item 13 verified on real media with 10 colors of my own (#FF0000, #00FF00, #0000FF, #2A2A2A, #FF00FF, #FFFF00, #00FFFF, #7B1FD3, #010203, #FFFFFF) on a 480x800 canvas at 25 fps, as a pure-background segment and as bars above and below C. Stored Y/Cb/Cr equals my own BT.709 limited-range values exactly in all 30 regions (red 63/102/240, green 173/42/26, blue 32/240/118, dark gray 52/128/128); decoded with the exact scaler path and with zscale, every channel mean is within 0.47 level of the spec round trip; output tagged bt709/tv.",
          "Item 6 verified with my own gaps at 11 s (Matroska PCM via asetpts; MPEG-TS AAC stream copy with a packet-level setts shift, one frame per PES). MPEG-TS: 3, 7, 9 and 9.9 ms stay contiguous (no zero run, chirps exactly the gap early); 10.0, 10.09, 11, 15 and 33 ms are filled with one zero run of 480/484/528/720/1584 samples and chirps are exact, in analysis and render alike. Matroska: 3, 7 and 9 ms uncorrected; 11, 15 and 33 ms corrected within 16 samples; nominal 9.9 to 10.1 ms all land on a 10 ms timestamp step and are corrected (480-sample run).",
          "Item 6 coverage: the media tests place the boundary only between 5 and 12 ms (mutation M2d). A 9 ms and a 10 ms MPEG-TS case (90 kHz timestamps are exact) would pin it without relying on the unit test that echoes the filter text.",
          "Item 9 documentation confirmed: a Matroska PCM file whose last packets are stamped 6 ms early loses 288 samples (6.0 ms) at the end of the analysis extraction; chirps stay exact and no silence is inserted. Files whose last packet is not early lose nothing.",
          "Item 12 verified with my own intra-only MPEG-TS files: libx264 with -output_ts_offset 0.011111 (start 127/90 s, printed 1.411111), libx264 with offset 2.777777 (start 188/45 s) and mpeg2video with offset 0.011111 (start 17/12 s). All have origins without an exact microsecond value; the probe returns the exact origin with no warning and no keyframe index (720 of 720 packets are keyframes); cuts at 0, 7/60, 117/20 (tie), 601/120 and 11.49 s show floor(60 t) on all 30 frames in all 15 renders.",
          "Item 5 test bound: a constant 3 ms placement bias passes the jitter render test (M6), because the bound is the file's largest packet deviation. A tighter oracle would compare each render against the measured deviation of its own seek packet.",
          "Changed paths: git diff --stat 6736401..m0-media-follow-ups lists 13 files, all inside the allowed paths (the only docs file is the handback). No skip, xfail or loosened tolerance was added; the replaced gap test keeps its Matroska tolerance and the MPEG-TS variant uses two samples.",
          "Full media tier on the final tree (b6a3e98): ./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock ./scripts/verify.sh --tier media passed 10 of 10 steps; unit tests 108 passed; media and population tests 81 passed in 358 s; evidence run 20261002T122431Z-431451.",
          "Scratch worktree C:/dev/AI-Video-Editor/.claude/worktrees/review-media-real-media-r1 was removed at the end; nothing was committed or pushed and the implementer's worktree was not touched."
        ],
        "summary": "FAIL with one blocking finding, on item 5: the jitter bound the branch documents does not hold on real media. Items 6, 9, 12 and 13 hold on my own constructions, every new test I mutated fails without its fix, no forbidden path changed, and the full media tier passes (10 of 10 steps, 108 unit and 81 media tests).\n\n**Blocking (item 5).** `backend/src/ave/media/audio_timing.py` says deviations below 10 ms are jitter and that a rendered clip sits a sub-tolerance offset from the analysis placement. The threshold is actually measured against the first decoded packet, so it holds only while peak-to-peak jitter is below 10 ms (amplitude under about 5 ms).\n- **MPEG-TS/AAC, alternating +-5.21 ms:** analysis is contiguous with exact chirps, but every 6 s render has 140-141 inserted silence runs of 500 samples, and one chirp is lost at seek 2.0.\n- **Matroska/PCM, alternating +-4.7 ms (10.0 ms peak-to-peak):** the reverse \u2014 analysis gets 234 silence runs and chirps 10 ms late, renders are clean.\n- **Below the boundary:** +-4.9 ms MPEG-TS and +-4 ms Matroska behave as claimed (no silence, error at most 8.33 ms).\n\nThe fix is either the optional robust anchor, or correcting the docstrings to the real bound and adding a case just below the boundary; ASM-008 needs the same correction from the lead.\n\n**Verified on real media.**\n- **Item 13:** ten colors (saturated primaries, secondaries, dark gray, near-black, white) as a pure-background segment and as contain bars store exactly my own BT.709 limited-range values and decode within 0.47 level of the spec round trip through both the exact scaler path and zscale.\n- **Item 6:** MPEG-TS gaps of 3 to 9.9 ms stay contiguous and 10.0 to 33 ms are filled exactly; Matroska behaves the same at its millisecond resolution.\n- **Item 9:** a stream whose last packets are stamped 6 ms early loses exactly 6.0 ms at the end of the analysis extraction, as documented.\n- **Item 12:** three intra-only MPEG-TS files with origins that have no exact microsecond value (libx264 and mpeg2video) probe exactly, store no index, and show floor(60 t) at five cuts each.\n\n**Mutations.** Restoring the old background source fails all four new media cases and the unit test, while the older 4-level test still passes. Tolerances of 1, 5 and 40 ms, the printed-start probe, the rounded origin and the old intra-only condition are each caught. Two survive the media tests: an 8 ms tolerance (caught only by the unit test on the filter text) and a 3 ms render placement bias (inside the test's bound by design); both are non-blocking.\n\nContract files: `C:/dev/AI-Video-Editor/docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md`, `C:/dev/AI-Video-Editor/docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md`, and the handback under `docs/briefs/handbacks/` on branch `m0-media-follow-ups`."
      }
    }
  ]
}

const RESUME_NOTE = `An earlier agent on this task was interrupted before committing. The worktree holds its uncommitted edits: start with \`git status --short\` and \`git diff\`, judge every hunk against the briefs (one hunk can be a temporary mutation that the interrupted agent had yet to revert: a deliberately broken behavior or assertion), keep what is right, repair what is wrong, and complete the rest. Rerun every mutation check yourself; treat nothing as verified.`

const PART4_DECISIONS = `Lead decisions for this part (2026-10-03), after part 3's handback: (a) item 15's commit rule: under "## Input revision" check 11 requires either a delimited 7-to-40-hex token (no letter, digit, underscore or hyphen on either side, so a branch name such as ccr-af7078da-q8r8mf fails) or the self-reference form \`git log -1 --format=%h -- docs/briefs/<this file's own name>\`; checker cases: no commit, branch name only, abbreviated hash accepted, self-reference accepted. (b) The two unlaunched briefs docs/briefs/2026-10-02-m1-backend-core.md and docs/briefs/2026-10-02-m2-synchronization.md name no commit yet: \`git mv\` them into docs/briefs/drafts/ (outside check 11), document in docs/briefs/README.md that a draft has no input revision yet and moves to docs/briefs/ with its commit hash when it is launched, and update the two links in docs/PROGRESS.md § In progress that point at them (the only PROGRESS.md edit you make). (c) Item 23 also rejects a hook entry with \`"async": true\` (such hooks escape their timeout), with a checker case. (d) Part 3's other open questions need no change: record them in your handback as answered.`

const worktreeRules = (name, branch) => `
Host facts: Windows 11 with Git Bash. Repository checks run inside a Linux development container (ADR-009, docs/decisions/ADR-009-linux-development-container-for-other-hosts.md): \`./scripts/verify.sh\` enters it by itself; every other check or test command takes the prefix \`./scripts/dev-container.sh\` (python3, uv, pytest, bash scripts/tests/run.sh, flock).
Working directory: the Git worktree ${ROOT}/.claude/worktrees/${name} (branch ${branch}, created from commit ${BASE}). Your shell starts in the main checkout, which you must leave untouched: begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${name} && \`, and use absolute paths under C:\\dev\\AI-Video-Editor\\.claude\\worktrees\\${name}\\ with Read, Edit, Write, Grep and Glob. First confirm that \`git rev-parse --abbrev-ref HEAD\` in the worktree prints ${branch}; otherwise return BLOCKED.
Rules: keep LF line endings; give a new script its executable bit with \`git update-index --chmod=+x <path>\` after \`git add\`; never push, merge, rebase, switch branches or run \`git worktree prune\`; never amend. Long commands (media or release tier, about 6 to 10 minutes plus lock waiting) run in the background or with a 10-minute timeout. Mutation checks delete __pycache__ directories first (WF-004) and are reverted with the inverse edit or \`git checkout -- <file>\` inside the worktree. Repository text states things affirmatively (avoid "X, not Y", "rather than", "instead of") and never contains model identifiers.
Every commit message ends with your own Co-Authored-By line and this trailer line:
${TRAILERS}
`

const HANDBACK = {
  type: 'object',
  properties: {
    result: { type: 'string', enum: ['COMPLETE', 'PARTIAL', 'BLOCKED'] },
    commits: { type: 'array', items: { type: 'string' } },
    handbackFile: { type: 'string' },
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string' },
          status: { type: 'string' },
          change: { type: 'string' },
          test: { type: 'string' },
          mutation: { type: 'string' },
        },
        required: ['item', 'status'],
      },
    },
    verification: { type: 'string' },
    leadUpdates: { type: 'string' },
    openQuestions: { type: 'string' },
  },
  required: ['result', 'commits', 'items', 'verification'],
}

const REVIEW = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['PASS', 'FAIL'] },
    blocking: {
      type: 'array',
      items: {
        type: 'object',
        properties: { location: { type: 'string' }, defect: { type: 'string' }, evidence: { type: 'string' }, fix: { type: 'string' } },
        required: ['location', 'defect', 'evidence', 'fix'],
      },
    },
    nonBlocking: { type: 'array', items: { type: 'string' } },
    mutations: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
  required: ['verdict', 'blocking', 'summary'],
}

// ---------------------------------------------------------------- Track A: process fixes, part 4 and final check
const PART4 = { n: 4, title: 'Procedures and concurrency', items: '4, 5, 8, 9, 14, 16, 17, 18, 26', commit: 'AVE-REQ-094, AVE-REQ-096, AVE-REQ-098: require persisted briefs and handbacks, enforce one heavy media job' }

const part4Prompt = `Implement part ${PART4.n} ("${PART4.title}") of the M0 process fix work for AVE-REQ-093, AVE-REQ-094, AVE-REQ-096, AVE-REQ-097 and AVE-REQ-098 (all in-progress).
Contract: docs/briefs/2026-10-02-m0-process-fixes-execution.md (execution plan, decisions, constraints) together with docs/briefs/2026-10-02-m0-process-verification-fixes.md (the findings with evidence and required fixes). Read both first. Do items ${PART4.items} only; every other item belongs to another part.
${RESUME_NOTE}
${PART4_DECISIONS}
Earlier parts are committed on this branch: read their handbacks under docs/briefs/handbacks/ and \`git log ${BASE}..HEAD --stat\` before you start, and build on their changes.
${worktreeRules('m0-process-fixes', 'm0-process-fixes')}
Scope: the brief's Allowed paths override your default document boundary for this task (CLAUDE.md, .claude/**, the named docs and the named sections of the five requirement files are in scope where an item requires them). Requirement statements, acceptance criteria, statuses, Status logs, PROGRESS.md (beyond the two links named above), TRACEABILITY.md, ROADMAP.md and ASSUMPTIONS.md stay the lead's: report proposed updates.
Item 5 follows the decision in the execution brief exactly (lock file path, AVE_HEAVY_LOCK_HELD, waiting line, fast tier unlocked), with a tiers-suite case that fails without the lock. After your commit, the final check of the whole task is run by a separate agent.
Procedure per item: make the change, add the test or checker case the finding requires, confirm by mutation that the new test fails without the fix, then restore. When the part is complete: run \`./scripts/verify.sh\` (fast tier) and, because this part touches scripts or hooks, \`./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks\`; both must pass. Write the handback file docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-${PART4.n}.md (per item: change, test, mutation result; commands with results; proposed lead updates; open questions), inspect \`git status\` and \`git diff\`, and commit everything of this part in one commit with the subject "${PART4.commit}" (adjust the summary when your changes differ) plus the trailers.
Return the structured handback: result, the commit hash, the handback file path, one entry per item (status done, partial or open), the verification commands with their results, proposed updates for lead-owned documents, open questions.`

const finalPromptA = `Final check of the M0 process fix work on branch m0-process-fixes (four parts are committed; handbacks under docs/briefs/handbacks/).
Contract: docs/briefs/2026-10-02-m0-process-fixes-execution.md § Test commands and docs/briefs/2026-10-02-m0-process-verification-fixes.md.
${worktreeRules('m0-process-fixes', 'm0-process-fixes')}
Run, in the worktree: (1) \`./scripts/verify.sh --tier release\` (it takes the heavy-media lock by itself after item 5; it can wait while another agent renders); (2) \`./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 AVE-REQ-094 AVE-REQ-096 AVE-REQ-097 AVE-REQ-098 --require-fresh\`; (3) \`./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks\`.
When a step fails because of this branch's changes, fix the root cause inside the brief's allowed paths (never weaken a check), commit with the subject "AVE-REQ-097: <imperative summary>" plus the trailers, and rerun until all three pass. Also walk items 1 to 26 of the fix brief against the branch (\`git diff ${BASE}..HEAD\`) and list every item that is open or only partly done, with the missing piece.
Write docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.final.md with the command results, the per-criterion evidence states and the open-item list, and commit it ("docs: record the final check of the M0 process fixes" plus the trailers).
Return the structured handback: result (COMPLETE only when all three commands pass on the final commit), commits you added, one entry per fix-brief item (status done, partial or open, with the evidence location), the verification results, proposed lead updates, open questions.`

const trackA = async () => {
  const part4 = await agent(part4Prompt, { label: 'process:part-4', phase: 'Process fixes', agentType: 'implementer', schema: HANDBACK, ...IMPL })
  if (!part4 || part4.result === 'BLOCKED') {
    log(`Process fixes: part 4 returned ${part4 ? part4.result : 'no result'}; stopping the track`)
    return { part4, final: null }
  }
  const fin = await agent(finalPromptA, { label: 'process:final-check', phase: 'Process fixes', agentType: 'implementer', schema: HANDBACK, ...IMPL })
  return { part4, final: fin }
}

// ---------------------------------------------------------------- Track B: media fix rounds and re-reviews
const lensPrompt = (lens, round, scratch) => `Independent review (${lens.name} lens, round ${round}) of the media-core follow-up work on branch m0-media-follow-ups: commits ${BASE}..m0-media-follow-ups in ${ROOT}.
Contract the work claims to satisfy: docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md and docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md (read them from the branch: \`git show m0-media-follow-ups:<path>\`), plus the handback docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md. The handback is a claim; verify it. Round ${round} follows a fix round: the handback's "Review round ${round - 1}" section lists the fixes; check them with your own constructions as well as the original items.
Host facts: Windows 11 with Git Bash; checks run in a Linux development container: prefix commands with \`./scripts/dev-container.sh\`. Work in your own scratch worktree so nothing you do touches the implementer's files: from the main checkout run \`cd /c/dev/AI-Video-Editor && git worktree add --detach .claude/worktrees/${scratch} m0-media-follow-ups\`, then begin every Bash command with \`cd /c/dev/AI-Video-Editor/.claude/worktrees/${scratch} && \`. Mutations happen only there. Remove it at the end with \`cd /c/dev/AI-Video-Editor && git worktree remove --force .claude/worktrees/${scratch}\`. Never run \`git worktree prune\`, never commit, never push.
Every heavy media command holds the shared lock: \`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock <command>\`; it waits while another agent renders, so use the background or a 10-minute timeout. Delete __pycache__ directories before every mutation rerun (WF-004).
${lens.focus}
A finding is blocking when an item's required change is missing or wrong, a new or changed test passes without its fix (mutation survives), a tolerance or check was loosened, a forbidden path changed (\`git diff --stat ${BASE}..m0-media-follow-ups\`), or real media contradicts a claim. Everything else is non-blocking. Return verdict PASS only with zero blocking findings; list each blocking finding with location, defect, the evidence you measured and the required fix, and list the mutations you ran with their results.`

const LENSES = [
  {
    key: 'oracles',
    name: 'oracle strength and mutation',
    focus: 'Focus: items 1 to 4, 6, 10, 11 and 12, and every test the fix round changed. For each, check the change against the brief, then mutation-check the new or changed tests yourself (at least six mutations across the items, chosen by you: the rounding in the origin tie case, the error-text assertion, the exact-start guard, the gap filter threshold, the intra-only condition, a cut time, the jitter bound). Run the unit suites and the targeted media tests.',
  },
  {
    key: 'real-media',
    name: 'real-media reconstruction',
    focus: 'Focus: items 5, 6, 9, 12 and 13, and the fix of the round-1 blocking finding on the jitter bound (deviations are measured from the first decoded packet; jitter is tolerated only while its peak-to-peak spread stays below 10 ms). Rebuild the claims with your own constructions that the implementer has never seen: jittered Matroska and MPEG-TS sources with amplitudes on both sides of the boundary (for example alternating +-4.5 ms, +-4.9 ms, +-5.2 ms) and several seek points, comparing analysis extraction and render placement; timestamp gaps of other sizes on both sides of 10 ms; an intra-only file with an offset origin; for item 13 at least four background colors of your choice rendered as a pure-background segment and as contain bars, decoded with zscale and with the exact scaler path, compared with BT.709 limited-range spec math you compute yourself. Mutation: restore the old behavior for the jitter bound and the background source and confirm the new tests fail. Run the full media tier once at the end.',
  },
]

const fixPromptB = (round, findings, resume) => `Fix the blocking review findings (round ${round}) on the media-core follow-up work, branch m0-media-follow-ups. AVE-REQ-012, AVE-REQ-024, AVE-REQ-019 and AVE-REQ-020 are in-progress.
Contract: docs/briefs/2026-10-02-m0-media-core-follow-ups-execution.md and docs/briefs/2026-10-02-m0-media-core-round-3-follow-ups.md; the same allowed and forbidden paths apply.
${worktreeRules('m0-media-follow-ups', 'm0-media-follow-ups')}
Every heavy media command holds the shared lock: \`./scripts/dev-container.sh flock /tmp/ave-heavy-media.lock <command>\`.
${resume ? RESUME_NOTE : ''}
Blocking findings to fix, each with a test that fails without the fix (mutation-checked):
${JSON.stringify(findings, null, 2)}
When a finding is wrong, say so with measured evidence and leave the code unchanged for it. Run the media tier under the lock until it passes, append a "Review round ${round}" section to docs/briefs/handbacks/2026-10-02-m0-media-core-follow-ups-execution.md, and commit as "AVE-REQ-012, AVE-REQ-024: fix review findings of the follow-ups (round ${round})" plus the trailers (name AVE-REQ-019, AVE-REQ-020 as well when item 13 changed).
Return the structured handback with one entry per finding.`

const reviewRound = async (round, lenses) => {
  const results = await parallel(lenses.map(lens => () =>
    agent(lensPrompt(lens, round, `review-media-${lens.key}-r${round}`), {
      label: `media-review:${lens.key}:r${round}`,
      phase: 'Media review',
      agentType: 'reviewer',
      schema: REVIEW,
      ...VERIFY,
    }).then(r => ({ lens: lens.key, review: r }))))
  return results.filter(Boolean)
}

const trackB = async () => {
  const rounds = [{ round: 1, reviews: R1.reviews, fix: null }]
  let findings = R1.reviews.filter(r => r.review.verdict !== 'PASS').flatMap(r => r.review.blocking.map(b => ({ lens: r.lens, ...b })))
  for (let round = 1; round <= 3; round++) {
    const fix = await agent(fixPromptB(round, findings, round === 1), { label: `media:fix-r${round}`, phase: 'Media follow-ups', agentType: 'implementer', schema: HANDBACK, ...IMPL })
    rounds[rounds.length - 1].fix = fix
    if (!fix || fix.result === 'BLOCKED') { log(`Media fix round ${round} returned ${fix ? fix.result : 'no result'}; handing over to the lead`); break }
    const reviews = await reviewRound(round + 1, LENSES)
    const failed = reviews.filter(r => !r.review || r.review.verdict !== 'PASS')
    rounds.push({ round: round + 1, reviews, fix: null })
    if (reviews.length === LENSES.length && failed.length === 0) break
    findings = failed.flatMap(r => (r.review ? r.review.blocking.map(b => ({ lens: r.lens, ...b })) : []))
    if (findings.length === 0) { log('Media review: a lens returned no result; handing over to the lead'); break }
    if (round === 3) log('Media review: blocking findings remain after three fix rounds; handing them to the lead')
  }
  return { rounds }
}

const [a, b] = await parallel([() => trackA(), () => trackB()])
return { base: BASE, processFixes: a, mediaFollowUps: b }
