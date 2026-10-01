---
id: AVE-REQ-081
title: Complete output delivery bundle
type: functional
status: ready
priority: must
parent: AVE-FEAT-017
source: human
scope: v1
primary_gate: M6
origins: [U11, U13, U18, U23]
dependencies: [AVE-REQ-039, AVE-REQ-063, AVE-REQ-071, AVE-REQ-072]
scenarios: [AT-18, AT-25, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-081.md
---

# AVE-REQ-081 — Complete output delivery bundle

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-017 — Rendering and output delivery](AVE-FEAT-017-rendering-and-output-delivery.md). Origin clauses in the user brief:
- [U11](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u11) — Provide separately usable caption/metadata outputs for external platforms such as YouTube, rather than forcing permanent captions into every export.
- [U13](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u13) — Generate copyable keywords and related SEO/publication text.
- [U18](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u18) — Organize a multi-day, multi-city trip into editable sections and export any section or the full edit.
- [U23](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u23) — Export different video/container formats, frame rates, bitrates, and quality settings while suggesting sensible defaults.

Imported from the immutable baseline [AVE-REQ-081](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-081.md) (package v1.0); primary gate M6, scope v1.

## Description
Deliver a coherent output bundle containing the rendered video and the selected supporting artifacts.

## Acceptance criteria
- [ ] AC-1 Bundle selected per-language captions, chapter list, editable publication metadata, and a render manifest with source/project revision and output settings.
- [ ] AC-2 Artifacts use consistent names and match the same exported time range.
- [ ] AC-3 No credentials, private filesystem paths, or unintended GPS data leak into publication bundles.
- [ ] AC-4 Users can download an individual artifact or the complete bundle.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-039 — Section and whole-project export](AVE-REQ-039-section-and-whole-project-export.md)
- [AVE-REQ-063 — Subtitle sidecars and supported embedded tracks](AVE-REQ-063-subtitle-sidecars-and-supported-embedded-tracks.md)
- [AVE-REQ-071 — Copyable SEO and publication suggestions](AVE-REQ-071-copyable-seo-and-publication-suggestions.md)
- [AVE-REQ-072 — Real export pipeline and default delivery profile](AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-081 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-18](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-18), [AT-25](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-25), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
