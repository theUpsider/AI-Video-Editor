# Brief — M0 final review fixes: baseline gate, run environment and fingerprint, evidence tool and checker

## Requirements
The final review round of M0 (run `wf_7d9d015c-906` at `2df637f`) returned FAIL for AVE-REQ-093, AVE-REQ-097,
AVE-REQ-096 and AVE-REQ-098. Each report holds, per finding, the location, the defect, the reproduction and a
proposed fix; read your track's findings there in full before coding:
[part 5](handbacks/2026-10-03-m0-gates-red-team.part-5.md) (AVE-REQ-093),
[part 6](handbacks/2026-10-03-m0-gates-red-team.part-6.md) (AVE-REQ-097),
[part 7](handbacks/2026-10-03-m0-gates-red-team.part-7.md) (AVE-REQ-096),
[part 8](handbacks/2026-10-03-m0-gates-red-team.part-8.md) (AVE-REQ-098). Three tracks, one writer each; a
prompt names its track. The lead repairs AVE-REQ-094 on its task branch and the lead-owned documents.

**Track A — baseline gate (AVE-REQ-093 AC-1, AC-3, AC-4).** Part 5, blocking 1 to 4 and non-blocking 1 to 8:
1. "The canonical form admits headings that a CommonMark reader renders" (list-item and quote forms, setext
   underlines) and "invisible characters outside the classes Cc, Cf, Zl, Zp, Zs also pass". Decision: outside the
   frontmatter and fenced blocks a line is judged after its leading spaces and every container marker (`>`, `-`,
   `*`, `+`, `N.`, `N)`) are removed: the rest opens no ATX heading (the template headings at column 0
   excepted) and is no run of `=` or of `-` alone. Characters follow an allow-list: U+0020 to U+007E, the line
   feed, and the other characters the baseline package and the working files hold today, each listed by code
   point in `scripts/reqfile.py`; a marker reason holds a letter or a digit. Raw HTML (`<` before a letter, `/`,
   `!` or `?`) fails outside code spans and fenced blocks.
2. "The rule 'a milestone with Status done that lists an unfinished requirement → fails' fires only when the first
   word … is exactly `done`". Decision: the Status line of every `### M<n>` entry matches
   `- **Status:** planned|in-progress|done` exactly; any other line, or none, fails.
3. "`from __future__ import annotations` … runs before the restart". Decision: `import os, sys` and the restart
   are the first statements `scripts/check_baseline.py` executes; the documents scope the guarantee to the
   isolated start `python3 -I -B` (verify.sh, CI) and name `PYTHONPATH` with a `sitecustomize` as local state
   for any other start.
4. The AC-4 strategy sentence about every tier is false for the fast and media tiers: state the rule as
   `scripts/verify.d/95-evidence.sh` and README § Definition of Done item 4 hold it.
5. Non-blocking: requirement lists of ROADMAP.md by their template labels only, `~~~` fence lines rejected
   there; a `Gate change` note for a successor under another milestone; every ID a supersession chain visits
   may keep `source: human`; a suite case that needs the chain-end dependency rule; the one-file rule keyed by
   kind and number; an imported requirement never returns to `proposed`; a feature or epic is `done`, and its
   acceptance boxes ticked, only when every non-superseded child is `done`; change marks of 16 hex digits (no
   working file holds a mark yet); rule 5 of the import mapping reworded in the importer and
   `IMPORT_MAPPING.md` regenerated.

**Track B1 — run environment, fingerprint, hooks (AVE-REQ-097 AC-2, AC-3, AC-4; AVE-REQ-096 AC-4; AVE-REQ-098
AC-2, AC-4).** Part 6 blocking 2, 3, 4 and non-blocking 2 (variables, line ends), 3 (the step); part 7
non-blocking 1; part 8 blocking 2 and non-blocking 7, 8, 11:
1. "Variables of the caller that change what Python and pytest load still reach the steps" (`PYTHONUSERBASE`,
   `UV_ENV_FILE`). Decision: the steps start from a named set of variables. `clean_environment` unsets every
   exported variable and exported function outside the set (`PATH`, `HOME`, `USER`, `LOGNAME`, `TMPDIR`, `LANG`,
   `LC_ALL`, `TZ`, the `UV_` variables the container and CI need to find the locked environment and its cache,
   `AVE_HEAVY_LOCK`, `AVE_HEAVY_LOCK_HELD`; derive the exact set from `scripts/dev-container.sh`,
   `.devcontainer/Dockerfile` and `.github/workflows/verify.yml`), then sets its own (`PYTHONSAFEPATH`,
   `PYTHONNOUSERSITE`, `PYTEST_DISABLE_PLUGIN_AUTOLOAD`, the bytecode prefix); `AVE_FFMPEG` and `AVE_FFPROBE`
   of the caller are outside the set; `backend_uv` passes `--no-env-file`. The tiers suite prints the names a
   step sees and compares them with the set.
2. "Two further local Git states hide an edited file from the fingerprint" (`ident`, fsmonitor). Decision: the
   fingerprint hashes the bytes the steps read. For every path of
   `git -c core.fsmonitor=false -c core.untrackedCache=false ls-files -z --cached --others
   --exclude-per-directory=.gitignore` it takes the index mode (or `untracked`), and the raw content hash
   (`git hash-object --no-filters`), `missing` for a path absent from the working tree, or the link text of a
   symbolic link; the fingerprint is the hash of the sorted listing. No index flag, attribute, filter, local
   ignore rule or fsmonitor state takes part; a tree with a gitlink or an embedded repository keeps no
   fingerprint. The same value comes out under Git Bash on the Windows host and in the container. Replace the
   cases of `vstate_blind` by cases in which each of those states leaves an edit visible in the fingerprint.
3. "The stand-in replaces AVE_FFMPEG and AVE_FFPROBE … PATH still holds the real tools". Decision: the fast
   pytest step also puts a directory with `ffmpeg` and `ffprobe` stand-ins first on `PATH` (built in the run's
   scratch directory from `scripts/lib/media-tier-only.sh`).
4. The ignored-file step fails when Git itself fails inside a work tree (a missing repository is the one skip).
5. An inherited `AVE_HEAVY_LOCK_HELD=1` fails closed: without `flock`, or with a lock file that cannot be
   opened, the run fails before any step.
6. `scripts/tests/test-session-start.sh` asserts the injected content (branch line, commit lines, last
   verification, PROGRESS.md block, uncommitted list) for startup, resume and compact; the three mutants of the
   report each fail it.
7. The failed-attempt counter of the Stop hook is read back after it is stored; the comment on the attempt
   limit states what a limit of 1 does; the header of `scripts/lib/verify-state.sh` says whose runs
   `last-result` records.

**Track B2 — evidence tool, suite runner, plugin, checker (AVE-REQ-097 AC-2, AC-3, AC-4; AVE-REQ-096 AC-1;
AVE-REQ-098 AC-1, AC-3, AC-4).** Part 6 blocking 1 and non-blocking 2 (the failed lighter tier), 3 (the plugin),
4, 7 (items 1 and 3); part 5 blocking 3 (the hint in `scripts/evidence.py`); part 7 non-blocking 3; part 8
non-blocking 6, 9, 10:
1. "The suite runner itself counts as a tooling test file that carries `AVE-REQ-097 AC-4` … and it never has a
   suite result". Decision: `scripts/tests/run.sh` holds no criterion tag, and a comment tag in a file of
   `scripts/tests/` that is neither a suite `run.sh` lists nor a `test_*.py` file stops `record` and
   `check-done` with file and line; one case runs on the real directory.
2. A unit case: a passing fresh release manifest beside a failed fresh fast manifest gives exit 1 for
   `show --require-complete`. Unit-test tags bind to class-qualified test IDs. `record` without `var/verify`
   creates it or ends with a tool error. The hint for the baseline checker names the isolated command.
3. The plugin fails the session when Git fails inside a work tree.
4. Check 12: the Stop handler has type `command` and the exact registered command with nothing after it; the
   `env` block holds none of `SHELLOPTS`, `BASHOPTS`, `BASH_ENV`, `ENV`; hook commands with `until`,
   `for ((;;))`, `while [ 1 ]`, `while :` or `--permission-mode` fail. Check 7: `under way`, `still executing`,
   `ongoing` and `runs now` fail like the listed wordings. `.claude/settings.local.json` stays unchecked (a
   personal file; the lead states the limit).
5. Check 11: HTML comments are removed before a section is judged; a file in `docs/briefs/` that is neither a
   `*.md` brief, `README.md`, `drafts/` nor `handbacks/`, and a hidden file in `handbacks/`, fail. Report the
   input-revision forms that still count as a commit.
6. The missing-heading case of PROGRESS.md loops over every heading the checker requires.

## Input revision
The commit that adds this brief, `git log -1 --format=%h -- docs/briefs/2026-10-06-m0-final-review-fixes.md`
(its parent is `547754e`). Isolated worktree per track, created by the lead from that commit; the prompt names
the full hash, and the task confirms that `git rev-parse HEAD` prints exactly it before changing anything.

## Allowed paths
- Track A: `scripts/reqfile.py`, `scripts/check_baseline.py`, `scripts/requirements/import_baseline.py`,
  `docs/requirements/IMPORT_MAPPING.md` (regenerated), `scripts/tests/test-check-baseline.sh`,
  `docs/requirements/README.md`, `docs/ROADMAP.md` (rule text of § Rules only),
  `docs/requirements/AVE-REQ-093-*.md` (§ Edge cases, § Verification strategy, § Implementation evidence).
- Track B1: `scripts/verify.sh`, `scripts/verify.d/20-backend.sh`, `scripts/lib/verify-state.sh`,
  `scripts/lib/media-tier-only.sh`, `.claude/hooks/stop-verify.sh`, `.claude/hooks/session-start.sh`,
  `scripts/tests/test-verify-tiers.sh`, `scripts/tests/test-stop-hook.sh`, `scripts/tests/test-session-start.sh`,
  `scripts/tests/make-fixture.sh`; `scripts/dev-container.sh` and `.github/workflows/verify.yml` only for a
  variable the named set needs; a case of `scripts/tests/test_evidence.py` only where your change breaks it.
- Track B2: `scripts/evidence.py`, `scripts/tests/run.sh`, `scripts/tests/test_evidence.py`,
  `backend/tests/evidence_plugin.py`, `backend/tests/unit/test_evidence_plugin.py`,
  `scripts/check-project-control.sh`, `scripts/tests/test-checker.sh`; a line of `docs/PROGRESS.md` only where a
  new wording rule flags it.

## Forbidden paths
The paths of the other tracks. `scripts/probe-environment.sh`, `scripts/tests/test-probe-environment.sh` (the
lead repairs AVE-REQ-094 on its branch). `ai-video-editor-requirements/**`. Every document outside your allowed
list: `CLAUDE.md`, `.claude/skills/**`, `.claude/agents/**`, `docs/ARCHITECTURE.md`, `docs/ASSUMPTIONS.md`,
`docs/TRACEABILITY.md`, `docs/WORKFLOW_LOG.md`, the requirement files of AVE-REQ-096, AVE-REQ-097 and
AVE-REQ-098 (propose their text in the handback), frontmatter, criteria, Test evidence and Status log of every
requirement file.

## Dependencies and constraints
- Every rule you add or change gets a named suite case that fails without it. Before the handback run one
  one-line mutant per rule and list mutant and failing case; delete `__pycache__` directories before a rerun of
  changed Python ([WF-004](../WORKFLOW_LOG.md)).
- A statement you write into a document holds for every form it names. Where a rule knows a list of forms, the
  text names the list and says who judges the rest (the diff review, `verify-requirement`).
- Never weaken a test, a tolerance or a gate. The working tree as committed passes the tightened rules; when a
  new rule flags an existing file outside your paths, report it.
- Host: Windows with Git Bash; `./scripts/verify.sh` enters the Linux development container by itself, every
  other check takes the prefix `./scripts/dev-container.sh` (ADR-009). The media and release tiers wait for the
  heavy-media lock; one other writer works on this host.
- Documents and messages state things affirmatively and avoid the forms "X, not Y", "rather than" and "instead
  of"; no file names a model or a local user path.
- Commit on your worktree branch when verification passes (`AVE-REQ-NNN: <imperative summary>`, ending with the
  trailer lines the prompt gives); never push, merge, rebase or switch branches.

## Test commands
- `./scripts/verify.sh --tier release` passes on your final tree.
- Track A: `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` and
  `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py`.
- Track B1: `./scripts/dev-container.sh bash scripts/tests/test-verify-tiers.sh`, `test-stop-hook.sh` and
  `test-session-start.sh` the same way; the fingerprint of the worktree printed under Git Bash and in the
  container (`. scripts/lib/verify-state.sh && vstate_fingerprint`) is the same value.
- Track B2: `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests`,
  `./scripts/dev-container.sh bash scripts/tests/test-checker.sh --all-awks`, and the plugin tests through the
  fast tier.

## Handback schema
`## Result: COMPLETE | PARTIAL | BLOCKED`, then: branch and commit hash; per finding (report part and number)
its disposition (fixed, stated as a limit, or open with the reason), the files and the named case; the mutation
list (mutant, failing case); commands run with results; proposed text for lead-owned documents (requirement
files of AVE-REQ-096, AVE-REQ-097, AVE-REQ-098, ARCHITECTURE.md, ASSUMPTIONS.md); deviations and discovered
work. The lead writes the returned report to `docs/briefs/handbacks/2026-10-06-m0-final-review-fixes.part-<n>.md`
(part 1 track A, part 2 track B1, part 3 track B2).
