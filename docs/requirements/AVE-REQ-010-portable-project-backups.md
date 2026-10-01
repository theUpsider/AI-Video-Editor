---
id: AVE-REQ-010
title: Portable project backups
type: functional
status: ready
priority: must
parent: AVE-FEAT-001
source: human
scope: v1
primary_gate: M7
origins: [U24, D01]
dependencies: [AVE-REQ-001, AVE-REQ-003]
scenarios: [AT-22, AT-20]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-010.md
---

# AVE-REQ-010 — Portable project backups

## Intent
Serves [GOAL-001](../PRODUCT.md#product-goals) through [AVE-FEAT-001 — Projects and media collection](AVE-FEAT-001-projects-and-media-collection.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-010](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-010.md) (package v1.0); primary gate M7, scope v1.

## Description
Users shall be able to export and restore a versioned editing-project bundle, with optional original media inclusion and a manifest of external references.

## Acceptance criteria
- [ ] AC-1 A metadata-only bundle restores projects after media relinking; a self-contained bundle restores without external paths.
- [ ] AC-2 Bundles contain edit decisions, profiles, sections, subtitles, and provenance but never API keys or session credentials.
- [ ] AC-3 Import validates bundle paths, schema version, hashes, and reference integrity before modifying an existing project.
- [ ] AC-4 Unsupported future schema versions are rejected safely and existing projects remain unchanged.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-003 — Immutable originals and stable asset identities](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-010 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
