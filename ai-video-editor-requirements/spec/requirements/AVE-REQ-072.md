---
id: AVE-REQ-072
title: "Real export pipeline and default delivery profile"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M1
origins: ["U22", "U23"]
dependencies: ["AVE-REQ-012", "AVE-REQ-048"]
scenarios: ["AT-02", "AT-18", "AT-28"]
---

# AVE-REQ-072 - Real export pipeline and default delivery profile

## Requirement

The product shall render real playable video files from the composition graph, with an initial MP4/H.264/AAC SDR delivery profile and configurable output parameters.

## Acceptance criteria

- [ ] **AC-1:** The initial delivery profile uses the project canvas/rate, normally 1920x1080 at resolved source-appropriate rate, with 48 kHz AAC audio.
- [ ] **AC-2:** Expose quality-based and target-bitrate controls with encoder-specific defaults; use a documented software starting point such as CRF 20 rather than claiming universal optimality.
- [ ] **AC-3:** Render video, selected audio, layouts, transforms, transitions, effects, and chosen captions; a downloaded project JSON is not a rendered video.
- [ ] **AC-4:** Outputs are written atomically and become downloadable only after validation succeeds.

## Dependencies

[AVE-REQ-012](AVE-REQ-012.md); [AVE-REQ-048](AVE-REQ-048.md)

## Verification plan

[AT-02](../ACCEPTANCE_TESTS.md#at-02); [AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-28](../ACCEPTANCE_TESTS.md#at-28). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U22](../../intake/USER_BRIEF.md#u22); [U23](../../intake/USER_BRIEF.md#u23). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
