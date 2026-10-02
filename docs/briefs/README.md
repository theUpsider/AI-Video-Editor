# Task briefs

A task brief is the contract the lead hands to one delegated task (implementer, tester, researcher or a workflow
agent). Briefs live here so that an interrupted task can be resumed or re-run from the repository alone, and so
that reviews can compare a handback with what was asked
([AVE-REQ-096](../requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)).

File: `docs/briefs/YYYY-MM-DD-<slug>.md`, written before the task starts and never edited afterwards; a changed
task gets a new brief. [WORKFLOW_LOG.md](../WORKFLOW_LOG.md) records how the run went.

## Template

Keep the headings verbatim and in order.

```markdown
# Brief — <task title>

## Requirements
<AVE-REQ IDs and the ACs or edge cases in scope; findings being fixed, quoted with their evidence.>

## Input revision
<Commit the task starts from, and whether it runs in an isolated worktree.>

## Allowed paths
<Paths the task may change.>

## Forbidden paths
<Paths owned by concurrent tasks or the lead.>

## Dependencies and constraints
<ADRs, interfaces, decisions already made, limits (CPU, time, concurrency).>

## Test commands
<Exact commands that must pass before the handback.>

## Handback schema
<Fields the final report contains.>
```
