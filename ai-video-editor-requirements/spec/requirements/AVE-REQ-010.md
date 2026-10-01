---
id: AVE-REQ-010
title: "Portable project backups"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-001
epic: AVE-EPIC-01
primary_gate: M7
origins: ["U24", "D01"]
dependencies: ["AVE-REQ-001", "AVE-REQ-003"]
scenarios: ["AT-22", "AT-20"]
---

# AVE-REQ-010 - Portable project backups

## Requirement

Users shall be able to export and restore a versioned editing-project bundle, with optional original media inclusion and a manifest of external references.

## Acceptance criteria

- [ ] **AC-1:** A metadata-only bundle restores projects after media relinking; a self-contained bundle restores without external paths.
- [ ] **AC-2:** Bundles contain edit decisions, profiles, sections, subtitles, and provenance but never API keys or session credentials.
- [ ] **AC-3:** Import validates bundle paths, schema version, hashes, and reference integrity before modifying an existing project.
- [ ] **AC-4:** Unsupported future schema versions are rejected safely and existing projects remain unchanged.

## Dependencies

[AVE-REQ-001](AVE-REQ-001.md); [AVE-REQ-003](AVE-REQ-003.md)

## Verification plan

[AT-22](../ACCEPTANCE_TESTS.md#at-22); [AT-20](../ACCEPTANCE_TESTS.md#at-20). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U24](../../intake/USER_BRIEF.md#u24); [D01](../../intake/USER_BRIEF.md#d01). Parent: [AVE-FEAT-001](../EPICS_AND_FEATURES.md#ave-feat-001).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
