# Handback — AVE-REQ-094 probe evidence, part 3 (implementation)

Brief: `docs/briefs/2026-10-03-ave-req-094-probe-evidence.md` (part 3). Branch `ave-req-094-probe-evidence`
(worktree `.claude/worktrees/ave-req-094-probe-evidence`), built on part 2's `49ecb21` (base `4e607de`). Commit:
the commit that adds this file, subject "AVE-REQ-094: measure every probe line and check reachability without a
body" (`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-3.md`).
Result: COMPLETE. `scripts/tests/test-probe-environment.sh` passes 96 of 96; the live probe prints `HTTP <code>`
for all seven hosts.

## Inputs checked
- Part 1 (structured result in the prompt; its handback lives on the working branch at `08237ac`): the HEAD form
  and the cwd finding were reproduced live in the container before relying on them. HEAD on the seven hosts:
  exit 0, codes 200, 404, 200, 200, 200, 404, 421, 0 body bytes, 0.83 to 1.43 s. The probe at `49ecb21` run from
  `/tmp` printed `disk (repository) 943G free of 1007G`, `worktrees 0 listed`, `branch none`; from the worktree it
  printed `20G free of 237G`, `2 listed`, `ave-req-094-probe-evidence`.
- Part 2 (`49ecb21`, its handback in this worktree): `PROBE TOTAL: pass=89 fail=7` before this part, the 7 failing
  checks the part-2 handback lists.

## Changes per item

### Network section (`scripts/probe-environment.sh`)
- Request: `curl -sS -o /dev/null -I -m 10 -w '%{http_code}' "$url"`, one HEAD request per host with a 10 s limit
  (part 1's recommended form). It replaces the GET with `-m 8` that downloaded the body (46 MB for
  `pypi.org/simple/`).
- Verdict from the status code curl writes: a three-digit code (`[1-9][0-9][0-9]`) prints `HTTP <code>`, any
  status included; anything else (curl writes `000` when no response arrives: refused, unresolved, TLS failure,
  the time limit) prints `unreachable`. The value `unreachable` replaces `HTTP unreachable`.
- Host list, labels, `--offline` and the `curl not installed` branch are unchanged; the output format is kept.

### Disk and Git lines (`scripts/probe-environment.sh`)
- `df -h "$ROOT"`, `git -C "$ROOT" worktree list` and `git -C "$ROOT" rev-parse --abbrev-ref HEAD` replace
  `df -h .` and `git` in the working directory: the `disk (repository)` and Git lines measure the repository
  whichever directory the probe starts in (the open question both handoffs raised, resolved with their
  recommended default). From `/tmp` the probe now prints the repository's values.

### Memory, media tools, toolchains, browsers
- Unchanged: each line was already measured, and part 2's checks compare them with the suite's own values.

### Test repair (`scripts/tests/test-probe-environment.sh`)
Test defect, with its evidence: the suite started every probe in the repository root and its fake `df` ignored
its arguments, so the disk and Git checks passed for a probe that measures its working directory. Evidence: the
probe at `49ecb21` run from `/tmp` in the container reports the overlay root (`943G free of 1007G`) as
`disk (repository)` and `0 listed` / `none` for Git, and part 2's suite passes it (the working directory is the
repository there). Repair:
- every probe run starts in the suite's temp directory (`cd "$T"`), outside the repository;
- the oracles measure the repository by path: `disk_free "$REPO"` (`df -h "$1"`), `git -C "$REPO" worktree list`,
  `git -C "$REPO" rev-parse --abbrev-ref HEAD`;
- the fake `df` answers `465G free of 977G` for the repository (its last argument resolves to the repository) and
  `1.0G free of 2.0G` for any other directory;
- the fixture's probe copy runs from the temp directory (`"$GITFIX/main/scripts/probe-environment.sh"`);
- two check names follow the oracle: `disk equals the Avail and Size fields of df -h on the repository (…)` and
  `fake df first on PATH: disk equals its Avail and Size fields for the repository (…)`; the header comment says
  where the probe starts.
No check was removed or weakened; the suite still holds 96 checks.

## Mutation results
Harness (session scratchpad, run in the container through `./scripts/dev-container.sh bash -s`): for each
mutation it copies `scripts/` and `.env.example` to `/tmp/m`, makes `/tmp/m` a Git repository on branch
`probe-mut-branch` with one linked worktree (so the repository's Git oracles read `2 listed`), applies one literal
replacement to the copy of the probe, runs the suite there and deletes the copy. Base copy: 96 of 96. All 17
mutations and the part-2 probe caught; no copy left in `/tmp`.

| Mutation of the part-3 probe | Failing checks |
|---|---|
| probe at `49ecb21` (whole file) with the repaired suite | 12: the 7 network checks of part 2, repository worktrees and branch, fake df, fixture worktrees and branch |
| `-I` dropped | no body, both scenarios (2) |
| `-X HEAD` for `-I` | no body (2) |
| open range `-r 0-` for `-I` | no body (2) |
| `-m 11` | time limit, both scenarios (2) |
| `-m 10` removed | time limit (2) |
| no response reported as `HTTP 000` | the five `unreachable` lines (5) |
| no response reported as `HTTP unreachable` | the five `unreachable` lines (5) |
| only 2xx counted as a response | every 3xx, 4xx and 5xx line (7) |
| code hard-coded `HTTP 200` | every other code line (7) |
| `api.openai.com/` dropped | its lines and requests, both scenarios (4) |
| `Authorization` header with `ANTHROPIC_API_KEY` | no credential value reaches curl (2) |
| `--offline` ignored | skipped offline, curl never invoked (2) |
| `df -h .` for `df -h "$ROOT"` | fake df (1); the real-df check also fails wherever the repository and the temp directory lie on different file systems, as `/workspace` (`20G free of 237G`) and `/tmp` (`943G free of 1007G`) do in the container; the copy in `/tmp` shares the temp directory's file system |
| disk hard-coded `1G free of 2G` | disk, fake df (2) |
| `git worktree list` without `-C "$ROOT"` | worktrees: repository and fixture (2) |
| `git rev-parse` without `-C "$ROOT"` | branch: repository and fixture (2) |
| memory hard-coded `1.0 GiB` | memory (1) |

## Test results
Every command ran from the worktree on branch `ave-req-094-probe-evidence`, on 2026-10-03.
- `./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh`: before this part
  `PROBE TOTAL: pass=89 fail=7` (part 2's 7 checks); after the probe change `pass=96 fail=0`; after the test repair
  `pass=96 fail=0`, the same from `/tmp`, from `/` with `PLAYWRIGHT_BROWSERS_PATH=/nonexistent`, and from
  `scripts/tests`; no `probe-tests.*` directory left behind.
- `./scripts/dev-container.sh bash scripts/tests/run.sh`: PASS (6 suites): checker 199/0, baseline 79/0, stop hook
  72/0, session start 31/0, verify tiers 23/0, probe environment 96/0.
- `./scripts/verify.sh`: PASS, tier fast, 9 of 9 steps (run twice: before and after this handback was completed).
- `./scripts/dev-container.sh ./scripts/probe-environment.sh`: live, two runs; every Network line reads
  `HTTP <code>` (rows below).
- `./scripts/dev-container.sh ./scripts/check-project-control.sh`: OK, 0 warnings (49 required files,
  196 Markdown files, 134 requirement files).
- Mutation harness: 17 mutations and the part-2 probe, all caught (table above).

## Re-measured rows (`docs/ENVIRONMENT_CAPABILITIES.md` § Network policy)
Live from the container on 2026-10-03 (`./scripts/dev-container.sh ./scripts/probe-environment.sh`, two runs at
05:33:48 and 05:34:01 UTC, the whole probe in 9.0 s and 8.0 s; curl 8.5.0). A timed run of the probe's request with
`%{time_total}` and `%{size_download}` added (05:34:19 UTC): exit 0 everywhere, 0 body bytes.

| Host | Probe line | Time |
|---|---|---|
| pypi.org/simple/ | HTTP 200 | 0.83 s |
| files.pythonhosted.org/ | HTTP 404 | 0.84 s |
| registry.npmjs.org/ | HTTP 200 | 1.43 s |
| github.com/ | HTTP 200 | 1.42 s |
| huggingface.co/api/models?limit=1 | HTTP 200 | 1.22 s |
| api.anthropic.com/ | HTTP 404 | 0.97 s |
| api.openai.com/ | HTTP 421 | 0.87 s |

The `unreachable` path through the real curl, with nothing contacted: the probe run with
`https_proxy=http://127.0.0.1:9` prints `unreachable` for all seven hosts.

Edited in that file: the probe sentence (names Git worktrees and branch, the HEAD request with its 10 s limit and
the verdict rule, and the 2026-10-03 runs) and § Network policy (method, date, the timed run, and the rows with the
probe's labels and codes; the `uv sync` result and the apt row keep their 2026-10-02 date). The Browser tools row
is unchanged: the probe gained no browser line.

## Requirement sections edited (`docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md`)
- § Edge cases: a media tool or toolchain absent from PATH; the probe started outside the repository; the
  network verdict (any status, no response within 10 s, header-only request), no `curl`, `--offline`.
- § Verification strategy AC-1: every measured line, as the suite checks it or, for the lines it compares with
  nothing (kernel, OS, CPU model, device lists, FFmpeg's built-in capabilities, node, pnpm, docker), as an
  inspection value; the probe started outside the repository; the fake `curl` scenarios; the live run outside
  the suite; browser tools named among the
  session-inspected rows. AC-2: cites this task's brief and its four stages.
- § Implementation evidence: the probe and capabilities entries describe the measured lines and the HEAD request;
  the `docs/briefs/` entry names this brief and its part handbacks.

## Lead updates (proposed)
- AC-2: cite this run (its workflow run ID) under § Verification strategy AC-2 and § Test evidence at integration;
  the brief is already cited there.
- `scripts/tests/run.sh` header, the line of this suite (part 2's proposal, still open): "measured resources,
  media tools, toolchains, browsers and Git; accelerator verdict; Claude Code version, OS user, writability;
  network lines through a fake curl; never prints secrets".
- `docs/ENVIRONMENT_CAPABILITIES.md` rows outside part 3's allowed paths (part 1's measurements): Container CPU /
  memory — the container has no cgroup limit (`memory.max` reads `max`), and `/proc/meminfo` shows the Docker
  Desktop WSL 2 VM total; Disk — the bind-mounted `C:` reads 19G free of 237G from the container on 2026-10-03.
- § Test evidence (after the review): `scripts/tests/test-probe-environment.sh`, 96 checks, AVE-REQ-094 AC-1.
- TRACEABILITY.md AVE-REQ-094 row: no cell changes (same implementation and test files).
- PROGRESS.md: part 3 done on branch `ave-req-094-probe-evidence`; review next.
- Status: stays `in-progress`; `verification` when the lead requests `verify-requirement`.
- Proposed `docs/ASSUMPTIONS.md` entry: "The probe measures the repository's disk and Git state" —
  assumption: `disk (repository)`, `worktrees` and `branch` measure the repository containing the probe (`$ROOT`),
  whatever the caller's working directory — reason: the labels name the repository, and the probe runs from
  several directories (container `/workspace`, worktrees, `/tmp`) — impact: the lines are comparable between runs
  started anywhere; a caller that wants another directory's disk uses `df` directly.

## Open questions
1. Memory hard-coded to this host's exact value (7.5 GiB) still passes the suite (part 2's open question 1): the
   probe reads `/proc/meminfo` with no override. Recommended default: a follow-up adding an input override in the
   style of `AVE_PROBE_DEV_DIR` together with a fixture check; it changes the probe's interface, so it is the
   lead's call. Not done here.
2. A cgroup memory limit is invisible to the memory line (`/proc/meminfo` follows the kernel). Part 1 recommends
   no change now; the lead update above proposes recording in the capabilities document that the container has
   no limit.
