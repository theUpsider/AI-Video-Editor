---
id: AVE-REQ-066
title: "Optional local or remote visual-caption adapter"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-014
epic: AVE-EPIC-06
primary_gate: M4
origins: ["U07", "U26"]
dependencies: ["AVE-REQ-053", "AVE-REQ-065", "AVE-REQ-050"]
scenarios: ["AT-19", "AT-24"]
---

# AVE-REQ-066 - Optional local or remote visual-caption adapter

## Requirement

Provide an optional visual-captioning adapter that can summarize selected frames or short windows using a configured vision model, including a documented Hugging Face candidate.

## Acceptance criteria

- [ ] **AC-1:** At least one supported model execution path is implemented behind the adapter and has contract tests plus a reproducible live-model validation command.
- [ ] **AC-2:** Caption requests have frame-count, resolution, context, duration, and memory limits appropriate to detected hardware.
- [ ] **AC-3:** Results are timestamped visual inferences with provenance, not verified facts about identity, location, or unseen events.
- [ ] **AC-4:** When no feasible vision model is available, expose that limitation and use metadata/transcript evidence rather than returning placeholder visual descriptions.

## Dependencies

[AVE-REQ-053](AVE-REQ-053.md); [AVE-REQ-065](AVE-REQ-065.md); [AVE-REQ-050](AVE-REQ-050.md)

## Verification plan

[AT-19](../ACCEPTANCE_TESTS.md#at-19); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U07](../../intake/USER_BRIEF.md#u07); [U26](../../intake/USER_BRIEF.md#u26). Parent: [AVE-FEAT-014](../EPICS_AND_FEATURES.md#ave-feat-014).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
