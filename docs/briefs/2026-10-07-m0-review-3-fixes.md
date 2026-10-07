# Brief — M0 review round three, fixes: acceptance boxes and roadmap by grammar, probe, evidence tool, checker

## Requirements
The third round of the final M0 review (run `wf_268ea4f6-bad` at `d7d5604`) returned FAIL for AVE-REQ-093,
AVE-REQ-094, AVE-REQ-096, AVE-REQ-097 and AVE-REQ-098 with nine blocking findings. The statement-audit tables
of the second fix round held where the reviewers ran their mutants again; each new finding lies in a place that
still matches text by a single pattern. Each report holds, per finding, the location, the defect, the
reproduction and a proposed fix; read your track's findings there in full before coding:
[part 1](handbacks/2026-10-07-m0-final-review-3.part-1.md) (AVE-REQ-093),
[part 2](handbacks/2026-10-07-m0-final-review-3.part-2.md) (AVE-REQ-094),
[part 3](handbacks/2026-10-07-m0-final-review-3.part-3.md) (AVE-REQ-096),
[part 4](handbacks/2026-10-07-m0-final-review-3.part-4.md) (AVE-REQ-097),
[part 5](handbacks/2026-10-07-m0-final-review-3.part-5.md) (AVE-REQ-098). Four tracks, one writer each; a
prompt names its track. The lead closes AVE-REQ-096 and the lead-owned documents. Hardening that a finding
proposes beyond the criteria and that no item below takes up belongs to
[AVE-REQ-105](../requirements/AVE-REQ-105-canonical-forms-for-the-remaining-control-documents.md); name it in
the handback and leave it.

**Track A — baseline gate (AVE-REQ-093 AC-3, AC-4).** Part 1, blocking 1 to 3, non-blocking 2 to 5:
1. Acceptance boxes by grammar. A ticked box of § Feature acceptance or § Success criteria inside a quote or
   nested on one line passes while the file is unfinished. Decision: the two sections follow a line grammar, as
   § Acceptance criteria does: each line is a list item at column 0 that opens `- [ ] ` or `- [x] ` and holds
   text, or one further form that the working files hold today and that you name; every other line fails, so a
   box in a container has no form. Cases: the nine forms of the finding, one per section and file kind, and the
   forms the files hold today as passing cases.
2. Roadmap entries by grammar. A second line, heading or list label passes when its letters stand in text the
   gate takes for a link target. Decision: a milestone entry holds only lines of the template's forms (its
   heading, a list item at column 0 that opens `- **<Label>:** ` with a label of the template, an indented
   sub-item below `Exit criteria`, a blank line); every other line of an entry fails, and every level-3 heading
   of the file is an entry heading. A link target leaves the letters only where a link of the one form stands
   outside code spans and no backslash precedes its `[`. Keep the rules of the second round where the grammar
   leaves them a case. Cases: the four forms of the finding and each template line as a passing case.
3. Character references. Python's `html.unescape` reads 94 numeric references as nothing and three through
   Windows-1252. Decision: by allow-list. When neither the roadmap nor a working file holds a character
   reference today, `&` before `#` or before a name and `;` fails outside code spans and fenced blocks in both
   (this also closes non-blocking 3); otherwise judge a numeric reference by its code point and name the
   references the files hold. Cases: the four of the finding and a reason made of one reference.
4. Non-blocking 2: the package directory as a symbolic link fails, with a case. Non-blocking 4: a parent lists
   a child through a link whose text opens with the child's ID, with a case. Non-blocking 5: the box forms join
   your construct comparison, and the result joins the handback.

**Track C — capability probe (AVE-REQ-094 AC-1).** Part 2, blocking 1, non-blocking 1, 2, 3 and 5:
1. Credential values under tracing. The set-or-unset test expands the value, so shell tracing writes it to the
   error stream. Decision: the test expands no value (`${!name:+x}`), and the probe switches tracing off with its
   other shell settings. Search the probe for every other expansion of a credential variable. Cases: a provider
   variable set, `SHELLOPTS=xtrace` exported and `bash -x`, both streams captured, the value absent; the case
   fails on the probe of the base commit.
2. Root and Git variables: the script path is resolved before the root is taken, and the Git lines ignore
   `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE` and `GIT_COMMON_DIR` of the caller; one case each.
3. Arguments: more than one argument exits 2 with the usage line; a case.
4. The four cases of non-blocking 3 (`dri/card1234`, the recorded time limit of 10, two nodes without access,
   a memory figure in another unit).
5. Wording of non-blocking 5 in § Edge cases.

**Track B2a — evidence tool and session-start hook (AVE-REQ-097 AC-4; AVE-REQ-098 AC-2).** Part 4, blocking 1;
part 5, blocking 1 and non-blocking 2 and 6 (a):
1. Failed runs of this tree. `show` reads the newest run of each tier, so a run of the same tier on another
   tree hides a failed run of this tree. Decision: for the heaviest fresh run and for the failed-run rule `show`
   reads the manifests of the kept run directories and takes, per tier, the newest that is fresh for the current
   tree; § Edge cases states the bound that remains (the number of kept runs). Unit cases: the sequence of the
   finding exits 1 and names the tier; a failed run pruned beyond the kept runs is the stated limit.
2. Injected progress file. The suite asserts one heading of the injected `docs/PROGRESS.md`. Decision: for each
   source the lines between the delimiters equal the fixture's file byte for byte, the fixture holds body lines
   under several headings, and the cap case asserts the exact number of lines with the last kept line present
   and the first cut line absent. The commit list is identified by the subjects of its first and last entry.
   The three mutants of the first round's finding and one that keeps headings only fail.
3. Character budget. Claude Code caps hook output (the Stop hook is sized for the cap; read
   `.claude/hooks/stop-verify.sh` and the hooks reference for the figure). Decision: the block of the
   SessionStart hook stays below that cap: the progress part ends at a character budget with the hook's own
   truncation note, with a case at the boundary.

**Track B2b — project checker (AVE-REQ-098 AC-3, AC-4; AVE-REQ-096 AC-1; AVE-REQ-097 AC-3).** Part 5, blocking 2
and non-blocking 1, 3, 4, 5 and 6 (b, c); part 3, non-blocking 2 and 3; part 4, non-blocking 2:
1. Wrapped claims and list markers. A wording split over two list items passes for `*`, `+` and numbered
   markers. Decision: the join removes one list marker (`-`, `*`, `+`, or digits with `.` or `)`, then a space)
   from the start of each line; cases for the three markers.
2. Matcher lists. Check the current hooks reference of Claude Code for how a matcher is read (the finding says a
   matcher of letters, digits, `_`, `-`, spaces, `,` and `|` is a list of exact names split on `|` or `,`),
   cite what you read, and classify a matcher the same way; cases for a comma list that covers the four
   sources, one that leaves a source out, a matcher that is no string and one that is no valid expression.
3. Handlers by allow-list for every event. `asyncRewake` under another event passes. Decision: under every
   event a group holds `hooks` and optionally `matcher`, and a handler `type`, `command` and optionally
   `timeout`; any other key fails. Cases: `asyncRewake` and `async` on a PreToolUse handler.
4. Folder files: `.DS_Store` and `Thumbs.db` are passed over as regular files only; a directory of that name
   in `docs/briefs/` and in `handbacks/` fails; one case each.
5. Cases without a rule change: the five of part 3 non-blocking 3, and a heading with one leading space for the
   heading rule of `docs/PROGRESS.md`.
6. The checker's Python calls start isolated (`python3 -I`), with a case that plants a module beside the tree's
   root.
7. Wording of part 5 non-blocking 5 (the counter counts by its first line) in the requirement file.

## Input revision
The commit that adds this brief, `git log -1 --format=%h -- docs/briefs/2026-10-07-m0-review-3-fixes.md`, on
branch `m0-final-integration` (its parent is `d5e062c`). Isolated worktree per track, created by the lead from
that commit; the prompt names the full hash, and the task confirms that `git rev-parse HEAD` prints exactly it
before changing anything.

## Allowed paths
- Track A: `scripts/reqfile.py`, `scripts/check_baseline.py`, `scripts/tests/test-check-baseline.sh`,
  `docs/requirements/README.md` (rule text of § Canonical form and § Enforced checks), `docs/ROADMAP.md` (rule
  text of § Rules, and a line a new rule fails), `docs/requirements/AVE-REQ-093-*.md` (§ Edge cases,
  § Verification strategy, § Implementation evidence).
- Track C: `scripts/probe-environment.sh`, `scripts/tests/test-probe-environment.sh`,
  `docs/requirements/AVE-REQ-094-*.md` (the same three sections).
- Track B2a: `scripts/evidence.py`, `scripts/tests/test_evidence.py`, `.claude/hooks/session-start.sh`,
  `scripts/tests/test-session-start.sh`, `docs/requirements/AVE-REQ-097-*.md` (the same three sections).
- Track B2b: `scripts/check-project-control.sh`, `scripts/tests/test-checker.sh`,
  `docs/requirements/AVE-REQ-098-*.md` (the same three sections); a line of a tracked file that a new rule fails
  (name it in the handback).

## Forbidden paths
The paths of the other tracks. `ai-video-editor-requirements/**`. Every document outside your allowed list:
`CLAUDE.md`, `.claude/skills/**`, `.claude/agents/**`, `.claude/settings.json`, `docs/ARCHITECTURE.md`,
`docs/ASSUMPTIONS.md`, `docs/ENVIRONMENT_CAPABILITIES.md`, `docs/TRACEABILITY.md`, `docs/PROGRESS.md`,
`docs/WORKFLOW_LOG.md`, the requirement files of AVE-REQ-096 and AVE-REQ-105 and every requirement file of
another track (propose their text in the handback); frontmatter, criteria, Test evidence and Status log of every
requirement file.

## Dependencies and constraints
- By grammar and by allow-list: where an item says so, the rule names the forms it admits and fails every other
  form. A rule that still matches a deny-list after your change is named in the handback with the reason.
- Statement audit of what you touch: every sentence you add or change in the three sections, and every
  sentence a finding of your track names, is pinned by a named suite case whose one-line mutant you ran, or is
  reworded to the behavior that holds, or is worded as a limit with the reader who judges it. A sentence with
  "every", "any", "no other", "only", "never", "whenever" or "cannot" holds through a grammar or an allow-list
  or names the forms it covers. The handback holds the table and the mutation list in full.
- Requirement files keep their canonical form (`docs/requirements/README.md` § Canonical form).
- Never weaken a test, a tolerance or a gate. The working tree as committed passes the tightened rules; when a
  new rule fails an existing file outside your paths, make the smallest edit that keeps the meaning and list it
  in the handback under "Forced edits".
- Host: Windows with Git Bash; `./scripts/verify.sh` enters the Linux development container by itself, every
  other check takes the prefix `./scripts/dev-container.sh` (ADR-009). The worktrees share one container: stop
  a process only by its process ID or by a working directory of your own, and when your worktree already holds
  edits (the run started the task again) read `git status` and `git diff` first
  ([WF-012](../WORKFLOW_LOG.md)). The media and release tiers wait for the heavy-media lock; one other writer
  works on this host. A file outside the fingerprint and outside `var/` fails every tier: scratch files live
  below `var/` or in the container's `/tmp`.
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
- Track B2a: `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests` and
  `./scripts/dev-container.sh bash scripts/tests/test-session-start.sh`.
- Track B2b: `./scripts/dev-container.sh bash scripts/tests/test-checker.sh --all-awks`.

## Handback schema
`## Result: COMPLETE | PARTIAL | BLOCKED`, then: branch and commit hash; per item of your track its disposition
(fixed, stated as a limit, or open with the reason), the files and the named cases; the mutation list (mutant,
failing case) in full; the statement-audit table of what you touched; commands run with results (suite totals,
the release run); forced edits; proposed text for documents outside your paths, each as the exact old sentence
and its replacement; hardening left for AVE-REQ-105; deviations and discovered work. The lead writes the
returned report to `docs/briefs/handbacks/2026-10-07-m0-review-3-fixes.part-<n>.md` (part 1 track A, part 2
track C, part 3 track B2a, part 4 track B2b).
