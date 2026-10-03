---
id: AVE-REQ-104
title: Robust audio placement for timestamp jitter of 5 ms or more
type: functional
status: proposed
priority: could
parent: AVE-FEAT-002
source: derived
scope: v1
primary_gate: M2
origins: []
dependencies: [AVE-REQ-012, AVE-REQ-024]
scenarios: []
---

# AVE-REQ-104 — Robust audio placement for timestamp jitter of 5 ms or more

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md):
decoded audio keeps its samples contiguous and lands at the same timeline time in the synchronization analysis
and in every render ([AVE-REQ-012](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md) AC-4).
Found by the follow-up review of the M0 media core (2026-10-03): deviations are measured from the first decoded
packet, so a source whose packet timestamps jitter by 5 ms or more each way (a peak-to-peak spread of 10 ms or
more) gets silence inserted and samples dropped at about every other packet, at different packets in the analysis
extraction and in each render ([ASM-008](../ASSUMPTIONS.md)).

## Description
Audio placement anchors on a fitted reference computed from the packet timestamps around the decode start (a
robust fit of timestamp against sample position) in place of the first decoded packet alone. The analysis
extraction and every render of the same source share that reference, so jitter below a configurable spread
stays contiguous while real gaps and overlaps keep being corrected.

## Acceptance criteria
- [ ] AC-1 A source whose packet timestamps jitter with a peak-to-peak spread of 10 ms or more around a contiguous stream (Matroska/PCM and MPEG-TS/AAC fixtures) decodes with no inserted silence and no dropped sample in the analysis extraction and in renders seeking to several points.
- [ ] AC-2 The analysis extraction and every render place the same source sample at the same timeline time within one output frame.
- [ ] AC-3 Real timestamp gaps and overlaps of 10 ms or more between contiguous runs stay corrected (filled with silence or dropped in full), as AVE-REQ-012 AC-4 requires.

## Edge cases
_TBD: settled before work starts._

## Dependencies
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)
- [AVE-REQ-024 — Audio-based offset estimation](AVE-REQ-024-audio-based-offset-estimation.md)

## Verification strategy
- AC-1, AC-2 — integration (media) — jittered fixtures with amplitudes of 5 ms and 7 ms in both containers, decoded analysis audio and rendered exports measured against the chirp oracle.
- AC-3 — integration (media) — the gap fixtures of AVE-REQ-012 AC-4 rerun on the new placement.
- Acceptance scenarios: None.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-03 — proposed — discovered during AVE-REQ-012 (follow-up review round 1, item 5): AAC in MPEG-TS alternating ±5 ms gives 701 silence runs in the analysis extraction and 141 in every 6 s render (lead)
