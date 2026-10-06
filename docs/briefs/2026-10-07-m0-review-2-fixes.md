# Brief — M0 review round two, fixes: baseline gate, probe, run environment, checker and evidence tool

## Requirements
The second round of the final M0 review (run `wf_b18a5f3e-54e` at `f996c17`) returned FAIL for AVE-REQ-093,
AVE-REQ-094 and AVE-REQ-097, and a PASS that the skeptic refuted for AVE-REQ-096 and AVE-REQ-098. Each report
holds, per finding, the location, the defect, the reproduction and a proposed fix; read your track's findings
there in full before coding:
[part 1](handbacks/2026-10-06-m0-final-review-2b.part-1.md) (AVE-REQ-093),
[part 2](handbacks/2026-10-06-m0-final-review-2b.part-2.md) (AVE-REQ-094),
[part 3](handbacks/2026-10-06-m0-final-review-2b.part-3.md) (AVE-REQ-096),
[part 4](handbacks/2026-10-06-m0-final-review-2b.part-4.md) (AVE-REQ-097),
[part 5](handbacks/2026-10-06-m0-final-review-2b.part-5.md) (AVE-REQ-098). Four tracks, one writer each; a
prompt names its track. The lead closes AVE-REQ-096 and the lead-owned documents.

Every blocking finding of both rounds has one shape: a sentence of a requirement file holds for the forms a fix
listed and fails for a neighbouring form ([WF-010](../WORKFLOW_LOG.md)). A track therefore does two things: it
closes its findings (the items below), and it audits the statements of its requirement (the statement audit
under § Dependencies and constraints). Where an item says "by allow-list", the rule names the forms it admits
and fails every other form, so a form nobody thought of fails by construction.

**Track A — baseline gate (AVE-REQ-093 AC-3).** Part 1, blocking 1 and 2, non-blocking 3:
1. Footnotes. A heading on the first line of a footnote definition passes the canonical form and GitHub renders
   it. Decision: a requirement, feature or epic file holds no footnote syntax; `[^` outside code spans and
   fenced blocks fails.
2. Fenced blocks by allow-list. Lines inside a fenced block are exempt from the heading rules, so the reader and
   a CommonMark renderer must agree on every line that opens or closes one. Compare the reader with CommonMark
   for an indent of four or more spaces, a closing fence shorter than the opening one, a backtick in the info
   string, tildes, trailing text on a closing line and a fence inside a container. Decision: the canonical form
   admits one fence form (a line at column 0 of exactly three backticks with an optional info word of letters,
   digits, `_` or `-`; the closing line is exactly three backticks at column 0); every other line whose text
   behind leading spaces and container markers opens with three or more backticks or tildes fails. The same
   holds for `docs/ROADMAP.md`.
3. Roadmap. Raw HTML other than a comment hides a Status line, an entry or a link from the rendered page while
   the gate reads it, and a second Status line in another emphasis form passes. Decision: `read_roadmap()`
   judges every line of `docs/ROADMAP.md` outside fenced blocks by the requirement reader's rules for raw HTML
   and unpaired backtick runs and by its character allow-list (with U+2026 added when the file needs it). An
   entry line whose text behind the bullet, with the emphasis marks `*` and `_` removed, opens with `status` in
   any letter case is a Status line, and the rule of exactly one line of the exact form stays. The labels of the
   lists the gate reads follow the same normalization: a second line that reads as such a label fails. A heading
   that opens with `### M` and a digit and is no entry heading of the template form fails.
4. Successor status (non-blocking 3). Decision: the end of the supersession chain of an imported requirement is
   never `proposed`; the rule that holds for the imported file holds for its replacement.
5. Differential check during the task. The reviewer compared the gate with cmark-gfm (footnotes option) and
   with markdown-it-py (footnote plugin). Do the same in the container's `/tmp` (`uvx` or `uv pip install
   --target`; when the package index is unreachable, report it and reason from the CommonMark and GFM
   specifications): for at least forty constructs (containers, footnotes, raw HTML forms, fences, emphasis
   forms, link reference definitions, tables, entity and numeric character references, backslash escapes, hard
   line breaks, tabs), insert each into a copy of a working requirement file and of the roadmap and compare what
   the renderer shows (headings, the criteria list, Status items, the requirement links of an entry) with what
   the gate reads. Each construct where the two differ fails the gate after this task or stands in the
   handback as a limit with proposed text for § Edge cases. The script stays in `/tmp`; the handback holds the
   construct list with the result per construct.

**Track C — capability probe (AVE-REQ-094 AC-1).** Part 2, blocking 1 and 2, non-blocking 1, 2, 4 and 6:
1. Node walk. The whole-name test runs on lines of `find` output and the access test opens with a form that
   creates a missing path. Decision: the probe decides each name as one string (a glob walk in the shell with
   the name test in the shell, or a NUL-delimited listing), requires a character device behind links, and opens
   without creating (`[ -c ]` first, then a non-creating open for reading and writing); the two list lines and
   the verdict come from the same walk, so a linked `dri` lists what it counts. The probe changes no file: a
   suite case compares the listing of the device directory before and after a run. Cases: `nvidia0<LF>x`,
   `dri/renderD128<LF>.bak`, `xnvidia0`, `dri/card-renderD128`, `dri/nvidia0`, a linked `dri`, a render node of
   one digit and of two (the reviewer's mutants N3, N10 and N17 then fail).
2. Network scenarios. Each of the seven hosts answers in one scenario and gets no response in the other; the
   reviewer's mutant O17 then fails.
3. `nvidia-smi` rows: `, 16 MiB` and `Tesla T4, 15360 MiB (shared)` read as no GPU, each with a case.
4. Quota lines. The CPU and memory lines print kernel totals. Decision: the probe prints two more lines, the
   CPU quota and the memory limit of its cgroup (cgroup v2 files `cpu.max` and `memory.max` under a directory
   that a test variable replaces; `none` for `max` and for a missing file), with cases on a fixture directory.
5. `CDPATH`: the root comes from `CDPATH= cd -- ...`; a case exports `CDPATH`.
6. Time limit: `AVE_PROBE_SMI_TIMEOUT` counts only as a positive integer (10 otherwise), with a case.
The node forms an unprivileged suite cannot build (a node made by `mknod`, a block device, a node readable or
writable only) are checked once by hand in the container (`mknod`, `setpriv`) and reported with the commands,
so the lead can name them as inspection.

**Track B1 — run environment and hooks (AVE-REQ-097 AC-2, AC-4; AVE-REQ-098 AC-4).** Part 4, blocking 1 and 2,
non-blocking 2, 3 (the fingerprint half) and 4; part 5, non-blocking 6 (third item) and 10:
1. Ignored files by allow-list. A file that a `.gitignore` rule ignores outside four directories takes part in
   the steps and in no fingerprint (`backend/ave.pyc`, a `.gitignore` in a subdirectory that hides `mypy.ini`,
   `ruff.toml` or a link target). Decision: the ignored-file step covers the whole tree. It fails on every path
   of `git ls-files --others --ignored --exclude-per-directory=.gitignore` (the ignore source of the
   fingerprint) outside a written list of paths that no step loads, each entry with its reason in a comment;
   derive the list from the root `.gitignore` and from what the steps, the hooks and the container write, and
   show by a run for each entry that no step reads it (a `__pycache__` directory under the bytecode prefix, a
   bytecode file outside one, `backend/.venv/` when the environment variable names another directory). The tree
   holds one `.gitignore`, at its root: any other `.gitignore`, tracked or untracked, fails the step. Each tool
   reads the configuration the tree tracks: ruff starts with `--config pyproject.toml`, mypy with
   `--config-file pyproject.toml`, pytest with `-c pyproject.toml`; check every other tool a step starts for a
   configuration file it would find first. Cases: the three forms of the finding and a control per list entry.
2. Caches. ruff starts with `--no-cache` (or a cache directory in the run's scratch directory). After a release
   run in a fresh checkout `git status --porcelain --ignored` shows only paths of the list of item 1; a suite
   case or the handback shows the listing.
3. The comment in `scripts/verify.d/20-backend.sh` and the docstring of
   `backend/tests/unit/test_fast_tier_media_tools.py` name both ways a test reaches a real media tool in the
   fast tier (an absolute path, a `PATH` of its own).
4. Fingerprint variables: a Stop-hook suite case per redirecting variable (`GIT_INDEX_FILE`,
   `GIT_OBJECT_DIRECTORY`, `GIT_COMMON_DIR`, `GIT_NAMESPACE`) expects the cache hit of this tree; the reviewer's
   mutant S5 then fails.
5. Generator digest. It covers three files while the generator imports further `ave` modules. Decision: the
   digest covers the source of every `ave` module in the static import closure of the generator (found by
   reading the imports, the same in every process), with a unit case that changes one imported helper; when the
   closure costs more than about forty lines, keep the digest and propose the limit sentence.
6. Failed-attempt counter: a value that is no decimal number of one or two digits counts as 0, and a number
   with a leading zero is read as decimal; cases for `08`, `09`, `007` and a 19-digit number. The suite comment
   says which case stands for a counter that cannot be stored.

**Track B2 — checker and evidence tool (AVE-REQ-098 AC-2, AC-3, AC-4; AVE-REQ-097 AC-2, AC-3; AVE-REQ-096 AC-1,
AC-2).** Part 5, the challenge and non-blocking 1, 3, 4, 5 and 6 (first two items); part 4, non-blocking 1, 3
(the `_run` half) and 6; part 3, non-blocking 3:
1. Settings file. A `.claude/settings.json` whose top-level value is no JSON object passes checks 3 and 12 with
   both hooks gone. Decision: such a file fails with a line that names the rule; the comment that says check 3
   reports it is corrected. Cases: `[]`, `null`, a string, a list that holds an object. The suite's edit helper
   reports a setup failure by its own line, and each new case asserts the rule's error line.
2. Hook registrations by allow-list. A SessionStart command that names the hook in a comment, discards its
   output or runs behind `false &&` passes. Decision: the SessionStart command equals the registered form
   `"$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh` exactly, as the Stop command does. For both
   registrations the group object holds `hooks` (SessionStart also `matcher`), and a handler holds `type`,
   `command` and optionally `timeout`; any other key fails. `clear` joins the sources a matcher must cover.
   Cases: the five forms of part 5 non-blocking 1, a foreign key in a group and in a handler, a matcher without
   `clear`.
3. Wrapped claims. Check 7 reads one line at a time, so a listed wording split by a line wrap passes. Decision:
   the check joins the lines of a paragraph or list item before it matches; cases for the four split wordings
   and for the hyphen forms `still-executing` and `runs-now`.
4. Frontmatter by allow-list. `permissionMode` or a `hooks` block in agent or skill frontmatter passes.
   Decision: checks 4 and 5 admit the keys the files hold today (agents: `name`, `description`, `tools`,
   `model`, `color`, `skills`; skills: `name`, `description`, `when_to_use`, `argument-hint`, `context`,
   `agent`, `background`) and fail any other key. The flag rule matches `dangerously-skip-permissions` without
   its leading dashes. Cases for each.
5. Session-start list boundary: cases with exactly 20 and with 21 uncommitted paths.
6. Evidence tool. With `--tier T`, `show --require-complete` counts a failed fresh run of every tier (unit
   case: `--tier release` beside a failed fresh fast run exits 1). `_run` returns `unavailable` for a command
   that prints text and exits 1 (unit case). A strategy line that names a test level and inspection: when the
   reader already yields the levels of a strategy line, the done gate credits the inspection line only beside a
   passing tagged test; otherwise propose the limit sentence.
7. Check 11: the seven cases of part 3 non-blocking 3, each failing its mutant.

## Input revision
The commit that adds this brief, `git log -1 --format=%h -- docs/briefs/2026-10-07-m0-review-2-fixes.md`, on
branch `m0-final-integration` (its parent is `fc068d8`). Isolated worktree per track, created by the lead from
that commit; the prompt names the full hash, and the task confirms that `git rev-parse HEAD` prints exactly it
before changing anything.

## Allowed paths
- Track A: `scripts/reqfile.py`, `scripts/check_baseline.py`, `scripts/tests/test-check-baseline.sh`,
  `docs/requirements/README.md` (rule text of § Canonical form and § Superseding), `docs/ROADMAP.md` (rule text
  of § Rules, and a line a new rule fails), `docs/requirements/AVE-REQ-093-*.md` (§ Edge cases, § Verification
  strategy, § Implementation evidence).
- Track C: `scripts/probe-environment.sh`, `scripts/tests/test-probe-environment.sh`,
  `docs/requirements/AVE-REQ-094-*.md` (the same three sections).
- Track B1: `scripts/verify.sh`, `scripts/verify.d/*.sh`, `scripts/lib/verify-state.sh`,
  `.claude/hooks/stop-verify.sh`, `scripts/tests/test-verify-tiers.sh`, `scripts/tests/test-stop-hook.sh`,
  `scripts/tests/make-fixture.sh`, `backend/src/ave/fixtures/generate.py`,
  `backend/tests/unit/test_fixture_cache_key.py`, `backend/tests/unit/test_fast_tier_media_tools.py`,
  `.gitignore` (an entry the list of item 1 needs), `docs/requirements/AVE-REQ-097-*.md` (the same three
  sections).
- Track B2: `scripts/check-project-control.sh`, `scripts/tests/test-checker.sh`, `scripts/evidence.py`,
  `scripts/tests/test_evidence.py`, `scripts/tests/test-session-start.sh`,
  `docs/requirements/AVE-REQ-098-*.md` (the same three sections); a line of a tracked file that a new rule
  fails (name it in the handback).

## Forbidden paths
The paths of the other tracks. `ai-video-editor-requirements/**`. Every document outside your allowed list:
`CLAUDE.md`, `.claude/skills/**`, `.claude/agents/**`, `.claude/settings.json`, `docs/ARCHITECTURE.md`,
`docs/ASSUMPTIONS.md`, `docs/ENVIRONMENT_CAPABILITIES.md`, `docs/TRACEABILITY.md`, `docs/PROGRESS.md`,
`docs/WORKFLOW_LOG.md`, the requirement file of AVE-REQ-096 and every requirement file of another track
(propose their text in the handback); frontmatter, criteria, Test evidence and Status log of every requirement
file.

## Dependencies and constraints
- Statement audit. After your items, go through § Edge cases, § Verification strategy and § Implementation
  evidence of your requirement file sentence by sentence (track B2 also through the sentences of the
  AVE-REQ-097 and AVE-REQ-096 files that describe the checker and the evidence tool). For each sentence that
  states what a script, a check or a suite does, reach one of four results: (a) a named suite case fails when
  the behavior is removed, shown by a one-line mutant you ran; (b) you add that case; (c) you reword the
  sentence to the behavior that holds; (d) you word it as a limit with the inspection that covers it. A
  sentence with "every", "any", "no other", "only", "never", "whenever" or "cannot" holds through an allow-list
  or names the forms it covers. Counts and names in a sentence (cases, mutants, hosts, files, variables) equal
  the tree. The handback holds the table: line, sentence (shortened), result, case or mutant.
- Every rule you add or change gets a named suite case that fails without it. Before the handback run one
  one-line mutant per rule and list mutant and failing case; delete `__pycache__` directories before a rerun of
  changed Python ([WF-004](../WORKFLOW_LOG.md)). Write the mutant list to the handback in full, so a reviewer
  can repeat it.
- Requirement files keep their canonical form (`docs/requirements/README.md` § Canonical form): the listed
  characters only, placeholders with angle brackets inside code spans, no new heading.
- Never weaken a test, a tolerance or a gate. The working tree as committed passes the tightened rules; when a
  new rule fails an existing file outside your paths, make the smallest edit that keeps the meaning and list it
  in the handback under "Forced edits".
- Host: Windows with Git Bash; `./scripts/verify.sh` enters the Linux development container by itself, every
  other check takes the prefix `./scripts/dev-container.sh` (ADR-009). The media and release tiers wait for the
  heavy-media lock; one other writer works on this host.
- Documents and messages state things affirmatively and avoid the forms "X, not Y", "rather than" and "instead
  of"; no file names a model or a local user path.
- Commit on your worktree branch when verification passes (`AVE-REQ-NNN: <imperative summary>`, ending with the
  trailer lines the prompt gives), after `git add -A` and a release run on that tree; never push, merge, rebase
  or switch branches.

## Test commands
- `./scripts/verify.sh --tier release` passes on your final tree.
- Track A: `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` and
  `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py`.
- Track C: `./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh` three times in a row with
  equal totals, and the live probe `./scripts/dev-container.sh ./scripts/probe-environment.sh`.
- Track B1: `./scripts/dev-container.sh bash scripts/tests/test-verify-tiers.sh` and `test-stop-hook.sh` the
  same way; the fingerprint of the worktree printed under Git Bash and in the container
  (`. scripts/lib/verify-state.sh && vstate_fingerprint`) is the same value.
- Track B2: `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests`,
  `./scripts/dev-container.sh bash scripts/tests/test-checker.sh --all-awks` and
  `./scripts/dev-container.sh bash scripts/tests/test-session-start.sh`.

## Handback schema
`## Result: COMPLETE | PARTIAL | BLOCKED`, then: branch and commit hash; per item of your track its disposition
(fixed, stated as a limit, or open with the reason), the files and the named cases; the mutation list (mutant,
failing case) in full; the statement-audit table; track A also the construct table of item 5; commands run with
results (suite totals, the release run); forced edits; proposed text for documents outside your paths, each as
the exact old sentence and its replacement; deviations and discovered work. The lead writes the returned report
to `docs/briefs/handbacks/2026-10-07-m0-review-2-fixes.part-<n>.md` (part 1 track A, part 2 track C, part 3
track B1, part 4 track B2).
