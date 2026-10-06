#!/usr/bin/env bash
# scripts/tests/test-verify-tiers.sh — tier selection of scripts/verify.sh (fast ⊂ media ⊂ release),
# its exit codes and its heavy-media lock, in a fixture project whose component step file registers
# one marker step per tier plus steps that report the lock state. Needs git, python3, flock and
# timeout. Every run uses a lock file in the suite's temp dir, so the suite never waits for a real
# media run. Exit 0 when every check passes.
# Checks are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/verify-tiers.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
for tool in git python3 flock timeout; do
  command -v "$tool" >/dev/null 2>&1 || { echo "test-verify-tiers.sh: $tool is required" >&2; exit 2; }
done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export AVE_HEAVY_LOCK="$T/heavy-media.lock"
unset AVE_HEAVY_LOCK_HELD
R="$T/project"
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
run() {  # run [args...] -> CODE, OUT (combined output); VERIFY_TIER comes from the caller
  OUT="$(cd "$R" && ./scripts/verify.sh "$@" 2>&1)"; CODE=$?
}
# run_bounded [args...] — run with a 60 s limit, for runs that must not wait for the lock; the run
# gets no copy of the suite's lock descriptor (8).
run_bounded() {
  OUT="$(cd "$R" && timeout 60 ./scripts/verify.sh "$@" 2>&1 8>&-)"; CODE=$?
}
ran() { printf '%s\n' "$OUT" | quiet -x "<== PASS: $1 step.*"; }
passed() { printf '%s\n' "$OUT" | quiet -x "<== PASS: $1 (.*"; }
waited() { printf '%s\n' "$OUT" | quiet "^verify.sh: waiting for the heavy-media lock"; }
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

"$W/make-fixture.sh" "$R" >/dev/null
cat > "$R/scripts/verify.d/20-backend.sh" <<'STEPS'
# fixture component step file: one marker step per tier, and the lock state each tier sees
# shellcheck shell=bash
# passes when this run holds the heavy-media lock: a child process finds AVE_HEAVY_LOCK_HELD=1 in
# its environment, and a new open of the lock file cannot take the lock
LOCK_HELD='[ "${AVE_HEAVY_LOCK_HELD:-}" = 1 ] && ! flock -n "${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}" true'
fast_step "fast step" true
fast_step "lock state" sh -c 'echo "lock state: AVE_HEAVY_LOCK_HELD=${AVE_HEAVY_LOCK_HELD:-unset}"'
media_step "media step" true
media_step "media tier holds the lock" sh -c "$LOCK_HELD"
# with LEAVE_PROCESS=<file>: leaves a background process behind and writes its PID to <file>
media_step "media background process" sh -c '[ -z "${LEAVE_PROCESS:-}" ] ||
  { sleep 300 </dev/null >/dev/null 2>&1 & echo "$!" >"$LEAVE_PROCESS"; }'
release_step "release step" true
release_step "release tier holds the lock" sh -c "$LOCK_HELD"
STEPS
(cd "$R" && git init -q && git config user.email t@t && git config user.name t && git add -A && git commit -qm init)

# AVE-REQ-097 AC-1
echo "## tier membership"
run
check "default tier is fast" '[ "$CODE" = 0 ] && ran fast && ! ran media && ! ran release && printf "%s" "$OUT" | quiet "PASS — tier fast"'
run --tier media
check "--tier media adds the media steps" '[ "$CODE" = 0 ] && ran fast && ran media && ! ran release'
run --tier=release
check "--tier=release runs every tier" '[ "$CODE" = 0 ] && ran fast && ran media && ran release'
VERIFY_TIER=media run
check "VERIFY_TIER selects the tier" '[ "$CODE" = 0 ] && ran media && ! ran release'
VERIFY_TIER=media run --tier fast
check "--tier overrides VERIFY_TIER" '[ "$CODE" = 0 ] && ! ran media'

# AVE-REQ-097 AC-1
echo "## usage errors"
run --tier full
check "unknown tier exits 2" '[ "$CODE" = 2 ] && printf "%s" "$OUT" | quiet "unknown tier: full"'
run --tier
check "missing tier value exits 2" '[ "$CODE" = 2 ]'
run --fast
check "unexpected argument exits 2" '[ "$CODE" = 2 ] && printf "%s" "$OUT" | quiet "unexpected argument"'

# AVE-REQ-096 AC-4
echo "## one heavy media job at a time: the heavy-media lock"
run --tier media
check "media tier steps run while the run holds the lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && ! waited'
run --tier release
check "release tier steps run while the run holds the lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && passed "release tier holds the lock"'
exec 8>>"$AVE_HEAVY_LOCK"
flock -n 8 || { echo "test-verify-tiers.sh: cannot take $AVE_HEAVY_LOCK" >&2; exit 2; }
# The suite now holds the lock, like a media run of another agent.
run_bounded
check "fast tier takes no lock (runs while another process holds it)" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet -x "lock state: AVE_HEAVY_LOCK_HELD=unset" && ! waited'
AVE_HEAVY_LOCK_HELD=1 run_bounded --tier media
check "a caller that holds the lock sets AVE_HEAVY_LOCK_HELD=1: no second lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && ! waited'
mkfifo "$T/out.fifo"
(cd "$R" && exec ./scripts/verify.sh --tier media 8>&-) >"$T/out.fifo" 2>&1 &
pid=$!
exec 7<"$T/out.fifo"
FIRST=""; IFS= read -r -t 60 FIRST <&7
check "a media run while the lock is held prints one waiting line" 'printf "%s" "$FIRST" | quiet "^verify.sh: waiting for the heavy-media lock $AVE_HEAVY_LOCK "'
read -r -t 2 NEXT <&7; READ_STATUS=$?
check "it runs no step while the lock is held (no output for 2 s, process alive)" '[ "$READ_STATUS" -gt 128 ] && kill -0 "$pid" 2>/dev/null'
exec 8>&-  # release: the waiting run takes the lock and proceeds
OUT="$(cat <&7)"; exec 7<&-
wait "$pid"; CODE=$?
check "after the release it runs the media tier under the lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && printf "%s" "$OUT" | quiet "PASS — tier media" && ! waited'
mkdir -p "$T/tmpdir"
OUT="$(cd "$R" && env -u AVE_HEAVY_LOCK TMPDIR="$T/tmpdir" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "default lock file: \$TMPDIR/ave-heavy-media.lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && [ -f "$T/tmpdir/ave-heavy-media.lock" ]'
LEAVE_PROCESS="$T/left.pid" run --tier media
LEFT="$(cat "$T/left.pid" 2>/dev/null)"
check "a process a step leaves behind keeps no lock after the run" '[ "$CODE" = 0 ] && [ -n "$LEFT" ] && kill -0 "$LEFT" 2>/dev/null && flock -n "$AVE_HEAVY_LOCK" true'
[ -z "$LEFT" ] || kill "$LEFT" 2>/dev/null
NO_FLOCK_PATH="$(path_without flock)"
OUT="$(cd "$R" && PATH="$NO_FLOCK_PATH" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "without flock the media tier fails before any step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet "needs flock" && ! printf "%s" "$OUT" | quiet "^==> "'
OUT="$(cd "$R" && PATH="$NO_FLOCK_PATH" ./scripts/verify.sh 2>&1)"; CODE=$?
check "without flock the fast tier still runs" '[ "$CODE" = 0 ]'

# AVE-REQ-097 AC-4
echo "## a failing step fails the tier that runs it"
sed -i 's/media_step "media step" true/media_step "media step" false/' "$R/scripts/verify.d/20-backend.sh"
run
check "fast tier still passes (the failing step is not in it)" '[ "$CODE" = 0 ]'
run --tier media
check "media tier fails with exit 1 and names the step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet -- "- media step (exit 1)"'
check "the failed run's manifest records FAIL" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && python3 -c "import json,sys; assert json.load(open(sys.argv[1]))[\"result\"] == \"FAIL\"" "$m"'
run --tier release
check "release tier fails too" '[ "$CODE" = 1 ]'

echo "VERIFY TIERS TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
