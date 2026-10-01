---
id: AVE-REQ-030
title: Manual synchronization tools
type: functional
status: ready
priority: must
parent: AVE-FEAT-004
source: human
scope: v1
primary_gate: M2
origins: [U15, U20]
dependencies: [AVE-REQ-017, AVE-REQ-026]
scenarios: [AT-06, AT-08, AT-11]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-030.md
---

# AVE-REQ-030 — Manual synchronization tools

## Intent
Serves [GOAL-003](../PRODUCT.md#product-goals) through [AVE-FEAT-004 — Multicamera synchronization](AVE-FEAT-004-multicamera-synchronization.md). Origin clauses in the user brief:
- [U15](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u15) — Synchronize simultaneous perspectives and preserve audiovisual/lip alignment while one source supplies the final audio.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-030](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-030.md) (package v1.0); primary gate M2, scope v1.

## Description
Users shall be able to inspect and refine synchronization using waveform views, reference-frame comparisons, anchors, and precise nudges.

## Acceptance criteria
- [ ] AC-1 Provide one-frame video nudges and numeric offsets with finer audio precision where supported.
- [ ] AC-2 Allow setting at least two corresponding event anchors for drift inspection or correction.
- [ ] AC-3 Play an aligned preview with one reference audio source and expose the predicted residual or manual status.
- [ ] AC-4 Manual overrides remain stable during subsequent automatic draft or analysis operations unless explicitly reset.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-017 — Usable synchronized preview](AVE-REQ-017-usable-synchronized-preview.md)
- [AVE-REQ-026 — Persistent synchronization transforms](AVE-REQ-026-persistent-synchronization-transforms.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-030 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-06](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-06), [AT-08](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-08), [AT-11](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-11) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
