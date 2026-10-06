#!/usr/bin/env bash
# scripts/tests/run.sh [--all-awks] — runs the regression suites of the project-control tooling:
#   test-checker.sh         scripts/check-project-control.sh (--all-awks: every installed awk)
#   test-check-baseline.sh  scripts/check_baseline.py and scripts/requirements/import_baseline.py
#   test-stop-hook.sh       .claude/hooks/stop-verify.sh and the working-tree step of scripts/verify.sh
#   test-session-start.sh   .claude/hooks/session-start.sh
#   test-verify-tiers.sh    tier selection, exit codes and heavy-media lock of scripts/verify.sh
#   test-probe-environment.sh  scripts/probe-environment.sh (offline: measured resources, accelerator
#                           verdict, Claude Code version, OS user, writability; never prints secrets)
# (scripts/tests/test_*.py, the evidence tooling unit tests, run in verify.sh's fast tier through
# `scripts/evidence.py unittest`.)
# Inside verify.sh (AVE_EVIDENCE_DIR set) each suite's result (file, exit status, number of checks,
# criterion tags) goes into the run's evidence directory: a suite's tags count only through that
# result, and only when the suite exited 0 and its `<NAME> TOTAL: pass=N fail=M` line reports N >= 1
# and M = 0. A listed suite that exited 0 without running a check, or with a failed check in its own
# total, fails here: a no-op script and a caught failure establish nothing.
# Every suite builds its fixtures in a temp dir outside every Git work tree and leaves the working
# tree unchanged; with a temp dir inside a work tree this script stops before the first suite.
# This file holds no criterion tag: the runner has no suite result of its own, and scripts/evidence.py
# stops on a comment tag in a file of this directory that is neither a listed suite nor a test_*.py
# file. The list of suites is the `run_suite <file>` lines at the end of this file, one per line and
# at the start of the line, which scripts/evidence.py reads; the cases that run this script are in
# test_evidence.py.
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

# The suites run Git commands in their fixtures: a temp dir inside a work tree would aim them at it.
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/run-suites.XXXXXX")" ||
  { printf 'scripts/tests/run.sh: no temporary directory\n' >&2; exit 2; }
if git -C "$SCRATCH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  rmdir "$SCRATCH"
  printf 'scripts/tests/run.sh: the temporary directory %s lies inside a Git work tree; set TMPDIR outside it\n' \
    "${TMPDIR:-/tmp}" >&2
  exit 2
fi
rmdir "$SCRATCH"

FAILED=""
# record_suite <suite> <exit status> <checks> <failed checks> — writes the suite's result when
# verify.sh runs this script.
record_suite() {
  [ -n "${AVE_EVIDENCE_DIR:-}" ] || return 0
  python3 -B "$W/../evidence.py" record-suite --dir "$AVE_EVIDENCE_DIR" --file "$W/$1" --exit "$2" \
    --checks "$3" --failed "$4"
}
run_suite() {
  local name="$1" status checks failed total out
  shift
  out="$(mktemp "${TMPDIR:-/tmp}/run-suite.XXXXXX")" ||
    { printf '<== FAIL: %s (no temp file for its output)\n' "$name"; FAILED="$FAILED $name"; return; }
  printf '\n==> %s\n' "$name"
  "$W/$name" "$@" 2>&1 | tee "$out"
  status=${PIPESTATUS[0]}
  total="$(grep -Eo 'TOTAL: pass=[0-9]{1,9} fail=[0-9]{1,9}([^0-9]|$)' "$out" | tail -n 1)"
  rm -f "$out"
  checks="$(printf '%s\n' "$total" | sed -E 's/.*pass=([0-9]+) fail=([0-9]+).*/\1/')"
  failed="$(printf '%s\n' "$total" | sed -E 's/.*pass=([0-9]+) fail=([0-9]+).*/\2/')"
  checks="${checks:-0}"
  failed="${failed:-0}"
  if [ "$status" -ne 0 ]; then
    printf '<== FAIL: %s (exit %s)\n' "$name" "$status"
    FAILED="$FAILED $name"
  elif [ "$failed" -ge 1 ]; then
    printf '<== FAIL: %s (its total reports %s failed check(s) while it exited 0)\n' "$name" "$failed"
    FAILED="$FAILED $name(failed-checks)"
    status=1
  elif [ "$checks" -lt 1 ]; then
    printf '<== FAIL: %s (no check ran: no "TOTAL: pass=N fail=M" line with N >= 1)\n' "$name"
    FAILED="$FAILED $name(no-check)"
    status=1
  else
    printf '<== PASS: %s (%s checks)\n' "$name" "$checks"
  fi
  if ! record_suite "$name" "$status" "$checks" "$failed"; then
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
