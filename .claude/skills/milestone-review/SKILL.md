---
name: milestone-review
description: Product-level review at the end of a milestone. Runs full verification, re-checks completed requirements and their acceptance criteria, tests key user journeys end to end, compares the product with docs/PRODUCT.md, runs architecture-review, audits markers, dependencies, assumptions, traceability, dead code and debt, records a PASS or FAIL verdict and re-plans the roadmap.
when_to_use: When every requirement of the current milestone is done (develop invokes it), for the final product review once every milestone is done (`final`), or on demand as a product health check.
argument-hint: "[M<n> | final]"
---

# Milestone review

Purpose: prevent local task success while the product as a whole drifts. `verify-requirement` proves each requirement; this review proves that the delivered requirements add up to the product `docs/PRODUCT.md` defines, that the codebase stays coherent, and that the plan still fits.

You are the lead and run this inline. Paths are relative to the repository root; dates come from `date -u +%F`.

Scope argument: `$ARGUMENTS`
- empty: the `in-progress` milestone in `docs/ROADMAP.md` (PROGRESS.md § Current milestone names it). When no milestone is in progress and every milestone is `done`, run in final mode; otherwise report that no milestone is in progress and stop.
- `M<n>`: that milestone.
- `final`: final mode. Scope is the whole product: every milestone, requirement and core user journey, plus `docs/PRODUCT.md` § Definition of product completion. Below, read "the milestone" as the whole roadmap.

Preconditions: `grep -m1 '^\*\*Status:\*\*' docs/PRODUCT.md docs/ARCHITECTURE.md` shows PRODUCT.md `defined` and ARCHITECTURE.md past `placeholder`. Otherwise there is nothing to review yet: run `resume-project`, which routes to the missing step.

## Rules

1. **Durable findings.** Record each confirmed finding at once in its durable home: a reopened or new requirement, a `docs/ASSUMPTIONS.md` entry, an ADR, `docs/ARCHITECTURE.md` § Risks and technical debt, or `docs/PRODUCT.md` § Open product questions. Keep a running list of the IDs for the Review line.
2. **Change scope.** Fix documentation and traceability inconsistencies in place. Route every behavior change through a requirement (reopened or new). Code edits inside this review are limited to marker comments (step 8) and local dead-code removal (step 12).
3. **Integrity.** Never weaken, skip or delete a check, test or acceptance criterion to reach PASS.
4. **Checkpoint.** After each step through step 17, keep one line in PROGRESS.md § In progress reading `milestone-review M<n> — step <N> of 18 done — follow-ups: <IDs | none> — re-verified: <IDs | none | pending> — journeys: <UJ-NNN PASS|FAIL, … | pending> — architecture: <HEALTHY|ATTENTION|ACTION-REQUIRED, <n> blocking, <n> important | pending> — rejected: <recommendation: reason; … | none | pending>` (final mode: `milestone-review final — …`). The line holds the results that step 18 reports and commits but that have no other durable home. A resumed session continues at the next step. Step 18 deletes the line (an emptied section reads `None.`) after copying it into the commit body.
5. **Context.** Load only what each step needs; read long output through `tail` or `grep`. Re-verification and architecture review run in forks and return reports only.
6. **Escalation.** Only under `CLAUDE.md` § Autonomy and escalation: finish independent work first, then ask once, batched, each question with a recommended default.

## Exit criteria (verdict PASS)

- [ ] Every non-superseded requirement in the milestone is `done`, and steps 3 and 4 confirm it.
- [ ] The exit criteria in the milestone entry hold, and so does every `## Feature acceptance` item of its features.
- [ ] Every core user journey the milestone delivers or touches, and every journey delivered earlier, passes end to end through its delivered steps: the `UJ-NNN` steps named in the `## User journey` sections of the features in this and earlier milestones. Steps that later milestones deliver are out of scope; final mode checks every step.
- [ ] `./scripts/verify.sh --tier release` passes on the final tree.
- [ ] No blocking finding remains open, architecture-review findings included.
- [ ] Final mode only: every item of `docs/PRODUCT.md` § Definition of product completion holds.

Any unmet item makes the verdict FAIL.

## Procedure

### 1. Scope and baseline

1. Read the milestone entry (`grep -n '^### M' docs/ROADMAP.md`, then that range): outcome, exit criteria, features, requirements, dependencies. Final mode: list every status with `grep -H '^status:' docs/requirements/*.md`.
2. List the status of every listed feature and requirement, and catch requirements of those features missing from the entry:

   ```sh
   for id in AVE-FEAT-NNN AVE-REQ-NNN AVE-REQ-NNN; do grep -H -m1 '^status:' docs/requirements/"$id"-*.md; done
   grep -l -E '^parent: (AVE-FEAT-NNN|AVE-FEAT-NNN)$' docs/requirements/AVE-REQ-*.md
   ```

3. Determine the base commit, the end of the previous milestone (final mode: the root commit):

   ```sh
   base=$(git log -1 --format=%H --grep='^docs: complete milestone M<n-1> review')
   [ -n "$base" ] || base=$(git rev-list --max-parents=0 HEAD | tail -n 1)
   echo "base $base"; git log --oneline "$base"..HEAD | wc -l; git diff --stat "$base"..HEAD | tail -n 1
   ```

   Shell variables do not persist between Bash calls or across a resume. Where a later step writes `<base>`, use the hash printed here. After a resume, re-run the first two lines and `echo "$base"`.

### 2. Run full verification

1. Run `./scripts/verify.sh --tier release` and keep its summary.
2. When `gh` is available and the remote is GitHub, check CI for HEAD: `gh run list --commit "$(git rev-parse HEAD)" --limit 1`.
3. A failure is blocking. Record it (reopen the responsible requirement, or create a `proposed` requirement for the fix; PROGRESS.md § Known failures when it needs the human) and continue the review to surface every other finding.

### 3. Compare implementation to requirements

1. Each listed requirement is `done`, or `superseded` with its `superseded_by` replacement listed or `done`. Each unfinished requirement is blocking.
2. Each feature and epic in scope has the status that `docs/requirements/README.md` § Status lifecycle rule 6 derives from its children.
3. Behavior without a requirement: from `git diff --stat <base>..HEAD` (the hash step 1.3 printed), list user-facing entry points added in the milestone (commands, routes, screens, public interfaces). Each traces to a requirement through `docs/TRACEABILITY.md` or a `AVE-REQ-NNN` anchor. Untraced substantial behavior gets a `proposed` requirement: one that specifies it, or one that removes it when `docs/PRODUCT.md` § Explicit non-goals excludes it.

### 4. Verify the supposedly completed acceptance criteria

For each `done` requirement in scope:
1. Every AC is ticked; `## Test evidence` has a line per AC and no `_TBD`; the `docs/TRACEABILITY.md` row reads `done` with Evidence filled.
2. Every AC has a tagged test or a recorded inspection:

   ```sh
   python3 -B scripts/evidence.py show AVE-REQ-NNN AVE-REQ-NNN --tier release --require-fresh --require-complete
   ```

   The command reads the release run of step 2 (test markers and comment tags; a grep of the tag would also
   match fixture text). An AC shown `missing` has no test: it needs an `inspection` line in `## Test evidence`
   whose `## Verification strategy` line names inspection, and then reads `inspected`; otherwise it is
   unevidenced (blocking). An exit status other than 0 is blocking.
3. The tagged tests ran and passed in step 2: the runner output shows them executed, none skipped.
4. Re-run `verify-requirement AVE-REQ-NNN` (a fresh reviewer fork) for each requirement that is high-risk (security, data integrity, parsing, state machines, concurrency, media or file-format handling), that has an AC verified by inspection (no test re-runs it, so only the fork re-performs that inspection on the current tree), or that is doubtful: its implementation files changed after its completion commit (`git log --oneline "$(git log -1 --format=%H --grep='AVE-REQ-NNN[:,]')"..HEAD -- <paths from § Implementation evidence>`), its tests changed later, or a journey failure in step 5 points at it. In a re-verification, the reviewer's notes on `done` status and ticked ACs are expected; ignore them. Add each re-verified ID to the checkpoint's `re-verified:` field.
5. A FAIL verdict reopens the requirement (`done → in-progress`, logged reason, affected ACs unticked, TRACEABILITY.md and PROGRESS.md updated) and is blocking.
6. For each non-superseded feature whose non-superseded requirements are all `done`: set it `verification`, check every `## Feature acceptance` item end to end (step 5 often covers it), tick the items that hold, and set the feature `done` when all hold. For each non-superseded epic whose non-superseded children are all `done` (its features and its cross-cutting requirements: `grep -l '^parent: AVE-EPIC-NN$' docs/requirements/AVE-REQ-*.md`): set it `verification`, check every `## Success criteria` item, and set the epic `done` when all hold. An unmet item is blocking: create a requirement for the gap.

### 5. Test key user journeys end to end

Journeys in scope: the `UJ-NNN` that the milestone's features (`## User journey`) and exit criteria name, plus every journey delivered by earlier milestones as regression. Final mode: every journey in `docs/PRODUCT.md` § Core user journeys. A journey's delivered steps are those named in the `## User journey` sections of the features in this and earlier milestones; steps that later milestones deliver are out of scope and never a failure. Final mode: every step.

For each journey:
1. Run its end-to-end or smoke tests (find them through the exit criteria, `docs/ARCHITECTURE.md` § Testing strategy, or `git grep -n -w "UJ-NNN" -- ':!*.md'`).
2. Walk it on the running application as its actor would: each journey the milestone delivered at least once, and every journey without automated end-to-end coverage. Start the app with the commands in `docs/ARCHITECTURE.md` § Local development, follow its delivered steps and their key failure paths in `docs/PRODUCT.md`, use scratch data outside the repository, and stop the app afterwards.
3. Record PASS or FAIL, the method (test name or walk-through) and observed failures. Add `UJ-NNN PASS|FAIL` to the checkpoint's `journeys:` field; a failure's details go into the requirement you reopen or create.

A failing journey is blocking: reopen the responsible requirement or create one. A journey without automated end-to-end coverage gets a follow-up requirement for it, blocking when the milestone's exit criteria demand that coverage.

### 6. Compare the product with PRODUCT.md

Read only the sections the delivered scope touches: § Product goals, § Must-have features, § Product boundaries, § Explicit non-goals, § UX principles, § Security and privacy expectations, § Performance expectations.
1. **Goals:** each success signal the milestone's epics serve moves as planned and can be observed in the product as built.
2. **Must-haves:** those scheduled up to this milestone behave as the human stated them (verbatim input in `docs/product-inputs/`).
3. **Boundaries and non-goals:** nothing was built outside them. Scope creep is a finding: a `proposed` requirement removes the behavior, or escalate when the human may want it kept.
4. **Expectations:** UX principles, security and privacy, and performance targets hold in what step 5 showed; measure the targets that have non-functional requirements.
5. **Direction of drift:** the product deviates from PRODUCT.md → requirement (blocking when a must-have breaks); PRODUCT.md is outdated by a decision already taken → update it with the reason in the commit body; a change to human-stated intent → escalation or `product-definition` amendment mode.

Final mode: check every item of § Definition of product completion; each unmet item is blocking and gets a follow-up requirement.

### 7. Inspect architecture drift

1. Invoke the `architecture-review` skill with `M<n>` (final mode: no argument, the whole repository). It forks the architect and returns a report whose first line is `ARCHITECTURE: HEALTHY | ATTENTION | ACTION-REQUIRED`. Copy the verdict and the blocking and important counts into the checkpoint's `architecture:` field.
2. Decide every finding and recommendation:
   - blocking → a requirement in the current milestone, or an in-place fix when only documentation drifted;
   - important → a requirement in the next milestone, an ADR action, or an ARCHITECTURE.md update;
   - minor → an entry in `docs/ARCHITECTURE.md` § Risks and technical debt, or dropped;
   - ADR supersession or a missing ADR → have the architect draft it as `Proposed`, then accept it per `docs/decisions/README.md` § Who writes, plus § Superseding when it replaces an ADR.
3. Record every rejected or dropped recommendation with a one-line reason in the checkpoint's `rejected:` field, for the review commit body.
4. Apply the accepted ARCHITECTURE.md corrections now.

### 8. Inspect TODO and FIXME markers

```sh
git grep -n -I -w --untracked -E 'TODO|FIXME|HACK|XXX' -- ':!*.md'                              # all markers
git grep -n -I -w --untracked -E 'TODO|FIXME|HACK|XXX' -- ':!*.md' | grep -v -E 'AVE-REQ-[0-9]{3,}'  # unlinked
```

After this step every marker is resolved or linked to a live requirement in the form `TODO(AVE-REQ-NNN): <what>`:
- unlinked: create a `proposed` requirement (or a technical-debt entry for non-behavioral cleanup) and add its ID; delete an obsolete marker;
- linked to a `done` or `superseded` requirement: stale; delete it, or create a requirement when the work is still missing;
- describes a defect in a `done` requirement's AC: reopen that requirement (blocking).

### 9. Inspect dependency issues

1. Vulnerabilities: confirm the security-scan step of verify.sh ran in step 2. Run the stack's dependency audit, outdated and license-listing commands read-only. When `docs/ARCHITECTURE.md` § Cross-cutting concerns § Security lacks them, find the ecosystem's standard commands (researcher for anything unclear) and record them there for later reviews.
2. Classify:
   - known vulnerability reachable from product code → blocking; upgrade requirement in the current milestone;
   - outdated major versions, unmaintained or deprecated packages → follow-up requirement; an ADR when a major dependency is replaced;
   - license incompatible with the product or its deployment (`docs/PRODUCT.md` § Product boundaries, § Deployment assumptions) → escalate (legal or business information);
   - unused dependency → step 12.
3. Lockfiles exist, are committed and match the manifests.

### 10. Inspect unresolved assumptions

```sh
sed -n '/^### ASM-/h; /^- \*\*Status:\*\* open/{x;p;x;}' docs/ASSUMPTIONS.md | grep -v 'ASM-NNN'   # open entries
```

Settle each open assumption per `docs/ASSUMPTIONS.md` § Rules, appending ` — YYYY-MM-DD — <evidence or link>` to its Status:
- evidence now exists (code, test, CI run, human statement) → `confirmed`;
- proven false → `invalidated` with a follow-up (requirement, ADR change or re-plan); blocking when a `done` requirement relies on it;
- became a requirement or ADR → `superseded` with the link;
- otherwise it stays `open` with a dated note naming what will settle it.

Check `docs/PRODUCT.md` § Open product questions: each is resolved or escalated; list unanswered escalations in the report. Final mode: an open assumption affecting a must-have feature is blocking.

### 11. Inspect incomplete traceability

1. `scripts/check-project-control.sh` passed inside step 2 (matrix rows, statuses, `done` rows, links).
2. Run the five `milestone-review` audits listed at the end of `docs/TRACEABILITY.md` § Update rules, using the commands in its § Conventions.
3. Roadmap consistency: every feature and requirement named in the milestone entry exists as a file, and every non-superseded requirement appears in some milestone:

   ```sh
   for f in docs/requirements/AVE-REQ-*.md; do grep -q '^status: superseded' "$f" && continue; id=$(basename "$f" | cut -d- -f1-3); grep -q -w "$id" docs/ROADMAP.md || echo "not on roadmap: $id"; done
   ```

4. Spot-check two or three `done` requirements not re-verified in step 4, choosing the riskiest: AC → tagged test → test passes (for an AC verified by inspection: the inspection re-performed by the procedure in § Implementation evidence, passing) → implementation files exist and hold the behavior → commit (`git log --oneline --grep='AVE-REQ-NNN[:,]'`).
5. Fix documentation gaps in place. An AC without evidence is blocking: reopen its requirement.
6. Baseline notes: `python3 -I -B scripts/check_baseline.py` prints every `Recorded change`, `Recorded addition`, `Gate change` and `Supersession` note. Judge each reason against AVE-REQ-093 AC-3 (a change of human intent needs the cited human input); a note without such a reason reopens its requirement.

### 12. Inspect dead or obsolete code and instructions

1. Dead code: use the stack's unused-code detection when the toolchain offers it; otherwise look for files and exported symbols without references (`git grep -n -w <symbol>`), unused dependencies, commented-out blocks, debug output, stale feature flags, and code anchors of superseded requirements.
2. Remove dead code when the removal is local and `./scripts/verify.sh` stays green; commit it separately (`refactor: remove dead code in <area>`). Larger removals become a requirement or a technical-debt entry.
3. Obsolete instructions: commands, paths, scripts, tools or decisions cited in `CLAUDE.md`, `README.md`, `.claude/` and `docs/` that no longer exist or contradict an Accepted ADR. For each superseded ADR, `git grep -n -w --untracked 'ADR-NNN' -- CLAUDE.md README.md .claude docs` and update every instruction that still relies on it. Confirm the commands in `docs/ARCHITECTURE.md` § Local development and § Testing strategy still run.
4. Remove each contradiction at its source, in the existing conventions, so instructions never accumulate contradictions.
5. `grep -rn '^_TBD' docs --exclude=README.md`: every remaining placeholder belongs to a requirement that is not `done` or to a section explicitly deferred; fill the others.

### 13. Review known technical debt

Work through `docs/ARCHITECTURE.md` § Risks and technical debt:
- resolved → delete the item (Git keeps history);
- still valid → update its impact and status;
- threatens a requirement of the next milestone or a quality target → schedule it as a requirement;
- add the items accepted in steps 7–12.

### 14. Consolidate missing and newly discovered requirements

1. Confirm every finding from steps 2–13 has its durable home:
   - missing behavior, defect or missing test → new requirement: next free ID (command in `docs/requirements/README.md` § IDs and files), an existing parent that lists it, `source: derived`, status `proposed`, Status-log line `- YYYY-MM-DD — proposed — discovered in milestone-review M<n> (lead)`;
   - regression in a `done` requirement → reopened requirement;
   - missing information → `docs/ASSUMPTIONS.md` entry; product-intent question → `docs/PRODUCT.md` § Open product questions plus escalation;
   - architecture decision → ADR; non-behavioral cleanup → technical-debt entry.
2. Never fold new scope into a `done` requirement.
3. Refine every blocking follow-up to Ready now (Definition of Ready in `docs/requirements/README.md`) so `develop` can take it next.

### 15. Decide the verdict

PASS when every exit criterion holds; FAIL otherwise. Blocking findings: an unfinished milestone requirement; a verify.sh failure; a failed re-verification or an AC without evidence; a failing journey, feature acceptance item or milestone exit criterion; an unresolved architecture-review blocking finding; a reachable known vulnerability; an invalidated assumption under a `done` requirement; in final mode, an unmet product-completion item.

### 16. Re-plan the roadmap and identify the next milestone

1. Place every follow-up requirement: blocking ones in the current milestone; the rest in the milestone that needs them by dependency and priority. Create a milestone only when none fits.
2. Re-plan later milestones that discoveries affected: reorder, split or rescope them under `docs/ROADMAP.md` § Rules and § Planning rules.
3. Add one Re-planning log row per change: `| YYYY-MM-DD | <change> | milestone-review M<n>: <reason> |`.
4. PASS: set the milestone `done`; set the next milestone (the first `planned` one whose `Depends on` milestones are `done`) `in-progress`; in final mode none remains. FAIL: the milestone stays `in-progress` and its requirement list includes the blocking follow-ups.

### 17. Record the review and update the canonical documents

1. Milestone entry Review line, replaced on each re-review (Git keeps earlier verdicts):

   ```text
   - **Review:** 2026-11-20 — PASS — follow-ups: AVE-REQ-041, AVE-REQ-042, ASM-009
   ```

   Final mode records its verdict in PROGRESS.md § Recently completed and § Verification status.
2. `docs/PRODUCT.md`: only statements the review proved outdated, with the reason in the commit body.
3. `docs/ARCHITECTURE.md`: drift corrections (step 7), dependency audit commands (step 9), debt list (step 13).
4. Feature and epic statuses with their Status-log lines (step 4); TRACEABILITY.md rows of reopened requirements.
5. `docs/PROGRESS.md`: set § Current milestone, § Current objective, § Recently completed (`YYYY-MM-DD — M<n> review: PASS | FAIL`), § Next recommended work, § Blockers, § Known failures, § Important recent decisions, § Verification status and the `_Last updated_` line.

### 18. Commit, refine the next milestone, continue

1. Run `./scripts/verify.sh --tier release`. It passes, or fails only with failures recorded as blocking findings in step 2 (name them in the commit body); the project-control step always passes. Inspect `git status` and `git diff`.
2. Copy the checkpoint line's results into the commit message, delete the line from PROGRESS.md § In progress (an emptied section reads `None.`), and commit the review with that deletion: `docs: complete milestone M<n> review` (final mode: `docs: complete final product review`). Body: verdict, follow-up IDs, rejected recommendations with reasons.
3. PASS outside final mode: refine the next milestone's requirements to Ready (Definition of Ready; `ready` transition with Status-log line; feature and epic statuses). A requirement that needs the human's answer stays `proposed` and joins the batched escalation. Commit: `AVE-REQ-NNN, AVE-REQ-NNN: refine to ready`.
4. Report in this format, then return to `develop` § 11, which continues with the next milestone or the follow-ups:

```text
MILESTONE REVIEW: M<n> | final — PASS | FAIL — YYYY-MM-DD
Verification: ./scripts/verify.sh PASS | FAIL; CI PASS | FAIL | unknown
Requirements: <done>/<total> done; re-verified: <IDs | none>; reopened: <IDs | none>
Journeys: <UJ-NNN PASS | UJ-NNN FAIL — reason>, …
Product vs PRODUCT.md: aligned | <deviations>
Architecture: HEALTHY | ATTENTION | ACTION-REQUIRED — <n> blocking, <n> important
Assumptions: confirmed <IDs>; invalidated <IDs>; open <IDs | none>
Follow-ups: <REQ/ASM/ADR IDs | none>
Escalations: <question — recommended default | none>
Next: <M<n+1> — name — <k> requirements ready | continue M<n> with AVE-REQ-NNN, … | product complete>
```
