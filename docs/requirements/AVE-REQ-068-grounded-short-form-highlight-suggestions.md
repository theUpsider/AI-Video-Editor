---
id: AVE-REQ-068
title: Grounded short-form highlight suggestions
type: functional
status: ready
priority: must
parent: AVE-FEAT-015
source: human
scope: v1
primary_gate: M6
origins: [U12]
dependencies: [AVE-REQ-047, AVE-REQ-058, AVE-REQ-065]
scenarios: [AT-19, AT-14]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-068.md
---

# AVE-REQ-068 — Grounded short-form highlight suggestions

## Intent
Serves [GOAL-007](../PRODUCT.md#product-goals) through [AVE-FEAT-015 — Shorts](AVE-FEAT-015-shorts.md). Origin clauses in the user brief:
- [U12](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u12) — Automatically identify useful approximately 15-20-second highlights and export editable shorts, including square 1:1 outputs.

Imported from the immutable baseline [AVE-REQ-068](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-068.md) (package v1.0); primary gate M6, scope v1.

## Description
The AI shall propose short-form highlights with a default duration range of 15 to 20 seconds and editable editorial rationale.

## Acceptance criteria
- [ ] AC-1 Default target is 18 seconds within the user-configurable 15..20-second range; source duration and hard constraints are respected.
- [ ] AC-2 Candidates reference selected source/project intervals, relevant transcript or visual evidence, and an explanation of the proposed hook or subject.
- [ ] AC-3 Prefer coherent starts and endings; if no adequate candidate exists, report that rather than padding with invented footage or claiming guaranteed engagement.
- [ ] AC-4 Users can compare candidates, choose one or several, and adjust their ranges before export.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-047 — Grounded editorial reasoning](AVE-REQ-047-grounded-editorial-reasoning.md)
- [AVE-REQ-058 — Editable searchable source transcripts](AVE-REQ-058-editable-searchable-source-transcripts.md)
- [AVE-REQ-065 — Timestamped keyframes and shot summaries](AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-068 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-14](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-14) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
