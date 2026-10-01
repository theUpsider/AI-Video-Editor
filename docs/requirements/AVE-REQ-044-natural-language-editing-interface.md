---
id: AVE-REQ-044
title: Natural-language editing interface
type: functional
status: ready
priority: must
parent: AVE-FEAT-009
source: human
scope: v1
primary_gate: M5
origins: [U24, U25]
dependencies: [AVE-REQ-015, AVE-REQ-048, AVE-REQ-050]
scenarios: [AT-14, AT-12, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-044.md
---

# AVE-REQ-044 — Natural-language editing interface

## Intent
Serves [GOAL-005](../PRODUCT.md#product-goals) through [AVE-FEAT-009 — AI draft and conversational editing](AVE-FEAT-009-ai-draft-and-conversational-editing.md). Origin clauses in the user brief:
- [U24](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u24) — End-to-end workflow: collection -> AI first draft -> preview/manual changes -> additional natural-language edits -> export.
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.

Imported from the immutable baseline [AVE-REQ-044](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-044.md) (package v1.0); primary gate M5, scope v1.

## Description
The editor shall offer a project-aware text interface for initial editing instructions and subsequent modifications.

## Acceptance criteria
- [ ] AC-1 Users can reference selected clips, named sections, visible timeline items, or a scoped time range in a prompt.
- [ ] AC-2 Show planning, analysis, proposal, application, and failure/cancel states rather than one indefinite spinner.
- [ ] AC-3 A request such as shorten the last section and move its title is converted to inspectable editing operations.
- [ ] AC-4 Provider errors or missing credentials do not masquerade as completed AI edits, and manual editing remains available.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](AVE-REQ-015-undo-redo-autosave-and-revisions.md)
- [AVE-REQ-048 — One typed editing command service](AVE-REQ-048-one-typed-editing-command-service.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](AVE-REQ-050-provider-neutral-language-model-adapters.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-044 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14), [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
