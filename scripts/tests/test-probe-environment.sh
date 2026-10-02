#!/usr/bin/env bash
# scripts/tests/test-probe-environment.sh — smoke test of scripts/probe-environment.sh: it runs
# offline, reports every section, and never prints a credential value. Exit 0 when every check
# passes.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBE="$W/../probe-environment.sh"
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }

SECRET="probe-test-secret-$$-value"
OUT="$(HF_TOKEN="$SECRET" ANTHROPIC_API_KEY="" "$PROBE" --offline 2>&1)"; CODE=$?
# AVE-REQ-094 AC-1
check "offline probe exits 0" '[ "$CODE" = 0 ]'
for heading in "Platform and resources" "Accelerators" "Media tools" "Toolchains" "Browsers" "Git" \
  "Product credential variables" "Network"; do
  check "reports section: $heading" 'printf "%s\n" "$OUT" | grep -q "^## $heading"'
done
check "network probes skipped offline" 'printf "%s\n" "$OUT" | grep -q "skipped (--offline)"'
check "a set credential is reported as set" 'printf "%s\n" "$OUT" | grep -Eq "^HF_TOKEN +set$"'
check "an empty credential is reported as unset" 'printf "%s\n" "$OUT" | grep -Eq "^ANTHROPIC_API_KEY +unset$"'
check "no credential value is printed" '! printf "%s\n" "$OUT" | grep -qF "$SECRET"'
"$PROBE" --bogus >/dev/null 2>&1; CODE=$?
check "unknown option exits 2" '[ "$CODE" = 2 ]'

echo "PROBE TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
