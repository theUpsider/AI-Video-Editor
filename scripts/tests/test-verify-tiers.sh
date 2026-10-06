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
# The fixtures are Git repositories of their own: with a temp dir inside a work tree their Git commands
# would act on that tree (AVE-REQ-097: a suite leaves the working tree unchanged).
if git -C "$T" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "test-verify-tiers.sh: the temporary directory $T lies inside a Git work tree; set TMPDIR outside it" >&2
  exit 2
fi
export GIT_CEILING_DIRECTORIES="$T"
for tool in git python3 flock timeout; do
  command -v "$tool" >/dev/null 2>&1 || { echo "test-verify-tiers.sh: $tool is required" >&2; exit 2; }
done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export AVE_HEAVY_LOCK="$T/heavy-media.lock"
unset AVE_HEAVY_LOCK_HELD VERIFY_TIER
REPO="$(cd "$W/../.." && pwd)"
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
  local dir entry name hide cmd mirror out=""
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    hide=0
    for cmd in "$@"; do [ -e "$dir/$cmd" ] && hide=1; done
    if [ "$hide" -eq 1 ]; then
      mirror="$(mktemp -d "$T/path-mirror.XXXXXX")" || return 1
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

# AVE-REQ-097 AC-2, AVE-REQ-097 AC-4: the run clears what its caller exported, reads no bytecode
# from the tree, names this tree in its manifest and starts in a directory that did not exist.
echo "## the run's environment"
cp "$R/scripts/verify.d/20-backend.sh" "$T/20-fixture.sh"
cat >> "$R/scripts/verify.d/20-backend.sh" <<'STEPS'
fast_step "environment" sh -c 'echo "env: PYTEST_ADDOPTS=${PYTEST_ADDOPTS-unset} PYTEST_PLUGINS=${PYTEST_PLUGINS-unset} PYTHONPATH=${PYTHONPATH-unset} VERIFY_TIER=${VERIFY_TIER-unset} GIT_DIR=${GIT_DIR-unset} GIT_WORK_TREE=${GIT_WORK_TREE-unset} BASH_ENV=${BASH_ENV-unset} AUTOLOAD=${PYTEST_DISABLE_PLUGIN_AUTOLOAD-unset} SAFEPATH=${PYTHONSAFEPATH-unset}"
  case "${PYTHONPYCACHEPREFIX-}" in "" | "$PWD"/*) ;; "$AVE_RUN_SCRATCH"/*) [ -d "$AVE_RUN_SCRATCH" ] && echo "env: bytecode prefix in the scratch directory of the run, outside the tree" ;; esac
  echo "env: scratch $AVE_RUN_SCRATCH"'
STEPS
mkdir -p "$T/other" && (cd "$T/other" && git init -q && git config user.email t@t && git config user.name t && printf 'x\n' > f && git add -A && git commit -qm other)
HERE_FP="$(cd "$R" && . scripts/lib/verify-state.sh && vstate_fingerprint)"
HERE_COMMIT="$(cd "$R" && git rev-parse HEAD)"
OUT="$(cd "$R" && PYTEST_ADDOPTS=--collect-only PYTEST_PLUGINS=x PYTHONPATH=/nonexistent VERIFY_TIER=media BASH_ENV=/nonexistent GIT_DIR="$T/other/.git" GIT_WORK_TREE="$T/other" ./scripts/verify.sh 2>&1)"; CODE=$?
check "the steps see none of the caller's Git, Python, pytest or tier variables" '[ "$CODE" = 0 ] && ran media && printf "%s\n" "$OUT" | quiet -x "env: PYTEST_ADDOPTS=unset PYTEST_PLUGINS=unset PYTHONPATH=unset VERIFY_TIER=unset GIT_DIR=unset GIT_WORK_TREE=unset BASH_ENV=unset AUTOLOAD=1 SAFEPATH=1"'
check "the steps read bytecode from the run's scratch directory only" 'printf "%s\n" "$OUT" | quiet -x "env: bytecode prefix in the scratch directory of the run, outside the tree"'
check "the scratch directory is gone after the run" 's="$(printf "%s\n" "$OUT" | sed -n "s/^env: scratch //p")" && [ -n "$s" ] && [ ! -e "$s" ]'
check "GIT_DIR and GIT_WORK_TREE of another repository: the manifest names this tree" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && [ -n "$HERE_FP" ] && python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert (d[\"fingerprint\"], d[\"commit\"]) == (sys.argv[2], sys.argv[3]), d" "$m" "$HERE_FP" "$HERE_COMMIT"'
OUT="$(cd "$R" && bash -c 'for i in 0 1 2 3 4 5; do mkdir -p "var/verify/runs/$(date -u -d "+$i sec" +%Y%m%dT%H%M%SZ)-$$"; done; exec ./scripts/verify.sh' 2>&1)"; CODE=$?
check "a run directory prepared by the caller is never reused" '[ "$CODE" = 2 ] && printf "%s\n" "$OUT" | quiet "cannot create the run directory" && ! printf "%s\n" "$OUT" | quiet "^==> "'

# AVE-REQ-097 AC-1, AVE-REQ-097 AC-4: a tier runs the registered step files, all of them.
echo "## step files"
printf 'fast_step "half a step" true\nif true; then\n' > "$R/scripts/verify.d/20-backend.sh"
run
check "a step file that cannot be loaded fails the tier" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet -F "<== FAIL: Load scripts/verify.d/20-backend.sh"'
sed 's/$/\r/' "$T/20-fixture.sh" > "$R/scripts/verify.d/20-backend.sh"
run
check "a step file with CRLF line ends fails the tier" '[ "$CODE" = 1 ]'
cp "$T/20-fixture.sh" "$R/scripts/verify.d/20-backend.sh"
printf 'fast_step "hidden step" true\nSTEPS_FAILED=0; FAILED_STEPS=""\n' > "$R/scripts/verify.d/99-local.sh"
run
check "an unregistered step file is never sourced and fails the control step" '[ "$CODE" = 1 ] && ! printf "%s\n" "$OUT" | quiet "hidden step" && printf "%s\n" "$OUT" | quiet -F "scripts/verify.d/99-local.sh: is no registered component step file"'
rm "$R/scripts/verify.d/99-local.sh"
run
check "the restored fixture passes again" '[ "$CODE" = 0 ] && ran fast'

# AVE-REQ-097 AC-4: a file Git ignores inside the source, test, script or hook directories takes
# part in no status, diff or fingerprint, so a run that could load it fails.
echo "## ignored files among sources, tests and scripts"
IGNORED_STEP="No ignored file among sources, tests and scripts"
check "the clean fixture passes the ignored-file step" 'passed "$IGNORED_STEP"'
# plant <path> — writes a file there; unplant <path> <topmost directory the case created, if any>
plant() { mkdir -p "$R/$(dirname "$1")" && printf 'x\n' > "$R/$1"; }
unplant() { rm -f "$R/$1"; [ -z "${2:-}" ] || rm -rf "${R:?}/$2"; }
while read -r planted created; do
  plant "$planted"
  run
  check "an ignored $planted fails the run and is named" '[ "$CODE" = 1 ] && [ -z "$(cd "$R" && git status --porcelain)" ] && printf "%s\n" "$OUT" | quiet -F "<== FAIL: $IGNORED_STEP" && printf "%s\n" "$OUT" | quiet -x "$planted"'
  unplant "$planted" "$created"
done <<'PLANTED'
scripts/unittest.pyc
backend/tests/unit/test-results/conftest.py backend/tests/unit
backend/src/ave/dist/module.py backend/src
.claude/hooks/local.pyc
PLANTED
plant scripts/__pycache__/evidence.cpython-312.pyc
plant scripts/tests/.DS_Store
plant var/fixtures/cache.pyc
run
check "bytecode directories, folder files of the operating system and var/ pass" '[ "$CODE" = 0 ] && passed "$IGNORED_STEP"'
unplant scripts/tests/.DS_Store scripts/__pycache__
rmdir "$R/scripts/tests" 2>/dev/null || true
check "the fixture is as committed after the planted files are gone" '[ -z "$(cd "$R" && git status --porcelain --ignored | grep -v "^!! var/")" ]'

# AVE-REQ-097 AC-4: a suite whose cases were all skipped establishes nothing.
echo "## skipped suites"
NO_AWKS_PATH="$(path_without mawk gawk original-awk busybox)"
OUT="$(PATH="$NO_AWKS_PATH" bash "$W/test-checker.sh" --all-awks 2>&1)"; CODE=$?
check "test-checker.sh --all-awks without any of its awk implementations fails" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "ran no awk implementation"'

# AVE-REQ-097 AC-2, AVE-REQ-097 AC-4: the backend steps of the real step file.
echo "## the real backend step file"
cp "$REPO/scripts/verify.d/20-backend.sh" "$R/scripts/verify.d/20-backend.sh"
mkdir -p "$T/stub" && cat > "$T/stub/uv" <<'STUB' && chmod +x "$T/stub/uv"
#!/bin/sh
echo "uv $*"
case " $* " in *" pytest "*) echo "media tools of pytest $*: ${AVE_FFMPEG-unset} ${AVE_FFPROBE-unset}" ;; esac
STUB
OUT="$(cd "$R" && env -u AVE_FFMPEG -u AVE_FFPROBE PATH="$T/stub:$PATH" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "the pytest steps take their configuration from pyproject.toml alone" 'printf "%s\n" "$OUT" | quiet -E "^uv run --frozen --quiet --directory backend pytest -c pyproject.toml -q -p no:cacheprovider --forbid-skips --evidence-report=.*/pytest-unit.json -m not media and not slow$"'
check "a pytest step that left no report fails" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "no report: the pytest session ended before it wrote one" && printf "%s\n" "$OUT" | quiet -F "<== FAIL: Backend unit tests"'
check "the type checker reads no cache from the tree" 'printf "%s\n" "$OUT" | quiet -E "^uv run .* mypy --cache-dir=.*/verify-run\.[^/]*/mypy-cache$" && ! printf "%s\n" "$OUT" | quiet -F -- "--cache-dir=$R/"'
# AVE-REQ-097 AC-3: the fast tier renders nothing; its tests see media tools that refuse to run.
MEDIA_STUB="$R/scripts/lib/media-tier-only.sh"
check "the fast tier's tests see media tools that refuse to run" 'printf "%s\n" "$OUT" | quiet -E "^media tools of pytest .* -m not media and not slow: $MEDIA_STUB $MEDIA_STUB\$"'
check "the media tier's tests see the real media tools" 'printf "%s\n" "$OUT" | quiet -E "^media tools of pytest .* -m media or slow: unset unset\$"'
STUB_OUT="$("$MEDIA_STUB" -version 2>&1)"; STUB_CODE=$?
check "the stand-in exits 1 and names the media tier" '[ "$STUB_CODE" = 1 ] && printf "%s\n" "$STUB_OUT" | quiet "media tools run in the media tier only"'
cp "$T/20-fixture.sh" "$R/scripts/verify.d/20-backend.sh"

# AVE-REQ-097 AC-4: the fast tier, which the Stop gate runs, judges done requirements too.
echo "## the done step in every tier"
D="$T/done-project"
"$W/make-fixture.sh" "$D" with-reqs >/dev/null
cp "$REPO/scripts/verify.d/95-evidence.sh" "$D/scripts/verify.d/95-evidence.sh"
OUT="$(cd "$D" && ./scripts/verify.sh 2>&1)"; CODE=$?
check "the fast tier fails a done requirement that this run does not evidence" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet -F "<== FAIL: Done requirements evidenced by this run" && printf "%s\n" "$OUT" | quiet "^ERROR: AVE-REQ-001"'

# AVE-REQ-096 AC-4
echo "## one heavy media job at a time: the heavy-media lock"
AVE_HEAVY_LOCK_HELD=1 run --tier media
check "AVE_HEAVY_LOCK_HELD=1 while nobody holds the lock fails before any step" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "nobody holds the heavy-media lock" && ! printf "%s\n" "$OUT" | quiet "^==> "'
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
