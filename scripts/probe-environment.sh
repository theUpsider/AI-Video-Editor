#!/usr/bin/env bash
# scripts/probe-environment.sh — re-measures the shell-observable capabilities recorded in
# docs/ENVIRONMENT_CAPABILITIES.md (AVE-REQ-094 AC-1): CPU and memory with their cgroup limits,
# disk, accelerators with a device verdict, media tools and hardware codecs, language toolchains,
# browsers, containers, Git worktrees, the session's Claude Code version, OS user and repository
# writability, network reachability of the hosts the project uses, and which product credential
# variables are set.
#
# Usage:  ./scripts/probe-environment.sh [--offline]     (--offline skips the network probes)
# Read-only: prints a report and changes nothing. Never prints a credential value, only whether a
# variable is set. The other Claude Code capabilities (workflow tool, subagents, models, hooks,
# permission mode) are not visible to a shell; docs/ENVIRONMENT_CAPABILITIES.md records them.
# Test inputs: AVE_PROBE_DEV_DIR replaces /dev (device nodes), AVE_PROBE_PROC_DIR replaces /proc
# (meminfo, cpuinfo), AVE_PROBE_CGROUP_DIR replaces /sys/fs/cgroup (cpu.max, memory.max),
# AVE_PROBE_ROOT replaces the repository root that the disk, Git and writability lines measure,
# and AVE_PROBE_SMI_TIMEOUT replaces the 10 s limit of the nvidia-smi query. The accelerator
# verdict opens each named character device for reading and for writing through dd, which creates
# no path and sends the device nothing.
# Not part of verify.sh: network results depend on the environment's policy.
set -uo pipefail
# Four settings hold whatever shell options the environment exports (SHELLOPTS, BASHOPTS): a
# command that fails does not end the report, and for the device walk, which reads directories
# through pathname expansion, expansion is on, an unmatched pattern is no error and hidden entries
# are matched.
set +e +f
shopt -u failglob
shopt -s dotglob

# CDPATH is emptied for this cd: with a search path the shell would look for the directory elsewhere
# and print it a second time.
ROOT="${AVE_PROBE_ROOT:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
DEV_DIR="${AVE_PROBE_DEV_DIR:-/dev}"
PROC_DIR="${AVE_PROBE_PROC_DIR:-/proc}"
CGROUP_DIR="${AVE_PROBE_CGROUP_DIR:-/sys/fs/cgroup}"
OFFLINE=0
case "${1:-}" in
  "") ;;
  --offline) OFFLINE=1 ;;
  -h | --help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) printf 'Usage: ./scripts/probe-environment.sh [--offline]\n' >&2; exit 2 ;;
esac

section() { printf '\n## %s\n' "$1"; }
item() { printf '%-28s %s\n' "$1" "$2"; }
first() { "$@" 2>/dev/null | head -n 1; }
have() { command -v "$1" >/dev/null 2>&1; }
version() { if have "$1"; then item "$1" "$(first "$@")"; else item "$1" "not installed"; fi; }
# is_number <string> — the string is one or more of the digits 0 to 9 and holds nothing else.
is_number() { case "$1" in "" | *[!0123456789]*) return 1 ;; esac; }

# cgroup_text <file name> — sets $content to the text of that file of the cgroup directory without
# its line end. read -d '' succeeds only when it meets a NUL byte and fails at the end of a text
# with the whole text read: a file with a NUL byte, an empty file and a file that cannot be read
# leave $content empty, which is none of the forms the two lines admit.
cgroup_text() {
  content=""
  if { IFS= read -r -d '' content < "$CGROUP_DIR/$1"; } 2>/dev/null; then content=""; fi
  content="${content%$'\n'}"
}
# cpu_quota, memory_limit — the limits of the cgroup mounted at /sys/fs/cgroup (cgroup v2), which
# inside a container with a cgroup namespace of its own is the container's cgroup: "none" for a
# missing file and for the value max, the figure for a number, "unknown" for any other content.
# The cgroup of a process below the root of the mount and a cgroup v1 hierarchy stay unread.
cpu_quota() {
  local content quota period
  [ -e "$CGROUP_DIR/cpu.max" ] || { printf 'none'; return; }
  cgroup_text cpu.max
  quota="${content%% *}"
  period="${content#* }"
  # The content is a quota or max, one space and a period above zero.
  if [ "$quota $period" != "$content" ] || ! is_number "$period" || [ -z "${period//0/}" ]; then
    printf 'unknown'
  elif [ "$quota" = max ]; then
    printf 'none'
  elif is_number "$quota"; then
    printf '%s cpus (cpu.max %s)' "$(awk -v q="$quota" -v p="$period" 'BEGIN { printf "%.2f", q / p }')" "$content"
  else
    printf 'unknown'
  fi
}
memory_limit() {
  local content
  [ -e "$CGROUP_DIR/memory.max" ] || { printf 'none'; return; }
  cgroup_text memory.max
  if [ "$content" = max ]; then
    printf 'none'
  elif is_number "$content"; then
    printf '%s GiB (memory.max %s)' "$(awk -v b="$content" 'BEGIN { printf "%.1f", b / 1073741824 }')" "$content"
  else
    printf 'unknown'
  fi
}

printf '# Environment probe — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

section "Platform and resources"
item "kernel" "$(uname -srm)"
[ -r /etc/os-release ] && item "os" "$(. /etc/os-release && printf '%s' "$PRETTY_NAME")"
# The cpus and memory lines are the kernel's totals; a quota of the container stands on the two
# cgroup lines.
item "cpus" "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
item "cpu quota (cgroup v2)" "$(cpu_quota)"
# arm64 kernels list no "model name" in cpuinfo: lscpu names the model there, or prints "-".
cpu_model="$(grep -m1 'model name' "$PROC_DIR/cpuinfo" 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
[ -n "$cpu_model" ] || cpu_model="$(lscpu 2>/dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -n 1)"
[ "$cpu_model" != "-" ] || cpu_model=""
item "cpu model" "${cpu_model:-unknown}"
item "memory" "$(awk '/MemTotal/ { printf "%.1f GiB", $2 / 1048576 }' "$PROC_DIR/meminfo" 2>/dev/null)"
item "memory limit (cgroup v2)" "$(memory_limit)"
# The disk and Git lines measure the repository, whichever directory the probe starts in.
item "disk (repository)" "$(df -h "$ROOT" 2>/dev/null | awk 'NR == 2 { print $4 " free of " $2 }')"

section "Accelerators"
gpu=""
# The time limit of the query: AVE_PROBE_SMI_TIMEOUT counts only as a positive whole number of
# seconds (digits alone, one of them above 0), and every other value leaves the 10 s (timeout
# reads 0 as no limit).
smi_limit=10
if is_number "${AVE_PROBE_SMI_TIMEOUT:-}" && [ -n "${AVE_PROBE_SMI_TIMEOUT//0/}" ]; then
  smi_limit="$AVE_PROBE_SMI_TIMEOUT"
fi
# smi_query — the GPU list of nvidia-smi under a time limit: a driver query that hangs is ended
# (killed 2 s after the limit when it ignores the signal) and counts as a failure.
smi_query() {
  timeout -k 2 "$smi_limit" nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
}
if ! have nvidia-smi; then
  item "nvidia-smi" "not installed"
elif ! have timeout; then
  # Without a time limit the query could block the probe: it is left out and reports no GPU.
  item "nvidia-smi" "no GPU reported (timeout unavailable)"
else
  # nvidia-smi counts only when it exits 0 and lists a GPU as "<name>, <memory> MiB" on its
  # standard output: without a driver or a device it prints a diagnostic and fails, and a line
  # without a memory figure is a diagnostic or a header, no device.
  if smi="$(smi_query 2>/dev/null)"; then
    gpu="$(printf '%s\n' "$smi" | grep -m1 -E '^.*[^,[:space:]].*,[[:space:]]*[0-9]+ MiB$')"
  fi
  item "nvidia-smi" "${gpu:-no GPU reported}"
fi
# One walk over the device directory gives the two list lines and the verdict. Listed: every entry
# named nvidia* and every entry of dri. Counted: a per-GPU node only, which is a character device
# (directly or behind symbolic links) whose whole name is nvidia<N> or dri/renderD<N>. Driver
# control nodes (nvidiactl, nvidia-uvm, nvidia-modeset, nvidia-caps), display-only nodes
# (dri/card<N>), directories (dri/by-path), regular files and names with a prefix or a suffix exist
# on hosts without a GPU this environment can compute on.
#
# opens <path> — this user can open the path for reading and for writing. dd opens its input
# read-only and, with conv=nocreat,notrunc, its output write-only without creating or truncating
# it; count=0 transfers nothing. A path that is gone by then fails the open and stays gone.
opens() { dd if="$1" of="$1" count=0 conv=nocreat,notrunc status=none 2>/dev/null; }
# Without a dd that takes these operands (GNU coreutils) no node is opened and the verdict says so.
# The operands are tried on /dev/null, which every user can open.
open_test=yes
opens /dev/null || open_test=no
open_nodes="" closed_nodes="" untested_nodes=""
# scan <directory> <listed prefix> <counted prefix> — walks the entries of the directory once. A
# name is judged as one string, whatever it holds (a line feed, a space). $listed receives the path
# of every entry whose name starts with the listed prefix, in the shell's quoted form (printf %q),
# so each entry is one word of the list line. A counted node goes in the same form to $open_nodes,
# $closed_nodes or $untested_nodes.
scan() {
  local dir="$1" path name quoted
  listed=""
  for path in "$dir"/*; do
    # A pattern without a match stays as written and names no entry.
    [ -e "$path" ] || [ -L "$path" ] || continue
    name="${path##*/}"
    [ "${name:0:${#2}}" = "$2" ] || continue
    printf -v quoted '%q' "$path"
    listed="$listed${listed:+ }$quoted"
    [ "${name:0:${#3}}" = "$3" ] || continue
    is_number "${name:${#3}}" || continue
    [ -c "$path" ] || continue
    if [ "$open_test" = no ]; then
      untested_nodes="$untested_nodes$quoted "
    elif opens "$path"; then
      open_nodes="$open_nodes$quoted "
    else
      closed_nodes="$closed_nodes$quoted "
    fi
  done
}
scan "$DEV_DIR" nvidia nvidia
item "/dev/nvidia* devices" "${listed:-none}"
scan "$DEV_DIR/dri" "" renderD
item "/dev/dri devices" "${listed:-none}"
# The verdict counts GPU devices only (a GPU row of nvidia-smi, per-GPU device nodes that open):
# FFmpeg's built-in hardware encoders (Media tools) need one.
evidence="$(printf '%s' "${gpu:+$gpu }$open_nodes" | sed 's/ *$//')"
if [ -n "$evidence" ]; then
  printf 'accelerator: present (%s)\n' "$evidence"
elif [ -n "$untested_nodes" ]; then
  printf 'accelerator: unknown (open test unavailable for %s)\n' "${untested_nodes% }"
elif [ -n "$closed_nodes" ]; then
  printf 'accelerator: none (no access to %s)\n' "${closed_nodes% }"
else
  printf 'accelerator: none (no device)\n'
fi

section "Media tools"
version ffmpeg -hide_banner -version
version ffprobe -hide_banner -version
if have ffmpeg; then
  # Built-in support says nothing about a device: only the Accelerators section above does.
  item "hwaccels (built in)" "$(ffmpeg -hide_banner -hwaccels 2>/dev/null | tail -n +2 | tr -s ' \n' ' ')"
  item "hw encoders (built in)" "$(ffmpeg -hide_banner -encoders 2>/dev/null |
    grep -Eo '(h264|hevc|av1)_(nvenc|vaapi|qsv|amf|videotoolbox)' | sort -u | tr '\n' ' ')"
  item "libx264 / aac" "$(ffmpeg -hide_banner -encoders 2>/dev/null |
    grep -Eo ' (libx264|aac) ' | tr -d ' ' | sort -u | tr '\n' ' ')"
  item "filters (rubberband, soxr)" "$(ffmpeg -hide_banner -filters 2>/dev/null |
    grep -Eo ' rubberband ' | tr -d ' ')$(ffmpeg -hide_banner -h filter=aresample 2>/dev/null |
    grep -q soxr && printf ' soxr')"
fi

section "Toolchains"
version python3 --version
version uv --version
version node --version
version pnpm --version
version git --version
version docker --version
if have docker; then
  item "docker daemon" "$(docker info >/dev/null 2>&1 && echo reachable || echo unreachable)"
fi

section "Browsers"
item "PLAYWRIGHT_BROWSERS_PATH" "${PLAYWRIGHT_BROWSERS_PATH:-unset}"
for browser in chromium chromium-browser google-chrome; do
  have "$browser" && item "$browser" "$(first "$browser" --version)"
done
[ -d "${PLAYWRIGHT_BROWSERS_PATH:-/nonexistent}" ] &&
  item "playwright browsers" "$(find "$PLAYWRIGHT_BROWSERS_PATH" -mindepth 1 -maxdepth 1 \
    -exec basename {} \; | sort | tr '\n' ' ')"

section "Git"
item "worktrees" "$(git -C "$ROOT" worktree list 2>/dev/null | wc -l | tr -d ' ') listed"
item "branch" "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"

section "Claude Code and session"
# The development container holds no `claude` command: there the version comes from the host.
version claude --version
item "os user" "$(id -un 2>/dev/null || echo unknown) (uid $(id -u 2>/dev/null || echo unknown))"
if [ -w "$ROOT" ]; then item "repository writable" "yes ($ROOT)"; else item "repository writable" "no ($ROOT)"; fi

section "Product credential variables (set or unset; values are never printed)"
# Only the product's own variables: the developer session's credentials are never product
# credentials (docs/ENVIRONMENT_CAPABILITIES.md, Credentials).
for name in ANTHROPIC_API_KEY OPENAI_API_KEY OPENAI_BASE_URL HF_TOKEN; do
  if [ -n "${!name:-}" ]; then item "$name" "set"; else item "$name" "unset"; fi
done

section "Network"
if [ "$OFFLINE" -eq 1 ]; then
  item "probes" "skipped (--offline)"
elif ! have curl; then
  item "probes" "curl not installed"
else
  # One HEAD request per host (-I) with a 10 s limit: any status code proves that the host answers,
  # and no body is downloaded, so the verdict does not depend on bandwidth. curl writes the code
  # 000 when no response arrives (refused, unresolved, TLS failure, the time limit): unreachable.
  # The URL with a question mark is quoted: unquoted it is a pattern the shell could expand.
  for url in https://pypi.org/simple/ https://files.pythonhosted.org/ https://registry.npmjs.org/ \
    https://github.com/ 'https://huggingface.co/api/models?limit=1' https://api.anthropic.com/ \
    https://api.openai.com/; do
    code="$(curl -sS -o /dev/null -I -m 10 -w '%{http_code}' "$url" 2>/dev/null)"
    case "$code" in
      [1-9][0-9][0-9]) item "${url#https://}" "HTTP $code" ;;
      *) item "${url#https://}" "unreachable" ;;
    esac
  done
fi
