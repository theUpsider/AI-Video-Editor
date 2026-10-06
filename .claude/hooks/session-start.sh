#!/usr/bin/env bash
# .claude/hooks/session-start.sh — SessionStart hook (registered in .claude/settings.json).
#
# Claude Code adds this script's stdout to Claude's context at startup, resume, clear and compact.
# It prints a compact "Project state" block: branch, HEAD, the count and the list of uncommitted
# paths (`git status --short`, at most 20 lines), the result of the last Stop-gate verification
# and whether it matches the current tree, the last 8 commits, docs/PROGRESS.md (at most 120 lines)
# and the instruction to follow the resume-project skill.
#
# Input:  SessionStart hook JSON on stdin; reads "source".
# Env:    CLAUDE_PROJECT_DIR (project root; default: two directories above this script).
# Exit:   always 0; this hook never fails the session.
# shellcheck source-path=SCRIPTDIR

set -u

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOOK_ROOT}"
VSTATE_LIB="$HOOK_ROOT/scripts/lib/verify-state.sh"
PROGRESS_FILE="docs/PROGRESS.md"
PROGRESS_MAX_LINES=120
RECENT_COMMITS=8
UNCOMMITTED_MAX_LINES=20

# Prints the session source from the hook JSON on stdin ("unknown" when absent).
read_source() {
  local input="" source
  [ -t 0 ] || input="$(cat)"
  source="$(printf '%s' "$input" | tr -d '\r\n' |
    sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([A-Za-z_-]*\)".*/\1/p')"
  printf '%s\n' "${source:-unknown}"
}

print_git_state() {
  local branch head changes
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf -- '- Git: not a Git work tree\n'
    return 0
  fi
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" || branch="detached HEAD"
  head="$(git rev-parse --verify --quiet --short HEAD 2>/dev/null)" || head="no commits yet"
  changes="$(git status --porcelain 2>/dev/null | awk 'END { print NR }')"
  printf -- '- Branch: %s | HEAD: %s | Uncommitted paths: %s\n' "$branch" "$head" "${changes:-?}"
  print_uncommitted_paths
}

# Lists the uncommitted paths (`git status --short`), at most UNCOMMITTED_MAX_LINES of them.
print_uncommitted_paths() {
  git -c color.status=false status --short 2>/dev/null | awk -v max="$UNCOMMITTED_MAX_LINES" '
    NR == 1 { print "- Uncommitted (git status --short):" }
    NR <= max { print "  " $0 }
    END { if (NR > max) printf "  [%d more; run git status --short]\n", NR - max }'
}

# The record is the Stop gate's (scripts/lib/verify-state.sh): a run of ./scripts/verify.sh started
# by hand leaves it as it is and records its evidence in var/verify/.
print_verification_state() {
  local record result stamp recorded current freshness
  # shellcheck source=../../scripts/lib/verify-state.sh
  if ! . "$VSTATE_LIB"; then
    printf -- '- Last verification: unknown (scripts/lib/verify-state.sh is missing)\n'
    return 0
  fi
  record="$(vstate_get last-result)"
  if [ -z "$record" ]; then
    printf -- '- Last verification: none recorded by the Stop gate (run ./scripts/verify.sh)\n'
    return 0
  fi
  read -r result stamp recorded _ <<EOF
$record
EOF
  current="$(vstate_fingerprint)" || current=""
  if [ -z "$current" ] || [ "${recorded:-none}" = "none" ]; then
    freshness="match with the current tree unknown"
  elif [ "$current" = "$recorded" ]; then
    freshness="matches the current tree"
  else
    freshness="stale: the tree changed since"
  fi
  printf -- '- Last verification: %s %s (%s)' "$result" "$stamp" "$freshness"
  [ "$result" = "PASS" ] || printf '; log: %s' "$(vstate_path last.log)"
  printf '\n'
}

print_recent_commits() {
  git rev-parse --verify --quiet HEAD >/dev/null 2>&1 || return 0
  printf -- '- Recent commits:\n'
  git log --oneline --no-decorate -n "$RECENT_COMMITS" 2>/dev/null | sed 's/^/  /'
}

print_progress() {
  if [ ! -f "$PROGRESS_FILE" ]; then
    printf -- '- %s is missing: restore it before continuing.\n' "$PROGRESS_FILE"
    return 0
  fi
  printf -- '--- %s ---\n' "$PROGRESS_FILE"
  awk -v max="$PROGRESS_MAX_LINES" -v file="$PROGRESS_FILE" '
    { sub(/\r$/, "") }
    NR <= max { print }
    END {
      if (NR > max) printf "[truncated: showing %d of %d lines; read %s for the rest]\n", max, NR, file
    }' "$PROGRESS_FILE"
  printf -- '--- end of %s ---\n' "$PROGRESS_FILE"
}

print_instruction() {
  if [ "$1" = "compact" ]; then
    printf '%s\n' "Context was compacted: re-anchor on the repository state before continuing (follow the \`resume-project\` skill)."
  else
    printf '%s\n' "Follow the \`resume-project\` skill to reconstruct the current state, then continue with the highest-priority unblocked task."
  fi
}

main() {
  local source
  source="$(read_source)"
  if ! cd "$PROJECT_DIR" 2>/dev/null; then
    printf 'session-start.sh: cannot enter project directory %s\n' "$PROJECT_DIR"
    return 0
  fi

  # technical-foundation adds cloud dependency installation here when the stack needs it
  # (guarded by CLAUDE_CODE_REMOTE=true, idempotent, in its own subshell bounded by `timeout`,
  # output to stderr, one stdout result line).

  printf '## Project state (injected by .claude/hooks/session-start.sh — source: %s)\n' "$source"
  print_git_state
  print_verification_state
  print_recent_commits
  print_progress
  print_instruction "$source"
}

# The subshell isolates every failure, so the hook always exits 0.
(main)
exit 0
