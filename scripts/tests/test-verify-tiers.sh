#!/usr/bin/env bash
# scripts/tests/test-verify-tiers.sh — tier selection of scripts/verify.sh (fast ⊂ media ⊂ release)
# and its exit codes, in a fixture project whose component step file registers one marker step per
# tier. Needs git and python3. Exit 0 when every check passes.
# Checks are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/verify-tiers.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
R="$T/project"
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
run() {  # run [args...] -> CODE, OUT (combined output); VERIFY_TIER comes from the caller
  OUT="$(cd "$R" && ./scripts/verify.sh "$@" 2>&1)"; CODE=$?
}
ran() { printf '%s\n' "$OUT" | grep -qx "<== PASS: $1 step.*"; }

"$W/make-fixture.sh" "$R" >/dev/null
cat > "$R/scripts/verify.d/20-backend.sh" <<'STEPS'
# fixture component step file: one marker step per tier
# shellcheck shell=bash
fast_step "fast step" true
media_step "media step" true
release_step "release step" true
STEPS
(cd "$R" && git init -q && git config user.email t@t && git config user.name t && git add -A && git commit -qm init)

# AVE-REQ-097 AC-1
echo "## tier membership"
run
check "default tier is fast" '[ "$CODE" = 0 ] && ran fast && ! ran media && ! ran release && printf "%s" "$OUT" | grep -q "PASS — tier fast"'
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
check "unknown tier exits 2" '[ "$CODE" = 2 ] && printf "%s" "$OUT" | grep -q "unknown tier: full"'
run --tier
check "missing tier value exits 2" '[ "$CODE" = 2 ]'
run --fast
check "unexpected argument exits 2" '[ "$CODE" = 2 ] && printf "%s" "$OUT" | grep -q "unexpected argument"'

# AVE-REQ-097 AC-4
echo "## a failing step fails the tier that runs it"
sed -i 's/media_step "media step" true/media_step "media step" false/' "$R/scripts/verify.d/20-backend.sh"
run
check "fast tier still passes (the failing step is not in it)" '[ "$CODE" = 0 ]'
run --tier media
check "media tier fails with exit 1 and names the step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | grep -q -- "- media step (exit 1)"'
check "the failed run's manifest records FAIL" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && python3 -c "import json,sys; assert json.load(open(sys.argv[1]))[\"result\"] == \"FAIL\"" "$m"'
run --tier release
check "release tier fails too" '[ "$CODE" = 1 ]'

echo "VERIFY TIERS TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
