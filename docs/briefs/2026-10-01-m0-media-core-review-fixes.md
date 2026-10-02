# Brief — Fix the M0 media-core review findings

## Requirements
In-progress requirements whose edge cases the findings violate: AVE-REQ-012 (AC-4 edge cases "VFR sources with
irregular gaps; container start time other than zero"), AVE-REQ-024 (AC-3 edge case "unrelated audio → insufficient
evidence, never a fabricated offset"), AVE-REQ-004 (AC-4 untrusted filenames), AVE-REQ-072 (AC-4 atomic publish,
originals never overwritten), AVE-REQ-031 (AC-1 B never audible). Independent review of commit `24499a6`
(verdict FAIL); every blocking finding below was reproduced by the reviewer on real media.

Blocking:
1. Audio ignores the audio stream's own start. `render/compiler.py:490-491`, `render/ffmpeg.py:204-226`,
   `sync/audio.py:211-224` treat decoded sample 0 as source time `seek` (or 0), but without `-copyts` the first
   delivered sample is the stream's first sample. Evidence: std-a remuxed with `-itsoffset 0.5` on audio (audio
   start 0.478, container start 0): render with source_in=0 puts the first chirp at 3.238 s instead of 3.716 s;
   `estimate_offset(std-a, delayed)` returns a = −0.0213 instead of about −0.5. Required: sample positions follow
   presentation timestamps relative to the container start (ADR-004 § Decision 2) in the render path and in the
   analysis extraction, with real-media tests for audio start ≠ container start and source_in < 1 s.
2. A VFR gap longer than the 1 s seek margin shows a future frame (`render/compiler.py:77,388`,
   `render/ffmpeg.py:124-127`). Evidence: std-a frames 0–59 then 240 onward (gap 0.98 s → 4.0 s), clip
   source_in=7/2: output frames 0–29 show frame 240 where the rule requires 59. Required: the frame rule (latest
   source frame with PTS ≤ t) holds for any gap length; real-media test with a gap longer than 1 s.
3. The sync estimator returns status OK with an invented offset on unrelated audio (`sync/audio.py:73,530-545`).
   Evidence: 14 of 400 seeded unrelated chirp pairs (tests' `recording()` helper) returned OK with
   matched_onsets=2, confidence 0.35–0.67, peak_ratio 1.50–1.81. Required: zero OK results on a seeded property
   test of at least 400 unrelated pairs, while every existing positive case (offsets ±, sub-frame, gain, noise,
   44.1 vs 48 kHz, partial overlap, AT-04 fixtures) still passes with its current accuracy.
4. Image filenames are read as image2 sequence patterns (`proc.py:47-49`, `media/probe.py:422-430`,
   `render/ffmpeg.py:117-121`). Evidence: `photo%d.png` (640x360) next to `photo1.png` (64x48): `describe_asset`
   reports 64x48. Required: a file is always read as itself in probe and render; tests with `%` in image names.

Non-blocking, in scope:
5. `tests/media/test_at02_render.py:250`: "B never audible" checks only the left channel; check every channel.
6. `tests/unit/test_sync_signals.py:157`: `bounded.offset != 6` is always true with `max_offset_s=3`; assert the
   status instead.
7. `render/ffmpeg.py:363-376`: `render()` must refuse a destination that resolves to any input path of the plan
   (an original can never be replaced); test it.
8. Output frames before a source's first video frame (no frame with PTS ≤ t) currently show the first frame.
   Keep that behavior (clamp to the first frame: no black flash at a source's start), state it in the compiler
   docstring and test it on a real file whose first video frame starts after the container start.
9. `sync/audio.py:211-220` holds the whole decoded stream in float64. Have FFmpeg deliver mono at the analysis rate
   as float32 so memory stays at about 4 bytes × analysis rate × duration (2-hour footage must not need gigabytes).
10. ADR-004 § Decision 4 separates clock-drift correction (`source_speed = 1/b`) from editorial speed, but `Clip`
    has only `source_speed`. Add a separate editorial speed field (default 1) so the mapping is
    `t = source_in + (T - timeline_start) * source_speed * editorial_speed`, keep pitch-preserving audio for
    editorial speed, and update the builders and tests; serialized compositions without the field stay valid.
11. `media/probe.py:369`: container start time comes from ffprobe's 6-decimal value. Document that this matches
    FFmpeg's internal microsecond resolution (a comment at the parse site).

## Input revision
`24499a6` on `ccr-af7078da-q8r8mf`; isolated worktree (branch created by the runtime from that HEAD). Commit on the
worktree branch when verification passes; never push, merge or rebase.

## Allowed paths
`backend/src/ave/**`, `backend/tests/**` except the forbidden paths below, `backend/README.md`.

## Forbidden paths
`backend/pyproject.toml`, `backend/uv.lock`, `backend/tests/conftest.py`, `backend/tests/evidence_plugin.py`,
`scripts/**`, `docs/**`, `.github/**`, `.claude/**`, `CLAUDE.md` (the lead is changing the verification and test
tagging infrastructure concurrently). Report any change needed there.

## Dependencies and constraints
- ADR-004 (time model; source time normalized by the container start), ADR-005 (segmented renderer, decoded
  validation, atomic publish). Argv-only subprocess calls through `ave.proc.run_tool`.
- Oracles stay independent of the code under test (fixture manifests, spec tables, bisect/floor rules). Never loosen
  a tolerance, skip a test or weaken an assertion to get green.
- Tag every new or changed test with one full `AVE-REQ-NNN AC-n` string per criterion in its docstring (no
  `AC-1/AC-2` shorthand); the lead converts the tags to pytest markers after integration.
- One heavy media job at a time: run the media tier once per fix round, not in parallel loops.
- Setup in a fresh worktree: `uv sync --frozen --directory backend`; fixtures regenerate under the worktree's `var/`.

## Test commands
- `./scripts/verify.sh --tier media` (fast checks plus the real-media tests) — must pass.
- For finding 3, also report the measured false-positive count and the accuracy on every positive case before and
  after the change.

## Handback schema
`## Result: COMPLETE | PARTIAL | BLOCKED`, then: branch and commit hash; per finding (1–11): the root cause, the
change (file:line), the test that now fails without the fix (name and how you confirmed it fails), and measured
numbers; commands run with results; deviations and proposed follow-ups; shared-document updates for the lead.
