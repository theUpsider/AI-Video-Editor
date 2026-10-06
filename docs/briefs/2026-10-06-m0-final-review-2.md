# Brief — M0 final review, second round: verify-requirement and a skeptic for the five M0 requirements

## Requirements
Independent review of AVE-REQ-093 (AC-1 to AC-4), AVE-REQ-094 (AC-1 to AC-4), AVE-REQ-096 (AC-1 to AC-4),
AVE-REQ-097 (AC-1 to AC-4) and AVE-REQ-098 (AC-1 to AC-4) at the commit of § Input revision, one reviewer per
requirement following `.claude/skills/verify-requirement/SKILL.md` step by step, and one skeptic per PASS
(`develop` § 6). Each requirement file holds the criteria, the Edge cases, the Verification strategy and the
Implementation evidence the review judges.

The first round (run `wf_7d9d015c-906`) returned FAIL for all five. Its reports hold every finding with its
reproduction: [part 5](handbacks/2026-10-03-m0-gates-red-team.part-5.md) (AVE-REQ-093),
[part 6](handbacks/2026-10-03-m0-gates-red-team.part-6.md) (AVE-REQ-097),
[part 7](handbacks/2026-10-03-m0-gates-red-team.part-7.md) (AVE-REQ-096),
[part 8](handbacks/2026-10-03-m0-gates-red-team.part-8.md) (AVE-REQ-098) and
[part 6 of the probe brief](handbacks/2026-10-03-ave-req-094-probe-evidence.part-6.md) (AVE-REQ-094). The fixes
ran from [the fix brief](2026-10-06-m0-final-review-fixes.md); its handback parts 1 to 3 list, per finding, the
disposition, the named case and the mutant that fails it. The lead states that every blocking finding is closed
and that each non-blocking finding is fixed or stated as a limit. These are claims: a reviewer repeats each
blocking finding of its requirement by the written reproduction, samples the non-blocking ones, and then looks
for the next path from a direction no report names.

What counts as blocking: an acceptance criterion that is unmet or unevidenced, or a statement of the
requirement file (Edge cases, Verification strategy, Implementation evidence) that is false at this commit. A
limit that § Edge cases states openly, with the inspection that covers it, is a limit; an unstated one is a
finding. Everything else is reported as non-blocking with its fix.

## Input revision
The commit that adds this brief, `git log -1 --format=%h -- docs/briefs/2026-10-06-m0-final-review-2.md`, on the
integration branch `m0-final-integration`: the working branch with the three fix tracks and the AVE-REQ-094 task
branch merged in, the five requirements in status `verification`. Isolated worktree: each reviewer and each
skeptic works in a private clone of the repository at that commit and confirms that `git rev-parse HEAD` prints
the full hash its prompt names.

## Allowed paths
The private clone under `.claude/worktrees/<clone name>/` and the container's `/tmp`, for probes, mutants and
scratch runs; every file a probe changed is restored before a run that is reported as evidence
(`git status --porcelain` empty). A reviewer writes nothing that outlives its clone.

## Forbidden paths
The main checkout, every other worktree and clone, the remote (no commit, no push, no `git worktree prune`).

## Dependencies and constraints
- Host: Windows 11 with Git Bash; `./scripts/verify.sh` enters the Linux development container by itself (ADR-009),
  every other check takes the prefix `./scripts/dev-container.sh`. A private clone has its own container and
  backend environment; the heavy-media lock is shared, so a media or release tier can wait for another run.
  Two reviewers work at a time: keep CPU stress below four parallel busy processes.
- Mutated Python reruns after its `__pycache__` directories are deleted ([WF-004](../WORKFLOW_LOG.md)).
- The acceptance scenarios AT-29 and AT-30 run at the final review of the product; a reviewer reports what
  already contradicts them and holds no requirement to them now.
- At the end the reviewer stops its container (`./scripts/dev-container.sh --stop`) and removes its clone.

## Test commands
- `./scripts/verify.sh --tier release` once per clone (Definition of Done item 4), then
  `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-NNN --require-fresh --tier release`.
- The suites that carry the requirement's tags (`grep -rl "AVE-REQ-NNN" scripts/tests backend/tests`), each
  through `./scripts/dev-container.sh bash scripts/tests/<suite>` or the unit-test command of
  `docs/ARCHITECTURE.md` § Testing strategy.
- AVE-REQ-093: `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py`. AVE-REQ-094: the probe
  suite three times in a row and the live probe `./scripts/dev-container.sh ./scripts/probe-environment.sh`.

## Handback schema
Reviewer: verdict PASS or FAIL; per criterion its verdict with evidence; the verification runs; blocking and
non-blocking findings, each with location, defect, evidence and fix; test quality; on PASS the lines for
§ Test evidence (per criterion the tests with their outcome in the release run, and one
`- AC-n → inspection: <what was checked and how> — pass` line per inspected criterion). Skeptic: refuted or
upheld, the disputed criteria with evidence from a run or a file, the reasoning. The lead writes the reports to
`docs/briefs/handbacks/2026-10-06-m0-final-review-2.part-<n>.md` (one part per requirement, the skeptic's report
after the reviewer's).
