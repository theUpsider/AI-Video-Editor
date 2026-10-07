#!/usr/bin/env bash
# .claude/hooks/stop-verify.sh — Stop-hook verification gate (registered in .claude/settings.json).
#
# Runs ./scripts/verify.sh when Claude is about to stop and the working tree differs from the last
# passing tree. A failure blocks stopping and feeds the log tail back to Claude; the
# CLAUDE_VERIFY_MAX_ATTEMPTS-th consecutive failure (default 3: it blocks twice and releases on the
# third) releases with a warning to the user.
#
# Input:  Stop hook JSON on stdin; reads "stop_hook_active" (true while Claude continues because a
#         Stop hook blocked).
#         Only an explicit false starts a fresh count; a missing or unparsable value counts as a
#         continued stop, so the gate stays bounded.
# Env:    CLAUDE_PROJECT_DIR          project root (default: two directories above this script)
#         CLAUDE_VERIFY_GATE=off      disables the gate (for humans; never set it to get green)
#         CLAUDE_VERIFY_MAX_ATTEMPTS  failed attempts until the gate releases (1 to 10, default 3;
#                                     with 1 the gate releases at the first failure)
# Exit:   0  stop allowed: verified, unchanged since the last pass, disabled, or released (then
#            stdout carries {"systemMessage": "..."})
#         2  stop blocked: stderr holds the log tail and repair guidance for Claude
#         1  hook setup error (non-blocking; Claude Code shows it to the user)
# State:  scripts/lib/verify-state.sh (last-pass, last-result, last.log, attempts).
# shellcheck source-path=SCRIPTDIR

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
HOOK_ROOT="$(cd "$HOOK_DIR/../.." && pwd)" || exit 1
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOOK_ROOT}"
VSTATE_LIB="$HOOK_ROOT/scripts/lib/verify-state.sh"
DEFAULT_MAX_ATTEMPTS=3
LOG_TAIL_LINES=40 # lines of the log fed back to Claude
LOG_LINE_MAX=200  # characters kept per line; 40 x 200 keeps the feedback under 10,000 characters

# shellcheck source=../../scripts/lib/verify-state.sh
. "$VSTATE_LIB" || {
  echo "stop-verify.sh: cannot load $VSTATE_LIB" >&2
  exit 1
}

# Prints stdin, or nothing when stdin is a terminal (manual run).
read_hook_input() {
  [ -t 0 ] || cat
}

# Prints the value of top-level boolean key $2 in JSON text $1 ("true", "false" or empty).
# Empty means unknown; callers treat every value except "false" as a continued stop.
# Only a key of the outermost object counts: the same key inside a nested object or a string
# decides nothing.
json_bool() {
  printf '%s' "$1" | tr -d '\r\n' | awk -v key="$2" '{
    text = $0; n = length(text); depth = 0; i = 1
    while (i <= n) {
      c = substr(text, i, 1)
      if (c == "\"") {
        j = i + 1
        while (j <= n) {
          d = substr(text, j, 1)
          if (d == "\\") { j += 2; continue }
          if (d == "\"") break
          j++
        }
        if (depth == 1 && substr(text, i + 1, j - i - 1) == key) {
          rest = substr(text, j + 1)
          if (match(rest, /^[ \t]*:[ \t]*[a-z]+/)) {
            value = substr(rest, RSTART, RLENGTH)
            sub(/^[ \t]*:[ \t]*/, "", value)
            print value
            exit
          }
        }
        i = j + 1
        continue
      }
      if (c == "{" || c == "[") depth++
      else if (c == "}" || c == "]") depth--
      i++
    }
  }'
}

# Escapes text for use inside a JSON string.
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\t\r\n' '   '
}

# Prints CLAUDE_VERIFY_MAX_ATTEMPTS when it is an integer from 1 to 10, else the default. The
# N-th consecutive failure releases, so a limit of N blocks N - 1 times: a limit of 1 never blocks
# (the first failure releases with the warning and the recorded FAIL), and 10 is the largest
# number of attempts a session spends on one stop.
max_attempts() {
  local value="${CLAUDE_VERIFY_MAX_ATTEMPTS:-$DEFAULT_MAX_ATTEMPTS}"
  case "$value" in
    [1-9] | 10) ;;
    *) value="$DEFAULT_MAX_ATTEMPTS" ;;
  esac
  printf '%s\n' "$value"
}

# Runs ./scripts/verify.sh with all output in log file $1. A missing or non-executable script fails.
run_verify() {
  if [ ! -x ./scripts/verify.sh ]; then
    printf 'ERROR: ./scripts/verify.sh is missing or not executable.\n' >"$1"
    return 1
  fi
  # The fast tier only: the gate runs on every stop, so it never renders media (AVE-REQ-097 AC-3).
  # The release tier runs before a requirement moves to done (develop § 8), at milestone reviews
  # and in CI.
  ./scripts/verify.sh --tier fast >"$1" 2>&1 </dev/null
}

# Increments and prints the failed-attempt counter. The stored value counts when it is a decimal
# number of one or two digits, read as decimal also with a leading zero (08 is eight); every
# other content counts as 0. The counter stops at 99, so the gate never writes a value that it
# would read as 0. When the counter cannot be stored, or reads back as another value, prints a
# value that still bounds the loop: 1 on a fresh stop (stop_hook_active false), else the maximum.
count_failed_attempt() {
  local stop_active="$1" max="$2" attempts
  attempts="$(vstate_get attempts)"
  case "$attempts" in
    [0-9] | [0-9][0-9]) attempts=$((10#$attempts)) ;;
    *) attempts=0 ;;
  esac
  [ "$attempts" -ge 99 ] || attempts=$((attempts + 1))
  if ! vstate_set attempts "$attempts" || [ "$(vstate_get attempts)" != "$attempts" ]; then
    if [ "$stop_active" = "false" ]; then attempts=1; else attempts="$max"; fi
  fi
  printf '%s\n' "$attempts"
}

# Cache hit: when a failed run on another tree came after the pass, make last-result and attempts
# describe the current, already verified tree again.
restore_pass_records() {
  case "$(vstate_get last-result)" in
    "PASS "*" $1") ;;
    *) vstate_record PASS "$1" || true ;;
  esac
  [ "$(vstate_get attempts)" = "0" ] || vstate_set attempts 0 || true
}

# Prints the end of log file $1 as Claude should see it: a line redrawn with carriage returns
# (progress output) reduced to its final state, at most LOG_TAIL_LINES lines of at most
# LOG_LINE_MAX characters each.
log_tail() {
  tail -c 65536 "$1" 2>/dev/null |
    awk -v max="$LOG_LINE_MAX" '{
      sub(/\r+$/, ""); n = split($0, part, "\r"); line = (n > 0) ? part[n] : ""
      if (length(line) > max) line = substr(line, 1, max) " [cut]"
      print line
    }' | tail -n "$LOG_TAIL_LINES"
}

# Blocks stopping: prints the failure report to stderr and exits 2.
block_stop() {
  local attempt="$1" max="$2" log="$3"
  {
    printf 'Stop blocked: ./scripts/verify.sh failed (gate attempt %s of %s).\n' "$attempt" "$max"
    printf -- '--- last %s lines of the verification log (long lines cut) ---\n' "$LOG_TAIL_LINES"
    log_tail "$log"
    printf -- '--- full log: %s ---\n' "$log"
    printf 'Diagnose and fix the root cause; never weaken checks. A check that needs a credential '
    printf 'belongs on its fake. If the fix needs the human (a tool or dependency the environment '
    printf 'cannot install, an external outage), record it in docs/PROGRESS.md § Known failures and '
    printf 'explain it in your reply — the gate releases after %s consecutive attempts.\n' "$max"
  } >&2
  exit 2
}

# Allows stopping with a warning for the user: prints {"systemMessage": ...} and exits 0.
release_stop() {
  printf '{"systemMessage": "%s"}\n' "$(json_escape "$1")"
  exit 0
}

main() {
  local input stop_active max fingerprint log attempts

  [ "${CLAUDE_VERIFY_GATE:-}" = "off" ] && exit 0
  input="$(read_hook_input)"
  stop_active="$(json_bool "$input" stop_hook_active)"
  max="$(max_attempts)"

  cd "$PROJECT_DIR" 2>/dev/null ||
    release_stop "Verification gate skipped: cannot enter project directory $PROJECT_DIR."

  fingerprint="$(vstate_fingerprint)" || fingerprint=""
  if [ -n "$fingerprint" ] && [ "$fingerprint" = "$(vstate_get last-pass)" ]; then
    case "$(vstate_get last-result)" in
      "FAIL "*" $fingerprint") ;; # the newest run failed on this very tree: no cached pass overrules it
      *)
        restore_pass_records "$fingerprint"
        exit 0
        ;;
    esac
  fi

  if [ "$stop_active" = "false" ]; then vstate_set attempts 0 || true; fi

  log="$(vstate_path last.log)" ||
    release_stop "Verification gate skipped: no writable state directory for the log."

  if run_verify "$log"; then
    vstate_record PASS "$fingerprint" || true
    vstate_set attempts 0 || true
    exit 0
  fi

  vstate_record FAIL "$fingerprint" || true
  attempts="$(count_failed_attempt "$stop_active" "$max")"
  if [ "$attempts" -lt "$max" ]; then
    block_stop "$attempts" "$max" "$log"
  fi
  release_stop "Verification gate released after $attempts consecutive failed attempts: ./scripts/verify.sh still fails. Log: $log"
}

main
