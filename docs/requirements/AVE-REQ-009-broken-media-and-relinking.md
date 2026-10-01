---
id: AVE-REQ-009
title: Broken media and relinking
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M1
origins: [U24, D01]
dependencies: [AVE-REQ-003, AVE-REQ-004]
scenarios: [AT-01, AT-22]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-009.md
---

# AVE-REQ-009 — Broken media and relinking

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-009](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-009.md) (package v1.0); primary gate M1, scope v1.

## Description
Missing, corrupted, unsupported, or inaccessible media shall produce recoverable errors rather than fabricated successful analysis or export.

## Acceptance criteria
- [ ] AC-1 The collection and affected timeline items display the specific problem and retain their edit metadata.
- [ ] AC-2 Relinking validates identity or asks for explicit replacement confirmation when the content differs.
- [ ] AC-3 Exports using broken media fail preflight or require an explicit, recorded gap policy; they never silently omit clips.
- [ ] AC-4 Errors identify the failing asset and actionable diagnostics without exposing secrets.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-003 — Immutable originals and stable asset identities](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)
- [AVE-REQ-004 — Media probing, exact dimensions, and source timing](AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-009 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-01](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-01), [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
