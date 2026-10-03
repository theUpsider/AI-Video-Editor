# Handback — AVE-REQ-094 probe evidence, part 2 (tests)

Brief: `docs/briefs/2026-10-03-ave-req-094-probe-evidence.md` (part 2). Branch `ave-req-094-probe-evidence`
(worktree `.claude/worktrees/ave-req-094-probe-evidence`), built on `4e607de`. Commit: the commit that adds this
file, subject "test: measure every AVE-REQ-094 AC-1 probe line in the probe suite"
(`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-03-ave-req-094-probe-evidence.part-2.md`).
Changed: `scripts/tests/test-probe-environment.sh` only, 28 → 96 checks. Result: COMPLETE; 7 checks fail until
part 3 changes the Network section of `scripts/probe-environment.sh`.

## Tests added per AC-1 item

Every expected value comes from the suite's own command or computation in the same run; the probe's output is
never an oracle. All checks sit under `# AVE-REQ-094 AC-1` comment tags.

### Memory
- `memory equals MemTotal of /proc/meminfo in GiB (…)`: MemTotal kB read from `/proc/meminfo` with `sed`,
  converted to GiB with one decimal by shell integer arithmetic (half up; an exact tie also accepts the value
  below, which printf's round-half-even gives). Replaces the format-only check `memory is a GiB value`.

### Disk
- `disk equals the Avail and Size fields of df -h . (…)`: the second line of `df -h .` read with `read`,
  measured before and after the probe run (either value matches: free space can change during the run).
  Replaces the format-only check `disk reports free and total space`.
- `fake df first on PATH: disk equals its Avail and Size fields (465G free of 977G)`: a fake `df` makes a value
  fixed in the probe fail even when it equals the host's value.

### Media tools and toolchains (ffmpeg, ffprobe, python3, uv, git)
- `<tool> equals the first line of '<tool> -hide_banner -version'` (ffmpeg, ffprobe) or `'<tool> --version'`
  (python3, uv, git): the real tools; the oracle is the first output line of the same command through the same
  PATH, and the tool's second output line must be absent from the report (a probe printing the whole output
  fails).
- `<tool> hidden from PATH: not installed`: the five tools hidden through `path_without`; the check also
  asserts that the tool is absent from that PATH.
- `fake <tool> first on PATH: equals the first line of …`: fakes with distinct two-line version output.

### Browsers
- `PLAYWRIGHT_BROWSERS_PATH unset: reported as unset` (the suite unsets the variable).
- `PLAYWRIGHT_BROWSERS_PATH set: reported with its directory`: a temp directory.
- `playwright browsers lists the entries of PLAYWRIGHT_BROWSERS_PATH (chromium-1187 ffmpeg-1011 firefox-1490 )`:
  the oracle is `ls -1 | sort` of that directory, compared as a sorted word list.
- `fake chromium on PATH: reported with the first line of its --version (…)`, and the same for
  `google-chrome`; the second output line must be absent.
- The base PATH hides `chromium`, `chromium-browser` and `google-chrome`, so a browser of the host never reaches
  the results.

### Git
- `worktrees equals git worktree list | wc -l (…)` (measured before and after the probe run) and
  `branch equals git rev-parse --abbrev-ref HEAD (…)`, in the repository: the suite runs every probe from the
  repository root.
- Fixture: a repository in the temp directory with two linked worktrees (3 listed) on branch
  `probe-fixture-branch`, holding a copy of the probe that runs from there (repository and working directory
  coincide): `git fixture: three worktrees on branch probe-fixture-branch` (setup guard),
  `git fixture: worktrees equals git worktree list | wc -l (3 listed)`,
  `git fixture: branch equals git rev-parse --abbrev-ref HEAD (probe-fixture-branch)`.

### Network
- `curl absent: network probes report curl not installed`.
- `offline: curl is never invoked`: a recording fake curl first on PATH during an `--offline` run.
- Two scripted scenarios, `network-1` and `network-2`: the probe runs without `--offline`, with a fake curl first
  on PATH (the real curl hidden) and the product credential variables set to a secret. Every host gets a status
  code in one scenario and no response in the other (curl exit codes 6, 7, 28, 35); the codes include 3xx, 4xx
  (405 shows that a refused HEAD still proves the host answers) and 5xx; `pypi.org/simple/` (48 000 000 bytes)
  and `github.com/` (600 000 bytes) carry large bodies. Per scenario:
  - `<host> reads 'HTTP <code>' on one line (fake curl: <code>)` or `<host> reads 'unreachable' on one line
    (fake curl: fail:<exit>)`, for each of the seven hosts;
  - `<host> is requested`, for each of the seven hosts;
  - `every request fetches no body (-I/--head, a bounded -r/--range or --max-filesize)`: the fake records each
    request that would download an unbounded body as a violation, and the suite prints the violations under the
    check;
  - `every request has a time limit of at most 10 s (-m/--max-time)`;
  - `only the seven hosts are requested`;
  - `no credential value reaches curl` (its arguments and the report).
- The fake curl parses short options (combined ones too, such as `-sSIo`) and long options, and emulates
  `-I`/`--head`, `-r`/`--range`, `--max-filesize` (exit 63 with the status code known when the body would exceed
  the limit, as curl does), `-f`/`--fail` (exit 22 on a code of 400 or more, the code still written), `-i`, `-o`,
  `-D` and `-w` (`%{http_code}`, `%{response_code}`, `%{exitcode}`, `%{url_effective}`); a scripted failure exits
  with its curl code and writes `000`. `-X HEAD` counts as a body request: curl keeps waiting for a body after
  it, and curl documents `-I` as the HEAD form.

### Suite setup
- The suite changes to the repository root before every probe run and unsets `PLAYWRIGHT_BROWSERS_PATH`,
  `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE` and `GIT_COMMON_DIR`.
- `path_without` builds each mirror with `mktemp -d` and links the directory's entries with one `ln -s`
  (test defect 3 below).
- New helpers: `line`, `has_line`, `lines_of`, `pw_entries`, `first_line`, `second_line`, `no_line`,
  `disk_free`, `make_fake_curl`, `time_limits_ok`.

## Checks failing until part 3 (7)

| Check | Defect it exposes |
|---|---|
| `network-1: files.pythonhosted.org/ reads 'unreachable' on one line (fake curl: fail:28)` | The probe prints `HTTP unreachable`: the no-response verdict carries the `HTTP` label of a status code. |
| `network-1: api.openai.com/ reads 'unreachable' on one line (fake curl: fail:6)` | Same. |
| `network-2: pypi.org/simple/ reads 'unreachable' on one line (fake curl: fail:7)` | Same. |
| `network-2: registry.npmjs.org/ reads 'unreachable' on one line (fake curl: fail:28)` | Same. |
| `network-2: api.anthropic.com/ reads 'unreachable' on one line (fake curl: fail:35)` | Same. |
| `network-1: every request fetches no body (-I/--head, a bounded -r/--range or --max-filesize)` | The probe sends `curl -sS -o /dev/null -m 8 -w %{http_code} <url>`, a plain GET that downloads the whole body (46 MB for `pypi.org/simple/`), so the verdict depends on bandwidth. |
| `network-2: every request fetches no body (-I/--head, a bounded -r/--range or --max-filesize)` | Same. |

Two reference fixes applied to a copy under the container's `/tmp` pass all 96 checks: `-I` with the verdict
taken from the status code (`[1-9][0-9][0-9]` → `HTTP <code>`, otherwise `unreachable`), and `-I` with the
verdict taken from curl's exit status. The suite also accepts `-r 0-0`, `--max-filesize 1024` with the
status-code verdict, `-sSIo /dev/null -m8`, the long-option spelling (`--head --output --max-time --write-out`)
and `-f` with the status-code verdict (each 96 of 96).

## Mutation results

Harness: a Python script kept outside the repository copies `scripts/` and `.env.example` to `/tmp/probe-mut` in
the container, applies one textual mutation to the copy of `scripts/probe-environment.sh`, runs the suite there,
compares its failing checks with those of the unmutated base, and deletes the copy. Bases: `orig` (the probe at
`4e607de`, 7 failing checks) and `fixA`/`fixB` (the two reference fixes, 0 failing). The copy is no Git
repository, so there the real-repository Git oracles read `0 listed` and `none`; the fixture covers Git in the
copy. 49 mutations: 48 caught, 1 survived.

| Mutation | Base | Caught by (new failing checks) |
|---|---|---|
| memory hard-coded `1.0 GiB` | orig | memory (1) |
| memory hard-coded to this host's `7.5 GiB` | orig | survived (open question 1) |
| memory line deleted | orig | memory (1) |
| `MemAvailable` read for `MemTotal` | orig | memory (1) |
| divisor 1000000 (GB) | orig | memory (1) |
| `%.0f` rounding | orig | memory (1) |
| disk hard-coded `1G free of 2G` | orig | disk, fake df (2) |
| disk hard-coded to this host's value | orig | fake df (1) |
| disk line deleted | orig | disk, fake df (2) |
| disk fields swapped (Size free of Avail) | orig | disk, fake df (2) |
| Media tools body deleted, heading kept | orig | ffmpeg and ffprobe: real, hidden, fake (6) |
| Toolchains body deleted, heading kept | orig | python3, uv, git: real, hidden, fake (9) |
| Browsers body deleted, heading kept | orig | Playwright unset, set, list; chromium; google-chrome (5) |
| Git body deleted, heading kept | orig | worktrees, branch: repository and fixture (4) |
| ffmpeg, ffprobe, python3, uv, git each hard-coded to this host's version (5 mutations) | orig | fake run and hidden run of that tool (2 each) |
| ffmpeg line removed | orig | ffmpeg real, hidden, fake (3) |
| `version()` without the `not installed` branch | orig | five hidden tools and `claude absent` (6) |
| `first()` without `head -n 1` | orig | real and fake version checks, browser checks (9) |
| worktrees hard-coded `2 listed` | orig | repository, fixture (2) |
| worktrees hard-coded to the copy's value | orig | fixture (1) |
| worktrees off by one (`tail -n +2`) | orig | fixture (1) |
| branch hard-coded `ave-req-094-probe-evidence` | orig | repository, fixture (2) |
| branch hard-coded to the copy's value | orig | fixture (1) |
| `PLAYWRIGHT_BROWSERS_PATH` hard-coded `unset` | orig | Playwright set (1) |
| Playwright list removed | orig | Playwright list (2) |
| Playwright list cut to its first entry | orig | Playwright list (1) |
| browser loop limited to `chromium` | orig | google-chrome (1) |
| browser version hard-coded `installed` | orig | chromium, google-chrome (2) |
| `--offline` ignored | orig | skipped offline, curl never invoked (2) |
| network code hard-coded `HTTP 200` | orig | every non-200 code line (7) |
| `-m 8` removed | orig | time limit, both scenarios (2) |
| `-m 30` | orig | time limit, both scenarios (2) |
| `api.openai.com/` dropped from the host list | orig | requested ×2, its code line (3) |
| `Authorization` header with `ANTHROPIC_API_KEY` | orig | credential, both scenarios (2) |
| each host line printed twice | orig | the code lines that otherwise pass (9) |
| extra host `example.com/` probed | orig | only the seven hosts, both scenarios (2) |
| `-I` dropped | fixA | no body, both scenarios (2) |
| `-X HEAD` for `-I` | fixA | no body, both scenarios (2) |
| open range `-r 0-` for `-I` | fixA | no body, both scenarios (2) |
| `-m 11` | fixA | time limit, both scenarios (2) |
| no response reported as `HTTP 000` | fixA | the five `unreachable` lines (5) |
| no response reported as `HTTP unreachable` | fixA | the five `unreachable` lines (5) |
| only 2xx counted as a response | fixA | every 3xx, 4xx, 5xx line (7) |
| `-f` with the exit-status verdict | fixB | every 4xx and 5xx line (6) |
| `--max-filesize 1024` with the exit-status verdict | fixB | `pypi.org/simple/` and `github.com/` `HTTP 200` (2) |

A first harness run found a defect of these tests: the `first()` without `head -n 1` mutation survived, because
the line check found the first version line among the extra lines. Fixed before this commit: every version check
also requires the tool's second output line to be absent, and every fake prints two lines; the second run above
catches it.

## Test defects found in the existing suite
1. The memory and disk checks matched a number format only; `item "memory" "1.0 GiB"` and
   `item "disk (repository)" "1G free of 2G"` passed (the skeptic's finding). Replaced by measured comparisons.
2. The Media tools, Toolchains, Browsers and Git sections were checked by heading only; deleting their bodies
   passed. Each line is now compared with a measured value.
3. `path_without` named its mirrors `path-mirror-$n` with `n` local to each call, and each call runs in a command
   substitution: a second call reused `path-mirror-1`, `ln` failed on the existing names, and a command the second
   call hides stayed visible through the first mirror's link. Latent while the suite called it once; fixed with
   `mktemp -d`. `scripts/tests/test-verify-tiers.sh` carries the same helper with a single call (latent there;
   outside this part's allowed paths).
4. The suite ran the probe from the caller's working directory, with the caller's `PLAYWRIGHT_BROWSERS_PATH` and
   browsers on PATH, so the Browsers, disk and Git lines depended on the host and the directory. The suite now runs
   from the repository root with those inputs controlled.

## Ambiguities and recommended readings
1. "every host line reads … `unreachable` when the fake exits non-zero": the tests require the value
   `unreachable` exactly. Other reading: `HTTP unreachable` (the current output). Recommended: `unreachable`, as
   the brief's network verdict rule words it.
2. `disk (repository)` and the Git lines measure the probe's working directory (`df -h .`, `git` without `-C`).
   The tests run the probe from the repository root and from its copy in the fixture, so measuring `.` and
   measuring `$ROOT` both pass. Recommended for part 3: measure `$ROOT` (`df -h "$ROOT"`, `git -C "$ROOT"`), so
   the label holds from any directory.
3. Time limit: the tests require `-m`/`--max-time` with 0 < t ≤ 10 s on every request (the brief allows at most
   10 s per request, and its verdict rule counts a response within the timeout). A `--connect-timeout` alone
   fails the check.
4. Body-free forms: `-I`/`--head`, `-r`/`--range` with a finite end, and `--max-filesize`. `-X HEAD` and an open
   range (`0-`) count as body requests. With `--max-filesize`, a larger response makes curl exit 63 with the
   status known; the tests then expect `HTTP <code>` (a response arrived), so an exit-status verdict combined
   with `--max-filesize` fails.
5. Host labels: the fake's answers and the expected lines use the seven URLs as the probe prints them today
   (`pypi.org/simple/`, `files.pythonhosted.org/`, `registry.npmjs.org/`, `github.com/`,
   `huggingface.co/api/models?limit=1`, `api.anthropic.com/`, `api.openai.com/`). A URL change in part 3 needs
   the same change in the `net_run` script lines (a test repair under part 3's rule, with its evidence).
6. Memory oracle: MemTotal of `/proc/meminfo`, as the brief states. In the container `memory.max` reads `max`,
   so MemTotal is the memory of the WSL virtual machine (7.5 GiB). If part 1 recommends reporting a cgroup limit,
   the oracle changes with it.
7. Unspecified and left untested: the output when `PLAYWRIGHT_BROWSERS_PATH` names a missing or empty directory,
   and when no browser binary is on PATH (the probe then prints no browser line).

## Verification
- `./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh`: `PROBE TOTAL: pass=89 fail=7`, the
  7 checks above. The same result from `/tmp` and `/` as working directory and with
  `PLAYWRIGHT_BROWSERS_PATH=/nonexistent` in the environment; no temp directory left behind.
- `./scripts/dev-container.sh bash scripts/tests/run.sh`: five suites PASS (checker 199, baseline 79, stop hook
  72, session start 31, verify tiers 23); `test-probe-environment.sh` FAIL with the 7 checks above.
- `./scripts/verify.sh`: PASS, tier fast, 9 of 9 steps.
- `./scripts/dev-container.sh ./scripts/check-project-control.sh`: OK, 0 warnings.
- Mutation harness: 49 mutations, 48 caught, 1 survived; 7 accepted request forms, 96 of 96 each.

## Lead updates (proposed)
- `scripts/tests/run.sh` header, the line of this suite, which reads "offline: measured resources, accelerator
  verdict, Claude Code version, OS user, writability; never prints secrets". Proposed: "measured resources,
  media tools, toolchains, browsers and Git; accelerator verdict; Claude Code version, OS user, writability;
  network lines through a fake curl; never prints secrets". The file lies outside the allowed paths of parts 2
  and 3.
- AVE-REQ-094 § Verification strategy AC-1 (part 3): list the measured lines as this suite checks them: memory
  against `/proc/meminfo`, disk against `df -h .`, tool versions against their own output and `not installed`
  when hidden, the Playwright directory and browser binaries, worktree count and branch, and the network lines
  through a fake curl with body-free requests limited to 10 s.
- § Test evidence (lead, after part 3 and the review): `scripts/tests/test-probe-environment.sh`, 96 checks,
  AVE-REQ-094 AC-1.
- No Status transition and no ENVIRONMENT_CAPABILITIES.md row from this part (it measures nothing live).

## Open questions
1. A memory value hard-coded to the host's exact value passes the suite: the probe reads `/proc/meminfo` with no
   override, so the suite can compare only with the host's own value (the pre-existing `cpus` check has the same
   limit with `getconf`). An input override in the style of `AVE_PROBE_DEV_DIR` (for example a directory that
   replaces `/proc` for `meminfo`) would let a fixture value prove that the line is computed. It changes the
   probe's interface, so it is the lead's call; it would come with a matching check.
