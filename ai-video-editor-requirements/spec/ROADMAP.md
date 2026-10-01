# Risk-first implementation roadmap

## Rule

The full version-one scope remains the target. Milestones are independently runnable slices, not permission to drop later requirements. A requirement's `primary_gate` identifies where its full acceptance is expected; implement prerequisite subsets earlier when the dependency graph requires them. Do not force milestone order against actual dependencies.

## M0 - Adopt the contract and prove the environment

Inspect existing bootstrap and application files. Validate this package. Establish an import mapping, working traceability, capability report, concise assumptions/ADRs, and a dependency-aware task queue. Smoke-test available native dynamic workflows or use the documented fallback. Keep the repository control plane concise.

Before substantial UI/framework investment, create the smallest executable media experiment: probe generated square and 2K/60 sources, compose a split/full/split clip, route one audio source, and validate a real CPU export. Add the known-offset sync fixture and independent expected timing. This spike becomes tested product infrastructure, not disposable fake media proof.

**Gate:** environment capabilities and gaps are recorded; package is integrated; the first real render/sync experiment has measurable evidence. Do not spend the whole session generating more plans.

## M1 - Thin real product path

Build a minimal running UI/backend/worker with project persistence, collection import, probing, typed edits, stable original references, a minimal timeline representation, default canvas, CPU render jobs, and downloadable playable output. Add proxy foundations and deployment commands.

**Gate:** a fresh user can import fixtures, view a mixed-layout composition, export a real file, reopen the saved project, and verify original checksums.

## M2 - Manual editing, synchronization, and sound

Deliver multitrack timeline interactions, trims/splits/transitions, undo/redo, locks, audio routing/mixing, candidate pairing, offset/drift mapping, unequal coverage, manual anchors and linked editing. Bring forward metadata/labels needed for pairing.

**Gate:** split/full/split footage stays aligned through manual edits, drift and silent-source fallbacks are honest, and output events/audio are measured rather than visually guessed.

## M3 - Titles, sections, and consistent looks

Add image/text overlays, opening/ending cards, safe typography, manual keyframes, date/place organization, sections, color controls and reusable project/camera/clip profiles. Confirm color interpretation and unknown-profile handling.

**Gate:** a manually edited multi-section trip has correctly timed titles, preserved aspect ratios, consistent grades, and reference-preview/export parity for these features.

## M4 - Source intelligence and captions

Implement bounded shot/keyframe indexing, accident suggestions with overrides, local speech recognition, editable transcripts, languages, translation capability, retimed captions, and optional bounded visual analysis. Pull forward provider abstractions needed by translation. Keep future continuous understanding/tracking excluded.

**Gate:** test speech is actually transcribed, original/translated cue tracks remain distinct, captions survive edits and section boundaries, and missing visual capability is not hidden by fake descriptions.

## M5 - AI edits and standardized integrations

Deliver the natural-language panel, grounded first-draft workflow, revision-safe proposals, validated operation transactions, MCP server, direct provider adapters, optional Claude Agent and Codex runtime integrations, privacy controls, budgeted jobs and cancellation.

**Gate:** a real configured planning provider creates an editable playable trip draft and successfully revises a scoped section; contract tests cover all adapters and live tests are recorded where dependencies permit. Missing credentials are explicit gaps, not passed tests.

## M6 - Shorts and delivery choices

Add grounded 15-20-second short suggestions, independent short sequences, square/portrait layouts, publication text, full/section/batch exports, SRT/VTT and supported embedded captions, codec/container matrix, quality presets, and capability-tested acceleration.

**Gate:** main, section and short outputs contain the correct imagery, timing, sound, looks, captions, and metadata. CPU works independently; tested hardware paths are reported separately.

## M7 - Whole-product hardening and handover

Run all applicable acceptance scenarios; inspect the complete user-clause matrix. Complete performance/resource limits, safe cleanup, crash/migration recovery, backup/relink, security tests, accessibility, offline behavior, installation, model/codec/license documentation, and an actual running-product walkthrough.

**Gate:** criterion-level evidence supports every claimed completed feature. The handover explicitly lists implemented-but-unverified external integrations and unmet criteria. No known failures are hidden behind an aggregate green status.

## After version one

Keep AVE-REQ-067 and AVE-REQ-101 deferred. Advanced temporal understanding and object/motion tracking may later build on the source-time/analysis interfaces without becoming mandatory dependencies of the current editor.
