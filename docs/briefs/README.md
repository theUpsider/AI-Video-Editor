# Task briefs

A task brief is the contract the lead hands to one delegated task: an implementer, tester, researcher or
architect, or a workflow run (review workflows included). Briefs live here so that an interrupted task can be
resumed or re-run from the repository alone, and so that reviews can compare a handback with what was asked
([AVE-REQ-096](../requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)). The skills that
fork their own agent, `verify-requirement` and `architecture-review`, take no brief: the skill is the task, and
the requirement and the repository are its inputs. The one-time setup skills, `product-definition` and
`technical-foundation`, give their agents the task text the skill defines.

File: `docs/briefs/YYYY-MM-DD-<slug>.md`, written from the template and committed before the task starts
(inside an uncommitted merge it joins the merge commit; `CLAUDE.md` § Delegation, `develop` § 4), passed by
path in the task's prompt, and never edited afterwards; a changed task gets a new brief. A brief written ahead
of its launch is a draft (§ Drafts). [WORKFLOW_LOG.md](../WORKFLOW_LOG.md) records how the run went.

## Template

Keep the headings verbatim and in order. `scripts/check-project-control.sh` (check 11) fails on a brief in
this directory that lacks a heading, repeats one or breaks the order, leaves a section empty, names no
`AVE-REQ-NNN` ID under Requirements, or names no commit under Input revision. A commit is a hash of 7 to 40
lowercase hex digits with no letter, digit, `_` or `-` on either side (a branch name such as
`ccr-af7078da-q8r8mf` names none), or the self-reference to the commit that adds the brief,
`git log -1 --format=%h -- docs/briefs/<this file's name>`. HTML comments are removed before a section is
judged. This directory holds briefs, `README.md`, `drafts/` and `handbacks/` only; check 11 fails on any other
entry.

```markdown
# Brief — <task title>

## Requirements
<AVE-REQ IDs and the ACs or edge cases in scope; findings being fixed, quoted with their evidence.>

## Input revision
<Commit the task starts from: the current commit hash (`git rev-parse --short HEAD`) plus the commit that adds this brief (`git log -1 --format=%h -- docs/briefs/<this file's name>`); then "isolated worktree" or "main working tree" (naming any uncommitted changes the task builds on).>

## Allowed paths
<Paths the task may change.>

## Forbidden paths
<Paths owned by concurrent tasks or the lead.>

## Dependencies and constraints
<ADRs, interfaces, decisions already made, limits (CPU, time, concurrency; heavy media commands under the heavy-media lock).>

## Test commands
<Exact commands that must pass before the handback.>

## Handback schema
<Fields the final report contains, and its handback file when the task writes it.>
```

## Handbacks

The final report of each delegated task persists as `handbacks/<brief-slug>.md`, or
`handbacks/<brief-slug>.part-<n>.md` for a task run in parts. The task writes the file when its brief's
handback schema names it; otherwise the lead writes the returned report there before acting on it. The file is
committed with the work it reports and stays unchanged afterwards. Check 11 fails on a file in
`docs/briefs/handbacks/` whose name matches no brief in this directory; a hidden file or a directory there
fails too.

## Drafts

A brief written before the commit it starts from exists is a draft in `drafts/`: it names no input revision
yet, and check 11 leaves it alone. At launch the lead fills its input revision with the commit the task starts
from (a hash, or the self-reference to the commit that adds the moved brief) and moves it to this directory
(`git mv docs/briefs/drafts/<file> docs/briefs/<file>`) in the commit that precedes the launch; check 11
covers it from then on.
