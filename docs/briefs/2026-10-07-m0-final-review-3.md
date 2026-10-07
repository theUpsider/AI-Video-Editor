# Brief — M0 final review, third round: verify-requirement and a skeptic for the five M0 requirements

## Requirements
Independent review of AVE-REQ-093 (AC-1 to AC-4), AVE-REQ-094 (AC-1 to AC-4), AVE-REQ-096 (AC-1 to AC-4),
AVE-REQ-097 (AC-1 to AC-4) and AVE-REQ-098 (AC-1 to AC-4) at the commit of § Input revision, one reviewer per
requirement following `.claude/skills/verify-requirement/SKILL.md` step by step, and one skeptic per PASS
(`develop` § 6). Each requirement file holds the criteria, the Edge cases, the Verification strategy and the
Implementation evidence the review judges.

The second round (run `wf_b18a5f3e-54e` at `f996c17`) returned FAIL for AVE-REQ-093, AVE-REQ-094 and AVE-REQ-097
and a PASS that the skeptic refuted for AVE-REQ-096 and AVE-REQ-098. Its reports hold every finding with its
reproduction: [part 1](handbacks/2026-10-06-m0-final-review-2b.part-1.md) (AVE-REQ-093),
[part 2](handbacks/2026-10-06-m0-final-review-2b.part-2.md) (AVE-REQ-094),
[part 3](handbacks/2026-10-06-m0-final-review-2b.part-3.md) (AVE-REQ-096),
[part 4](handbacks/2026-10-06-m0-final-review-2b.part-4.md) (AVE-REQ-097) and
[part 5](handbacks/2026-10-06-m0-final-review-2b.part-5.md) (AVE-REQ-098). The fixes ran from
[the fix brief](2026-10-07-m0-review-2-fixes.md); its handbacks hold, per item, the disposition, the named
cases, the mutation list in full and a statement-audit table of the requirement file:
[part 1](handbacks/2026-10-07-m0-review-2-fixes.part-1.md) (track A, AVE-REQ-093, with a table of 188 constructs
compared with two Markdown renderers), [part 2](handbacks/2026-10-07-m0-review-2-fixes.part-2.md) (track C,
AVE-REQ-094), [part 3](handbacks/2026-10-07-m0-review-2-fixes.part-3.md) (track B1, AVE-REQ-097 and the hook
part of AVE-REQ-098) and [part 4](handbacks/2026-10-07-m0-review-2-fixes.part-4.md) (track B2, AVE-REQ-098 and
the checker and evidence-tool parts of AVE-REQ-097 and AVE-REQ-096). The lead closed the refuted criterion of
AVE-REQ-096 and its other items in the documents (Status log of the requirement, [WF-011](../WORKFLOW_LOG.md)).

The lead states that every blocking finding and both refutations are closed, that each non-blocking finding is
fixed or stated as a limit, and that each sentence of the three sections is pinned by a case, reworded to what
holds, or worded as a limit ([WF-010](../WORKFLOW_LOG.md)). These are claims. A reviewer
1. repeats each blocking finding of its requirement, or the refutation, by the written reproduction;
2. samples the statement-audit table of its requirement: at least ten rows of its own choice, the mutant of each
   run again, and at least five sentences of the three sections checked against the tree from scratch;
3. samples the non-blocking findings and their dispositions;
4. then looks for the next path from a direction no report names.

What counts as blocking: an acceptance criterion that is unmet or unevidenced, or a statement of the
requirement file (Edge cases, Verification strategy, Implementation evidence) that is false at this commit. A
limit that § Edge cases states openly, with the inspection or the reader that covers it, is a limit
([ASM-041](../ASSUMPTIONS.md) lists the hardening the lead left for a later need); an unstated one is a
finding. Everything else is reported as non-blocking with its fix. The five requirements move to `done`
together in the order AVE-REQ-093, AVE-REQ-094, then AVE-REQ-096, AVE-REQ-097 and AVE-REQ-098, so a dependency
among the five in status `verification` is the planned state of this run.

## Input revision
The commit that adds this brief, `git log -1 --format=%h -- docs/briefs/2026-10-07-m0-final-review-3.md`, on the
integration branch `m0-final-integration`; its parent is the merge of the four fix tracks, where CI passed the
release tier. Isolated worktree: each reviewer and each skeptic works in a private clone of the repository at
the commit that adds this brief and confirms that `git rev-parse HEAD` prints the full hash its prompt names.

## Allowed paths
The private clone under `.claude/worktrees/<clone name>/` and the container's `/tmp`, for probes, mutants and
scratch runs. Since this commit the step "No file outside the fingerprint and the listed paths" fails a run when
the clone holds a file outside `var/` that Git ignores or that lies outside the fingerprint, so scratch files of
a clone live below `var/` or in the container's `/tmp`; every file a probe changed is restored before a run that
is reported as evidence (`git status --porcelain` empty). A reviewer writes nothing that outlives its clone.

## Forbidden paths
The main checkout, every other worktree and clone, the remote (no commit, no push, no `git worktree prune`).

## Dependencies and constraints
- Host: Windows 11 with Git Bash; `./scripts/verify.sh` enters the Linux development container by itself
  (ADR-009), every other check takes the prefix `./scripts/dev-container.sh`. A private clone has its own
  container and backend environment; the heavy-media lock is shared, so a media or release tier can wait for
  another run. The fixture cache key changed with this tree, so the first media run of a clone generates its
  fixtures.
- At most two clones exist at a time (`develop` § 4 Concurrency limits): the run works in two lanes, and a
  skeptic starts after its reviewer removed its clone. Keep CPU stress below four parallel busy processes, and
  stop a process only by its process ID or by a working directory of your own.
- At its end each reviewer and each skeptic removes its backend environment
  (`./scripts/dev-container.sh bash -c 'rm -rf "$UV_PROJECT_ENVIRONMENT"'`), then its container
  (`./scripts/dev-container.sh --stop`), then its clone.
- Mutated Python reruns after its `__pycache__` directories are deleted ([WF-004](../WORKFLOW_LOG.md)).
- The acceptance scenarios AT-29 and AT-30 run at the final review of the product; a reviewer reports what
  already contradicts them and holds no requirement to them now.

## Test commands
- `./scripts/verify.sh --tier release` once per clone (Definition of Done item 4), then
  `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-NNN --require-fresh --tier release`.
- The suites that carry the requirement's tags (`grep -rl "AVE-REQ-NNN" scripts/tests backend/tests`), each
  through `./scripts/dev-container.sh bash scripts/tests/<suite>` or the unit-test command of
  `docs/ARCHITECTURE.md` § Testing strategy.
- AVE-REQ-093: `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py`. AVE-REQ-094: the probe
  suite three times in a row and the live probe `./scripts/dev-container.sh ./scripts/probe-environment.sh`.

## Handback schema
Reviewer: verdict PASS or FAIL; per criterion its verdict with evidence; the verification runs; the rows of the
statement-audit table it sampled, each with its result; blocking and non-blocking findings, each with
location, defect, evidence and fix; test quality; on PASS the lines for § Test evidence (per criterion the tests
with their outcome in the release run, and one `- AC-n → inspection: <what was checked and how> — pass` line per
criterion whose strategy names inspection). Skeptic: refuted or upheld, the disputed criteria with evidence from
a run or a file, the reasoning. The lead writes the reports to
`docs/briefs/handbacks/2026-10-07-m0-final-review-3.part-<n>.md` (part 1 AVE-REQ-093, part 2 AVE-REQ-094, part 3
AVE-REQ-096, part 4 AVE-REQ-097, part 5 AVE-REQ-098; the skeptic's report after the reviewer's).
