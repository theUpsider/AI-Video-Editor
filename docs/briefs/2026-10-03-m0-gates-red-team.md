# Brief — Red-team the M0 gates of AVE-REQ-093 and AVE-REQ-097 with six lenses before their next reviews

## Requirements
AVE-REQ-093 (AC-1, AC-3, AC-4) and AVE-REQ-097 (AC-1 to AC-4). Both passed `verify-requirement` more than once
and each PASS fell to a skeptic's single probe; this task enumerates the remaining probes in one pass.

History, each finding reproduced by its reviewer and fixed since:
- AVE-REQ-093, review 2 (`d4d3883`): the per-file hash check lived in the package's own validator; editing that
  file disabled it. Fixed in `0e4f8d9`.
- AVE-REQ-093, review 3 skeptic (`97a8d20`): a continuation line, a fenced block or a sub-heading inside
  § Acceptance criteria qualified a criterion unnoticed. Fixed in `a681e4d` (also: symbolic links in the package).
- AVE-REQ-093, review 4 skeptic (`08237ac`): a version-one must-have was retired through `superseded_by` naming a
  weaker requirement that carried none of its criteria. Fixed in `442f68c` (also: added criteria and ticks).
- AVE-REQ-093, review 5 skeptic (`442f68c`, cut off by a session restart; the lead reproduced its probe): the
  future-scope AVE-REQ-101 was superseded by a derived version-one requirement. Fixed in `56e5864` (future-scope
  supersession, superseded features and epics).
- AVE-REQ-097, review 2 skeptic (`d4d3883`): a listed shell suite reduced to a tagged `exit 0` credited every
  tag it carried. Fixed in `a10e2df` (check counts).

Task: find every remaining way to make a gate pass, or evidence credit a criterion, while the behavior the
criterion states is violated; and every statement in the two requirements' § Edge cases, § Verification
strategy and § Implementation evidence, or in the rules they cite, that is false as written. One read-only
finder per lens, each in a private clone:

- 093-A — working-file text: frontmatter keys and values (duplicates, quoting, case, whitespace, Unicode
  look-alikes, byte-order marks, line endings), sections (repeated, renamed, nested, indented, setext or
  HTML headings, comments, fences), criterion lines and ticks, the Status log (dates, statuses, reasons, order),
  and differences between the Python parser of `scripts/check_baseline.py`, the awk parser of
  `scripts/check-project-control.sh` and what a Markdown reader sees.
- 093-B — lifecycle and planning: statuses and transitions of requirements, features and epics (superseded
  chains and cycles, deferred, blocked, done), derived requirements that shadow, narrow or absorb baseline ones,
  parents and children, dependencies, primary gates, ROADMAP.md and TRACEABILITY.md gating, IMPORT_MAPPING.md,
  and what `milestone-review` and `develop` then skip.
- 093-C — package and repository state: the manifest and its entries, file kinds and modes, links, nested
  repositories and gitlinks, ignored and untracked files, `.gitattributes` and Git filters, case and
  normalization of names, how `scripts/requirements/import_baseline.py` reads the package compared with the
  package validator (a field one reads and the other ignores), and environment variables or the working
  directory that change what the checker reads.
- 097-D — tiers and the suite runner: `scripts/verify.sh`, `scripts/verify.d/*.sh`, `scripts/tests/run.sh` and
  the suites it lists: steps that can pass without running their checks, tier selection, exit-code handling,
  output parsing (the `TOTAL` line), suites or cases that never run, environment variables, the working-tree
  step, the heavy-media lock variables.
- 097-E — evidence and the done gate: `scripts/evidence.py` (`record`, `show`, `check-done`, `unittest`,
  `record-suite`), the manifest, the tree fingerprint and freshness, `latest-<tier>.json`, run directories,
  tags and their validation, inspection lines, contract-only evidence, a `done` requirement with missing,
  stale or foreign evidence, and what the fast tier leaves unchecked that the Stop gate relies on.
- 097-F — the pytest plugin, the hooks and CI: `backend/tests/evidence_plugin.py` and `conftest.py` (markers,
  parametrization, deselection, skips, expected failures, collection errors, swallowed exceptions, `addopts`
  and configuration files), `.claude/hooks/stop-verify.sh` and `scripts/lib/verify-state.sh` (attempt counting,
  release, fingerprint reuse, tier), `.claude/settings.json`, `.github/workflows/verify.yml`.

Scope rule for every finding:
- Blocking: a change to anything other than the gate's own code (requirement and document files, the baseline
  package, test files and fixtures, configuration and data files, the environment, Git state) lets a gate pass
  or an AC be credited while the criterion's behavior is violated; or a statement of the requirement, the README
  or the skills about what the gate rejects is false.
- Boundary: the path needs an edit to the gate's own code or pins, or it rests on free text or on a vacuous
  test that only a reader can judge. Each requirement's § Edge cases names these limits and the inspection that
  covers them (`verify-requirement`, commit review). Report a boundary path only when the documents claim a
  mechanical guard for it, or when the named inspection could not see it.
- Every finding carries the exact reproduction (commands and the observed output, run in the clone) and the
  smallest fix with the suite case that would hold it.

## Input revision
The commit that adds this brief (`git log -1 --format=%h -- docs/briefs/2026-10-03-m0-gates-red-team.md`); every
finder works in a private clone of the main checkout at that commit and modifies nothing in the main working
tree.

## Allowed paths
None in the repository. Each finder changes files only inside its private clone
`.claude/worktrees/redteam-<lens>` and removes the clone at the end. The lead persists the combined result as
`docs/briefs/handbacks/2026-10-03-m0-gates-red-team.md`.

## Forbidden paths
Every path of the main working tree and of the worktree `.claude/worktrees/ave-req-094-probe-evidence`;
`ai-video-editor-requirements/` outside the private clone; commits, pushes, `git worktree prune`.

## Dependencies and constraints
- ADR-009: checks run in the development container through `./scripts/dev-container.sh`; a private clone is made
  with `git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/<name>` and gets
  its own container, stopped at the end with `./scripts/dev-container.sh --stop`.
- Heavy media jobs serialize on the shared heavy-media lock: a media or release tier run waits for it by
  itself. The 093 lenses need no heavy job. The 097 lenses probe through `scripts/tests/run.sh`,
  `scripts/evidence.py` and the fast tier, and run the release tier at most once each, to confirm a finding end
  to end.
- Mutated Python runs after every `__pycache__` directory is deleted (WF-004). Probes restore the clone
  (`git status --short` empty) before the next probe.
- Read-only review: six finders run concurrently; no writing agent runs in this task.
- The requirement text, the README rules and earlier reviews are claims; a finding rests on a run in the clone.
- Repository text states things affirmatively and names no model.

## Test commands
Baseline for every finder, in its clone, before the first probe:
- `./scripts/verify.sh` — fast tier passes.
- 093 lenses: `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` and
  `./scripts/dev-container.sh python3 -B scripts/check_baseline.py`.
- 097 lenses: `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest` and
  `./scripts/dev-container.sh bash scripts/tests/run.sh`.

## Handback schema
Each finder returns a structured result: `lens`; `findings`, each with `title`, `criterion` (requirement and
AC), `class` (blocking or boundary), `reproduction` (exact commands), `observed` (the output that shows the gate
passing), `expected`, `fix` (smallest change and the suite case that holds it); `held` (the probes that the
gates rejected, one line each, so the lead sees the coverage); `baseline` (the results of the test commands);
`cleanup` (clone removed, container stopped, main checkout untouched).
