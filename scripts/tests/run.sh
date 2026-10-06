#!/usr/bin/env bash
# scripts/tests/run.sh [--all-awks] — runs the regression suites of the project-control tooling:
#   test-checker.sh         scripts/check-project-control.sh (--all-awks: every installed awk)
#   test-check-baseline.sh  scripts/check_baseline.py and scripts/requirements/import_baseline.py
#   test-stop-hook.sh       .claude/hooks/stop-verify.sh and the working-tree step of scripts/verify.sh
#   test-session-start.sh   .claude/hooks/session-start.sh
#   test-verify-tiers.sh    tier selection, exit codes and heavy-media lock of scripts/verify.sh
#   test-probe-environment.sh  scripts/probe-environment.sh (measured resources, media tools, toolchains,
#                           browsers and Git; accelerator verdict; Claude Code version, OS user,
#                           writability; network lines through a fake curl; never prints secrets)
# (scripts/tests/test_*.py, the evidence tooling unit tests, run in verify.sh's fast tier through
# `scripts/evidence.py unittest`.)
# Inside verify.sh (AVE_EVIDENCE_DIR set) each suite's result (file, exit status, number of checks,
# criterion tags) goes into the run's evidence directory: a suite's tags count only through that
# result, and only when the suite exited 0 and its `<NAME> TOTAL: pass=N fail=M` line reports N >= 1.
# A listed suite that exited 0 without running a check fails here (AVE-REQ-097 AC-4: a no-op script
# establishes nothing).
# Every suite builds its fixtures in a temp dir and leaves the working tree unchanged.
# Exit: 0 every suite passed · 1 a suite failed · 2 usage error.
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER_ARGS=()
case "${1:-}" in
  "") ;;
  --all-awks) CHECKER_ARGS=(--all-awks) ;;
  -h | --help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) printf 'Usage: scripts/tests/run.sh [--all-awks]\n' >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { printf 'Usage: scripts/tests/run.sh [--all-awks]\n' >&2; exit 2; }

FAILED=""
# record_suite <suite> <exit status> <checks> — writes the suite's result when verify.sh runs this script.
record_suite() {
  [ -n "${AVE_EVIDENCE_DIR:-}" ] || return 0
  python3 -B "$W/../evidence.py" record-suite --dir "$AVE_EVIDENCE_DIR" --file "$W/$1" --exit "$2" --checks "$3"
}
run_suite() {
  local name="$1" status checks out
  shift
  out="$(mktemp "${TMPDIR:-/tmp}/run-suite.XXXXXX")" ||
    { printf '<== FAIL: %s (no temp file for its output)\n' "$name"; FAILED="$FAILED $name"; return; }
  printf '\n==> %s\n' "$name"
  "$W/$name" "$@" 2>&1 | tee "$out"
  status=${PIPESTATUS[0]}
  checks="$(grep -Eo 'TOTAL: pass=[0-9]+ fail=[0-9]+' "$out" | tail -n 1 | sed -E 's/.*pass=([0-9]+) fail=.*/\1/')"
  rm -f "$out"
  checks="${checks:-0}"
  if [ "$status" -eq 0 ] && [ "$checks" -ge 1 ]; then
    printf '<== PASS: %s (%s checks)\n' "$name" "$checks"
  elif [ "$status" -eq 0 ]; then
    printf '<== FAIL: %s (no check ran: no "TOTAL: pass=N fail=M" line with N >= 1)\n' "$name"
    FAILED="$FAILED $name(no-check)"
  else
    printf '<== FAIL: %s (exit %s)\n' "$name" "$status"
    FAILED="$FAILED $name"
  fi
  if ! record_suite "$name" "$status" "$checks"; then
    printf '<== FAIL: %s (result not recorded in %s)\n' "$name" "$AVE_EVIDENCE_DIR"
    FAILED="$FAILED $name(evidence)"
  fi
}

run_suite test-checker.sh ${CHECKER_ARGS[@]+"${CHECKER_ARGS[@]}"}
run_suite test-check-baseline.sh
run_suite test-stop-hook.sh
run_suite test-session-start.sh
run_suite test-verify-tiers.sh
run_suite test-probe-environment.sh

if [ -n "$FAILED" ]; then
  printf '\nscripts/tests/run.sh: FAIL:%s\n' "$FAILED"
  exit 1
fi
printf '\nscripts/tests/run.sh: PASS (6 suites)\n'
