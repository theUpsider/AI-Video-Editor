# Brief — Fix the M0 process-requirement verification findings

## Requirements
AVE-REQ-093, AVE-REQ-094, AVE-REQ-096, AVE-REQ-097, AVE-REQ-098. Independent `verify-requirement` reviews at
`4d9ef9a` (one reviewer per requirement in a private clone; workflow `wf_b0c34bba-a20`, script in
[docs/workflows/](../workflows/README.md)): all five FAIL. Per criterion: 093 AC-1 FAIL, AC-2 PASS, AC-3 FAIL,
AC-4 PASS; 094 AC-1 FAIL, AC-2–AC-4 PASS; 096 AC-1 FAIL, AC-2 PASS, AC-3 PASS, AC-4 FAIL; 097 AC-1 PASS, AC-2 FAIL,
AC-3 PASS, AC-4 FAIL; 098 AC-1 PASS, AC-2 PASS, AC-3 FAIL, AC-4 PASS. Every reviewer confirmed its mutations of
the existing suites were caught; the defects below are coverage and procedure gaps.

Blocking:
1. AVE-REQ-093 AC-1, AC-3 — `scripts/check_baseline.py:174-194`, `ai-video-editor-requirements/tools/validate_package.py:256-257`:
   immutability rests on the package's own MANIFEST.json, which nothing outside the package pins. Probe: MANIFEST.json
   version set to 1.1 with an added excludes entry → `check_baseline.py` exit 0 "OK: baseline intact"; AVE-REQ-001
   AC-2 weakened in the baseline .md, requirements.json and the working file with MANIFEST.json re-hashed → exit 0.
   Required: a trust anchor outside the package (the SHA-256 of `ai-video-editor-requirements/MANIFEST.json`,
   `140307b86ab7b9e070088adc469888fe8a7fbfdb5a0c4dffa2c6a04846696e05`, or the package's Git tree
   `477830924b60774cab80859b26b9d113e3db6439` plus a clean status for the path); a mismatch fails with "baseline
   changed". Suite cases "edited MANIFEST.json fails" and "baseline edit with a re-hashed manifest fails".
2. AVE-REQ-093 AC-3 — `scripts/check_baseline.py:255-310`: a baseline requirement's `## Description` can be
   rewritten with no logged reason (probe: AVE-REQ-093's Description replaced → exit 0). README § Baseline import
   and ADR-003 decision 3 keep the statement verbatim. Required: compare the Description with the baseline
   statement; a mismatch needs a Status-log line `Description changed: <reason>` (reported as a recorded change),
   otherwise an error; suite cases for both; Description added to the enforced identity list in the requirements
   README and the requirement's Edge cases.
3. AVE-REQ-094 AC-1 — `docs/ENVIRONMENT_CAPABILITIES.md` § Claude Code capabilities and the requirement's
   Verification strategy: permissions and available models have no evidence. Required: a Permissions row measured
   in a session (permission mode, project allow/deny rules and whether a denied rule is enforced, launcher-level
   settings, OS user and repository writability, sandbox or network restriction); a Models row (how the session's
   model and the default model of subagent and workflow runs are observed, and which model overrides the Agent and
   Workflow tools accept, checked by a run); shell-observable parts (OS user, writability, `claude --version`) added
   to `scripts/probe-environment.sh` with assertions; the AC-1 strategy names permissions and models.
4. AVE-REQ-096 AC-1 — `.claude/skills/develop/SKILL.md:96-104,132`, `CLAUDE.md` § Delegation: the canonical
   procedure briefs subagents with "requirement ID, file paths and constraints only" and never requires a
   persisted brief; two delegated workflows after the rule landed (`wf_1a23bf0d-2a0`, `wf_b0c34bba-a20`) had no
   brief in `docs/briefs/`. `docs/ENVIRONMENT_CAPABILITIES.md:102-103` claims every delegated task runs in a
   worktree, which develop §4/§5 contradict. Required: develop §4/§5, the tester and researcher delegation lines and
   CLAUDE.md § Delegation require writing `docs/briefs/YYYY-MM-DD-<slug>.md` from the template before spawning
   (input revision as a commit, plus "main working tree" when no worktree is used) and passing its path in the
   prompt; state whether reviewer and workflow review tasks need one; correct ENVIRONMENT_CAPABILITIES.
5. AVE-REQ-096 AC-4 — `docs/WORKFLOW_LOG.md:81` (WF-003), `docs/ENVIRONMENT_CAPABILITIES.md:99-100`,
   `docs/WORKFLOW_LOG.md:29`: the documented limit (two writing agents plus one heavy media job) was exceeded and
   logged as a positive result (WF-003: a re-review running media tests overlapped a media-tier run; on
   2026-10-02 at 09:00 four agents ran media-heavy work at once across `wf_1a23bf0d-2a0` and `wf_b0c34bba-a20`).
   No entry measures headroom (baseline `spec/AGENT_WORKFLOW.md:41` requires that before any increase) and nothing
   enforces the limit. Required, one of: (a) measure two concurrent heavy media jobs (CPU time, wall time, test
   stability) in a new WF entry and raise the limit with that evidence; (b) enforce it, for example a `flock` on a
   shared lock file around the media and release tiers and heavy review commands, heavy review lenses run in
   sequence, no second media-heavy workflow while one runs. Either way the develop and delivery skills say how the
   lead counts heavy jobs across concurrent workflows, and WF-003's measured result is corrected.
6. AVE-REQ-097 AC-4 — `scripts/evidence.py:56-59,183-225` (`SUITE_STEPS`, `suite_tags`, `collect`),
   `scripts/verify.d/15-evidence-tooling.sh:5`, `scripts/tests/run.sh:38-43`: tooling evidence is credited from a
   `# AVE-REQ-NNN AC-n` comment anywhere in a `scripts/tests` file plus the outcome of the step meant to run it.
   Probes: an `@unittest.skip` test tagged AVE-REQ-012 AC-2 printed "OK (skipped=1)" and showed AC-2 "passed"; a
   `scripts/tests/test-placeholder.sh` with body `exit 1`, absent from run.sh, collected as "passed"; `done_problems()`
   accepted AVE-REQ-012 as done on those placeholders. Required: credit tooling tags only from suites that ran
   (run.sh or each suite writes per-suite results with file, exit status and tags into `$AVE_EVIDENCE_DIR`;
   `collect()` reads those); the unittest step fails on skips and expected failures (a small runner or result
   hook, matching `--forbid-skips`); `test_evidence.py` cases tagged AVE-REQ-097 AC-4 for a skipped unittest, a
   suite run.sh never runs, and the failing unittest step.
7. AVE-REQ-097 AC-2 — `scripts/evidence.py:183-195,219-224,365-366`: tooling tags are never checked with
   `tag_problems()`; a file tagged `AVE-REQ-097 AC-9` and `AVE-REQ-999 AC-1` was recorded as passed evidence, and
   `evidence.py show --tier release` then raised `KeyError: 'AVE-REQ-999'`. Required: validate tooling tags (the
   fast-tier "Evidence tooling unit tests" step or `record` fails with file and line); `cmd_show` reports unknown IDs
   as an `EvidenceError`; a `test_evidence.py` case tagged AVE-REQ-097 AC-2.
8. AVE-REQ-098 AC-3 — `docs/PROGRESS.md`, `CLAUDE.md` § Git: partial results that PROGRESS.md names as the resume
   point lived only in the container (the media-core fix branch `worktree-agent-ace5eb07e8aecbfbf` with
   `548c8ca`/`90a1f2e`/`dc89da2` was never pushed; the M1/M2 briefs and the tag-conversion script were in the
   session scratchpad). The lead persisted the briefs (`90365e0`) and the workflow records ([docs/workflows/](../workflows/README.md))
   before handing over. Required: CLAUDE.md § Git and develop § Parallel work make every commit and file that
   PROGRESS.md names reachable from the remote before PROGRESS.md names it (worktree branches merged into or pushed
   alongside the working branch after each handback, as the session's push permission allows); the AC-3
   strategy covers the lead's own session limit with an inspection that the remote holds every hash PROGRESS.md
   names (`git branch -r --contains <hash>`).
9. AVE-REQ-098 AC-3 — `docs/PROGRESS.md:22,27` (as of `4d9ef9a`): persisted state said delegated reviews were
   "running", which a later session cannot check (baseline `spec/AGENT_WORKFLOW.md:108`: never say unfinished work
   is still running after the session stops). Required: a stop-safe form for in-flight delegated work ("launched
   <date>; verdict not recorded — on resume without a recorded verdict, re-run <exact command>") in the PROGRESS.md
   header comment or develop § Context hygiene, and resume-project treats an unrecorded verdict as not running.

Also in scope (non-blocking findings):
10. 093: the Implementation evidence path of the package validator is `ai-video-editor-requirements/tools/validate_package.py`.
11. 093: `scripts/tests/test_evidence.py:119-120` writes the real tags "AVE-REQ-093 AC-1/AC-2" as fixture strings;
    use a fictitious ID or build the string so the literal tag never appears in the source.
12. 094: `scripts/tests/test-probe-environment.sh` checks only headings; a probe with every CPU, memory, disk and
    device measurement removed and a false "GPU available (h264_nvenc)" line passed 14/14. Assert the cpus value
    equals `getconf _NPROCESSORS_ONLN`, memory matches a GiB value, and with no device and no `nvidia-smi` on PATH the
    probe prints an explicit "accelerator: none (no device)".
13. 094: record `claude --version` in the probe and update the version row (2.1.286 recorded, 2.1.287 installed);
    resume-project runs `./scripts/probe-environment.sh --offline` and updates ENVIRONMENT_CAPABILITIES.md when it
    differs. Cite completed workflow runs only, with their results.
14. 094: the sequential fallback states how independent review happens without subagents (a fresh session or
    context working from the repository alone; the review is recorded as sequential; the requirement stays in
    verification until reviewed).
15. 096: `scripts/tests/test-checker.sh:182-186` exercises two of the seven brief headings (mutation keeping only
    those two passed 134/134): loop over all seven. Check 11 also enforces heading order, non-empty sections, at
    least one AVE-REQ ID in Requirements and a 7–40-hex commit in Input revision, with test cases.
16. 096: develop §4's worktree check uses `git merge-base --is-ancestor`; use equality with the intended commit.
17. 096: WORKFLOW_LOG WF-001 says mutation runs are "recorded in the commits' handbacks", which commit messages do
    not hold: persist handbacks (for example `docs/briefs/<slug>.handback.md`) and correct the wording; get an
    independent review recorded for each WF entry (AT-29 needs a reviewed workflow-change log).
18. 096: the operating baseline allows concurrent writers in the main tree on disjoint paths, while the
    Description requires verified worktree isolation for concurrent writers: remove that option or record an
    assumption reconciling it.
19. 097: `--forbid-skips` misses module-level `pytest.skip(allow_module_level=True)` and `pytest.importorskip`
    ("1 passed, 2 skipped", exit 0): handle skipped collect reports in `pytest_collectreport`, with a pytester case.
20. 097: `evidence.py show --require-fresh --require-complete` exits 0 for a manifest whose result is FAIL: return 1.
21. 097: `backend/tests/unit/test_evidence_plugin.py:76-85` mixes skip and xfail in one module (mutations dropping
    either category survive): parametrize over skip-only, xfail-only and xpass-only modules.
22. 097: `scripts/tests/test-stop-hook.sh:40` is vacuous (fixture steps register nothing): register marker steps
    per tier and assert media and release markers are absent.
23. 098: `scripts/check-project-control.sh` rejects `bypassPermissions`/`dontAsk` default modes,
    skip-permission-prompt settings, a SessionStart matcher excluding compact or resume, and hook commands with
    `while true`, `sleep`, `nohup`, `disown`, `setsid` or a trailing `&` (a mutated settings.json with all of these
    passed every check); test-checker cases tagged AVE-REQ-098 AC-2/AC-4.
24. 098: the SessionStart hook prints a count of uncommitted paths: print a bounded `git status --short` list or
    correct the strategy and test comment; map AC-1 "changed files" to evidence.
25. 098: `.env.example` with the product variable names and purposes; each external gap in PROGRESS.md § Blockers
    or ENVIRONMENT_CAPABILITIES.md gets one exact unblock line; § Verification status names the commit and tier.
26. All five: criterion evidence for the tooling suites comes from the release tier; each requirement's Test
    evidence records inspection lines (`- AC-n → inspection: …`) so the manifest shows them as inspected; the
    dependency order holds (093 → 094 → 096/097/098 move to done in that order).

Recorded by the lead, outside this task: the requirement status transitions, PROGRESS.md, TRACEABILITY.md and the
re-verification. Proposed follow-ups, not in this task: a superseded baseline requirement needs a successor that
carries every baseline criterion (093 finding); provider-fake fixtures apply the `contract` marker automatically
when the provider adapters land (097 finding).

## Input revision
`ccr-af7078da-q8r8mf` at the commit that adds this brief (`git log -1 --format=%h -- docs/briefs/2026-10-02-m0-process-verification-fixes.md`),
or a later commit of that branch that merged the media-core fix branch; main working tree or an isolated worktree
from that commit. Add commits; never amend.

## Allowed paths
`scripts/**`, `.claude/**`, `CLAUDE.md`, `.env.example` (new), `backend/tests/evidence_plugin.py`,
`backend/tests/unit/test_evidence_plugin.py`, `docs/ENVIRONMENT_CAPABILITIES.md`, `docs/WORKFLOW_LOG.md`,
`docs/ARCHITECTURE.md` (§ Testing strategy), `docs/requirements/README.md`, `docs/briefs/README.md`, the
§ Edge cases, § Verification strategy and § Implementation evidence sections of the five requirement files.

## Forbidden paths
`ai-video-editor-requirements/**`; `backend/src/**` and the other backend tests (the media-core fix branch and the
M1/M2 tasks own them); requirement statements, acceptance criteria, statuses and Status logs (the lead's);
`docs/PROGRESS.md`, `docs/TRACEABILITY.md`, `docs/ROADMAP.md`, `docs/ASSUMPTIONS.md` (report updates);
existing briefs; `.github/**`.

## Dependencies and constraints
- ADR-001, ADR-003; [docs/requirements/README.md](../requirements/README.md) for the evidence format.
- Repository artifacts never carry model identifiers (session rule): the Models row records how models are
  observed and which overrides the tools accept.
- Each fix gets a test confirmed to fail without it (mutation; clear `__pycache__` first, WF-004). No loosened
  check, skipped test or weakened gate.
- One heavy media job at a time across every running agent.
- Style: affirmative statements (no "X, not Y", "rather than", "instead of").

## Test commands
- `./scripts/verify.sh --tier release` must pass.
- `python3 scripts/evidence.py show AVE-REQ-093 AVE-REQ-094 AVE-REQ-096 AVE-REQ-097 AVE-REQ-098 --require-fresh`
  after that run: report per-criterion states.
- `bash scripts/tests/run.sh --all-awks`.

## Handback schema
Per item 1–26: change (files), test (node or case name), mutation result; commands with results; proposed
updates for the lead-owned documents; open questions.
