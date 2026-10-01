# Data model and temporal contract

## Contents

- Entities
- Time domains and intervals
- Synchronization convention
- Editing and export mapping
- Revision and persistence rules
- Color, captions, and derived assets

## Entities

Treat these as domain responsibilities, not mandatory database table names. Prefer a small typed model over an early microservice design.

| Entity | Minimum responsibility |
| --- | --- |
| Project | Stable ID, name, settings, owner boundary, current revision, output profiles. |
| MediaAsset | Stable ID, immutable checksum, storage reference, original name, probed streams, capture metadata/provenance. |
| DerivedAsset | Proxy, thumbnail, waveform, sampled frame, transcript, or render; source and configuration hashes. |
| Sequence | Timeline, output canvas/rate, tracks, ordered sections, relationship to a parent short/full edit. |
| Track | Type, order, visible/mute/solo/locked state. |
| ClipInstance | Asset reference, selected streams, source in/out, project placement, transform/effects, links. |
| SyncGroup | Member assets/instances, reference source, affine source-to-reference maps, anchors, method/confidence. |
| LayoutSegment | Active layout regions and member clip references over a defined timeline interval. |
| AudioRoute | Selected reference stream or mix, gain/fades, explicit fallback policy. |
| Overlay | Text/image content, timing, region, style, transform and optional manual keyframes. |
| ColorProfile | Technical-input interpretation plus separate creative controls and inheritance/override policy. |
| SourceTranscript | Source-time text, language, words/cues, confidence, corrections and provenance. |
| SubtitleTrack | Language, cue links, edited text/style, mapped project/output intervals, translation lineage. |
| Section | Name, optional date/place labels with provenance, timeline boundaries and anchor policy. |
| EditProposal/Transaction | Base revision, actor, operations, idempotency key, scope, diff, approval/application state. |
| Analysis/RenderJob | Immutable inputs/revision, state, progress, configuration, actual device, diagnostics, outputs. |
| Provider/ModelProfile | Capabilities, version/revision, execution limits, credential reference, allowed data egress. |

## Time domains and intervals

Do not use one unlabeled floating-point `time` field for everything. Distinguish:

1. **Source time:** presentation timestamps in the original stream, normalized with a recorded original offset.
2. **Synchronization reference time:** one group's selected reference/source capture clock.
3. **Project time:** the final edit's timeline, with cuts and inserted segments.
4. **Section/short time:** project intervals remapped into an independent output sequence.
5. **Encoded output time:** muxed stream timestamps, including explicitly handled encoder delay and time bases.

Use exact rational values `{num, den}` or bounded integer ticks. Document conversion, rounding, representable ranges, and overflow handling. Rational frame rate `60000/1001` is not `60`. Output frame `n` starts at `n * fps.den / fps.num` seconds. Audio sample timing is based on the selected sample rate and the same intended real-time mapping.

All intervals are half-open: `[start, end)`. An overlay `[3,6)` is present on frames whose presentation times satisfy `3 <= t < 6`. It is not present on the frame at exactly 6 seconds. Quantization onto an output grid is explicit; never repeatedly round intermediate clip operations.

Inspect VFR source presentation timestamps when exact frame access matters. `frame_number / average_rate` is not a reliable universal source-time lookup.

## Synchronization convention

Define, for each group source `i`:

```text
T_reference = a_i + b_i * t_source_i
```

`a_i` is the offset in reference seconds and `b_i` is the source-to-reference clock scale. The reference source has `a=0, b=1` under its normalized clock. Store the sign convention, contributing anchors, residuals, confidence, and whether a user supplied the mapping.

**Example:** A begins at real reference time 0. B starts 2 seconds later. Then `a_B=2, b_B=1`. To show reference event 10 seconds, read A at 10 seconds and B at 8 seconds. Do not trim A and B using the same source-time number.

If A covers `[0,30)` and B covers source `[0,25)`, B covers reference `[2,27)`. The common overlap is reference `[2,27)`, a duration of 25 seconds. The default split-screen edit uses A source `[2,27)` and B source `[0,25)`. Originals and unused handles remain available.

For an edited segment placed at project time `P0`, beginning at reference time `G0`, without an editorial speed change:

```text
T_reference = G0 + (T_project - P0)
t_source_i = (T_reference - a_i) / b_i
```

An optional editorial speed factor is a separate explicit transform. Clock drift correction is not silently treated as a creative speed ramp. Apply corresponding mappings to audible audio and transcripts; preserve audio pitch when correcting its time scale.

For long clips, estimate alignment at multiple anchors. Detect inconsistency rather than forcing a linear correction onto non-linear timing defects. Arbitrary time-warp editing and optical-flow interpolation are not mandatory first-version features.

## Editing and export mapping

Do not flatten all edits into destructively rewritten intermediates. A timeline references original source intervals. Proxies are derived views with known timing maps. Render plans resolve from the chosen immutable project revision.

For a section `[S,E)` exported independently, output time is `T_out = T_project - S` for visible intervals, after applying any selected boundary transition policy. Intersect overlays and cue ranges with `[S,E)` before rebasing. Split subtitles that cross removed spans; repeated source use yields repeated mapped cues, not edits to the original transcript.

Implement linked operations atomically across grouped clips, audio, subtitles, and section anchors. Decide and document when an overlay follows a clip versus an absolute project time. The user must be able to inspect/change that anchoring mode.

## Revision and persistence rules

- A project mutation validates `expected_revision` and applies atomically.
- An `idempotency_key` returns the original committed result for an equivalent retry; reuse with a different payload fails.
- An export uses one immutable revision and config hash, never a moving current-state reference.
- A UI user and AI writer cannot both commit stale transformations without conflict handling.
- Locked objects are checked in the domain service.
- The command log records ordinary operations; secrets and full raw media content do not belong in it.
- A completed analysis result may be cached without becoming an accepted timeline edit.
- Cancellation and failed jobs cannot publish partial media as successful output.

## Color, captions, and derived assets

Record input color interpretation separately from creative looks. A defined technical normalization occurs once; project/camera/clip creative inheritance follows documented precedence. Derived shorts inherit looks unless explicitly overridden.

Store source transcripts, translated text, subtitle cue timing, UI visibility, and burn-in choices separately. A platform upload sidecar and an embedded subtitle stream are separate export artifacts. Keyword suggestions are not caption tracks.

Hash derived assets using source checksum, operation parameters, engine/model revision, schema version, and language where relevant. Delete caches only through references rooted in application-owned storage. Imported media paths, render destinations, and HF model IDs are validated data, never executable command fragments.
