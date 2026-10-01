---
id: AVE-REQ-029
title: Linked edits preserve synchronization
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U20]
dependencies: [AVE-REQ-013, AVE-REQ-026]
scenarios: [AT-05, AT-11, AT-12]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-029.md
---

# AVE-REQ-029 — Linked edits preserve synchronization

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-029](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-029.md) (package v1.0); primary gate M2, scope v1.

## Description
Timeline edits on a synchronized group shall preserve relative timing unless the user explicitly chooses to slip or unlink one source.

## Acceptance criteria
- [ ] AC-1 Moving, splitting, ripple-deleting, or trimming a linked group updates all affected video, audio, and overlay mappings as specified.
- [ ] AC-2 A deliberate single-source slip warns that alignment changes and creates an undoable operation.
- [ ] AC-3 Locked linked members prevent a conflicting group edit rather than leaving the group partially updated.
- [ ] AC-4 Undo and redo restore both visible arrangement and synchronization transforms.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-013 — Manual editing and precision controls](AVE-REQ-013-manual-editing-and-precision-controls.md)
- [AVE-REQ-026 — Persistent synchronization transforms](AVE-REQ-026-persistent-synchronization-transforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-029 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-05](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-05), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11), [AT-12](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-12) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
