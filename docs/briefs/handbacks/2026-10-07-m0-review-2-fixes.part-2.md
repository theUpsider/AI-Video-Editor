# Handback — M0 review round two, fixes, part 2: track C, the capability probe (AVE-REQ-094)

Brief: [2026-10-07-m0-review-2-fixes.md](../2026-10-07-m0-review-2-fixes.md). Run `wf_6c06f19f-506` ([script](../../workflows/m0-review-2-fixes.js)), branch `m0-r2-fixes-c` from `07eceb1`, commit `61b5ae4`. The report below is the writer's, unedited apart from local paths and the level of its headings. The host stood in standby from 00:38 to 09:52 local time on 2026-10-07; the run started tracks A and B1 again at 09:52 with new writers in the same worktrees.

## Report

### Result: COMPLETE

### Requirements
AVE-REQ-094 — Capability-aware native dynamic workflows — ACs done: AC-1 (track C: probe, suite, three sections of the requirement file); AC-2, AC-3, AC-4 untouched (PASS in the second review round); open: none — proposed status `verification`, once the lead has settled AVE-REQ-093 (named under Dependencies, `in-progress` at the base commit).

### Branch and commit
- Branch `m0-r2-fixes-c` — commit `61b5ae4a1020779cd1128de241b66b6822f127fb`, parent `07eceb1aa1693df708c240642f837d8838be175a`. `git rev-parse HEAD` printed exactly the base hash before the first change. Worktree `.claude/worktrees/m0-r2-fixes-c`. Nothing pushed, merged, rebased or switched.
- Commit message: `AVE-REQ-094: decide device names as whole strings, open without creating, print the cgroup limits`, with the two trailer lines of the prompt.

### Changes (file — purpose)
- `scripts/probe-environment.sh` — device walk through pathname expansion with the name test in the shell; open through `dd` without creating; one walk for both list lines and the verdict; two cgroup lines; `CDPATH= cd --`; time limit as a positive whole number; four shell settings fixed against exported `SHELLOPTS`/`BASHOPTS`; the URL with `?` quoted; help range `2,19`.
- `scripts/tests/test-probe-environment.sh` — 155 checks at the base, 256 now; 18 tag lines `# AVE-REQ-094 AC-1`, the one `AVE-REQ-098 AC-3` tag unchanged.
- `docs/requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md` — § Edge cases (lines 39–105), § Verification strategy (line 111, AC-1), § Implementation evidence (lines 119–121, 125). Frontmatter, criteria, Test evidence and Status log untouched.

### Items of track C

Case names are the names the suite prints.

**1. Node walk — fixed.** `scan()` walks `"$dir"/*`, takes the name as `${path##*/}`, tests the prefix by string comparison and the number by `is_number` (an explicit list of the ten digits), requires `[ -c ]`, then opens with `dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none`. Both list lines and the verdict come from that walk; a path is printed in the form of `printf %q` on the list lines and in the verdict. A trial of the `dd` operands on `/dev/null` decides whether the open test exists; without it a GPU node reads `accelerator: unknown (open test unavailable for <node>)`.
- Line feed and space: `a character device named nvidia0<LF>x is no GPU node: accelerator: none (no device)`, `a character device named nvidia0<LF>x: the probe leaves the device directory as it was`, `a character device named nvidia0<LF>x is one word of the one nvidia list line`; the same three for `dri/renderD128<LF>.bak`; `a character device named 'nvidia0 1' is no GPU node and one word of its list line`; `a device directory named 'dev spaced': the list line and the verdict name its node as one word`.
- Names: `a character device named <name> is no GPU node: accelerator: none (no device)` for `xnvidia0`, `dri/card-renderD128`, `dri/xrenderD128`, `dri/nvidia0`, `renderD128` (beside the seven names of the base); `xnvidia0 stands on no list line`; `dri/nvidia0 stands on the dri line alone`; `renderD128 outside dri stands on no list line`.
- Linked `dri`: `dri as a link to a directory: the list line and the verdict name the same render node`. Hidden entry: `a hidden entry of dri is listed`. Missing directory: `a missing device directory: both list lines read none and accelerator: none (no device)`.
- Digits: `the node dri/renderD7 alone: accelerator: present names it`, `the node dri/renderD42 alone: accelerator: present names it`. Link chain: `nvidia0 as a link to a link to a character device: accelerator: present names it`.
- Kinds: `nvidia0 as a <kind> entry is listed and is no device: accelerator: none (no device)` for regular, fifo, dangling, dirlink (the list line joined the check).
- The open: `each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none`; `the operands are tried on /dev/null once, and no other path is opened (the display node included)`; `no dd on PATH beside a GPU node: accelerator: unknown names the node the open test is unavailable for`; `no dd on PATH and no GPU node: accelerator: none (no device)`; `a dd that knows no conv=nocreat beside two GPU nodes: accelerator: unknown names both`; `a dd that knows no conv=nocreat: after the trial on /dev/null no node is opened`; `no dd on PATH, a GPU node and a GPU row of nvidia-smi: accelerator: present names the row alone`.
- No write: the helper `dev_run` lists the directory (`ls -laR --time-style=full-iso`) before and after each of its runs; `no probe run changed its device directory (changed: none)`.
- Whole list lines: `driver control nodes without a GPU node: the five entries are listed, and accelerator: none (no device)`, and the `dev-both` and `dev-card` checks now compare whole lines.
- The reviewer's mutants N3, N10 and N17, applied to the probe of the base commit and run against the new suite, each fail named new cases that the unmutated base probe passes: N3 (`grep -E "/$2\$"` to `grep -E "$2\$"`) fails `xnvidia0`, `dri/card-renderD128`, `dri/xrenderD128`; N10 (`'renderD[0-9]+'` to `'renderD[0-9]{3}'`) fails `dri/renderD7`, `dri/renderD42`; N17 (`'renderD[0-9]+'` to `'(renderD|nvidia)[0-9]+'`) fails `dri/nvidia0`. The new suite on the unmutated base probe: 174 pass, 82 fail.

**2. Network scenarios — fixed.** `network-1`: pypi 200 (48 MB), files.pythonhosted `fail:28`, registry 301, github 405 (600 kB), huggingface 429, anthropic 404, openai `fail:6`. `network-2`: pypi `fail:7`, files.pythonhosted 503, registry `fail:28`, github `fail:35`, huggingface `fail:56`, anthropic `fail:60`, openai 421. New check `the two scenarios hold seven hosts, each answering once and failing once`. The reviewer's O17 is mutant O10 below: killed by `network-2: github.com/ reads 'unreachable' on one line (fake curl: fail:35)`.

**3. `nvidia-smi` rows — fixed by cases** (the row pattern of the probe is unchanged). `nvidia-smi exits 0 with '<answer>' (no name, or text behind the unit): accelerator: none (no device)` for `, 16 MiB`, ` , 16 MiB`, `Tesla T4, 15360 MiB (shared)`, `Tesla T4, 15360 MiB ` (trailing space). The reviewer's S8 and S9 are S8 and S9 below.

**4. Quota lines — fixed, with a stated limit.** Lines `cpu quota (cgroup v2)` and `memory limit (cgroup v2)` read `cpu.max` and `memory.max` of `${AVE_PROBE_CGROUP_DIR:-/sys/fs/cgroup}`: `2.00 cpus (cpu.max 200000 100000)`, `1.0 GiB (memory.max 1073741824)`, `none` for `max` and a missing file, `unknown` for any other content (read NUL-safe, one line end at most). Cases: `cpu.max '200000 100000': cpu quota 2.00 cpus`, `memory.max 1073741824: memory limit 1.0 GiB`, `beside a quota the cpus and memory lines keep the kernel totals`, the `150000 100000` / `536870912`, `333333 100000` / `8000000000` and `50000 200000` cases, `cpu.max 'max 100000' and memory.max 'max': both lines read none`, `a cgroup directory without the two files: both lines read none`, `a missing cgroup directory: both lines read none`, `cpu.max alone: ...`, thirteen `cpu.max '<content>' is no quota form: cpu quota unknown`, eight `memory.max '<content>' is no limit form: memory limit unknown`, the three cases without a line end, with a second line end and with a NUL byte, `cpu.max and memory.max as directories: both lines read unknown`, and two host checks `cpu quota agrees with /sys/fs/cgroup/cpu.max of this host (...)`, `memory limit agrees with /sys/fs/cgroup/memory.max of this host (...)`. Limit, stated in § Edge cases lines 87–89: the lines read the two files of the mount root; a container that shares the host's cgroup namespace, a parent cgroup and cgroup v1 read `none` (observed, see Commands).

**5. `CDPATH` — fixed.** `ROOT="${AVE_PROBE_ROOT:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"`. Cases: `CDPATH exported, relative start: worktrees and branch are the fixture's`, `... writability names the fixture root on one line`, `... disk measures the fixture root (...)` (the fixture's probe started as `bash scripts/probe-environment.sh` inside the fixture, `CDPATH` naming a directory with a `scripts` directory of its own); `the probe below a directory named -dash: the root is that directory`.

**6. Time limit — fixed.** `AVE_PROBE_SMI_TIMEOUT` replaces the 10 only when `is_number` holds and one digit differs from 0. Cases: `AVE_PROBE_SMI_TIMEOUT=30 is a positive whole number: timeout is given 30`, the same for `007`, and `AVE_PROBE_SMI_TIMEOUT='<value>' is no positive whole number: the limit stays 10 s` for `0`, `00`, `abc`, `-5`, `+5`, `1.5`, `5s`, `1m`, ` 7`, `7 `, `7 8`, the empty value and `7<LF>8`. The pipe case stands as a limit in § Edge cases lines 74–76.

**Node forms checked by hand** (development container, root, 2026-10-07, final probe; `<dir>` a fresh directory given through `AVE_PROBE_DEV_DIR` to `./scripts/probe-environment.sh --offline`; `NOBODY` is `setpriv --reuid 65534 --regid 65534 --clear-groups`):

| Construction | Result |
|---|---|
| `mknod <dir>/nvidia0 c 1 3` | listed; `accelerator: present (<dir>/nvidia0)` |
| `mknod <dir>/dri/renderD128 c 1 3` | listed; `accelerator: present (<dir>/dri/renderD128)` |
| `mknod <dir>/nvidia0 b 7 0` | listed; `accelerator: none (no device)` |
| `mknod <dir>/nvidia0 c 195 0` (no driver) | `accelerator: none (no access to <dir>/nvidia0)` |
| `c 1 3` node, mode 0600, 0444, 0222, probed through `NOBODY` | each `accelerator: none (no access to <dir>/nvidia0)` |
| the same node, mode 0666 through `NOBODY`; mode 0600 as root | `accelerator: present (<dir>/nvidia0)` |
| `dri/renderD128`, mode 0660, group 44: `NOBODY`, then `setpriv --reuid 65534 --regid 65534 --groups 44` | no access, then present |
| `nvidia0` 0600 beside `nvidia1` 0666, `NOBODY` | both listed; `accelerator: present (<dir>/nvidia1)` |
| open node in a directory of mode 0711, `NOBODY` | both lists `none`; `accelerator: none (no device)` (the limit of line 58) |
| `mknod "<dir>/nvidia0"$'\n'"x" c 1 3`, mode 0666, root and `NOBODY` | list `$'<dir>/nvidia0\nx'`; `accelerator: none (no device)`; entries of the directory equal before and after |
| `dd if=<dir>/nvidia0 of=<dir>/nvidia0 count=0 conv=nocreat,notrunc status=none` on a missing path | exit 1, the directory stays empty |
| fake `nvidia-smi` (`trap "" TERM; setsid sleep 8 & wait`), `AVE_PROBE_SMI_TIMEOUT=1` | `no GPU reported` after 8 s and 10 s in two runs (the limit of lines 74–76) |
| fake `nvidia-smi` that ignores SIGTERM, `AVE_PROBE_SMI_TIMEOUT=1` | `no GPU reported` after 4 s |

**Beyond the six items, found by the statement audit:** `set +e +f`, `shopt -u failglob`, `shopt -s dotglob` (cases `SHELLOPTS=noglob exported: the walk still lists and counts the nodes`, `BASHOPTS=failglob exported: an empty device directory prints both list lines and the verdict, and no error of the shell`, `SHELLOPTS=errexit exported, a cpuinfo without a model name: the report runs to its last section`); the quoted URL (`BASHOPTS=nullglob exported: huggingface.co/api/models?limit=1 is requested and reported, seven requests in all`); `<tool> hidden from PATH: not installed` for `node`, `pnpm`, `docker`; `--help exits 0 and prints the header comment from its first line through its last, and no line of code`; the suite unsets the probe's test inputs and `CDPATH` before its first run.

### Tests (AVE-REQ-094 AC-n → test location)
- AVE-REQ-094 AC-1 → `scripts/tests/test-probe-environment.sh` (256 checks, names above); inspection: the by-hand table above and the two quota containers under Commands.
- AVE-REQ-094 AC-2, AC-3, AC-4 → inspection, unchanged by this track.

### Mutation list

Method: a copy of the probe, the suite and `.env.example` in a fresh Git repository under the container's `/tmp`, one exact replacement that matches the probe once, `bash scripts/tests/test-probe-environment.sh` with a `TMPDIR` of its own; the run stops at its first failing check. Format: `id :: old text  ==>  new text  :: first failing check`; `⏎` stands for a line feed inside the replaced text, `(nothing)` for a deletion. The unmutated copy: 256 pass, 0 fail. 132 mutants: 129 killed, 3 survive the suite (C2, N14, N15, each covered by inspection as noted). N2 survived a first run because its case compared the three lines only; the case now also requires that no `no match` message appears, and N2, N1 and the unmutated copy were rerun on that suite. N37 run to its end fails three checks, `no probe run changed its device directory` among them.

```text
R1 :: $(CDPATH= cd -- "$(dirname  ==>  $(cd -- "$(dirname  :: CDPATH exported, relative start: worktrees and branch are the fixture's
R2 :: dirname -- "${BASH_SOURCE[0]}"  ==>  dirname "${BASH_SOURCE[0]}"  :: the probe below a directory named -dash: the root is that directory
R3 :: CDPATH= cd -- "$(  ==>  CDPATH= cd "$(  :: the probe below a directory named -dash: the root is that directory
R4 :: df -h "$ROOT"  ==>  df -h .  :: fake df first on PATH: disk equals its Avail and Size fields for the repository
R5 :: git -C "$ROOT" worktree list  ==>  git worktree list  :: worktrees equals git worktree list | wc -l
R6 :: git -C "$ROOT" rev-parse --abbrev-ref HEAD  ==>  git rev-parse --abbrev-ref HEAD  :: branch equals git rev-parse --abbrev-ref HEAD
R7 :: if [ -w "$ROOT" ]; then  ==>  if true; then  :: missing fixture root: repository writable no with that root
R8 :: ROOT="${AVE_PROBE_ROOT:-$(CDPATH=  ==>  ROOT="${AVE_PROBE_ROOT_X:-$(CDPATH=  :: writable fixture root: repository writable yes with that root
R9 :: sed -n '2,19p' "$0"  ==>  sed -n '2,16p' "$0"  :: --help exits 0 and prints the header comment from its first line through its last, and no line of code
R10 :: sed -n '2,19p' "$0"  ==>  sed -n '2,21p' "$0"  :: --help exits 0 and prints the header comment from its first line through its last, and no line of code
R11 :: [--offline]\n' >&2; exit 2 ;;  ==>  [--offline]\n' >&2; exit 0 ;;  :: unknown option exits 2
P1 :: getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown  ==>  nproc  :: fake getconf answers 3: cpus 3
P2 :: $2 / 1048576  ==>  $2 / 1000000  :: memory equals MemTotal of /proc/meminfo in GiB
P3 :: "$PROC_DIR/meminfo"  ==>  /proc/meminfo  :: meminfo fixture with MemTotal 2883584 kB: memory 2.8 GiB
P4 :: "$PROC_DIR/cpuinfo"  ==>  /proc/cpuinfo  :: cpuinfo fixture: cpu model is its model name
P5 :: [ "$cpu_model" != "-" ] || cpu_model=""  ==>  :  :: cpuinfo without a model name and lscpu answering '-': cpu model unknown
P6 :: lscpu 2>/dev/null | sed -n  ==>  true 2>/dev/null | sed -n  :: cpuinfo without a model name: cpu model follows lscpu
P7 :: printf "%.1f GiB", $2 / 1048576  ==>  printf "%.2f GiB", $2 / 1048576  :: memory equals MemTotal of /proc/meminfo in GiB
C1 :: CGROUP_DIR="${AVE_PROBE_CGROUP_DIR:-/sys/fs/cgroup}"  ==>  CGROUP_DIR="/sys/fs/cgroup"  :: cpu.max '200000 100000': cpu quota 2.00 cpus
C2 :: CGROUP_DIR="${AVE_PROBE_CGROUP_DIR:-/sys/fs/cgroup}"  ==>  CGROUP_DIR="${AVE_PROBE_CGROUP_DIR:-/sys/fs/cgroup/unified}"  :: SURVIVED where no quota applies; in a container started with --memory 1g --cpus 2 it fails both host checks (254 pass, 2 fail)
C3 :: elif [ "$quota" = max ]; then⏎    printf 'none'  ==>  elif [ "$quota" = max ]; then⏎    printf 'unlimited'  :: cpu quota agrees with /sys/fs/cgroup/cpu.max of this host
C4 :: [ -e "$CGROUP_DIR/cpu.max" ] || { printf 'none'; return; }  ==>  [ -e "$CGROUP_DIR/cpu.max" ] || { printf 'unknown'; return; }  :: a cgroup directory without the two files: both lines read none
C5 ::   else⏎    printf 'unknown'⏎  fi⏎}⏎memory_limit() {  ==>    else⏎    printf 'none'⏎  fi⏎}⏎memory_limit() {  :: cpu.max 'abc 100000' is no quota form: cpu quota unknown
C6 :: printf "%.2f", q / p }  ==>  printf "%.2f", q / 100000 }  :: cpu.max '50000 200000': the quota is divided by the period, 0.25 cpus
C7 :: || [ -z "${period//0/}" ]; then  ==>  ; then  :: cpu.max '200000 0' is no quota form: cpu quota unknown
C8 :: ! is_number "$period" || [ -z "${period//0/}" ]; then  ==>  [ -z "${period//0/}" ]; then  :: cpu.max '200000 abc' is no quota form: cpu quota unknown
C9 :: if [ "$quota $period" != "$content" ] || ! is_number "$period"  ==>  if ! is_number "$period"  :: cpu.max '200000' is no quota form: cpu quota unknown
C10 :: printf "%.2f", q / p }  ==>  printf "%.1f", q / p }  :: cpu.max '200000 100000': cpu quota 2.00 cpus
C11 :: if [ "$content" = max ]; then⏎    printf 'none'  ==>  if [ "$content" = max ]; then⏎    printf 'unknown'  :: memory limit agrees with /sys/fs/cgroup/memory.max of this host
C12 :: [ -e "$CGROUP_DIR/memory.max" ] || { printf 'none'; return; }  ==>  [ -e "$CGROUP_DIR/memory.max" ] || { printf 'unknown'; return; }  :: a cgroup directory without the two files: both lines read none
C13 ::   else⏎    printf 'unknown'⏎  fi⏎}⏎⏎printf '# Environment probe  ==>    else⏎    printf 'none'⏎  fi⏎}⏎⏎printf '# Environment probe  :: memory.max '' is no limit form: memory limit unknown
C14 :: b / 1073741824  ==>  b / 1000000000  :: memory.max 1073741824: memory limit 1.0 GiB
C15 :: elif is_number "$content"; then  ==>  elif [ -n "$content" ]; then  :: memory.max 'abc' is no limit form: memory limit unknown
C16 :: "" | *[!0123456789]*) return 1 ;;  ==>  "" | [!0123456789]*) return 1 ;;  :: a character device named nvidia0.txt is no GPU node: accelerator: none (no device)
C17 :: "" | *[!0123456789]*) return 1 ;;  ==>  *[!0123456789]*) return 1 ;;  :: offline probe exits 0
C18 :: item "cpu quota (cgroup v2)" "$(cpu_quota)"  ==>  :  :: cpu quota agrees with /sys/fs/cgroup/cpu.max of this host
C19 :: item "memory limit (cgroup v2)" "$(memory_limit)"  ==>  :  :: memory limit agrees with /sys/fs/cgroup/memory.max of this host
C20 :: 2>/dev/null; then content=""; fi  ==>  2>/dev/null; then :; fi  :: cpu.max and memory.max with a NUL byte behind max: both lines read unknown
C21 :: content="${content%$'\n'}"  ==>  content="${content%%$'\n'*}"  :: memory.max 'max|1073741824' is no limit form: memory limit unknown
C22 :: content="${content%$'\n'}"  ==>  :  :: cpu quota agrees with /sys/fs/cgroup/cpu.max of this host
S1 :: if is_number "${AVE_PROBE_SMI_TIMEOUT:-}" && [ -n "${AVE_PROBE_SMI_TIMEOUT//0/}" ]; then  ==>  if [ -n "${AVE_PROBE_SMI_TIMEOUT:-}" ]; then  :: AVE_PROBE_SMI_TIMEOUT='0' is no positive whole number: the limit stays 10 s
S2 :: if is_number "${AVE_PROBE_SMI_TIMEOUT:-}" && [ -n "${AVE_PROBE_SMI_TIMEOUT//0/}" ]; then  ==>  if is_number "${AVE_PROBE_SMI_TIMEOUT:-}"; then  :: AVE_PROBE_SMI_TIMEOUT='0' is no positive whole number: the limit stays 10 s
S3 :: smi_limit="$AVE_PROBE_SMI_TIMEOUT"  ==>  smi_limit=10  :: AVE_PROBE_SMI_TIMEOUT replaces the limit of the query
S4 :: smi_limit=10⏎if is_number  ==>  smi_limit=600⏎if is_number  :: the nvidia-smi query runs under a 10 s limit with a kill after 2 s more
S5 :: timeout -k 2 "$smi_limit" nvidia-smi  ==>  timeout "$smi_limit" nvidia-smi  :: the nvidia-smi query runs under a 10 s limit with a kill after 2 s more
S6 :: if smi="$(smi_query 2>/dev/null)"; then  ==>  if smi="$(smi_query 2>/dev/null)" || true; then  :: nvidia-smi prints a GPU row and fails: accelerator: none (no device)
S7 :: smi="$(smi_query 2>/dev/null)"  ==>  smi="$(smi_query 2>&1)"  :: a GPU row on the error stream alone: accelerator: none (no device)
S8 :: '^.*[^,[:space:]].*,[[:space:]]*[0-9]+ MiB$'  ==>  '^.*,[[:space:]]*[0-9]+ MiB$'  :: nvidia-smi exits 0 with ', 16 MiB' (no name, or text behind the unit): accelerator: none (no device)
S9 :: [0-9]+ MiB$')  ==>  [0-9]+ MiB')  :: nvidia-smi exits 0 with 'Tesla T4, 15360 MiB (shared)' (no name, or text behind the unit): accelerator: none (no device)
S10 :: [0-9]+ MiB$')  ==>  [0-9]+ MiB[[:space:]]*$')  :: nvidia-smi exits 0 with 'Tesla T4, 15360 MiB ' (no name, or text behind the unit): accelerator: none (no device)
S11 :: grep -m1 -E  ==>  grep -E  :: nvidia-smi exits 0 with GPU rows: accelerator: present names the row
S12 :: printf '%s\n' "$smi" | grep -m1 -E  ==>  printf '%s\n' "$smi" | head -n 1 | grep -m1 -E  :: a line that is no row before a GPU row: the row is reported and counts
S13 :: [0-9]+ MiB$')  ==>  [0-9]+ .*$')  :: nvidia-smi exits 0 with 'Tesla T4, 15360 MiB (shared)' (no name, or text behind the unit): accelerator: none (no device)
S14 :: elif ! have timeout; then  ==>  elif false; then  :: nvidia-smi without a timeout command: the query is left out and reports no GPU
S15 :: timeout -k 2 "$smi_limit" nvidia-smi  ==>  nvidia-smi  :: the nvidia-smi query runs under a 10 s limit with a kill after 2 s more
S16 :: --format=csv,noheader  ==>  --format=csv  :: the nvidia-smi query runs under a 10 s limit with a kill after 2 s more
S17 :: item "nvidia-smi" "not installed"  ==>  item "nvidia-smi" "no GPU reported"  :: no device, no nvidia-smi: nvidia-smi not installed
N1 :: set +e +f⏎shopt -u failglob  ==>  set +e⏎shopt -u failglob  :: SHELLOPTS=noglob exported: the walk still lists and counts the nodes
N41 :: set +e +f⏎shopt -u failglob  ==>  set +f⏎shopt -u failglob  :: SHELLOPTS=errexit exported, a cpuinfo without a model name: the report runs to its last section
N2 :: shopt -u failglob⏎  ==>  (nothing)  :: BASHOPTS=failglob exported: an empty device directory prints both list lines and the verdict, and no error of the shell
N3 :: shopt -s dotglob⏎  ==>  (nothing)  :: a hidden entry of dri is listed
N4 :: name="${path##*/}"  ==>  name="${path##*/}"; name="${name%%$'\n'*}"  :: a character device named nvidia0<LF>x is no GPU node: accelerator: none (no device)
N5 :: [ "${name:0:${#2}}" = "$2" ] || continue  ==>  :  :: ordinary /dev entries (null, sda, a directory): accelerator: none (no device)
N6 :: [ "${name:0:${#3}}" = "$3" ] || continue⏎    is_number "${name:${#3}}" || continue  ==>  [[ "$name" =~ $3[0123456789]+$ ]] || continue  :: a character device named dri/card-renderD128 is no GPU node: accelerator: none (no device)
N7 :: scan "$DEV_DIR/dri" "" renderD⏎  ==>  scan "$DEV_DIR/dri" "" nvidia⏎scan "$DEV_DIR/dri" "" renderD⏎  :: a character device named dri/nvidia0 is no GPU node: accelerator: none (no device)
N8 :: scan "$DEV_DIR" nvidia nvidia⏎  ==>  scan "$DEV_DIR" renderD renderD⏎scan "$DEV_DIR" nvidia nvidia⏎  :: a character device named renderD128 is no GPU node: accelerator: none (no device)
N9 :: is_number "${name:${#3}}" || continue  ==>  is_number "${name:${#3}}" || [ -z "${name:${#3}}" ] || continue  :: a character device named nvidia is no GPU node: accelerator: none (no device)
N10 :: is_number "${name:${#3}}" || continue  ==>  is_number "${name:${#3}}" && { [ "$3" = nvidia ] || [ "${#name}" = 10 ]; } || continue  :: the node dri/renderD7 alone: accelerator: present names it
N11 :: is_number "${name:${#3}}" || continue  ==>  case "${name:${#3}}" in [0123456789]) ;; *) continue ;; esac  :: a DRI render node: accelerator: present names it
N12 :: [ -c "$path" ] || continue  ==>  [ -c "$path" ] || [ -f "$path" ] || continue  :: nvidia0 as a regular entry is listed and is no device: accelerator: none (no device)
N13 :: [ -c "$path" ] || continue  ==>  [ -c "$path" ] && [ ! -L "$path" ] || continue  :: device node present: accelerator verdict names it
N14 :: [ -c "$path" ] || continue  ==>  [ -c "$path" ] || [ -b "$path" ] || continue  :: SURVIVED (inspection: mknod b 7 0 reads none)
N15 :: [ -c "$path" ] || continue  ==>  [ -L "$path" ] && [ -c "$path" ] || continue  :: SURVIVED (inspection: mknod c 1 3 reads present)
N16 :: [ -c "$path" ] || continue  ==>  [ -c "$path" ] && { [ ! -L "$path" ] || [ ! -L "$(readlink -- "$path")" ]; } || continue  :: nvidia0 as a link to a link to a character device: accelerator: present names it
N17 :: printf -v quoted '%q' "$path"  ==>  quoted="$path"  :: a character device named nvidia0<LF>x is one word of the one nvidia list line
N18 :: listed="$listed${listed:+ }$quoted"  ==>  listed="$listed$quoted "  :: driver control nodes without a GPU node: the five entries are listed, and accelerator: none (no device)
N19 :: scan "$DEV_DIR/dri" "" renderD⏎item "/dev/dri devices" "${listed:-none}"  ==>  scan "$DEV_DIR/dri" "" renderD⏎listed="$(find "$DEV_DIR/dri" -mindepth 1 -maxdepth 1 2>/dev/null | sort | tr '\n' ' ')"; listed="${listed% }"⏎item "/dev/dri devices" "${listed:-none}"  :: a character device named dri/renderD128<LF>.bak is one word of the one dri list line
N20 :: closed_nodes="$closed_nodes$quoted "  ==>  open_nodes="$open_nodes$quoted "  :: a GPU node that cannot be opened: accelerator: none names the node without access
N21 :: elif [ -n "$closed_nodes" ]; then  ==>  elif false; then  :: a GPU node that cannot be opened: accelerator: none names the node without access
N22 :: opens() { dd if="$1" of="$1" count=0 conv=nocreat,notrunc status=none 2>/dev/null; }  ==>  opens() { [ -r "$1" ] && [ -w "$1" ]; }  :: a GPU node that cannot be opened: accelerator: none names the node without access
N23 :: opens() { dd if="$1" of="$1" count=0 conv=nocreat,notrunc status=none 2>/dev/null; }  ==>  opens() { (exec 3<>"$1") 2>/dev/null; }  :: each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none
N24 :: count=0 conv=nocreat,notrunc status=none  ==>  count=0 conv=notrunc status=none  :: each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none
N25 :: count=0 conv=nocreat,notrunc status=none  ==>  count=0 conv=nocreat status=none  :: each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none
N26 :: dd if="$1" of="$1" count=0  ==>  dd if="$1" of=/dev/null count=0  :: each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none
N27 :: dd if="$1" of="$1" count=0  ==>  dd if=/dev/null of="$1" count=0  :: each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none
N28 :: count=0 conv=nocreat,notrunc status=none  ==>  count=1 conv=nocreat,notrunc status=none  :: each GPU node is opened once as dd if=<node> of=<node> count=0 conv=nocreat,notrunc status=none
N29 :: opens /dev/null || open_test=no  ==>  :  :: the operands are tried on /dev/null once, and no other path is opened (the display node included)
N30 :: untested_nodes="$untested_nodes$quoted "  ==>  closed_nodes="$closed_nodes$quoted "  :: no dd on PATH beside a GPU node: accelerator: unknown names the node the open test is unavailable for
N39 :: printf -v quoted '%q' "$path"  ==>  printf -v quoted '%q' "$name"; quoted="$dir/$quoted"  :: a character device named nvidia0<LF>x is one word of the one nvidia list line
N40 :: open_nodes="$open_nodes$quoted "  ==>  open_nodes="$open_nodes$path "  :: a device directory named 'dev spaced': the list line and the verdict name its node as one word
N31 :: if [ -n "$evidence" ]; then  ==>  if [ -n "$evidence" ] && [ -z "$untested_nodes" ]; then  :: no dd on PATH, a GPU node and a GPU row of nvidia-smi: accelerator: present names the row alone
N32 :: scan "$DEV_DIR/dri" "" renderD⏎  ==>  scan "$DEV_DIR/dri" "" card⏎scan "$DEV_DIR/dri" "" renderD⏎  :: a GPU node and a render node: accelerator: present names both and leaves the display node out
N33 :: is_number "${name:${#3}}" || continue  ==>  :  :: driver control nodes without a GPU node: the five entries are listed, and accelerator: none (no device)
N34 :: [ -e "$path" ] || [ -L "$path" ] || continue  ==>  :  :: ordinary /dev entries (null, sda, a directory): accelerator: none (no device)
N35 :: [ -e "$path" ] || [ -L "$path" ] || continue  ==>  [ -e "$path" ] || continue  :: nvidia0 as a dangling entry is listed and is no device: accelerator: none (no device)
N36 :: "${gpu:+$gpu }$open_nodes"  ==>  "$open_nodes"  :: nvidia-smi exits 0 with GPU rows: accelerator: present names the row
N37 :: opens() { dd if="$1" of="$1" count=0 conv=nocreat,notrunc status=none 2>/dev/null; }  ==>  opens() { dd if="$1" of="$1" count=0 conv=nocreat,notrunc status=none 2>/dev/null && : > "$1.opened"; }  :: dri as a link to a directory: the list line and the verdict name the same render node (run to its end: also no probe run changed its device directory)
N38 :: [ "${name:0:${#2}}" = "$2" ] || continue  ==>  case "$name" in *"$2"*) ;; *) continue ;; esac  :: xnvidia0 stands on no list line
T1 :: else item "$1" "not installed"; fi; }  ==>  else item "$1" "missing"; fi; }  :: claude absent from PATH: not installed
T2 :: first() { "$@" 2>/dev/null | head -n 1; }  ==>  first() { "$@" 2>/dev/null; }  :: ffmpeg equals the first line of 'ffmpeg -hide_banner -version'
T3 :: version ffmpeg -hide_banner -version  ==>  item ffmpeg "ffmpeg version 6.1.1-3ubuntu5 Copyright (c) 2000-2023 the FFmpeg developers"  :: ffmpeg hidden from PATH: not installed
T4 :: version python3 --version  ==>  item python3 "Python 3.12.3"  :: python3 hidden from PATH: not installed
T5 :: "${PLAYWRIGHT_BROWSERS_PATH:-unset}"  ==>  "unset"  :: PLAYWRIGHT_BROWSERS_PATH set: reported with its directory
T6 :: [ -d "${PLAYWRIGHT_BROWSERS_PATH:-/nonexistent}" ] &&  ==>  false &&  :: playwright browsers lists the entries of PLAYWRIGHT_BROWSERS_PATH
T7 :: for browser in chromium chromium-browser google-chrome; do  ==>  for browser in chromium google-chrome; do  :: fake chromium-browser on PATH: reported with the first line of its --version
T8 :: version claude --version  ==>  item claude "not installed"  :: claude on PATH: its version is reported
T9 :: id -un 2>/dev/null || echo unknown  ==>  whoami 2>/dev/null || echo unknown  :: fake id answers probeuser and 4242: os user probeuser (uid 4242)
T10 :: (uid $(id -u 2>/dev/null || echo unknown))  ==>  (uid 0)  :: fake id answers probeuser and 4242: os user probeuser (uid 4242)
T11 :: item "$name" "set"; else  ==>  item "$name" "set ${!name}"; else  :: a set credential is reported as set
T12 :: for name in ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL HF_TOKEN; do  ==>  for name in ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL; do  :: a set credential is reported as set
T13 :: if [ -n "${!name:-}" ]; then  ==>  if [ -n "${!name+x}" ]; then  :: an empty credential is reported as unset
T14 :: section "Git"  ==>  section "Repository"  :: reports section: Git
T15 :: version uv --version  ==>  :  :: uv equals the first line of 'uv --version'
T16 :: version git --version  ==>  item git "$(git --version 2>/dev/null | head -n 1)"  :: git hidden from PATH: not installed
T17 :: version node --version  ==>  item node "$(node --version 2>/dev/null | head -n 1)"  :: node hidden from PATH: not installed
T19 :: for name in ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL HF_TOKEN; do  ==>  for name in ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL HF_TOKEN GITHUB_TOKEN; do  :: every reported credential variable is listed in .env.example (missing: GITHUB_TOKEN)
T20 :: if [ -n "${!name:-}" ]; then  ==>  if false; then  :: a set credential is reported as set
T18 :: "$(git -C "$ROOT" worktree list 2>/dev/null | wc -l | tr -d ' ') listed"  ==>  "1 listed"  :: git fixture: worktrees equals git worktree list | wc -l
O1 :: if [ "$OFFLINE" -eq 1 ]; then  ==>  if false; then  :: network probes skipped offline
O2 :: item "probes" "curl not installed"  ==>  item "probes" "skipped"  :: curl absent: network probes report curl not installed
O3 :: curl -sS -o /dev/null -I -m 10  ==>  curl -sS -o /dev/null -m 10  :: network-1: every request fetches no body (-I/--head, a bounded -r/--range or --max-filesize)
O4 :: -I -m 10 -w  ==>  -I -m 30 -w  :: network-1: every request has a time limit of at most 10 s (-m/--max-time)
O5 :: [1-9][0-9][0-9]) item  ==>  2[0-9][0-9]) item  :: network-1: registry.npmjs.org/ reads 'HTTP 301' on one line (fake curl: 301)
O6 :: [1-9][0-9][0-9]) item  ==>  [1-4][0-9][0-9]) item  :: network-2: files.pythonhosted.org/ reads 'HTTP 503' on one line (fake curl: 503)
O7 :: https://api.openai.com/; do  ==>  https://api.openai.com/ https://example.com/; do  :: network-1: only the seven hosts are requested
O8 :: https://files.pythonhosted.org/ https://registry.npmjs.org/   ==>  https://files.pythonhosted.org/   :: network-1: registry.npmjs.org/ reads 'HTTP 301' on one line (fake curl: 301)
O9 :: 'https://huggingface.co/api/models?limit=1'  ==>  https://huggingface.co/api/models?limit=1  :: BASHOPTS=nullglob exported: huggingface.co/api/models?limit=1 is requested and reported, seven requests in all
O10 :: *) item "${url#https://}" "unreachable" ;;  ==>  *) case "$url" in *github.com*|*huggingface.co*) item "${url#https://}" "HTTP 000" ;; *) item "${url#https://}" "unreachable" ;; esac ;;  :: network-2: github.com/ reads 'unreachable' on one line (fake curl: fail:35)
O11 :: -w '%{http_code}' "$url"  ==>  -w '%{http_code}' -H "Authorization: Bearer ${HF_TOKEN:-}" "$url"  :: network-1: no credential value reaches curl
O12 :: -I -m 10 -w  ==>  -I -w  :: network-1: every request has a time limit of at most 10 s (-m/--max-time)
O13 :: *) item "${url#https://}" "unreachable" ;;  ==>  *) item "${url#https://}" "HTTP $code" ;;  :: network-1: files.pythonhosted.org/ reads 'unreachable' on one line (fake curl: fail:28)
O14 :: [1-9][0-9][0-9]) item  ==>  [1245][0-9][0-9]) item  :: network-1: registry.npmjs.org/ reads 'HTTP 301' on one line (fake curl: 301)
```

### Statement audit

Line numbers are those of the requirement file at commit `61b5ae4`. Results: (a) a named case fails under a mutant I ran; (b) case added, then as (a); (c) sentence reworded to the behavior that holds; (d) worded as a limit with its inspection.

| Line | Sentence (shortened) | Result | Case or mutant |
|---|---|---|---|
| 35–38 | fallback without workflow tool or subagents | states a procedure of `CLAUDE.md` § Delegation; no script, check or suite | unchanged |
| 39–42 | a changed capability is re-probed; step 6 runs `--offline`, a full run re-measures the network lines | (c), closes part 2 non-blocking 3 on the requirement side | `.claude/skills/resume-project/SKILL.md` line 32; header of `docs/ENVIRONMENT_CAPABILITIES.md`; O1 |
| 43 | workflow syntax never assumed | process rule (AC-3 inspection); no script | unchanged |
| 44–46 | `none (no device)` when no character device with a GPU node's name and no GPU row | (c) wording of non-blocking 5, (a) | N9, N12, N33 |
| 47–49 | one walk gives both list lines and the verdict; a name is one string | (b) | N19, N4, N17 |
| 49–51 | GPU node: character device, directly or behind links, whole name, digits; counts when it opens for reading and writing | (a), (b); "directly" and one-sided access (d) | N13, N16, N6, N9, N10, N11, C16, N22, N26, N27; inspection `mknod c 1 3`, modes 0444 and 0222 (N15 survives the suite) |
| 51–55 | every other entry counts for nothing (list of forms) | (a), (b); block device (d) | N33, N32, N12, N6, N4, N7, N8, the kind cases; inspection `mknod b 7 0` (N14 survives the suite) |
| 55–58 | list lines: entries named `nvidia*`, entries of `dri`, hidden and linked ones, one word in `printf %q` form, no other entry | (b) | N5, N38, N35, N3, N19, N17, N18, N39, N40 |
| 58–59 | a missing or unlistable device directory reads as empty | (b) missing; (d) unlistable | `a missing device directory: ...`; inspection mode 0711 |
| 60–61 | no access verdict; the open node named alone | (a) | N20, N21 |
| 61–63 | one `dd` call, creates and truncates nothing, transfers nothing, directory unchanged | (b) | N23, N24, N25, N28, N37 |
| 63–65 | without such a `dd`: no node opened, `accelerator: unknown`, unless a GPU row | (b) | N29, N30, N31, `a dd that knows no conv=nocreat: after the trial ...` |
| 66–70 | `nvidia-smi` counts with exit 0, within the limit, row form on standard output | (a), (b) | S6, S15, S5, S7, S8, S9, S10, S13 |
| 70–72 | diagnostics and malformed rows leave the verdict to the nodes | (a), (b) | S6, S7, S8, S9, S12, `nvidia-smi fails while a device node exists: ...` |
| 72–73 | without `timeout` the query is left out | (a) | S14 |
| 73–74 | `AVE_PROBE_SMI_TIMEOUT` only as a positive whole number; any other value leaves 10 s | (b) | S1, S2, S3 |
| 74–76 | the limit covers `nvidia-smi` and its process group | (d) | by-hand rows with `setsid sleep 8` and with the ignored signal |
| 77–80 | `present` means a node opens or a GPU row; nothing is sent | (a); the software-driver sentence is a stated limit | N28; `device node present: accelerator verdict names it` (a link to `/dev/null` reads present) |
| 81–87 | two cgroup lines, forms of the two files, `none`, `unknown` | (b); default directory (d) | C1, C3–C22; C2 in the quota container |
| 87–89 | the two lines read these two files alone | (d) | `docker run --cgroupns=host --memory 1g --cpus 2`: both lines `none` |
| 90–93 | fixture inputs show computed lines | (a), (b) | P1, P3, P4, C1, T9, T10, R8 |
| 94–95 | no `claude` reads `not installed` | (a); the host half is a procedure | T1, T8 |
| 96–97 | deny rule recorded after a refused command | process statement; no script | unchanged |
| 98–99 | eight tools read `not installed` when absent | (b) for `node`, `pnpm`, `docker` | T1, T16, T17 |
| 100–101 | start outside the repository or relative with `CDPATH` | (a), (b) | R1, R4, R5, R6, R8 |
| 102–105 | status classes read `HTTP <code>`, no response reads `unreachable`, header-only, no `curl`, `--offline` | (c) "any status" became the named classes; (a) | O3, O5, O6, O14, O13, O4, O12, O1, O2 |
| 111 | CPUs, memory, disk | (a) | P1, P2, P7, R4 |
| 111 | cgroup clause (figures, `none`, thirteen and eight other contents, line end, NUL, directories) | (b); counts equal `CPU_OTHER` (13) and `MEMORY_OTHER` (8) | C1–C22 |
| 111 | version lines, fakes, eight hidden tools | (a), (b) | T1, T2, T3, T4, T15, T16, T17 |
| 111 | Playwright, browsers | (a) | T5, T6, T7 |
| 111 | worktrees and branch, fixture repository | (a) | R5, R6, T18 |
| 111 | `CDPATH` and `-dash` | (b) | R1, R2, R3 |
| 111 | `dev_run` lists the directory before and after | (b), (c) worded to the helper | N37 |
| 111 | verdict lists (none, present), closed node | (a), (b) | N4–N16, N20–N22, N32–N36 |
| 111 | fake `dd`, hidden `dd`, refusing `dd` | (b) | N23–N31 |
| 111 | `SHELLOPTS=noglob`, `BASHOPTS=failglob`, `SHELLOPTS=errexit` | (b) | N1, N2, N41 |
| 111 | `nvidia-smi` answers, fake `timeout`, 3 accepted and 13 other values | (a), (b) | S1–S17 |
| 111 | whole list lines; `nvidia-smi` line in the fake scenarios; headings once | (b), (c) | N5, N17, N18, N19, N35, N38, N39, N40, S17, T14 |
| 111 | fixture inputs, `lscpu` | (a) | P1, P3, P4, P5, P6, T9, T10, R7, R8 |
| 111 | Claude Code version, credentials | (a) | T8, T11, T12, T13, T19, T20 |
| 111 | network: seven hosts in both states, codes 200, 301, 405, 429, 404, 503, 421, no body, time limit, no credential, `nullglob` | (b), (a) | O1–O14 (O10 is the reviewer's O17) |
| 111 | `--help`, unknown option | (b) | R9, R10, R11 |
| 111 | lines the suite leaves uncompared | (c) the `not installed` form of node, pnpm, docker is now compared | live run |
| 111 | inspection clause | (d) | by-hand table, quota containers |
| 111 | live run and Claude Code rows | session observations; "the probe reports only browser binaries and the Playwright directory" (a) | T5, T6, T7; live run below |
| 112–115 | AC-2, AC-3, AC-4, scenarios | no script, check or suite; names checked: commits `486b3a0`, `24499a6` exist, the three run scripts stand in `docs/workflows/`, handback parts 1–6 and WF-002 exist | unchanged |
| 118 | `docs/ENVIRONMENT_CAPABILITIES.md` rows | names equal the tree (rows Permissions, Browser tools, Models; § Network policy; § External gaps) | unchanged |
| 119 | probe line | (c) rewritten to the probe as it stands | as above |
| 120 | inspection line | (d), new | by-hand table |
| 121 | resume step 6 | (c) "runs the probe with `--offline`" | `SKILL.md` line 32 |
| 122–124 | workflow log, fallback documents, Tests | names equal the tree | unchanged |
| 125 | Decisions | ASM-015 added (the assumption on the accelerator rule) | — |

### Commands and results
- `git rev-parse HEAD` in the worktree before the first change — `07eceb1aa1693df708c240642f837d8838be175a`.
- `./scripts/dev-container.sh bash scripts/tests/test-probe-environment.sh` at the base — `PROBE TOTAL: pass=155 fail=0`.
- The same command on the final tree, three runs in a row — exit 0 each, `PROBE TOTAL: pass=256 fail=0`, 256 `ok` lines and 0 `FAIL` lines each; the three logs are equal after replacing the temp directory name and the disk figures (one checksum). Duration 51 s to 66 s without other load, 109 s to 129 s beside the other writer's runs (26 s at the base).
- `./scripts/dev-container.sh ./scripts/probe-environment.sh` (live, 2 s, 2026-10-07T04:49:26Z) — exit 0: cpus 8, `cpu quota (cgroup v2) none`, cpu model unknown, memory 7.5 GiB, `memory limit (cgroup v2) none`, disk 16G free of 237G, nvidia-smi not installed, both device lists none, `accelerator: none (no device)`, ffmpeg and ffprobe 6.1.1-3ubuntu5, Python 3.12.3, uv 0.8.17, node v18.19.1, pnpm and docker not installed, git 2.55.0, worktrees 7 listed, branch m0-r2-fixes-c, claude not installed, os user root (uid 0), repository writable yes, four credential variables unset; Network: pypi.org/simple/ HTTP 200, files.pythonhosted.org/ HTTP 404, registry.npmjs.org/ HTTP 200, github.com/ HTTP 200, huggingface.co/api/models?limit=1 HTTP 200, api.anthropic.com/ HTTP 404, api.openai.com/ HTTP 421 (equal to the § Network policy rows).
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py` — `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`. `./scripts/dev-container.sh ./scripts/check-project-control.sh` — `OK: ... 134 requirement files ...; 0 warning(s)`.
- `docker run --rm --memory 1g --cpus 2` with the image of the development container, the checkout mounted read-only — the probe prints `cpus 8`, `cpu quota (cgroup v2) 2.00 cpus (cpu.max 200000 100000)`, `memory 7.5 GiB`, `memory limit (cgroup v2) 1.0 GiB (memory.max 1073741824)`; the suite there: `PROBE TOTAL: pass=256 fail=0`; mutant C2 there: `pass=254 fail=2` (the two host checks).
- The same with `--cgroupns=host` — `/proc/self/cgroup` reads `0::/docker/<id>`, `/sys/fs/cgroup/cpu.max` is absent, the files of `/sys/fs/cgroup/docker/<id>` hold `200000 100000` and `1073741824`, and the probe prints `none` on both lines.
- Mutation harness, three parallel runs — 132 mutants of the final probe, 129 killed, 3 survive the suite (list above); three mutants of the base probe (the reviewer's N3, N10, N17) each fail the named new cases.
- `git add -A`, then `./scripts/verify.sh --tier release` on that tree — `verify.sh: PASS — tier release (13 of 13 steps passed)`: project control files, no ignored file, baseline integrity, evidence tooling unit tests, backend format, lint, type check, unit tests, media and population tests (84 passed, 518 s), tooling suites (checker 1090, check-baseline 305, stop-hook 145, session-start 56, verify-tiers 65, probe 256 checks), done requirements evidenced, working tree unchanged, evidence manifest `var/verify/runs/20261007T044950Z-2068662/manifest.json` (58 criteria tagged).
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-094 --require-fresh --tier release` — tier release, PASS, FRESH; AC-1 passed (1 result: `scripts/tests/test-probe-environment.sh`); AC-2, AC-3, AC-4 missing (inspection criteria).
- `git status --short` and `git diff --cached` before the commit — three staged files, modes `100755` for both scripts, LF line ends, `git diff --cached --check` silent; after the commit the tree is clean.

### Forced edits
None.

### Proposed text for documents outside the track's paths (shared-document updates for the lead)

- `docs/ASSUMPTIONS.md`, ASM-015, Assumption — old: "`scripts/probe-environment.sh` reports an accelerator as present from a character device under `/dev` whose whole name is `nvidia<N>` or `dri/renderD<N>` and that this user can open, and from a GPU row with a memory figure that `nvidia-smi` prints; FFmpeg's built-in hardware encoders and every other entry of `/dev` never count." — new: "`scripts/probe-environment.sh` reports an accelerator as present from a character device under `/dev` whose whole name is `nvidia<N>` or `dri/renderD<N>` and that this user can open for reading and for writing, and from a GPU row with a name and a memory figure that `nvidia-smi` prints; FFmpeg's built-in hardware encoders and every other entry of `/dev` never count. The open runs through GNU `dd` with `count=0 conv=nocreat,notrunc` and creates nothing; where `dd` lacks these operands a GPU node reads `accelerator: unknown (open test unavailable for <node>)`."
- `docs/ASSUMPTIONS.md`, ASM-015, Status — old: "open — 2026-10-06 — narrowed to GPU nodes and rows with a memory figure after the review of AVE-REQ-094 at `eb73896` (handback part 5), and to character devices with the whole name that open after the review at `d4147d8` (handback part 6)" — new: the same text followed by "; 2026-10-07 — names judged as one string, an open that creates nothing and a third verdict `unknown` after the review at `f996c17` (second final review, handback part 2)".
- `docs/ASSUMPTIONS.md` — new entry: The probe reads the cgroup limits at the root of the cgroup mount — assumption: the lines `cpu quota (cgroup v2)` and `memory limit (cgroup v2)` read `cpu.max` and `memory.max` of `/sys/fs/cgroup` — reason: decision of the fix brief (track C item 4); a container with a cgroup namespace of its own (the development container, Docker's default on cgroup v2) shows its limits there — impact: a container that shares the host's cgroup namespace, a limit of a parent cgroup and cgroup v1 read `none` (observed with `--cgroupns=host`).
- `docs/ASSUMPTIONS.md` — new entry: The probe's device lines and verdict print paths in the shell's quoted form — assumption: `printf %q`, entries separated by one space, no space behind the last — reason: a name with a line feed or a space stays one word of one line — impact: ordinary paths print unchanged; the base printed a space behind the last entry.
- `docs/ENVIRONMENT_CAPABILITIES.md`, header — old: "re-measures the shell-observable part (resources, accelerators with a device verdict, media tools, toolchains," — new: "re-measures the shell-observable part (resources with the cgroup v2 limits, accelerators with a device verdict, media tools, toolchains,".
- `docs/ENVIRONMENT_CAPABILITIES.md`, row Container CPU / memory — old: "8 CPUs, 7.5 GiB plus 2 GiB swap; no cgroup limit (`memory.max` reads `max`), so" — new: "8 CPUs, 7.5 GiB plus 2 GiB swap; no cgroup limit (probe `cpu quota (cgroup v2) none` and `memory limit (cgroup v2) none` on 2026-10-07: `cpu.max` reads `max 100000`, `memory.max` reads `max`), so".
- `docs/ENVIRONMENT_CAPABILITIES.md`, row GPU — old: "The verdict counts a character device named `/dev/nvidia<N>` or `/dev/dri/renderD<N>` that this user can open, and a `nvidia-smi` GPU row with a memory figure; a node without access reads `none (no access to …)`." — new: "The verdict counts a character device named `/dev/nvidia<N>` or `/dev/dri/renderD<N>` that this user can open for reading and for writing, and a `nvidia-smi` GPU row with a name and a memory figure; a node without access reads `none (no access to …)`, and where `dd` cannot open without creating a node reads `unknown (open test unavailable for …)`."
- `.claude/skills/resume-project/SKILL.md`, step 6 — old: "(Claude Code version, CPUs, memory, accelerator verdict, tool versions, OS user, writability, credential variables set)" — new: "(Claude Code version, CPUs, memory, the two cgroup limit lines, accelerator verdict, tool versions, OS user, writability, credential variables set)"; and behind the sentence that ends "(`docs: re-measure the environment`)." the added sentence "When the host or its network changed since the last session, run the probe once more without `--offline` and compare its Network lines with § Network policy." (part 2 non-blocking 3).
- `docs/TRACEABILITY.md`, AVE-REQ-094 row — Implementation and Tests cells stay as they are (same files); the status follows the lead's transition.
- `docs/requirements/AVE-REQ-094-...md`, Status log (lead-owned) — the next line can cite branch `m0-r2-fixes-c`, commit `61b5ae4`, 256 checks and 129 of 132 mutants failing the suite, with the three inspection-covered ones named above.
- `scripts/tests/run.sh`, header comment (outside every track's list) — "measured resources" can read "measured resources and cgroup limits".

### Deviations, open issues, discovered work
- Precondition: the dependency AVE-REQ-093 stood `in-progress` at the base commit, while the skill expects every dependency `done`. The brief schedules tracks A and C in parallel and the probe work is independent of track A, so the work proceeded; the order of the two transitions is the lead's (part 2 non-blocking 8).
- Item 4, scope of "its cgroup": the lines read the mount root, as the brief's decision words it. In a container with `--cgroupns=host` a real quota reads `none` (run above). Proposed follow-up, parent AVE-FEAT-019: resolve the path behind `0::` of `/proc/self/cgroup` and take the lowest limit along its parents. Recommendation: keep the stated limit for M0.
- New output forms, each a proposed assumption above: the verdict `accelerator: unknown (open test unavailable for <node>)`; two more lines in the first section; list lines without a trailing space and with `printf %q` paths.
- Rules outside the six items, each with a case and a mutant: `set +e` (the base probe and an exported `SHELLOPTS=errexit` ended the report after its first section on this arm64 host), `set +f`, `shopt -u failglob`, `shopt -s dotglob`, the quoted URL. Open and unguarded: `BASH_ENV`, exported shell functions and `SHELLOPTS=noexec` change any Bash script before its first line; the requirement file claims nothing about them.
- Locale: the order of the list lines follows the shell's collation of pathname expansion. The whole-line check of the five driver control entries expects byte order, as its predecessor expected `nvidiactl` last; the development container and CI use the C locale family.
- Suite duration grew from 26 s to about one minute (256 checks); the cgroup and time-limit cases run without the media tools to keep it there.
- Incident in the shared container: at about 03:59 UTC on 2026-10-07 I stopped my own mutation harness with `pkill -f "mut[.]py"`. The pattern also matches a harness of the same file name that track B2 runs in that container (seen at 04:08 UTC). A B2 mutation run that ended without a result near 03:59 UTC has this cause; my later stops used the working directory under my own `/tmp` directory. Proposed workflow-log entry: in a container that several writers share, a process is stopped by its PID or its working directory.
- The handback of part 6 cited 38 mutants without a list; this handback holds its list in full, with the replacement text of each mutant.
- Part 2 non-blocking 5 is closed by the wording of lines 44–65; non-blocking 7 (the Status line cites the 2b brief) and 8 are the lead's.
- The track's helper scripts and mutation copies lived in the container's `/tmp` and the session scratchpad; the container copies are removed, and the tree holds the three committed files only.
