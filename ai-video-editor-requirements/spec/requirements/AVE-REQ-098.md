---
id: AVE-REQ-098
title: "Persistent progress and bounded autonomous continuation"
type: delivery
scope: v1
priority: must
status: ready
parent: AVE-FEAT-019
epic: AVE-EPIC-09
primary_gate: M0
origins: ["U27", "D05"]
dependencies: ["AVE-REQ-093", "AVE-REQ-094"]
scenarios: ["AT-30", "AT-29"]
---

# AVE-REQ-098 - Persistent progress and bounded autonomous continuation

## Requirement

Claude Code shall persist actionable progress and continue unblocked work within actual session limits, then leave an exact resumable state.

## Acceptance criteria

- [ ] **AC-1:** Update the current objective, requirement statuses, blockers, failed checks, changed files, and next command after coherent work units.
- [ ] **AC-2:** Reconstruct state from repository files and Git after compaction or a new session rather than relying on conversational memory.
- [ ] **AC-3:** At a genuine permission, resource, credential, or session limit, preserve partial results and report the exact unblock action without claiming ongoing execution.
- [ ] **AC-4:** Do not use infinite loops, arbitrary sleep daemons, or permission bypass flags to simulate unlimited autonomy.

## Dependencies

[AVE-REQ-093](AVE-REQ-093.md); [AVE-REQ-094](AVE-REQ-094.md)

## Verification plan

[AT-30](../ACCEPTANCE_TESTS.md#at-30); [AT-29](../ACCEPTANCE_TESTS.md#at-29). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U27](../../intake/USER_BRIEF.md#u27); [D05](../../intake/USER_BRIEF.md#d05). Parent: [AVE-FEAT-019](../EPICS_AND_FEATURES.md#ave-feat-019).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
