#!/usr/bin/env bash
# scripts/tests/test-session-start.sh — SessionStart hook matrix (.claude/hooks/session-start.sh)
# in fixture repositories under a temp dir whose paths contain spaces. Needs git. Exit 0 when every
# check passes.
# Checks and mutations are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/session-start-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
# The fixtures are Git repositories of their own: with a temp dir inside a work tree their Git commands
# would act on that tree (AVE-REQ-097: a suite leaves the working tree unchanged).
if git -C "$T" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "test-session-start.sh: the temporary directory $T lies inside a Git work tree; set TMPDIR outside it" >&2
  exit 2
fi
export GIT_CEILING_DIRECTORIES="$T"
command -v git >/dev/null 2>&1 || { echo "test-session-start.sh: git is required" >&2; exit 2; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; printf '%s\n' "$OUT" | head -20; fi; }
ss() {  # ss <project dir> <json>
  OUT="$(cd "$T" && printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" "$1/.claude/hooks/session-start.sh" 2>"$T/.sserr")"; CODE=$?
  ERR="$(cat "$T/.sserr")"
}
# json <source> — the hook input of a session start from that source.
json() { printf '{"session_id":"t","hook_event_name":"SessionStart","source":"%s","model":"x"}' "$1"; }
START="$(json startup)"
COMPACT="$(json compact)"
# Claude Code starts the hook at startup, on resume and after compaction: every content check of the
# state block runs once per source (AVE-REQ-098 AC-2).
SOURCES="startup resume compact"
# every <name> <check> — the check holds for the output of a session start from each source.
every() {
  local source
  for source in $SOURCES; do
    ss "$R" "$(json "$source")"
    check "$1 [source=$source]" "$2"
  done
}

R="$T/ss repo"; "$W/make-fixture.sh" "$R" >/dev/null
(cd "$R" && git init -q -b main && git config user.email t@t && git config user.name t && git add -A && git commit -qm "chore: first" && for i in 2 3 4 5 6 7 8 9 10; do git commit -q --allow-empty -m "chore: commit $i"; done) 2>/dev/null

# AVE-REQ-098 AC-2: every session start, resume and compaction injects the state reconstructed
# from the repository (branch, commits, uncommitted paths, last verification, PROGRESS.md).
echo "## repo with commits, no verification yet: startup, resume and compact"
every "exit 0" '[ "$CODE" = 0 ] && [ -z "$ERR" ]'
every "header names the source" 'printf "%s\n" "$OUT" | sed -n 1p | quiet -x "## Project state (injected by .claude/hooks/session-start.sh — source: $source)"'
every "branch, HEAD and change count line" 'printf "%s\n" "$OUT" | quiet -E "^- Branch: main \| HEAD: [0-9a-f]{7,} \| Uncommitted paths: 0$"'
every "clean tree: no uncommitted list" '! printf "%s\n" "$OUT" | quiet "^- Uncommitted"'
every "no verification recorded" 'printf "%s\n" "$OUT" | quiet -x -- "- Last verification: none recorded by the Stop gate (run ./scripts/verify.sh)"'
every "exactly 8 recent commits under their heading" 'printf "%s\n" "$OUT" | quiet -x -- "- Recent commits:" && [ "$(printf "%s\n" "$OUT" | grep -c "^  [0-9a-f]\{7,\} chore: commit")" = 8 ]'
every "PROGRESS.md included between delimiters" 'printf "%s\n" "$OUT" | awk "/^--- docs\/PROGRESS.md ---\$/ { on = 1; next } /^--- end of docs\/PROGRESS.md ---\$/ { on = 0 } on && /^## Known failures\$/ { found = 1 } END { exit !found }"'
ss "$R" "$START"
check "startup: the last line is the resume-project instruction" 'printf "%s\n" "$OUT" | tail -1 | quiet "^Follow the \`resume-project\` skill"'
check "compact output (<= 40 lines here)" '[ "$(printf "%s\n" "$OUT" | wc -l)" -le 40 ]'
echo "     ($(printf "%s\n" "$OUT" | wc -l) lines)"
ss "$R" "$(json resume)"
check "resume: the last line is the resume-project instruction" 'printf "%s\n" "$OUT" | tail -1 | quiet "^Follow the \`resume-project\` skill"'
ss "$R" "$COMPACT"
check "compact: the last line asks to re-anchor on the repository state" 'printf "%s\n" "$OUT" | tail -1 | quiet "^Context was compacted: re-anchor on the repository state before continuing"'

echo "## verification states"
printf '{"stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" >/dev/null 2>&1
every "PASS matching the current tree" 'printf "%s\n" "$OUT" | quiet -E "^- Last verification: PASS [0-9T:-]+Z \(matches the current tree\)$"'
objs_before="$(cd "$R" && git count-objects -v | awk '$1 == "count:" || $1 == "size:" { printf "%s ", $2 }')"
printf 'x\n' > "$R/untracked.txt"
every "stale after an untracked change; change counted" 'printf "%s\n" "$OUT" | quiet "(stale: the tree changed since)" && printf "%s\n" "$OUT" | quiet "Uncommitted paths: 1$"'
check "fingerprinting the untracked file writes no objects ($objs_before)" '[ "$(cd "$R" && git count-objects -v | awk '"'"'$1 == "count:" || $1 == "size:" { printf "%s ", $2 }'"'"')" = "$objs_before" ]'
# AVE-REQ-098 AC-1, AVE-REQ-098 AC-2: the changed files themselves are listed, bounded.
printf '\nchanged\n' >> "$R/docs/ARCHITECTURE.md"
every "uncommitted list names the modified and the untracked file" 'printf "%s\n" "$OUT" | quiet -x -- "- Uncommitted (git status --short):" && printf "%s\n" "$OUT" | quiet -x "   M docs/ARCHITECTURE.md" && printf "%s\n" "$OUT" | quiet -x "  ?? untracked.txt"'
for i in $(seq 1 24); do : > "$R/extra-$i.txt"; done
every "uncommitted list capped at 20 lines with the remainder counted" '[ "$(printf "%s\n" "$OUT" | grep -c "^  ?? extra-\|^   M \|^  ?? untracked")" = 20 ] && printf "%s\n" "$OUT" | quiet -x "  \[6 more; run git status --short\]" && printf "%s\n" "$OUT" | quiet "Uncommitted paths: 26$"'
rm -f "$R"/extra-*.txt
(cd "$R" && git checkout -q -- docs/ARCHITECTURE.md)
mkdir -p "$R/vendor/sub" && (cd "$R/vendor/sub" && git init -q && git config user.email t@t && git config user.name t && printf 'v\n' > f && git add f && git commit -qm s)
ss "$R" "$START"
check "embedded repository: match with the current tree unknown" 'printf "%s\n" "$OUT" | quiet "(match with the current tree unknown)"'
rm -rf "$R/vendor"
rm "$R/untracked.txt"; chmod -x "$R/.claude/hooks/session-start.sh"
printf '{"stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" >/dev/null 2>&1
chmod +x "$R/.claude/hooks/session-start.sh"
every "FAIL shows the log path (tree differs again after the fix)" 'printf "%s\n" "$OUT" | quiet "^- Last verification: FAIL .*(stale: the tree changed since); log: .*/.git/claude-verify/last.log$"'

echo "## other hook inputs"
ss "$R" '{"source":"resume"}'
check "an input that holds the source alone names it" 'printf "%s\n" "$OUT" | sed -n 1p | quiet "source: resume)$" && printf "%s\n" "$OUT" | tail -1 | quiet "^Follow the"'
ss "$R" ''
check "empty stdin: source unknown, exit 0" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | sed -n 1p | quiet "source: unknown)$"'

echo "## PROGRESS.md variants"
awk 'BEGIN { for (i = 1; i <= 150; i++) print "line " i }' >> "$R/docs/PROGRESS.md"
ss "$R" "$START"
check "capped at 120 lines with a truncation note" 'printf "%s\n" "$OUT" | quiet "^\[truncated: showing 120 of 162 lines; read docs/PROGRESS.md for the rest\]$" && ! printf "%s\n" "$OUT" | quiet "^line 109$"'
sed 's/$/\r/' "$R/docs/PROGRESS.md" > "$R/p.tmp" && mv "$R/p.tmp" "$R/docs/PROGRESS.md"
ss "$R" "$START"
check "CRLF stripped" '! printf "%s" "$OUT" | quiet "$(printf "\r")"'
rm "$R/docs/PROGRESS.md"
ss "$R" "$START"
check "missing PROGRESS.md: notice and exit 0" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet "^- docs/PROGRESS.md is missing"'

echo "## repository with no commits"
N="$T/ss nocommit"; "$W/make-fixture.sh" "$N" >/dev/null; (cd "$N" && git init -q -b main)
ss "$N" "$START"
check "no commits yet, no commit list, exit 0" '[ "$CODE" = 0 ] && [ -z "$ERR" ] && printf "%s\n" "$OUT" | quiet "HEAD: no commits yet" && ! printf "%s\n" "$OUT" | quiet "^- Recent commits"'
check "uncommitted paths counted" 'printf "%s\n" "$OUT" | quiet -E "Uncommitted paths: [1-9][0-9]*$"'
ss "$N" "$COMPACT"
check "no commits + compact" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | tail -1 | quiet "^Context was compacted"'

echo "## detached HEAD, plain directory, broken environments"
(cd "$R" && git checkout -q --detach HEAD~1)
ss "$R" "$START"
check "detached HEAD reported" 'printf "%s\n" "$OUT" | quiet "^- Branch: detached HEAD | HEAD: "'
G="$T/ss plain"; "$W/make-fixture.sh" "$G" >/dev/null
OUT="$(printf '%s' "$START" | CLAUDE_PROJECT_DIR="$G" TMPDIR="$T/tmp2" "$G/.claude/hooks/session-start.sh" 2>&1)"; CODE=$?
check "plain directory: not a Git work tree, exit 0, no stderr" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet "^- Git: not a Git work tree" && ! printf "%s\n" "$OUT" | quiet -i "fatal"'
rm -rf "$T/tmp2"
mv "$G/scripts/lib/verify-state.sh" "$G/vs.bak"
OUT="$(printf '%s' "$START" | CLAUDE_PROJECT_DIR="$G" "$G/.claude/hooks/session-start.sh" 2>/dev/null)"; CODE=$?
check "missing lib: exit 0, still prints progress and instruction" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet "Last verification: unknown (scripts/lib/verify-state.sh is missing)" && printf "%s\n" "$OUT" | tail -1 | quiet "resume-project"'
mv "$G/vs.bak" "$G/scripts/lib/verify-state.sh"
OUT="$(printf '%s' "$START" | CLAUDE_PROJECT_DIR="/no such dir" "$G/.claude/hooks/session-start.sh" 2>&1)"; CODE=$?
check "unreachable project dir: exit 0 with a message" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet "cannot enter project directory"'
OUT="$(printf '%s' "$START" | env -u CLAUDE_PROJECT_DIR "$R/.claude/hooks/session-start.sh" 2>&1)"; CODE=$?
check "CLAUDE_PROJECT_DIR unset: uses the hook's project" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet "^- Branch: detached HEAD"'
OUT="$(printf '%s' "$START" | PATH="/nonexistent" CLAUDE_PROJECT_DIR="$R" /bin/bash "$R/.claude/hooks/session-start.sh" 2>/dev/null)"; CODE=$?
check "no tools on PATH at all: still exit 0" '[ "$CODE" = 0 ]'

echo "SESSION START TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
