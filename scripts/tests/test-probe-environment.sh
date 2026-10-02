#!/usr/bin/env bash
# scripts/tests/test-probe-environment.sh — tests of scripts/probe-environment.sh: it runs offline,
# reports every section, measures CPUs, memory and disk, gives an accelerator verdict from device
# nodes alone, reports the Claude Code version, OS user and repository writability, and never
# prints a credential value. Device nodes come from a temp directory (AVE_PROBE_DEV_DIR) and
# `nvidia-smi` and `claude` are hidden from PATH, so the results hold on any host. Exit 0 when
# every check passes.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$W/../.." && pwd)"
PROBE="$W/../probe-environment.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/probe-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
has() { printf '%s\n' "$OUT" | grep -Eq -- "$1"; }

# path_without <command>... — prints PATH with the named commands hidden: a directory that holds
# one of them is replaced by a mirror of its other entries.
path_without() {
  local dir entry name hide cmd mirror out="" n=0
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    hide=0
    for cmd in "$@"; do [ -e "$dir/$cmd" ] && hide=1; done
    if [ "$hide" -eq 1 ]; then
      n=$((n + 1)); mirror="$T/path-mirror-$n"; mkdir -p "$mirror"
      for entry in "$dir"/*; do
        name="${entry##*/}"
        for cmd in "$@"; do [ "$name" = "$cmd" ] && continue 2; done
        ln -s "$entry" "$mirror/$name"
      done
      dir="$mirror"
    fi
    out="${out:+$out:}$dir"
  done
  printf '%s\n' "$out"
}
BARE_PATH="$(path_without nvidia-smi claude)"
mkdir -p "$T/dev-none" "$T/dev-gpu" "$T/bin"
: > "$T/dev-gpu/nvidia0"
printf '#!/bin/sh\nprintf "9.9.9 (Claude Code)\\n"\n' > "$T/bin/claude"; chmod +x "$T/bin/claude"

SECRET="probe-test-secret-$$-value"
OUT="$(PATH="$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-none" HF_TOKEN="$SECRET" ANTHROPIC_API_KEY="" "$PROBE" --offline 2>&1)"; CODE=$?
# AVE-REQ-094 AC-1
check "offline probe exits 0" '[ "$CODE" = 0 ]'
for heading in "Platform and resources" "Accelerators" "Media tools" "Toolchains" "Browsers" "Git" \
  "Claude Code and session" "Product credential variables" "Network"; do
  check "reports section: $heading" 'printf "%s\n" "$OUT" | grep -q "^## $heading"'
done
# AVE-REQ-094 AC-1: resources are measured values.
check "cpus equals getconf _NPROCESSORS_ONLN ($(getconf _NPROCESSORS_ONLN))" 'has "^cpus +$(getconf _NPROCESSORS_ONLN)\$"'
check "memory is a GiB value" 'has "^memory +[0-9]+\.[0-9] GiB$"'
check "disk reports free and total space" 'has "^disk \(repository\) +[0-9.,]+[KMGTPE]? free of [0-9.,]+[KMGTPE]?$"'
# AVE-REQ-094 AC-1: no device and no nvidia-smi means no accelerator, whatever FFmpeg lists.
check "no device, no nvidia-smi: nvidia-smi not installed" 'has "^nvidia-smi +not installed$"'
check "no device, no nvidia-smi: accelerator: none (no device)" 'has "^accelerator: none \(no device\)$"'
check "exactly one accelerator verdict" '[ "$(printf "%s\n" "$OUT" | grep -c "^accelerator:")" = 1 ]'
check "no line claims a GPU" '! printf "%s\n" "$OUT" | grep -Eqi "gpu (available|present|found)"'
# AVE-REQ-094 AC-1: the shell-observable part of the Claude Code and permission rows.
check "claude absent from PATH: not installed" 'has "^claude +not installed$"'
check "os user is the user running the probe" 'has "^os user +$(id -un) \(uid $(id -u)\)$"'
WRITABLE=no; [ -w "$REPO" ] && WRITABLE=yes
check "repository writability matches the file system ($WRITABLE)" 'printf "%s\n" "$OUT" | grep -qxF "$(printf "%-28s %s" "repository writable" "$WRITABLE ($REPO)")"'
check "network probes skipped offline" 'has "skipped \(--offline\)"'
check "a set credential is reported as set" 'has "^HF_TOKEN +set$"'
check "an empty credential is reported as unset" 'has "^ANTHROPIC_API_KEY +unset$"'
check "no credential value is printed" '! printf "%s\n" "$OUT" | grep -qF "$SECRET"'
# AVE-REQ-098 AC-3: every credential the probe reports is documented in .env.example.
NAMES="$(printf '%s\n' "$OUT" | awk '/^## Product credential variables/ { on = 1; next } /^## / { on = 0 } on && NF { print $1 }')"
UNLISTED=""; for name in $NAMES; do grep -q "^$name=" "$REPO/.env.example" 2>/dev/null || UNLISTED="$UNLISTED $name"; done
check "every reported credential variable is listed in .env.example (missing:${UNLISTED:- none})" '[ -n "$NAMES" ] && [ -z "$UNLISTED" ]'

OUT="$(PATH="$T/bin:$BARE_PATH" AVE_PROBE_DEV_DIR="$T/dev-gpu" "$PROBE" --offline 2>&1)"; CODE=$?
# AVE-REQ-094 AC-1
check "device node present: accelerator verdict names it" '[ "$CODE" = 0 ] && has "^accelerator: present \($T/dev-gpu/nvidia0\)$"'
check "claude on PATH: its version is reported" 'has "^claude +9\.9\.9 \(Claude Code\)$"'

"$PROBE" --bogus >/dev/null 2>&1; CODE=$?
check "unknown option exits 2" '[ "$CODE" = 2 ]'

echo "PROBE TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
