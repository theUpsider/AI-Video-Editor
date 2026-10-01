# Product definition

**Status:** placeholder — awaiting the human's product prompt.
**Working title:** AI Video Editor (unconfirmed; inferred from the repository name).

This file is the canonical product definition. Epics, features and requirements in
`docs/requirements/` ([format](requirements/README.md)) derive from it;
[ROADMAP.md](ROADMAP.md) orders them.

> **Before substantial implementation begins**, the `product-definition` skill
> ([SKILL.md](../.claude/skills/product-definition/SKILL.md)) must transform the next
> high-level product prompt into a much more complete specification. It stores the human's
> verbatim input in `docs/product-inputs/YYYY-MM-DD-<slug>.md`, populates every section
> below, replaces the status line above, and creates the epics, features, requirements,
> assumptions, architectural drivers and initial roadmap.

## Maintenance rules

1. Replace each `_TBD:` line with content. A populated file has no line starting with `_TBD`
   (`grep -n '^_TBD' docs/PRODUCT.md` prints nothing); a section with nothing to state says
   `None.` with the reason.
2. Stay at product level. Behavior details and acceptance criteria live in requirement files.
3. Infer baseline capabilities with
   [baseline-capabilities.md](../.claude/skills/product-definition/baseline-capabilities.md)
   and this rule: «Include what is required to make the requested product coherent,
   reliable, usable, and production-quality. Avoid speculative features that do not support
   an identified user need.»
4. Never silently change human-stated content. A change that alters product intent goes to
   the human ([CLAUDE.md](../CLAUDE.md) § Autonomy and escalation). Apply new human input
   through the amendment mode of `product-definition`.
5. Allocate `GOAL-NNN` and `UJ-NNN` sequentially (three digits, zero-padded); never reuse or
   renumber them.

## Product vision

_TBD: two to four sentences — what the product is, for whom, and the outcome it delivers._

## Problem statement

_TBD: the problem, who has it, how they cope today, and where current options fall short._

## Target users

_TBD: one bullet per user type — context, needs, skill level; mark the primary user._

## Product goals

_TBD: three to seven measurable outcomes, one row each. Epics cite them in their `goals` frontmatter; each success signal is observable and verifiable._

| ID | Goal | Success signal |
|---|---|---|

## Core user journeys

_TBD: one `### UJ-NNN — Title` subsection per journey — actor, trigger, numbered steps, successful outcome, key failure paths, related `GOAL-NNN` and `FEAT-NNN`. Milestone reviews test these end to end._

## Must-have features

_TBD: each must-have the human stated, in the human's wording (source file in `docs/product-inputs/`), followed by the `EPIC-NNN`/`FEAT-NNN` that covers it. Requirements implementing a must-have carry `source: human`; derived capabilities appear under Functional areas._

## Product boundaries

_TBD: what the product covers — supported platforms, inputs and outputs, scale, languages, external systems it relies on, and constraints the human set._

## Explicit non-goals

_TBD: capabilities deliberately excluded, one bullet each with the reason. Use this list to reject scope creep._

## Functional areas

_TBD: one bullet per area — name, one-line scope, and the `EPIC-NNN` it maps to. Include areas that hold derived baseline capabilities._

## UX principles

_TBD: three to seven principles that settle interface trade-offs, e.g. how progress, errors and destructive actions are presented, and the accessibility level._

## Security and privacy expectations

_TBD: data handled and its sensitivity, authentication and authorization needs, retention and deletion, compliance constraints. Each expectation becomes a non-functional requirement._

## Performance expectations

_TBD: measurable targets (latency, throughput, input sizes, concurrency, resource limits) and the conditions they apply under. Each target becomes a non-functional requirement._

## Deployment assumptions

_TBD: how users obtain and run the product (hosted service, desktop, mobile, CLI, self-hosted), expected environments, operating constraints. Unstated items become `ASM-NNN` entries; technology choices follow as ADRs from `technical-foundation`._

## Open product questions

_TBD: one bullet per question with its resolution — `→ ASM-NNN` (assumed and recorded in ASSUMPTIONS.md) or `→ escalated YYYY-MM-DD` (asked with a recommended default). Every question is resolved before development starts._

## Definition of product completion

The product is complete when all of the following hold; the final `milestone-review` checks them.

1. Every product milestone in [ROADMAP.md](ROADMAP.md) is `done` with a recorded review verdict of PASS.
2. Every `must` requirement is `done`; no requirement is `in-progress`, `verification` or `blocked`.
3. Every success signal in § Product goals holds (goals marked `retired` excepted), and every core user journey passes end to end.
4. `./scripts/verify.sh` passes locally and in CI.
5. [TRACEABILITY.md](TRACEABILITY.md) holds a complete row for every `done` requirement.
6. No `open` assumption in [ASSUMPTIONS.md](ASSUMPTIONS.md) affects a must-have feature.
7. This file, [ARCHITECTURE.md](ARCHITECTURE.md) and [PROGRESS.md](PROGRESS.md) describe the delivered product.

_TBD: product-specific completion criteria (release form, user documentation, deployment target), populated by the product-definition skill._
