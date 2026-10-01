---
id: AVE-REQ-071
title: "Copyable SEO and publication suggestions"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-016
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U13"]
dependencies: ["AVE-REQ-047", "AVE-REQ-058", "AVE-REQ-038"]
scenarios: ["AT-25", "AT-19"]
---

# AVE-REQ-071 - Copyable SEO and publication suggestions

## Requirement

The AI shall generate editable keyword, tag, title, and description suggestions for the whole video, a section, or a short.

## Acceptance criteria

- [ ] **AC-1:** Suggestions are grounded in available content, locations, language, and user instructions, without invented claims.
- [ ] **AC-2:** Users can copy individual fields or export a text/JSON metadata bundle in a selected language.
- [ ] **AC-3:** Suggested keywords and hashtags are distinguished from technical container metadata and subtitle tracks.
- [ ] **AC-4:** The interface makes no promise of search ranking, reach, or virality and does not upload to a platform automatically.

## Dependencies

[AVE-REQ-047](AVE-REQ-047.md); [AVE-REQ-058](AVE-REQ-058.md); [AVE-REQ-038](AVE-REQ-038.md)

## Verification plan

[AT-25](../ACCEPTANCE_TESTS.md#at-25); [AT-19](../ACCEPTANCE_TESTS.md#at-19). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U13](../../intake/USER_BRIEF.md#u13). Parent: [AVE-FEAT-016](../EPICS_AND_FEATURES.md#ave-feat-016).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
