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
# Environment (AVE-REQ-097 AC-2, AC-4): the steps start from a named set of variables. Before this
# file defines anything of its own, the run removes every shell function that exists (an exported
# function of the caller) and every exported variable outside the set
#   PATH HOME USER LOGNAME TMPDIR LANG LC_ALL TZ
#   UV_PROJECT_ENVIRONMENT UV_CACHE_DIR UV_PYTHON_INSTALL_DIR  the locked backend environment, the
#       uv cache and the Python that uv installed, where scripts/dev-container.sh and
#       .devcontainer/Dockerfile keep them (.github/workflows/verify.yml sets none of the three)
#   AVE_HEAVY_LOCK AVE_HEAVY_LOCK_HELD                         the heavy-media lock (below)
#   PWD SHLVL _                                                which the shell maintains itself
# so no other variable of the caller reaches a step: none that redirects or configures Git
# (GIT_DIR, GIT_CONFIG_COUNT), changes what Python, pytest or uv load and select (PYTHONPATH,
# PYTHONUSERBASE, PYTEST_ADDOPTS, UV_ENV_FILE), names the media tools (AVE_FFMPEG, AVE_FFPROBE) or
# makes a child shell run a startup file (BASH_ENV, ENV). VERIFY_TIER selects the tier and reaches
# no step. An environment entry that the shell cannot unset (its name is no shell identifier)
# fails the run before any step. The run then sets its own variables: PYTHONSAFEPATH and
# PYTHONNOUSERSITE (no Python process takes a module from the directory of the script it runs or
# from a user site directory), PYTEST_DISABLE_PLUGIN_AUTOLOAD (pytest loads no plugin by itself),
# PYTHONPYCACHEPREFIX and AVE_RUN_SCRATCH (bytecode and the type-checker cache of a run live in a
# scratch directory that the run creates outside the tree and removes at its end) and
# AVE_EVIDENCE_DIR (below). The run fails when Git ignores a file inside the source, test, script
# or hook directories. Trusted, and outside this gate: the interpreter, the tools on PATH, the
# files under HOME, and the shell with what acts before the first line of this file (SHELLOPTS,
# BASHOPTS, BASH_ENV, a function exported under the name of a shell builtin). CI on a fresh
# checkout is the run that admits a commit to main.
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
# held: with a lock that nobody holds, without flock, or with a lock file it cannot open or test,
# the run fails before any step. Every other heavy media command runs as
# `flock <lock file> <command>`. The fast tier takes no lock.
# ==================================================================================================
# shellcheck source-path=SCRIPTDIR

set -uo pipefail

# The named environment (header § Environment). A function that exists before this file defines
# its own came from the caller: none stays.
while IFS= read -r REPLY; do
  [ -z "$REPLY" ] || unset -f -- "$REPLY"
done <<<"$(compgen -A function)"

# in_named_set <name> — true for a variable that a step inherits from the caller, and for the
# three the shell maintains itself.
in_named_set() {
  case "$1" in
    PATH | HOME | USER | LOGNAME | TMPDIR | LANG | LC_ALL | TZ) ;;
    UV_PROJECT_ENVIRONMENT | UV_CACHE_DIR | UV_PYTHON_INSTALL_DIR) ;;
    AVE_HEAVY_LOCK | AVE_HEAVY_LOCK_HELD) ;;
    PWD | SHLVL | _) ;;
    *) return 1 ;;
  esac
}

# clean_environment — unsets every exported variable outside the named set, then sets the run's
# own. It runs before this file assigns a variable, so every exported name is the caller's, and it
# keeps the names in its positional parameters, so it needs no variable of its own. VERIFY_TIER
# stays for the line below that reads and unsets it. A read-only variable (SHELLOPTS, BASHOPTS)
# leaves the environment and keeps its value. OLDPWD goes too: the shell exports it again at the
# next cd only while it still holds the export mark of the shell's start.
clean_environment() {
  # shellcheck disable=SC2046 # names of shell variables hold no blank and no pattern character
  set -- $(compgen -e)
  while [ "$#" -gt 0 ]; do
    if ! in_named_set "$1" && [ "$1" != VERIFY_TIER ]; then
      unset "$1" 2>/dev/null || export -n "$1"
    fi
    shift
  done
  unset OLDPWD
  export PYTHONSAFEPATH=1 PYTHONNOUSERSITE=1 PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
}

# A Windows host passes the run to the development container (end of this file); this file
# starts again there and cleans the environment its steps get.
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) ;;
  *) clean_environment ;;
esac

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

# environment_is_named — fails when a step would still see a name outside the named set and the
# run's own variables: an environment entry that the shell passes on and cannot unset.
environment_is_named() {
  local foreign
  if ! foreign="$(env -0 | while IFS= read -r -d '' REPLY; do
    REPLY="${REPLY%%=*}"
    case "$REPLY" in
      PYTHONSAFEPATH | PYTHONNOUSERSITE | PYTEST_DISABLE_PLUGIN_AUTOLOAD) ;;
      *) in_named_set "$REPLY" || printf ' %s' "$REPLY" ;;
    esac
  done)"; then
    printf 'verify.sh: FAIL — cannot list the environment of the steps (env -0)\n'
    return 1
  fi
  [ -n "$foreign" ] || return 0
  printf 'verify.sh: FAIL — the environment holds names outside the named set of the steps:%s\n' "$foreign"
  printf 'Start the run without them (env -u <name> ./scripts/verify.sh).\n'
  return 1
}

# hold_heavy_lock — in the media and release tiers, takes the heavy-media lock on file descriptor 9
# for the rest of the run (header: one heavy media job at a time). Returns 1 when it cannot.
hold_heavy_lock() {
  local status
  tier_includes media || return 0
  if ! command -v flock >/dev/null 2>&1; then
    printf 'verify.sh: FAIL — tier %s needs flock (util-linux) for the heavy-media lock %s\n' \
      "$TIER" "$HEAVY_LOCK"
    return 1
  fi
  if ! exec 9>>"$HEAVY_LOCK"; then
    printf 'verify.sh: FAIL — cannot open the heavy-media lock %s\n' "$HEAVY_LOCK"
    return 1
  fi
  if [ "${AVE_HEAVY_LOCK_HELD:-}" = 1 ]; then
    # The caller says it holds the lock, and the run confirms it: a lock that this run can take is
    # held by nobody, and a lock that it cannot test confirms nothing.
    flock -n -E 75 9
    status=$?
    exec 9>&-
    case "$status" in
      75) return 0 ;;
      0)
        printf 'verify.sh: FAIL — AVE_HEAVY_LOCK_HELD=1 is set and nobody holds the heavy-media lock %s\n' \
          "$HEAVY_LOCK"
        ;;
      *)
        printf 'verify.sh: FAIL — AVE_HEAVY_LOCK_HELD=1 is set and the heavy-media lock %s cannot be tested (flock exit %s)\n' \
          "$HEAVY_LOCK" "$status"
        ;;
    esac
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
# scripts/lib/verify-state.sh), or nothing for a tree that keeps none (outside Git, with a
# submodule or an embedded repository, and the other cases its header lists).
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
    printf 'Skipped: no working-tree fingerprint (outside Git, or a tree that keeps none: scripts/lib/verify-state.sh).\n'
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

# check_no_ignored_sources — a file Git ignores inside the directories whose files the steps load
# (sources, tests, scripts, hooks) would take part in a run and appear in no status, diff or
# fingerprint: a conftest.py in an ignored directory, a module or a bytecode file beside a script.
# Bytecode directories are exempt (no step reads them, header § Environment), and so are the
# folder files an operating system leaves behind. The one skip is a directory without a
# repository (no .git here or above); a Git command that fails inside a work tree fails the step.
check_no_ignored_sources() {
  local listed dir="$PWD"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while :; do
      if [ -e "$dir/.git" ]; then
        printf 'Git fails inside the work tree of %s/.git:\n' "$dir"
        git rev-parse --is-inside-work-tree 2>&1
        return 1
      fi
      [ -n "$dir" ] || break
      dir="${dir%/*}"
    done
    printf 'Skipped: outside a Git work tree (no .git here or above).\n'
    return 0
  fi
  if ! listed="$(git ls-files --others --ignored --exclude-standard -- backend/src backend/tests scripts .claude/hooks)"; then
    printf 'Git fails to list the ignored files of this work tree.\n'
    return 1
  fi
  listed="$(printf '%s\n' "$listed" | awk '!/(^|\/)(__pycache__\/|\.DS_Store$|Thumbs\.db$)/')"
  [ -z "$listed" ] && return 0
  printf 'Files that Git ignores inside the source, test, script and hook directories:\n%s\n' "$listed"
  printf 'Remove or track them: a run loads only files of the tree its fingerprint names.\n'
  return 1
}

# step_files — the component step files, as scripts/check-project-control.sh registers them.
step_files() {
  sed -n 's|^\(scripts/verify\.d/[A-Za-z0-9_.-]*\.sh\)$|\1|p' scripts/check-project-control.sh
}

main() {
  local before step_file
  cd "$ROOT" || return 2
  environment_is_named || return 1
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
  run_step "No ignored file among sources, tests and scripts" check_no_ignored_sources
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
