# Requirements

This directory holds every epic, feature and requirement, one Markdown file each. This README is
the authoritative format. [scripts/check-project-control.sh](../../scripts/check-project-control.sh)
and [scripts/check_baseline.py](../../scripts/check_baseline.py) enforce its mechanical rules (see
[Enforced checks](#enforced-checks)). Traceability conventions live in
[docs/TRACEABILITY.md](../TRACEABILITY.md); milestone membership lives in
[docs/ROADMAP.md](../ROADMAP.md); product goals and journeys live in [docs/PRODUCT.md](../PRODUCT.md).

The working files start as an import of the immutable requirements baseline
[ai-video-editor-requirements/](../../ai-video-editor-requirements/README.md) (package v1.0) and keep its
stable AVE IDs ([ADR-003](../decisions/ADR-003-requirements-baseline-import.md)).
[IMPORT_MAPPING.md](IMPORT_MAPPING.md) maps every baseline ID to its working file; see
[Baseline import and integrity](#baseline-import-and-integrity).

## IDs and files

| Kind | ID | File | Links upward via |
|---|---|---|---|
| Epic | `AVE-EPIC-NN` | `AVE-EPIC-NN-<slug>.md` | `goals: [GOAL-NNN]` (PRODUCT.md § Product goals) |
| Feature | `AVE-FEAT-NNN` | `AVE-FEAT-NNN-<slug>.md` | `parent: AVE-EPIC-NN` |
| Requirement | `AVE-REQ-NNN` | `AVE-REQ-NNN-<slug>.md` | `parent: AVE-FEAT-NNN`, or `parent: AVE-EPIC-NN` for a cross-cutting non-functional requirement or a removal (product-definition amendment mode) |
| Acceptance criterion | `AC-n` | inside its requirement file | referenced globally as `AVE-REQ-NNN AC-n` |

In this README, "EPIC", "FEAT" and "REQ" name the three kinds of file.

1. Epic numbers have at least 2 digits (`AVE-EPIC-01`, as in the baseline); feature and
   requirement numbers have at least 3 (`AVE-FEAT-001`, `AVE-REQ-001`). All are zero-padded and
   allocated sequentially per kind. The baseline IDs are used verbatim; IDs allocated later
   continue after the baseline's last ones (`AVE-EPIC-11`, `AVE-FEAT-021`, `AVE-REQ-102`), and
   such requirements carry `source: derived`. Never reuse an ID, including the IDs of superseded
   files.
2. Slug: lowercase kebab-case `[a-z0-9-]+` from the title (an imported file takes its whole
   baseline title), fixed at creation. Never rename a file; the ID is the anchor.
3. Files sit flat in `docs/requirements/`. Never create subdirectories.
4. Never delete a requirement file; retire it with status `superseded`.
5. Only the lead (main session) allocates IDs and creates files. Subagents propose follow-up
   work in their reports.
6. AC numbers start at `AC-1` and are stable. Never renumber: a new AC takes the next unused
   number; a removed AC's line is deleted, its number stays retired, and the `## Status` log
   records the removal.

Next free ID (set `K` to `AVE-REQ` or `AVE-FEAT` with `W=3`, or to `AVE-EPIC` with `W=2`):

```sh
K=AVE-REQ W=3; n=$(ls docs/requirements | sed -n "s/^$K-\([0-9][0-9]*\)-.*/\1/p" | sort -n | tail -1); printf "%s-%0${W}d\n" "$K" $((10#${n:-0} + 1))
```

## Frontmatter

Every EPIC, FEAT and REQ file starts with a frontmatter block between two `---` lines. It
uses a YAML subset that the checker parses line by line:
- one `key: value` per line, keys in the order of the templates below;
- lists in flow style: `[GOAL-001, GOAL-002]`;
- no nesting, no multi-line values, no quoting, no comments;
- values never contain `: ` or ` #` (rephrase the title).

| Key | Used in | Allowed values | Meaning |
|---|---|---|---|
| `id` | all | `AVE-EPIC-NN`, `AVE-FEAT-NNN`, `AVE-REQ-NNN` | Equals the ID in the filename and the H1 |
| `title` | all | short plain text | Equals the title in the H1; an imported file keeps the baseline title |
| `type` | REQ | `functional`, `non-functional`, `constraint` | functional: observable behavior. non-functional: a quality attribute with a measurable threshold (performance, security, reliability, accessibility, operability). constraint: an imposed limit on the solution (platform, compatibility, compliance, license, mandated technology or delivery process). Baseline mapping: `functional` → functional, `nonfunctional` → non-functional, `delivery` → constraint |
| `status` | all | `proposed`, `ready`, `in-progress`, `verification`, `done`, `blocked`, `superseded`, `deferred` | Canonical lifecycle state; see [Status lifecycle](#status-lifecycle) |
| `priority` | all | `must`, `should`, `could` | must: required for product completion. should: important; scheduled after the musts of its milestone. could: desirable; built when cheap. A `deferred` file carries `could` (the baseline's `future` priority) and stays unbuilt while deferred. Exclusions belong in PRODUCT.md § Explicit non-goals |
| `parent` | FEAT, REQ | FEAT: `AVE-EPIC-NN`. REQ: `AVE-FEAT-NNN`, or `AVE-EPIC-NN` for a cross-cutting non-functional requirement or a removal | The parent file exists and lists this child |
| `goals` | EPIC | non-empty list of `GOAL-NNN` | Each goal exists in PRODUCT.md § Product goals |
| `source` | REQ | `human`, `derived` | human: stated by the human; Intent cites the human input (an imported file cites its user-brief clauses `U01`–`U27` in [USER_BRIEF.md](../../ai-video-editor-requirements/intake/USER_BRIEF.md); other files cite `docs/product-inputs/`). derived: inferred by Claude (decomposition, baseline capability, technical need); an imported file is derived when its origins hold only the brief's derived clauses `D01`–`D05` |
| `scope` | REQ | `v1`, `future` | v1: part of version one. future: explicit future scope with status `deferred`. An imported file keeps the baseline scope |
| `primary_gate` | REQ | `M0`…`M7` (milestones of [ROADMAP.md](../ROADMAP.md)), `FUTURE` | The milestone whose review completes the requirement; `FUTURE` exactly for scope future |
| `origins` | REQ | flow list of brief clause IDs; `[]` allowed for later derived files | The user-brief clauses the requirement implements |
| `dependencies` | REQ | flow list of `AVE-REQ-NNN`; `[]` when none | Requirements that are `done` before this one starts; § Dependencies links them |
| `scenarios` | REQ | flow list of `AT-NN`; `[]` allowed for later derived files | Acceptance scenarios of [ACCEPTANCE_TESTS.md](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md) that exercise the requirement |
| `baseline` | REQ, imported files only | relative path to the baseline requirement file | The immutable source of the imported statement and criteria |
| `superseded_by` | all, optional, last key | ID of the same kind; for an EPIC or FEAT retired by a removal, the removal REQ | Required when status is `superseded`; names the replacement |

## Templates

Copy a template, replace every `<…>`, keep the headings verbatim and in order. Unfilled
sections hold one `_TBD: …_` line. Link children and dependencies with relative links such as
`[AVE-REQ-NNN — Title](AVE-REQ-NNN-<slug>.md)`; every link must resolve. The import tool fills
imported files from the same templates (see [Baseline import and integrity](#baseline-import-and-integrity)).

### Requirement (REQ)

```markdown
---
id: AVE-REQ-NNN
title: <Title>
type: functional
status: proposed
priority: must
parent: AVE-FEAT-NNN
source: derived
scope: v1
primary_gate: M<n>
origins: []
dependencies: []
scenarios: []
---

# AVE-REQ-NNN — <Title>

## Intent
<Why this requirement exists: the user need, GOAL-NNN or UJ-NNN step it serves. For source: human, cite the human input (brief clause or docs/product-inputs/<file>.md).>

## Description
<Precise expected behavior: inputs, outputs, states, rules and limits with concrete values.>

## Acceptance criteria
- [ ] AC-1 <observable, testable behavior>
- [ ] AC-2 <error behavior>
- [ ] AC-3 <boundary behavior>

## Edge cases
- <case> — <expected behavior and the AC that covers it, or "out of scope: <reason>">

## Dependencies
- <AVE-REQ-NNN / ADR-NNN / external service — why>, or "None."

## Verification strategy
- AC-1 — <unit | integration | end-to-end | inspection> — <what is exercised, fixtures, data>
- Acceptance scenarios: <AT-NN links; scenario tests carry the tag `AT-NN`>, or "None."

## Implementation evidence
_TBD: filled by the implementer when the implementation is complete._

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- <YYYY-MM-DD> — proposed — <reason> (<actor>)
```

Filled evidence sections look like this:

```markdown
## Implementation evidence
- `<path/to/module>` — <what it implements> (AC-1, AC-2)
- `<path/to/other-module>` — <role> (AC-3)
- Tests: `<path/to/test-file>` — AVE-REQ-NNN AC-1, AVE-REQ-NNN AC-2, AVE-REQ-NNN AC-3
- Decisions: ADR-NNN, ASM-NNN (or "None.")

## Test evidence
- verify-requirement: PASS — <YYYY-MM-DD> — no blocking findings
- ./scripts/verify.sh: PASS — <YYYY-MM-DD>
- AC-1 → `<test location>` — pass
- AC-2 → `<test location>` — pass
- AC-3 → inspection: <what was checked and how> — pass
- Non-blocking findings: <summary with follow-up AVE-REQ/ASM IDs, or "None.">
```

### Epic (EPIC)

```markdown
---
id: AVE-EPIC-NN
title: <Title>
status: proposed
priority: must
goals: [GOAL-NNN]
---

# AVE-EPIC-NN — <Title>

## Goal
<The product goal(s) this epic serves and the outcome it delivers.>

## Scope
<Capabilities included and the boundary of the epic.>

## Features
- [AVE-FEAT-NNN — <Title>](AVE-FEAT-NNN-<slug>.md)
- Cross-cutting: [AVE-REQ-NNN — <Title>](AVE-REQ-NNN-<slug>.md)

## Success criteria
- <measurable outcome, checked in milestone-review>

## Status
- <YYYY-MM-DD> — proposed — <reason> (<actor>)
```

### Feature (FEAT)

```markdown
---
id: AVE-FEAT-NNN
title: <Title>
status: proposed
priority: must
parent: AVE-EPIC-NN
---

# AVE-FEAT-NNN — <Title>

## Intent
<The user need this feature satisfies.>

## User journey
<The UJ-NNN step(s) from docs/PRODUCT.md this feature enables.>

## Requirements
- [AVE-REQ-NNN — <Title>](AVE-REQ-NNN-<slug>.md)

## Out of scope
<What this feature deliberately excludes, with the reason.>

## Feature acceptance
- [ ] <end-to-end check across this feature's requirements, verified in milestone-review>

## Status
- <YYYY-MM-DD> — proposed — <reason> (<actor>)
```

## Writing requirements

Every requirement is:
1. **Independently understandable**: a reader holding only this file and its parent knows what
   to build and why. Define domain terms; reference other files by ID.
2. **Testable**: every AC has a pass/fail outcome decidable by a test or a recorded inspection.
3. **Reasonably scoped**: implementable and verifiable in one focused session.
4. **Linked to its parent**: `parent` names an existing FEAT (or EPIC) that lists it.
5. **Traceable to implementation**: `## Implementation evidence` names the files and modules.
6. **Traceable to verification**: tests carry `AVE-REQ-NNN AC-n`; `## Test evidence` records results.

Section guidance:
- **Intent**: one to three sentences on the need and the goal or journey it serves.
- **Description**: the behavior a correct implementation exhibits. State numbers (limits,
  sizes, timeouts, formats). Prescribe technology only in `constraint` requirements or by
  citing an ADR.
- **Acceptance criteria**:
  - Observable from outside the code (UI, API, CLI, files, persisted data, logs).
  - Testable: a fixed procedure yields pass or fail. Replace vague words (fast, robust,
    intuitive, secure) with thresholds and measurement methods.
  - One behavior per AC.
  - Cover the success path, error behavior (invalid input, failure of a dependency) and
    boundary behavior (empty, minimum, maximum, limit plus one).
  - Given/When/Then is optional; use it when preconditions matter.
  - Non-functional ACs state the metric, threshold, load or data set, and measurement method.
- **Edge cases**: consider empty and maximal input, invalid formats, duplicates, interruption
  and retry, concurrency, permissions, encoding and locale, slow or failing dependencies,
  partial failure. Each case maps to an AC or is declared out of scope with a reason.
- **Dependencies**: requirements that must be `done` first, governing ADRs, external services.
- **Verification strategy**: per AC, the level (unit, integration, end-to-end, inspection) and
  what is exercised. Inspection needs a reason why automation is impractical.

```markdown
Weak:   - [ ] AC-1 Submitting items is fast and errors are handled gracefully.
Strong: - [ ] AC-1 Given an item within the size limit, when the user submits it, then it appears in the list with state "Ready" within 5 s.
        - [ ] AC-2 Given an item larger than the size limit, when the user submits it, then the submission is rejected with a message stating the limit and nothing is stored.
        - [ ] AC-3 Given an item exactly at the size limit, when the user submits it, then it is accepted.
```

## Status lifecycle

```text
proposed → ready → in-progress → verification → done
                        ↑              │
                        └──────────────┘  verification fails
any state → blocked → the prior state     (reason in the Status log and PROGRESS.md § Blockers)
any state → superseded                    (terminal; superseded_by set)
done → in-progress                        (reopened with a logged reason)
deferred                                  (future scope; leaves it only through a human scope change)
```

| Value | Display name | Enter when |
|---|---|---|
| `proposed` | Proposed | Created; Definition of Ready not yet met |
| `ready` | Ready | Definition of Ready met |
| `in-progress` | In Progress | Work starts; the TRACEABILITY.md row is added |
| `verification` | Verification | Implementation and tests complete, `./scripts/verify.sh` passes, `verify-requirement` runs |
| `done` | Done | Every Definition of Done item holds |
| `blocked` | Blocked | Progress needs something outside Claude's control |
| `superseded` | Superseded | A replacement exists |
| `deferred` | Deferred | The requirement is explicit future scope (`scope: future`); version one excludes it |

Rules:
1. The lead sets every status. Frontmatter `status` is canonical. Every transition appends
   one line to `## Status`: `- YYYY-MM-DD — <status> — <reason> (<actor>)`. The newest line
   is last, and its status equals the frontmatter.
2. A logged change without a transition repeats the current status:
   `- 2026-10-03 — ready — AC-2 limit clarified to 100 items (lead)`.
3. With every transition, update the TRACEABILITY.md row (once it exists) and docs/PROGRESS.md
   in the same change.
4. `blocked`: log the reason and the prior state; add the blocker to PROGRESS.md § Blockers;
   on resolution return to the prior state and remove the blocker.
5. Reopening `done`: log the reason (regression, changed AC), untick the affected ACs, and run
   the full Definition of Done again.
6. EPIC and FEAT status derives from their children, leaving out superseded and deferred
   children: `ready` when every remaining child is ready or later; `in-progress` once any child
   is in progress or later; `verification` while milestone-review checks Feature acceptance or
   Success criteria after every remaining child is `done`; `done` when every remaining child is
   `done` and Feature acceptance or Success criteria hold; `blocked` when no remaining child can
   progress. An EPIC or FEAT whose every non-superseded child is deferred is `deferred`. The
   lead updates them on child transitions. A `superseded` EPIC or FEAT keeps that status.
7. `deferred`: a requirement with `scope: future` holds this status and `primary_gate: FUTURE`.
   It stays out of `in-progress` and `done`, and no version-one requirement depends on it.
   Moving it into version one is a product change: the human decides it through
   `product-definition` amendment mode, a new baseline version carries the new scope, and the
   Status log records the decision. A version-one requirement never becomes `deferred`.

## Definition of Ready

A requirement moves to `ready` when all items below hold. An imported requirement starts `ready`
because the baseline specified it for planning; the lead settles its Edge cases and dependency
order before it moves to `in-progress`, as its Status log records.
- [ ] Intent states the need and the goal or journey it serves.
- [ ] Description specifies the behavior with concrete values.
- [ ] At least one testable AC exists, and the ACs cover error and boundary behavior.
- [ ] Edge cases are considered and each is mapped to an AC or declared out of scope.
- [ ] Dependencies are identified, and each is `done` or scheduled first in ROADMAP.md.
- [ ] Verification strategy is stated per AC.
- [ ] The parent exists and lists this requirement.

## Definition of Done

A requirement moves to `done` only when ALL hold. A `deferred` requirement lies outside version
one: it never moves to `done`, and product completion counts the version-one requirements.
1. implementation exists;
2. every AC is satisfied and ticked;
3. tests or other verification exist for every AC and are tagged with `AVE-REQ-NNN AC-n`;
4. `./scripts/verify.sh` passes;
5. [`verify-requirement`](../../.claude/skills/verify-requirement/SKILL.md) (independent
   reviewer) returned PASS with no blocking findings;
6. traceability updated: Implementation evidence + Test evidence filled (no `_TBD` left),
   TRACEABILITY.md row present with matching status.

## Changing requirements

`proposed` requirements change freely within rule 2; log substantial changes. "Approved"
means status `ready` or later, and `deferred`. For an approved requirement:
1. Log every change to Intent, Description or ACs in `## Status` with the reason before or with
   the edit. Never change a requirement silently. For a changed or removed baseline AC, the log
   line contains `AC-n changed: <reason>`; for a changed Description of an imported requirement,
   it contains `Description changed: <reason>`
   ([Baseline import and integrity](#baseline-import-and-integrity)).
2. `source: human` and the change alters product intent, in any status: a change the human
   requested is authorized; apply it through `product-definition` amendment mode, which records
   the input and cites it in the log. Escalate any other such change to the human (CLAUDE.md
   § Autonomy and escalation), leave the requirement unchanged until the answer arrives, and
   continue independent work.
3. `source: derived`: the lead decides, logs the reason, and records the underlying assumption
   in docs/ASSUMPTIONS.md when one exists. An imported requirement keeps the requested
   behavior, safety and testability of its baseline criteria; a change that weakens one goes to
   the human as in rule 2.
4. Changing a `done` requirement reopens it (`in-progress`).
5. Discovered work becomes a new `proposed` requirement. Never expand the current one silently.

### Superseding

1. Create the replacement with the next free ID; its Intent names the requirement it replaces.
2. In the old file set `status: superseded`, add `superseded_by: <new ID>` as the last
   frontmatter key, and log the reason.
3. Update the parent's list, the TRACEABILITY.md row status, ROADMAP.md references, ADR
   `## Related requirements`, and tests tagged with the old ID (retag or delete them).
4. Keep the old file.

### Sizing and splitting

One requirement is implementable and verifiable in one focused session. Split when it has more
than about seven ACs, spans several independent behaviors, touches unrelated modules, or its
title needs "and". To split, keep the original ID for the core behavior, move the remaining ACs
to new requirements with the same parent, and log the split in each file. Merge trivially small
requirements that always change together.

## Who edits what

| Actor | In requirement files |
|---|---|
| Lead (main session) | Everything: allocates IDs, creates files, refines to Ready, changes status (frontmatter and Status log), ticks ACs only after a `verify-requirement` PASS, fills Test evidence from the verdict report's "Evidence for the requirement file", logs approved changes |
| implementer subagent | Only `## Implementation evidence` of its assigned requirements; reports every other update to the lead |
| reviewer (`verify-requirement`) | Nothing; returns the verdict report |
| tester | Nothing; writes test files only |
| architect, researcher | Nothing; the architect drafts ADRs in `docs/decisions/` |

When the lead implements directly, the lead also fills Implementation evidence.

## Baseline import and integrity

The human's requirements package lives unchanged in
[ai-video-editor-requirements/](../../ai-video-editor-requirements/README.md); its `MANIFEST.json`
pins the SHA-256 hash of every file, and `BASELINE_MANIFEST_SHA256` in
[check_baseline.py](../../scripts/check_baseline.py) pins the SHA-256 of `MANIFEST.json` itself:
the trust anchor lives outside the package, so a baseline edit fails with "baseline changed" even
when the manifest is re-hashed. The working files in this directory carry the lifecycle.

1. **Never edit the baseline.** A requirement change happens in the working file, with a logged
   reason; a new baseline version comes only from the human, and the commit that adopts it
   updates the pinned manifest hash and cites the human's input.
2. **Import.** `python3 scripts/requirements/import_baseline.py`
   ([source](../../scripts/requirements/import_baseline.py)) creates one working file per
   baseline epic, feature and requirement and regenerates [IMPORT_MAPPING.md](IMPORT_MAPPING.md).
   It keeps every existing working file and prints `kept` for it, so a rerun creates only
   missing files; `--check` lists what a run would create or regenerate and exits 1 when that is
   anything. An imported requirement holds: the baseline statement verbatim as Description; the
   baseline criteria verbatim as `- [ ] AC-n <text>` with the same AC numbers; Intent with the
   goal, the parent feature and links to the origin clauses of
   [USER_BRIEF.md](../../ai-video-editor-requirements/intake/USER_BRIEF.md) and to the baseline
   file; Dependencies linking the working files of the baseline dependencies; a Verification
   strategy naming the criterion-level test tags and the linked
   [acceptance scenarios](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md); `_TBD:`
   lines for Edge cases and the evidence sections; a first Status-log line
   `- 2026-10-01 — ready — imported from baseline v1.0 (lead)` or
   `- 2026-10-01 — deferred — future scope in baseline (lead)`.
3. **Value mappings** (also listed in IMPORT_MAPPING.md): type `functional` → functional,
   `nonfunctional` → non-functional, `delivery` → constraint; priority `must` → must, `future` →
   could; status `ready` → ready, `deferred` → deferred; source human when the origins include a
   user clause (`U01`–`U27`) and derived when they hold only derived clauses (`D01`–`D05`).
4. **Changing an imported requirement.** Log every change in `## Status` (see
   [Changing requirements](#changing-requirements)). A baseline AC whose text changes, or which
   is removed, needs a Status-log line containing `AC-n changed: <reason>`; check_baseline.py
   reports it as a recorded change. Added ACs take the next unused AC number and are reported.
   The Description (the baseline statement verbatim), `scope`, `parent`, `dependencies`,
   `origins`, `scenarios`, `baseline`, the title, the type, the priority and the source stay
   equal to the baseline (mapped); a different value fails the check. Of these, only the
   Description may change, with a Status-log line containing `Description changed: <reason>`;
   check_baseline.py reports it as a recorded change. A primary gate moved by the roadmap is
   reported.
5. **New work.** A requirement found later takes the next free ID after the baseline range
   (`AVE-REQ-102` onward) with `source: derived`, a `scope` and a `primary_gate`; it is absent
   from IMPORT_MAPPING.md.

## Enforced checks

`./scripts/check-project-control.sh` (run by `./scripts/verify.sh`) fails on:
1. a filename outside the `AVE-EPIC-NN-<slug>.md`, `AVE-FEAT-NNN-<slug>.md` and
   `AVE-REQ-NNN-<slug>.md` patterns (this README and IMPORT_MAPPING.md excepted);
2. an empty file, a missing or unterminated frontmatter block, an empty `title`, a frontmatter
   `id` different from the filename ID, or a duplicate ID;
3. an invalid `status` (including `deferred`) or `priority`, or an invalid REQ `type` or `source`;
4. a missing parent or a parent of the wrong kind (REQ → AVE-FEAT or AVE-EPIC; FEAT → AVE-EPIC);
5. an EPIC with empty `goals` or a GOAL ID absent from PRODUCT.md;
6. `superseded` without `superseded_by`, or a `superseded_by` that names no file;
7. an H1 that does not start with `# <ID>`;
8. a REQ missing any template heading, having no AC line, or having a list item under
   `## Acceptance criteria` that does not read `- [ ] AC-n <behavior>` (`- [x]` once ticked);
9. a missing `## Status` section (any kind), one without a dated log line, or one whose newest
   log line records a status other than the frontmatter `status`;
10. a `done` REQ with an unticked AC or a `_TBD` marker;
11. a relative link that does not resolve;
12. a missing TRACEABILITY.md matrix header; a matrix row separated from the header by a blank or
    text line, without an `AVE-REQ-NNN` ID, duplicated, or whose requirement file is missing or
    whose status differs from the frontmatter; or a `done` REQ without a row.

The checker ignores frontmatter keys it does not know, so the requirement keys `scope`,
`primary_gate`, `origins`, `dependencies`, `scenarios` and `baseline` pass through to
`python3 scripts/check_baseline.py`, which fails on:
1. a changed baseline: a `MANIFEST.json` whose SHA-256 differs from the pinned
   `BASELINE_MANIFEST_SHA256`, a missing manifest or a second `MANIFEST.json` inside the package
   (each reported as "baseline changed"), or a failing package validation
   (`tools/validate_package.py`: consistency and the manifest's hash of every file), so any edit
   of the baseline fails, including one that re-hashes the manifest;
2. a baseline epic, feature or requirement without exactly one working file of the same ID, or
   with a different title or H1;
3. an imported requirement whose type, priority or source differs from the mapped baseline
   value, or whose `scope`, `parent`, `dependencies`, `origins`, `scenarios` or `baseline`
   differs from the baseline, or whose Description differs from the baseline statement without a
   `Description changed: <reason>` Status-log line; a parent that does not link its baseline
   child;
4. scope and status out of step: `deferred` without `scope: future`, a future requirement in a
   status other than `deferred` or `superseded`, or `primary_gate: FUTURE` outside future scope;
5. a baseline AC that is missing or altered without a `AC-n changed: <reason>` Status-log line;
6. a version-one requirement that depends on a `deferred` requirement, or a dependency without
   a working file;
7. a working file numbered inside the baseline range without a baseline entry, or a later
   requirement without `source: derived`, `scope`, `primary_gate` or `dependencies`;
8. a missing or stale IMPORT_MAPPING.md.
It also prints requirements by status and by gate and the ticked ACs. The regression suites
for both checkers and the hooks run with `scripts/tests/run.sh`.

The checkers cover mechanics only. The lead enforces the Definition of Ready, and
`verify-requirement` judges whether ACs are met.
