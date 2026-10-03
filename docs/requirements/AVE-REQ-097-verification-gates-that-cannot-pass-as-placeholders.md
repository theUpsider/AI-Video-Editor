---
id: AVE-REQ-097
title: Verification gates that cannot pass as placeholders
type: constraint
status: verification
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D03]
dependencies: [AVE-REQ-093]
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-097.md
---

# AVE-REQ-097 — Verification gates that cannot pass as placeholders

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D03](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d03) — Derived correctness requirement: exact timing semantics, rendered-output evidence, shared composition model, and honest verification.

Imported from the immutable baseline [AVE-REQ-097](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-097.md) (package v1.0); primary gate M0, scope v1.

## Description
Replace bootstrap-only verification with staged real checks and independently verifiable release gates as implementation begins.

## Acceptance criteria
- [ ] AC-1 Keep a fast feedback tier, real-media integration tier, and full release tier behind documented repository commands.
- [ ] AC-2 Tie verification evidence to a commit/tree fingerprint, configuration, requirement IDs, and test results; stale evidence cannot certify changed code.
- [ ] AC-3 Use supported hooks only after a small smoke test; avoid recursive Stop-hook loops and repeated full renders on every conversational response.
- [ ] AC-4 No-op scripts, skipped integration tests, caught exceptions returning success, or provider mocks cannot establish completed product requirements.

## Edge cases
- A skipped, expected-to-fail or never-collected test → fails verification or gives no evidence (AC-4); this holds for a module skipped at collection (`pytest.skip(allow_module_level=True)`, `pytest.importorskip`) and for the tooling unit tests (`scripts/evidence.py unittest` also fails a file without tests).
- A tooling suite that `scripts/tests/run.sh` never runs → gives no evidence; a tooling suite or unit-test file that fails → counts against every criterion it tags (AC-4).
- A listed tooling suite that exits 0 without running a check (no `TOTAL: pass=N fail=M` line with N ≥ 1) → `run.sh` fails and the suite counts against every criterion it tags (AC-4).
- A test tagged with a criterion that does not exist → stops the test run; a tooling test comment tag of that kind fails the "Evidence manifest" step of every tier and `check-done`, naming the file and line (AC-2).
- A manifest that names a requirement without a working file → `evidence.py show` reports the unknown ID as an error (AC-2).
- A run with a failed step → certifies no requirement complete: `evidence.py show --require-complete` exits 1 (AC-4).
- Evidence recorded for an older tree → reported stale and refused where freshness is required (AC-2).
- A provider test that runs on a fake → never evidences a criterion alone (AC-4).
- The Stop gate asked for a heavier tier by the environment → still runs the fast tier (AC-3).
- A failing step in any tier → that tier fails with exit 1 (AC-1, AC-4).

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)

## Verification strategy
- AC-1 — integration — `scripts/tests/test-verify-tiers.sh`: fast ⊂ media ⊂ release membership, `--tier`/`VERIFY_TIER` selection, usage errors; CI runs the release tier.
- AC-2 — unit and integration — `scripts/tests/test_evidence.py` (criterion states, manifest ties results to commit, fingerprint, configuration and suite results, stale evidence refused with `--require-fresh`, tooling tags naming no criterion stop `record` and `check-done` with file and line, unknown requirement IDs reported by `show`), `backend/tests/unit/test_evidence_plugin.py` (tags validated against requirement files, per-test report), `scripts/tests/test-stop-hook.sh` (a real run leaves a manifest with the tree fingerprint).
- AC-3 — integration and inspection — `scripts/tests/test-stop-hook.sh`: the gate runs the fast tier even when the environment asks for release (its fixture registers one marker step per tier; the log holds the fast marker and neither the media nor the release marker), stays bounded without `stop_hook_active`, releases after its attempt limit; hooks were smoke-tested before use (ASM-001, ASM-003).
- AC-4 — unit and integration — `backend/tests/unit/test_evidence_plugin.py` (`--forbid-skips` fails a session holding one skipped, expected-to-fail or unexpectedly passing test, one module per category, or a module skipped at collection; contract flag recorded), `scripts/tests/test_evidence.py` (contract-only and skipped evidence never satisfy a done requirement; tooling tags count only through suite results of the run: a suite `run.sh` never runs gives no evidence, a failing suite counts against its criteria, a listed suite that exits 0 without a check fails `run.sh` and counts against its criteria, `evidence.py unittest` fails on a skipped, failing, erroring, expected-to-fail or unexpectedly passing test and on a file without tests; a failed run never satisfies `show --require-complete`), `scripts/tests/test-verify-tiers.sh` and `test-stop-hook.sh` (failing steps fail the tier and the gate).
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `scripts/verify.sh`, `scripts/verify.d/*.sh` — fast, media and release tiers behind one command (AC-1)
- `scripts/evidence.py`, `backend/tests/evidence_plugin.py`, `backend/tests/conftest.py` — per-run evidence manifests tied to commit, tree fingerprint, toolchain, configuration, suite results and criterion tags; freshness check; tooling tags validated with file and line; unknown requirement IDs reported by `show` (AC-2)
- `.claude/hooks/stop-verify.sh` — Stop gate pinned to the fast tier, bounded attempts (AC-3)
- `scripts/verify.d/20-backend.sh` (`--forbid-skips`, including modules skipped at collection), `scripts/verify.d/95-evidence.sh` (`check-done`) — skipped tests and contract-only evidence never establish completion (AC-4)
- `scripts/tests/run.sh` and `scripts/evidence.py` (`record-suite`, `unittest`; `scripts/verify.d/15-evidence-tooling.sh`) — one suite result (file, exit status, number of checks, tags) per tooling test file that ran, the only source of tooling evidence; a suite that exited 0 without a check counts as failed; the unit-test step fails on skipped, expected-to-fail and unexpectedly passing tests and on a file without tests; `show --require-complete` exits 1 for a failed run (AC-4)
- Tests: `scripts/tests/test-verify-tiers.sh` — AVE-REQ-097 AC-1, AVE-REQ-097 AC-4; `scripts/tests/test_evidence.py` — AVE-REQ-097 AC-2, AVE-REQ-097 AC-4; `backend/tests/unit/test_evidence_plugin.py` — AVE-REQ-097 AC-2, AVE-REQ-097 AC-4; `scripts/tests/test-stop-hook.sh` — AVE-REQ-097 AC-2, AVE-REQ-097 AC-3, AVE-REQ-097 AC-4
- Decisions: [ADR-001](../decisions/ADR-001-specification-driven-development-workflow.md), [ADR-003](../decisions/ADR-003-requirements-baseline-import.md), [WF-004](../WORKFLOW_LOG.md)

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
- 2026-10-03 — in-progress — verify-requirement PASS at `d4d3883` (workflow `wf_ed1f5104-63a`) refuted by its skeptic: a listed shell suite reduced to `exit 0` still credited every tag it carries, because `scripts/tests/run.sh` recorded the exit status only; `run.sh` now records the suite's check count from its `TOTAL: pass=N fail=M` line and fails a suite that ran no check, and `scripts/evidence.py` credits a suite only with exit 0 and at least one check (lead)
- 2026-10-03 — verification — fix in place with unit and runner cases; independent verification requested again (lead)
