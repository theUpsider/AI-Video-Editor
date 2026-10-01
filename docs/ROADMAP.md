# Roadmap

Hierarchy: **Phase → Milestone → Feature → Requirement.** A phase (`## Phase <n> — Name`)
groups milestones; a milestone (`### M<n> — Name`) delivers features (`FEAT-NNN`); features
decompose into requirements (`REQ-NNN`) in `docs/requirements/`
([format](requirements/README.md)). Milestone IDs `M1`, `M2`, … run sequentially across
phases and are never reused.

When working, read only the current milestone entry; [PROGRESS.md](PROGRESS.md)
§ Current milestone names it.

## Rules

1. The roadmap is derived from requirements: every listed feature and requirement exists as a
   file in `docs/requirements/`.
2. Dependencies determine ordering, between requirements and between milestones.
3. Establish working vertical slices early.
4. Avoid implementing all infrastructure before user-visible functionality: build
   infrastructure in the milestone whose features need it.
5. Keep milestones independently verifiable through their exit criteria.
6. Re-plan when discoveries invalidate assumptions; log each change in § Re-planning log.
7. Do not treat the roadmap as immutable. Update it whenever requirements, assumptions or
   evidence change.

## Planning rules

1. **M1 is a walking skeleton.** The first product milestone is the thinnest vertical slice
   of one core user journey (`UJ-NNN`) running end to end through every architectural layer,
   built and checked by verify.sh and CI with real checks. `technical-foundation` scaffolds
   the skeleton; `develop` completes M1.
2. **Refine just in time.** The initial plan details M1 fully and sketches later milestones
   with an outcome, features and `proposed` requirements. Requirements reach `ready` before
   work on them starts; `milestone-review` refines the next milestone when the current one
   ends.
3. **One active milestone.** Exactly one milestone is `in-progress`; `develop` selects
   requirements from it first.
4. **Milestone done.** A milestone is `done` when every non-superseded requirement in it is
   `done`, its exit criteria hold, and `milestone-review`
   ([SKILL.md](../.claude/skills/milestone-review/SKILL.md)) recorded a PASS in its Review
   line.
5. **Size.** Each milestone is small enough to finish and review as one unit and ends in a
   demonstrable user-visible outcome.
6. **Log every move.** Adding, splitting, reordering or rescoping milestones, and moving
   requirements between them, each get a Re-planning log row.

## Milestone entry template

Copy under the owning phase heading. In real entries, link each ID to its file.

```
### M<n> — Name
- **Status:** planned | in-progress | done
- **Outcome:** <what a user can do when the milestone is done>
- **Exit criteria:**
  - <verifiable condition, e.g. "UJ-NNN steps 1–3 pass end to end in ./scripts/verify.sh">
- **Features:** FEAT-NNN, FEAT-NNN
- **Requirements (dependency order):** REQ-NNN, REQ-NNN, REQ-NNN
- **Depends on:** M<n> | none
- **Review:** pending | YYYY-MM-DD — PASS | FAIL — follow-ups: <REQ/ASM/ADR IDs or none>
```

## Phase 0 — Development environment bootstrap

- **Status:** done — 2026-10-01
- **Outcome:** repository ready for specification-driven development: canonical documents,
  requirement and ADR formats, subagents, skills, hooks, `./scripts/verify.sh`, CI.
- **Decisions:** [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)
- **Verification:** `./scripts/verify.sh` PASS on 2026-10-01 (bootstrap checks only).
- **Follow-ups:** confirm ASM-001 to ASM-003 in [ASSUMPTIONS.md](ASSUMPTIONS.md).

## Phase 1 — Product definition

- **Status:** planned — next; starts when the human's product prompt arrives.
- **Outcome:** a specification complete enough to guide development: PRODUCT.md populated;
  epics, features and requirements with acceptance criteria; assumptions; architectural
  drivers; product phases and milestones in this file.
- **Procedure:** `product-definition`
  ([SKILL.md](../.claude/skills/product-definition/SKILL.md)), then `technical-foundation`
  ([SKILL.md](../.claude/skills/technical-foundation/SKILL.md)) before M1 starts.

_TBD: completion date and outcome links, recorded by the product-definition skill._

## Product phases

_TBD: populated by the product-definition skill — `## Phase <n> — Name` headings (n ≥ 2) replacing this section, each holding milestone entries from the template; M1 is the walking skeleton._

## Re-planning log

Newest last. One row per change to milestones, their order or their scope.

| Date | Change | Reason |
|---|---|---|

_No entries yet._
