# Assumptions

Missing information that does not justify interrupting the human becomes a recorded
assumption here. Escalation criteria: [CLAUDE.md](../CLAUDE.md) § Autonomy and escalation.

## Rules

1. Make a reasonable, industry-standard assumption; record it here; continue.
2. Record it before, or in the same commit as, the work that relies on it, and cite its
   `ASM-NNN` in that requirement or ADR.
3. Allocate the next free `ASM-NNN` and append the entry at the end. Never reuse, renumber or
   delete entries.
4. Change **Status** in place and append ` — YYYY-MM-DD — <evidence or link>`.
5. When an assumption becomes a requirement or ADR, set `superseded` and add the REQ/ADR to
   **Links**.
6. When an assumption proves false, set `invalidated`, add the follow-up (new requirement, ADR
   change or re-plan) to **Links**, and repair the affected work.
7. `milestone-review` revisits every `open` assumption: confirm, invalidate, supersede, or keep
   it open with a reason.
8. An assumption that would materially change the intended product is a question for the
   human: escalate it and track it in [PRODUCT.md](PRODUCT.md) § Open product questions.

## Entry format

```
### ASM-NNN — Short title
- **Date:** YYYY-MM-DD
- **Assumption:** what is taken as true
- **Reason:** why it is reasonable and why the human was not asked
- **Impact:** what changes if it proves false
- **Status:** open | confirmed | invalidated | superseded
- **Links:** ADR-NNN, AVE-REQ-NNN
```

## Status meanings

- `open` — in effect, unverified.
- `confirmed` — validated by evidence or by the human.
- `invalidated` — proven false; follow-up recorded.
- `superseded` — became a requirement or ADR; linked.

## Entries

### ASM-001 — Project hooks activate after workspace trust
- **Date:** 2026-10-01
- **Assumption:** Future sessions load the SessionStart and Stop hooks from
  [.claude/settings.json](../.claude/settings.json) once the workspace is trusted.
- **Reason:** The bootstrap session created the hooks mid-session and could not exercise them.
- **Impact:** If false, the verification gate and recovery context fall back to
  [CLAUDE.md](../CLAUDE.md) instructions and CI.
- **Status:** confirmed — 2026-10-01 — the resumed session showed the "Project state" block injected by
  [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh) (source: resume).
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-002 — Baseline tooling
- **Date:** 2026-10-01
- **Assumption:** `bash` (3.2+), `git`, and POSIX `awk`, `grep` and `sed` exist wherever
  verify.sh and the hooks run (Linux, macOS, WSL/Git Bash).
- **Reason:** These tools ship with mainstream development environments and CI runners, so
  the scripts need no further dependencies.
- **Impact:** If false, verification needs a POSIX shell environment on that machine.
- **Status:** open
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-003 — GitHub hosts the repository and runs CI
- **Date:** 2026-10-01
- **Assumption:** GitHub hosts the canonical repository (`github.com/theUpsider/AI-Video-Editor`)
  and GitHub Actions runs CI.
- **Reason:** The configured Git remote points to that GitHub repository.
- **Impact:** If false, port [.github/workflows/verify.yml](../.github/workflows/verify.yml) to
  the actual CI system; it only runs `./scripts/verify.sh`.
- **Status:** confirmed — 2026-10-01 — first CI run green on commit f605c6c
  (https://github.com/theUpsider/AI-Video-Editor/actions/runs/36851238702).
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)

### ASM-004 — Baseline interpretation register adopted
- **Date:** 2026-10-01
- **Assumption:** The baseline's interpretation register (ASM-01 to ASM-20 in
  [SCOPE_AND_ASSUMPTIONS.md](../ai-video-editor-requirements/spec/SCOPE_AND_ASSUMPTIONS.md)) holds for this
  implementation: self-hosted single-owner browser editor with a media worker; probed (never assumed)
  dimensions/rates; unconfirmed "DJI Go" device terminology; contain/padding as the default square layout; Auto
  output rate from the reference source with a 1080p 16:9 canvas; final audio separate from sync evidence; common
  coverage for split segments; evidence-dependent sync; ASR scope without dubbing/diarization; bounded indexing as
  the version-one foundation; distinct caption/metadata products; 1:1 15–20 s shorts; agent runtimes distinct from
  models; no inherited credentials; CPU mandatory and GPU conditional; no social publishing; consented, budgeted
  external compute; environment-discovered versions; defaults changeable only by ADR.
- **Reason:** The human supplied the register with the requirements; it resolves every ambiguity the brief leaves.
- **Impact:** If the human revises any entry, apply it through `product-definition` amendment mode.
- **Status:** open
- **Links:** [ADR-002](decisions/ADR-002-technology-stack.md), [ADR-003](decisions/ADR-003-requirements-baseline-import.md)

### ASM-005 — Synthetic fixtures stand in for real camera footage
- **Date:** 2026-10-01
- **Assumption:** Deterministic, clearly labeled synthetic media (markers, flashes, impulses, pilot tones,
  synthesized speech) is sufficient evidence for timing, geometry, routing and caption criteria; it never
  represents the user's real footage.
- **Reason:** No user footage, camera model or color profile was supplied; the baseline requires generated
  fixtures with independent ground truth.
- **Impact:** Real-footage behavior (camera color profiles, real-world sync evidence quality) stays a reported gap
  until footage is supplied.
- **Status:** open
- **Links:** [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md)

### ASM-006 — The development container is no deployment target
- **Date:** 2026-10-01
- **Assumption:** The measured Claude Code container ([ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md))
  is a build/test environment with no GPU, no Docker daemon, no product credentials and no Hugging Face access.
  Live provider, agent-runtime, vision, translation, multilingual ASR, container and GPU criteria are implemented
  and contract-tested here and reported as externally unverified with exact prerequisites.
- **Reason:** Measured network policy and device checks.
- **Impact:** If the environment gains access, rerun the corresponding live tests and update the matrix.
- **Status:** confirmed — 2026-10-01 — measured
- **Links:** [ADR-007](decisions/ADR-007-ai-integration-boundaries.md), [ADR-008](decisions/ADR-008-local-speech-recognition.md)

