---
id: AVE-REQ-084
title: "Measured responsiveness and bounded memory"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["D02", "U03", "U20"]
dependencies: ["AVE-REQ-007", "AVE-REQ-017", "AVE-REQ-077"]
scenarios: ["AT-23", "AT-27"]
---

# AVE-REQ-084 - Measured responsiveness and bounded memory

## Requirement

Keep interactive editing responsive and media processing memory-bounded, with declared reference hardware and measurable performance tests.

## Acceptance criteria

- [ ] **AC-1:** On the declared reference browser/system, a 300-item timeline targets p95 under 150 ms for local selection/trim feedback after assets are indexed, excluding network and rendering completion.
- [ ] **AC-2:** Exercise two 2560x1440 60 fps sources in a CPU render smoke test; record elapsed time and peak memory instead of promising real-time export.
- [ ] **AC-3:** On the reference 4-vCPU/8-GiB CPU worker profile, one baseline render job excluding optional local LLM/VLM inference stays within a configured 6-GiB worker budget.
- [ ] **AC-4:** Import large files and analyze long recordings with streaming/chunked processing; do not read an entire recording into application RAM.
- [ ] **AC-5:** If a target cannot be met, report the benchmark and bottleneck; do not silently lower input rate, resolution, or test coverage.

## Dependencies

[AVE-REQ-007](AVE-REQ-007.md); [AVE-REQ-017](AVE-REQ-017.md); [AVE-REQ-077](AVE-REQ-077.md)

## Verification plan

[AT-23](../ACCEPTANCE_TESTS.md#at-23); [AT-27](../ACCEPTANCE_TESTS.md#at-27). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D02](../../intake/USER_BRIEF.md#d02); [U03](../../intake/USER_BRIEF.md#u03); [U20](../../intake/USER_BRIEF.md#u20). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
