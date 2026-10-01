---
id: AVE-REQ-090
title: Crash recovery and safe migrations
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: derived
scope: v1
primary_gate: M7
origins: [D01]
dependencies: [AVE-REQ-001, AVE-REQ-015, AVE-REQ-077]
scenarios: [AT-22, AT-17]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-090.md
---

# AVE-REQ-090 — Crash recovery and safe migrations

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D01](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d01) — Derived integrity requirement: non-destructive originals, revision consistency, recovery, and reversible changes.

Imported from the immutable baseline [AVE-REQ-090](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-090.md) (package v1.0); primary gate M7, scope v1.

## Description
Project persistence and schema migrations shall recover safely from crashes and preserve existing user edits.

## Acceptance criteria
- [ ] AC-1 Transactions interrupted before commit leave the previous revision intact; interrupted jobs can be inspected and retried.
- [ ] AC-2 Back up or otherwise safely checkpoint project data before destructive schema migration.
- [ ] AC-3 Version checks reject unsupported states instead of guessing at missing fields.
- [ ] AC-4 Recovery tests restart the application during autosave, analysis, and export and verify originals and accepted edits remain intact.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)
- [AVE-REQ-015 — Undo, redo, autosave, and revisions](AVE-REQ-015-undo-redo-autosave-and-revisions.md)
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-090 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-22](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-22), [AT-17](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-17) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
