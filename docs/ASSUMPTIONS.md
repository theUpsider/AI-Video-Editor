# Assumptions

Missing information that does not justify interrupting the human becomes a recorded
assumption here. Escalation criteria: [CLAUDE.md](../CLAUDE.md) § Autonomy and escalation.

## Rules

1. Make a reasonable, industry-standard assumption; record it here; continue.
2. Record it before, or in the same commit as, the work that relies on it, and cite its
   `ASM-NNN` in that requirement or ADR.
3. Allocate the next free `ASM-NNN` and append the entry at the end. Never reuse, renumber or
   delete entries.
4. Change **Status** in place and append ` — YYYY-MM-DD — <evidence or link>`.
5. When an assumption becomes a requirement or ADR, set `superseded` and add the REQ/ADR to
   **Links**.
6. When an assumption proves false, set `invalidated`, add the follow-up (new requirement, ADR
   change or re-plan) to **Links**, and repair the affected work.
7. `milestone-review` revisits every `open` assumption: confirm, invalidate, supersede, or keep
   it open with a reason.
8. An assumption that would materially change the intended product is a question for the
   human: escalate it and track it in [PRODUCT.md](PRODUCT.md) § Open product questions.

## Entry format

```
### ASM-NNN — Short title
- **Date:** YYYY-MM-DD
- **Assumption:** what is taken as true
- **Reason:** why it is reasonable and why the human was not asked
- **Impact:** what changes if it proves false
- **Status:** open | confirmed | invalidated | superseded
- **Links:** ADR-NNN, AVE-REQ-NNN
```

## Status meanings

- `open` — in effect, unverified.
- `confirmed` — validated by evidence or by the human.
- `invalidated` — proven false; follow-up recorded.
- `superseded` — became a requirement or ADR; linked.

## Entries

### ASM-001 — Project hooks activate after workspace trust
- **Date:** 2026-10-01
- **Assumption:** Future sessions load the SessionStart and Stop hooks from
  [.claude/settings.json](../.claude/settings.json) once the workspace is trusted.
- **Reason:** The bootstrap session created the hooks mid-session and could not exercise them.
- **Impact:** If false, the verification gate and recovery context fall back to
  [CLAUDE.md](../CLAUDE.md) instructions and CI.
- **Status:** confirmed — 2026-10-01 — the resumed session showed the "Project state" block injected by
  [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh) (source: resume).
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-002 — Baseline tooling
- **Date:** 2026-10-01
- **Assumption:** `bash` (3.2+), `git`, and POSIX `awk`, `grep` and `sed` exist wherever
  verify.sh and the hooks run (Linux, macOS, WSL/Git Bash).
- **Reason:** These tools ship with mainstream development environments and CI runners, so
  the scripts need no further dependencies.
- **Impact:** If false, verification needs a POSIX shell environment on that machine.
- **Status:** open
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-003 — GitHub hosts the repository and runs CI
- **Date:** 2026-10-01
- **Assumption:** GitHub hosts the canonical repository (`github.com/theUpsider/AI-Video-Editor`)
  and GitHub Actions runs CI.
- **Reason:** The configured Git remote points to that GitHub repository.
- **Impact:** If false, port [.github/workflows/verify.yml](../.github/workflows/verify.yml) to
  the actual CI system; it only runs `./scripts/verify.sh`.
- **Status:** confirmed — 2026-10-01 — first CI run green on commit f605c6c
  (https://github.com/theUpsider/AI-Video-Editor/actions/runs/36851238702).
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-004 — Baseline interpretation register adopted
- **Date:** 2026-10-01
- **Assumption:** The baseline's interpretation register (ASM-01 to ASM-20 in
  [SCOPE_AND_ASSUMPTIONS.md](../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md)) holds for this
  implementation: self-hosted single-owner browser editor with a media worker; probed (never assumed)
  dimensions/rates; unconfirmed "DJI Go" device terminology; contain/padding as the default square layout; Auto
  output rate from the reference source with a 1080p 16:9 canvas; final audio separate from sync evidence; common
  coverage for split segments; evidence-dependent sync; ASR scope without dubbing/diarization; bounded indexing as
  the version-one foundation; distinct caption/metadata products; 1:1 15–20 s shorts; agent runtimes distinct from
  models; no inherited credentials; CPU mandatory and GPU conditional; no social publishing; consented, budgeted
  external compute; environment-discovered versions; defaults changeable only by ADR.
- **Reason:** The human supplied the register with the requirements; it resolves every ambiguity the brief leaves.
- **Impact:** If the human revises any entry, apply it through `product-definition` amendment mode.
- **Status:** open
- **Links:** [ADR-002](decisions/ADR-002-technology-stack.md), [ADR-003](decisions/ADR-003-requirements-baseline-import.md)

### ASM-005 — Synthetic fixtures stand in for real camera footage
- **Date:** 2026-10-01
- **Assumption:** Deterministic, clearly labeled synthetic media (markers, flashes, impulses, pilot tones,
  synthesized speech) is sufficient evidence for timing, geometry, routing and caption criteria; it never
  represents the user's real footage.
- **Reason:** No user footage, camera model or color profile was supplied; the baseline requires generated
  fixtures with independent ground truth.
- **Impact:** Real-footage behavior (camera color profiles, real-world sync evidence quality) stays a reported gap
  until footage is supplied.
- **Status:** open
- **Links:** [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md)

### ASM-006 — The development container is no deployment target
- **Date:** 2026-10-01
- **Assumption:** The measured Claude Code container ([ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md))
  is a build/test environment with no GPU, no Docker daemon, no product credentials and no Hugging Face access.
  Live provider, agent-runtime, vision, translation, multilingual ASR, container and GPU criteria are implemented
  and contract-tested here and reported as externally unverified with exact prerequisites.
- **Reason:** Measured network policy and device checks.
- **Impact:** If the environment gains access, rerun the corresponding live tests and update the matrix.
- **Status:** confirmed — 2026-10-01 — measured
- **Links:** [ADR-007](decisions/ADR-007-ai-integration-boundaries.md), [ADR-008](decisions/ADR-008-local-speech-recognition.md)

### ASM-007 — Audio sync accepts an offset only when chance and rival alignments are ruled out
- **Date:** 2026-10-02
- **Assumption:** The audio offset estimator (`ave.sync.audio`) reports OK only when the coinciding onsets at the
  chosen lag are unlikely by chance (binomial bound times the number of searched lags at most 1e-3) and no other
  alignment that chance does not explain has at least half as many coincidences; otherwise it reports
  insufficient evidence or ambiguity with alternatives. Thresholds are validated on seeded synthetic populations
  only.
- **Reason:** A confident wrong offset is the one unacceptable outcome (CLAUDE.md product invariants,
  AVE-REQ-024); independent reviews found wrong offsets on unrelated, lattice-noise and same-tempo populations
  before these gates.
- **Impact:** Sensitivity cost, measured by the independent review: music-like scenes with a strong shared
  rhythm become ambiguous (9 of 100 music-like positives right with the gate, 100 without), so such footage needs
  visual or manual anchors (AVE-REQ-025, AVE-REQ-030) until the M2 synchronization work adds a waveform-level
  discriminator. Known open weakness, measured by the round-3 review of `dc89da2`: unrelated recordings whose
  notes sit on a shared rhythmic grid still return a confident wrong offset in 0.3 to 0.9 % of synthetic pairs
  (22 of 6,720 over grid steps 1/8 to 1/2 s, densities 0.05 to 0.4 and four transient families; none at
  densities 0.3 and above; the worst family is step 1/2 s at densities 0.1 to 0.2; the population test's own
  family, step 1/4 s at density 0.15, gives 5 of 1,000 outside its seed slice). The wrong results match 3 to 6
  onsets with chance probabilities from 8e-4 down to 1e-9, and the rival gate never fires on them. The M2
  synchronization task owns the fix (a lattice-aware null model or the waveform-level discriminator).
- **Status:** open
- **Links:** [AVE-REQ-024](requirements/AVE-REQ-024-audio-based-offset-estimation.md), [WORKFLOW_LOG WF-001](WORKFLOW_LOG.md)

### ASM-008 — Audio timestamp deviations up to 10 ms are jitter
- **Date:** 2026-10-02
- **Assumption:** Decoded audio is placed by its timestamps; deviations from a contiguous stream below 10 ms are
  treated as container rounding or muxer jitter (samples stay contiguous), deviations of 10 ms or more as real
  gaps or overlaps (filled with silence or dropped in full; FFmpeg's threshold is a float option, so exactly
  10 ms is corrected). A rendered clip of a jittered source sits up to the jitter of its seek packet (below
  the threshold) from the analysis placement of the same source.
- **Reason:** A 1 ms threshold inserted hundreds of dropouts into a stream with 2 ms jitter; one lost AAC frame is
  21.3 ms at 48 kHz, so real gaps stay above the threshold.
- **Impact:** A genuine gap shorter than 10 ms stays uncorrected (an error below one frame at 60 fps).
- **Status:** open
- **Links:** [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md), `backend/src/ave/media/audio_timing.py`

### ASM-009 — Output before a source's first video frame shows that first frame
- **Date:** 2026-10-02
- **Assumption:** When a clip's source time precedes the stream's first video frame (a video stream that starts
  after the container start), the output shows the first frame instead of the background.
- **Reason:** The frame rule (latest frame with PTS <= t) has no frame there; a background flash at a clip's start
  would be a visible artifact, while the first frame is what players show.
- **Impact:** Up to the stream's start offset (typically a few milliseconds) shows a held first frame.
- **Status:** open
- **Links:** [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md), `backend/src/ave/render/compiler.py`
