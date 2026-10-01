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
- **Links:** ADR-NNN, REQ-NNN
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
- **Status:** open — confirm when a session shows the "Project state" block injected by
  [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh); `resume-project` does this.
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
- **Status:** open — confirm with the first green CI run.
- **Links:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)
