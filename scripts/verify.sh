#!/usr/bin/env bash
# scripts/verify.sh — the single repository-wide verification entry point.
#
# Humans, Claude, the Stop hook (.claude/hooks/stop-verify.sh) and CI (.github/workflows/verify.yml)
# all run this script, and only this script, to decide whether the repository is green.
#
# Usage:  ./scripts/verify.sh [--tier fast|media|release]     (default: fast; or VERIFY_TIER=…)
#   fast     project control files, requirements baseline, lint, format, types, unit tests
#   media    fast + real-media integration tests (FFmpeg renders with decoded-output oracles)
#   release  media + tooling regression suites (every installed awk) and the remaining release checks
# Exit:   0 every step passed · 1 at least one step failed · 2 usage error
#
# ==================================================================================================
# Structure: this file runs the "Project control files" step, then sources every component step file
# in scripts/verify.d/ in name order, then the final "Working tree unchanged by verification" step.
# Component files register steps with fast_step / media_step / release_step "<name>" <command…>;
# each registers its checks in this order: formatting check (read-only), lint, static analysis /
# security scan, type checking, unit tests, integration tests, build, end-to-end / smoke tests of key
# user journeys, other stack-specific validation. Every component file is a required file
# (scripts/check-project-control.sh), so a missing component fails instead of skipping silently.
# Rules: non-interactive, deterministic, read-only toward the working tree (outputs go only to
# .gitignore-d paths; the last step enforces it, because the Stop-gate cache fingerprints untracked
# files), identical locally and in CI. A missing tool fails its step. Never weaken, skip or suppress
# a check to get green: fix the root cause. Package checks never certify product behavior.
# ==================================================================================================
# shellcheck source-path=SCRIPTDIR

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
STEPS_RUN=0
STEPS_FAILED=0
FAILED_STEPS=""
TIER="${VERIFY_TIER:-fast}"

usage() {
  printf 'Usage: ./scripts/verify.sh [--tier fast|media|release]\n'
  printf 'Runs every verification step of the tier, prints a summary, exits 0 on PASS and 1 on FAIL.\n'
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

# Tier membership: fast ⊂ media ⊂ release.
tier_includes() {
  case "$1:$TIER" in
    fast:*) return 0 ;;
    media:media | media:release) return 0 ;;
    release:release) return 0 ;;
  esac
  return 1
}

# Step registration helpers used by scripts/verify.d/*.sh.
fast_step() { run_step "$@"; }
media_step() { if tier_includes media; then run_step "$@"; fi; }
release_step() { if tier_includes release; then run_step "$@"; fi; }

print_summary() {
  printf '\n'
  if [ "$STEPS_FAILED" -eq 0 ]; then
    printf 'verify.sh: PASS — tier %s (%s of %s steps passed)\n' "$TIER" "$STEPS_RUN" "$STEPS_RUN"
    return 0
  fi
  printf 'verify.sh: FAIL — tier %s (%s of %s steps failed)\n%s' "$TIER" "$STEPS_FAILED" "$STEPS_RUN" \
    "$FAILED_STEPS"
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
  local before step_file
  cd "$ROOT" || return 2
  before="$(tree_state)"

  run_step "Project control files" ./scripts/check-project-control.sh
  for step_file in scripts/verify.d/*.sh; do
    [ -f "$step_file" ] || continue
    # shellcheck source=/dev/null
    . "./$step_file"
  done

  run_step "Working tree unchanged by verification" check_tree_unchanged "$before"  # keep last
  print_summary
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    --tier)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      TIER="$2"
      shift 2
      ;;
    --tier=*) TIER="${1#--tier=}"; shift ;;
    *)
      printf 'verify.sh: unexpected argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done
case "$TIER" in
  fast | media | release) ;;
  *) printf 'verify.sh: unknown tier: %s\n' "$TIER" >&2; usage >&2; exit 2 ;;
esac
main
