#!/usr/bin/env bash
# scripts/tests/test-probe-environment.sh — tests of scripts/probe-environment.sh. Every AC-1 line is
# compared with a value this suite measures itself in the same run: CPUs, memory (MemTotal of
# /proc/meminfo in GiB) and disk (`df -h "$REPO"`); the two cgroup lines (this host's files, and
# fixture directories given through AVE_PROBE_CGROUP_DIR); the accelerator verdict from device
# nodes alone; the ffmpeg, ffprobe, python3, uv and git versions (`not installed` when hidden from
# PATH, a fake's version when a fake comes first); Playwright's browser directory and the browser
# binaries; the Git worktree count and branch (of the repository and of a fixture repository with
# three worktrees); the Claude Code version, OS user and repository writability; credential
# variables by name only; and the Network section, driven by a fake curl that answers from a
# script, records every request and flags a request that downloads a body without a bound. Device
# nodes come from temp directories (AVE_PROBE_DEV_DIR), which the cases of the device walk list
# before and after their run, and the other external commands the cases vary are hidden or faked
# through PATH, so no host is contacted. A fake nvidia-smi drives the accelerator verdict (a diagnostic, a failure or an empty
# answer is no device; a GPU row is one), a fake dd shows how a node is opened, and fixture inputs
# that differ from this host (a fake getconf and id, AVE_PROBE_PROC_DIR, AVE_PROBE_ROOT) prove that
# the CPU, memory, CPU model, OS user and writability lines are computed.
# Exit 0 when every check passes.
# A probe run starts in the temp directory, outside the repository it measures; the one case that
# exports CDPATH starts its fixture's probe through a relative path inside the fixture.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$W/../.." && pwd)"
PROBE="$W/../probe-environment.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/probe-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
has() { printf '%s\n' "$OUT" | quiet -E -- "$1"; }
# line <label> <value> — one report line laid out as the probe prints it (`%-28s %s`).
line() { printf '%-28s %s' "$1" "$2"; }
# has_line <label> <value> — $OUT holds exactly that line.
has_line() { printf '%s\n' "$OUT" | quiet -xF -- "$(line "$1" "$2")"; }
# lines_of <label> — how many lines of $OUT start with the label and a space.
lines_of() { printf '%s\n' "$OUT" | awk -v p="$1 " 'index($0, p) == 1 { n++ } END { print n + 0 }'; }
# pw_entries — the entries of the `playwright browsers` lines of $OUT, sorted, space-separated.
pw_entries() {
  printf '%s\n' "$OUT" | awk 'index($0, "playwright browsers ") == 1 { sub(/^playwright browsers +/, ""); print }' |
    tr -s ' ' '\n' | sed '/^$/d' | sort | tr '\n' ' '
}

# path_without <command>... — prints PATH with the named commands hidden: a directory that holds
# one of them is replaced by a fresh mirror of its other entries.
path_without() {
  local dir cmd hide mirror out=""
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    hide=0
    for cmd in "$@"; do [ -e "$dir/$cmd" ] && hide=1; done
    if [ "$hide" -eq 1 ]; then
      mirror="$(mktemp -d "$T/path-mirror.XXXXXX")" || return 1
      ln -s "$dir"/* "$mirror/" 2>/dev/null
      for cmd in "$@"; do rm -f "${mirror:?}/${cmd:?}"; done
      dir="$mirror"
    fi
    out="${out:+$out:}$dir"
  done
  printf '%s\n' "$out"
}
# first_line <path> <command>... — the first output line of the command found through <path>, or
# "not installed" when <path> holds no such command.
first_line() {
  local p="$1"; shift
  (PATH="$p"; if command -v "$1" >/dev/null 2>&1; then "$@" 2>/dev/null | head -n 1; else printf 'not installed'; fi)
}
# second_line <path> <command>... — the second output line of the command found through <path>.
second_line() { local p="$1"; shift; (PATH="$p"; "$@" 2>/dev/null | sed -n 2p); }
# no_line <text> — $OUT holds no line equal to <text> (always true for an empty text).
no_line() { [ -z "$1" ] || ! printf '%s\n' "$OUT" | quiet -xF -- "$1"; }
# disk_free <dir> — "<Avail> free of <Size>" from the second line of `df -h <dir>`, read by this suite.
disk_free() { df -h "$1" 2>/dev/null | { read -r _ && read -r _ size _ avail _ && printf '%s free of %s' "$avail" "$size"; }; }
# snapshot <dir> — every entry below the directory with its kind, size, modification time and link
# target: equal before and after a run that created, removed and changed nothing there.
snapshot() { ls -laR --time-style=full-iso "$1" 2>&1; }
# host_cgroup <label> <file> — the line of $OUT agrees with that file of this host's /sys/fs/cgroup,
# read by this suite: `none` without the file and for the value max, else a line that ends with the
# file's name and content in parentheses.
host_cgroup() {
  local file="/sys/fs/cgroup/$2" content
  [ -e "$file" ] || { has_line "$1" none; return; }
  content="$(cat "$file" 2>/dev/null)"
  case "$content" in
    max | "max "*) has_line "$1" none ;;
    *) printf '%s\n' "$OUT" | awk -v p="$1 " -v s="($2 $content)" \
         'index($0, p) == 1 && substr($0, length($0) - length(s) + 1) == s { n++ } END { exit !(n == 1) }' ;;
  esac
}

# make_fake_curl <dir> <script line>... — writes <dir>/bin/curl, a fake curl that answers each URL
# from the script lines ("<URL without scheme> <HTTP code> [<body bytes>]" or "<URL without scheme>
# fail:<curl exit code>"), records every invocation in <dir>/calls (raw arguments, then one CALL line
# per URL with the request form and time limit) and, in <dir>/violations, every request that would
# download a body without a bound (a GET without -I/--head, a bounded -r/--range or --max-filesize).
make_fake_curl() {
  local dir="$1"; shift
  mkdir -p "$dir/bin" || return 1
  : > "$dir/calls"; : > "$dir/violations"
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@"; fi > "$dir/script"
  { printf '#!/usr/bin/env bash\nNET=%q\n' "$dir"; cat <<'FAKE'
# Fake curl of scripts/tests/test-probe-environment.sh. Emulates -I/--head, -r/--range,
# --max-filesize (exit 63 before a larger body, the response code known), -f/--fail (exit 22 on a
# code >= 400), -i, -o, -D and -w (%{http_code}, %{response_code}, %{exitcode}, %{url_effective});
# a scripted failure exits with its code and writes http_code 000, as curl does.
set -u
ALL=("$@")
{ printf 'ARGS'; printf ' %q' "$@"; printf '\n'; } >> "$NET/calls"
head=0 fail=0 include=0 range="" maxfs="" maxtime="" out="" wout="" dump="" method=""
urls=()
while [ "$#" -gt 0 ]; do
  arg="$1"; shift
  case "$arg" in
    --head) head=1 ;;
    --fail | --fail-with-body) fail=1 ;;
    --include) include=1 ;;
    --range) range="${1-}"; shift ;;
    --max-filesize) maxfs="${1-}"; shift ;;
    --max-time) maxtime="${1-}"; shift ;;
    --output) out="${1-}"; shift ;;
    --write-out) wout="${1-}"; shift ;;
    --dump-header) dump="${1-}"; shift ;;
    --request) method="${1-}"; shift ;;
    --url) urls+=("${1-}"); shift ;;
    --connect-timeout | --header | --user-agent | --user | --referer | --retry | --retry-delay) shift ;;
    --retry-max-time | --proxy | --noproxy | --resolve | --connect-to | --cacert | --capath) shift ;;
    --interface | --max-redirs | --limit-rate | --speed-limit | --speed-time | --proto) shift ;;
    --proto-redir | --oauth2-bearer | --data | --data-raw | --data-binary | --data-urlencode) shift ;;
    --form | --cookie | --cookie-jar | --config | --stderr | --trace | --trace-ascii) shift ;;
    --keepalive-time | --expect100-timeout | --output-dir) shift ;;
    --*) ;;
    -?*)
      opts="${arg#-}"
      while [ -n "$opts" ]; do
        c="${opts:0:1}"; opts="${opts:1}"
        case "$c" in
          [owmrXDHAeuxdFTKCEbcUYyztQ])
            if [ -n "$opts" ]; then val="$opts"; opts=""; else val="${1-}"; shift; fi
            case "$c" in
              o) out="$val" ;; w) wout="$val" ;; m) maxtime="$val" ;; r) range="$val" ;;
              X) method="$val" ;; D) dump="$val" ;;
            esac ;;
          I) head=1 ;;
          f) fail=1 ;;
          i) include=1 ;;
        esac
      done ;;
    *) urls+=("$arg") ;;
  esac
done
bounded_range() {
  local part
  [ -n "$1" ] || return 1
  local IFS=,
  for part in $1; do [[ "$part" =~ ^[0-9]*-[0-9]+$ ]] || return 1; done
}
to_bytes() {
  local n="${1%[kKmMgG]}"
  [[ "$n" =~ ^[0-9]+$ ]] || { echo 0; return; }
  case "$1" in
    *[kK]) echo $((n * 1024)) ;; *[mM]) echo $((n * 1048576)) ;; *[gG]) echo $((n * 1073741824)) ;;
    *) echo "$n" ;;
  esac
}
emit() {
  case "$1" in
    "" | -) printf '%s' "$2" ;;
    /dev/null) ;;
    *) printf '%s' "$2" > "$1" ;;
  esac
}
render() {
  local w="$wout" p
  p='%{http_code}'; w="${w//"$p"/$1}"
  p='%{response_code}'; w="${w//"$p"/$1}"
  p='%{exitcode}'; w="${w//"$p"/$2}"
  p='%{url_effective}'; w="${w//"$p"/$3}"
  printf '%b' "$w"
}
# -X HEAD sends HEAD but leaves curl waiting for a body: only -I/--head is header-only.
form=unbounded
if [ "$head" = 1 ]; then form=head
elif bounded_range "$range"; then form=range
elif [ -n "$maxfs" ]; then form=max-filesize
fi
[ "${#urls[@]}" -gt 0 ] || { printf 'curl: no URL specified\n' >&2; exit 2; }
rc=0
for url in "${urls[@]}"; do
  key="${url#http://}"; key="${key#https://}"
  printf 'CALL url=%s form=%s maxtime=%s method=%s\n' "$key" "$form" "${maxtime:-none}" "${method:-default}" >> "$NET/calls"
  if [ "$form" = unbounded ]; then
    { printf 'VIOLATION %s: the request downloads the body without a bound:' "$key"; printf ' %q' "${ALL[@]}"; printf '\n'; } >> "$NET/violations"
  fi
  rec="$(awk -v k="$key" '$1 == k { print $2, ($3 == "" ? 512 : $3); exit }' "$NET/script")"
  code=000 err=0 size=512
  if [ -z "$rec" ]; then
    printf 'UNEXPECTED %s\n' "$key" >> "$NET/calls"; err=6
  else
    result="${rec%% *}"; size="${rec#* }"
    case "$result" in fail:*) err="${result#fail:}" ;; *) code="$result" ;; esac
  fi
  if [ "$err" = 0 ] && [ "$head" = 0 ] && [ -n "$maxfs" ] && [ "$size" -gt "$(to_bytes "$maxfs")" ]; then
    err=63
  elif [ "$err" = 0 ] && [ "$fail" = 1 ] && [ "$code" -ge 400 ]; then
    err=22
  fi
  if [ "$err" = 0 ]; then
    printf -v headers 'HTTP/2 %s \r\ncontent-length: %s\r\n\r\n' "$code" "$size"
    body="fake body of $key"
    [ "$head" = 1 ] && body=""
    [ "$head" = 0 ] && [ "$form" = range ] && body="f"
    [ -n "$dump" ] && emit "$dump" "$headers"
    if [ "$head" = 1 ] || [ "$include" = 1 ]; then emit "$out" "$headers$body"; else emit "$out" "$body"; fi
  else
    case "$err" in
      22) printf 'curl: (22) The requested URL returned error: %s\n' "$code" >&2 ;;
      63) printf 'curl: (63) Exceeded the maximum allowed file size (%s) with %s bytes\n' "$maxfs" "$size" >&2 ;;
      *) code=000; printf 'curl: (%s) no response from %s (fake)\n' "$err" "$url" >&2 ;;
    esac
  fi
  [ -n "$wout" ] && render "$code" "$err" "$url"
  [ "$err" = 0 ] || rc="$err"
done
exit "$rc"
FAKE
  } > "$dir/bin/curl"
  chmod +x "$dir/bin/curl"
}
# time_limits_ok <calls file> — every request carries -m/--max-time with 0 < seconds <= 10.
time_limits_ok() {
  awk '/^CALL / { n++; t = ""
         for (i = 2; i <= NF; i++) if (index($i, "maxtime=") == 1) t = substr($i, 9)
         if (t !~ /^[0-9]+([.][0-9]+)?$/ || t + 0 <= 0 || t + 0 > 10) bad++ }
       END { exit !(n > 0 && bad == 0) }' "$1"
}

# A probe run starts in the temp directory, outside the repository: the disk and Git lines pass
# only when the probe measures the repository, whichever directory it starts in. The probe's test
# inputs and CDPATH reach a run only where a case sets them.
cd "$T" || exit 2
unset PLAYWRIGHT_BROWSERS_PATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
unset AVE_PROBE_DEV_DIR AVE_PROBE_PROC_DIR AVE_PROBE_CGROUP_DIR AVE_PROBE_ROOT AVE_PROBE_SMI_TIMEOUT CDPATH
BARE_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome)"
# The cases that vary one input over many values (the cgroup files, the time limit of the query) run
# without the media tools, whose lines they leave uncompared: a run is then about half as long.
LEAN_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome ffmpeg ffprobe)"
mkdir -p "$T/dev-none" "$T/dev-gpu" "$T/bin"
# A device node of the fixtures is a symbolic link to /dev/null: a character device that every user
# can open and that needs no privilege to create.
node() { ln -s /dev/null "$1"; }
node "$T/dev-gpu/nvidia0"
printf '#!/bin/sh\nprintf "9.9.9 (Claude Code)\\n"\n' > "$T/bin/claude"; chmod +x "$T/bin/claude"

# Memory oracle: MemTotal (kB) to GiB with one decimal by integer arithmetic, half up; an exact tie
# also accepts the value below (printf rounds a tie to even).
MEM_KB="$(sed -n 's/^MemTotal:[[:space:]]*\([0-9][0-9]*\) kB$/\1/p' /proc/meminfo 2>/dev/null)"
MEM_T=$(( (${MEM_KB:-0} * 10 + 524288) / 1048576 ))
MEM_GIB="$((MEM_T / 10)).$((MEM_T % 10)) GiB"; MEM_TIE="$MEM_GIB"
if [ $(( ${MEM_KB:-0} * 10 % 1048576 )) -eq 524288 ]; then
  MEM_TIE="$(((MEM_T - 1) / 10)).$(((MEM_T - 1) % 10)) GiB"
fi

SECRET="probe-test-secret-$$-value"
# Disk space and worktrees can change while the probe runs: both are measured before and after.
DISK_BEFORE="$(disk_free "$REPO")"; WT_BEFORE="$(git -C "$REPO" worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" HF_TOKEN="$SECRET" ANTHROPIC_API_KEY="" "$PROBE" --offline 2>&1)"; CODE=$?
DISK_AFTER="$(disk_free "$REPO")"; WT_AFTER="$(git -C "$REPO" worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
BRANCH="$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
# AVE-REQ-094 AC-1
check "offline probe exits 0" '[ "$CODE" = 0 ]'
for heading in "Platform and resources" "Accelerators" "Media tools" "Toolchains" "Browsers" "Git" \
  "Claude Code and session" "Product credential variables" "Network"; do
  check "reports section: $heading" 'printf "%s\n" "$OUT" | quiet "^## $heading"'
done
# AVE-REQ-094 AC-1: resources equal this suite's own measurement.
check "cpus equals getconf _NPROCESSORS_ONLN ($(getconf _NPROCESSORS_ONLN))" 'has "^cpus +$(getconf _NPROCESSORS_ONLN)\$"'
check "memory equals MemTotal of /proc/meminfo in GiB ($MEM_GIB)" '[ -n "$MEM_KB" ] && { has_line memory "$MEM_GIB" || has_line memory "$MEM_TIE"; }'
check "disk equals the Avail and Size fields of df -h on the repository ($DISK_BEFORE)" '[ -n "$DISK_BEFORE" ] && { has_line "disk (repository)" "$DISK_BEFORE" || has_line "disk (repository)" "$DISK_AFTER"; }'
# AVE-REQ-094 AC-1: without the test variable the two cgroup lines read /sys/fs/cgroup of this host.
check "cpu quota agrees with /sys/fs/cgroup/cpu.max of this host ($(cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo no file))" 'host_cgroup "cpu quota (cgroup v2)" cpu.max && [ "$(lines_of "cpu quota (cgroup v2)")" = 1 ]'
check "memory limit agrees with /sys/fs/cgroup/memory.max of this host ($(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo no file))" 'host_cgroup "memory limit (cgroup v2)" memory.max && [ "$(lines_of "memory limit (cgroup v2)")" = 1 ]'
# AVE-REQ-094 AC-1: media tools and toolchains equal the first line of their own version output,
# without the lines that follow it.
for SPEC in "ffmpeg -hide_banner -version" "ffprobe -hide_banner -version" "python3 --version" "uv --version" "git --version"; do
  TOOL="${SPEC%% *}"
  # shellcheck disable=SC2086
  EXPECTED="$(first_line "$BARE_PATH" $SPEC)"; NEXT="$(second_line "$BARE_PATH" $SPEC)"
  check "$TOOL equals the first line of '$SPEC' ($EXPECTED)" 'has_line "$TOOL" "$EXPECTED" && no_line "$NEXT"'
done
# AVE-REQ-094 AC-1: browsers and Git equal this suite's own measurement.
check "PLAYWRIGHT_BROWSERS_PATH unset: reported as unset" 'has_line PLAYWRIGHT_BROWSERS_PATH unset'
check "worktrees equals git worktree list | wc -l ($WT_BEFORE)" 'has_line worktrees "$WT_BEFORE" || has_line worktrees "$WT_AFTER"'
check "branch equals git rev-parse --abbrev-ref HEAD ($BRANCH)" 'has_line branch "$BRANCH"'
# AVE-REQ-094 AC-1: no device and no nvidia-smi means no accelerator, whatever FFmpeg lists.
check "no device, no nvidia-smi: nvidia-smi not installed" 'has "^nvidia-smi +not installed$"'
check "no device, no nvidia-smi: accelerator: none (no device)" 'has "^accelerator: none \(no device\)$"'
check "exactly one accelerator verdict" '[ "$(printf "%s\n" "$OUT" | grep -c "^accelerator:")" = 1 ]'
check "no line claims a GPU" '! printf "%s\n" "$OUT" | quiet -Ei "gpu (available|present|found)"'
# AVE-REQ-094 AC-1: the shell-observable part of the Claude Code and permission rows.
check "claude absent from PATH: not installed" 'has "^claude +not installed$"'
check "os user is the user running the probe" 'has "^os user +$(id -un) \(uid $(id -u)\)$"'
WRITABLE=no; [ -w "$REPO" ] && WRITABLE=yes
check "repository writability matches the file system ($WRITABLE)" 'printf "%s\n" "$OUT" | quiet -xF "$(printf "%-28s %s" "repository writable" "$WRITABLE ($REPO)")"'
check "network probes skipped offline" 'has "skipped \(--offline\)"'
check "a set credential is reported as set" 'has "^HF_TOKEN +set$"'
check "an empty credential is reported as unset" 'has "^ANTHROPIC_API_KEY +unset$"'
check "no credential value is printed" '! printf "%s\n" "$OUT" | quiet -F "$SECRET"'
# AVE-REQ-098 AC-3: every credential the probe reports is documented in .env.example.
NAMES="$(printf '%s\n' "$OUT" | awk '/^## Product credential variables/ { on = 1; next } /^## / { on = 0 } on && NF { print $1 }')"
UNLISTED=""; for name in $NAMES; do grep -q "^$name=" "$REPO/.env.example" 2>/dev/null || UNLISTED="$UNLISTED $name"; done
check "every reported credential variable is listed in .env.example (missing:${UNLISTED:- none})" '[ -n "$NAMES" ] && [ -z "$UNLISTED" ]'
# The provider variables of .env.example (every name outside the AVE_ settings), each reported once.
PROVIDER_NAMES="$(sed -n 's/^\([A-Z][A-Z0-9_]*\)=.*/\1/p' "$REPO/.env.example" | grep -v '^AVE_' | sort | tr '\n' ' ')"
check "the report names exactly the provider variables of .env.example ($PROVIDER_NAMES)" '[ "$(printf "%s\n" $NAMES | sort | tr "\n" " ")" = "$PROVIDER_NAMES" ]'

OUT="$(PATH="$T/bin:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-gpu" "$PROBE" --offline 2>&1)"; CODE=$?
# AVE-REQ-094 AC-1
check "device node present: accelerator verdict names it" '[ "$CODE" = 0 ] && has "^accelerator: present \($T/dev-gpu/nvidia0\)$"'
check "claude on PATH: its version is reported" 'has "^claude +9\.9\.9 \(Claude Code\)$"'

# AVE-REQ-094 AC-1: nvidia-smi counts only when it exits 0 and lists a GPU. A fake nvidia-smi comes
# first on PATH; without a device node, a diagnostic, a failure or an empty answer is no device.
# smi_run <name> <exit status> <dev dir> <output line>... — runs the probe with that fake.
smi_run() {
  local name="$1" status="$2" dev="$3" dir="$T/smi-$1"
  shift 3
  mkdir -p "$dir"
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@"; fi > "$dir/output"
  printf '#!/bin/sh\ncat %q\nexit %s\n' "$dir/output" "$status" > "$dir/nvidia-smi"
  chmod +x "$dir/nvidia-smi"
  OUT="$(PATH="$dir:$BARE_PATH" AVE_PROBE_DEV_DIR="$dev" "$PROBE" --offline 2>&1)"; CODE=$?
}
GPU_ROW="NVIDIA RTX A4000, 16376 MiB"
smi_run driver 9 "$T/dev-none" "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running."
check "nvidia-smi fails with a driver diagnostic, no device node: no GPU reported" '[ "$CODE" = 0 ] && has_line nvidia-smi "no GPU reported"'
check "nvidia-smi fails with a driver diagnostic, no device node: accelerator: none (no device)" 'has "^accelerator: none \(no device\)$" && [ "$(printf "%s\n" "$OUT" | grep -c "^accelerator:")" = 1 ]'
smi_run nodevice 6 "$T/dev-none" "No devices were found"
check "nvidia-smi exits 6 with 'No devices were found': accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && has "^accelerator: none \(no device\)$"'
smi_run failrow 1 "$T/dev-none" "$GPU_ROW"
check "nvidia-smi prints a GPU row and fails: accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && has "^accelerator: none \(no device\)$"'
smi_run text 0 "$T/dev-none" "No devices were found"
check "nvidia-smi exits 0 with a diagnostic and no GPU row: accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && has "^accelerator: none \(no device\)$"'
smi_run empty 0 "$T/dev-none"
check "nvidia-smi exits 0 with no output: accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && has "^accelerator: none \(no device\)$"'
smi_run gpu 0 "$T/dev-none" "$GPU_ROW" "NVIDIA RTX A2000, 6138 MiB"
check "nvidia-smi exits 0 with GPU rows: the first row is reported" '[ "$CODE" = 0 ] && has_line nvidia-smi "$GPU_ROW"'
check "nvidia-smi exits 0 with GPU rows: accelerator: present names the row" 'printf "%s\n" "$OUT" | quiet -xF "accelerator: present ($GPU_ROW)" && [ "$(printf "%s\n" "$OUT" | grep -c "^accelerator:")" = 1 ]'
smi_run gpunode 0 "$T/dev-gpu" "$GPU_ROW"
check "GPU row and device node: accelerator: present names both" 'printf "%s\n" "$OUT" | quiet -xF "accelerator: present ($GPU_ROW $T/dev-gpu/nvidia0)"'
smi_run drivernode 9 "$T/dev-gpu" "NVIDIA-SMI has failed"
check "nvidia-smi fails while a device node exists: accelerator: present names the node alone" 'printf "%s\n" "$OUT" | quiet -xF "accelerator: present ($T/dev-gpu/nvidia0)"'

# AVE-REQ-094 AC-1: the verdict counts GPU devices only. The per-GPU nodes nvidia<N> and
# dri/renderD<N> count; driver control nodes, display-only nodes, directories and every other
# entry of /dev are listed or ignored and never make an accelerator.
mkdir -p "$T/dev-plain/shm" "$T/dev-ctl/nvidia-caps" "$T/dev-render/dri" "$T/dev-both/dri" \
  "$T/dev-card/dri/by-path" "$T/nvidia-empty" "$T/dev-file" "$T/dev-dirnode/nvidia0" "$T/dev-dirnode/dri/renderD128"
node "$T/dev-plain/null"; node "$T/dev-plain/sda"
node "$T/dev-ctl/nvidiactl"; node "$T/dev-ctl/nvidia-uvm"; node "$T/dev-ctl/nvidia-uvm-tools"; node "$T/dev-ctl/nvidia-modeset"
node "$T/dev-render/dri/renderD128"
node "$T/dev-both/nvidia0"; node "$T/dev-both/dri/renderD128"; node "$T/dev-both/dri/card0"
node "$T/dev-card/dri/card0"
node "$T/dev-file/nvidia-readme.txt"
NONE='accelerator: none (no device)'
verdict() { printf '%s\n' "$OUT" | quiet -xF "$1" && [ "$(printf '%s\n' "$OUT" | grep -c '^accelerator:')" = 1 ]; }
# dev_run <device directory> [<launcher>...] — runs the probe on the directory (behind the launcher,
# such as `setsid -w` or `env NAME=value`) and lists the directory before and after: DEV_SAME reads 1
# when the run left it as it was, and CHANGED collects every directory a run changed.
CHANGED=""
dev_run() {
  local dir="$1" before after
  shift
  before="$(snapshot "$dir")"
  OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$dir" "$@" "$PROBE" --offline 2>&1 </dev/null)"; CODE=$?
  after="$(snapshot "$dir")"
  DEV_SAME=1
  [ "$before" = "$after" ] || { DEV_SAME=0; CHANGED="$CHANGED $dir"; }
}
dev_run "$T/dev-plain"
check "ordinary /dev entries (null, sda, a directory): accelerator: none (no device)" '[ "$CODE" = 0 ] && verdict "$NONE" && has_line "/dev/nvidia* devices" none && has_line "/dev/dri devices" none'
dev_run "$T/dev-ctl"
check "driver control nodes without a GPU node: the five entries are listed, and accelerator: none (no device)" 'verdict "$NONE" && has_line "/dev/nvidia* devices" "$T/dev-ctl/nvidia-caps $T/dev-ctl/nvidia-modeset $T/dev-ctl/nvidia-uvm $T/dev-ctl/nvidia-uvm-tools $T/dev-ctl/nvidiactl" && has_line "/dev/dri devices" none'
smi_run ctlnodevice 6 "$T/dev-ctl" "No devices were found"
check "control nodes with nvidia-smi answering 'No devices were found' (exit 6): accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && verdict "$NONE"'
dev_run "$T/dev-render"
check "a DRI render node: accelerator: present names it" 'verdict "accelerator: present ($T/dev-render/dri/renderD128)"'
dev_run "$T/dev-both"
check "a GPU node and a render node: accelerator: present names both and leaves the display node out" 'verdict "accelerator: present ($T/dev-both/nvidia0 $T/dev-both/dri/renderD128)" && has_line "/dev/nvidia* devices" "$T/dev-both/nvidia0" && has_line "/dev/dri devices" "$T/dev-both/dri/card0 $T/dev-both/dri/renderD128"'
dev_run "$T/dev-card"
check "a display-only DRI node and dri/by-path: listed, and accelerator: none (no device)" 'verdict "$NONE" && has_line "/dev/dri devices" "$T/dev-card/dri/by-path $T/dev-card/dri/card0"'
dev_run "$T/nvidia-empty"
check "an empty device directory whose own name starts with nvidia: accelerator: none (no device)" 'verdict "$NONE" && has_line "/dev/nvidia* devices" none'
dev_run "$T/dev-file"
check "a file named nvidia-readme.txt is no GPU node: accelerator: none (no device)" 'verdict "$NONE"'
dev_run "$T/dev-dirnode"
check "directories named nvidia0 and dri/renderD128 are no devices: accelerator: none (no device)" 'verdict "$NONE"'
# The whole name decides: a character device whose name only starts or only ends like a GPU node, or
# that carries the name of the other directory's node, counts for nothing.
for NAME in nvidia0.txt nvidia0-readme.txt nvidia3d-vision.conf nvidia dri/renderD128.bak dri/renderD1-notes dri/renderD \
  xnvidia0 dri/card-renderD128 dri/xrenderD128 dri/nvidia0 renderD128; do
  D="$T/dev-name-$(printf '%s' "$NAME" | tr '/.' '--')"
  mkdir -p "$D/dri"; node "$D/$NAME"
  dev_run "$D"
  check "a character device named $NAME is no GPU node: accelerator: none (no device)" 'verdict "$NONE"'
done
# Listed are the entries named nvidia* and the entries of dri: three fixtures of the loop above show
# an entry that stands on no line, one that stands on the dri line, and a render name outside dri.
dev_run "$T/dev-name-xnvidia0"
check "xnvidia0 stands on no list line" 'has_line "/dev/nvidia* devices" none && has_line "/dev/dri devices" none'
dev_run "$T/dev-name-dri-nvidia0"
check "dri/nvidia0 stands on the dri line alone" 'has_line "/dev/nvidia* devices" none && has_line "/dev/dri devices" "$T/dev-name-dri-nvidia0/dri/nvidia0"'
dev_run "$T/dev-name-renderD128"
check "renderD128 outside dri stands on no list line" 'has_line "/dev/nvidia* devices" none && has_line "/dev/dri devices" none'
# A name is one string: a line feed or a space inside it splits nothing. The entry is no GPU node,
# it is one word of its list line (the shell's quoted form), and the probe leaves the directory as
# it was.
mkdir -p "$T/dev-lf" "$T/dev-lf-dri/dri" "$T/dev-space"
node "$T/dev-lf/nvidia0"$'\n'"x"
node "$T/dev-lf-dri/dri/renderD128"$'\n'".bak"
node "$T/dev-space/nvidia0 1"
dev_run "$T/dev-lf"
check "a character device named nvidia0<LF>x is no GPU node: accelerator: none (no device)" '[ "$CODE" = 0 ] && verdict "$NONE"'
check "a character device named nvidia0<LF>x: the probe leaves the device directory as it was" '[ "$DEV_SAME" = 1 ] && [ "$(find "$T/dev-lf" -mindepth 1 -printf x | wc -c)" = 1 ]'
check "a character device named nvidia0<LF>x is one word of the one nvidia list line" 'has_line "/dev/nvidia* devices" "\$'"'"'$T/dev-lf/nvidia0\\nx'"'"'" && [ "$(lines_of "/dev/nvidia* devices")" = 1 ] && no_line x'
dev_run "$T/dev-lf-dri"
check "a character device named dri/renderD128<LF>.bak is no GPU node: accelerator: none (no device)" '[ "$CODE" = 0 ] && verdict "$NONE"'
check "a character device named dri/renderD128<LF>.bak: the probe leaves the device directory as it was" '[ "$DEV_SAME" = 1 ] && [ "$(find "$T/dev-lf-dri/dri" -mindepth 1 -printf x | wc -c)" = 1 ]'
check "a character device named dri/renderD128<LF>.bak is one word of the one dri list line" 'has_line "/dev/dri devices" "\$'"'"'$T/dev-lf-dri/dri/renderD128\\n.bak'"'"'" && [ "$(lines_of "/dev/dri devices")" = 1 ] && no_line .bak'
dev_run "$T/dev-space"
check "a character device named 'nvidia0 1' is no GPU node and one word of its list line" 'verdict "$NONE" && has_line "/dev/nvidia* devices" "$T/dev-space/nvidia0\\ 1"'
# The same form holds for the directory part: a device directory with a space in its own name.
mkdir -p "$T/dev spaced"; node "$T/dev spaced/nvidia0"
dev_run "$T/dev spaced"
check "a device directory named 'dev spaced': the list line and the verdict name its node as one word" 'verdict "accelerator: present ($T/dev\\ spaced/nvidia0)" && has_line "/dev/nvidia* devices" "$T/dev\\ spaced/nvidia0"'
# dri as a symbolic link to a directory: the list line shows what the verdict counts.
mkdir -p "$T/dev-linked"; ln -s "$T/dev-render/dri" "$T/dev-linked/dri"
dev_run "$T/dev-linked"
check "dri as a link to a directory: the list line and the verdict name the same render node" 'verdict "accelerator: present ($T/dev-linked/dri/renderD128)" && has_line "/dev/dri devices" "$T/dev-linked/dri/renderD128"'
# Every entry of dri is listed, a hidden one included.
mkdir -p "$T/dev-hidden/dri"; : > "$T/dev-hidden/dri/.hidden"
dev_run "$T/dev-hidden"
check "a hidden entry of dri is listed" 'verdict "$NONE" && has_line "/dev/dri devices" "$T/dev-hidden/dri/.hidden"'
# A device directory that does not exist reads as one without entries, and stays absent.
dev_run "$T/dev-missing"
check "a missing device directory: both list lines read none and accelerator: none (no device)" '[ "$CODE" = 0 ] && [ ! -e "$T/dev-missing" ] && verdict "$NONE" && has_line "/dev/nvidia* devices" none && has_line "/dev/dri devices" none'
# The kind decides: only a character device counts under the exact name.
mkdir -p "$T/dev-regular/dri" "$T/dev-fifo" "$T/dev-dangling/dri" "$T/dev-dirlink"
: > "$T/dev-regular/nvidia0"; : > "$T/dev-regular/dri/renderD128"
mkfifo "$T/dev-fifo/nvidia0"
ln -s "$T/no-such-node" "$T/dev-dangling/nvidia0"; ln -s "$T/no-such-node" "$T/dev-dangling/dri/renderD128"
ln -s "$T/dev-none" "$T/dev-dirlink/nvidia0"
for KIND in regular fifo dangling dirlink; do
  dev_run "$T/dev-$KIND"
  check "nvidia0 as a $KIND entry is listed and is no device: accelerator: none (no device)" '[ "$CODE" = 0 ] && verdict "$NONE" && has_line "/dev/nvidia* devices" "$T/dev-$KIND/nvidia0"'
done
# Every number counts, whatever its length: a host that is given one GPU of several holds another
# node than nvidia0, and a render node carries one digit as well as three.
for NAME in nvidia1 nvidia10 dri/renderD129 dri/renderD7 dri/renderD42; do
  D="$T/dev-number-$(printf '%s' "$NAME" | tr '/' '-')"
  mkdir -p "$D/dri"; node "$D/$NAME"
  dev_run "$D"
  check "the node $NAME alone: accelerator: present names it" 'verdict "accelerator: present ($D/$NAME)"'
done
# Access decides: a node this user cannot open is reported as such. /dev/tty is a character device
# whose open fails for a process without a controlling terminal, which setsid provides.
mkdir -p "$T/dev-closed/dri" "$T/dev-half/dri"
ln -s /dev/tty "$T/dev-closed/nvidia0"
ln -s /dev/tty "$T/dev-half/nvidia0"; node "$T/dev-half/dri/renderD128"
dev_run "$T/dev-closed" setsid -w
check "a GPU node that cannot be opened: accelerator: none names the node without access" '[ "$CODE" = 0 ] && verdict "accelerator: none (no access to $T/dev-closed/nvidia0)"'
dev_run "$T/dev-half" setsid -w
check "one node without access beside one that opens: accelerator: present names the open one" 'verdict "accelerator: present ($T/dev-half/dri/renderD128)"'
# How a node is opened: a fake dd first on PATH records its operands and succeeds. The probe tries
# the operands on /dev/null once, then opens each named character device once, for reading and for
# writing, creating and truncating nothing and transferring nothing; the display node stays unopened.
mkdir -p "$T/dd-record" "$T/dd-plain"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexit 0\n' "$T/dd-record/calls" > "$T/dd-record/dd"; chmod +x "$T/dd-record/dd"
dev_run "$T/dev-both" env PATH="$T/dd-record:$BARE_PATH"
DD_FORM="count=0 conv=nocreat,notrunc status=none"
check "each GPU node is opened once as dd if=<node> of=<node> $DD_FORM" 'verdict "accelerator: present ($T/dev-both/nvidia0 $T/dev-both/dri/renderD128)" && [ "$(grep -cxF -- "if=$T/dev-both/nvidia0 of=$T/dev-both/nvidia0 $DD_FORM" "$T/dd-record/calls")" = 1 ] && [ "$(grep -cxF -- "if=$T/dev-both/dri/renderD128 of=$T/dev-both/dri/renderD128 $DD_FORM" "$T/dd-record/calls")" = 1 ]'
check "the operands are tried on /dev/null once, and no other path is opened (the display node included)" '[ "$(grep -cxF -- "if=/dev/null of=/dev/null $DD_FORM" "$T/dd-record/calls")" = 1 ] && [ "$(wc -l < "$T/dd-record/calls")" = 3 ]'
# Without a dd that takes these operands no node is opened, and the verdict says so.
NODD_PATH="$(PATH="$BARE_PATH" path_without dd)"
dev_run "$T/dev-gpu" env PATH="$NODD_PATH"
check "no dd on PATH beside a GPU node: accelerator: unknown names the node the open test is unavailable for" '[ "$CODE" = 0 ] && ! (PATH="$NODD_PATH"; command -v dd >/dev/null 2>&1) && verdict "accelerator: unknown (open test unavailable for $T/dev-gpu/nvidia0)"'
dev_run "$T/dev-none" env PATH="$NODD_PATH"
check "no dd on PATH and no GPU node: accelerator: none (no device)" 'verdict "$NONE"'
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\ncase "$*" in *nocreat*) echo "dd: invalid conversion: nocreat" >&2; exit 1 ;; esac\nexit 0\n' "$T/dd-plain/calls" > "$T/dd-plain/dd"; chmod +x "$T/dd-plain/dd"
dev_run "$T/dev-both" env PATH="$T/dd-plain:$BARE_PATH"
check "a dd that knows no conv=nocreat beside two GPU nodes: accelerator: unknown names both" 'verdict "accelerator: unknown (open test unavailable for $T/dev-both/nvidia0 $T/dev-both/dri/renderD128)"'
check "a dd that knows no conv=nocreat: after the trial on /dev/null no node is opened" '[ "$(cat "$T/dd-plain/calls")" = "if=/dev/null of=/dev/null $DD_FORM" ]'
dev_run "$T/dev-gpu" env PATH="$T/smi-gpu:$NODD_PATH"
check "no dd on PATH, a GPU node and a GPU row of nvidia-smi: accelerator: present names the row alone" 'has_line nvidia-smi "$GPU_ROW" && verdict "accelerator: present ($GPU_ROW)"'
# A node behind two symbolic links is the character device at their end.
mkdir -p "$T/dev-chain"; ln -s /dev/null "$T/dev-chain-end"; ln -s "$T/dev-chain-end" "$T/dev-chain/nvidia0"
dev_run "$T/dev-chain"
check "nvidia0 as a link to a link to a character device: accelerator: present names it" 'verdict "accelerator: present ($T/dev-chain/nvidia0)"'
# Shell options the environment exports leave the walk as it is: with pathname expansion switched
# off the nodes are still listed and counted, and with unmatched patterns made an error an empty
# device directory still prints its three lines, without a `no match` message of the shell.
dev_run "$T/dev-both" env SHELLOPTS=noglob
check "SHELLOPTS=noglob exported: the walk still lists and counts the nodes" 'verdict "accelerator: present ($T/dev-both/nvidia0 $T/dev-both/dri/renderD128)" && has_line "/dev/dri devices" "$T/dev-both/dri/card0 $T/dev-both/dri/renderD128"'
dev_run "$T/dev-none" env BASHOPTS=failglob
check "BASHOPTS=failglob exported: an empty device directory prints both list lines and the verdict, and no error of the shell" '[ "$CODE" = 0 ] && verdict "$NONE" && has_line "/dev/nvidia* devices" none && has_line "/dev/dri devices" none && ! has "no match"'
check "no probe run changed its device directory (changed:${CHANGED:- none})" '[ -z "$CHANGED" ]'
for ANSWER in "Sorry, no GPU is attached to this machine" "name, memory.total [MiB]" "[N/A], [N/A]"; do
  smi_run comma 0 "$T/dev-none" "$ANSWER"
  check "nvidia-smi exits 0 with '$ANSWER' (a comma, no memory figure): accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && verdict "$NONE"'
done
# A row holds a name before its last comma and ends with the unit.
for ANSWER in ", 16 MiB" " , 16 MiB" "Tesla T4, 15360 MiB (shared)" "Tesla T4, 15360 MiB "; do
  smi_run rowform 0 "$T/dev-none" "$ANSWER"
  check "nvidia-smi exits 0 with '$ANSWER' (no name, or text behind the unit): accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && verdict "$NONE"'
done
smi_run commaname 0 "$T/dev-none" "Acme GPU, Model X, 8192 MiB"
check "a GPU name that holds a comma: the row is reported and counts" 'has_line nvidia-smi "Acme GPU, Model X, 8192 MiB" && verdict "accelerator: present (Acme GPU, Model X, 8192 MiB)"'
smi_run errors 0 "$T/dev-none" "GPU 0 failed, 3 errors"
check "nvidia-smi exits 0 with 'GPU 0 failed, 3 errors' (a figure without the unit): accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && verdict "$NONE"'
smi_run later 0 "$T/dev-none" "Warning: persistence mode is off" "$GPU_ROW"
check "a line that is no row before a GPU row: the row is reported and counts" 'has_line nvidia-smi "$GPU_ROW" && verdict "accelerator: present ($GPU_ROW)"'
mkdir -p "$T/smi-stderr" "$T/smi-limit" "$T/smi-nolimit"
printf '#!/bin/sh\necho "%s" >&2\nexit 0\n' "$GPU_ROW" > "$T/smi-stderr/nvidia-smi"; chmod +x "$T/smi-stderr/nvidia-smi"
OUT="$(PATH="$T/smi-stderr:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "a GPU row on the error stream alone: accelerator: none (no device)" 'has_line nvidia-smi "no GPU reported" && verdict "$NONE"'
# The default time limit: a fake timeout first on PATH records its arguments and runs the command.
printf '#!/bin/sh\necho "%s"\n' "$GPU_ROW" > "$T/smi-limit/nvidia-smi"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" > "%s"\nwhile [ "$#" -gt 0 ] && [ "$1" != nvidia-smi ]; do shift; done\nexec "$@"\n' "$T/smi-limit/arguments" > "$T/smi-limit/timeout"
chmod +x "$T/smi-limit/nvidia-smi" "$T/smi-limit/timeout"
OUT="$(PATH="$T/smi-limit:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "the nvidia-smi query runs under a 10 s limit with a kill after 2 s more" 'has_line nvidia-smi "$GPU_ROW" && sed -n 1p "$T/smi-limit/arguments" | quiet -x -- "-k 2 10 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader"'
OUT="$(PATH="$T/smi-limit:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_SMI_TIMEOUT=7 "$PROBE" --offline 2>&1)"; CODE=$?
check "AVE_PROBE_SMI_TIMEOUT replaces the limit of the query" 'has_line nvidia-smi "$GPU_ROW" && sed -n 1p "$T/smi-limit/arguments" | quiet -x -- "-k 2 7 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader"'
# The variable counts only as a positive whole number (digits alone, one of them above 0): every
# other value leaves the 10 s (timeout reads 0 as no limit and 1m as a minute).
# limit_run <value> — runs the probe with that value; LIMIT_ARGS receives what timeout was given.
limit_run() {
  rm -f "$T/smi-limit/arguments"
  OUT="$(PATH="$T/smi-limit:$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_SMI_TIMEOUT="$1" "$PROBE" --offline 2>&1)"; CODE=$?
  LIMIT_ARGS="$(cat "$T/smi-limit/arguments" 2>/dev/null)"
}
for VALUE in 30 007; do
  limit_run "$VALUE"
  check "AVE_PROBE_SMI_TIMEOUT=$VALUE is a positive whole number: timeout is given $VALUE" 'has_line nvidia-smi "$GPU_ROW" && [ "$LIMIT_ARGS" = "-k 2 $VALUE nvidia-smi --query-gpu=name,memory.total --format=csv,noheader" ]'
done
for VALUE in 0 00 abc -5 +5 1.5 5s 1m " 7" "7 " "7 8" ""; do
  limit_run "$VALUE"
  check "AVE_PROBE_SMI_TIMEOUT='$VALUE' is no positive whole number: the limit stays 10 s" 'has_line nvidia-smi "$GPU_ROW" && [ "$LIMIT_ARGS" = "-k 2 10 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader" ]'
done
limit_run "7"$'\n'"8"
check "AVE_PROBE_SMI_TIMEOUT='7<LF>8' is no positive whole number: the limit stays 10 s" 'has_line nvidia-smi "$GPU_ROW" && [ "$LIMIT_ARGS" = "-k 2 10 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader" ]'
# Without a timeout command the query is left out: it could block the probe.
printf '#!/bin/sh\necho "%s"\n' "$GPU_ROW" > "$T/smi-nolimit/nvidia-smi"; chmod +x "$T/smi-nolimit/nvidia-smi"
NO_TIMEOUT_PATH="$(PATH="$BARE_PATH" path_without timeout)"
OUT="$(PATH="$T/smi-nolimit:$NO_TIMEOUT_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "nvidia-smi without a timeout command: the query is left out and reports no GPU" '[ "$CODE" = 0 ] && ! (PATH="$NO_TIMEOUT_PATH"; command -v timeout >/dev/null 2>&1) && has_line nvidia-smi "no GPU reported (timeout unavailable)" && verdict "$NONE"'
mkdir -p "$T/smi-hang"
printf '#!/bin/sh\nexec sleep 30\n' > "$T/smi-hang/nvidia-smi"; chmod +x "$T/smi-hang/nvidia-smi"
STARTED=$SECONDS
OUT="$(PATH="$T/smi-hang:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_SMI_TIMEOUT=1 "$PROBE" --offline 2>&1)"; CODE=$?
check "an nvidia-smi that hangs is cut off at its time limit and counts as no GPU" '[ "$CODE" = 0 ] && [ "$((SECONDS - STARTED))" -lt 20 ] && has_line nvidia-smi "no GPU reported" && verdict "$NONE"'

# AVE-REQ-094 AC-1: fixture inputs that differ from this host: the CPU count follows getconf, the
# memory and CPU model follow meminfo and cpuinfo, the OS user follows id, and writability follows
# the repository root, so a line fixed to this host's value fails here.
FIX="$T/fixture-inputs"; mkdir -p "$FIX/bin" "$FIX/proc" "$FIX/root-writable"
REAL_GETCONF="$(command -v getconf)"; REAL_ID="$(command -v id)"
cat > "$FIX/bin/getconf" <<EOF
#!/bin/sh
case "\$1" in _NPROCESSORS_ONLN) printf '3\n' ;; *) exec "$REAL_GETCONF" "\$@" ;; esac
EOF
cat > "$FIX/bin/id" <<EOF
#!/bin/sh
case "\$*" in -un) printf 'probeuser\n' ;; -u) printf '4242\n' ;; *) exec "$REAL_ID" "\$@" ;; esac
EOF
chmod +x "$FIX/bin/getconf" "$FIX/bin/id"
printf 'MemTotal:        2883584 kB\nMemFree:          100000 kB\n' > "$FIX/proc/meminfo"
printf 'processor\t: 0\nmodel name\t: Probe Fixture CPU @ 9.99GHz\n' > "$FIX/proc/cpuinfo"
OUT="$(PATH="$FIX/bin:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_PROC_DIR="$FIX/proc" AVE_PROBE_ROOT="$FIX/root-writable" "$PROBE" --offline 2>&1)"; CODE=$?
check "fixture inputs: probe exits 0" '[ "$CODE" = 0 ]'
check "fake getconf answers 3: cpus 3" 'has_line cpus 3'
check "meminfo fixture with MemTotal 2883584 kB: memory 2.8 GiB" 'has_line memory "2.8 GiB"'
check "cpuinfo fixture: cpu model is its model name" 'has_line "cpu model" "Probe Fixture CPU @ 9.99GHz"'
check "fake id answers probeuser and 4242: os user probeuser (uid 4242)" 'has_line "os user" "probeuser (uid 4242)"'
check "writable fixture root: repository writable yes with that root" 'has_line "repository writable" "yes ($FIX/root-writable)"'
# A cpuinfo without a model name (arm64): the CPU model follows lscpu, and "-" or no answer reads unknown.
mkdir -p "$FIX/proc-arm" "$FIX/lscpu-named" "$FIX/lscpu-dash"
printf 'processor	: 0
BogoMIPS	: 38.40
' > "$FIX/proc-arm/cpuinfo"; cp "$FIX/proc/meminfo" "$FIX/proc-arm/meminfo"
printf '#!/bin/sh
printf "%%s\n" "Architecture:   aarch64" "Model name:     Probe Fixture Arm Core" "Model:          1"
' > "$FIX/lscpu-named/lscpu"
printf '#!/bin/sh
printf "%%s\n" "Architecture:   aarch64" "Model name:     -" "Model:          1"
' > "$FIX/lscpu-dash/lscpu"
chmod +x "$FIX/lscpu-named/lscpu" "$FIX/lscpu-dash/lscpu"
OUT="$(PATH="$FIX/lscpu-named:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_PROC_DIR="$FIX/proc-arm" "$PROBE" --offline 2>&1)"
check "cpuinfo without a model name: cpu model follows lscpu" 'has_line "cpu model" "Probe Fixture Arm Core"'
OUT="$(PATH="$FIX/lscpu-dash:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_PROC_DIR="$FIX/proc-arm" "$PROBE" --offline 2>&1)"
check "cpuinfo without a model name and lscpu answering '-': cpu model unknown" 'has_line "cpu model" unknown'
# A command of the probe that fails (the search for a model name in this cpuinfo) does not end the
# report, also when the environment exports the shell option that ends a script at a failure.
OUT="$(PATH="$FIX/lscpu-named:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_PROC_DIR="$FIX/proc-arm" env SHELLOPTS=errexit "$PROBE" --offline 2>&1)"; CODE=$?
check "SHELLOPTS=errexit exported, a cpuinfo without a model name: the report runs to its last section" '[ "$CODE" = 0 ] && has_line "cpu model" "Probe Fixture Arm Core" && verdict "$NONE" && has "^## Network" && has "skipped \(--offline\)"'
OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_ROOT="$FIX/root-missing" "$PROBE" --offline 2>&1)"; CODE=$?
check "missing fixture root: repository writable no with that root" '[ "$CODE" = 0 ] && [ ! -e "$FIX/root-missing" ] && has_line "repository writable" "no ($FIX/root-missing)"'

# AVE-REQ-094 AC-1: the cgroup lines follow cpu.max and memory.max of the directory given through
# AVE_PROBE_CGROUP_DIR: the figure for a number, `none` for max and for a missing file, `unknown`
# for any other content. The kernel totals stay on the cpus and memory lines.
# cg_run <name> <cpu.max content> <memory.max content> — runs the probe on a fixture directory with
# these two files; "-" leaves a file out.
cg_run() {
  CG="$T/cgroup-$1"
  mkdir -p "$CG"
  [ "$2" = - ] || printf '%s\n' "$2" > "$CG/cpu.max"
  [ "$3" = - ] || printf '%s\n' "$3" > "$CG/memory.max"
  OUT="$(PATH="$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_CGROUP_DIR="$CG" "$PROBE" --offline 2>&1)"; CODE=$?
}
cg_run limited "200000 100000" 1073741824
check "cpu.max '200000 100000': cpu quota 2.00 cpus" '[ "$CODE" = 0 ] && has_line "cpu quota (cgroup v2)" "2.00 cpus (cpu.max 200000 100000)"'
check "memory.max 1073741824: memory limit 1.0 GiB" 'has_line "memory limit (cgroup v2)" "1.0 GiB (memory.max 1073741824)"'
check "beside a quota the cpus and memory lines keep the kernel totals" 'has "^cpus +$(getconf _NPROCESSORS_ONLN)\$" && { has_line memory "$MEM_GIB" || has_line memory "$MEM_TIE"; }'
cg_run fraction "150000 100000" 536870912
check "cpu.max '150000 100000': cpu quota 1.50 cpus" 'has_line "cpu quota (cgroup v2)" "1.50 cpus (cpu.max 150000 100000)"'
check "memory.max 536870912: memory limit 0.5 GiB" 'has_line "memory limit (cgroup v2)" "0.5 GiB (memory.max 536870912)"'
cg_run rounded "333333 100000" 8000000000
check "cpu.max '333333 100000': cpu quota 3.33 cpus" 'has_line "cpu quota (cgroup v2)" "3.33 cpus (cpu.max 333333 100000)"'
check "memory.max 8000000000: memory limit 7.5 GiB" 'has_line "memory limit (cgroup v2)" "7.5 GiB (memory.max 8000000000)"'
cg_run period "50000 200000" 1073741824
check "cpu.max '50000 200000': the quota is divided by the period, 0.25 cpus" 'has_line "cpu quota (cgroup v2)" "0.25 cpus (cpu.max 50000 200000)"'
cg_run max "max 100000" max
check "cpu.max 'max 100000' and memory.max 'max': both lines read none" 'has_line "cpu quota (cgroup v2)" none && has_line "memory limit (cgroup v2)" none'
cg_run nofiles - -
check "a cgroup directory without the two files: both lines read none" '[ "$CODE" = 0 ] && has_line "cpu quota (cgroup v2)" none && has_line "memory limit (cgroup v2)" none'
OUT="$(PATH="$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_CGROUP_DIR="$T/cgroup-missing" "$PROBE" --offline 2>&1)"; CODE=$?
check "a missing cgroup directory: both lines read none" '[ "$CODE" = 0 ] && [ ! -e "$T/cgroup-missing" ] && has_line "cpu quota (cgroup v2)" none && has_line "memory limit (cgroup v2)" none'
cg_run cpuonly "200000 100000" -
check "cpu.max alone: the quota is reported and the memory limit reads none" 'has_line "cpu quota (cgroup v2)" "2.00 cpus (cpu.max 200000 100000)" && has_line "memory limit (cgroup v2)" none'
# Any other content reads unknown; one run takes a cpu.max form and, while the list lasts, a
# memory.max form (an empty string is a file that holds an empty line).
CPU_OTHER=("" max 200000 "200000 0" "200000 00" "abc 100000" "200000 abc" "200000 100000 7" "200000  100000"
  "-1 100000" "2e5 100000" "max 100000"$'\n'"200000 100000" "max 0")
MEMORY_OTHER=("" abc -1 "1024 kB" 1.5 "max 100000" "1073741824 0" "max"$'\n'"1073741824")
for I in "${!CPU_OTHER[@]}"; do
  CONTENT="${CPU_OTHER[$I]}"
  cg_run "other-$I" "$CONTENT" "${MEMORY_OTHER[$I]--}"
  check "cpu.max '$(printf '%s' "$CONTENT" | tr '\n' '|')' is no quota form: cpu quota unknown" 'has_line "cpu quota (cgroup v2)" unknown && [ "$(lines_of "cpu quota (cgroup v2)")" = 1 ]'
  [ "$I" -lt "${#MEMORY_OTHER[@]}" ] || continue
  CONTENT="${MEMORY_OTHER[$I]}"
  check "memory.max '$(printf '%s' "$CONTENT" | tr '\n' '|')' is no limit form: memory limit unknown" 'has_line "memory limit (cgroup v2)" unknown && [ "$(lines_of "memory limit (cgroup v2)")" = 1 ]'
done
# The line end is one at most, and a NUL byte makes the content no text.
mkdir -p "$T/cgroup-bare" "$T/cgroup-blank" "$T/cgroup-nul"
printf '200000 100000' > "$T/cgroup-bare/cpu.max"; printf 'max' > "$T/cgroup-bare/memory.max"
printf 'max 100000\n\n' > "$T/cgroup-blank/cpu.max"; printf '1073741824\n\n' > "$T/cgroup-blank/memory.max"
printf 'max 100000\0\n' > "$T/cgroup-nul/cpu.max"; printf 'max\0\n' > "$T/cgroup-nul/memory.max"
OUT="$(PATH="$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_CGROUP_DIR="$T/cgroup-bare" "$PROBE" --offline 2>&1)"
check "cpu.max and memory.max without a line end: the quota is reported and the memory limit reads none" 'has_line "cpu quota (cgroup v2)" "2.00 cpus (cpu.max 200000 100000)" && has_line "memory limit (cgroup v2)" none'
OUT="$(PATH="$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_CGROUP_DIR="$T/cgroup-blank" "$PROBE" --offline 2>&1)"
check "cpu.max and memory.max with a second line end: both lines read unknown" 'has_line "cpu quota (cgroup v2)" unknown && has_line "memory limit (cgroup v2)" unknown'
OUT="$(PATH="$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_CGROUP_DIR="$T/cgroup-nul" "$PROBE" --offline 2>&1)"
check "cpu.max and memory.max with a NUL byte behind max: both lines read unknown" 'has_line "cpu quota (cgroup v2)" unknown && has_line "memory limit (cgroup v2)" unknown'
mkdir -p "$T/cgroup-directory/cpu.max" "$T/cgroup-directory/memory.max"
OUT="$(PATH="$LEAN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" AVE_PROBE_CGROUP_DIR="$T/cgroup-directory" "$PROBE" --offline 2>&1)"; CODE=$?
check "cpu.max and memory.max as directories: both lines read unknown" '[ "$CODE" = 0 ] && has_line "cpu quota (cgroup v2)" unknown && has_line "memory limit (cgroup v2)" unknown'

# AVE-REQ-094 AC-1: a tool hidden from PATH is reported as not installed.
HIDDEN_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome ffmpeg ffprobe python3 uv node pnpm git docker)"
OUT="$(PATH="$HIDDEN_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "tools hidden from PATH: probe exits 0" '[ "$CODE" = 0 ]'
# `type -P` looks on PATH alone (this suite holds a function named node).
for TOOL in ffmpeg ffprobe python3 uv node pnpm git docker; do
  check "$TOOL hidden from PATH: not installed" '! (PATH="$HIDDEN_PATH"; type -P "$TOOL" >/dev/null 2>&1) && has_line "$TOOL" "not installed"'
done

# AVE-REQ-094 AC-1: fakes first on PATH: each line follows the command the probe finds, so a value
# fixed in the probe fails here or in the run above; Playwright's directory lists its entries.
FAKE="$T/fake-bin"; mkdir -p "$FAKE" "$T/pw/chromium-1187" "$T/pw/ffmpeg-1011" "$T/pw/firefox-1490"
REAL_GIT="$(PATH="$BARE_PATH"; command -v git)"
cat > "$FAKE/ffmpeg" <<'EOF'
#!/bin/sh
case "$*" in *-version*) printf '%s\n' 'ffmpeg version 99.1-probe-fake Copyright (c) the probe tests' 'ffmpeg built with probe-fake' ;; esac
EOF
cat > "$FAKE/ffprobe" <<'EOF'
#!/bin/sh
case "$*" in *-version*) printf '%s\n' 'ffprobe version 99.2-probe-fake Copyright (c) the probe tests' 'ffprobe built with probe-fake' ;; esac
EOF
cat > "$FAKE/python3" <<'EOF'
#!/bin/sh
printf '%s\n' 'Python 3.99.3-probe-fake' 'python3 second line'
EOF
cat > "$FAKE/uv" <<'EOF'
#!/bin/sh
printf '%s\n' 'uv 0.99.4-probe-fake (0000000 2026-10-03)' 'uv second line'
EOF
cat > "$FAKE/git" <<EOF
#!/bin/sh
case "\$1" in
  --version) printf '%s\n' 'git version 2.99.5.probe-fake' 'git second line' ;;
  *) exec "$REAL_GIT" "\$@" ;;
esac
EOF
cat > "$FAKE/df" <<EOF
#!/bin/sh
# One file system for the repository (the last argument), another for every other directory.
for arg in "\$@"; do dir="\$arg"; done
if [ "\$(cd "\${dir:-.}" 2>/dev/null && pwd -P)" = "$(cd "$REPO" && pwd -P)" ]; then
  printf '%s\n' 'Filesystem      Size  Used Avail Use% Mounted on' 'probe-fake-fs   977G  512G  465G  53% /probe'
else
  printf '%s\n' 'Filesystem      Size  Used Avail Use% Mounted on' 'probe-fake-other  2.0G  1.0G  1.0G  50% /other'
fi
EOF
cat > "$FAKE/chromium" <<'EOF'
#!/bin/sh
printf '%s\n' 'Chromium 140.0.7339.185 probe-fake' 'chromium second line'
EOF
cat > "$FAKE/google-chrome" <<'EOF'
#!/bin/sh
printf '%s\n' 'Google Chrome 139.0.7258.66 probe-fake' 'google-chrome second line'
EOF
cat > "$FAKE/chromium-browser" <<'EOF'
#!/bin/sh
printf '%s\n' 'Chromium 138.0.7204.100 probe-fake-browser' 'chromium-browser second line'
EOF
chmod +x "$FAKE"/*
make_fake_curl "$T/net-offline"
FAKE_PATH="$FAKE:$T/net-offline/bin:$BARE_PATH"
DISK_FAKE="$(PATH="$FAKE_PATH"; disk_free "$REPO")"
OUT="$(PATH="$FAKE_PATH" PLAYWRIGHT_BROWSERS_PATH="$T/pw" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" --offline 2>&1)"; CODE=$?
check "fakes first on PATH: probe exits 0" '[ "$CODE" = 0 ]'
for SPEC in "ffmpeg -hide_banner -version" "ffprobe -hide_banner -version" "python3 --version" "uv --version" "git --version"; do
  TOOL="${SPEC%% *}"
  # shellcheck disable=SC2086
  EXPECTED="$(first_line "$FAKE_PATH" $SPEC)"; NEXT="$(second_line "$FAKE_PATH" $SPEC)"
  check "fake $TOOL first on PATH: equals the first line of '$SPEC' ($EXPECTED)" 'has_line "$TOOL" "$EXPECTED" && no_line "$NEXT"'
done
check "fake df first on PATH: disk equals its Avail and Size fields for the repository ($DISK_FAKE)" 'has_line "disk (repository)" "$DISK_FAKE"'
for TOOL in chromium chromium-browser google-chrome; do
  EXPECTED="$(first_line "$FAKE_PATH" "$TOOL" --version)"; NEXT="$(second_line "$FAKE_PATH" "$TOOL" --version)"
  check "fake $TOOL on PATH: reported with the first line of its --version ($EXPECTED)" 'has_line "$TOOL" "$EXPECTED" && no_line "$NEXT"'
done
check "PLAYWRIGHT_BROWSERS_PATH set: reported with its directory" 'has_line PLAYWRIGHT_BROWSERS_PATH "$T/pw"'
PW_EXPECTED="$(ls -1 "$T/pw" | sort | tr '\n' ' ')"
check "playwright browsers lists the entries of PLAYWRIGHT_BROWSERS_PATH ($PW_EXPECTED)" '[ "$(pw_entries)" = "$PW_EXPECTED" ]'
check "offline: curl is never invoked" '[ ! -s "$T/net-offline/calls" ]'

# AVE-REQ-094 AC-1: Git lines of a fixture repository with three worktrees on a known branch; the
# probe runs as its copy in the fixture, started from the temp directory outside the fixture.
GITFIX="$T/gitfix"
git_fixture() {
  git -c init.defaultBranch=probe-main init -q "$GITFIX/main" &&
    git -C "$GITFIX/main" -c user.name=probe-test -c user.email=probe-test@example.invalid \
      -c commit.gpgsign=false commit -q --allow-empty -m fixture &&
    git -C "$GITFIX/main" checkout -q -b probe-fixture-branch &&
    git -C "$GITFIX/main" worktree add -q -b probe-wt-a "$GITFIX/wt-a" &&
    git -C "$GITFIX/main" worktree add -q -b probe-wt-b "$GITFIX/wt-b" &&
    mkdir -p "$GITFIX/main/scripts" && cp "$PROBE" "$GITFIX/main/scripts/probe-environment.sh"
}
git_fixture >/dev/null 2>&1; FIX_CODE=$?
FIX_WT="$(cd "$GITFIX/main" 2>/dev/null && git worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
FIX_BRANCH="$(cd "$GITFIX/main" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$GITFIX/main/scripts/probe-environment.sh" --offline 2>&1)"; CODE=$?
check "git fixture: three worktrees on branch probe-fixture-branch" '[ "$FIX_CODE" = 0 ] && [ "$FIX_WT" = "3 listed" ] && [ "$FIX_BRANCH" = probe-fixture-branch ]'
check "git fixture: worktrees equals git worktree list | wc -l ($FIX_WT)" '[ "$CODE" = 0 ] && has_line worktrees "$FIX_WT"'
check "git fixture: branch equals git rev-parse --abbrev-ref HEAD ($FIX_BRANCH)" 'has_line branch "$FIX_BRANCH"'
# AVE-REQ-094 AC-1: the root is the directory above the probe's own, whatever CDPATH the environment
# exports. The fixture's probe starts through a relative path inside the fixture while CDPATH names
# a directory that holds a scripts directory of its own.
mkdir -p "$T/cdpath-decoy/scripts"
FIX_DISK_BEFORE="$(disk_free "$GITFIX/main")"
OUT="$(cd "$GITFIX/main" && PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" CDPATH="$T/cdpath-decoy" bash scripts/probe-environment.sh --offline 2>&1)"; CODE=$?
FIX_DISK_AFTER="$(disk_free "$GITFIX/main")"
check "CDPATH exported, relative start: worktrees and branch are the fixture's" '[ "$CODE" = 0 ] && has_line worktrees "$FIX_WT" && has_line branch "$FIX_BRANCH"'
check "CDPATH exported, relative start: writability names the fixture root on one line" 'has_line "repository writable" "yes ($GITFIX/main)" && [ "$(lines_of "repository writable")" = 1 ]'
check "CDPATH exported, relative start: disk measures the fixture root ($FIX_DISK_BEFORE)" '[ -n "$FIX_DISK_BEFORE" ] && { has_line "disk (repository)" "$FIX_DISK_BEFORE" || has_line "disk (repository)" "$FIX_DISK_AFTER"; }'
# A probe in a directory whose name starts with a dash: the name is no option of dirname or cd.
mkdir -p "$T/-dash/scripts" && cp "$PROBE" "$T/-dash/scripts/probe-environment.sh"
OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" bash -- -dash/scripts/probe-environment.sh --offline 2>&1)"; CODE=$?
check "the probe below a directory named -dash: the root is that directory" '[ "$CODE" = 0 ] && has_line "repository writable" "yes ($T/-dash)"'

# AVE-REQ-094 AC-1: network. Without curl the probe says so.
NOCURL_PATH="$(path_without nvidia-smi claude chromium chromium-browser google-chrome curl)"
OUT="$(PATH="$NOCURL_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" "$PROBE" 2>&1)"; CODE=$?
check "curl absent: network probes report curl not installed" '[ "$CODE" = 0 ] && has_line probes "curl not installed"'

# net_run <name> <script line>... — runs the probe online with a fake curl that answers from the
# script lines and the product credential variables set, then checks each host line against the
# script (`HTTP <code>` for a code, `unreachable` for a failure) and every recorded request.
net_run() {
  local name="$1" rec result
  shift
  NET="$T/net-$name"
  make_fake_curl "$NET" "$@"
  OUT="$(PATH="$NET/bin:$NOCURL_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" ANTHROPIC_API_KEY="$SECRET" \
    OPENAI_API_KEY="$SECRET" OPENAI_BASE_URL="$SECRET" HF_TOKEN="$SECRET" "$PROBE" 2>&1)"; CODE=$?
  check "$name: probe exits 0" '[ "$CODE" = 0 ]'
  check "$name: the four provider variables read set" 'has "^ANTHROPIC_API_KEY +set$" && has "^OPENAI_API_KEY +set$" && has "^OPENAI_BASE_URL +set$" && has "^HF_TOKEN +set$"'
  for rec in "$@"; do
    KEY="${rec%% *}"; result="${rec#* }"; result="${result%% *}"
    case "$result" in fail:*) WANT="unreachable" ;; *) WANT="HTTP $result" ;; esac
    check "$name: $KEY reads '$WANT' on one line (fake curl: $result)" 'has_line "$KEY" "$WANT" && [ "$(lines_of "$KEY")" = 1 ]'
    check "$name: $KEY is requested" 'grep -qF "CALL url=$KEY " "$NET/calls"'
  done
  check "$name: every request fetches no body (-I/--head, a bounded -r/--range or --max-filesize)" '[ -s "$NET/calls" ] && [ ! -s "$NET/violations" ]'
  [ -s "$NET/violations" ] && sed 's/^/         /' "$NET/violations"
  check "$name: every request has a time limit of at most 10 s (-m/--max-time)" 'time_limits_ok "$NET/calls"'
  check "$name: only the seven hosts are requested" '[ -s "$NET/calls" ] && ! grep -q "^UNEXPECTED " "$NET/calls"'
  check "$name: no credential value reaches curl" '! grep -qF "$SECRET" "$NET/calls" && ! printf "%s\n" "$OUT" | quiet -F "$SECRET"'
}
# AVE-REQ-094 AC-1: each of the seven hosts answers in one scenario and gets no response in the
# other; a 4xx or 5xx still proves that the host answers; pypi.org/simple/ and github.com/ answer
# with a large body.
NET_1=("pypi.org/simple/ 200 48000000" "files.pythonhosted.org/ fail:28" "registry.npmjs.org/ 301"
  "github.com/ 405 600000" "huggingface.co/api/models?limit=1 429" "api.anthropic.com/ 404" "api.openai.com/ fail:6")
NET_2=("pypi.org/simple/ fail:7" "files.pythonhosted.org/ 503" "registry.npmjs.org/ fail:28"
  "github.com/ fail:35" "huggingface.co/api/models?limit=1 fail:56" "api.anthropic.com/ fail:60" "api.openai.com/ 421")
net_run network-1 "${NET_1[@]}"
net_run network-2 "${NET_2[@]}"
# The two scripts themselves: seven hosts, each with a code in one and a failure in the other.
BOTH_STATES="$(printf '%s\n' "${NET_1[@]}" "${NET_2[@]}" | awk '
  { state = ($2 ~ /^fail:/) ? "fail" : "code"; seen[$1 " " state]++; hosts[$1] = 1 }
  END { for (h in hosts) { n++; if (seen[h " code"] != 1 || seen[h " fail"] != 1) bad++ } print n + 0, bad + 0 }')"
check "the two scenarios hold seven hosts, each answering once and failing once" '[ "$BOTH_STATES" = "7 0" ]'
# An exported shell option that drops unmatched patterns leaves the URL with a question mark in the
# list of hosts.
make_fake_curl "$T/net-nullglob" "pypi.org/simple/ 200" "files.pythonhosted.org/ 200" "registry.npmjs.org/ 200" \
  "github.com/ 200" "huggingface.co/api/models?limit=1 204" "api.anthropic.com/ 200" "api.openai.com/ 200"
OUT="$(PATH="$T/net-nullglob/bin:$NOCURL_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" env BASHOPTS=nullglob "$PROBE" 2>&1)"; CODE=$?
check "BASHOPTS=nullglob exported: huggingface.co/api/models?limit=1 is requested and reported, seven requests in all" '[ "$CODE" = 0 ] && has_line "huggingface.co/api/models?limit=1" "HTTP 204" && [ "$(grep -c "^CALL " "$T/net-nullglob/calls")" = 7 ] && ! grep -q "^UNEXPECTED " "$T/net-nullglob/calls"'

"$PROBE" --bogus >/dev/null 2>&1; CODE=$?
check "unknown option exits 2" '[ "$CODE" = 2 ]'
OUT="$("$PROBE" --help 2>&1)"; CODE=$?
check "--help exits 0 and prints the header comment from its first line through its last, and no line of code" '[ "$CODE" = 0 ] && has "^scripts/probe-environment\.sh " && has "^Usage: +\./scripts/probe-environment\.sh \[--offline\]" && has "^Not part of verify\.sh" && ! has "pipefail" && ! has "^#"'

echo "PROBE TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
