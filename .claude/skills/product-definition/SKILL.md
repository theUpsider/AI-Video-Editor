---
name: product-definition
description: Turns the human's product prompt into the canonical specification — PRODUCT.md, goals, user journeys, epics, features and requirements with acceptance criteria, assumptions, architectural drivers and the initial roadmap. Use when a product prompt arrives, when the human adds, changes or removes goals or must-haves (amendment mode), or to resume an interrupted product definition.
argument-hint: "[product prompt text | path to a file holding it]"
---

# Product definition

Turn high-level human input into a specification coherent enough to guide development, then hand off. You act as product lead. Record every result in repository files as you produce it.

Input: `$ARGUMENTS` holds the product prompt or a path to a file holding it. When it is empty, use the product input in the human's latest messages.

## Rules

- Scope inferred capabilities by the inclusion rule: «Include what is required to make the requested product coherent, reliable, usable, and production-quality. Avoid speculative features that do not support an identified user need.»
- The human's words are authoritative. Keep their wording for must-haves and constraints, give their requirements `source: human`, and never silently alter human-sourced content.
- Stay technology-neutral. Select no language, framework, database, AI provider, deployment platform or media-processing stack; `technical-foundation` does that. A technology the human mandates becomes a `type: constraint` requirement with `source: human`.
- Write no product code. Implementation starts after `technical-foundation`.
- Formats: requirement files per [docs/requirements/README.md](../../../docs/requirements/README.md) (templates, next-free-ID command, Definition of Ready); assumptions per [docs/ASSUMPTIONS.md](../../../docs/ASSUMPTIONS.md); IDs and escalation per [CLAUDE.md](../../../CLAUDE.md). Dates come from `date -u +%F`.
- Escalate only under CLAUDE.md § Autonomy and escalation. Everything else: decide, record an `ASM-NNN`, continue.
- Checkpoint: after each step through step 15, keep one line in PROGRESS.md § In progress. Initial mode: `product-definition — initial — step <N> of 17 done — input <file>`. Amendment mode counts § Amendment mode steps: `product-definition — amendment — amendment step <A> of 9 done — input <file>`, and while amendment step 3 or 9 runs main steps, `product-definition — amendment — in amendment step <A>, step <N> of 17 done — input <file>`. A compacted session resumes at the next step of the procedure the line names. Step 16 deletes it (an emptied section reads `None.`).
- Before ending any turn, including one that asks the human questions, make `./scripts/verify.sh` pass; the Stop gate runs it.

## Preconditions

1. Inspect `git status --short`. Commit unrelated completed work separately first. A requirement in `in-progress` or `verification` keeps its code and tests uncommitted, because develop commits a requirement only after its PASS; commit only its recorded transition (its requirement file, `docs/TRACEABILITY.md`, `docs/PROGRESS.md`, parent status edits) as `AVE-REQ-NNN: start implementation`. An interrupted run keeps its own pending changes.
2. `./scripts/verify.sh` passes; fix defects before starting.
3. Determine the mode; the first match wins:
   - A `product-definition —` line in PROGRESS.md § In progress, or PRODUCT.md status `placeholder` with a file in `docs/product-inputs/`: an interrupted run. Resume at the step after the one that line names, in the procedure it names: an `amendment step <A> of 9` line resumes at amendment step A+1; an `in amendment step <A>, step <N> of 17` line resumes at step N+1 inside amendment step A (default: the first step whose output is missing).
   - PRODUCT.md status `placeholder` (`grep -m1 '^\*\*Status:\*\*' docs/PRODUCT.md`): initial mode.
   - PRODUCT.md status `defined …` and the input is already recorded verbatim in a committed `docs/product-inputs/` file: it is processed; record nothing and follow [resume-project](../resume-project/SKILL.md) step 8 rules 2–6.
   - PRODUCT.md status `defined …`: amendment mode (§ Amendment mode below).
4. No product input available: tell the human the repository is ready for the product prompt, and stop.

## Procedure

### Step 1 — Record the verbatim input
Create `docs/product-inputs/YYYY-MM-DD-<slug>.md` (slug: two to five words naming the topic; pick another slug when the name exists):

```markdown
# Product input — YYYY-MM-DD — <short title>

- **Received:** YYYY-MM-DD — <session message | path of the file provided>
- **Mode:** initial | amendment

## Verbatim input

<the input, unedited, inside a fenced code block tagged text>
```

The fence keeps links in the human's text out of the link check; when the input contains its own fence lines, use a longer fence (four backticks). Never edit this file afterwards; later input gets a new file. Every citation of human input links to it.

### Step 2 — Extract explicit must-haves (user step 1)
List every explicit item in the input and classify it: must-have capability, quality expectation, constraint (platform, mandated technology, compliance, budget, deadline) or exclusion. Keep the human's wording. Write must-haves into PRODUCT.md § Must-have features, one line each; the FEAT link follows in step 8:

```markdown
- "<human wording>" — [YYYY-MM-DD-<slug>](product-inputs/YYYY-MM-DD-<slug>.md) → [AVE-FEAT-NNN](requirements/AVE-FEAT-NNN-<slug>.md)
```

Collect every ambiguity and gap for step 10.

### Step 3 — Frame the product
Fill PRODUCT.md § Product vision, § Problem statement, § Target users and § Product goals: three to seven `GOAL-NNN` rows, each with an observable, measurable success signal. Every must-have serves at least one goal. Update the Working title line when the input names the product.

### Step 4 — Core user journeys (user step 2)
Write one `### UJ-NNN — Title` subsection per journey in PRODUCT.md § Core user journeys: actor, trigger, numbered steps, successful outcome, key failure paths, related `GOAL-NNN` (features follow in step 8). Every must-have capability appears in at least one journey step. Add the implied journeys the human left unstated: first use, recovery from errors, managing what the user created.

### Step 5 — Baseline capabilities (user step 3)
Walk [baseline-capabilities.md](baseline-capabilities.md) category by category. Include a capability only when it serves a named journey step, goal or must-have; it becomes `source: derived` work in step 7. Record notable skips a reader would expect in § Explicit non-goals with the reason.

### Step 6 — Boundaries and non-goals (user steps 4–5)
Fill PRODUCT.md § Product boundaries, § Explicit non-goals (one bullet each, with the reason), § UX principles, § Security and privacy expectations, § Performance expectations (measurable targets with their conditions) and § Deployment assumptions (how users obtain and run the product; no technology choice).

### Step 7 — Functional and non-functional requirements (user step 6)
Group behavior into functional areas, one per future epic, in PRODUCT.md § Functional areas. Per area list: functional requirements (observable behavior per journey step, including error paths), non-functional requirements (measurable thresholds from § Security and privacy, § Performance and step 5) and constraints. Size each to one focused session (README § Sizing and splitting).

### Step 8 — Epics, features and requirements (user step 7)
Create the files from the README templates, parents first:
1. `AVE-EPIC-NN` per functional area; `goals` lists its GOAL IDs.
2. `AVE-FEAT-NNN` per user-visible capability, `parent: AVE-EPIC-NN`; § User journey names its UJ steps.
3. `AVE-REQ-NNN` per requirement, `parent: AVE-FEAT-NNN` (or `AVE-EPIC-NN` for a cross-cutting non-functional requirement). `source: human` when it implements a stated must-have or constraint, with Intent linking `../product-inputs/<file>.md`; otherwise `source: derived`, with Intent naming the need it serves.

Every parent lists its children with relative links. First Status line: `- YYYY-MM-DD — proposed — specified from <input file name> (product-definition)`. Complete the FEAT links in PRODUCT.md § Must-have features, § Functional areas (EPIC per area) and each journey.

### Step 9 — Acceptance criteria (user step 8)
Write ACs per README § Writing requirements: observable, one behavior each, covering success, error and boundary behavior; non-functional ACs state metric, threshold, conditions and measurement method. Fill Edge cases, Dependencies and Verification strategy as far as known. Every REQ gets at least one AC now; detail beyond that scales with the milestone (step 12). Give every FEAT § Feature acceptance and EPIC § Success criteria at least one end-to-end check.

### Step 10 — Assumptions and questions (user step 9)
Resolve every gap from step 2 onward:
- Answerable by industry practice: add an `ASM-NNN` entry, cite it in the requirements it shapes, and list the question in PRODUCT.md § Open product questions as `→ ASM-NNN`.
- Meets an escalation criterion: list it as `→ escalated YYYY-MM-DD` and queue it for one batched message (question, impact, recommended default), sent at step 17. When the answer is reversible, proceed on the recommended default, recorded as an `open` assumption. Keep requirements that a different answer would invalidate `proposed` and out of M1 where possible.

### Step 11 — Architectural drivers (user step 10)
Fill docs/ARCHITECTURE.md § Architectural drivers: one bullet per quality attribute, constraint or risk that shapes the design (users and scale, data sizes and volumes, latency, long-running work, privacy, platforms, external services, cost), each with its source ID. Replace only that section's `_TBD` line; the other sections belong to `technical-foundation`. Name a technology only when a human constraint mandates it.

### Step 12 — Initial roadmap (user step 11)
In docs/ROADMAP.md, replace § Product phases with `## Phase <n> — Name` headings (n ≥ 2) holding milestone entries from the template, following its § Planning rules:
1. **M1 — walking skeleton:** the thinnest end-to-end slice of one core journey through every layer. Its first requirement is the slice `technical-foundation` scaffolds. Detail M1 fully; status `planned`.
2. **Later milestones:** outcome, exit criteria, features and `proposed` requirements in dependency order, each ending in a demonstrable user-visible outcome.
3. Order by dependencies, then priority (`must` before `should` before `could`).
4. Bring every M1 requirement to the Definition of Ready and set it `ready` (frontmatter and Status log: `- YYYY-MM-DD — ready — Definition of Ready met (product-definition)`); set FEAT and EPIC status per README § Status lifecycle rule 6. Later requirements stay `proposed`; `milestone-review` refines them just in time.
5. Set the Phase 1 entry to `done — YYYY-MM-DD` and replace its `_TBD` line with links to the input file and PRODUCT.md.
6. Add a Re-planning log row directly below the table's separator row, deleting its blank line and `_No entries yet._`: initial roadmap M1–M<n>, reason: product-definition from the input file.

### Step 13 — Synchronize canonical documents (user step 12)
1. PRODUCT.md: replace the Status line with `**Status:** defined — YYYY-MM-DD` and the "Before substantial implementation begins" note with an Inputs line linking each input file (amendment mode: keep the Status and Inputs lines amendment step 8 set); fill the product-specific criteria in § Definition of product completion. `grep -n '^_TBD' docs/PRODUCT.md` prints nothing; a section with nothing to state says `None.` with the reason.
2. TRACEABILITY.md § Goal coverage: one row per GOAL with links to its epics, directly below that table's separator row, deleting its blank line and `_No entries yet._`. Requirement matrix rows start when work starts (`develop`).
3. PROGRESS.md: current milestone M1 (planned); objective `technical-foundation` (amendment mode: the current milestone and objective after the amendment step 7 re-plan); next recommended work; decisions and open escalations; verification status.

### Step 14 — Independent specification critique
Spawn the `reviewer` subagent (fresh context) with this task:

```text
Critique the product specification only; any existing implementation is out of scope. Read
docs/product-inputs/*.md (an input whose Mode is amendment overrides earlier inputs for each item
it changes or removes; judge every item against its newest statement), docs/PRODUCT.md,
docs/ROADMAP.md, docs/ASSUMPTIONS.md, docs/ARCHITECTURE.md § Architectural drivers
and docs/requirements/*.md.
Check: (1) every human must-have and constraint, in its newest statement, maps to a source: human
requirement, with nothing lost or altered (a removed one maps to the removal constraint that
supersedes it); (2) gaps: journey steps, error paths and baseline needs without requirements;
(3) contradictions between input, goals, non-goals, requirements and assumptions; (4) vague or
untestable ACs, non-functional requirements without thresholds; (5) scope inflation: requirements
serving no identified need, enterprise features in a small product; (6) M1 is a real vertical slice
and every M1 requirement meets the Definition of Ready in docs/requirements/README.md; (7) technology
choices made before technical-foundation; (8) broken hierarchy: parents missing children, goals
without epics (goals marked retired excepted). Use your verdict format with "Requirement: none —
product specification", one row per check in § Acceptance criteria, and path:line locations.
Modify no files.
```

Fix every blocking finding. Apply cheap non-blocking fixes; record the rest as assumptions or `proposed` requirements. Rerun the critique when fixes were substantial; after three rounds, escalate any blocking item still open.

### Step 15 — Exit check: sufficient clarity
Proceed when every item holds; then stop elaborating.
- [ ] The input is recorded verbatim and cited.
- [ ] PRODUCT.md has no placeholder line (`grep -n '^_TBD' docs/PRODUCT.md` prints nothing); every must-have links to a feature covered by `source: human` requirements.
- [ ] Every GOAL not marked `retired` has a measurable success signal and at least one epic; Goal coverage is complete.
- [ ] Every core journey step maps to features; every parent lists its children.
- [ ] Every derived requirement names the need it serves.
- [ ] M1 is a walking skeleton and all its requirements are `ready`.
- [ ] Later milestones have outcome, exit criteria and `proposed` requirements with at least one AC each.
- [ ] Architectural drivers are recorded; no technology is selected beyond human constraints.
- [ ] Every open question is resolved as `→ ASM-NNN` or `→ escalated YYYY-MM-DD`.
- [ ] The critique has no open blocking finding.

Over-elaboration signals: full ACs for later milestones, screen layouts, library choices, requirements for hypothetical users. Leave that detail to just-in-time refinement.

### Step 16 — Verify and commit
1. Run `./scripts/verify.sh`; fix failures at the root.
2. Inspect `git status` and `git diff`: only specification files changed, apart from an unfinished requirement's uncommitted code and tests (precondition 1).
3. Delete the `product-definition —` line from PROGRESS.md § In progress and commit at once, so an interrupted run never loses its checkpoint before the commit: stage the specification files by path (`git add docs/`; never `git add -A`) and commit: `docs: define product specification from <input slug>` (amendment: `docs: amend product specification from <input slug>`).

### Step 17 — Hand off
Report to the human in at most 15 lines: goals, counts of epics, features and requirements, M1 scope, key assumptions, and the batched escalation questions with recommended defaults. Then continue without waiting:
- `docs/ARCHITECTURE.md` status `placeholder`: run [technical-foundation](../technical-foundation/SKILL.md). When an open escalation would change a stack decision needed now, finish the independent work and wait for the answer.
- Stack already selected: run [develop](../develop/SKILL.md).

## Amendment mode

New product input arrives after PRODUCT.md is defined.
1. Run step 1 (mode `amendment`).
2. Classify each item against the current specification as addition, clarification, change or removal. Find affected IDs with `grep -rn` across `docs/`.
3. Additions: run steps 2–11 for the delta only. Allocate next free IDs; never renumber.
4. Clarifications and changes the human states explicitly are authorized; apply them and cite the new input file:
   - `proposed` requirement: edit it and log the change in `## Status`.
   - Approved (`ready` or later): log `- YYYY-MM-DD — <status> — <change> per <input file> (product-definition)` with the edit; a `done` requirement reopens to `in-progress` with the affected ACs unticked.
   - Replacement behavior: supersede per README § Superseding.
5. Removals: create one requirement (`type: constraint`, `source: human`, `parent:` the EPIC that held the removed capability) stating the removal and how existing behavior and data are handled, and supersede each removed requirement with it. A FEAT or EPIC whose children, apart from that removal requirement, are all superseded gets `status: superseded` and `superseded_by: <removal REQ ID>`. In PRODUCT.md, move the must-have line from § Must-have features to § Explicit non-goals citing the input file, and drop the capability from the § Core user journeys steps that used it. A GOAL that no remaining epic serves keeps its row (IDs are never reused): append `retired YYYY-MM-DD — <input file>` to its Success signal cell and drop it from the `goals` of epics that are not superseded.
6. Input that contradicts existing `source: human` content without explicitly changing it: escalate with your recommended reading; leave the affected requirements unchanged meanwhile and continue independent work.
7. Re-plan: place new and changed requirements by dependency and priority; leave the in-progress requirement undisturbed unless the change targets it; bring new requirements of the current milestone to `ready`; add one Re-planning log row per change.
8. PRODUCT.md: update the touched sections, set the Status line to `**Status:** defined — <first date>; amended YYYY-MM-DD`, and add the input file to the Inputs line. Update § Architectural drivers when they change; when a change invalidates an Accepted ADR, record a follow-up for the architect in PROGRESS.md § Next recommended work.
9. Run steps 13–17 scoped to the delta and its interactions, keeping the Status line set in step 8; the critique checks the amended parts and everything they touch. Hand off to the work PROGRESS.md names, usually `develop`.
