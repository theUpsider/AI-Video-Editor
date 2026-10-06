#!/usr/bin/env bash
# scripts/lib/verify-state.sh — verification state shared by verify.sh and the Claude Code hooks.
#
# Sourced by .claude/hooks/stop-verify.sh, .claude/hooks/session-start.sh and scripts/verify.sh
# after they cd to the project root. Defines functions only; never run it directly. Compatible
# with bash 3.2.
#
# State directory: "$(git rev-parse --git-path claude-verify)" (inside .git, so never committed;
# one per worktree). Outside a Git work tree, or when that directory is not writable, the records
# go to a per-user temporary directory.
# Record files, written by the Stop gate (.claude/hooks/stop-verify.sh) alone:
#   last-pass    fingerprint of the last tree on which a Stop-gate run passed
#   last-result  "PASS|FAIL <ISO-8601 UTC> <fingerprint|none>" of the last Stop-gate run
#   last.log     full output of the last Stop-gate run
#   attempts     consecutive failed Stop-gate attempts
# A run of ./scripts/verify.sh started any other way (by hand, by CI) leaves these records as they
# are; its result is the manifest in var/verify/ (scripts/evidence.py).
#
# Fingerprint (AVE-REQ-097 AC-2): the hash of a sorted listing with one entry per path that
# `git ls-files --cached --others --exclude-per-directory=.gitignore` names, which is every index
# entry and every untracked file that no .gitignore file of the tree ignores. An entry holds
#   - the mode of the index entry, or `untracked`;
#   - the state of the working file, read from the file system: `missing`, `other` (a directory
#     or a special file at the path of an index entry), `link` with the hash of the link text, or
#     `file-x` / `file--` (a regular file with or without the executable bit) with the hash of the
#     file's raw bytes (`git hash-object --no-filters`);
#   - the path.
# The listing is made of the bytes and the executable bit a step reads. The index gives the paths
# and the committed mode and nothing else: an index flag (assume-unchanged, skip-worktree,
# fsmonitor-valid), an attribute (filter, ident, text, eol), a line-end conversion, an ignore rule
# outside the .gitignore files (.git/info/exclude, core.excludesFile) and the fsmonitor and
# untracked-cache state change no entry. HEAD takes no part, so a commit keeps a pass valid;
# staging a new file changes its entry from `untracked` to its index mode.
# A Windows host keeps no executable bit: every regular file counts as `file-x` there, which is
# what the development container reads through its mount of the same checkout, so both print one
# value for one checkout.
# A symbolic link enters with its link text: the file it points to is fingerprinted when it is a
# listed path itself, and stays outside the fingerprint when it lies outside the tree or is ignored.
# Hashing time grows with the listed content, so generated media and render outputs belong in
# .gitignore.
# A tree keeps no fingerprint, so that the Stop gate always runs verify.sh there and no evidence
# reads fresh, when it holds a gitlink (submodule) or an embedded repository (Git records only its
# commit), a listed path that begins with a double quote, holds a line feed or ends with a
# carriage return (no line of `git hash-object --stdin-paths` names it), or a listed file that
# cannot be read, and whenever a Git command of the listing fails.

# This checkout only: no Git variable of the caller points the commands at another repository,
# index or object store, or adds configuration to them.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
  GIT_COMMON_DIR GIT_NAMESPACE GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS

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

# vstate_ls_files <options> — the NUL-separated path listing of the fingerprint (header). Git 2.55
# gives this listing the same paths with and without the two settings (measured under an fsmonitor
# hook and the untracked cache, in the container and under Git for Windows): they pin the listing
# for a Git that would consult either state.
vstate_ls_files() {
  git -c core.fsmonitor=false -c core.untrackedCache=false ls-files -z "$@" 2>/dev/null
}

# Prints one record "<index mode | untracked><TAB><path><NUL>" per index entry and per untracked
# file that no .gitignore file ignores, then one empty record. Returns 1, without the empty
# record, when a Git command failed: a listing without it is incomplete.
vstate_listing() {
  local record tracked
  vstate_ls_files -s --cached | while IFS= read -r -d '' record; do
    printf '%s\t%s\0' "${record%% *}" "${record#*$'\t'}"
  done
  tracked="${PIPESTATUS[0]}"
  vstate_ls_files --others --exclude-per-directory=.gitignore | while IFS= read -r -d '' record; do
    printf 'untracked\t%s\0' "$record"
  done
  [ "$tracked${PIPESTATUS[0]}" = 00 ] || return 1
  printf '\0'
}

# vstate_entry <index mode | untracked> <path> — adds one entry to the listing that the calling
# vstate_fingerprint builds: its line to $entries and, for a regular file, its path to $regular
# (the files whose bytes are hashed, in the order of their entries). Returns 1 for a path that
# leaves the tree without a fingerprint (header).
vstate_entry() {
  local mode="$1" path="$2" state
  [ "$mode" != 160000 ] || return 1
  case "$path" in
    */ | '"'* | *$'\n'* | *$'\r') return 1 ;;
  esac
  if [ -L "$path" ]; then
    state="$(readlink -- "$path" 2>/dev/null | git hash-object --stdin 2>/dev/null)"
    [ -n "$state" ] || return 1
    state="link $state"
  elif [ -f "$path" ]; then
    if [ "$no_mode_bits" = 1 ] || [ -x "$path" ]; then state="file-x"; else state="file--"; fi
    regular+="$path"$'\n'
  elif [ -e "$path" ]; then
    state="other"
  else
    state="missing"
  fi
  entries+="$mode"$'\t'"$state"$'\t'"$path"$'\n'
}

# Prints the fingerprint of the current working tree (header). Returns 1 outside Git and for a
# tree that keeps no fingerprint.
vstate_fingerprint() {
  vstate_in_git || return 1
  (
    cd "./$(git rev-parse --show-cdup 2>/dev/null)" 2>/dev/null || exit 1
    entries="" regular="" complete=0 no_mode_bits=0 hashes=""
    case "$(uname -s 2>/dev/null)" in
      MINGW* | MSYS* | CYGWIN*) no_mode_bits=1 ;;
    esac
    while IFS= read -r -d '' record; do
      if [ -z "$record" ]; then
        complete=1
        continue
      fi
      vstate_entry "${record%%$'\t'*}" "${record#*$'\t'}" || exit 1
    done < <(vstate_listing | LC_ALL=C sort -z)
    [ "$complete" -eq 1 ] || exit 1
    if [ -n "$regular" ]; then
      hashes="$(printf '%s' "$regular" | git hash-object --no-filters --stdin-paths 2>/dev/null)" || exit 1
    fi
    printf '%s%s\n' "$entries" "$hashes" | git hash-object --stdin 2>/dev/null
  )
}

# Records the outcome of a Stop-gate run: vstate_record PASS|FAIL <fingerprint, may be empty>.
vstate_record() {
  local result="$1" fingerprint="${2:-}" now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  vstate_set last-result "$result $now ${fingerprint:-none}" || return 1
  if [ "$result" = "PASS" ] && [ -n "$fingerprint" ]; then
    vstate_set last-pass "$fingerprint" || return 1
  fi
  return 0
}
