---
id: AVE-REQ-088
title: "Pinned dependencies and license inventory"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M7
origins: ["D02", "D04"]
dependencies: ["AVE-REQ-082"]
scenarios: ["AT-21", "AT-29"]
---

# AVE-REQ-088 - Pinned dependencies and license inventory

## Requirement

Deliver reproducible dependency configuration and a documented inventory of software, model, codec, and font licensing considerations.

## Acceptance criteria

- [ ] **AC-1:** Pin supported stable dependency versions and model revisions in lockfiles or equivalent reproducible manifests.
- [ ] **AC-2:** Use permissively usable defaults where feasible; do not introduce paid SDKs or subscription-gated editing components without approval.
- [ ] **AC-3:** Document the actual FFmpeg build and enabled codecs rather than claiming all possible codec distributions have identical licensing.
- [ ] **AC-4:** Provide dependency-update and vulnerability-check commands and report unresolved issues honestly.

## Dependencies

[AVE-REQ-082](AVE-REQ-082.md)

## Verification plan

[AT-21](../ACCEPTANCE_TESTS.md#at-21); [AT-29](../ACCEPTANCE_TESTS.md#at-29). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[D02](../../intake/USER_BRIEF.md#d02); [D04](../../intake/USER_BRIEF.md#d04). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
