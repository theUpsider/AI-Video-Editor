---
id: AVE-REQ-041
title: Reusable project, camera, and clip color profiles
type: functional
status: ready
priority: must
parent: AVE-FEAT-008
source: human
scope: v1
primary_gate: M3
origins: [U21]
dependencies: [AVE-REQ-040]
scenarios: [AT-10, AT-22]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-041.md
---

# AVE-REQ-041 — Reusable project, camera, and clip color profiles

## Intent
Serves [GOAL-004](../PRODUCT.md#product-goals) through [AVE-FEAT-008 — Color and reusable looks](AVE-FEAT-008-color-and-reusable-looks.md). Origin clauses in the user brief:
- [U21](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u21) — Offer color grading, shadows/highlights/contrast and related controls, with reusable looks applied across a trip/project.

Imported from the immutable baseline [AVE-REQ-041](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-041.md) (package v1.0); primary gate M3, scope v1.

## Description
Users shall save reusable color profiles and apply them project-wide, by camera/perspective, or to individual clips.

## Acceptance criteria
- [ ] AC-1 A project profile affects all applicable current clips and newly imported clips according to an explicit inheritance rule.
- [ ] AC-2 Camera-level and clip-level overrides have visible precedence and never accidentally apply the same input transform twice.
- [ ] AC-3 Profiles can be named, duplicated, imported, exported, previewed, and reset without altering originals.
- [ ] AC-4 A linked preset update has a documented effect; users can detach or freeze an individual clip look.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-040 — Non-destructive color and tonal controls](AVE-REQ-040-non-destructive-color-and-tonal-controls.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-041 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-10](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-10), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
