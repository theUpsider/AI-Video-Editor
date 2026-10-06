---
name: verify-requirement
description: Independently verifies one requirement in a forked reviewer context. Reads the requirement first, checks every acceptance criterion against code, tests and real check runs, hunts false-positive tests, and returns VERDICT PASS or FAIL with evidence. Required before any requirement moves to done.
argument-hint: "<REQ-ID>"
context: fork
agent: reviewer
background: false
---

# Verify $ARGUMENTS

Verify requirement $ARGUMENTS independently and return the verdict report defined under Output. Below, `AVE-REQ-NNN` stands for this ID.

PASS requires evidence you verified yourself for every applicable acceptance criterion and zero blocking findings. Never approve because the implementation "looks reasonable".

Ground rules:
- You start from clean context. Treat every claim (implementer reports, commit messages, evidence sections, test names, comments) as unverified until your own code reading and runs confirm it.
- Modify no files. Use Bash only to run checks and inspect. Never run `git add`, `commit`, `checkout`, `reset`, `stash`, `clean`, `merge` or `push`, formatters in write mode, or installs that rewrite lockfiles. Run experiments only in a temporary copy outside the repository (`mktemp -d`) and delete it afterwards. On a host that verifies in the development container (ADR-009) the copy is a clone under `.claude/worktrees/`, the only path the container mounts, made with `git clone -q --no-hardlinks -c core.autocrlf=false -c core.eol=lf . .claude/worktrees/<name>` so the checkout keeps LF bytes.
- Paths are relative to the repository root; dates come from `date -u +%F`.
- Load only what the review needs: the requirement and its parent, the governing ADRs and `docs/ARCHITECTURE.md` sections, the changed code and its tests. Report missing context as a finding; never guess product intent.

## 1. Read the requirement independently

1. Resolve the file: `ls docs/requirements/AVE-REQ-NNN-*.md`. When the argument is empty or names no requirement file, return `VERDICT: FAIL` with the blocking finding "no requirement to verify".
2. Read the whole file (frontmatter, Intent, Description, every AC, Edge cases, Dependencies, Verification strategy) and its parent FEAT/EPIC.
3. Before opening any code or test, write a working note: for each AC, the expected observable behavior, its inputs and conditions, and the evidence that would prove it; then the edge cases you will probe (those in § Edge cases plus your own). Judge everything after this against the note and the requirement text.

## 2. Inspect every acceptance criterion

For each AC, determine:
- whether it is testable as written; an ambiguous or untestable AC is a finding, blocking when it prevents verification;
- the verification level § Verification strategy requires (unit, integration, end-to-end, inspection); inspection needs a stated reason why automation is impractical;
- whether it agrees with the Description, the other ACs and Accepted ADRs.

Every AC in the file applies. An AC you judge inapplicable is a finding for the lead; never pass it silently.

## 3. Inspect the implementation

1. Locate the change: § Implementation evidence (a claim to check), `git grep -n -w --untracked "AVE-REQ-NNN"`, `git log --oneline --grep='AVE-REQ-NNN[:,]'`, `git status`, `git diff HEAD`, `git show <commit>`.
2. Read the changed code and its callers. For each AC, trace the code path that produces the behavior.
3. Check error handling and input validation at trust boundaries; data integrity (atomicity, cleanup, loss or corruption paths); concurrency where state is shared; Accepted ADRs and the module boundaries in `docs/ARCHITECTURE.md`; backward compatibility; secrets; substantial behavior outside the requirement's scope; leftover debug code; TODO or FIXME markers without a follow-up ID.

## 4. Inspect the tests

1. Map tests to ACs through their tags (substitute the ID):

```sh
git grep -n -w --untracked "AVE-REQ-NNN AC-1" -- ':!*.md'
```

The grep also matches expected-output strings and fixture text of the tooling suites: read each hit before
you count it as a test. `python3 -B scripts/evidence.py show AVE-REQ-NNN` after the verification run of the
next section lists each AC with the tests that carry its tag as a test marker or a comment line (`missing`:
no tagged test; `not-run`: its tests did not run in that tier).

2. Read each test completely, including its fixtures and helpers, and apply the checklist in section 8.
3. An AC without a tagged test needs a justified inspection in § Verification strategy; perform that inspection yourself and record what you checked.

## 5. Run the tests

1. Run the targeted tests for each AC (commands in `docs/ARCHITECTURE.md` § Testing strategy or the test runner configuration). Confirm in the runner output that each AC's tests executed and passed: none skipped, filtered out or marked expected-to-fail.
2. Run `./scripts/verify.sh --tier release` (the tier that runs every tagged test; a lighter tier leaves
   tagged tests out and certifies nothing complete), then
   `python3 scripts/evidence.py show AVE-REQ-NNN --require-fresh`: every AC's tagged tests and their outcomes
   in that run, tied to the current tree. One heavy media job runs at a time: the media and release tiers
   wait for the heavy-media lock by themselves, and every other heavy media command (a targeted
   `-m "media or slow"` run, a reproduction that renders or decodes media) runs as
   `flock <lock file> <command>` (`docs/ARCHITECTURE.md` § Testing strategy).
3. Record every command with its result. A check that cannot run (missing dependency, broken environment) leaves you without evidence: report a blocking finding.

## 6. Run integration and end-to-end checks

1. When integration, end-to-end or smoke tests exist for the affected components or for the user journey the Intent names, run them and record the result.
2. When an AC is observable through a runnable entry point (CLI, server, script), exercise it with scratch inputs in a temporary directory outside the repository.
3. When § Verification strategy requires a test level the project lacks, report it; it is blocking when an AC depends on it.

## 7. Test realistic edge cases

Probe the edge cases from your working note: empty, minimum, maximum, limit and limit plus one, invalid format, large input, duplicates, repeated or idempotent operations, interruption and retry, concurrency, permission and I/O failure, encoding and locale, slow or failing dependencies, as relevant. For each, find the test or code path that handles it, or demonstrate the behavior with a scratch run. A mishandled case that an AC covers, or that § Edge cases maps to an AC, is blocking. A case beyond the ACs is non-blocking with a proposed follow-up requirement.

## 8. Check for false-positive tests

Every test claimed for an AC must pass all of these:
- [ ] **Assertion strength:** asserts the AC's observable outcome with specific expected values. "Not null", "did not throw", truthiness or length alone fail where content matters.
- [ ] **Fails without the behavior:** removing, inverting or shifting the behavior by one would make it fail. When reasoning is inconclusive for a critical AC, break the behavior in a temporary copy of the working tree outside the repository, run the test there, and delete the copy. Delete every `__pycache__` directory before each run of mutated Python: a same-size edit within one second keeps a stale `.pyc` valid (WF-004).
- [ ] **Real unit under test:** mocks and stubs replace only external boundaries; assertions target real outputs and state; a test that asserts only on mock call records fails this item.
- [ ] **No tautology:** the expected value is independent of the code under test; it is neither copied from that code's output nor computed by the same code path, and no value is compared with itself.
- [ ] **Executed:** neither skipped, focused (`only`, `fit`, `fdescribe`), filtered, marked expected-to-fail nor conditionally skipped; the runner collects it.
- [ ] **Snapshots and golden files:** their content was checked against the AC; a snapshot created or updated in this change without that check fails.
- [ ] **Tagged:** carries `AVE-REQ-NNN AC-n`; an untagged test gives the AC no traceable evidence.
- [ ] **Sound control flow and determinism:** no swallowed errors, early returns or conditional assertions; no dependence on timing, execution order or shared state.
- [ ] **Own constructions (media and file-format criteria):** rebuild each claimed fix with inputs of your own (other containers, codecs, seek points, populations) in the scratch copy and measure the numbers there; the implementer's fixtures prove only the constructions the implementer had in mind (WF-001).

An AC whose only tests fail this checklist is unevidenced, which is blocking.

## 9. Check documentation consistency

- § Implementation evidence names files and tests that exist and match the change; no `_TBD` remains there.
- Frontmatter `status` is `verification` and matches the newest Status-log line; the ACs are still unticked. Exception: `milestone-review` re-verifies `done` requirements, where status `done`, ticked ACs and filled Test evidence are expected.
- `parent` exists and lists this requirement; every requirement under Dependencies is `done`.
- The `docs/TRACEABILITY.md` row exists with matching status; cited ADRs exist and are Accepted, or Proposed with an open escalation while only a fake implements their interface.

Inconsistencies are non-blocking findings with the exact fix, unless they hide a missing AC, test or check.

## 10. Classify findings and decide

Blocking (any one forces FAIL):
- an AC unmet, partially met, or without evidence you verified;
- an AC covered only by false-positive tests, or with neither a tagged test nor a justified inspection;
- `./scripts/verify.sh` or a relevant test fails, or tests of other requirements regress;
- a security or data-integrity defect (exposed secret, unvalidated input at a trust boundary, data loss or corruption path);
- a violation of an Accepted ADR or a documented module boundary;
- a check weakened, skipped or suppressed to get green;
- substantial behavior outside the requirement's scope.

Non-blocking: maintainability and readability issues, minor duplication, edge cases beyond the ACs (propose follow-up requirements), documentation and traceability fixes. Never block on style preference.

Write each finding as `path:line` — defect — evidence (command and output, input, or reasoning) — concrete fix or follow-up.

Verdict: PASS only when every AC row is PASS with evidence you verified and § Blocking is empty; otherwise FAIL. An AC you could not verify is FAIL.

## Output

Your final message is the report alone, in exactly this format; nothing precedes the first line.

```text
VERDICT: PASS | FAIL
Requirement: AVE-REQ-NNN — <title>
## Acceptance criteria
| AC | Verdict | Evidence |
## Verification runs
## Findings
### Blocking
### Non-blocking
## Test quality
## Evidence for the requirement file
```

- First line: `VERDICT: PASS` or `VERDICT: FAIL`.
- Acceptance criteria: one row per AC; Verdict `PASS` or `FAIL`; Evidence names the test (`path::name`) and the run that executed it, or the inspection you performed.
- Verification runs: each command with its result; for failures, the decisive output lines.
- Findings: "None." under an empty heading.
- Test quality: per AC, the checklist outcome from section 8 and any coverage gaps.
- Evidence for the requirement file: on PASS, ready-to-paste `## Test evidence` lines in the format of `docs/requirements/README.md`; on FAIL, "None — verdict FAIL."

```text
- verify-requirement: PASS — YYYY-MM-DD — no blocking findings
- ./scripts/verify.sh: PASS — YYYY-MM-DD
- AC-1 → `<test location>` — pass
- AC-3 → inspection: <what was checked and how> — pass
- Non-blocking findings: <summary, or "None.">
```
