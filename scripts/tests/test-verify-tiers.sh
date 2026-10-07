#!/usr/bin/env bash
# scripts/tests/test-verify-tiers.sh — tier selection of scripts/verify.sh (fast ⊂ media ⊂ release),
# its exit codes, the environment its steps start from and its heavy-media lock, in a fixture
# project whose component step file registers one marker step per tier plus steps that report the
# lock state and the environment; and the options of the real backend step file, with a stub of uv
# and with the real ruff and mypy of the backend environment. Needs git, python3, flock, timeout
# and uv. Every run uses a lock file in the suite's temp dir, so the suite never waits for a real
# media run. Exit 0 when every check passes.
# Checks are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/verify-tiers.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
# The fixtures are Git repositories of their own: with a temp dir inside a work tree their Git commands
# would act on that tree (AVE-REQ-097: a suite leaves the working tree unchanged).
if git -C "$T" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "test-verify-tiers.sh: the temporary directory $T lies inside a Git work tree; set TMPDIR outside it" >&2
  exit 2
fi
export GIT_CEILING_DIRECTORIES="$T"
for tool in git python3 flock timeout uv; do
  command -v "$tool" >/dev/null 2>&1 || { echo "test-verify-tiers.sh: $tool is required" >&2; exit 2; }
done
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export AVE_HEAVY_LOCK="$T/heavy-media.lock"
unset AVE_HEAVY_LOCK_HELD VERIFY_TIER
REPO="$(cd "$W/../.." && pwd)"
R="$T/project"
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  ok   $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1   [$2]"; fi; }
run() {  # run [args...] -> CODE, OUT (combined output); VERIFY_TIER comes from the caller
  OUT="$(cd "$R" && ./scripts/verify.sh "$@" 2>&1)"; CODE=$?
}
# run_bounded [args...] — run with a 60 s limit, for runs that must not wait for the lock; the run
# gets no copy of the suite's lock descriptor (8).
run_bounded() {
  OUT="$(cd "$R" && timeout 60 ./scripts/verify.sh "$@" 2>&1 8>&-)"; CODE=$?
}
ran() { printf '%s\n' "$OUT" | quiet -x "<== PASS: $1 step.*"; }
passed() { printf '%s\n' "$OUT" | quiet -x "<== PASS: $1 (.*"; }
waited() { printf '%s\n' "$OUT" | quiet "^verify.sh: waiting for the heavy-media lock"; }
# path_without <command>... — prints PATH with the named commands hidden: a directory that holds
# one of them is replaced by a mirror of its other entries.
path_without() {
  local dir entry name hide cmd mirror out=""
  local IFS=:
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    hide=0
    for cmd in "$@"; do [ -e "$dir/$cmd" ] && hide=1; done
    if [ "$hide" -eq 1 ]; then
      mirror="$(mktemp -d "$T/path-mirror.XXXXXX")" || return 1
      for entry in "$dir"/*; do
        name="${entry##*/}"
        for cmd in "$@"; do [ "$name" = "$cmd" ] && continue 2; done
        ln -s "$entry" "$mirror/$name"
      done
      dir="$mirror"
    fi
    out="${out:+$out:}$dir"
  done
  printf '%s\n' "$out"
}

"$W/make-fixture.sh" "$R" >/dev/null
cat > "$R/scripts/verify.d/20-backend.sh" <<'STEPS'
# fixture component step file: one marker step per tier, and the lock state each tier sees
# shellcheck shell=bash
# passes when this run holds the heavy-media lock: a child process finds AVE_HEAVY_LOCK_HELD=1 in
# its environment, and a new open of the lock file cannot take the lock
LOCK_HELD='[ "${AVE_HEAVY_LOCK_HELD:-}" = 1 ] && ! flock -n "${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}" true'
fast_step "fast step" true
fast_step "lock state" sh -c 'echo "lock state: AVE_HEAVY_LOCK_HELD=${AVE_HEAVY_LOCK_HELD:-unset}"'
media_step "media step" true
media_step "media tier holds the lock" sh -c "$LOCK_HELD"
# with a file <lock file>.leave-process: leaves a background process behind and writes its PID
# there (the lock file's path is the one variable of the suite that reaches a step)
media_step "media background process" sh -c 'pidfile="${AVE_HEAVY_LOCK:-}.leave-process"; [ ! -e "$pidfile" ] ||
  { sleep 300 </dev/null >/dev/null 2>&1 & echo "$!" >"$pidfile"; }'
release_step "release step" true
release_step "release tier holds the lock" sh -c "$LOCK_HELD"
STEPS
(cd "$R" && git init -q && git config user.email t@t && git config user.name t && git add -A && git commit -qm init)

# AVE-REQ-097 AC-1
echo "## tier membership"
run
check "default tier is fast" '[ "$CODE" = 0 ] && ran fast && ! ran media && ! ran release && printf "%s" "$OUT" | quiet "PASS — tier fast"'
run --tier media
check "--tier media adds the media steps" '[ "$CODE" = 0 ] && ran fast && ran media && ! ran release'
run --tier=release
check "--tier=release runs every tier" '[ "$CODE" = 0 ] && ran fast && ran media && ran release'
VERIFY_TIER=media run
check "VERIFY_TIER selects the tier" '[ "$CODE" = 0 ] && ran media && ! ran release'
VERIFY_TIER=media run --tier fast
check "--tier overrides VERIFY_TIER" '[ "$CODE" = 0 ] && ! ran media'

# AVE-REQ-097 AC-1
echo "## usage errors"
run --tier full
check "unknown tier exits 2" '[ "$CODE" = 2 ] && printf "%s" "$OUT" | quiet "unknown tier: full"'
run --tier
check "missing tier value exits 2" '[ "$CODE" = 2 ]'
run --fast
check "unexpected argument exits 2" '[ "$CODE" = 2 ] && printf "%s" "$OUT" | quiet "unexpected argument"'

# AVE-REQ-097 AC-2, AVE-REQ-097 AC-4: the steps start from a named set of variables, read no
# bytecode from the tree and no module from a user site directory; the run names this tree in its
# manifest and starts in a directory that did not exist.
echo "## the run's environment"
cp "$R/scripts/verify.d/20-backend.sh" "$T/20-fixture.sh"
cat >> "$R/scripts/verify.d/20-backend.sh" <<'STEPS'
fast_step "environment names" env
fast_step "environment" sh -c 'echo "env: AUTOLOAD=${PYTEST_DISABLE_PLUGIN_AUTOLOAD-unset} SAFEPATH=${PYTHONSAFEPATH-unset} NOUSERSITE=${PYTHONNOUSERSITE-unset} HOME=${HOME-unset} TZ=${TZ-unset}"
  case "${PYTHONPYCACHEPREFIX-}" in "" | "$PWD"/*) ;; "$AVE_RUN_SCRATCH"/*) [ -d "$AVE_RUN_SCRATCH" ] && echo "env: bytecode prefix in the scratch directory of the run, outside the tree" ;; esac
  echo "env: scratch $AVE_RUN_SCRATCH"'
fast_step "python3 step" python3 -c 'print("python3 step ran")'
STEPS
mkdir -p "$T/other" && (cd "$T/other" && git init -q && git config user.email t@t && git config user.name t && printf 'x\n' > f && git add -A && git commit -qm other)
HERE_FP="$(cd "$R" && . scripts/lib/verify-state.sh && vstate_fingerprint)"
HERE_COMMIT="$(cd "$R" && git rev-parse HEAD)"
# A module that Python loads at its start from a user site directory: one under HOME, which is in
# the named set, and one under a user base the caller names. Each leaves a file beside itself.
SITE="$(python3 -c 'import sys; print("lib/python%d.%d/site-packages" % sys.version_info[:2])')"
for base in "$T/home/.local" "$T/userbase"; do
  mkdir -p "$base/$SITE"
  printf 'import os\nopen(os.path.join(os.path.dirname(__file__), "loaded"), "a").close()\n' > "$base/$SITE/usercustomize.py"
done
(cd "$T" && env -u PYTHONNOUSERSITE HOME="$T/home" python3 -c pass && env -u PYTHONNOUSERSITE PYTHONUSERBASE="$T/userbase" python3 -c pass)
check "control: without the run, Python loads the module of each user site directory" '[ -e "$T/home/.local/$SITE/loaded" ] && [ -e "$T/userbase/$SITE/loaded" ]'
rm -f "$T/home/.local/$SITE/loaded" "$T/userbase/$SITE/loaded"
mkdir -p "$T/tmpdir"
# The caller sets every variable of the named set, and beside them variables that redirect Git,
# change what Python, pytest and uv load, name the media tools or the run's own directories, the
# two option variables that the shell keeps read-only (with the options a script has anyway), an
# arbitrary name and an exported function that would stand in for `true`. The caller sets no
# OLDPWD: the shell then exports the one of its own start at the first cd, unless the run unsets it.
NAMED=(PATH="$PATH" HOME="$T/home" USER=tester LOGNAME=tester TMPDIR="$T/tmpdir" LANG=C.UTF-8 LC_ALL=C.UTF-8
  TZ=UTC UV_PROJECT_ENVIRONMENT="$T/venv" UV_CACHE_DIR="$T/uv-cache" UV_PYTHON_INSTALL_DIR="$T/uv-python"
  AVE_HEAVY_LOCK="$AVE_HEAVY_LOCK")
OUTSIDE=(VERIFY_TIER=media PYTEST_ADDOPTS=--collect-only PYTEST_PLUGINS=x PYTHONPATH=/nonexistent
  PYTHONHOME=/nonexistent PYTHONSTARTUP=/nonexistent PYTHONOPTIMIZE=2 PYTHONWARNINGS=ignore PYTHONINSPECT=1
  PYTHONUSERBASE="$T/userbase" PYTHONPYCACHEPREFIX="$R/pycache" UV_ENV_FILE="$T/uv.env" UV_NO_SYNC=1
  BASH_ENV=/nonexistent ENV=/nonexistent CDPATH=/nonexistent SHELLOPTS=braceexpand:hashall:interactive-comments
  BASHOPTS=cmdhist GIT_DIR="$T/other/.git"
  GIT_WORK_TREE="$T/other" GIT_INDEX_FILE=/nonexistent/index GIT_OBJECT_DIRECTORY=/nonexistent
  GIT_ALTERNATE_OBJECT_DIRECTORIES=/nonexistent GIT_COMMON_DIR=/nonexistent GIT_NAMESPACE=other
  GIT_CONFIG_COUNT=abc AVE_FFMPEG=/nonexistent/ffmpeg AVE_FFPROBE=/nonexistent/ffprobe
  AVE_EVIDENCE_DIR=/nonexistent AVE_RUN_SCRATCH=/nonexistent AVE_VAR_DIR=/nonexistent XDG_CONFIG_HOME=/nonexistent
  CLAUDE_VERIFY_GATE=off ANY_OTHER_NAME=1 'BASH_FUNC_true%%=() { echo "the function of the caller ran"; return 1; }')
# The names a step sees: the caller's variables of the named set, the run's own, the shell's own.
EXPECTED_NAMES="$(printf '%s\n' PATH HOME USER LOGNAME TMPDIR LANG LC_ALL TZ UV_PROJECT_ENVIRONMENT UV_CACHE_DIR \
  UV_PYTHON_INSTALL_DIR AVE_HEAVY_LOCK AVE_HEAVY_LOCK_HELD PYTHONSAFEPATH PYTHONNOUSERSITE \
  PYTEST_DISABLE_PLUGIN_AUTOLOAD PYTHONPYCACHEPREFIX AVE_RUN_SCRATCH AVE_EVIDENCE_DIR PWD SHLVL _ | LC_ALL=C sort | tr '\n' ' ')"
# names_seen — the variable names in the output of the step that runs `env`.
names_seen() {
  printf '%s\n' "$OUT" | awk '/^==> environment names$/ { on = 1; next } /^<== (PASS|FAIL): environment names / { on = 0 }
    on { sub(/=.*/, ""); print }' | LC_ALL=C sort | tr '\n' ' '
}
OUT="$(cd "$R" && env -i "${NAMED[@]}" "${OUTSIDE[@]}" ./scripts/verify.sh 2>&1)"; CODE=$?
check "the steps see the named set, the run's own variables and no other name" '[ "$CODE" = 0 ] && ran media && [ "$(names_seen)" = "$EXPECTED_NAMES" ]'
check "the run sets its own Python and pytest variables and passes on the values of the named set" 'printf "%s\n" "$OUT" | quiet -x "env: AUTOLOAD=1 SAFEPATH=1 NOUSERSITE=1 HOME=$T/home TZ=UTC"'
check "an exported function of the caller stands in for no command of a step" 'ran fast && ! printf "%s\n" "$OUT" | quiet "the function of the caller ran"'
check "no step loads a module from a user site directory" 'printf "%s\n" "$OUT" | quiet -x "python3 step ran" && [ ! -e "$T/home/.local/$SITE/loaded" ] && [ ! -e "$T/userbase/$SITE/loaded" ]'
check "the steps read bytecode from the run's scratch directory only" 'printf "%s\n" "$OUT" | quiet -x "env: bytecode prefix in the scratch directory of the run, outside the tree"'
check "the scratch directory is gone after the run" 's="$(printf "%s\n" "$OUT" | sed -n "s/^env: scratch //p")" && [ -n "$s" ] && [ ! -e "$s" ]'
check "GIT_DIR and GIT_WORK_TREE of another repository: the manifest names this tree" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && [ -n "$HERE_FP" ] && python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert (d[\"fingerprint\"], d[\"commit\"]) == (sys.argv[2], sys.argv[3]), d" "$m" "$HERE_FP" "$HERE_COMMIT"'
OUT="$(cd "$R" && bash -c 'for i in 0 1 2 3 4 5; do mkdir -p "var/verify/runs/$(date -u -d "+$i sec" +%Y%m%dT%H%M%SZ)-$$"; done; exec ./scripts/verify.sh' 2>&1)"; CODE=$?
check "a run directory prepared by the caller is never reused" '[ "$CODE" = 2 ] && printf "%s\n" "$OUT" | quiet "cannot create the run directory" && ! printf "%s\n" "$OUT" | quiet "^==> "'
# The shell passes on an environment entry whose name is no shell identifier and cannot unset it.
OUT="$(cd "$R" && env 'not.an-identifier=1' ./scripts/verify.sh 2>&1)"; CODE=$?
check "an environment entry that the shell cannot unset fails the run before any step" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet -x "verify.sh: FAIL — the environment holds names outside the named set of the steps: not.an-identifier" && ! printf "%s\n" "$OUT" | quiet "^==> "'

# AVE-REQ-097 AC-1, AVE-REQ-097 AC-4: a tier runs the registered step files, all of them.
echo "## step files"
printf 'fast_step "half a step" true\nif true; then\n' > "$R/scripts/verify.d/20-backend.sh"
run
check "a step file that cannot be loaded fails the tier" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet -F "<== FAIL: Load scripts/verify.d/20-backend.sh"'
sed 's/$/\r/' "$T/20-fixture.sh" > "$R/scripts/verify.d/20-backend.sh"
run
check "a step file with CRLF line ends fails the tier" '[ "$CODE" = 1 ]'
cp "$T/20-fixture.sh" "$R/scripts/verify.d/20-backend.sh"
printf 'fast_step "hidden step" true\nSTEPS_FAILED=0; FAILED_STEPS=""\n' > "$R/scripts/verify.d/99-local.sh"
run
check "an unregistered step file is never sourced and fails the control step" '[ "$CODE" = 1 ] && ! printf "%s\n" "$OUT" | quiet "hidden step" && printf "%s\n" "$OUT" | quiet -F "scripts/verify.d/99-local.sh: is no registered component step file"'
rm "$R/scripts/verify.d/99-local.sh"
run
check "the restored fixture passes again" '[ "$CODE" = 0 ] && ran fast'

# AVE-REQ-097 AC-2, AVE-REQ-097 AC-4: a file of the tree that its fingerprint does not name takes
# part in no status, diff or fingerprint, so a run that could load it fails, wherever the file
# lies and whatever hides it. The step admits the list of ignored paths of verify.sh
# (IGNORED_DIRECTORIES, IGNORED_FILES) and no other place.
echo "## files outside the fingerprint"
FILES_STEP="No file outside the fingerprint and the listed paths"
TREE_STEP="Working tree unchanged by verification"
check "the clean fixture passes the step" 'passed "$FILES_STEP"'
# plant <path> — writes a file there; unplant <path> <topmost directory the case created, if any>
plant() { mkdir -p "$R/$(dirname "$1")" && printf 'x\n' > "$R/$1"; }
unplant() { rm -f "$R/$1"; [ -z "${2:-}" ] || rm -rf "${R:?}/$2"; }
failed() { printf '%s\n' "$OUT" | quiet -F "<== FAIL: $1 ("; }
named() { printf '%s\n' "$OUT" | quiet -xF -- "$1"; }
clean_for_git() { [ -z "$(cd "$R" && git status --porcelain)" ]; }
as_committed() { [ -z "$(cd "$R" && git status --porcelain --ignored | grep -v "^!! var/")" ]; }
# The three forms of the review finding, each alone: a bytecode file where pytest finds it ahead
# of the product package, and a .gitignore file below the root that lists itself and hides the
# configuration of a tool or the target of a link.
plant backend/ave.pyc
run
check "an ignored backend/ave.pyc fails the run and is named" '[ "$CODE" = 1 ] && clean_for_git && failed "$FILES_STEP" && named backend/ave.pyc'
unplant backend/ave.pyc
printf '.gitignore\nmypy.ini\nruff.toml\n' > "$R/backend/.gitignore"
printf '[mypy]\nfiles = tests/__init__.py\n' > "$R/backend/mypy.ini"
printf 'exclude = ["src", "tests"]\n' > "$R/backend/ruff.toml"
run
check "a backend/.gitignore that lists itself, mypy.ini and ruff.toml fails the run, and the three are named" '[ "$CODE" = 1 ] && clean_for_git && failed "$FILES_STEP" && named backend/.gitignore && named backend/mypy.ini && named backend/ruff.toml'
rm -f "$R/backend/.gitignore" "$R/backend/mypy.ini" "$R/backend/ruff.toml"
printf '.gitignore\nhidden-note.md\n' > "$R/docs/.gitignore"
printf 'hidden\n' > "$R/docs/hidden-note.md"
run
check "a docs/.gitignore that lists itself and a link target fails the run, and both are named" '[ "$CODE" = 1 ] && clean_for_git && failed "$FILES_STEP" && named docs/.gitignore && named docs/hidden-note.md'
rm -f "$R/docs/.gitignore" "$R/docs/hidden-note.md"
# Paths that a rule of the root .gitignore ignores and the list does not admit: the directories
# of the first form of this step, the names of the list at another depth or in another place, a
# file of another kind inside a bytecode directory, and the rules the list leaves out. One run
# holds them all; the step names each path it fails on.
OUTSIDE_LIST='scripts/unittest.pyc
.claude/hooks/local.pyc
backend/tests/unit/test-results/conftest.py backend/tests/unit
backend/src/ave/dist/module.py backend/src
docs/.env
backend/.env.local
docs/.env.test.local
docs/CLAUDE.local.md
docs/.serena/project.yml docs/.serena
.venv/lib/site.py .venv
backend/src/.venv/lib/site.py backend/src
.pytest_cache/v/cache/lastfailed .pytest_cache
scripts/.ruff_cache/content/x scripts/.ruff_cache
backend/tests/.mypy_cache/3.11/x.json backend/tests/.mypy_cache
scripts/__pycache__/helper.py scripts/__pycache__
scripts/__pycache__/sub/helper.cpython-312.pyc scripts/__pycache__
backend/.coverage
backend/htmlcov/index.html backend/htmlcov
node_modules/x/index.js node_modules
dist/bundle.js dist
playwright-report/index.html playwright-report
test-results/result.json test-results'
while read -r planted created; do plant "$planted"; done <<<"$OUTSIDE_LIST"
run
check "ignored paths outside the list fail the run while Git reports the tree clean" '[ "$CODE" = 1 ] && clean_for_git && failed "$FILES_STEP"'
while read -r planted created; do
  check "an ignored $planted is named" 'named "$planted"'
  unplant "$planted" "$created"
done <<<"$OUTSIDE_LIST"
check "the fixture is as committed after the planted files are gone" 'as_committed'
# Files that Git lists nowhere: one inside a directory named .git below the root, and a FIFO. A
# FIFO under the name of a listed directory is no directory, so it fails as every other FIFO. A
# file name of the list counts at the place the list names: settings.local.json elsewhere fails.
mkdir -p "$R/docs/.git" && printf 'hidden\n' > "$R/docs/.git/hidden-note.md"
printf '{}\n' > "$R/docs/.git/settings.local.json"
mkfifo "$R/docs/notes.fifo" "$R/data"
run_bounded
GIT_LISTS='git ls-files --cached --others --exclude-per-directory=.gitignore && git ls-files --others --ignored --exclude-per-directory=.gitignore'
check "control: the two listings of Git hold a file that a rule ignores" 'plant docs/seen.pyc && (cd "$R" && eval "$GIT_LISTS") | quiet -x docs/seen.pyc; seen=$?; unplant docs/seen.pyc; [ "$seen" = 0 ]'
check "a file inside a directory named .git below the root and a FIFO fail the run, and no listing of Git holds them" '[ "$CODE" = 1 ] && clean_for_git && ! (cd "$R" && eval "$GIT_LISTS") | quiet -e hidden-note -e notes.fifo && failed "$FILES_STEP" && named docs/.git/hidden-note.md && named docs/notes.fifo'
check "a FIFO under the name of a listed directory fails the run" 'named data'
check "a settings.local.json outside .claude/ fails the run" 'named docs/.git/settings.local.json'
rm -rf "$R/docs/.git" "$R/docs/notes.fifo" "$R/data"
# A name with a line feed stays one line of the report, as the shell quotes it.
TWO_LINES="$(printf 'docs/two\nlines.pyc')"
printf -v TWO_LINES_QUOTED '%q' "$TWO_LINES"
printf 'x\n' > "$R/$TWO_LINES"
run
check "a name with a line feed is printed on one line, as the shell quotes it" '[ "$CODE" = 1 ] && failed "$FILES_STEP" && named "$TWO_LINES_QUOTED"'
rm -f "$R/$TWO_LINES"
# The tree holds one .gitignore, at its root: another one fails the run, tracked or untracked,
# also inside a directory of the list.
printf 'nothing-of-this-name\n' > "$R/docs/.gitignore"
run
check "an untracked .gitignore below the root fails the run and is named" '[ "$CODE" = 1 ] && failed "$FILES_STEP" && printf "%s\n" "$OUT" | quiet -x ".gitignore files besides the one at the root of the tree:" && named docs/.gitignore'
(cd "$R" && git add docs/.gitignore)
run
check "a tracked .gitignore below the root fails the run and is named" '[ "$CODE" = 1 ] && failed "$FILES_STEP" && named docs/.gitignore'
(cd "$R" && git rm -q -f --cached docs/.gitignore) && rm -f "$R/docs/.gitignore"
printf '!keep.py\n' > "$R/var/.gitignore"
(cd "$R" && git add -f var/.gitignore)
run
check "a tracked .gitignore inside a directory of the list fails the run and is named" '[ "$CODE" = 1 ] && failed "$FILES_STEP" && named var/.gitignore'
(cd "$R" && git rm -q -f --cached var/.gitignore) && rm -f "$R/var/.gitignore"
# The list: one planted path per entry, in one run. A path of the list passes the step; were its
# entry gone, the run would fail and name the path.
ODD_BYTE="$(printf 'scripts/__pycache__/caf\351.cpython-312.pyc')"
LISTED="var/fixtures/cache.pyc
data/media/clip.py data
.claude/worktrees/x/conftest.py .claude/worktrees
.serena/project.yml .serena
backend/.venv/lib/site.py backend/.venv
backend/.pytest_cache/v/cache/lastfailed backend/.pytest_cache
backend/.ruff_cache/content/x backend/.ruff_cache
backend/.mypy_cache/3.11/x.json backend/.mypy_cache
.claude/settings.local.json
CLAUDE.local.md
.env
.env.local
.env.test.local
scripts/__pycache__/evidence.cpython-312.pyc scripts/__pycache__
backend/tests/__pycache__/conftest.cpython-311-pytest-9.1.1.pyc backend/tests/__pycache__
$ODD_BYTE
scripts/tests/.DS_Store scripts/tests
docs/Thumbs.db"
while read -r planted created; do plant "$planted"; done <<<"$LISTED"
# The names of the list are bytes: under a UTF-8 locale the expressions still match a name that
# holds a byte outside UTF-8.
check "control: under the UTF-8 locale of this case an expression does not match that byte by itself" '! LC_ALL=C.UTF-8 bash -c '"'"'[[ $1 =~ ^[^/]*$ ]]'"'"' _ "${ODD_BYTE##*/}"'
LC_ALL=C.UTF-8 run
check "every path of the list passes the step, under a UTF-8 locale too" '[ "$CODE" = 0 ] && passed "$FILES_STEP" && passed "$TREE_STEP"'
while read -r planted created; do
  check "the list admits $(printf '%q' "$planted")" '! named "$(printf "%q" "$planted")"'
  unplant "$planted" "$created"
done <<<"$LISTED"
check "the fixture is as committed after the listed files are gone" 'as_committed'
# Git names an embedded repository and a gitlink as a whole (and the tree keeps no fingerprint
# then): the files below them count as named.
mkdir -p "$R/vendor/sub"
(cd "$R/vendor/sub" && git init -q && git config user.email t@t && git config user.name t && printf 'v1\n' > f.txt && git add f.txt && git commit -qm sub)
run
check "the files of an untracked embedded repository count as named" '[ "$CODE" = 0 ] && passed "$FILES_STEP" && passed "$TREE_STEP"'
(cd "$R" && git add vendor/sub 2>/dev/null)
run
check "the files below a gitlink count as named" '[ "$(cd "$R" && git ls-files -s vendor/sub | cut -d " " -f 1)" = 160000 ] && [ "$CODE" = 0 ] && passed "$FILES_STEP"'
(cd "$R" && git rm -q -f --cached vendor/sub)
rm -rf "$R/vendor"
# A step that leaves a file outside the list fails the run that wrote it: the tree is walked
# again after the steps.
printf 'fast_step "a step that leaves a file" sh -c "echo x > backend/leftover.pyc"\n' >> "$R/scripts/verify.d/20-backend.sh"
run
check "a file that a step leaves outside the list fails the working-tree step of the same run" '[ "$CODE" = 1 ] && passed "$FILES_STEP" && failed "$TREE_STEP" && named backend/leftover.pyc'
cp "$T/20-fixture.sh" "$R/scripts/verify.d/20-backend.sh"
rm -f "$R/backend/leftover.pyc"
run
check "the restored fixture passes both steps" '[ "$CODE" = 0 ] && passed "$FILES_STEP" && passed "$TREE_STEP" && as_committed'
# A Git command that fails inside a work tree proves nothing about the files of the tree: the
# step fails. A directory without a repository is the one skip.
cp "$R/.git/config" "$T/git-config.saved"
printf '[core\n' > "$R/.git/config"
run
check "a repository that Git cannot read fails the step" '[ "$CODE" = 1 ] && failed "$FILES_STEP" && printf "%s\n" "$OUT" | quiet -x "Git fails inside the work tree of $R/.git:"'
cp "$T/git-config.saved" "$R/.git/config"
cp "$R/.git/index" "$T/git-index.saved"
printf 'no index\n' > "$R/.git/index"
run
check "a listing that Git cannot produce fails the step" '[ "$CODE" = 1 ] && failed "$FILES_STEP" && printf "%s\n" "$OUT" | quiet -x "Git fails to list the files of this work tree."'
cp "$T/git-index.saved" "$R/.git/index"
run
check "the restored repository passes the step" '[ "$CODE" = 0 ] && passed "$FILES_STEP" && clean_for_git'
PLAIN="$T/plain-project"
"$W/make-fixture.sh" "$PLAIN" >/dev/null
OUT="$(cd "$PLAIN" && ./scripts/verify.sh 2>&1)"; CODE=$?
check "a directory without a repository skips the step" '[ "$CODE" = 0 ] && passed "$FILES_STEP" && printf "%s\n" "$OUT" | quiet -x "Skipped: outside a Git work tree (no .git here or above)."'

# AVE-REQ-097 AC-4: a suite whose cases were all skipped establishes nothing.
echo "## skipped suites"
NO_AWKS_PATH="$(path_without mawk gawk original-awk busybox)"
OUT="$(PATH="$NO_AWKS_PATH" bash "$W/test-checker.sh" --all-awks 2>&1)"; CODE=$?
check "test-checker.sh --all-awks without any of its awk implementations fails" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "ran no awk implementation"'

# AVE-REQ-097 AC-2, AVE-REQ-097 AC-4: the backend steps of the real step file.
echo "## the real backend step file"
cp "$REPO/scripts/verify.d/20-backend.sh" "$R/scripts/verify.d/20-backend.sh"
mkdir -p "$T/stub" && cat > "$T/stub/uv" <<'STUB' && chmod +x "$T/stub/uv"
#!/bin/sh
echo "uv $*"
case " $* " in *" pytest "*)
  echo "media tools of pytest $*: ${AVE_FFMPEG-unset} ${AVE_FFPROBE-unset}"
  for tool in ffmpeg ffprobe; do
    found="$(command -v "$tool" || echo none)"
    said="$("$tool" -version 2>&1)"
    status=$?
    echo "$tool on PATH of pytest $*: $found exit $status $(printf '%s\n' "$said" | sed -n 1p)"
  done ;;
esac
STUB
# The caller names media tools of its own: they are outside the named set, so no step sees them.
OUT="$(cd "$R" && AVE_FFMPEG=/nonexistent/ffmpeg AVE_FFPROBE=/nonexistent/ffprobe PATH="$T/stub:$PATH" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "the pytest steps take their configuration from pyproject.toml alone, and uv reads no environment file" 'printf "%s\n" "$OUT" | quiet -E "^uv run --frozen --quiet --no-env-file --directory backend pytest -c pyproject.toml -q -p no:cacheprovider --forbid-skips --evidence-report=.*/pytest-unit.json -m not media and not slow$"'
check "every uv call of the backend steps passes --no-env-file" '[ "$(printf "%s\n" "$OUT" | grep -c "^uv run ")" -ge 5 ] && ! printf "%s\n" "$OUT" | grep "^uv run " | quiet -v -- "^uv run --frozen --quiet --no-env-file --directory backend "'
check "a pytest step that left no report fails" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "no report: the pytest session ended before it wrote one" && printf "%s\n" "$OUT" | quiet -F "<== FAIL: Backend unit tests"'
# Each tool takes the configuration the tree tracks, by name, and neither an ignore file nor a
# cache of the tree: both ruff commands and the type checker, as the stub of uv saw them start.
RUFF_LINES="$(printf '%s\n' "$OUT" | grep -E "^uv run --frozen --quiet --no-env-file --directory backend ruff (format --check|check) ")"
check "the format check and the lint are the two ruff commands of the step file" '[ "$(printf "%s\n" "$RUFF_LINES" | grep -c .)" = 2 ] && printf "%s\n" "$RUFF_LINES" | quiet " ruff format --check " && printf "%s\n" "$RUFF_LINES" | quiet " ruff check "'
check "both ruff commands take their configuration from pyproject.toml by name" '[ "$(printf "%s\n" "$RUFF_LINES" | grep -c -- " --config pyproject\.toml ")" = 2 ]'
check "both ruff commands read no ignore file" '[ "$(printf "%s\n" "$RUFF_LINES" | grep -c -- " --no-respect-gitignore ")" = 2 ]'
check "both ruff commands read and write no cache" '[ "$(printf "%s\n" "$RUFF_LINES" | grep -c -- " --no-cache ")" = 2 ]'
check "the type checker takes its configuration from pyproject.toml by name" 'printf "%s\n" "$OUT" | quiet -E "^uv run .* mypy --config-file pyproject\.toml "'
check "the type checker reads no cache from the tree" 'printf "%s\n" "$OUT" | quiet -E "^uv run .* mypy .*--cache-dir=[^ ]*/verify-run\.[^/ ]*/mypy-cache$" && ! printf "%s\n" "$OUT" | quiet -F -- "--cache-dir=$R/"'
# The same options with the real ruff and mypy of the backend environment, in a project that
# holds a failing source file beside the files that would hide it: the configuration files a
# tool finds ahead of pyproject.toml, an ignore file, and a cache written for an earlier text.
# options_of <command words> — the arguments the step file gave uv for that command.
options_of() {
  printf '%s\n' "$OUT" | sed -n "s|^uv run --frozen --quiet --no-env-file --directory backend \($1 .*\)\$|\1|p" | sed -n 1p
}
RUFF_FORMAT="$(options_of "ruff format")"
RUFF_CHECK="$(options_of "ruff check")"
MYPY="$(options_of mypy | sed 's| --cache-dir=[^ ]*||') --cache-dir=$T/mypy-cache"
P="$T/tool-project"
BAD='import os\n\n\ndef broken() -> int:\n    return "text"\nx=1\n'
mkdir -p "$P"
printf '[tool.ruff.lint]\nselect = ["F"]\n\n[tool.mypy]\nfiles = ["bad.py"]\n' > "$P/pyproject.toml"
printf '%b' "$BAD" > "$P/bad.py"
printf 'VALUE = 1\n' > "$P/good.py"
# real <command…> — a tool of the backend environment, started in the project; sets CODE.
real() { (cd "$P" && uv run --frozen --quiet --no-env-file --project "$REPO/backend" "$@") >/dev/null 2>&1; CODE=$?; }
# ruff_codes / mypy_code — the exit codes of the tools under the options of the step file (words
# without blanks).
# shellcheck disable=SC2086
ruff_codes() { real $RUFF_FORMAT; printf '%s' "$CODE"; real $RUFF_CHECK; printf '%s' "$CODE"; }
# shellcheck disable=SC2086
mypy_code() { real $MYPY; printf '%s' "$CODE"; }
check "the step file names a ruff format, a ruff check and a mypy command" '[ -n "$RUFF_FORMAT" ] && [ -n "$RUFF_CHECK" ] && [ -n "$(options_of mypy)" ]'
check "control: the real format check, lint and type check fail the source file" '[ "$(ruff_codes)$(mypy_code)" = 111 ]'
printf 'exclude = ["bad.py"]\n' > "$P/ruff.toml"
printf '[mypy]\nfiles = good.py\n' > "$P/mypy.ini"
check "a ruff.toml and a mypy.ini beside pyproject.toml change no result" '[ "$(ruff_codes)$(mypy_code)" = 111 ]'
real ruff format --check --no-respect-gitignore --no-cache .; SHADOW="$CODE"
real ruff check --no-respect-gitignore --no-cache .; SHADOW="$SHADOW$CODE"
real mypy --cache-dir="$T/mypy-cache-shadow"; SHADOW="$SHADOW$CODE"
check "control: without the option each tool takes the file beside pyproject.toml and passes ($SHADOW)" '[ "$SHADOW" = 000 ]'
rm -f "$P/ruff.toml" "$P/mypy.ini"
printf 'bad.py\n' > "$P/.ignore"
check "an ignore file that names the source file changes no result" '[ "$(ruff_codes)" = 11 ]'
real ruff format --check --config pyproject.toml --no-cache .; IGNORE="$CODE"
real ruff check --config pyproject.toml --no-cache .; IGNORE="$IGNORE$CODE"
check "control: without the option ruff passes the source file over ($IGNORE)" '[ "$IGNORE" = 00 ]'
rm -f "$P/.ignore"
# A cache entry of ruff holds the time stamp and the mode of a file: an edited file with its
# earlier time stamp passes unread while the cache is in use.
printf 'VALUE = 2\n' > "$P/bad.py"
real ruff format --check --config pyproject.toml --no-respect-gitignore .; CACHED="$CODE"
real ruff check --config pyproject.toml --no-respect-gitignore .; CACHED="$CACHED$CODE"
touch -r "$P/bad.py" "$T/stamp"
printf '%b' "$BAD" > "$P/bad.py"
touch -r "$T/stamp" "$P/bad.py"
real ruff format --check --config pyproject.toml --no-respect-gitignore .; CACHED="$CACHED$CODE"
real ruff check --config pyproject.toml --no-respect-gitignore .; CACHED="$CACHED$CODE"
check "control: with its cache ruff passes an edited file that kept its time stamp ($CACHED)" '[ "$CACHED" = 0000 ] && [ -d "$P/.ruff_cache" ]'
check "a cache written for an earlier text changes no result" '[ "$(ruff_codes)" = 11 ]'
rm -rf "$P/.ruff_cache"
check "the tools leave no cache in the project" '[ "$(ruff_codes)$(mypy_code)" = 111 ] && [ ! -e "$P/.ruff_cache" ] && [ ! -e "$P/.mypy_cache" ] && [ -d "$T/mypy-cache" ]'
# AVE-REQ-097 AC-3: the fast tier renders nothing; its tests see media tools that refuse to run,
# through the variables that ave.proc reads and by name on PATH.
MEDIA_STUB="$R/scripts/lib/media-tier-only.sh"
check "the fast tier's tests see media tools that refuse to run" 'printf "%s\n" "$OUT" | quiet -E "^media tools of pytest .* -m not media and not slow: $MEDIA_STUB $MEDIA_STUB\$"'
for tool in ffmpeg ffprobe; do
  check "the fast tier's tests resolve $tool on PATH to a stand-in that exits 1" 'printf "%s\n" "$OUT" | quiet -E "^$tool on PATH of pytest .* -m not media and not slow: /.*/verify-run\.[^/]*/media-tier-only/$tool exit 1 media tools run in the media tier only"'
  check "the media tier's tests resolve $tool on PATH outside the stand-ins" 'printf "%s\n" "$OUT" | quiet -E "^$tool on PATH of pytest .* -m media or slow: " && ! printf "%s\n" "$OUT" | grep -E "^$tool on PATH of pytest .* -m media or slow: " | quiet "media-tier-only"'
done
check "the media tier's tests see the real media tools, whatever the caller named" 'printf "%s\n" "$OUT" | quiet -E "^media tools of pytest .* -m media or slow: unset unset\$"'
STUB_OUT="$("$MEDIA_STUB" -version 2>&1)"; STUB_CODE=$?
check "the stand-in exits 1 and names the media tier" '[ "$STUB_CODE" = 1 ] && printf "%s\n" "$STUB_OUT" | quiet "media tools run in the media tier only"'
cp "$T/20-fixture.sh" "$R/scripts/verify.d/20-backend.sh"

# AVE-REQ-097 AC-4: the fast tier, which the Stop gate runs, judges done requirements too.
echo "## the done step in every tier"
D="$T/done-project"
"$W/make-fixture.sh" "$D" with-reqs >/dev/null
cp "$REPO/scripts/verify.d/95-evidence.sh" "$D/scripts/verify.d/95-evidence.sh"
OUT="$(cd "$D" && ./scripts/verify.sh 2>&1)"; CODE=$?
check "the fast tier fails a done requirement that this run does not evidence" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet -F "<== FAIL: Done requirements evidenced by this run" && printf "%s\n" "$OUT" | quiet "^ERROR: AVE-REQ-001"'

# AVE-REQ-096 AC-4
echo "## one heavy media job at a time: the heavy-media lock"
AVE_HEAVY_LOCK_HELD=1 run --tier media
check "AVE_HEAVY_LOCK_HELD=1 while nobody holds the lock fails before any step" '[ "$CODE" = 1 ] && printf "%s\n" "$OUT" | quiet "nobody holds the heavy-media lock" && ! printf "%s\n" "$OUT" | quiet "^==> "'
run --tier media
check "media tier steps run while the run holds the lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && ! waited'
run --tier release
check "release tier steps run while the run holds the lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && passed "release tier holds the lock"'
exec 8>>"$AVE_HEAVY_LOCK"
flock -n 8 || { echo "test-verify-tiers.sh: cannot take $AVE_HEAVY_LOCK" >&2; exit 2; }
# The suite now holds the lock, like a media run of another agent.
run_bounded
check "fast tier takes no lock (runs while another process holds it)" '[ "$CODE" = 0 ] && printf "%s\n" "$OUT" | quiet -x "lock state: AVE_HEAVY_LOCK_HELD=unset" && ! waited'
AVE_HEAVY_LOCK_HELD=1 run_bounded --tier media
check "a caller that holds the lock sets AVE_HEAVY_LOCK_HELD=1: no second lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && ! waited'
mkfifo "$T/out.fifo"
(cd "$R" && exec ./scripts/verify.sh --tier media 8>&-) >"$T/out.fifo" 2>&1 &
pid=$!
exec 7<"$T/out.fifo"
FIRST=""; IFS= read -r -t 60 FIRST <&7
check "a media run while the lock is held prints one waiting line" 'printf "%s" "$FIRST" | quiet "^verify.sh: waiting for the heavy-media lock $AVE_HEAVY_LOCK "'
read -r -t 2 NEXT <&7; READ_STATUS=$?
check "it runs no step while the lock is held (no output for 2 s, process alive)" '[ "$READ_STATUS" -gt 128 ] && kill -0 "$pid" 2>/dev/null'
exec 8>&-  # release: the waiting run takes the lock and proceeds
OUT="$(cat <&7)"; exec 7<&-
wait "$pid"; CODE=$?
check "after the release it runs the media tier under the lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && printf "%s" "$OUT" | quiet "PASS — tier media" && ! waited'
mkdir -p "$T/tmpdir"
OUT="$(cd "$R" && env -u AVE_HEAVY_LOCK TMPDIR="$T/tmpdir" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "default lock file: \$TMPDIR/ave-heavy-media.lock" '[ "$CODE" = 0 ] && passed "media tier holds the lock" && [ -f "$T/tmpdir/ave-heavy-media.lock" ]'
: > "$AVE_HEAVY_LOCK.leave-process"
run --tier media
LEFT="$(cat "$AVE_HEAVY_LOCK.leave-process" 2>/dev/null)"
check "a process a step leaves behind keeps no lock after the run" '[ "$CODE" = 0 ] && [ -n "$LEFT" ] && kill -0 "$LEFT" 2>/dev/null && flock -n "$AVE_HEAVY_LOCK" true'
[ -z "$LEFT" ] || kill "$LEFT" 2>/dev/null
rm -f "$AVE_HEAVY_LOCK.leave-process"
NO_FLOCK_PATH="$(path_without flock)"
OUT="$(cd "$R" && PATH="$NO_FLOCK_PATH" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "without flock the media tier fails before any step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet "needs flock" && ! printf "%s" "$OUT" | quiet "^==> "'
OUT="$(cd "$R" && PATH="$NO_FLOCK_PATH" ./scripts/verify.sh 2>&1)"; CODE=$?
check "without flock the fast tier still runs" '[ "$CODE" = 0 ]'
# A run that cannot test the lock its caller claims to hold confirms nothing: it fails closed.
OUT="$(cd "$R" && AVE_HEAVY_LOCK_HELD=1 PATH="$NO_FLOCK_PATH" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "AVE_HEAVY_LOCK_HELD=1 without flock fails before any step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet "needs flock" && ! printf "%s" "$OUT" | quiet "^==> "'
OUT="$(cd "$R" && AVE_HEAVY_LOCK_HELD=1 AVE_HEAVY_LOCK="$T/no-such-directory/heavy-media.lock" ./scripts/verify.sh --tier release 2>&1)"; CODE=$?
check "AVE_HEAVY_LOCK_HELD=1 with a lock file that cannot be opened fails before any step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet "cannot open the heavy-media lock $T/no-such-directory/heavy-media.lock" && ! printf "%s" "$OUT" | quiet "^==> "'
mkdir -p "$T/failing-flock" && printf '#!/bin/sh\nexit 2\n' > "$T/failing-flock/flock" && chmod +x "$T/failing-flock/flock"
OUT="$(cd "$R" && AVE_HEAVY_LOCK_HELD=1 PATH="$T/failing-flock:$PATH" ./scripts/verify.sh --tier media 2>&1)"; CODE=$?
check "AVE_HEAVY_LOCK_HELD=1 with a lock that flock cannot test fails before any step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet "cannot be tested (flock exit 2)" && ! printf "%s" "$OUT" | quiet "^==> "'

# AVE-REQ-097 AC-4
echo "## a failing step fails the tier that runs it"
sed -i 's/media_step "media step" true/media_step "media step" false/' "$R/scripts/verify.d/20-backend.sh"
run
check "fast tier still passes (the failing step is not in it)" '[ "$CODE" = 0 ]'
run --tier media
check "media tier fails with exit 1 and names the step" '[ "$CODE" = 1 ] && printf "%s" "$OUT" | quiet -- "- media step (exit 1)"'
check "the failed run's manifest records FAIL" 'm="$(ls "$R"/var/verify/runs/*/manifest.json | tail -1)" && python3 -c "import json,sys; assert json.load(open(sys.argv[1]))[\"result\"] == \"FAIL\"" "$m"'
run --tier release
check "release tier fails too" '[ "$CODE" = 1 ]'

echo "VERIFY TIERS TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
