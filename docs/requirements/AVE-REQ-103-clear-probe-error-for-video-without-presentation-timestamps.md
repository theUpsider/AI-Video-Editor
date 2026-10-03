---
id: AVE-REQ-103
title: Clear probe error for video without presentation timestamps
type: functional
status: proposed
priority: should
parent: AVE-FEAT-001
source: derived
scope: v1
primary_gate: M1
origins: []
dependencies: [AVE-REQ-004, AVE-REQ-009, AVE-REQ-012]
scenarios: []
---

# AVE-REQ-103 — Clear probe error for video without presentation timestamps

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md):
a source whose frames cannot be placed in time is reported when it is added. Found by the round-3 review of the
M0 media core (2026-10-02): a raw H.264 elementary stream (format `h264`, no packet carries a presentation
timestamp) is accepted by `describe_asset` and renders only background at every cut while the render reports
success.

## Description
Probing recognizes a video stream whose packets carry no presentation timestamp (raw H.264 or HEVC elementary
streams and similar formats). Describing such a file fails with a structured probe error that names the file and
the stream and suggests remuxing into a container with timestamps (MP4, Matroska, MPEG-TS); no asset record is
created. A render never publishes an export whose placed video clip decoded to no frame.

## Acceptance criteria
- [ ] AC-1 Probing a raw H.264 elementary stream raises a structured probe error naming the file, the stream index and the missing presentation timestamps; no asset is registered.
- [ ] AC-2 Video streams whose packets carry timestamps (MP4, Matroska, MPEG-TS, intra-only MPEG-TS, VFR) probe as before.
- [ ] AC-3 A render in which a placed video clip delivers no decoded frame fails with a structured error naming the clip; nothing is published.

## Edge cases
- An elementary stream with a frame-rate hint supplied by the user — out of scope: version one has no user-supplied timing.
- Audio elementary streams (ADTS AAC, raw PCM) — their timestamps follow from the sample count; outside this requirement.

## Dependencies
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)
- [AVE-REQ-009 — Broken media and relinking](AVE-REQ-009-broken-media-and-relinking.md)
- [AVE-REQ-012 — Canonical rational timing and temporal invariants](AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md)

## Verification strategy
- AC-1, AC-2 — integration (media) — a generated raw H.264 stream and the existing fixture matrix.
- AC-3 — integration (media) — a plan built from a probe record of such a stream.
- Acceptance scenarios: None.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-03 — proposed — discovered during AVE-REQ-012 (round-3 review of the media core, follow-up item 11): a raw H.264 elementary stream probes as a valid asset and renders background at every cut (lead)
