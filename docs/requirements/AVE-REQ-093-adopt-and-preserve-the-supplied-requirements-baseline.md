---
id: AVE-REQ-093
title: Adopt and preserve the supplied requirements baseline
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D05]
dependencies: []
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-093.md
---

# AVE-REQ-093 — Adopt and preserve the supplied requirements baseline

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-093](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-093.md) (package v1.0); primary gate M0, scope v1.

## Description
The implementing agent shall integrate this specification into the existing bootstrapped repository without re-running or replacing the bootstrap.

## Acceptance criteria
- [ ] AC-1 Preserve this input package as an immutable baseline and map every AVE-REQ ID to its canonical working requirement file.
- [ ] AC-2 Populate the existing PRODUCT, ARCHITECTURE, ROADMAP, PROGRESS, ASSUMPTIONS, and TRACEABILITY documents without losing meaningful existing content.
- [ ] AC-3 Explicit user requirements and exclusions cannot be demoted or rewritten merely to fit an easier implementation.
- [ ] AC-4 Requirement implementation status starts unverified; package validation is not product verification.

## Edge cases
- A baseline file edited, added or removed → package validation fails (AC-1).
- MANIFEST.json edited, removed or duplicated inside the package, or a baseline edit with a re-hashed
  MANIFEST.json → the baseline check fails with "baseline changed": the checker pins the manifest's SHA-256
  outside the package (AC-1, AC-3).
- A working file missing, duplicated or with a changed identity (title, type, priority, scope, source, parent,
  dependencies, origins, scenarios, Description) → the baseline check fails; a Description change passes only
  with a logged reason (AC-1, AC-3).
- A criterion or the Description reworded or removed, or text added to the Description (a fenced block
  included), without a logged reason (`AC-n changed: <reason>`, `Description changed: <reason>`) → fails; with
  a logged reason → reported (AC-3).
- A future requirement made ready, or a version-one requirement deferred → fails (AC-3).
- Package validation passing while no requirement is verified → statuses stay unverified (AC-4).
- Existing bootstrap content kept when documents are populated (AC-2, inspection).

## Dependencies
None.

## Verification strategy
- AC-1 — integration — `scripts/tests/test-check-baseline.sh` (tagged comment lines): immutability of the package (hash and inventory checks; the manifest hash pinned outside the package, so an edited, removed, duplicated or re-hashed MANIFEST.json fails with "baseline changed"), exactly one working file per baseline ID, a current IMPORT_MAPPING.md; step "Requirements baseline integrity" runs `scripts/check_baseline.py` on the real repository in every tier.
- AC-2 — inspection — the six documents are populated from the baseline and keep their bootstrap content (Git history of each file since `f605c6c`); automation cannot judge "meaningful content".
- AC-3 — integration — `scripts/tests/test-check-baseline.sh`: demoted priority, changed scope, type, source, parent, dependencies, origins or scenarios, deferring a version-one requirement, readying a future one, rewording a criterion or the Description without a logged reason, or weakening a criterion in the baseline, its JSON and the working file with a re-hashed manifest all fail; a reworded Description with a logged `Description changed: <reason>` line is reported.
- AC-4 — integration and inspection — `scripts/tests/test-check-baseline.sh` (import starts unverified: statuses `ready`/`deferred`, 0 of 404 criteria ticked); `scripts/evidence.py check-done` (release tier) refuses a `done` requirement without this run's evidence.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `ai-video-editor-requirements/` — the baseline package, committed unchanged at `6160278`; validated by its own `ai-video-editor-requirements/tools/validate_package.py` and MANIFEST.json hashes (AC-1)
- `scripts/check_baseline.py` — the manifest hash pinned outside the package (`BASELINE_MANIFEST_SHA256`), package validation, and working-file integrity (identity, Description, criteria, statuses, mapping) (AC-1, AC-3, AC-4)
- `scripts/requirements/import_baseline.py`, `docs/requirements/IMPORT_MAPPING.md`, 131 `docs/requirements/AVE-*.md` — idempotent import and the ID mapping (AC-1, AC-4)
- `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PROGRESS.md`, `docs/ASSUMPTIONS.md`, `docs/TRACEABILITY.md` — populated from the baseline, bootstrap content kept (AC-2)
- `scripts/evidence.py` (`check-done`), `scripts/verify.d/95-evidence.sh` — package checks never certify completion (AC-4)
- Tests: `scripts/tests/test-check-baseline.sh` — AVE-REQ-093 AC-1, AVE-REQ-093 AC-3, AVE-REQ-093 AC-4; `scripts/tests/test_evidence.py` — done requirements need run evidence
- Decisions: [ADR-003](../decisions/ADR-003-requirements-baseline-import.md), [ASM-004](../ASSUMPTIONS.md)

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-02 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-02 — in-progress — M0 delivery-process gates implemented; criterion evidence under review (lead)
- 2026-10-02 — in-progress — verification levels recorded per criterion; AT-29/AT-30 run at the final review (lead)
- 2026-10-02 — verification — implementation evidence complete; independent verification requested (lead)
- 2026-10-02 — in-progress — verify-requirement FAIL at `4d9ef9a` (workflow `wf_b0c34bba-a20`); blocking findings and fixes in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) (lead)
