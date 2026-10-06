#!/usr/bin/env bash
# scripts/tests/test-stop-hook.sh — Stop-hook gate matrix (.claude/hooks/stop-verify.sh) and the
# working-tree step of scripts/verify.sh, in fixture repositories under a temp dir whose paths
# contain spaces. Needs git and jq. Exit 0 when every check passes.
# Checks and mutations are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/stop-hook-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
# The fixtures are Git repositories of their own: with a temp dir inside a work tree their Git commands
# would act on that tree (AVE-REQ-097: a suite leaves the working tree unchanged).
if git -C "$T" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "test-stop-hook.sh: the temporary directory $T lies inside a Git work tree; set TMPDIR outside it" >&2
  exit 2
fi
export GIT_CEILING_DIRECTORIES="$T"
for tool in git jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "test-stop-hook.sh: $tool is required" >&2; exit 2; }
done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset CLAUDE_VERIFY_GATE CLAUDE_VERIFY_MAX_ATTEMPTS VERIFY_TIER
R="$T/stop repo"
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
J_FALSE='{"session_id":"t","transcript_path":"/x","cwd":"/x","hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"done"}'
J_TRUE='{"session_id":"t","hook_event_name":"Stop","stop_hook_active":true}'
hook() {  # hook <json> -> sets CODE OUT ERR
  local tmp="$T/.hookerr"
  OUT="$(cd "$T" && printf '%s' "$1" | CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>"$tmp")"; CODE=$?
  ERR="$(cat "$tmp")"
}
state() { cat "$R/.git/claude-verify/$1" 2>/dev/null; }
# shellcheck source=/dev/null
fp() { (cd "$R" && . scripts/lib/verify-state.sh && vstate_fingerprint); }
objects() { (cd "$R" && git count-objects -v | awk '$1 == "count:" || $1 == "size:" { printf "%s ", $2 }'); }
J_NOKEY='{"session_id":"t","hook_event_name":"Stop"}'
logrm() { rm -f "$R/.git/claude-verify/last.log"; }
logexists() { [ -f "$R/.git/claude-verify/last.log" ]; }

"$W/make-fixture.sh" "$R" with-reqs >/dev/null
# One marker step per tier, so the log shows which tiers the gate ran.
cat > "$R/scripts/verify.d/20-backend.sh" <<'STEPS'
# fixture component step file: one marker step per tier
# shellcheck shell=bash
fast_step "Marker fast step" true
media_step "Marker media step" true
release_step "Marker release step" true
STEPS
(cd "$R" && git init -q && git config user.email t@t && git config user.name t && git add -A && git commit -qm init)

echo "## pass path"
# AVE-REQ-097 AC-3: the gate runs the fast tier even when the session asks for a heavier one.
VERIFY_TIER=release hook "$J_FALSE"
check "gate ran the fast tier despite VERIFY_TIER=release" 'grep -q "verify.sh: PASS — tier fast" "$R/.git/claude-verify/last.log"'
check "gate ran the fast marker step" 'grep -qx "<== PASS: Marker fast step ([0-9]*s)" "$R/.git/claude-verify/last.log"'
check "gate ran no media or release marker step" '! grep -Eq "^==> Marker (media|release) step$" "$R/.git/claude-verify/last.log"'
check "exit 0 on pass" '[ "$CODE" = 0 ]'
check "stdout empty on pass" '[ -z "$OUT" ]'
check "last-pass = current fingerprint" '[ "$(state last-pass)" = "$(fp)" ]'
check "last-result PASS ISO-8601 fp" 'state last-result | quiet -E "^PASS [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z [0-9a-f]{40}$"'
check "attempts reset to 0" '[ "$(state attempts)" = 0 ]'
check "last.log holds verify output" 'grep -q "verify.sh: PASS" "$R/.git/claude-verify/last.log"'
check "verify.sh ran the working-tree step, then recorded the evidence manifest" '[ "$(grep "^==> " "$R/.git/claude-verify/last.log" | tail -2 | tr "\n" "|")" = "==> Working tree unchanged by verification|==> Evidence manifest|" ] && grep -q "PASS: Working tree unchanged by verification" "$R/.git/claude-verify/last.log" && grep -q "PASS: Evidence manifest" "$R/.git/claude-verify/last.log"'
# AVE-REQ-097 AC-2
check "the run left a manifest tied to the tree fingerprint" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d[\"result\"]==\"PASS\" and d[\"fingerprint\"]==sys.argv[2], d[\"fingerprint\"]" "$m" "$(fp)"'
check "state dir is ignored by git status" '[ -z "$(cd "$R" && git status --porcelain)" ]'

echo "## cached path"
logrm; before="$(state last-result)"
hook "$J_FALSE"
check "exit 0 on cache hit" '[ "$CODE" = 0 ] && [ -z "$OUT" ]'
check "verify not run (last.log not recreated)" '! logexists'
check "last-result untouched" '[ "$(state last-result)" = "$before" ]'
t0=$(date +%s%N); hook "$J_TRUE"; t1=$(date +%s%N)
check "cache hit also with stop_hook_active=true ($(( (t1-t0)/1000000 )) ms)" '[ "$CODE" = 0 ] && ! logexists'

echo "## tracked change invalidates, commit keeps the pass"
printf '\nMore text.\n' >> "$R/docs/ARCHITECTURE.md"
hook "$J_FALSE"
check "modified tracked file reruns verify" '[ "$CODE" = 0 ] && logexists'
(cd "$R" && git add -A && git commit -qm change); logrm
hook "$J_FALSE"
check "committing does not invalidate the pass" '[ "$CODE" = 0 ] && ! logexists'
(cd "$R" && git rm -q --cached docs/ROADMAP.md && git commit -qm untrack && git add docs/ROADMAP.md && git commit -qm retrack); logrm
hook "$J_FALSE"
check "history-only changes keep the pass" '[ "$CODE" = 0 ] && ! logexists'

echo "## untracked and ignored files"
objs_before="$(objects)"
printf 'scratch\n' > "$R/notes.txt"; logrm
hook "$J_FALSE"
check "untracked file invalidates the cache" '[ "$CODE" = 0 ] && logexists'
check "fingerprinting writes no objects to .git/objects ($objs_before)" '[ "$(objects)" = "$objs_before" ]'
rm "$R/notes.txt"; logrm
hook "$J_FALSE"
check "removing it changes the tree again (only the latest pass is cached: rerun)" '[ "$CODE" = 0 ] && logexists'
printf 'SECRET=1\n' > "$R/.env"; mkdir -p "$R/.claude/worktrees/x"; printf 'x\n' > "$R/.claude/worktrees/x/f"; logrm
hook "$J_FALSE"
check "ignored files (.env, worktrees) keep the cache" '[ "$CODE" = 0 ] && ! logexists'
check "real index untouched by fingerprinting" '[ -z "$(cd "$R" && git diff --cached --name-only)" ]'
check "the state directory holds the Stop gate's records only" '[ -z "$(ls "$R/.git/claude-verify" | grep -v -e "^last-pass$" -e "^last-result$" -e "^last.log$" -e "^attempts$")" ]'

# AVE-REQ-097 AC-2, AVE-REQ-097 AC-3: the fingerprint is made of the bytes a step reads, so no
# state of the local repository hides an edit from it: Git takes the edited tree for the committed
# one, the fingerprint changes, the gate runs verify.sh, and a pass recorded before the edit
# certifies nothing.
echo "## local Git states leave an edit visible in the fingerprint"
BROKEN='[x](no-such-file.md)'
HEAD_ARCHITECTURE='git cat-file blob HEAD:docs/ARCHITECTURE.md > docs/ARCHITECTURE.md'
# How Git shows that it takes the edited tree for the committed one: its status is empty; or, for
# a file that a filter or an ident keyword rewrites (the status goes by the changed size there),
# its diff is empty and the blob it would store for the edited file is the committed one.
STATUS_EMPTY='[ -z "$(git status --porcelain)" ]'
SAME_BLOB='[ -z "$(git diff)" ] && [ "$(git hash-object docs/ARCHITECTURE.md)" = "$(git rev-parse :docs/ARCHITECTURE.md)" ]'
# visible <name> <how Git shows it> <local Git state plus a failing edit> <cleanup> — the three
# commands run in the repository.
visible() {
  local shown="$2"
  hook "$J_FALSE"; logrm; before="$(fp)"
  if ! ( cd "$R" && eval "$3" ); then
    FAIL=$((FAIL+1)); echo "  SETUP FAIL $1"
    ( cd "$R" && eval "$4" )
    return
  fi
  check "$1: Git takes the edited tree for the committed one" '( cd "$R" && eval "$shown" )'
  check "$1: the edit changes the fingerprint" '[ -n "$before" ] && [ -n "$(fp)" ] && [ "$(fp)" != "$before" ]'
  hook "$J_FALSE"
  check "$1: the gate runs verify.sh and blocks" '[ "$CODE" = 2 ] && logexists'
  ( cd "$R" && eval "$4" )
  check "$1: the cleaned tree has the earlier fingerprint" '[ "$(fp)" = "$before" ]'
  hook "$J_FALSE"
  check "$1: the cleaned tree passes" '[ "$CODE" = 0 ]'
}
visible "skip-worktree entry" "$STATUS_EMPTY" 'git update-index --skip-worktree docs/ARCHITECTURE.md && printf "\n%s\n" "$BROKEN" >> docs/ARCHITECTURE.md' \
  'git update-index --no-skip-worktree docs/ARCHITECTURE.md && eval "$HEAD_ARCHITECTURE"'
visible "assume-unchanged entry" "$STATUS_EMPTY" 'git update-index --assume-unchanged docs/ARCHITECTURE.md && printf "\n%s\n" "$BROKEN" >> docs/ARCHITECTURE.md' \
  'git update-index --no-assume-unchanged docs/ARCHITECTURE.md && eval "$HEAD_ARCHITECTURE"'
visible "file hidden by .git/info/exclude" "$STATUS_EMPTY" 'mkdir -p .git/info && printf "docs/hidden-note.md\n" >> .git/info/exclude && printf "%s\n" "$BROKEN" > docs/hidden-note.md' \
  ': > .git/info/exclude && rm docs/hidden-note.md'
visible "file hidden by core.excludesFile" "$STATUS_EMPTY" 'printf "docs/hidden-note.md\n" > "$T/user-ignore" && git config core.excludesFile "$T/user-ignore" && printf "%s\n" "$BROKEN" > docs/hidden-note.md' \
  'git config --unset core.excludesFile && rm docs/hidden-note.md'
visible "clean filter from .git/info/attributes" "$SAME_BLOB" 'mkdir -p .git/info && printf "docs/ARCHITECTURE.md filter=pin\n" >> .git/info/attributes && git config filter.pin.clean "git cat-file blob HEAD:docs/ARCHITECTURE.md" && printf "\n%s\n" "$BROKEN" >> docs/ARCHITECTURE.md' \
  'rm .git/info/attributes && git config --unset filter.pin.clean && eval "$HEAD_ARCHITECTURE"'
# An ident attribute makes Git read "$Id: <anything> $" as "$Id$".
(cd "$R" && printf '\n$Id$\n' >> docs/ARCHITECTURE.md && git commit -qam "a line with an ident keyword")
visible "ident attribute from .git/info/attributes" "$SAME_BLOB" 'mkdir -p .git/info && printf "docs/ARCHITECTURE.md ident\n" >> .git/info/attributes && sed -i "s|^\\\$Id\\\$\$|\$Id: $BROKEN \$|" docs/ARCHITECTURE.md && grep -q "^\\\$Id: .x.(no-such-file.md) \\\$\$" docs/ARCHITECTURE.md' \
  'rm .git/info/attributes && eval "$HEAD_ARCHITECTURE"'
# A file-system monitor that reports no change: once Git holds the file for valid (`h` in
# `git ls-files -f`) it trusts the monitor and looks at the file no more. The old time stamp keeps
# the entry clear of Git's check for files as young as the index; one status takes the new time
# stamp into the index, the next marks the entry valid (at most five are tried).
printf '#!/bin/sh\nprintf "token\\0"\n' > "$T/fsmonitor-hook" && chmod +x "$T/fsmonitor-hook"
HELD_VALID='git ls-files -f docs/ARCHITECTURE.md | quiet "^h "'
visible "fsmonitor hook that reports no change" "$STATUS_EMPTY" 'git config core.fsmonitor "$T/fsmonitor-hook" && git config core.fsmonitorHookVersion 2 && git update-index --fsmonitor && touch -t 200001010000 docs/ARCHITECTURE.md && { for i in 1 2 3 4 5; do git status --porcelain >/dev/null; eval "$HELD_VALID" && break; done; eval "$HELD_VALID"; } && printf "\n%s\n" "$BROKEN" >> docs/ARCHITECTURE.md' \
  'git config --unset core.fsmonitor && git config --unset core.fsmonitorHookVersion && git update-index --no-fsmonitor && eval "$HEAD_ARCHITECTURE"'
# The same monitor beside the untracked cache: Git holds the listing of docs/ for valid while the
# time stamp of the directory stands, so its status shows no new file there. The fingerprint's
# listing reads the directory itself. This case records how Git behaves: Git 2.55 lists the file
# with and without the two settings of vstate_ls_files, and the fingerprint of the commit before
# this one passes the case too, so no one-line change of the library fails it.
visible "untracked cache under an fsmonitor hook that reports no change" "$STATUS_EMPTY" 'git config core.fsmonitor "$T/fsmonitor-hook" && git config core.fsmonitorHookVersion 2 && git config core.untrackedCache true && git update-index --fsmonitor --untracked-cache && touch -t 200001010000 docs && { for i in 1 2 3 4 5; do git status --porcelain >/dev/null; done; } && printf "%s\n" "$BROKEN" > docs/hidden-note.md && touch -t 200001010000 docs' \
  'git config --unset core.fsmonitor; git config --unset core.fsmonitorHookVersion; git config --unset core.untrackedCache; git update-index --no-fsmonitor --no-untracked-cache; rm -f docs/hidden-note.md'
mkdir -p "$T/other" && (cd "$T/other" && git init -q && git config user.email t@t && git config user.name t && printf 'x\n' > f && git add -A && git commit -qm other)
hook "$J_FALSE"; logrm
GIT_DIR="$T/other/.git" GIT_WORK_TREE="$T/other" hook "$J_FALSE"
check "GIT_DIR and GIT_WORK_TREE of another repository do not redirect the gate (cache hit for this tree)" '[ "$CODE" = 0 ] && ! logexists && [ ! -e "$T/other/.git/claude-verify" ]'
# Configuration that the caller adds through the environment takes no part either: with
# core.ignoreCase the rule /var/ of .gitignore would hide the untracked file VAR/note.txt.
mkdir -p "$R/VAR" && printf 'note\n' > "$R/VAR/note.txt"
plain="$(fp)"
check "GIT_CONFIG_COUNT of the caller changes no fingerprint" '[ -n "$plain" ] && [ "$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.ignoreCase GIT_CONFIG_VALUE_0=true fp)" = "$plain" ]'
check "GIT_CONFIG_PARAMETERS of the caller changes no fingerprint" '[ "$(GIT_CONFIG_PARAMETERS="'"'"'core.ignorecase=true'"'"'" fp)" = "$plain" ]'
check "control: with that setting Git itself hides the file" '[ -z "$(cd "$R" && git -c core.ignoreCase=true ls-files --others --exclude-standard)" ] && [ -n "$(cd "$R" && git ls-files --others --exclude-standard)" ]'
rm -rf "$R/VAR"

# AVE-REQ-097 AC-2: what an entry of the fingerprint holds.
echo "## the fingerprint reads bytes, executable bits and index modes"
hook "$J_FALSE"; before="$(fp)"
sed -i 's/$/\r/' "$R/scripts/verify.d/20-backend.sh"
check "a file rewritten with CRLF line ends changes the fingerprint" '[ -n "$before" ] && [ -n "$(fp)" ] && [ "$(fp)" != "$before" ]'
(cd "$R" && git checkout -q scripts/verify.d/20-backend.sh)
check "the restored file gives the earlier fingerprint" '[ "$(fp)" = "$before" ]'
sed -i '1s/$/\r/' "$R/scripts/verify.d/20-backend.sh"
check "one CRLF line end among LF line ends changes the fingerprint" '[ "$(cd "$R" && git ls-files --eol scripts/verify.d/20-backend.sh | awk "{ print \$2 }")" = w/mixed ] && [ -n "$(fp)" ] && [ "$(fp)" != "$before" ]'
(cd "$R" && git checkout -q scripts/verify.d/20-backend.sh)
chmod -x "$R/scripts/check_baseline.py"
check "a file that lost its executable bit changes the fingerprint" '[ -n "$(fp)" ] && [ "$(fp)" != "$before" ]'
chmod +x "$R/scripts/check_baseline.py"
check "the executable bit restored gives the earlier fingerprint" '[ "$(fp)" = "$before" ]'
(cd "$R" && git update-index --chmod=-x scripts/check_baseline.py)
check "another mode in the index changes the fingerprint" '[ -x "$R/scripts/check_baseline.py" ] && [ -n "$(fp)" ] && [ "$(fp)" != "$before" ]'
(cd "$R" && git update-index --chmod=+x scripts/check_baseline.py)
check "the index mode restored gives the earlier fingerprint" '[ "$(fp)" = "$before" ]'
rm "$R/docs/ROADMAP.md"
check "a deleted tracked file changes the fingerprint" '[ -n "$(fp)" ] && [ "$(fp)" != "$before" ]'
(cd "$R" && git checkout -q docs/ROADMAP.md)
ln -s ROADMAP.md "$R/docs/link.md"; linked="$(fp)"
check "a symbolic link enters the fingerprint" '[ -n "$linked" ] && [ "$linked" != "$before" ]'
ln -sfn PRODUCT.md "$R/docs/link.md"
check "another link text changes the fingerprint" '[ -n "$(fp)" ] && [ "$(fp)" != "$linked" ] && [ "$(fp)" != "$before" ]'
rm "$R/docs/link.md"
# Paths that no line of `git hash-object --stdin-paths` names: each stands beside the file that the
# line would name, so a fingerprint here would hold the bytes of the wrong file.
printf 'twin\n' > "$R/quoted.txt"; printf 'twin\n' > "$R/first"; printf 'twin\n' > "$R/second"
before_odd="$(fp)"
while IFS= read -r -d '' odd; do
  printf 'odd\n' > "$R/$odd"
  check "a path that no line can name leaves the tree without a fingerprint ($(printf '%q' "$odd"))" '[ -n "$before_odd" ] && [ -z "$(fp)" ]'
  rm -f "$R/$odd"
done < <(printf '%s\0' '"quoted.txt"' $'first\nsecond' $'first\r')
check "without those paths the tree has its fingerprint again" '[ "$(fp)" = "$before_odd" ]'
rm -f "$R/quoted.txt" "$R/first" "$R/second"
check "the fingerprint is the whole tree's from a directory below the root" '[ "$(cd "$R/docs" && . ../scripts/lib/verify-state.sh && vstate_fingerprint)" = "$before" ]'
cp "$R/.git/index" "$T/index.saved"; printf 'no index\n' > "$R/.git/index"
check "a repository whose index Git cannot read has no fingerprint" '(cd "$R" && git rev-parse --is-inside-work-tree >/dev/null 2>&1) && [ -z "$(fp)" ]'
cp "$T/index.saved" "$R/.git/index"
# A Windows host keeps no executable bit and reports every file of the checkout as the container
# reads it through its mount: executable. A stand-in for uname names such a host here.
mkdir -p "$T/windows" && printf '#!/bin/sh\necho MINGW64_NT-10.0\n' > "$T/windows/uname" && chmod +x "$T/windows/uname"
on_windows="$(PATH="$T/windows:$PATH" fp)"
chmod -x "$R/scripts/check_baseline.py"
check "on a host without mode bits every regular file counts as executable" '[ -n "$on_windows" ] && [ "$on_windows" != "$before" ] && [ "$(PATH="$T/windows:$PATH" fp)" = "$on_windows" ] && [ "$(fp)" != "$before" ]'
chmod +x "$R/scripts/check_baseline.py"
check "the fixture is as committed again" '[ -z "$(cd "$R" && git status --porcelain)" ] && [ "$(fp)" = "$before" ]'
hook "$J_FALSE"

# AVE-REQ-097 AC-4: a failing check blocks; it never passes as green.
echo "## failing path"
printf '\n[broken](no-such-file.md)\n' >> "$R/docs/ARCHITECTURE.md"
hook "$J_FALSE"
check "exit 2 on failure" '[ "$CODE" = 2 ]'
check "stdout empty when blocking" '[ -z "$OUT" ]'
check "stderr header with attempt 1 of 3" 'printf "%s" "$ERR" | quiet "gate attempt 1 of 3"'
check "stderr carries the log tail" 'printf "%s" "$ERR" | quiet "broken link to .no-such-file.md."'
check "stderr names the full log path" 'printf "%s" "$ERR" | quiet -F "full log: $R/.git/claude-verify/last.log"'
check "stderr carries the guidance" 'printf "%s" "$ERR" | quiet "never weaken checks" && printf "%s" "$ERR" | quiet "Known failures"'
check "guidance sends credential checks to fakes" 'printf "%s" "$ERR" | quiet "A check that needs a credential belongs on its fake. If the fix needs the human (a tool or dependency the environment cannot install, an external outage)"'
check "stderr tail capped (<= 44 lines)" '[ "$(printf "%s\n" "$ERR" | wc -l)" -le 44 ]'
check "attempts = 1" '[ "$(state attempts)" = 1 ]'
check "last-result FAIL" 'state last-result | quiet "^FAIL "'
check "last-pass kept from the previous pass" '[ -n "$(state last-pass)" ] && [ "$(state last-pass)" != "$(fp)" ]'
# A last-pass that names this tree (written by hand, or left by a pass that a later run of the same
# tree contradicted) never overrules the recorded failure: the gate runs again.
kept_pass="$(state last-pass)"; kept_attempts="$(state attempts)"; kept_result="$(state last-result)"
fp > "$R/.git/claude-verify/last-pass"; logrm
hook "$J_FALSE"
check "a cached pass never overrules the recorded failure of the same tree" '[ "$CODE" = 2 ] && logexists && state last-result | quiet "^FAIL .* $(fp)\$" && printf "%s" "$ERR" | quiet "broken link to .no-such-file.md."'
printf '%s\n' "$kept_pass" > "$R/.git/claude-verify/last-pass"
printf '%s\n' "$kept_attempts" > "$R/.git/claude-verify/attempts"
printf '%s\n' "$kept_result" > "$R/.git/claude-verify/last-result"

# AVE-REQ-097 AC-3, AVE-REQ-098 AC-4: the gate is bounded; it releases after its attempt limit.
echo "## escalation and release"
hook "$J_TRUE"
check "attempt 2 blocks (stop_hook_active=true)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 2 of 3"'
hook "$J_TRUE"
check "attempt 3 releases with exit 0" '[ "$CODE" = 0 ]'
check "release prints valid JSON systemMessage" 'printf "%s" "$OUT" | jq -e ".systemMessage | test(\"still fails\")" >/dev/null'
check "systemMessage names the log path" 'printf "%s" "$OUT" | jq -r .systemMessage | quiet -F "$R/.git/claude-verify/last.log"'
check "release writes nothing to stderr" '[ -z "$ERR" ]'
hook "$J_TRUE"
check "further continued stops stay released" '[ "$CODE" = 0 ] && [ -n "$OUT" ]'

echo "## reset on a fresh stop"
hook "$J_FALSE"
check "stop_hook_active=false resets attempts (attempt 1 again)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 1 of 3" && [ "$(state attempts)" = 1 ]'

echo "## stdin parsing"
PRETTY="$(printf '{\n  "session_id": "t",\n  "last_assistant_message": "I set \\"stop_hook_active\\": true in a test",\n  "stop_hook_active" :\n    false\n}\n')"
hook "$PRETTY"
check "pretty JSON with an embedded escaped key parses as false (reset)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 1 of 3"'
hook ""
check "empty stdin counts as a continued stop (attempt 2)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 2 of 3"'

# AVE-REQ-097 AC-3: no recursive Stop-hook loop, even without the stop_hook_active flag.
echo "## stop_hook_active absent: the gate stays bounded"
printf '0\n' > "$R/.git/claude-verify/attempts"
codes=""
for i in 1 2 3; do hook "$J_NOKEY"; codes="$codes$CODE"; done
check "missing key with failing verify: blocks 2,2 then releases 0 ($codes)" '[ "$codes" = 220 ] && printf "%s" "$OUT" | jq -e ".systemMessage | test(\"still fails\")" >/dev/null'
hook '{"stop_hook_active":"yes"}'
check "unparsable value counts as a continued stop (stays released)" '[ "$CODE" = 0 ] && [ -n "$OUT" ]'
hook "$J_FALSE"
check "explicit false starts a fresh count" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 1 of 3"'

echo "## max attempts override"
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_MAX_ATTEMPTS=1 CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>/dev/null)"; CODE=$?
check "CLAUDE_VERIFY_MAX_ATTEMPTS=1 releases on the first failure" '[ "$CODE" = 0 ] && printf "%s" "$OUT" | jq -e .systemMessage >/dev/null'
ERR="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_MAX_ATTEMPTS=abc CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>&1 >/dev/null)"; CODE=$?
check "invalid CLAUDE_VERIFY_MAX_ATTEMPTS falls back to 3" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "of 3"'
# AVE-REQ-097 AC-3: the limit stays in a small range, so no value releases at once or blocks forever.
for limit in 0 11 1000000000 99999999999999999999; do
  ERR="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_MAX_ATTEMPTS="$limit" CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>&1 >/dev/null)"; CODE=$?
  check "CLAUDE_VERIFY_MAX_ATTEMPTS=$limit falls back to 3" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 1 of 3"'
done
ERR="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_MAX_ATTEMPTS=10 CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>&1 >/dev/null)"; CODE=$?
check "CLAUDE_VERIFY_MAX_ATTEMPTS=10 is the largest limit" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 1 of 10"'
# Only the key of the outermost object decides whether a stop is fresh.
printf '2\n' > "$R/.git/claude-verify/attempts"
hook '{"stop_hook_active":true,"nested":{"stop_hook_active":false}}'
check "a nested stop_hook_active key does not restart the count (attempt 3 releases)" '[ "$CODE" = 0 ] && [ -n "$OUT" ]'
hook '{"nested":{"stop_hook_active":true},"list":[{"stop_hook_active":true}],"stop_hook_active":false}'
check "the outermost key decides: false after nested true is a fresh stop" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "attempt 1 of 3"'

# AVE-REQ-097 AC-3, AVE-REQ-098 AC-4: the gate counts only what it can read back, so a counter that
# is written and reads as another value still ends in a release.
echo "## a counter that cannot be read back"
rm -f "$R/.git/claude-verify/attempts"; mkdir "$R/.git/claude-verify/attempts"
codes=""
for j in "$J_FALSE" "$J_TRUE" "$J_TRUE"; do hook "$j"; codes="$codes$CODE"; done
check "the counter path is a directory: a fresh stop blocks once, a continued stop releases ($codes)" '[ "$codes" = 200 ] && printf "%s" "$OUT" | jq -e ".systemMessage | test(\"still fails\")" >/dev/null'
rm -rf "$R/.git/claude-verify/attempts"

echo "## gate off"
logrm
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_GATE=off CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
check "CLAUDE_VERIFY_GATE=off exits 0 silently without running verify" '[ "$CODE" = 0 ] && [ -z "$OUT" ] && ! logexists'

echo "## carriage-return progress output is cut to size"
cp "$R/scripts/verify.sh" "$T/verify.sh.saved"
cat > "$R/scripts/verify.sh" <<'EOF'
#!/usr/bin/env bash
i=0
while [ "$i" -lt 20000 ]; do printf 'frame=%05d fps=24 speed=1.0x\r' "$i"; i=$((i + 1)); done
printf 'FAIL: x\n'
awk 'BEGIN { s = ""; for (i = 0; i < 5000; i++) s = s "y"; print "long " s }'
exit 1
EOF
hook "$J_FALSE"
check "progress log: blocked" '[ "$CODE" = 2 ]'
check "progress log: stderr at most 10,000 bytes ($(printf "%s" "$ERR" | wc -c) bytes)" '[ "$(printf "%s" "$ERR" | wc -c)" -le 10000 ]'
check "progress log: keeps FAIL: x and the guidance" 'printf "%s" "$ERR" | quiet "FAIL: x" && printf "%s" "$ERR" | quiet "Diagnose and fix the root cause"'
check "progress log: long line cut" 'printf "%s" "$ERR" | quiet "^long y*y \[cut\]$" && printf "%s" "$ERR" | quiet "(long lines cut)"'
cp "$T/verify.sh.saved" "$R/scripts/verify.sh"; rm -f "$T/verify.sh.saved"

echo "## repair"
python3 - "$R/docs/ARCHITECTURE.md" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(s.replace('\n[broken](no-such-file.md)\n',''))
PY
hook "$J_TRUE"
check "repair back to the last passing tree: cache hit restores PASS record and attempts=0" '[ "$CODE" = 0 ] && [ -z "$OUT" ] && [ "$(state attempts)" = 0 ] && state last-result | quiet "^PASS"'

# AVE-REQ-097 AC-4: a missing or broken verification script fails the gate.
echo "## missing or non-executable verify.sh"
chmod -x "$R/scripts/verify.sh"
hook "$J_FALSE"
check "non-executable verify.sh fails the gate" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | quiet "missing or not executable"'
chmod +x "$R/scripts/verify.sh"

echo "## verify.sh: working tree unchanged by verification"
(cd "$R" && git add -A && { git commit -qm "baseline before output checks" >/dev/null 2>&1 || true; })
cp "$R/scripts/verify.sh" "$T/verify.sh.saved"
python3 - "$R/scripts/verify.sh" <<'PY2'
import sys; p=sys.argv[1]; s=open(p).read()
anchor='  run_step "Working tree unchanged by verification"'
assert anchor in s
open(p,'w').write(s.replace(anchor, '  run_step "Write a report" sh -c "date > report.txt"\n' + anchor, 1))
PY2
OUT="$(cd "$R" && ./scripts/verify.sh 2>&1)"; CODE=$?
check "a step that leaves an untracked file fails the last step" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "FAIL: Working tree unchanged by verification" && printf "%s\n" "$OUT" | quiet "A verification step changed the working tree" && printf "%s\n" "$OUT" | quiet "^?? report.txt$"'
rm -f "$R/report.txt"; printf 'report.txt\n' >> "$R/.gitignore"
OUT="$(cd "$R" && ./scripts/verify.sh 2>&1)"; CODE=$?
check "output to a .gitignore-d path passes" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet "PASS: Working tree unchanged by verification"'
cp "$T/verify.sh.saved" "$R/scripts/verify.sh"; rm -f "$T/verify.sh.saved" "$R/report.txt"
(cd "$R" && git checkout -q -- .gitignore)
logrm; hook "$J_FALSE"; logrm; hook "$J_FALSE"
check "second Stop on an unchanged tree skips verify.sh" '[ "$CODE" = 0 ] && [ -z "$OUT" ] && ! logexists'

echo "## submodule or embedded repository"
mkdir -p "$R/vendor/sub"
(cd "$R/vendor/sub" && git init -q && git config user.email t@t && git config user.name t && printf 'v1\n' > f.txt && git add f.txt && git commit -qm sub)
check "a tree holding an embedded repository has no fingerprint" '[ -z "$(fp)" ]'
logrm; hook "$J_FALSE"
check "Stop runs verify.sh there" '[ "$CODE" = 0 ] && logexists && grep -q "Skipped: no working-tree fingerprint" "$R/.git/claude-verify/last.log"'
printf 'dirty\n' >> "$R/vendor/sub/f.txt"; logrm; hook "$J_FALSE"
check "and again on the next Stop (dirty submodule content is never a cache hit)" '[ "$CODE" = 0 ] && logexists'
(cd "$R" && git add vendor/sub 2>/dev/null)
check "a tree with a gitlink in its index has no fingerprint" '[ "$(cd "$R" && git ls-files -s vendor/sub | cut -d " " -f 1)" = 160000 ] && [ -z "$(cd "$R" && git ls-files --others --exclude-standard)" ] && [ -z "$(fp)" ]'
(cd "$R" && git rm -q -f --cached vendor/sub)
rm -rf "$R/vendor"
check "without the repository the tree has a fingerprint again" '[ -n "$(fp)" ] && [ -z "$(cd "$R" && git status --porcelain)" ]'
check "the state directory still holds the Stop gate's records only" '[ -z "$(ls "$R/.git/claude-verify" | grep -v -e "^last-pass$" -e "^last-result$" -e "^last.log$" -e "^attempts$")" ]'

echo "## CLAUDE_PROJECT_DIR unset (defaults to the hook's project)"
OUT="$(cd / && printf '%s' "$J_FALSE" | env -u CLAUDE_PROJECT_DIR "$R/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
check "runs against the script's own project" '[ "$CODE" = 0 ] && [ -z "$OUT" ]'
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_PROJECT_DIR="/nonexistent dir" "$R/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
check "unreachable project dir releases with a systemMessage" '[ "$CODE" = 0 ] && printf "%s" "$OUT" | jq -e .systemMessage >/dev/null'

echo "## repository with no commits"
N="$T/stop nocommit"; "$W/make-fixture.sh" "$N" >/dev/null; (cd "$N" && git init -q)
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_PROJECT_DIR="$N" "$N/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
check "no-commit repo: pass path exit 0" '[ "$CODE" = 0 ] && [ -z "$OUT" ] && [ -n "$(cat "$N/.git/claude-verify/last-pass")" ]'
rm -f "$N/.git/claude-verify/last.log"
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_PROJECT_DIR="$N" "$N/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
check "no-commit repo: cached path" '[ "$CODE" = 0 ] && [ ! -f "$N/.git/claude-verify/last.log" ]'
check "no-commit repo: index still absent (nothing staged)" '[ ! -f "$N/.git/index" ]'

echo "## not a Git repository"
G="$T/stop plain"; "$W/make-fixture.sh" "$G" >/dev/null
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_PROJECT_DIR="$G" TMPDIR="$T/tmp" "$G/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
SD="$(find "$T/tmp" -maxdepth 1 -name "claude-verify-*" 2>/dev/null | head -1)"
check "plain dir: pass path exit 0, state in temp dir" '[ "$CODE" = 0 ] && [ -f "$SD/last.log" ] && grep -q " none$" "$SD/last-result"'
rm -f "$SD/last.log"
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_PROJECT_DIR="$G" TMPDIR="$T/tmp" "$G/.claude/hooks/stop-verify.sh" 2>&1)"; CODE=$?
check "plain dir: no caching (verify reruns)" '[ "$CODE" = 0 ] && [ -f "$SD/last.log" ]'
chmod -x "$G/.claude/hooks/session-start.sh"
codes=""
for j in "$J_FALSE" "$J_TRUE" "$J_TRUE"; do printf '%s' "$j" | CLAUDE_PROJECT_DIR="$G" TMPDIR="$T/tmp" "$G/.claude/hooks/stop-verify.sh" >/dev/null 2>&1; codes="$codes$?"; done
check "plain dir: failure escalates 2,2 then releases 0 ($codes)" '[ "$codes" = 220 ]'
rm -rf "$T/tmp"

echo "STOP HOOK TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
