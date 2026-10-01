---
id: AVE-REQ-082
title: "Self-hostable browser application and CPU reference setup"
type: nonfunctional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-018
epic: AVE-EPIC-08
primary_gate: M1
origins: ["U24", "D02"]
dependencies: []
scenarios: ["AT-21", "AT-23", "AT-20"]
---

# AVE-REQ-082 - Self-hostable browser application and CPU reference setup

## Requirement

Deliver a working desktop-browser editor backed by a local or self-hosted media-processing service, with a documented CPU-first reference deployment.

## Acceptance criteria

- [ ] **AC-1:** Provide repeatable installation/start commands, persistent storage configuration, migrations, and health checks.
- [ ] **AC-2:** A reference Linux environment can run without Docker when cloud-development policy prevents nested containers; container deployment is also documented.
- [ ] **AC-3:** Do not depend on Claude Code Cloud as a permanent production host, storage service, or GPU provider.
- [ ] **AC-4:** Bind local-only deployments safely by default; remote exposure requires the documented authentication and transport settings.

## Dependencies

No requirement dependencies.

## Verification plan

[AT-21](../ACCEPTANCE_TESTS.md#at-21); [AT-23](../ACCEPTANCE_TESTS.md#at-23); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [D02](../../intake/USER_BRIEF.md#d02). Parent: [AVE-FEAT-018](../EPICS_AND_FEATURES.md#ave-feat-018).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
