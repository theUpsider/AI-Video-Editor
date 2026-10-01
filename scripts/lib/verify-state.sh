#!/usr/bin/env bash
# scripts/lib/verify-state.sh — verification state shared by verify.sh and the Claude Code hooks.
#
# Sourced by .claude/hooks/stop-verify.sh, .claude/hooks/session-start.sh and scripts/verify.sh
# after they cd to the project root. Defines functions only; never run it directly. Compatible
# with bash 3.2.
#
# State directory: "$(git rev-parse --git-path claude-verify)" (inside .git, so never committed;
# one per worktree). Outside a Git work tree, or when that directory is not writable, it falls
# back to a per-user temporary directory, and fingerprints are unavailable (no caching).
# Record files:
#   last-pass    fingerprint of the last tree that passed ./scripts/verify.sh
#   last-result  "PASS|FAIL <ISO-8601 UTC> <fingerprint|none>" of the last run
#   last.log     full output of the last run
#   attempts     consecutive failed Stop-gate attempts
#
# Fingerprint: the tree hash of the full working-tree content, untracked non-ignored files
# included, built in a temporary copy of the index with a throwaway object directory (it reads
# the real object store and writes nothing to it). It ignores HEAD, so committing keeps a pass
# valid, while any content change (tracked or untracked) invalidates it. Hashing time grows with
# untracked and modified non-ignored content, so generated media and render outputs belong in
# .gitignore. A tree that contains a submodule or embedded repository gets no fingerprint (Git
# records only its commit), so the Stop gate always runs verify.sh there.

# True inside a Git work tree.
vstate_in_git() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Prints the absolute state directory, creating it when needed. Returns 1 when none is usable.
vstate_dir() {
  local dir=""
  if vstate_in_git; then
    dir="$(git rev-parse --git-path claude-verify 2>/dev/null)" || dir=""
    case "$dir" in
      "" | /*) ;;
      *) dir="$(pwd)/$dir" ;;
    esac
    if [ -n "$dir" ] && mkdir -p "$dir" 2>/dev/null && [ -w "$dir" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
  fi
  dir="${TMPDIR:-/tmp}"
  dir="${dir%/}/claude-verify-$(id -u 2>/dev/null || echo 0)-$(pwd | cksum | awk '{ print $1 }')"
  mkdir -p "$dir" 2>/dev/null && [ -w "$dir" ] || return 1
  printf '%s\n' "$dir"
}

# Prints the path of record file $1 inside the state directory.
vstate_path() {
  local dir
  dir="$(vstate_dir)" || return 1
  printf '%s/%s\n' "$dir" "$1"
}

# Prints the first line of record file $1 (empty when absent), without a trailing CR.
vstate_get() {
  local file
  file="$(vstate_path "$1")" || return 1
  [ -f "$file" ] || return 0
  head -n 1 "$file" | tr -d '\r'
}

# Writes value $2 to record file $1 atomically.
vstate_set() {
  local file tmp
  file="$(vstate_path "$1")" || return 1
  tmp="$file.tmp.$$"
  if printf '%s\n' "$2" >"$tmp" 2>/dev/null && mv -f "$tmp" "$file" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp"
  return 1
}

# Prints the fingerprint of the current working tree. Returns 1 outside Git or on any Git error.
vstate_fingerprint() {
  local dir real_index objects tmp_index tmp_objects tree status=1
  vstate_in_git || return 1
  dir="$(vstate_dir)" || return 1
  real_index="$(git rev-parse --git-path index 2>/dev/null)" || return 1
  objects="$(git rev-parse --git-path objects 2>/dev/null)" || return 1
  case "$objects" in
    /*) ;;
    *) objects="$(pwd)/$objects" ;;
  esac
  tmp_index="$dir/fingerprint-index.$$"
  tmp_objects="$dir/fingerprint-objects.$$"
  rm -rf "$tmp_index" "$tmp_objects"
  if [ -f "$real_index" ] && ! cp "$real_index" "$tmp_index" 2>/dev/null; then
    rm -f "$tmp_index"
    return 1
  fi
  # New blobs and trees go to a throwaway object directory that reads the real store as an
  # alternate, so fingerprinting never adds objects to the repository. A gitlink (submodule or
  # embedded repository) records only its commit, so such a tree gets no fingerprint. awk reads
  # the whole listing, which keeps the pipeline status reliable under pipefail.
  if mkdir -p "$tmp_objects" &&
    GIT_INDEX_FILE="$tmp_index" GIT_OBJECT_DIRECTORY="$tmp_objects" \
      GIT_ALTERNATE_OBJECT_DIRECTORIES="$objects" git add -A >/dev/null 2>&1 &&
    ! GIT_INDEX_FILE="$tmp_index" git ls-files -s 2>/dev/null |
      awk '$1 == "160000" { found = 1 } END { exit !found }' &&
    tree="$(GIT_INDEX_FILE="$tmp_index" GIT_OBJECT_DIRECTORY="$tmp_objects" \
      GIT_ALTERNATE_OBJECT_DIRECTORIES="$objects" git write-tree 2>/dev/null)"; then
    printf '%s\n' "$tree"
    status=0
  fi
  rm -rf "$tmp_index" "$tmp_index.lock" "$tmp_objects"
  return "$status"
}

# Records the outcome of a verify run: vstate_record PASS|FAIL <fingerprint, may be empty>.
vstate_record() {
  local result="$1" fingerprint="${2:-}" now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  vstate_set last-result "$result $now ${fingerprint:-none}" || return 1
  if [ "$result" = "PASS" ] && [ -n "$fingerprint" ]; then
    vstate_set last-pass "$fingerprint" || return 1
  fi
  return 0
}
