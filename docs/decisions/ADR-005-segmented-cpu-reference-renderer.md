# ADR-005 — Segmented CPU reference renderer with decoded-output validation

## Status
Accepted — 2026-10-01

## Context
Exports must be real, exact in timing and geometry, CPU-capable, bounded for long trips, cancellable and never
published partially (AVE-REQ-072, 075, 077, 078). The baseline warns against one giant filter graph and against
stream copy at arbitrary cuts.

## Decision
1. A typed compiler turns `(sequence revision, project range, output profile)` into a render plan.
2. **Video** is planned in segments: the range is split at every clip, overlay and transition boundary into
   intervals with a constant layer set, each covering whole output frames. Each segment renders with a small
   FFmpeg filter graph (written to a filter-script file; argv lists only; text through UTF-8 text files) and
   identical encoder settings, starting with a keyframe.
3. **Audio** for the range renders once at 48 kHz with sample-accurate placement, explicit routing and
   `normalize=0` mixing; drift correction uses pitch-preserving time scaling.
4. Segments concatenate by stream copy (same codec parameters), then mux with the encoded audio. Segment outputs
   are cached by a key over input revision, asset hashes and output parameters.
5. Output goes to a temporary path, is decoded and validated (container, codec, dimensions, exact rate,
   duration, streams), and is atomically renamed into the export store only on success.
6. The same compiler renders single reference frames for preview parity (AVE-REQ-022).

## Alternatives considered
- One filter graph per export — rejected for long timelines (unbounded graph, memory, no reuse).
- Lossless intermediates plus a final encode — viable for rate-controlled codecs; kept as an option where
  concat-copy proves unsuitable (measured per codec).
- Browser-side rendering — rejected as the authoritative path; browser preview is approximate.

## Consequences
- Cut points quantize to the output frame grid explicitly and once.
- Concat by stream copy requires identical encoder settings per export; the validator checks the result.
- Transitions render as their own segments containing both clips.

## Related requirements
- [AVE-REQ-072 — Real export pipeline and default delivery profile](../requirements/AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)
- [AVE-REQ-075 — CPU-only reference rendering](../requirements/AVE-REQ-075-cpu-only-reference-rendering.md)
- [AVE-REQ-078 — Export preflight and decoded-output validation](../requirements/AVE-REQ-078-export-preflight-and-decoded-output-validation.md)
