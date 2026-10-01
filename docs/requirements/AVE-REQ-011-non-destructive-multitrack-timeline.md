---
id: AVE-REQ-011
title: Non-destructive multitrack timeline
type: functional
status: ready
priority: must
parent: AVE-FEAT-002
source: human
scope: v1
primary_gate: M2
origins: [U02, U20]
dependencies: [AVE-REQ-001, AVE-REQ-003]
scenarios: [AT-02, AT-11]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-011.md
---

# AVE-REQ-011 — Non-destructive multitrack timeline

## Intent
Serves [GOAL-002](../PRODUCT.md#product-goals) through [AVE-FEAT-002 — Manual timeline and history](AVE-FEAT-002-manual-timeline-and-history.md). Origin clauses in the user brief:
- [U02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u02) — Support simultaneous video and separate audio tracks, a selected source audio track, user-defined aspect ratios, and two square views inside a default 16:9 output.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-011](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-011.md) (package v1.0); primary gate M2, scope v1.

## Description
The editor shall provide multiple simultaneous video, audio, image, and text tracks with non-destructive clip instances.

## Acceptance criteria
- [ ] AC-1 A project can contain at least four simultaneous video tracks, four audio tracks, and independent overlay tracks; this is a baseline test, not an artificial product limit.
- [ ] AC-2 Each clip instance has independent source in/out, timeline position, track, transform, and relevant audio or effect settings.
- [ ] AC-3 Layer order, track visibility, mute, solo, and lock have defined, consistent effects in preview and export.
- [ ] AC-4 Using the same asset twice creates independent clip instances rather than altering the source or the other instance.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-003 — Immutable originals and stable asset identities](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-011 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-02](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-02), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
