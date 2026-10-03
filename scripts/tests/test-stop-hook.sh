#!/usr/bin/env bash
# scripts/tests/test-stop-hook.sh — Stop-hook gate matrix (.claude/hooks/stop-verify.sh) and the
# working-tree step of scripts/verify.sh, in fixture repositories under a temp dir whose paths
# contain spaces. Needs git and jq. Exit 0 when every check passes.
# Checks and mutations are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/stop-hook-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
for tool in git jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "test-stop-hook.sh: $tool is required" >&2; exit 2; }
done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
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
check "last-result PASS ISO-8601 fp" 'state last-result | grep -Eq "^PASS [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z [0-9a-f]{40}$"'
check "attempts reset to 0" '[ "$(state attempts)" = 0 ]'
check "last.log holds verify output" 'grep -q "verify.sh: PASS" "$R/.git/claude-verify/last.log"'
check "verify.sh ran the working-tree step, then recorded the evidence manifest" '[ "$(grep "^==> " "$R/.git/claude-verify/last.log" | tail -2 | tr "\n" "|")" = "==> Working tree unchanged by verification|==> Evidence manifest|" ] && grep -q "PASS: Working tree unchanged by verification" "$R/.git/claude-verify/last.log" && grep -q "PASS: Evidence manifest" "$R/.git/claude-verify/last.log"'
# AVE-REQ-097 AC-2
check "the run left a manifest tied to the tree fingerprint" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d[\"result\"]==\"PASS\" and len(d[\"fingerprint\"])==40" "$m"'
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
check "no temp index left behind" '[ -z "$(ls "$R/.git/claude-verify" | grep -v -e "^last-pass$" -e "^last-result$" -e "^last.log$" -e "^attempts$")" ]'

# AVE-REQ-097 AC-4: a failing check blocks; it never passes as green.
echo "## failing path"
printf '\n[broken](no-such-file.md)\n' >> "$R/docs/ARCHITECTURE.md"
hook "$J_FALSE"
check "exit 2 on failure" '[ "$CODE" = 2 ]'
check "stdout empty when blocking" '[ -z "$OUT" ]'
check "stderr header with attempt 1 of 3" 'printf "%s" "$ERR" | grep -q "gate attempt 1 of 3"'
check "stderr carries the log tail" 'printf "%s" "$ERR" | grep -q "broken link to .no-such-file.md."'
check "stderr names the full log path" 'printf "%s" "$ERR" | grep -qF "full log: $R/.git/claude-verify/last.log"'
check "stderr carries the guidance" 'printf "%s" "$ERR" | grep -q "never weaken checks" && printf "%s" "$ERR" | grep -q "Known failures"'
check "guidance sends credential checks to fakes" 'printf "%s" "$ERR" | grep -q "A check that needs a credential belongs on its fake. If the fix needs the human (a tool or dependency the environment cannot install, an external outage)"'
check "stderr tail capped (<= 44 lines)" '[ "$(printf "%s\n" "$ERR" | wc -l)" -le 44 ]'
check "attempts = 1" '[ "$(state attempts)" = 1 ]'
check "last-result FAIL" 'state last-result | grep -q "^FAIL "'
check "last-pass kept from the previous pass" '[ -n "$(state last-pass)" ] && [ "$(state last-pass)" != "$(fp)" ]'

# AVE-REQ-097 AC-3, AVE-REQ-098 AC-4: the gate is bounded; it releases after its attempt limit.
echo "## escalation and release"
hook "$J_TRUE"
check "attempt 2 blocks (stop_hook_active=true)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "attempt 2 of 3"'
hook "$J_TRUE"
check "attempt 3 releases with exit 0" '[ "$CODE" = 0 ]'
check "release prints valid JSON systemMessage" 'printf "%s" "$OUT" | jq -e ".systemMessage | test(\"still fails\")" >/dev/null'
check "systemMessage names the log path" 'printf "%s" "$OUT" | jq -r .systemMessage | grep -qF "$R/.git/claude-verify/last.log"'
check "release writes nothing to stderr" '[ -z "$ERR" ]'
hook "$J_TRUE"
check "further continued stops stay released" '[ "$CODE" = 0 ] && [ -n "$OUT" ]'

echo "## reset on a fresh stop"
hook "$J_FALSE"
check "stop_hook_active=false resets attempts (attempt 1 again)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "attempt 1 of 3" && [ "$(state attempts)" = 1 ]'

echo "## stdin parsing"
PRETTY="$(printf '{\n  "session_id": "t",\n  "last_assistant_message": "I set \\"stop_hook_active\\": true in a test",\n  "stop_hook_active" :\n    false\n}\n')"
hook "$PRETTY"
check "pretty JSON with an embedded escaped key parses as false (reset)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "attempt 1 of 3"'
hook ""
check "empty stdin counts as a continued stop (attempt 2)" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "attempt 2 of 3"'

# AVE-REQ-097 AC-3: no recursive Stop-hook loop, even without the stop_hook_active flag.
echo "## stop_hook_active absent: the gate stays bounded"
printf '0\n' > "$R/.git/claude-verify/attempts"
codes=""
for i in 1 2 3; do hook "$J_NOKEY"; codes="$codes$CODE"; done
check "missing key with failing verify: blocks 2,2 then releases 0 ($codes)" '[ "$codes" = 220 ] && printf "%s" "$OUT" | jq -e ".systemMessage | test(\"still fails\")" >/dev/null'
hook '{"stop_hook_active":"yes"}'
check "unparsable value counts as a continued stop (stays released)" '[ "$CODE" = 0 ] && [ -n "$OUT" ]'
hook "$J_FALSE"
check "explicit false starts a fresh count" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "attempt 1 of 3"'

echo "## max attempts override"
OUT="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_MAX_ATTEMPTS=1 CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>/dev/null)"; CODE=$?
check "CLAUDE_VERIFY_MAX_ATTEMPTS=1 releases on the first failure" '[ "$CODE" = 0 ] && printf "%s" "$OUT" | jq -e .systemMessage >/dev/null'
ERR="$(printf '%s' "$J_FALSE" | CLAUDE_VERIFY_MAX_ATTEMPTS=abc CLAUDE_PROJECT_DIR="$R" "$R/.claude/hooks/stop-verify.sh" 2>&1 >/dev/null)"; CODE=$?
check "invalid CLAUDE_VERIFY_MAX_ATTEMPTS falls back to 3" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "of 3"'

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
check "progress log: keeps FAIL: x and the guidance" 'printf "%s" "$ERR" | grep -q "FAIL: x" && printf "%s" "$ERR" | grep -q "Diagnose and fix the root cause"'
check "progress log: long line cut" 'printf "%s" "$ERR" | grep -q "^long y*y \[cut\]$" && printf "%s" "$ERR" | grep -q "(long lines cut)"'
cp "$T/verify.sh.saved" "$R/scripts/verify.sh"; rm -f "$T/verify.sh.saved"

echo "## repair"
python3 - "$R/docs/ARCHITECTURE.md" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(s.replace('\n[broken](no-such-file.md)\n',''))
PY
hook "$J_TRUE"
check "repair back to the last passing tree: cache hit restores PASS record and attempts=0" '[ "$CODE" = 0 ] && [ -z "$OUT" ] && [ "$(state attempts)" = 0 ] && state last-result | grep -q "^PASS"'

# AVE-REQ-097 AC-4: a missing or broken verification script fails the gate.
echo "## missing or non-executable verify.sh"
chmod -x "$R/scripts/verify.sh"
hook "$J_FALSE"
check "non-executable verify.sh fails the gate" '[ "$CODE" = 2 ] && printf "%s" "$ERR" | grep -q "missing or not executable"'
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
check "a step that leaves an untracked file fails the last step" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | grep -q "FAIL: Working tree unchanged by verification" && printf "%s\n" "$OUT" | grep -q "A verification step changed the working tree" && printf "%s\n" "$OUT" | grep -q "^?? report.txt$"'
rm -f "$R/report.txt"; printf 'report.txt\n' >> "$R/.gitignore"
OUT="$(cd "$R" && ./scripts/verify.sh 2>&1)"; CODE=$?
check "output to a .gitignore-d path passes" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | grep -q "PASS: Working tree unchanged by verification"'
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
rm -rf "$R/vendor"
check "no temp index or object directory left behind" '[ -z "$(ls "$R/.git/claude-verify" | grep -v -e "^last-pass$" -e "^last-result$" -e "^last.log$" -e "^attempts$")" ]'

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
