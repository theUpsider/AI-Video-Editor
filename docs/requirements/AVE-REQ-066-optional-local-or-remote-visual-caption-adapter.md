---
id: AVE-REQ-066
title: Optional local or remote visual-caption adapter
type: functional
status: ready
priority: must
parent: AVE-FEAT-014
source: human
scope: v1
primary_gate: M4
origins: [U07, U26]
dependencies: [AVE-REQ-053, AVE-REQ-065, AVE-REQ-050]
scenarios: [AT-19, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-066.md
---

# AVE-REQ-066 — Optional local or remote visual-caption adapter

## Intent
Serves [GOAL-006](../PRODUCT.md#product-goals) through [AVE-FEAT-014 — Visual indexing and understanding](AVE-FEAT-014-visual-indexing-and-understanding.md). Origin clauses in the user brief:
- [U07](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u07) — Prepare for identifying clips and understanding their contents using keyframes, multiple images, or Hugging Face video models; richer understanding was described as future-facing.
- [U26](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u26) — Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.

Imported from the immutable baseline [AVE-REQ-066](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-066.md) (package v1.0); primary gate M4, scope v1.

## Description
Provide an optional visual-captioning adapter that can summarize selected frames or short windows using a configured vision model, including a documented Hugging Face candidate.

## Acceptance criteria
- [ ] AC-1 At least one supported model execution path is implemented behind the adapter and has contract tests plus a reproducible live-model validation command.
- [ ] AC-2 Caption requests have frame-count, resolution, context, duration, and memory limits appropriate to detected hardware.
- [ ] AC-3 Results are timestamped visual inferences with provenance, not verified facts about identity, location, or unseen events.
- [ ] AC-4 When no feasible vision model is available, expose that limitation and use metadata/transcript evidence rather than returning placeholder visual descriptions.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-053 — Hugging Face model registry and downloads](AVE-REQ-053-hugging-face-model-registry-and-downloads.md)
- [AVE-REQ-065 — Timestamped keyframes and shot summaries](AVE-REQ-065-timestamped-keyframes-and-shot-summaries.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](AVE-REQ-050-provider-neutral-language-model-adapters.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-066 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-19](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-19), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
