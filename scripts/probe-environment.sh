#!/usr/bin/env bash
# scripts/probe-environment.sh — re-measures the shell-observable capabilities recorded in
# docs/ENVIRONMENT_CAPABILITIES.md (AVE-REQ-094 AC-1): CPU, memory, disk, accelerators with a
# device verdict, media tools and hardware codecs, language toolchains, browsers, containers, Git
# worktrees, the session's Claude Code version, OS user and repository writability, network
# reachability of the hosts the project uses, and which product credential variables are set.
#
# Usage:  ./scripts/probe-environment.sh [--offline]     (--offline skips the network probes)
# Read-only: prints a report and changes nothing. Never prints a credential value, only whether a
# variable is set. The other Claude Code capabilities (workflow tool, subagents, models, hooks,
# permission mode) are not visible to a shell; docs/ENVIRONMENT_CAPABILITIES.md records them.
# Test inputs: AVE_PROBE_DEV_DIR replaces /dev (device nodes), AVE_PROBE_PROC_DIR replaces /proc
# (meminfo, cpuinfo) and AVE_PROBE_ROOT replaces the repository root that the disk, Git and
# writability lines measure.
# Not part of verify.sh: network results depend on the environment's policy.
set -uo pipefail

ROOT="${AVE_PROBE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DEV_DIR="${AVE_PROBE_DEV_DIR:-/dev}"
PROC_DIR="${AVE_PROBE_PROC_DIR:-/proc}"
OFFLINE=0
case "${1:-}" in
  "") ;;
  --offline) OFFLINE=1 ;;
  -h | --help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) printf 'Usage: ./scripts/probe-environment.sh [--offline]\n' >&2; exit 2 ;;
esac

section() { printf '\n## %s\n' "$1"; }
item() { printf '%-28s %s\n' "$1" "$2"; }
first() { "$@" 2>/dev/null | head -n 1; }
have() { command -v "$1" >/dev/null 2>&1; }
version() { if have "$1"; then item "$1" "$(first "$@")"; else item "$1" "not installed"; fi; }

printf '# Environment probe — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

section "Platform and resources"
item "kernel" "$(uname -srm)"
[ -r /etc/os-release ] && item "os" "$(. /etc/os-release && printf '%s' "$PRETTY_NAME")"
item "cpus" "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
# arm64 kernels list no "model name" in cpuinfo: lscpu names the model there.
cpu_model="$(grep -m1 'model name' "$PROC_DIR/cpuinfo" 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
[ -n "$cpu_model" ] || cpu_model="$(lscpu 2>/dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -n 1)"
item "cpu model" "${cpu_model:-unknown}"
item "memory" "$(awk '/MemTotal/ { printf "%.1f GiB", $2 / 1048576 }' "$PROC_DIR/meminfo" 2>/dev/null)"
# The disk and Git lines measure the repository, whichever directory the probe starts in.
item "disk (repository)" "$(df -h "$ROOT" 2>/dev/null | awk 'NR == 2 { print $4 " free of " $2 }')"

section "Accelerators"
gpu=""
if have nvidia-smi; then
  # nvidia-smi counts only when it exits 0 and lists a GPU as "<name>, <memory>": without a driver
  # or a device it prints a diagnostic and fails, and a diagnostic is no device.
  if smi="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null)"; then
    gpu="$(printf '%s\n' "$smi" | grep -m1 -E '^[^,]*[^,[:space:]][^,]*,[[:space:]]*[^,[:space:]][^,]*$')"
  fi
  item "nvidia-smi" "${gpu:-no GPU reported}"
else
  item "nvidia-smi" "not installed"
fi
nvidia_nodes="$(find "$DEV_DIR" -maxdepth 1 -name 'nvidia*' 2>/dev/null | sort | tr '\n' ' ')"
dri_nodes="$(find "$DEV_DIR/dri" -mindepth 1 -maxdepth 1 2>/dev/null | sort | tr '\n' ' ')"
item "/dev/nvidia* devices" "${nvidia_nodes:-none}"
item "/dev/dri devices" "${dri_nodes:-none}"
# The verdict counts devices only (a GPU row of nvidia-smi, device nodes): FFmpeg's built-in
# hardware encoders (Media tools) need one.
evidence="$(printf '%s' "${gpu:+$gpu }$nvidia_nodes$dri_nodes" | sed 's/ *$//')"
if [ -n "$evidence" ]; then
  printf 'accelerator: present (%s)\n' "$evidence"
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
  for url in https://pypi.org/simple/ https://files.pythonhosted.org/ https://registry.npmjs.org/ \
    https://github.com/ https://huggingface.co/api/models?limit=1 https://api.anthropic.com/ \
    https://api.openai.com/; do
    code="$(curl -sS -o /dev/null -I -m 10 -w '%{http_code}' "$url" 2>/dev/null)"
    case "$code" in
      [1-9][0-9][0-9]) item "${url#https://}" "HTTP $code" ;;
      *) item "${url#https://}" "unreachable" ;;
    esac
  done
fi
