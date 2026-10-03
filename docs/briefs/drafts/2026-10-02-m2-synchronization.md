# Brief — M2 synchronization: candidates, visual and manual anchors, drift, coverage

## Requirements
Implement the backend acceptance criteria of (working files in `docs/requirements/AVE-REQ-NNN-*.md`; read each in
full):
- AVE-REQ-023 Synchronization candidate matching (AC-1–AC-4).
- AVE-REQ-024 Audio-based offset estimation: extend with multi-window evidence and residuals (AC-2, AC-3).
- AVE-REQ-025 Silent or weak-evidence synchronization (AC-1–AC-4: shared visual events, manual anchors, explicit
  INSUFFICIENT_SYNC_EVIDENCE; coarse metadata labeled approximate).
- AVE-REQ-026 Persistent synchronization transforms (AC-1–AC-4 at the domain level: re-express a group under
  another reference exactly; source↔reference mappings for video frames, audio samples and transcript times).
- AVE-REQ-027 Unequal coverage and missing-perspective policy (AC-1–AC-4 in a new `ave.domain.coverage`).
- AVE-REQ-028 Clock-drift detection and correction (AC-1–AC-4: robust affine fit from several anchors, constant
  offset versus drift, inconsistent anchors flagged, a single uncertain match never becomes a speed change).
- AVE-REQ-030 Manual synchronization tools, backend part (anchors, one-frame and audio-sample nudges, re-fit with
  residuals; a user-supplied mapping survives re-analysis unless explicitly reset).
- AVE-REQ-024 AC-3 hardening ([ASM-007](../../ASSUMPTIONS.md)): the onset-timing gates cannot separate sparse genuine
  evidence from unrelated recordings on a shared rhythmic grid. Add a waveform-level discriminator between the
  chosen and the competing alignments (the same scene shares the whole waveform; unrelated music shares at most
  transient shapes). Targets on seeded populations: 0 wrong offsets on unrelated grid music over grid steps
  1/8, 1/6, 3/16, 1/4, 1/3, 3/8 and 1/2 s, densities 0.05 to 0.2, with identical, random-level, mixed (chirp,
  noise burst, pluck, click) and shared-kit transients, a few hundred seeds per family (today 22 of 6,720 wrong;
  worst step 1/2 s at density 0.1 to 0.2; step 1/4 s at density 0.15 gives 5 of 1,000 on seeds 7200–8199); at
  least 90 of 100 right on music-like positives with a shared rhythm and unique events (9 of 100 today); no
  regression on the existing populations in `tests/unit/test_sync_populations.py`. Rename
  `test_unrelated_music_on_a_shared_grid_never_yields_an_offset` to the property it shows until the estimator
  meets the 0-wrong target on the larger population.
Scenarios AT-04 to AT-08 in `ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md`; timing convention in
`spec/DATA_AND_TIMING_MODEL.md` (§ Synchronization) and ADR-004: `T_reference = a + b * t_source`, reference member
`a = 0, b = 1`, drift applied as `source_speed = 1 / b`, editorial speed separate (`Clip.editorial_speed`).

## Input revision
The `ccr-af7078da-q8r8mf` commit that closes M0 (media-core fixes merged, test tags converted to markers, M0
review recorded); the launching prompt names its hash. Isolated worktree created by the runtime from that HEAD.
Confirm `git log --oneline -1` shows that hash before changing anything; report a mismatch as BLOCKED. Commit on the
worktree branch when verification passes; never push, merge or rebase.

## Allowed paths
`backend/src/ave/sync/**`, `backend/src/ave/fixtures/**` (add fixtures; keep existing ones and their cache keys
stable), `backend/src/ave/domain/sync_layout.py`, new `backend/src/ave/domain/coverage.py`,
`backend/tests/sync/**` (new), `backend/tests/unit/test_sync_*.py`, `backend/tests/media/test_sync_*.py`,
`backend/tests/media/derived.py` (add variants only).

## Forbidden paths
`backend/src/ave/domain/model.py`, `backend/src/ave/domain/operations.py`, `backend/src/ave/domain/service.py`,
`backend/src/ave/storage/**`, `backend/src/ave/services/**`, `backend/src/ave/config.py` (the concurrent M1 core
task owns them; report the exact model change you need, for example fields of `SyncGroup`/`SyncMember`);
`backend/src/ave/render/**` (report needed changes); `backend/pyproject.toml`, `backend/uv.lock` (numpy and
scipy suffice; report any other dependency); `docs/**`, `scripts/**`, `.github/**`, `.claude/**`, `CLAUDE.md`,
`ai-video-editor-requirements/**`.

## Dependencies and constraints
- Read `ave.sync.audio` (chance-probability and rival-alignment gates, timestamp-placed float32 analysis audio),
  `ave.media.audio_timing`, `ave.media.probe`, `ave.domain.model`, `ave.domain.sync_layout`, `ave.timebase` and
  `tests/unit/test_sync_populations.py` first; extend them, never duplicate them.
- Insufficient or ambiguous evidence is reported with what is missing and the alternatives; a confident wrong
  mapping is the one unacceptable outcome. Every new estimator gets a seeded population test (marker `slow`) that
  counts wrong results (must be 0) and states a sensitivity floor measured on genuine positives.
- Fixtures: AT-06 silent-B pair with shared flashes; a manual-anchor case without shared events; AT-07 unrelated
  and periodic pairs; AT-08 180-second pair with `T_ref = 2 + 1.001 * t_B` (small frames, e.g. 320x320, to keep
  generation fast) and a non-linear negative case. Ground truth comes from the generator's parameters, never from
  an estimator.
- AT-08 must render a low-resolution verification output of a split segment with the estimated mapping and
  measure early, middle and late events on the decoded output (within one output frame), including pitch
  continuity when audio is time-scaled.
- Tag every criterion test with `@pytest.mark.req("AVE-REQ-NNN AC-n", ...)` and scenario tests with
  `@pytest.mark.scenario("AT-NN")`; long fixtures under `media`, populations under `slow`.
- One heavy media job at a time.

## Test commands
- `./scripts/verify.sh --tier media` must pass.
- `python3 scripts/evidence.py show AVE-REQ-023 AVE-REQ-024 AVE-REQ-025 AVE-REQ-026 AVE-REQ-027 AVE-REQ-028
  AVE-REQ-030`: report per-criterion states in the handback, with the population outcome counts.

## Handback schema
`## Result: COMPLETE | PARTIAL | BLOCKED`, then: branch and commit hash; per requirement and AC: status, tests
(node IDs) and what they prove; population outcome counts (wrong / correct / ambiguous / insufficient); commands
with results; needed changes in forbidden paths (exact); decisions taken (proposed ASSUMPTIONS entries);
deviations and follow-ups; documentation updates for the lead.
