---
id: AVE-REQ-073
title: "Multiple containers and codec choices"
type: functional
scope: v1
priority: must
status: ready
parent: AVE-FEAT-017
epic: AVE-EPIC-07
primary_gate: M6
origins: ["U23"]
dependencies: ["AVE-REQ-072"]
scenarios: ["AT-18", "AT-24"]
---

# AVE-REQ-073 - Multiple containers and codec choices

## Requirement

The editor shall offer validated export combinations beyond the default profile and show capability-dependent alternatives honestly.

## Acceptance criteria

- [ ] **AC-1:** The reference software build supports MP4/H.264/AAC, WebM/VP9/Opus, and a documented MKV profile with correct muxing and playback tests.
- [ ] **AC-2:** Additional HEVC, AV1, ProRes/MOV, or other choices are exposed only when installed encoders and output constraints permit them.
- [ ] **AC-3:** The UI distinguishes container, video codec, audio codec, pixel format, quality, and bitrate.
- [ ] **AC-4:** Changing a container revalidates audio/subtitle compatibility rather than only changing the filename extension.

## Dependencies

[AVE-REQ-072](AVE-REQ-072.md)

## Verification plan

[AT-18](../ACCEPTANCE_TESTS.md#at-18); [AT-24](../ACCEPTANCE_TESTS.md#at-24). Implement criterion-level tests and retain actual evidence; a linked scenario is a plan, not a passing test.

## Traceability

[U23](../../intake/USER_BRIEF.md#u23). Parent: [AVE-FEAT-017](../EPICS_AND_FEATURES.md#ave-feat-017).

## Implementation and verification evidence

Not implemented or verified by this package. In the canonical working copy, record implementation paths, test IDs/commands, artifact paths, code/tree fingerprint, execution environment, reviewer findings, and externally blocked criteria. Do not edit this imported baseline to manufacture completion.
