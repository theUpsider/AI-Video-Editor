# ADR-004 — Exact rational time and one typed, versioned composition document

## Status
Accepted — 2026-10-01

## Context
Synchronization, cuts, overlays, audio, captions, sections and shorts must share explicit time mappings;
60 and 60000/1001 stay distinct; intervals are half-open; variable-rate sources use presentation timestamps
([DATA_AND_TIMING_MODEL.md](../../ai-video-editor-requirements/spec/DATA_AND_TIMING_MODEL.md)). UI, AI and MCP
edit the same composition through validated, atomic, undoable operations (AVE-REQ-048, AVE-REQ-015/016).

## Decision
1. **Time values** are exact rationals (`fractions.Fraction`), serialized as `{"num", "den"}` with a positive,
   reduced denominator. Floats enter only through explicit conversion with a declared resolution (estimated
   synchronization parameters). Intervals are half-open `[start, end)` and reject empty or negative spans.
2. **Time domains** are explicit: source time (presentation timestamps, normalized by the stream start),
   synchronization reference time, project time, section/short time and encoded output time. Functions name
   their domain in parameters and types.
3. **Output grid:** output frame `n` presents time `n / fps` and covers `[n/fps, (n+1)/fps)`; content with
   interval `[s, e)` is present on frames `ceil(s*fps) … ceil(e*fps) - 1`. Audio sample `k` presents `k / rate`.
   Quantization happens once, at render planning.
4. **Clip mapping:** a clip maps project time `T` in `[timeline_start, timeline_start + d)` to source time
   `t = source_in + (T - timeline_start) * source_speed`; `d = (source_out - source_in) / source_speed`.
   `source_speed = 1 / b_i` applies clock-drift correction; an editorial speed change is a separate field.
5. **Synchronization convention:** `T_reference = a_i + b_i * t_source_i`; the reference source has `a=0, b=1`.
   Sync groups store `a`, `b`, method, anchors, residuals, confidence and whether a user supplied them.
6. **Composition document:** a Pydantic-typed document (sequences, tracks, clips, layout regions/fit, sync
   groups, overlays, sections, looks, subtitle tracks, derived shorts). Each committed transaction stores a full
   immutable revision snapshot plus its operation list, actor, idempotency key and diff. Undo/redo is linear over
   the project's transaction history and creates new revisions.
7. **Layout** is per-clip: a normalized canvas region (exact fractions) plus fit `contain | cover` and a focus
   point; a silent stretch is never a default. Split-screen is two clips with left/right regions.

## Alternatives considered
- Floating-point seconds — rejected: accumulates error and conflates 60 with 60000/1001.
- Integer ticks at one global timebase — viable, but rationals keep every source and output rate exact without
  choosing a least common multiple; ticks remain an option for hot paths.
- Event-sourced state rebuilt from operations only — rejected for version one: snapshots make reads, exports
  pinned to a revision and crash recovery simpler; the operation log is still kept.
- A dedicated LayoutSegment entity — replaced by per-clip regions plus a `layout.apply` operation that sets them
  for a time range, which keeps one representation for manual and AI edits.

## Consequences
- Every consumer (renderer, preview, captions, exports, AI context) reads the same mapping functions.
- Revision snapshots grow with timeline size; a 300-item timeline stays well under a megabyte per revision.
  Compaction can be added when measured.
- Tests compute expected output frames and samples independently of the renderer.

## Related requirements
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](../requirements/AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](../requirements/AVE-REQ-015-undo-redo-autosave-and-revisions.md)
- [AVE-REQ-026 — Persistent synchronization transforms](../requirements/AVE-REQ-026-persistent-synchronization-transforms.md)
- [AVE-REQ-048 — One typed editing command service](../requirements/AVE-REQ-048-one-typed-editing-command-service.md)
