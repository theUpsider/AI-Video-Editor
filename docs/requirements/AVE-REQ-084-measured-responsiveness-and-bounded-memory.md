---
id: AVE-REQ-084
title: Measured responsiveness and bounded memory
type: non-functional
status: ready
priority: must
parent: AVE-FEAT-018
source: human
scope: v1
primary_gate: M7
origins: [D02, U03, U20]
dependencies: [AVE-REQ-007, AVE-REQ-017, AVE-REQ-077]
scenarios: [AT-23, AT-27]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-084.md
---

# AVE-REQ-084 — Measured responsiveness and bounded memory

## Intent
Serves [GOAL-008](../PRODUCT.md#product-goals) through [AVE-FEAT-018 — Runtime quality and handover](AVE-FEAT-018-runtime-quality-and-handover.md). Origin clauses in the user brief:
- [D02](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d02) — Derived implementation default: self-hostable CPU-first single-user browser application, bounded resources, reproducibility, and explicit capability reporting.
- [U03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u03) — Detect actual input frame rates and resolutions, including the described approximately 2K/60 fps footage, and handle mixed inputs.
- [U20](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u20) — Offer ordinary manual timeline controls, including draggable cuts, transitions, and earlier/later clip endings, before or after AI edits.

Imported from the immutable baseline [AVE-REQ-084](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-084.md) (package v1.0); primary gate M7, scope v1.

## Description
Keep interactive editing responsive and media processing memory-bounded, with declared reference hardware and measurable performance tests.

## Acceptance criteria
- [ ] AC-1 On the declared reference browser/system, a 300-item timeline targets p95 under 150 ms for local selection/trim feedback after assets are indexed, excluding network and rendering completion.
- [ ] AC-2 Exercise two 2560x1440 60 fps sources in a CPU render smoke test; record elapsed time and peak memory instead of promising real-time export.
- [ ] AC-3 On the reference 4-vCPU/8-GiB CPU worker profile, one baseline render job excluding optional local LLM/VLM inference stays within a configured 6-GiB worker budget.
- [ ] AC-4 Import large files and analyze long recordings with streaming/chunked processing; do not read an entire recording into application RAM.
- [ ] AC-5 If a target cannot be met, report the benchmark and bottleneck; do not silently lower input rate, resolution, or test coverage.

## Edge cases
_TBD: refined when implementation starts._

## Dependencies
- [AVE-REQ-007 — Proxies, thumbnails, and waveforms](AVE-REQ-007-proxies-thumbnails-and-waveforms.md)
- [AVE-REQ-017 — Usable synchronized preview](AVE-REQ-017-usable-synchronized-preview.md)
- [AVE-REQ-077 — Durable asynchronous jobs](AVE-REQ-077-durable-asynchronous-jobs.md)

## Verification strategy
- AC-1–AC-5 — criterion-level tests tagged `AVE-REQ-084 AC-n`, one tag per criterion; the level of each (unit, integration, end-to-end, inspection) is recorded when implementation starts.
- Acceptance scenarios [AT-23](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-23), [AT-27](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-27) — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it passes on the current tree.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
