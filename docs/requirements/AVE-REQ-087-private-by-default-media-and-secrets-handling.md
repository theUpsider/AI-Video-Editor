---
id: AVE-REQ-087
title: Private-by-default media and secrets handling
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M5
origins: [D04, U25, U26]
dependencies: [AVE-REQ-001]
scenarios: [AT-20, AT-24]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-087.md
---

# AVE-REQ-087 — Private-by-default media and secrets handling

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D04](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d04) — Derived security requirement: untrusted-media boundaries, least privilege, protected credentials, and private-by-default processing.
- [U25](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u25) — Ideally integrate Claude Code and Codex as selectable AI/agent backends.
- [U26](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u26) — Support OpenAI-compatible endpoints and downloadable Hugging Face analysis models, using practical defaults.

Imported from the immutable baseline [AVE-REQ-087](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-087.md) (package v1.0); primary gate M5, scope v1.

## Description
Keep original recordings, location metadata, transcripts, and credentials private by default and require clear configuration before external processing.

## Acceptance criteria
- [ ] AC-1 Local import, manual editing, and CPU export do not upload source media to model providers.
- [ ] AC-2 Before enabling remote analysis, show which data types and approximate payloads leave the system and allow text-only or reduced-frame policies.
- [ ] AC-3 Secrets are server-side and redacted; they are excluded from repositories, browser responses, project exports, prompts, and logs.
- [ ] AC-4 Provide retention and deletion controls for derived analysis without deleting originals by default.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)

## Verification strategy
- AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-087 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-20](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-20), [AT-24](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-24) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
