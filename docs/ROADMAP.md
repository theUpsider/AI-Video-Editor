# Roadmap

Hierarchy: **Phase → Milestone → Feature → Requirement.** A phase (`## Phase <n> — Name`)
groups milestones; a milestone (`### M<n> — Name`) delivers features (`AVE-FEAT-NNN`); features
decompose into requirements (`AVE-REQ-NNN`) in `docs/requirements/`
([format](requirements/README.md)). Milestone IDs `M1`, `M2`, … run sequentially across
phases and are never reused.

When working, read only the current milestone entry; [PROGRESS.md](PROGRESS.md)
§ Current milestone names it.

## Rules

1. The roadmap is derived from requirements: every listed feature and requirement exists as a
   file in `docs/requirements/`.
2. Dependencies determine ordering, between requirements and between milestones.
3. Establish working vertical slices early.
4. Avoid implementing all infrastructure before user-visible functionality: build
   infrastructure in the milestone whose features need it.
5. Keep milestones independently verifiable through their exit criteria.
6. Re-plan when discoveries invalidate assumptions; log each change in § Re-planning log.
7. Do not treat the roadmap as immutable. Update it whenever requirements, assumptions or
   evidence change.

## Planning rules

1. **M1 is a walking skeleton.** The first product milestone is the thinnest vertical slice
   of one core user journey (`UJ-NNN`) running end to end through every architectural layer,
   built and checked by verify.sh and CI with real checks. `technical-foundation` scaffolds
   the skeleton; `develop` completes M1.
2. **Refine just in time.** The initial plan details M1 fully and sketches later milestones
   with an outcome, features and `proposed` requirements. Requirements reach `ready` before
   work on them starts; `milestone-review` refines the next milestone when the current one
   ends.
3. **One active milestone.** Exactly one milestone is `in-progress`; `develop` selects
   requirements from it first.
4. **Milestone done.** A milestone is `done` when every non-superseded requirement in it is
   `done`, its exit criteria hold, and `milestone-review`
   ([SKILL.md](../.claude/skills/milestone-review/SKILL.md)) recorded a PASS in its Review
   line.
5. **Size.** Each milestone is small enough to finish and review as one unit and ends in a
   demonstrable user-visible outcome.
6. **Log every move.** Adding, splitting, reordering or rescoping milestones, and moving
   requirements between them, each get a Re-planning log row.

## Milestone entry template

Copy under the owning phase heading. In real entries, link each ID to its file.

```
### M<n> — Name
- **Status:** planned | in-progress | done
- **Outcome:** <what a user can do when the milestone is done>
- **Exit criteria:**
  - <verifiable condition, e.g. "UJ-NNN steps 1–3 pass end to end in ./scripts/verify.sh">
- **Features:** AVE-FEAT-NNN, AVE-FEAT-NNN
- **Requirements (dependency order):** AVE-REQ-NNN, AVE-REQ-NNN, AVE-REQ-NNN
- **Depends on:** M<n> | none
- **Review:** pending | YYYY-MM-DD — PASS | FAIL — follow-ups: <REQ/ASM/ADR IDs or none>
```

## Phase 0 — Development environment bootstrap

- **Status:** done — 2026-10-01
- **Outcome:** repository ready for specification-driven development: canonical documents,
  requirement and ADR formats, subagents, skills, hooks, `./scripts/verify.sh`, CI.
- **Decisions:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)
- **Verification:** `./scripts/verify.sh` PASS on 2026-10-01 (bootstrap checks only).
- **Follow-ups:** confirm ASM-001 to ASM-003 in [ASSUMPTIONS.md](ASSUMPTIONS.md).

## Phase 1 — Product definition

- **Status:** done — 2026-10-01
- **Outcome:** a specification complete enough to guide development: PRODUCT.md populated;
  epics, features and requirements with acceptance criteria; assumptions; architectural
  drivers; product phases and milestones in this file.
- **Procedure:** `product-definition`
  ([SKILL.md](../.claude/skills/product-definition/SKILL.md)), then `technical-foundation`
  ([SKILL.md](../.claude/skills/technical-foundation/SKILL.md)) before M1 starts.

- **Result:** the human supplied a complete specification package; it is the immutable baseline
  ([input](product-inputs/2026-10-01-ai-video-editor-v1.md), [PRODUCT.md](PRODUCT.md),
  [import mapping](requirements/IMPORT_MAPPING.md)). Technical foundation: ADR-002 to ADR-008.

## Phase 2 — Version-one product delivery

Milestones follow the baseline's risk-first [ROADMAP](../ai-video-editor-requirements/spec/ROADMAP.md): each
requirement's `primary_gate` is where its full acceptance is expected; prerequisite subsets are built earlier when
the dependency graph requires them. A milestone is never a reduction of the version-one scope (99 requirements).

### M0 — Adopt the contract and prove the environment
- **Status:** in-progress
- **Outcome:** Environment capabilities and gaps are recorded; the package is integrated with an import mapping, working traceability, assumptions and ADRs; a real CPU split/full/split render and a known-offset sync experiment have measurable decoded evidence (AT-02, AT-04 core).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-019](requirements/AVE-FEAT-019-autonomous-implementation-workflow.md)
- **Requirements (dependency order):** [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md), [AVE-REQ-094](requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md), [AVE-REQ-096](requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md), [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md), [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)
- **Depends on:** none
- **Review:** pending

### M1 — Thin real product path
- **Status:** planned
- **Outcome:** A fresh user can import fixtures, view a mixed-layout composition, export a real file, reopen the saved project, and verify original checksums (UJ-001; AT-01, AT-02).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-001](requirements/AVE-FEAT-001-projects-and-media-collection.md), [AVE-FEAT-002](requirements/AVE-FEAT-002-manual-timeline-and-history.md), [AVE-FEAT-003](requirements/AVE-FEAT-003-canvas-and-mixed-layouts.md), [AVE-FEAT-005](requirements/AVE-FEAT-005-audio-routing-and-mixing.md), [AVE-FEAT-010](requirements/AVE-FEAT-010-typed-editing-api-and-mcp.md), [AVE-FEAT-017](requirements/AVE-FEAT-017-rendering-and-output-delivery.md), [AVE-FEAT-018](requirements/AVE-FEAT-018-runtime-quality-and-handover.md)
- **Requirements (dependency order):** [AVE-REQ-001](requirements/AVE-REQ-001-persistent-projects-and-project-settings.md), [AVE-REQ-002](requirements/AVE-REQ-002-collection-based-batch-ingestion.md), [AVE-REQ-003](requirements/AVE-REQ-003-immutable-originals-and-stable-asset-identities.md), [AVE-REQ-004](requirements/AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md), [AVE-REQ-007](requirements/AVE-REQ-007-proxies-thumbnails-and-waveforms.md), [AVE-REQ-009](requirements/AVE-REQ-009-broken-media-and-relinking.md), [AVE-REQ-012](requirements/AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md), [AVE-REQ-018](requirements/AVE-REQ-018-configurable-canvas-dimensions-and-output-rate.md), [AVE-REQ-020](requirements/AVE-REQ-020-two-perspective-split-screen-layout.md), [AVE-REQ-031](requirements/AVE-REQ-031-explicit-master-audio-and-routing.md), [AVE-REQ-048](requirements/AVE-REQ-048-one-typed-editing-command-service.md), [AVE-REQ-072](requirements/AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md), [AVE-REQ-082](requirements/AVE-REQ-082-self-hostable-browser-application-and-cpu-reference-setup.md), [AVE-REQ-075](requirements/AVE-REQ-075-cpu-only-reference-rendering.md), [AVE-REQ-077](requirements/AVE-REQ-077-durable-asynchronous-jobs.md)
- **Depends on:** M0
- **Proposed during M0 reviews:** [AVE-REQ-103](requirements/AVE-REQ-103-clear-probe-error-for-video-without-presentation-timestamps.md) (video without presentation timestamps), to refine with the M1 ingestion work.
- **Review:** pending

### M2 — Manual editing, synchronization and sound
- **Status:** planned
- **Outcome:** Split/full/split footage stays aligned through manual edits; drift and silent-source fallbacks are honest; output events and audio are measured (AT-04–AT-08, AT-11, AT-28).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-002](requirements/AVE-FEAT-002-manual-timeline-and-history.md), [AVE-FEAT-003](requirements/AVE-FEAT-003-canvas-and-mixed-layouts.md), [AVE-FEAT-004](requirements/AVE-FEAT-004-multicamera-synchronization.md), [AVE-FEAT-005](requirements/AVE-FEAT-005-audio-routing-and-mixing.md)
- **Requirements (dependency order):** [AVE-REQ-011](requirements/AVE-REQ-011-non-destructive-multitrack-timeline.md), [AVE-REQ-013](requirements/AVE-REQ-013-manual-editing-and-precision-controls.md), [AVE-REQ-014](requirements/AVE-REQ-014-basic-transitions-and-handles.md), [AVE-REQ-015](requirements/AVE-REQ-015-undo-redo-autosave-and-revisions.md), [AVE-REQ-017](requirements/AVE-REQ-017-usable-synchronized-preview.md), [AVE-REQ-019](requirements/AVE-REQ-019-aspect-preserving-composition-and-transforms.md), [AVE-REQ-021](requirements/AVE-REQ-021-mixed-split-screen-and-full-width-segments.md), [AVE-REQ-023](requirements/AVE-REQ-023-synchronization-candidate-matching.md), [AVE-REQ-024](requirements/AVE-REQ-024-audio-based-offset-estimation.md), [AVE-REQ-025](requirements/AVE-REQ-025-silent-or-weak-evidence-synchronization.md), [AVE-REQ-026](requirements/AVE-REQ-026-persistent-synchronization-transforms.md), [AVE-REQ-027](requirements/AVE-REQ-027-unequal-coverage-and-missing-perspective-policy.md), [AVE-REQ-028](requirements/AVE-REQ-028-clock-drift-detection-and-correction.md), [AVE-REQ-029](requirements/AVE-REQ-029-linked-edits-preserve-synchronization.md), [AVE-REQ-030](requirements/AVE-REQ-030-manual-synchronization-tools.md), [AVE-REQ-032](requirements/AVE-REQ-032-independent-audio-tracks-and-basic-mixing.md)
- **Depends on:** M1
- **Proposed during M0 reviews:** [AVE-REQ-102](requirements/AVE-REQ-102-seek-safe-decoding-of-gradual-refresh-sources.md) (gradual-refresh sources) and [AVE-REQ-104](requirements/AVE-REQ-104-robust-audio-placement-for-timestamp-jitter.md) (audio placement under timestamp jitter of 5 ms or more), to settle and schedule with the M2 synchronization work.
- **Review:** pending

### M3 — Titles, sections and consistent looks
- **Status:** planned
- **Outcome:** A manually edited multi-section trip has correctly timed titles, preserved aspect ratios, consistent grades and reference-preview/export parity for these features (AT-09, AT-10, AT-26).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-001](requirements/AVE-FEAT-001-projects-and-media-collection.md), [AVE-FEAT-006](requirements/AVE-FEAT-006-overlays-and-titles.md), [AVE-FEAT-007](requirements/AVE-FEAT-007-sections-and-chapters.md), [AVE-FEAT-008](requirements/AVE-FEAT-008-color-and-reusable-looks.md)
- **Requirements (dependency order):** [AVE-REQ-005](requirements/AVE-REQ-005-capture-date-timezone-and-location-metadata.md), [AVE-REQ-006](requirements/AVE-REQ-006-library-organization-and-filtering.md), [AVE-REQ-034](requirements/AVE-REQ-034-timed-text-and-image-overlays.md), [AVE-REQ-038](requirements/AVE-REQ-038-editable-date-and-location-sections.md), [AVE-REQ-035](requirements/AVE-REQ-035-contextual-opening-titles-and-end-references.md), [AVE-REQ-036](requirements/AVE-REQ-036-readable-international-text-and-safe-areas.md), [AVE-REQ-037](requirements/AVE-REQ-037-basic-overlay-animation-without-tracking.md), [AVE-REQ-040](requirements/AVE-REQ-040-non-destructive-color-and-tonal-controls.md), [AVE-REQ-041](requirements/AVE-REQ-041-reusable-project-camera-and-clip-color-profiles.md), [AVE-REQ-042](requirements/AVE-REQ-042-input-color-interpretation-and-sdr-normalization.md)
- **Depends on:** M2
- **Review:** pending

### M4 — Source intelligence and captions
- **Status:** planned
- **Outcome:** Test speech is transcribed by a real local model; original/translated cue tracks stay distinct; captions survive edits and section boundaries; missing visual capability is reported (AT-13, AT-15, AT-19 indexing).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-001](requirements/AVE-FEAT-001-projects-and-media-collection.md), [AVE-FEAT-011](requirements/AVE-FEAT-011-providers-and-downloadable-models.md), [AVE-FEAT-013](requirements/AVE-FEAT-013-speech-translation-and-captions.md), [AVE-FEAT-014](requirements/AVE-FEAT-014-visual-indexing-and-understanding.md)
- **Requirements (dependency order):** [AVE-REQ-008](requirements/AVE-REQ-008-reviewable-accidental-recording-detection.md), [AVE-REQ-053](requirements/AVE-REQ-053-hugging-face-model-registry-and-downloads.md), [AVE-REQ-057](requirements/AVE-REQ-057-speech-extraction-and-local-transcription.md), [AVE-REQ-058](requirements/AVE-REQ-058-editable-searchable-source-transcripts.md), [AVE-REQ-059](requirements/AVE-REQ-059-language-detection-and-source-language-control.md), [AVE-REQ-060](requirements/AVE-REQ-060-translated-subtitle-language-tracks.md), [AVE-REQ-064](requirements/AVE-REQ-064-caption-formatting-and-manual-cue-editor.md), [AVE-REQ-061](requirements/AVE-REQ-061-toggleable-single-and-dual-language-captions.md), [AVE-REQ-062](requirements/AVE-REQ-062-subtitle-retiming-through-edits-and-synchronization.md), [AVE-REQ-065](requirements/AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md), [AVE-REQ-066](requirements/AVE-REQ-066-optional-local-or-remote-visual-caption-adapter.md)
- **Depends on:** M3
- **Review:** pending

### M5 — AI edits and standardized integrations
- **Status:** planned
- **Outcome:** A configured planning provider creates an editable playable draft and revises a scoped section; contract tests cover every adapter; live tests are recorded where dependencies permit and missing credentials are explicit gaps (AT-12, AT-14, AT-16, AT-24).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-002](requirements/AVE-FEAT-002-manual-timeline-and-history.md), [AVE-FEAT-009](requirements/AVE-FEAT-009-ai-draft-and-conversational-editing.md), [AVE-FEAT-010](requirements/AVE-FEAT-010-typed-editing-api-and-mcp.md), [AVE-FEAT-011](requirements/AVE-FEAT-011-providers-and-downloadable-models.md), [AVE-FEAT-012](requirements/AVE-FEAT-012-ai-trust-and-tool-authorization.md), [AVE-FEAT-018](requirements/AVE-FEAT-018-runtime-quality-and-handover.md)
- **Requirements (dependency order):** [AVE-REQ-016](requirements/AVE-REQ-016-concurrent-user-and-ai-edit-safety.md), [AVE-REQ-050](requirements/AVE-REQ-050-provider-neutral-language-model-adapters.md), [AVE-REQ-044](requirements/AVE-REQ-044-natural-language-editing-interface.md), [AVE-REQ-047](requirements/AVE-REQ-047-grounded-editorial-reasoning.md), [AVE-REQ-045](requirements/AVE-REQ-045-end-to-end-ai-first-draft.md), [AVE-REQ-046](requirements/AVE-REQ-046-reviewable-and-atomic-ai-edit-proposals.md), [AVE-REQ-087](requirements/AVE-REQ-087-private-by-default-media-and-secrets-handling.md), [AVE-REQ-056](requirements/AVE-REQ-056-tool-authorization-and-credential-boundaries.md), [AVE-REQ-049](requirements/AVE-REQ-049-mcp-editing-interface-and-external-agent-clients.md), [AVE-REQ-051](requirements/AVE-REQ-051-claude-agent-runtime-adapter.md), [AVE-REQ-052](requirements/AVE-REQ-052-codex-runtime-adapter.md), [AVE-REQ-054](requirements/AVE-REQ-054-ai-budgets-retries-caching-and-cancellation.md), [AVE-REQ-055](requirements/AVE-REQ-055-untrusted-media-and-prompt-injection-boundary.md)
- **Depends on:** M4
- **Review:** pending

### M6 — Shorts and delivery choices
- **Status:** planned
- **Outcome:** Main, section and short outputs contain the correct imagery, timing, sound, looks, captions and metadata; CPU works independently; hardware paths are reported separately (AT-18, AT-19, AT-25).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-007](requirements/AVE-FEAT-007-sections-and-chapters.md), [AVE-FEAT-013](requirements/AVE-FEAT-013-speech-translation-and-captions.md), [AVE-FEAT-015](requirements/AVE-FEAT-015-shorts.md), [AVE-FEAT-016](requirements/AVE-FEAT-016-publication-metadata.md), [AVE-FEAT-017](requirements/AVE-FEAT-017-rendering-and-output-delivery.md)
- **Requirements (dependency order):** [AVE-REQ-063](requirements/AVE-REQ-063-subtitle-sidecars-and-supported-embedded-tracks.md), [AVE-REQ-039](requirements/AVE-REQ-039-section-and-whole-project-export.md), [AVE-REQ-068](requirements/AVE-REQ-068-grounded-short-form-highlight-suggestions.md), [AVE-REQ-069](requirements/AVE-REQ-069-independent-short-sequences-and-reframing.md), [AVE-REQ-070](requirements/AVE-REQ-070-short-preview-and-batch-delivery.md), [AVE-REQ-071](requirements/AVE-REQ-071-copyable-seo-and-publication-suggestions.md), [AVE-REQ-073](requirements/AVE-REQ-073-multiple-containers-and-codec-choices.md), [AVE-REQ-074](requirements/AVE-REQ-074-mixed-rate-input-and-controlled-output-timing.md), [AVE-REQ-076](requirements/AVE-REQ-076-capability-tested-hardware-acceleration.md), [AVE-REQ-079](requirements/AVE-REQ-079-editable-output-presets-and-quality-guidance.md), [AVE-REQ-081](requirements/AVE-REQ-081-complete-output-delivery-bundle.md)
- **Depends on:** M5
- **Review:** pending

### M7 — Whole-product hardening and handover
- **Status:** planned
- **Outcome:** All applicable acceptance scenarios run; criterion-level evidence supports every claimed feature; the handover lists implemented-but-unverified integrations and unmet criteria (AT-17, AT-20–AT-23, AT-27, AT-29–AT-31).
- **Exit criteria:**
  - every non-superseded requirement below is `done` with current-tree evidence;
  - `./scripts/verify.sh` passes, including the media tier;
  - `milestone-review` records PASS.
- **Features:** [AVE-FEAT-001](requirements/AVE-FEAT-001-projects-and-media-collection.md), [AVE-FEAT-003](requirements/AVE-FEAT-003-canvas-and-mixed-layouts.md), [AVE-FEAT-005](requirements/AVE-FEAT-005-audio-routing-and-mixing.md), [AVE-FEAT-008](requirements/AVE-FEAT-008-color-and-reusable-looks.md), [AVE-FEAT-017](requirements/AVE-FEAT-017-rendering-and-output-delivery.md), [AVE-FEAT-018](requirements/AVE-FEAT-018-runtime-quality-and-handover.md), [AVE-FEAT-019](requirements/AVE-FEAT-019-autonomous-implementation-workflow.md)
- **Requirements (dependency order):** [AVE-REQ-010](requirements/AVE-REQ-010-portable-project-backups.md), [AVE-REQ-022](requirements/AVE-REQ-022-preview-and-export-composition-parity.md), [AVE-REQ-033](requirements/AVE-REQ-033-rendered-audiovisual-synchronization-verification.md), [AVE-REQ-043](requirements/AVE-REQ-043-color-consistency-across-outputs.md), [AVE-REQ-078](requirements/AVE-REQ-078-export-preflight-and-decoded-output-validation.md), [AVE-REQ-080](requirements/AVE-REQ-080-storage-quotas-and-safe-derived-file-cleanup.md), [AVE-REQ-083](requirements/AVE-REQ-083-real-media-automated-verification-suite.md), [AVE-REQ-084](requirements/AVE-REQ-084-measured-responsiveness-and-bounded-memory.md), [AVE-REQ-085](requirements/AVE-REQ-085-observable-jobs-and-reproducible-diagnostics.md), [AVE-REQ-086](requirements/AVE-REQ-086-safe-media-processing-boundary.md), [AVE-REQ-088](requirements/AVE-REQ-088-pinned-dependencies-and-license-inventory.md), [AVE-REQ-089](requirements/AVE-REQ-089-accessible-discoverable-editing-interface.md), [AVE-REQ-090](requirements/AVE-REQ-090-crash-recovery-and-safe-migrations.md), [AVE-REQ-091](requirements/AVE-REQ-091-offline-editing-and-graceful-ai-degradation.md), [AVE-REQ-092](requirements/AVE-REQ-092-user-and-developer-handover.md), [AVE-REQ-095](requirements/AVE-REQ-095-evidence-driven-workflow-self-improvement.md), [AVE-REQ-099](requirements/AVE-REQ-099-honest-completion-and-conditional-verification.md), [AVE-REQ-100](requirements/AVE-REQ-100-milestone-level-product-validation.md)
- **Depends on:** M6
- **Review:** pending

### Deferred — future scope (no version-one milestone)
- **Status:** deferred by the user; never a version-one prerequisite (AT-31).
- **Version-one checks:** their acceptance criteria constrain version one (AVE-REQ-067 AC-1–AC-3: extensible analysis
  schemas, no large-model prerequisite, honest labeling; AVE-REQ-101 AC-1–AC-3: static crop and manual keyframes
  without tracking). Deferred requirements never reach `done`, so M7 checks these criteria through
  [AVE-REQ-100](requirements/AVE-REQ-100-milestone-level-product-validation.md) AC-4 and scenario AT-31, and the
  final `milestone-review` records the result.
- **Requirements:** [AVE-REQ-067](requirements/AVE-REQ-067-advanced-continuous-video-understanding.md), [AVE-REQ-101](requirements/AVE-REQ-101-object-and-motion-tracking.md)

## Re-planning log

Newest last. One row per change to milestones, their order or their scope.

| Date | Change | Reason |
|---|---|---|
| 2026-10-01 | Initial product roadmap M0–M7 plus the deferred group, from the baseline gates | product-definition from the supplied baseline package |
| 2026-10-03 | AVE-REQ-103 proposed into M1 (clear probe error for video without presentation timestamps) | round-3 review of the M0 media core: a raw H.264 elementary stream probes as a valid asset and renders background at every cut |
| 2026-10-03 | AVE-REQ-104 proposed into M2 (robust audio placement for timestamp jitter of 5 ms or more) | follow-up review: sources with a timestamp spread of 10 ms or more get dropouts at different packets in analysis and renders |
