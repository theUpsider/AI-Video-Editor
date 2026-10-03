# Brief — AVE-REQ-094 probe evidence: measured probe tests, bandwidth-independent network checks, and a run that composes investigation and testing stages

## Requirements
AVE-REQ-094 AC-1 and AC-2 (AC-3 and AC-4 stay as evidenced). The re-review at `d4d3883` (workflow
`wf_ed1f5104-63a`) returned PASS; its skeptic refuted the verdict with evidence the lead accepts:
1. AC-1, test quality: `scripts/tests/test-probe-environment.sh` checks only the headings of the Media tools,
   Toolchains, Browsers and Git sections and only a number format for memory and disk. Two mutations of
   `scripts/probe-environment.sh` survived with 28 of 28 checks passing: memory and disk hard-coded
   (`item "memory" "1.0 GiB"`, `item "disk (repository)" "1G free of 2G"`), and the bodies of the Media tools,
   Toolchains, Browsers and Git sections deleted with the headings kept.
2. AC-1, network: the probe's pypi check (`curl -sS -o /dev/null -m 8 -w '%{http_code}' https://pypi.org/simple/`)
   downloads the 46 MB simple index; on this link it timed out three times while `https://pypi.org/` answered
   200, so the probe printed `pypi.org/simple/ HTTP unreachable` against the recorded "reachable" row. The
   verdict depends on bandwidth.
3. AC-1, browser tools: at `d4d3883` no session observation of browser tools existed. The Browser tools row of
   `docs/ENVIRONMENT_CAPABILITIES.md` was added in `97a8d20`; the requirement's § Verification strategy AC-1
   still omits browser tools from the session-inspected rows.
4. AC-2: every completed run composes implementation and review stages; none composes the investigation
   (researcher) and testing (tester) stages the criterion names. This task is such a run: a researcher
   investigates (part 1) in parallel with a tester that writes the tests (part 2); an implementer makes them
   pass (part 3) from both handoffs; an independent reviewer verifies the requirement and a skeptic challenges a
   PASS. The lead cites the run under AC-2 at integration.

Parts:
1. Research (read-only): for each of the seven hosts the probe checks (`pypi.org/simple/`,
   `files.pythonhosted.org/`, `registry.npmjs.org/`, `github.com/`, `huggingface.co/api/models?limit=1`,
   `api.anthropic.com/`, `api.openai.com/`), which request form answers with a status code without
   downloading a body (HEAD, a byte range, a bounded GET with `--max-filesize`), measured live from the
   container with the status code and the time to the response; one recommended `curl` invocation that
   reports `HTTP <code>` for any status and `unreachable` for no response, with the timeout that fits; the
   oracle commands a test can use for the memory and disk lines (`/proc/meminfo` MemTotal to GiB with one
   decimal, `df -h .` fields) and whether the container reports host memory or a cgroup limit.
2. Tests: `scripts/tests/test-probe-environment.sh` gains checks that compare each AC-1 measurement with a value
   the test measures itself: memory from `/proc/meminfo` (the test's own computation), disk from `df -h .`, the
   ffmpeg and ffprobe lines equal to `ffmpeg -hide_banner -version | head -n 1` and the ffprobe equivalent
   (and `not installed` when the suite hides them from PATH), the python3, uv and git lines equal to their
   `--version` output (and `not installed` when hidden), `PLAYWRIGHT_BROWSERS_PATH` reported as set to a temp
   directory whose entries the probe lists and a fake `chromium` on PATH reported with its version, the Git
   worktree count and branch equal to `git worktree list | wc -l` and `git rev-parse --abbrev-ref HEAD`, and
   the Network section driven by a fake `curl` on PATH that records its arguments and returns scripted
   results: every host line reads `HTTP <code>` for a scripted code and `unreachable` when the fake exits
   non-zero, and the fake is invoked in a form that fetches no body (header-only or bounded; the fake fails
   the check when it receives a plain unbounded GET). Each new check fails under a mutation that removes or
   hard-codes the measured line; the handback records the mutation results. Checks that need part 3 stay
   failing and are listed.
3. Implementation: `scripts/probe-environment.sh` keeps its output format and satisfies part 2's tests: the
   Network section uses the request form part 1 recommends; the memory, disk, media-tool, toolchain, browser
   and Git lines stay measured. `docs/ENVIRONMENT_CAPABILITIES.md` § Network policy records the re-measured
   rows with the method; the sentence describing the probe names the request form. The requirement's § Edge
   cases, § Verification strategy (AC-1 lists every measured line and names browser tools among the
   session-inspected rows; AC-2 cites this task's brief) and § Implementation evidence are updated.

## Input revision
`09018b8` plus the commit that adds this brief
(`git log -1 --format=%h -- docs/briefs/2026-10-03-ave-req-094-probe-evidence.md`); isolated worktree
`.claude/worktrees/ave-req-094-probe-evidence` on branch `ave-req-094-probe-evidence`, created by the lead
from that commit. Part 1 reads the main checkout and modifies nothing.

## Allowed paths
- Part 1: none. The lead persists its structured result as `docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-1.md`.
- Part 2: `scripts/tests/test-probe-environment.sh`; `docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-2.md`.
- Part 3: `scripts/probe-environment.sh`; `scripts/tests/test-probe-environment.sh` only to repair a test
  defect the part-3 handback names with its evidence; `docs/ENVIRONMENT_CAPABILITIES.md` (the probe sentence,
  § Network policy rows, the Browser tools row wording when the probe gains a browser line);
  `docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md` § Edge cases, § Verification
  strategy and § Implementation evidence only; `docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-3.md`.

## Forbidden paths
Everything else, in particular: the frontmatter, § Acceptance criteria, § Test evidence and § Status of every
requirement file; `docs/PROGRESS.md`, `docs/TRACEABILITY.md`, `docs/WORKFLOW_LOG.md`, `docs/ASSUMPTIONS.md`,
`docs/ROADMAP.md`, `docs/workflows/`; `scripts/verify.sh`, `scripts/verify.d/`, `scripts/evidence.py`,
`scripts/check-project-control.sh`, `scripts/check_baseline.py`, `scripts/dev-container.sh`; `backend/`;
`.claude/`; `ai-video-editor-requirements/` (immutable baseline).

## Dependencies and constraints
- ADR-009: every check runs in the development container through `./scripts/dev-container.sh`; the worktree
  shares the main checkout's container. This task runs the fast tier and the tooling suites only; it starts no
  heavy media job.
- Network: the host reaches the internet. Part 1 and part 3 run live `curl` probes from the container
  (`./scripts/dev-container.sh curl …`) against the seven hosts above only, anonymously, with a timeout of at
  most 10 s per request. Nothing else is contacted; no credential is used or printed.
- The suite stays deterministic on any host: measured values come from the same machine in the same run;
  external commands are hidden or faked through PATH (the suite's `path_without` helper and `$T/bin` fakes);
  the network checks use the fake `curl` only (the live probe is a manual run, outside the suite).
- Test oracle rule (verify-requirement § 8): an expected value is measured by the test with its own command or
  computation; it is never read from the probe's output. Mutation copies live under the container's `/tmp`
  (`./scripts/dev-container.sh bash -c 'cp -R scripts /tmp/m && …'`), never in the worktree; `__pycache__`
  directories are deleted before a mutated Python run (WF-004; this task runs shell only).
- Network verdict rule: the probe reports `HTTP <code>` for any HTTP status (a 4xx on a HEAD request still
  proves the host answers) and `unreachable` when no response arrives within the timeout; the request fetches
  no body, so the verdict does not depend on bandwidth.
- Browser tools: the probe reports shell-observable facts only (binaries, Playwright path); the session-level
  Browser tools row stays a lead observation (`97a8d20`).
- Structured handoffs: the workflow passes part 1's result and part 2's handback into part 3's prompt; part 3
  treats them as inputs to verify, with the brief as the contract.
- Concurrency: part 1 runs in parallel with part 2; part 3 starts after both; the review after part 3. One
  writer at a time in the worktree.
- Repository text states things affirmatively and names no model; LF line endings; commits in the worktree
  carry the trailers the prompt names.

## Test commands
- `./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh` — after part 2: the new checks that
  need part 3 fail and the handback lists them; after part 3: every check passes.
- `./scripts/dev-container.sh bash scripts/tests/run.sh` — every tooling suite passes after part 3.
- `./scripts/verify.sh` — fast tier passes after part 2 and after part 3.
- `./scripts/dev-container.sh ./scripts/probe-environment.sh` — live run after part 3: every Network line reads
  `HTTP <code>`.
- `./scripts/dev-container.sh ./scripts/check-project-control.sh` — passes after part 3.

## Handback schema
Every part returns a structured result with the fields `result` (COMPLETE, PARTIAL or BLOCKED), `commits`
(worktree commit hashes; empty for part 1), `handbackFile`, `items` (one per item of its part: item, status,
change, test, mutation), `verification` (the commands run and their results), `leadUpdates` (proposed Status
lines, TRACEABILITY.md and PROGRESS.md updates, the ENVIRONMENT_CAPABILITIES.md rows re-measured) and
`openQuestions`.
- Part 1 adds `hosts` (per host: request form, status code, response time, body size fetched), `curlCommand`
  (the recommended invocation), `oracles` (memory and disk oracle commands with their rounding), `sources`,
  `confidence` and `unknowns`.
- Part 2 writes `docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-2.md`: tests added per AC-1
  item, mutation results, the failing tests that await part 3 with the defect each exposes, test defects found
  in the existing suite, ambiguities with the recommended reading.
- Part 3 writes `docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-3.md`: changes per item, the
  test results of every test command, the re-measured network rows, the requirement sections edited, and the
  lead updates (including the request to cite this run under AC-2).
