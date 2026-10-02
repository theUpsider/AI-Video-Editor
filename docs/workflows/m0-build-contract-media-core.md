# Implementation contract — media core (first real CPU render + sync slice)

Repository: /home/user/AI-Video-Editor. Immutable spec: ai-video-editor-requirements/ (never edit).
Read only what you need: spec/DATA_AND_TIMING_MODEL.md, spec/ACCEPTANCE_TESTS.md (AT-02, AT-03, AT-04),
spec/TECHNICAL_DEFAULTS.md, and the requirement files AVE-REQ-004, 012, 018, 019, 020, 021, 024, 031, 072, 075
in ai-video-editor-requirements/spec/requirements/.

## Environment facts (measured)
Ubuntu 24.04, 4 vCPU, 15 GiB RAM, no GPU, Python 3.11.15, uv 0.8.17, FFmpeg/FFprobe 6.1.1 (libx264, libx265,
libvpx-vp9, libsvtav1, aac, libopus, drawtext+harfbuzz, libass, rubberband, zscale, flite), PyPI reachable,
Hugging Face blocked. Fonts: DejaVu, Liberation, IPAGothic, Noto Color Emoji.

## Paths you own (write only here)
- backend/ — uv project (pyproject.toml, uv.lock, src/ave/**, tests/**). Python 3.11. Package name `ave`.
- var/ is the gitignored runtime/artifact root: generated fixtures in var/fixtures/, test outputs in var/test-artifacts/.
Do not edit docs/, scripts/, .claude/, CLAUDE.md or ai-video-editor-requirements/.

## Dependencies
uv-managed, pinned via uv.lock: pydantic>=2, numpy, scipy; dev: pytest, ruff, mypy. Add nothing else
without need (no Pillow unless frame generation really needs it; prefer ffmpeg lavfi or numpy).
Commands that must work from backend/: `uv sync`, `uv run pytest`, `uv run ruff check`, `uv run ruff format --check`,
`uv run mypy src`.

## Modules to build (src/ave/)
1. `ave/timebase.py` — exact time: Fraction-based `Rational` helpers, JSON form {"num","den"} (den>0, reduced),
   half-open `Interval[start,end)` with validation (reject end<=start, NaN/float input unless explicitly converted),
   frame-grid helpers: `frame_start(n, fps)=n*fps.den/fps.num`, `frames_in(interval, fps)` = range of frame indices
   n with interval.start <= n/fps < interval.end (i.e. ceil(start*fps) .. ceil(end*fps)-1), sample-grid equivalents.
   Never convert 60000/1001 to 60. Property tests for long timelines (e.g. 10^6 frames at 60000/1001, repeated edits).
2. `ave/media/probe.py` — ffprobe JSON → typed `ProbeInfo` (container, duration, streams with codec, exact
   width/height, rotation → display width/height, SAR, r_frame_rate & avg_frame_rate as Rational, time_base,
   start_time, VFR flag (r != avg or PTS deltas irregular — inspect packet/frame PTS when needed), pix_fmt,
   color_range/space/transfer/primaries, sample_rate, channels). Subprocess with argv list, timeout, no shell.
3. `ave/domain/model.py` — Pydantic v2 models (frozen where sensible) for the composition document:
   - `Canvas(width, height)`; `Sequence(id, name, kind main|short, parent_id, canvas, fps: Rational,
     sample_rate=48000, background="#000000", tracks, clips, sync_groups)`.
   - `Track(id, kind video|audio, name, index, muted, solo, locked, hidden)`; video z-order = index (higher on top).
   - `Clip(id, track_id, asset_id, kind video|audio|image, timeline_start: Rational (project time),
     source_in, source_out: Rational (source time, half-open), source_speed: Rational=1 (source seconds per project
     second; drift correction uses 1/b), stream_index, region: NormRect (x,y,w,h as Rationals in canvas fractions,
     default full), fit: contain|cover (never a silent stretch; an explicit `stretch` value may exist but is never
     a default), focus_x/focus_y for cover crop (0..1, default 1/2), gain_db=0, enabled=True, link_group: str|None,
     locked=False)`. Clip project duration = (source_out - source_in)/source_speed.
   - `SyncGroup(id, reference_asset_id, members: [SyncMember(asset_id, a: Rational (reference seconds),
     b: Rational (scale), method, confidence: float, anchors, residual_s, user_supplied)])` with the spec convention
     T_reference = a + b * t_source; reference member a=0, b=1.
4. `ave/domain/layout.py` — pure geometry: given canvas, region, source display size, fit, focus → integer pixel
   scale size, crop rect, and placement (x,y). Contain of 1080x1080 into the left half of 1920x1080 must give
   960x960 at (0,60); right half at (960,60). Cover gives 1080x1080 cropped to 960x1080 (crop x offset from focus).
   Document rounding (even dimensions for yuv420p).
5. `ave/domain/sync_layout.py` (or similar) — build the standard split/full/split timeline from a SyncGroup and a
   reference interval: given reference interval [G0,G1) placed at project P0, clip i source_in = (G0 - a_i)/b_i,
   source_speed = 1/b_i. Default split coverage = common overlap of members (AT-05 later extends policies).
6. `ave/render/compiler.py` + `ave/render/ffmpeg.py` — compile (Sequence, assets, OutputProfile, project range)
   into a RenderPlan and execute it with FFmpeg on CPU:
   - Segment the range at every clip boundary into intervals where the active layer set is constant; each segment
     covers whole output frames (frames n with start <= n/fps < end). Render each segment with a small filter graph
     (filter script file via -filter_complex_script, argv lists only, no shell): per active video clip in z-order,
     accurate input seek near the needed source time, trim/setpts to the exact source span, convert to the output
     grid with explicit timestamp semantics (output frame n shows, for each clip, the latest source frame whose
     PTS <= mapped source time t = source_in + (n/fps - timeline_start)*source_speed; document and test this rule,
     including VFR sources), scale/crop/pad per layout, overlay onto the background canvas.
   - Audio: render the whole range's audio once: each enabled, unmuted audio clip → sample-accurate trim, resample to
     48 kHz (soxr or swr), time-scale by source_speed when != 1 using rubberband (pitch preserved), gain, delay to its
     project position, mix with normalize=0 (no automatic level halving). Output exactly round(range_duration*48000)
     samples.
   - Encode segments with identical libx264 settings (yuv420p, closed GOP, keyframe at segment start), concatenate
     with stream copy, mux with AAC 48 kHz audio into MP4 (+faststart). Default profile: H.264 CRF 20 preset medium,
     AAC 192k, canvas/rate from the sequence. Write to a temp path and atomically rename only after validation.
   - Return a RenderReport (segments, commands, durations, encoder settings, validation results).
7. `ave/render/validate.py` — decoded-output validation used by the product and by tests: ffprobe the output
   (codec, dimensions, rate as exact rational, duration, stream count), decode video frames to raw RGB at reduced
   resolution and audio to float PCM, and expose helpers to sample frames and audio windows.
8. `ave/sync/audio.py` — audio-based offset estimation (AVE-REQ-024): extract mono analysis audio (any sample rate)
   with ffmpeg, compute onset/envelope features at a common analysis rate, FFT cross-correlation over plausible
   bounds, refine around the peak at a finer rate with parabolic interpolation, report offset a (reference
   seconds, spec sign convention), peak-to-second-peak ratio (outside a guard window) and normalized correlation as
   confidence, and return INSUFFICIENT_EVIDENCE / ambiguous alternatives when the evidence is weak (silent track,
   unrelated audio, periodic signal). Works when the camera audio will be muted in export.
9. `ave/fixtures/` — deterministic synthetic fixture generator + ground-truth manifest (JSON with all parameters and
   expected marker times), clearly labeled synthetic. Keep generation code independent from the renderer/compiler.
   Standard composition (spec): A square 1080x1080, 60/1, source [0,30) (reference), audio 48 kHz; B square
   1080x1080, 60/1, source [0,25) starting 2 s after A (a_B=2, b_B=1), audio 44.1 kHz with different gain and added
   noise; C 1920x1080 60/1, 6 s, audio 48 kHz. Each video frame shows a source-specific background color and a large
   binary barcode of its source frame index (cells big enough to survive 1080→960 scaling and H.264), plus a
   one-frame full-white flash on shared events. Shared events: nonperiodic reference frames at 60 fps
   (e.g. 193, 354, 566, 783, 1063, 1282, 1488) so they fall on exact frame boundaries for A and B; at each event both
   A and B audio contain the same short broadband impulse/chirp. Each source carries a distinct low-level pilot tone
   (e.g. A 1000 Hz, B 1700 Hz, C 2600 Hz) for source identification in the output mix. Also generate a short
   2560x1440 60/1 clip (e.g. 4 s) for AT-03 probing. Cache fixtures by parameter hash under var/fixtures/.

## Tests (backend/tests/), tagged with requirement/AC IDs in names or docstrings, e.g. "AVE-REQ-020 AC-1"
- Unit: timebase (exactness, half-open intervals, 60 vs 60000/1001, rejection of invalid values), layout geometry,
  probe parsing (real ffprobe on fixtures: exact 2560x1440, 60/1), sync estimation (positive offset, negative offset
  by swapping reference, gain change, noise, 44.1 vs 48 kHz, partial overlap, unrelated/silent → insufficient
  evidence, periodic → ambiguous).
- Integration (real FFmpeg, mark with a pytest marker `media`): the AT-02 standard 22-second composition rendered
  at 1920x1080 60/1 with sync taken from the *estimated* mapping:
  project [0,8) split A [2,10) | B [0,8); [8,14) full-width C [0,6); [14,22) split A [12,20) | B [10,18);
  final audio A in split segments, C in the full segment; B audio muted in export but used for sync.
  Oracles must be computed independently from the fixture manifest and spec math (do not import compiler mapping
  code into the oracle): duration within one output frame of 22 s; contain geometry (960x960 at y=60 in both halves,
  background strips black); barcode-decoded source frame indices in segment interiors match expected source frames
  (±1 frame); flash events appear in both halves on the same output frame and at the expected output frame (±1);
  audio impulses in the output within one output frame of the expected time; pilot-tone energy shows only A in split
  segments and only C in the full segment (B never audible); original fixture SHA-256 unchanged after rendering.
  Also render a cover-mode variant and assert crop (no aspect change).
- Keep media tests reasonably fast (lower resolution decode for analysis is fine; the render itself stays 1920x1080).

## Done means
`uv run pytest` (including media tests) passes, ruff/format/mypy pass, and you return a structured handback:
requirement_ids, base_revision (git rev-parse HEAD at start), changed_paths, criteria_results (per AC: what test
proves it, PASS/FAIL), commands_run with results, artifact_paths, unresolved_findings, status
"implemented_not_yet_independently_verified". Do not commit; the lead integrates. Do not claim anything you did
not run.
