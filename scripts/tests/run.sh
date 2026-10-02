#!/usr/bin/env bash
# scripts/tests/run.sh [--all-awks] — runs the regression suites of the project-control tooling:
#   test-checker.sh         scripts/check-project-control.sh (--all-awks: every installed awk)
#   test-check-baseline.sh  scripts/check_baseline.py and scripts/requirements/import_baseline.py
#   test-stop-hook.sh       .claude/hooks/stop-verify.sh and the working-tree step of scripts/verify.sh
#   test-session-start.sh   .claude/hooks/session-start.sh
#   test-verify-tiers.sh    tier selection and exit codes of scripts/verify.sh
#   test-probe-environment.sh  scripts/probe-environment.sh (offline: measured resources, accelerator
#                           verdict, Claude Code version, OS user, writability; never prints secrets)
# (scripts/tests/test_*.py, the evidence tooling unit tests, run in verify.sh's fast tier through
# `scripts/evidence.py unittest`.)
# Inside verify.sh (AVE_EVIDENCE_DIR set) each suite's result (file, exit status, criterion tags)
# goes into the run's evidence directory: a suite's tags count only through that result.
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
# record_suite <suite> <exit status> — writes the suite's result when verify.sh runs this script.
record_suite() {
  [ -n "${AVE_EVIDENCE_DIR:-}" ] || return 0
  python3 -B "$W/../evidence.py" record-suite --dir "$AVE_EVIDENCE_DIR" --file "$W/$1" --exit "$2"
}
run_suite() {
  local name="$1" status
  shift
  printf '\n==> %s\n' "$name"
  "$W/$name" "$@"
  status=$?
  if [ "$status" -eq 0 ]; then
    printf '<== PASS: %s\n' "$name"
  else
    printf '<== FAIL: %s (exit %s)\n' "$name" "$status"
    FAILED="$FAILED $name"
  fi
  if ! record_suite "$name" "$status"; then
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
