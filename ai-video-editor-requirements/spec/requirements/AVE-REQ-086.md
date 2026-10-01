---
id: AVE-REQ-086
title: "Safe media processing boundary"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["D04"]
dependencies: ["AVE-REQ-002", "AVE-REQ-048"]
scenarios: ["AT-20", "AT-23"]
---

# AVE-REQ-086 - Safe media processing boundary

## Requirement

Process uploaded media and images as untrusted input with constrained subprocesses, paths, protocols, and resource usage.

## Acceptance criteria

- [ ] **AC-1:** Build subprocess argument arrays without shell interpolation; validate or safely serialize any generated filter expressions.
- [ ] **AC-2:** Prevent path traversal, symlink escape, decompression/resource abuse, unapproved protocols, and unauthorized network fetches.
- [ ] **AC-3:** Use supported patched dependencies, per-job working directories, timeouts, cancellation, and least-privilege workers.
- [ ] **AC-4:** Security tests cover malicious filenames, overlay text, project bundles, subtitles, and oversized or malformed media.

## Dependencies

[AVE-REQ-002](AVE-REQ-002.md); [AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-20](../ACCEPTANCE_TESTS.md#at-20); [AT-23](../ACCEPTANCE_TESTS.md#at-23). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D04](../../intake/USER_BRIEF.md#d04). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
