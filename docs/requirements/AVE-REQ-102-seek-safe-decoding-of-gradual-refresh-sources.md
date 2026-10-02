---
id: AVE-REQ-102
title: Seek-safe decoding of gradual-refresh sources
type: functional
status: proposed
priority: should
parent: AVE-FEAT-017
source: derived
scope: v1
primary_gate: M2
origins: []
dependencies: [AVE-REQ-012, AVE-REQ-072]
scenarios: []
---

# AVE-REQ-102 — Seek-safe decoding of gradual-refresh sources

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md):
every cut of a real camera recording shows the frame the timing model selects
([AVE-REQ-012](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md) AC-4). Found by the independent
review of the M0 media core (2026-10-02): sources encoded with gradual decoder refresh (intra refresh, recovery
points marked as keyframes and no IDR frames) show frames after the cut point when a segment starts mid-stream.

## Description
A video stream whose seek points are recovery points rather than instantaneous decoder refreshes needs decoding
to start early enough that the picture is fully refreshed before the first output frame. The renderer detects
such streams at probe time (recovery-point keyframes without IDR frames, or a declared recovery frame count) and
starts decoding at a seek point at least one full refresh period before the first needed frame, or from the
previous IDR frame when one exists.

## Acceptance criteria
- [ ] AC-1 An intra-refresh source (MPEG-TS and MP4) cut at several points shows, on every output frame, the frame the ADR-004 frame rule selects; no output frame shows a later source frame.
- [ ] AC-2 Probing reports whether a video stream relies on gradual refresh, from its own packets and headers, without inventing a value when that cannot be determined.
- [ ] AC-3 Sources with instantaneous refresh keep their current decode cost (no extra decoding before a cut).

## Edge cases
_TBD: settled before work starts._

## Dependencies
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1 — integration — real-media renders of x264 `intra-refresh` encodes in MPEG-TS and MP4, decoded frames
  compared with the frame rule from the fixture manifest.
- AC-2 — unit and integration — probe parsing on synthetic packet tables and on the real encodes.
- AC-3 — integration — decode-cost comparison on an IDR-based source before and after.
- Acceptance scenarios: None.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-02 — proposed — discovered by the round-2 independent review of the media core: an intra-refresh MPEG-TS cut at 2 s showed later frames on 66 of 90 output frames (MP4 at 13 s: 6 of 90) (lead)
