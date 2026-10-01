---
name: implement-requirement
description: Implements one Ready or In Progress requirement with the smallest coherent change and tests tagged REQ-NNN AC-n, runs ./scripts/verify.sh, fills Implementation evidence and ends with the standard implementer report. Used inline by the lead and preloaded by the implementer subagent.
argument-hint: "<REQ-ID>"
---

# implement-requirement

Target: `$ARGUMENTS`. When that is empty or unsubstituted (this skill is preloaded into the implementer subagent), the task message names the target: one `REQ-NNN`, or a tight set under one parent handled together. Below, `REQ-NNN` stands for the target.

Paths are relative to the repository root; dates come from `date -u +%F`. Formats live in `docs/requirements/README.md` and `docs/TRACEABILITY.md`.

## Modes

Lead mode: the main session invokes this skill inline. Implementer mode: you run as the implementer subagent with this skill preloaded.

| Item | Lead mode | Implementer mode |
|---|---|---|
| `## Implementation evidence` of the target | Write it | Write it |
| Status (frontmatter and Status log) | Record the move to `in-progress` (Preconditions) and leave it there | Change none; propose the next status on the report's Requirements line |
| Other requirement files, ADRs, TRACEABILITY.md, PROGRESS.md, ROADMAP.md, ASSUMPTIONS.md | Update them | List the updates under "Shared-document updates for the lead" |
| Commit | The `develop` loop commits after a `verify-requirement` PASS | Only when the task message says so |

In both modes, AC checkboxes and `## Test evidence` stay untouched; the lead fills them after a `verify-requirement` PASS.

## Preconditions

1. The file `docs/requirements/REQ-NNN-*.md` exists.
2. Status is `ready` or `in-progress`.
   - Lead mode: `ready` → record the transition to `in-progress` (`.claude/skills/develop/SKILL.md` § Recording a transition). `proposed` → refine it to Ready first (Definition of Ready). `verification` after a FAIL verdict, or a reopened `done` → transition to `in-progress` with a logged reason. `blocked` or `superseded` → return to the `develop` loop.
   - Implementer mode: any other status → return `## Result: BLOCKED` naming the status.
3. Every requirement under `## Dependencies` is `done`. Otherwise lead: complete it first; implementer: return `BLOCKED`.
4. The Definition of Ready holds: testable ACs, edge cases mapped, verification strategy stated. Lead: close gaps with a logged change. Implementer: implement the unambiguous part and report the gap.

## Procedure

### 1. Read the requirement

Read the whole file: frontmatter (`type`, `priority`, `parent`, `source`), Intent, Description, every AC, Edge cases, Dependencies, Verification strategy. List the ACs; they are your contract.

### 2. Read related requirements

Read the parent FEAT/EPIC, the requirements under Dependencies, and siblings touching the same behavior (`grep -l "<key term>" docs/requirements/REQ-*.md`). Note the interfaces and behavior you must keep intact.

### 3. Inspect architecture and ADRs

Read the `docs/ARCHITECTURE.md` sections for the affected components plus § Testing strategy; read the ADRs the requirement cites and those that cite it (`grep -rl "REQ-NNN" docs/decisions/`). Accepted ADRs and documented module boundaries bind you.

### 4. Understand the existing implementation

Locate the code: `git grep -n -w --untracked "REQ-NNN"`, entry points, neighboring modules, existing tests and fixtures, and project conventions (naming, error handling, logging, test layout). Check for earlier partial work: `git log --oneline --grep='REQ-NNN[:,]'`, `git status`, `git diff`.

### 5. Plan

Write a concise plan in your response (no plan file):
- Files: `path` — intended change.
- Approach: 2–5 lines.
- AC → test: `AC-n` → test file and name, level (unit, integration, end-to-end, inspection).
- Risks and open points.

A plan that needs a new major dependency, a new module boundary, or a data-model change beyond the requirement and its ADRs needs an architecture decision. Lead: consult the architect first (`develop` section 3). Implementer: stop and report it under Deviations.

### 6. Implement the smallest coherent change

1. Implement exactly the ACs. Add no behavior the requirement does not ask for; make no drive-by refactors; never reformat code outside the change.
2. Follow the project's conventions and the boundaries in `docs/ARCHITECTURE.md`.
3. Preserve backward compatibility of public interfaces, data and file formats, persisted data, configuration, and CLI or API contracts unless a requirement or Accepted ADR explicitly allows breaking it. Migrate persisted data when its format changes.
4. Decide details the requirement leaves open by the project's conventions; record each such decision as an assumption (lead) or a proposed assumption in the report (implementer).
5. Optionally anchor the primary entry point with one `REQ-NNN` comment; tag nothing else.
6. Keep secrets out of code, tests and fixtures; read configuration as `docs/ARCHITECTURE.md` § Configuration and secrets specifies.

When practical, write the step 7 tests first and watch them fail.

### 7. Add or update tests

1. Cover every AC with at least one test at the level its Verification strategy names, plus the edge cases mapped to it.
2. Tag every test `REQ-NNN AC-n` in its name or description; use an adjacent comment only when the framework forbids free text there. A test covering several ACs carries every tag.
3. Each test must fail without the change: watch it fail before the implementation exists, or temporarily revert or mutate the behavior, run the test, restore the code, and confirm with `git diff` that no mutation remains.
4. Assert observable outcomes with specific expected values. Mock only external boundaries. Never mock the unit under test. Keep tests deterministic: control time, randomness and network; synchronize without sleeps.
5. An AC verified by inspection: the Verification strategy states why automation is impractical; describe the exact inspection procedure in Implementation evidence for the reviewer.
6. An existing test breaks: when an AC requires the new behavior, update the test and report it; otherwise treat it as a regression and fix the code.

### 8. Run relevant checks

1. Run the targeted tests for each AC (commands in `docs/ARCHITECTURE.md` § Testing strategy), then `./scripts/verify.sh`.
2. Fix root causes and rerun until both pass. Never skip, weaken, filter or delete a check or test.
3. A failure that predates your change and is unrelated to it: lead — record it in `docs/PROGRESS.md` § Known failures, then fix it or create a requirement for it; implementer — report the failing step with the evidence that it is unrelated.
4. Inspect `git status` and `git diff`: every change is in scope and intended; no debug output, stray files or secrets.

### 9. Update traceability

1. Fill `## Implementation evidence` in the requirement file in the format of `docs/requirements/README.md`: implementation files with the ACs they serve, test files with their tags, decisions (ADR and ASM IDs, or "None.").
2. Lead: update the TRACEABILITY.md row's Implementation and Tests cells per `docs/TRACEABILITY.md` § Update rules. Implementer: list the row update in the report.

### 10. Update requirement evidence and status

Confirm that `## Implementation evidence` (step 9) matches the final change. Both modes leave the status `in-progress`: the caller records `in-progress → verification` after any `tester` run and a passing `./scripts/verify.sh`, immediately before `verify-requirement` (`develop` section 6 step 2, which `technical-foundation` step 12 also follows). Implementer: propose the next status on the report's Requirements line. Never declare your own work verified.

### 11. Report follow-up requirements separately

Report discovered work (missing behavior, needed refactors, gaps, contradictions, ambiguous ACs) as proposed follow-up requirements or assumptions, each with a one-line rationale. Lead: create them (`develop` section 10). Keep them out of the current requirement.

## Rules

- The ACs are the contract. Never redefine, reinterpret, weaken or delete an AC to fit the implementation.
  - Lead: change an approved requirement only per `docs/requirements/README.md` § Changing requirements (logged reason; escalate a `source: human` change that alters product intent).
  - Implementer: leave the affected AC open and report it under Deviations with a recommended resolution.
- Fix root causes; never suppress a failing check.
- Never commit secrets or weaken a security check.

## Report

Both modes end with this report; in lead mode, list the shared-document updates you applied. Give exact paths, test locations, commands and results; keep narrative out. Write "None." under an empty heading.

```text
## Result: COMPLETE | PARTIAL | BLOCKED
## Requirements
## Changes (file — purpose)
## Tests (REQ-NNN AC-n → test location)
## Verification (command — result)
## Shared-document updates for the lead
## Deviations, open issues, follow-up requirements
```

- **Result:** `COMPLETE` — every AC implemented and tested, targeted tests and `./scripts/verify.sh` pass. `PARTIAL` — some ACs remain open; Deviations says which and why. `BLOCKED` — no progress possible; the first line under Requirements gives the reason.
- **Requirements:** one line per requirement: `REQ-NNN — <title> — ACs done: AC-n…; open: AC-n… — proposed status <status>`.
- **Changes:** one line per file, `path — purpose`. In a worktree, the first line is `Branch: <name> — commit <hash>` (or `uncommitted`).
- **Tests:** one line per AC, `REQ-NNN AC-n → path::test name`, or `inspection: <procedure>`.
- **Verification:** each command run with PASS or FAIL; for failures, the decisive output lines.
- **Shared-document updates for the lead:** one line per file with the exact change.
- **Deviations, open issues, follow-up requirements:** AC deviations with a recommended resolution; proposed assumptions (assumption, reason, impact); proposed follow-up requirements (title, parent, rationale); pre-existing failures.

```text
- docs/TRACEABILITY.md — REQ-012 row: Implementation `<path/to/module>`; Tests `<path/to/test-file>` (AC-1–AC-3)
- docs/ASSUMPTIONS.md — new entry: <title> — assumption: <…> — reason: <…> — impact: <…>
```
