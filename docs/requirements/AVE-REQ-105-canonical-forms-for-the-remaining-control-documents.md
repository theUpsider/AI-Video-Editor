---
id: AVE-REQ-105
title: Canonical forms for the remaining control documents
type: constraint
status: proposed
priority: could
parent: AVE-FEAT-019
source: derived
scope: v1
primary_gate: M7
origins: []
dependencies: [AVE-REQ-093, AVE-REQ-096, AVE-REQ-097, AVE-REQ-098]
scenarios: []
---

# AVE-REQ-105 — Canonical forms for the remaining control documents

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md):
the gates read the control documents the way a reader sees them. Found by the three rounds of the final M0
review (2026-10-06 and 2026-10-07): requirement files and the roadmap follow written forms, while task briefs,
`docs/PROGRESS.md`, the entries of `.claude/` and a few probe and tool corners are read by single patterns, where
each review found one more form ([WF-013](../WORKFLOW_LOG.md)). The criteria of AVE-REQ-093, AVE-REQ-096,
AVE-REQ-097 and AVE-REQ-098 hold without this work; it hardens their gates.

## Description
The control documents that the M0 gates still read by pattern get a written form that fails every other form,
as requirement files and the roadmap have: task briefs and `docs/PROGRESS.md` (headings, comments, fenced blocks,
code spans), the entries of `.claude/` and the `env` block of its settings file. The probe reports the limit
that holds along the cgroup path of its process, and tracked backend files lie where every backend tool reads
them. A form that a later review finds to pass a gate, while the criteria of the gate's requirement hold, is
recorded in § Edge cases of this requirement.

## Acceptance criteria
- [ ] AC-1 A task brief and `docs/PROGRESS.md` follow one written form for headings, HTML comments, fenced blocks and code spans; the project checker fails every other form, so the checker and a Markdown renderer read the same headings, sections and wordings.
- [ ] AC-2 The entries of `.claude/` follow an allow-list: a command file, a plugin, an agent file in a subdirectory or a nested `.claude` directory fails the project checker.
- [ ] AC-3 The `env` block of `.claude/settings.json` holds listed names only.
- [ ] AC-4 The probe reports the lowest CPU and memory limit along the cgroup path of its process.
- [ ] AC-5 A tracked file under `backend/src` or `backend/tests` below a directory that ruff, mypy or pytest passes over fails the project checker.
- [ ] AC-6 An entry of `docs/requirements/` is a file of the name pattern or a listed file, whatever its extension.

## Edge cases
- A form found by a later review that belongs to none of the criteria above → added here with its reproduction
  before this requirement is refined to Ready.
- The provider variables of `.env` on a host that verifies in the development container → outside this
  requirement: the first requirement with a live provider decides how they reach the container.

## Dependencies
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-096 — Isolated bounded tasks and independent review](AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)
- [AVE-REQ-097 — Verification gates that cannot pass as placeholders](AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)
- [AVE-REQ-098 — Persistent progress and bounded autonomous continuation](AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md)

## Verification strategy
- AC-1, AC-2, AC-3, AC-5, AC-6 — integration — cases of `scripts/tests/test-checker.sh` and a comparison with a Markdown renderer.
- AC-4 — integration — cases of `scripts/tests/test-probe-environment.sh` on a fixture directory.
- Acceptance scenarios: None.

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-07 — proposed — discovered during the final M0 review, rounds one to three: hardening of the gates beyond the criteria of AVE-REQ-093, AVE-REQ-096, AVE-REQ-097 and AVE-REQ-098 ([WF-013](../WORKFLOW_LOG.md), [ASM-041](../ASSUMPTIONS.md)) (lead)
