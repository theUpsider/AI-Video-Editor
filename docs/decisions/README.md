# Architecture decision records

An ADR records one significant decision: its context, the alternatives weighed and the
consequences accepted. Later sessions build on recorded decisions and change them only
deliberately, by superseding them. [docs/ARCHITECTURE.md](../ARCHITECTURE.md) describes the
current result; the ADRs record why it looks that way.

## When to write one

Write an ADR for a decision that materially affects:
- architecture: structure, module boundaries, runtime topology;
- data models and persistence;
- integration boundaries: external APIs and services, file formats, protocols;
- infrastructure and deployment;
- major dependencies: language, framework, database, media-processing stack, AI provider;
- long-term maintainability: testing strategy, compatibility policy, development workflow.

`technical-foundation` writes one ADR per significant stack choice. Test: would reversing the
decision later cost more than a day of rework or move a boundary other code depends on? Then
write an ADR.

Never write ADRs for trivial coding choices: naming, formatting, small helper libraries, local
refactors, or choices an accepted ADR already governs. Record gap-filling guesses in
[docs/ASSUMPTIONS.md](../ASSUMPTIONS.md); when an assumption grows into a significant decision,
write the ADR, mark the assumption `superseded` and link the ADR.

## IDs and files

1. File: `docs/decisions/ADR-NNN-<slug>.md`. `NNN` has at least 3 digits, zero-padded,
   allocated sequentially, never reused. The slug is lowercase kebab-case `[a-z0-9-]+`, fixed
   at creation.
2. H1: `# ADR-NNN — <Decision title>`, with the ID equal to the filename ID. The title names
   the decision, e.g. "Use <X> for <Y>".
3. One decision per ADR, about one page.
4. Never delete or renumber an ADR.

Next free ID:

```sh
n=$(ls docs/decisions | sed -n 's/^ADR-\([0-9][0-9]*\)-.*/\1/p' | sort -n | tail -1); printf 'ADR-%03d\n' $((10#${n:-0} + 1))
```

## Template

Copy it, replace every `<…>`, keep the headings verbatim and in order.

```markdown
# ADR-NNN — <Decision title>

## Status
Proposed — <YYYY-MM-DD>

## Context
<The problem, forces and constraints. Cite AVE-REQ-NNN, ASM-NNN, ADR-NNN and the architectural drivers in docs/ARCHITECTURE.md.>

## Decision
<What is decided, stated imperatively and specifically: scope, boundaries, versions where relevant.>

## Alternatives considered
- <Option> — <why it was rejected>

## Consequences
- <Positive and negative effects, follow-up work (new requirements, verify.sh steps, ARCHITECTURE.md updates), revisit triggers.>

## Related requirements
- [AVE-REQ-NNN — <Title>](../requirements/AVE-REQ-NNN-<slug>.md), or "None (process-level)."
```

## Status lifecycle

`Proposed → Accepted → Superseded`. The line directly under `## Status` is the status line, in
one of these forms (the date is the date of the latest transition):

```text
Proposed — 2026-10-01
Accepted — 2026-10-01
Superseded by ADR-007 — 2026-11-02
```

The section holds only this line; Git keeps the history.
- **Proposed**: drafted and awaiting the lead's acceptance or, when escalated, the human's answer.
  Build on a Proposed ADR only behind an interface with a fake built for its recommended default
  while its escalated question is open (`technical-foundation` step 5); the real integration waits
  for acceptance.
- **Accepted**: in effect. Its substance is fixed; change the decision by superseding it.
  Permitted edits: typo fixes, link fixes, additional related requirements.
- **Superseded**: replaced by the named ADR and kept for history.

## Who writes

1. The architect subagent drafts ADRs with status `Proposed`; it writes only in
   `docs/decisions/` and returns its recommendation to the lead.
2. The lead reviews the draft. To accept, set `Accepted — <date>`. To reject an option, revise
   the draft into the decision actually taken, move the rejected option to Alternatives
   considered, and accept that.
3. The lead may write and accept ADRs directly (`technical-foundation`, `develop`).
4. Before accepting a decision that is genuinely irreversible or materially changes the
   product, escalate to the human ([CLAUDE.md](../../CLAUDE.md) § Autonomy and escalation).
5. On acceptance, the lead updates the [index](#index), docs/ARCHITECTURE.md when the
   architecture changes, the ADR's § Related requirements (every requirement it governs), the
   ADRs column of affected rows in [docs/TRACEABILITY.md](../TRACEABILITY.md), and
   docs/PROGRESS.md § Important recent decisions.

## Superseding

1. Write the replacement with the next free ID; its Context names the ADR it replaces and why.
2. Accept the replacement.
3. Set the old ADR's status line to `Superseded by ADR-NNN — <date>` and leave the rest of it
   unchanged.
4. Update the index, docs/ARCHITECTURE.md, the TRACEABILITY.md ADRs column, and every
   instruction that cites the old decision (CLAUDE.md, skills, scripts).
5. Commit both ADRs and the updates together: `docs: supersede ADR-NNN with ADR-NNN`.

## Enforced checks

`./scripts/check-project-control.sh` (run by `./scripts/verify.sh`) fails on an ADR file whose
name breaks the `ADR-NNN-<slug>.md` pattern, whose H1 ID differs from the filename, that lacks a
template heading, whose status line has an invalid form, whose Superseded line names a missing ADR
or the ADR itself, or whose ID duplicates another ADR's.

## Index

The lead adds a row for every ADR and updates its status on each transition.

| ADR | Title | Status |
|---|---|---|
| [ADR-001](ADR-001-specification-driven-development-workflow.md) | Specification-driven development workflow | Accepted — 2026-10-01 |
| [ADR-002](ADR-002-technology-stack.md) | Use Python/FastAPI, SQLite, FFmpeg and React/TypeScript as the version-one stack | Accepted — 2026-10-01 |
| [ADR-003](ADR-003-requirements-baseline-import.md) | Adopt the AVE requirement IDs as working IDs over an immutable baseline | Accepted — 2026-10-01 |
| [ADR-004](ADR-004-exact-time-and-composition-model.md) | Exact rational time and one typed, versioned composition document | Accepted — 2026-10-01 |
| [ADR-005](ADR-005-segmented-cpu-reference-renderer.md) | Segmented CPU reference renderer with decoded-output validation | Accepted — 2026-10-01 |
| [ADR-006](ADR-006-sqlite-revisions-and-durable-jobs.md) | SQLite revisions and a durable job table consumed by a separate worker | Accepted — 2026-10-01 |
| [ADR-007](ADR-007-ai-integration-boundaries.md) | Separate provider, agent-runtime, analysis and MCP integrations behind the command service | Accepted — 2026-10-01 |
| [ADR-008](ADR-008-local-speech-recognition.md) | Pluggable local ASR: faster-whisper when cached, bundled PocketSphinx as the offline floor | Accepted — 2026-10-01 |
