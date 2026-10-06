# Traceability

This file defines how the repository links every product goal to verified, evidenced
implementation, and holds the two traceability tables. Everything is repository-native:
Markdown files, stable IDs, relative links and `grep`. The requirement format lives in
[docs/requirements/README.md](requirements/README.md). The working requirements keep the stable
AVE IDs of the immutable baseline
[ai-video-editor-requirements/](../ai-video-editor-requirements/README.md);
[IMPORT_MAPPING.md](requirements/IMPORT_MAPPING.md) maps each baseline ID to its working file, and
the baseline's own [TRACEABILITY.md](../ai-video-editor-requirements/spec/TRACEABILITY.md) maps the
user-brief clauses to requirements and scenarios.

## Model

```text
GOAL-NNN                    docs/PRODUCT.md § Product goals
└─ AVE-EPIC-NN              docs/requirements/AVE-EPIC-NN-<slug>.md    goals: [GOAL-NNN]
   └─ AVE-FEAT-NNN          docs/requirements/AVE-FEAT-NNN-<slug>.md   parent: AVE-EPIC-NN
      └─ AVE-REQ-NNN        docs/requirements/AVE-REQ-NNN-<slug>.md    parent: AVE-FEAT-NNN (or AVE-EPIC-NN)
         ├─ origins            brief clauses U01–U27, D01–D05 (frontmatter origins)
         ├─ baseline           ai-video-editor-requirements/spec/requirements/AVE-REQ-NNN.md (immutable)
         ├─ AC-n               § Acceptance criteria
         ├─ Implementation     § Implementation evidence; optional AVE-REQ-NNN anchors at entry points
         ├─ Tests              tests tagged "AVE-REQ-NNN AC-n"; planned in § Verification strategy
         ├─ Scenarios          AT-NN (frontmatter scenarios); scenario tests tagged "AT-NN"
         ├─ Evidence           § Test evidence: verify.sh result, verify-requirement verdict, per-AC results
         └─ ADR-NNN            ADR § Related requirements
Commits: "AVE-REQ-NNN: <summary>"
```

Each link has one canonical home. Other places mirror it, and the canonical home wins when
they disagree:
- Goal → Epic: EPIC `goals` frontmatter. View: [Goal coverage](#goal-coverage).
- Epic → Feature → Requirement: the child's `parent` frontmatter. Views: EPIC § Features,
  FEAT § Requirements.
- Requirement → Implementation, Tests, Evidence: the REQ file's evidence sections and the test
  tags. View: [Requirement matrix](#requirement-matrix).
- Requirement → brief clauses, acceptance scenarios, baseline file: the REQ frontmatter
  `origins`, `scenarios` and `baseline`, checked against the baseline by
  [check_baseline.py](../scripts/check_baseline.py). View: [IMPORT_MAPPING.md](requirements/IMPORT_MAPPING.md).
- Requirement ↔ ADR: the ADR's § Related requirements. View: the matrix ADRs column.
- Requirement → history: commit messages.

## What each implemented requirement exposes

1. **Requirement ID**: filename and frontmatter `id`.
2. **Implementation files and modules**: REQ § Implementation evidence; matrix Implementation
   column; optional code anchors.
3. **Tests**: test names tagged `AVE-REQ-NNN AC-n` (scenario tests also `AT-NN`); REQ § Test
   evidence; matrix Tests column.
4. **Acceptance criteria**: REQ § Acceptance criteria, ticked after a `verify-requirement` PASS.
5. **Verification evidence**: REQ § Test evidence; matrix Evidence column.
6. **Current status**: frontmatter `status`, mirrored in the matrix Status column.
7. **Related ADRs**: ADR § Related requirements; matrix ADRs column.

## Conventions

1. **Test tags.** Every test that verifies an AC carries the full tag `AVE-REQ-NNN AC-n`: Python
   tests as `@pytest.mark.req("AVE-REQ-NNN AC-n", …)` (validated against the requirement files at
   collection), tooling tests in `scripts/tests/` as a `# AVE-REQ-NNN AC-n` comment line directly
   above the case; a tooling tag counts only through a suite result of the run, with that file's exit
   status and check count, so a suite that ran no check credits nothing (`scripts/tests/run.sh` for the shell suites it lists, `scripts/evidence.py unittest` for
   `test_*.py`), and one naming no existing criterion stops the run with its file and line. A test covering several ACs carries one full tag per AC. A test that
   runs an acceptance scenario of
   [ACCEPTANCE_TESTS.md](../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md) also carries
   its scenario tag `AT-NN`; the scenario tag alone never proves a criterion.
2. **Inspection.** When automating an AC is impractical, § Verification strategy states why and
   § Test evidence records the method, date and result (`AC-n → inspection: …`).
3. **Code anchors.** Optional: one `AVE-REQ-NNN` comment at a requirement's primary entry point
   (handler, command, public function). Never tag individual lines or helpers. Retag or remove
   anchors when a requirement is superseded.
4. **Commits.** `AVE-REQ-NNN: <imperative summary>` (several: `AVE-REQ-NNN, AVE-REQ-NNN: …`); other work
   uses a type prefix ([CLAUDE.md](../CLAUDE.md) § Git). Commit a requirement together with its
   tests, evidence and traceability updates.
5. **ADRs.** An ADR lists the requirements it governs in § Related requirements; the matrix
   mirrors them.

```text
test "AVE-REQ-012 AC-2 rejects an item above the size limit"
test "AVE-REQ-012 AC-3 accepts an item exactly at the size limit"
# AVE-REQ-012 AC-1 / AVE-REQ-012 AC-4      (comment form, directly above the test)
test "lists a new item with state Ready"
test "AT-04 AVE-REQ-024 AC-1 renders the known offset within one output frame"
```

Audit commands (run from the repository root; `-w` keeps `AC-1` from matching `AC-10`;
`':!*.md'` limits a search to code and tests):

```sh
# Every reference to a requirement (docs, code, tests)
git grep -n -w --untracked "AVE-REQ-012"
# Code anchors and tests for a requirement, or for one AC
git grep -n -w --untracked "AVE-REQ-012" -- ':!*.md'
git grep -n -w --untracked "AVE-REQ-012 AC-2" -- ':!*.md'
# Tests that run an acceptance scenario
git grep -n -w --untracked "AT-04" -- ':!*.md' ':!ai-video-editor-requirements'
# Commits for a requirement
git log --oneline --grep='AVE-REQ-012[:,]'
# Requirements in a status; version-one requirements of a gate
grep -l '^status: in-progress' docs/requirements/AVE-REQ-*.md
grep -l '^primary_gate: M1$' docs/requirements/AVE-REQ-*.md
# ACs without a tagged test (expected only for ACs verified by inspection)
for ac in $(grep -oE '^- \[[ x]\] AC-[0-9]+' docs/requirements/AVE-REQ-012-*.md | grep -oE 'AC-[0-9]+'); do
  git grep -q -w --untracked "AVE-REQ-012 $ac" -- ':!*.md' || echo "no tagged test: AVE-REQ-012 $ac"
done
# Tags in code or tests that point to no requirement file
git grep -h -o -E --untracked 'AVE-REQ-[0-9]{3,}' -- ':!*.md' ':!ai-video-editor-requirements' | sort -u | while read -r id; do
  ls docs/requirements/"$id"-*.md >/dev/null 2>&1 || echo "orphan tag: $id"
done
# Baseline integrity, status and gate counts, ticked ACs
python3 scripts/check_baseline.py
# Unfilled placeholders
grep -rn '^_TBD' docs --exclude=README.md
```

## Update rules

The lead owns this file. Subagents report updates under "Shared-document updates for the lead"
in their reports. Update the tables in the same commit as the requirement change they reflect.

1. EPIC created, or its `goals` changed: update the Goal coverage rows.
2. REQ enters `in-progress`: add a matrix row with status `in-progress`, `—` for
   Implementation, Tests and Evidence, and the ADRs known so far.
3. REQ enters `verification`: update Status; fill Implementation and Tests from the REQ
   file's Implementation evidence.
4. REQ enters `done`: update Status; fill Evidence with the verdict date and a link to the REQ
   file's Test evidence; confirm Implementation and Tests are complete.
5. Any other transition of a REQ with a row (`blocked`, unblocked, reopened, `superseded`):
   update Status. Keep rows of superseded requirements.
6. ADR accepted or superseded: update the ADRs column of the affected rows.
7. The first row of a table goes on the line directly below its separator row; delete the blank
   line and the `_No entries yet._` line. Keep rows sorted by ID.

Cell formats:
- **Goal**: the plain ID; **Epics**: links to the epic files.
- **Requirement**: link to the file, `[AVE-REQ-NNN](requirements/AVE-REQ-NNN-<slug>.md)`.
- **Status**: the frontmatter value, lowercase.
- **Implementation**: up to three primary paths in code spans; the full list stays in the REQ file.
- **Tests**: test files or suites in code spans with the ACs they cover; `inspection` for ACs
  verified by inspection.
- **Evidence**: `PASS YYYY-MM-DD` plus a link to the REQ file's `#test-evidence` section.
- **ADRs**: ADR links, or `—` when none.
- `—` marks a cell with nothing recorded yet.

```markdown
| GOAL-001 | [AVE-EPIC-01](requirements/AVE-EPIC-01-example-slug.md), [AVE-EPIC-03](requirements/AVE-EPIC-03-example-slug.md) |
| [AVE-REQ-012](requirements/AVE-REQ-012-example-slug.md) | done | `<path/to/module>`, `<path/to/other-module>` | `<path/to/test-file>` (AC-1–AC-3), inspection (AC-4) | PASS 2026-10-05 — [Test evidence](requirements/AVE-REQ-012-example-slug.md#test-evidence) | [ADR-004](decisions/ADR-004-example-slug.md) |
```

`./scripts/check-project-control.sh` enforces, for the matrix outside code fences: the header row
exists; rows follow it with no blank or text line between them; each row names one REQ ID, at
most once; each row's requirement file exists; each row's status equals the file's frontmatter
status; every `done` requirement has a row; every relative link resolves.
`python3 scripts/check_baseline.py` enforces the link from each working requirement to its
baseline (origins, scenarios, dependencies, criteria). `milestone-review` audits the rest:
1. Every GOAL in [PRODUCT.md](PRODUCT.md) § Product goals not marked `retired` has at least one
   epic that is not superseded.
2. Every `done` row has Implementation, Tests and Evidence filled.
3. The untagged-AC loop above reports only ACs whose Test evidence records an inspection.
4. The orphan-tag loop reports nothing.
5. The ADRs column matches each ADR's § Related requirements.
6. Every acceptance scenario `AT-NN` named by a `done` requirement has a tagged test whose latest
   run passed on real rendered output, or is a whole-product scenario that the requirement's
   § Verification strategy schedules for the final review (AT-29 to AT-31 run in M7,
   [ROADMAP.md](ROADMAP.md)); the final review runs those and audits them under this rule.

## Scale

Markdown tables and grep suffice for up to a few hundred requirements and one lead session.
Consider a heavier mechanism when requirements exceed a few hundred, several humans edit
concurrently, the matrix becomes a frequent merge-conflict hotspot, or compliance demands
formal trace reports. First step: generate the matrix from frontmatter and test tags with a
script run by `./scripts/verify.sh`; next step: a dedicated requirements tool. Record either
move in an ADR (see the revisit trigger in
[ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)).

## Goal coverage

| Goal | Epics |
|---|---|
| GOAL-001 | [AVE-EPIC-01](requirements/AVE-EPIC-01-project-and-asset-management.md) |
| GOAL-002 | [AVE-EPIC-02](requirements/AVE-EPIC-02-editing-and-composition.md) |
| GOAL-003 | [AVE-EPIC-03](requirements/AVE-EPIC-03-synchronized-perspectives-and-sound.md) |
| GOAL-004 | [AVE-EPIC-04](requirements/AVE-EPIC-04-presentation-chapters-and-looks.md) |
| GOAL-005 | [AVE-EPIC-05](requirements/AVE-EPIC-05-ai-orchestration-and-integration.md) |
| GOAL-006 | [AVE-EPIC-06](requirements/AVE-EPIC-06-media-intelligence-and-captions.md) |
| GOAL-007 | [AVE-EPIC-07](requirements/AVE-EPIC-07-short-form-content-and-delivery.md) |
| GOAL-008 | [AVE-EPIC-08](requirements/AVE-EPIC-08-reliability-security-and-operations.md) |
| GOAL-009 | [AVE-EPIC-09](requirements/AVE-EPIC-09-claude-code-delivery-process.md) |
| GOAL-010 | [AVE-EPIC-10](requirements/AVE-EPIC-10-explicit-future-scope.md) |

## Requirement matrix

| Requirement | Status | Implementation | Tests | Evidence | ADRs |
|---|---|---|---|---|---|
| [AVE-REQ-004](requirements/AVE-REQ-004-media-probing-exact-dimensions-and-source-timing.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| [AVE-REQ-012](requirements/AVE-REQ-012-canonical-rational-timing-and-temporal-invariants.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| [AVE-REQ-018](requirements/AVE-REQ-018-configurable-canvas-dimensions-and-output-rate.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| [AVE-REQ-019](requirements/AVE-REQ-019-aspect-preserving-composition-and-transforms.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| [AVE-REQ-020](requirements/AVE-REQ-020-two-perspective-split-screen-layout.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| [AVE-REQ-021](requirements/AVE-REQ-021-mixed-split-screen-and-full-width-segments.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md), [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) |
| [AVE-REQ-024](requirements/AVE-REQ-024-audio-based-offset-estimation.md) | in-progress | — | — | — | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| [AVE-REQ-031](requirements/AVE-REQ-031-explicit-master-audio-and-routing.md) | in-progress | — | — | — | [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) |
| [AVE-REQ-072](requirements/AVE-REQ-072-real-export-pipeline-and-default-delivery-profile.md) | in-progress | — | — | — | [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) |
| [AVE-REQ-075](requirements/AVE-REQ-075-cpu-only-reference-rendering.md) | in-progress | — | — | — | [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) |
| [AVE-REQ-093](requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md) | in-progress | `scripts/check_baseline.py`, `scripts/reqfile.py`, `scripts/requirements/import_baseline.py`, `docs/requirements/IMPORT_MAPPING.md` | `scripts/tests/test-check-baseline.sh` (AC-1, AC-3, AC-4), `scripts/tests/test_evidence.py` (AC-4), inspection (AC-2) | — | [ADR-003](decisions/ADR-003-requirements-baseline-import.md) |
| [AVE-REQ-094](requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md) | in-progress | `docs/ENVIRONMENT_CAPABILITIES.md`, `scripts/probe-environment.sh`, `docs/WORKFLOW_LOG.md`, `CLAUDE.md` § Delegation, `.claude/skills/develop/SKILL.md`, `.claude/skills/resume-project/SKILL.md` | `scripts/tests/test-probe-environment.sh` (AC-1), inspection (AC-1–AC-4) | — | [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md) |
| [AVE-REQ-096](requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md) | in-progress | `docs/briefs/`, `docs/briefs/handbacks/`, `scripts/check-project-control.sh`, `scripts/verify.sh`, `.claude/skills/develop/SKILL.md`, `CLAUDE.md`, `.claude/settings.json` | `scripts/tests/test-checker.sh` (AC-1, AC-2), `scripts/tests/test-verify-tiers.sh` (AC-4), inspection (AC-1–AC-4) | — | [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md) |
| [AVE-REQ-097](requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md) | in-progress | `scripts/verify.sh`, `scripts/evidence.py`, `scripts/reqfile.py`, `scripts/tests/run.sh`, `backend/tests/evidence_plugin.py` | `scripts/tests/test-verify-tiers.sh`, `scripts/tests/test_evidence.py`, `backend/tests/unit/test_evidence_plugin.py`, `scripts/tests/test-stop-hook.sh` (AC-1–AC-4) | — | [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md), [ADR-003](decisions/ADR-003-requirements-baseline-import.md) |
| [AVE-REQ-098](requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md) | in-progress | `docs/PROGRESS.md`, `.claude/hooks/session-start.sh`, `.claude/hooks/stop-verify.sh`, `scripts/check-project-control.sh`, `.env.example`, `docs/ENVIRONMENT_CAPABILITIES.md`, `CLAUDE.md` § Git, `.claude/skills/develop/SKILL.md`, `.claude/skills/resume-project/SKILL.md` | `scripts/tests/test-session-start.sh` (AC-1, AC-2), `scripts/tests/test-checker.sh` (AC-2, AC-3, AC-4), `scripts/tests/test-probe-environment.sh` (AC-3), `scripts/tests/test-stop-hook.sh` (AC-4), inspection (AC-1, AC-3, AC-4) | — | [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md) |
