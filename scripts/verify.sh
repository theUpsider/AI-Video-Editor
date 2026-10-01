#!/usr/bin/env bash
# scripts/verify.sh — the single repository-wide verification entry point.
#
# Humans, Claude, the Stop hook (.claude/hooks/stop-verify.sh) and CI (.github/workflows/verify.yml)
# all run this script, and only this script, to decide whether the repository is green.
#
# Usage:  ./scripts/verify.sh          (no arguments; -h prints usage)
# Exit:   0 every step passed · 1 at least one step failed · 2 usage error
#
# ==================================================================================================
# Once the application stack exists, this script MUST run every relevant check, one run_step each,
# in this order, between the "Project control files" step and the final "Working tree unchanged by
# verification" step:
#   1. formatting check (read-only)          6. integration tests
#   2. lint                                  7. build
#   3. static analysis / security scan       8. end-to-end / smoke tests of key user journeys
#   4. type checking                         9. other stack-specific validation
#   5. unit tests
# The technical-foundation skill adds them; until then only the bootstrap checks run.
# Rules: non-interactive, deterministic, read-only toward the working tree (outputs go only to
# .gitignore-d paths; the last step enforces it, because the Stop-gate cache fingerprints untracked
# files), identical locally and in CI. Add commands only for selected technologies. A missing tool
# fails its step. Never weaken, skip or suppress a check to get green: fix the root cause.
# ==================================================================================================
# shellcheck source-path=SCRIPTDIR

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
STEPS_RUN=0
STEPS_FAILED=0
FAILED_STEPS=""

usage() {
  printf 'Usage: ./scripts/verify.sh\n'
  printf 'Runs every verification step, prints a summary, exits 0 on PASS and 1 on FAIL.\n'
}

# run_step "<name>" <command> [args...] — runs one check, records its result, never aborts the run.
run_step() {
  local name="$1" started status
  shift
  STEPS_RUN=$((STEPS_RUN + 1))
  printf '\n==> %s\n' "$name"
  started=$SECONDS
  "$@" </dev/null
  status=$?
  if [ "$status" -eq 0 ]; then
    printf '<== PASS: %s (%ss)\n' "$name" "$((SECONDS - started))"
  else
    STEPS_FAILED=$((STEPS_FAILED + 1))
    FAILED_STEPS="${FAILED_STEPS}  - ${name} (exit ${status})
"
    printf '<== FAIL: %s (exit %s, %ss)\n' "$name" "$status" "$((SECONDS - started))"
  fi
}

# Bootstrap NOTICE: delete this function and its call when technical-foundation adds the stack checks.
print_stack_notice() {
  printf '\nNOTICE: stack-specific checks are pending. The technical-foundation skill adds them\n'
  printf '        (format, lint, static analysis, types, tests, build, end-to-end) once the stack is selected.\n'
}

print_summary() {
  printf '\n'
  if [ "$STEPS_FAILED" -eq 0 ]; then
    printf 'verify.sh: PASS (%s of %s steps passed)\n' "$STEPS_RUN" "$STEPS_RUN"
    return 0
  fi
  printf 'verify.sh: FAIL (%s of %s steps failed)\n%s' "$STEPS_FAILED" "$STEPS_RUN" "$FAILED_STEPS"
  return 1
}

# Prints the Stop-gate fingerprint of the working tree (vstate_fingerprint in
# scripts/lib/verify-state.sh), or nothing when none is available (outside Git, or a tree that
# holds a submodule).
tree_state() {
  (
    # shellcheck source=lib/verify-state.sh
    . ./scripts/lib/verify-state.sh 2>/dev/null || exit 0
    vstate_fingerprint 2>/dev/null || true
  )
}

# check_tree_unchanged <tree_state before the steps> — fails when a step changed the working tree.
check_tree_unchanged() {
  if [ -z "$1" ]; then
    printf 'Skipped: no working-tree fingerprint (outside Git, or the tree holds a submodule).\n'
    return 0
  fi
  [ "$(tree_state)" = "$1" ] && return 0
  printf 'A verification step changed the working tree. Make it read-only, or send its output\n'
  printf '(reports, coverage, screenshots, rendered media) to a path listed in .gitignore.\n'
  printf 'Current git status:\n'
  git status --short --untracked-files=all
  return 1
}

main() {
  local before
  cd "$ROOT" || return 2
  before="$(tree_state)"

  run_step "Project control files" ./scripts/check-project-control.sh
  # Stack checks go here, in the order listed in the header.

  run_step "Working tree unchanged by verification" check_tree_unchanged "$before"  # keep last
  print_stack_notice
  print_summary
}

if [ "$#" -gt 0 ]; then
  case "$1" in
    -h | --help) usage; exit 0 ;;
  esac
  printf 'verify.sh: unexpected argument: %s\n' "$1" >&2
  usage >&2
  exit 2
fi
main
