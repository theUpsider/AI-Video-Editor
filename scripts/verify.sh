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
# Structure: this file runs the "Project control files" step, then sources the component step files
# of scripts/verify.d/ that scripts/check-project-control.sh lists as required files, in that order,
# then the "Working tree unchanged by verification" step, and finally records the run's evidence
# (scripts/evidence.py record). A step file that cannot be loaded fails the run, and a file in
# scripts/verify.d/ that is no required file is never sourced (the checker reports it).
# Component files register steps with fast_step / media_step / release_step "<name>" <command…>;
# each registers its checks in this order: formatting check (read-only), lint, static analysis /
# security scan, type checking, unit tests, integration tests, build, end-to-end / smoke tests of key
# user journeys, other stack-specific validation. Every component file is a required file
# (scripts/check-project-control.sh), so a missing component fails instead of skipping silently.
# Rules: non-interactive, deterministic, read-only toward the working tree (outputs go only to
# .gitignore-d paths; the last step enforces it, because the Stop-gate cache fingerprints untracked
# files), identical locally and in CI. A missing tool fails its step. Never weaken, skip or suppress
# a check to get green: fix the root cause. Package checks never certify product behavior.
#
# Environment (AVE-REQ-097 AC-2, AC-4): the run clears the variables of its caller that redirect
# Git (GIT_DIR and its relatives), change what Python and pytest load or select (PYTHONPATH,
# PYTEST_ADDOPTS and their relatives) or make a child shell run a startup file, reads no bytecode
# and no type-checker cache from the tree (PYTHONPYCACHEPREFIX and AVE_RUN_SCRATCH point into a
# scratch directory that the run creates outside the tree and removes at its end) and loads no
# pytest plugin by itself (PYTEST_DISABLE_PLUGIN_AUTOLOAD). The interpreter, the shell and the tools
# on PATH are trusted; CI on a fresh checkout is the run that admits a commit to main.
#
# Evidence (AVE-REQ-097): every run gets a new directory var/verify/runs/<run-id>/, exported to the
# steps as AVE_EVIDENCE_DIR. run_step logs each step there (steps.tsv), test runners write their
# per-test reports and per-suite results there, and the last step writes manifest.json: results
# tied to the commit, the tree fingerprint, the toolchain, the configuration and every requirement
# tag. Inspect it with
# `python3 scripts/evidence.py show [AVE-REQ-NNN ...]`.
#
# One heavy media job at a time (AVE-REQ-096 AC-4): a media or release tier run holds an exclusive
# flock on the heavy-media lock file ${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock} from its
# first step to its summary, prints one line while it waits for the lock, and exports
# AVE_HEAVY_LOCK_HELD=1 to its steps. A caller that already holds the lock sets
# AVE_HEAVY_LOCK_HELD=1, and the run takes no second lock after it confirmed that the lock is
# held. Every other heavy media command runs as `flock <lock file> <command>`. The fast tier
# takes no lock.
# ==================================================================================================
# shellcheck source-path=SCRIPTDIR

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
STEPS_RUN=0
STEPS_FAILED=0
FAILED_STEPS=""
TIER="${VERIFY_TIER:-fast}"
unset VERIFY_TIER # the steps see the tier of this run through the step helpers only
AVE_EVIDENCE_DIR=""
AVE_RUN_SCRATCH=""
HEAVY_LOCK="${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}"

usage() {
  printf 'Usage: ./scripts/verify.sh [--tier fast|media|release]\n'
  printf 'Runs every verification step of the tier, prints a summary, exits 0 on PASS and 1 on FAIL.\n'
}

# run_step "<name>" <command> [args...] — runs one check, records its result, never aborts the run.
# The step gets no copy of the heavy-media lock descriptor (9), so no process a step leaves behind
# keeps the lock after the run.
run_step() {
  local name="$1" started status
  shift
  STEPS_RUN=$((STEPS_RUN + 1))
  printf '\n==> %s\n' "$name"
  started=$SECONDS
  "$@" </dev/null 9>&-
  status=$?
  if [ -n "$AVE_EVIDENCE_DIR" ]; then
    printf '%s\t%s\t%s\n' "$name" "$([ "$status" -eq 0 ] && echo PASS || echo FAIL)" \
      "$((SECONDS - started))" >>"$AVE_EVIDENCE_DIR/steps.tsv"
  fi
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

# hold_heavy_lock — in the media and release tiers, takes the heavy-media lock on file descriptor 9
# for the rest of the run (header: one heavy media job at a time). Returns 1 when it cannot.
hold_heavy_lock() {
  tier_includes media || return 0
  if [ "${AVE_HEAVY_LOCK_HELD:-}" = 1 ]; then
    # The caller says it holds the lock: a lock that this run could take is held by nobody.
    if command -v flock >/dev/null 2>&1 && flock -n "$HEAVY_LOCK" true 2>/dev/null; then
      printf 'verify.sh: FAIL — AVE_HEAVY_LOCK_HELD=1 is set and nobody holds the heavy-media lock %s\n' \
        "$HEAVY_LOCK"
      return 1
    fi
    return 0
  fi
  if ! command -v flock >/dev/null 2>&1; then
    printf 'verify.sh: FAIL — tier %s needs flock (util-linux) to hold the heavy-media lock %s\n' \
      "$TIER" "$HEAVY_LOCK"
    return 1
  fi
  if ! exec 9>>"$HEAVY_LOCK"; then
    printf 'verify.sh: FAIL — cannot open the heavy-media lock %s\n' "$HEAVY_LOCK"
    return 1
  fi
  if ! flock -n 9; then
    printf 'verify.sh: waiting for the heavy-media lock %s (%s)\n' "$HEAVY_LOCK" \
      "another media or release run holds it; a caller that holds it sets AVE_HEAVY_LOCK_HELD=1"
    if ! flock 9; then
      printf 'verify.sh: FAIL — cannot take the heavy-media lock %s\n' "$HEAVY_LOCK"
      return 1
    fi
  fi
  AVE_HEAVY_LOCK_HELD=1
  export AVE_HEAVY_LOCK_HELD
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

# record_evidence <tree_state before the steps> — writes the run's manifest.json.
record_evidence() {
  python3 -B scripts/evidence.py record --dir "$AVE_EVIDENCE_DIR" --tier "$TIER" --fingerprint "$1"
}

# clean_environment — header § Environment.
clean_environment() {
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
    GIT_COMMON_DIR GIT_NAMESPACE PYTHONPATH PYTHONHOME PYTHONSTARTUP PYTHONOPTIMIZE PYTHONWARNINGS \
    PYTHONINSPECT PYTEST_ADDOPTS PYTEST_PLUGINS BASH_ENV ENV CDPATH
  export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
}

# step_files — the component step files, as scripts/check-project-control.sh registers them.
step_files() {
  sed -n 's|^\(scripts/verify\.d/[A-Za-z0-9_.-]*\.sh\)$|\1|p' scripts/check-project-control.sh
}

main() {
  local before step_file
  cd "$ROOT" || return 2
  clean_environment
  hold_heavy_lock || return 1
  before="$(tree_state)"
  # A run starts in a directory that did not exist: nothing a caller prepared counts as its result.
  AVE_EVIDENCE_DIR="$ROOT/var/verify/runs/$(date -u +%Y%m%dT%H%M%SZ)-$$"
  if ! mkdir -p "$ROOT/var/verify/runs" || ! mkdir "$AVE_EVIDENCE_DIR"; then
    printf 'verify.sh: cannot create the run directory %s (a run never reuses one)\n' "$AVE_EVIDENCE_DIR" >&2
    return 2
  fi
  export AVE_EVIDENCE_DIR
  # Caches of this run only, outside the tree: no step reads bytecode or type-checker state that an
  # older tree left behind.
  AVE_RUN_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/verify-run.XXXXXX")" || return 2
  trap 'rm -rf "$AVE_RUN_SCRATCH"' EXIT
  export AVE_RUN_SCRATCH
  export PYTHONPYCACHEPREFIX="$AVE_RUN_SCRATCH/pycache"

  run_step "Project control files" ./scripts/check-project-control.sh
  for step_file in $(step_files); do
    # shellcheck source=/dev/null
    . "./$step_file" || run_step "Load $step_file" false
  done

  run_step "Working tree unchanged by verification" check_tree_unchanged "$before"
  run_step "Evidence manifest" record_evidence "$before"  # keep last
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
# A Windows host (Git Bash) lacks the Linux toolchain the steps need, so every tier runs inside
# the development container, which holds what CI installs (scripts/dev-container.sh).
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    cd "$ROOT" || exit 2
    exec ./scripts/dev-container.sh ./scripts/verify.sh --tier "$TIER"
    ;;
esac
main
