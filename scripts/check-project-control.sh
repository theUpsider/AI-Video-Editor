#!/usr/bin/env bash
# scripts/check-project-control.sh — enforces the mechanical invariants of the project-control files.
#
# Usage:  ./scripts/check-project-control.sh      (run by ./scripts/verify.sh; no arguments)
# Checks: 1 required files exist                    6 relative Markdown links resolve
#         2 scripts and hooks are executable        7 docs/PROGRESS.md headings; no line claims
#         3 .claude/settings.json is valid JSON       that work is running
#         4 agent frontmatter                       8 requirement files (docs/requirements/README.md)
#         5 skill frontmatter                       9 ADR files (docs/decisions/README.md)
#                                                  10 requirement matrix in docs/TRACEABILITY.md
#        11 task briefs (docs/briefs/README.md): every heading once and in template order, no empty
#           section, an AVE-REQ ID under Requirements, a commit under Input revision, each judged
#           without HTML comments; docs/briefs/ holds briefs (*.md), README.md, drafts/ and
#           handbacks/ only; each handback in docs/briefs/handbacks/ is named after its brief
#        12 .claude/settings.json policy: no permission bypass, the SessionStart hook runs on
#           startup, resume and compact, hook commands start no loop, sleep or background job and
#           none runs asynchronously; the Stop gate is one handler of type command with exactly
#           the registered command, and no setting switches it off or changes the hooks' shell
# Output: every violation as "ERROR: <path>: <message>", "WARN: ..." for a check that could not
#         run, then an "OK: ..." or "FAILED: ..." summary.
# Exit:   0 no errors · 1 errors found · 2 usage error
# Portability: bash 3.2+, POSIX awk/grep/sed (mawk, gawk, BSD awk, busybox); CRLF tolerant.
#              Check 12 needs python3 and warns without it.
# Maintenance: add every file other files depend on to REQUIRED_FILES; keep the rules in sync with
# docs/requirements/README.md, docs/decisions/README.md, docs/TRACEABILITY.md and docs/PROGRESS.md.
# Baseline integrity (the requirements package and its import) is scripts/check_baseline.py's job.
# Regression tests: scripts/tests/run.sh (test-checker.sh exercises every rule here).

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
SELF="scripts/check-project-control.sh"
TAB="$(printf '\t')"

# Check 1: files the workflow depends on (.github/workflows/verify.yml and docs/product-inputs/ excepted).
REQUIRED_FILES='
CLAUDE.md
README.md
.gitignore
.gitattributes
.env.example
docs/PRODUCT.md
docs/ARCHITECTURE.md
docs/ROADMAP.md
docs/PROGRESS.md
docs/ASSUMPTIONS.md
docs/TRACEABILITY.md
docs/requirements/README.md
docs/requirements/IMPORT_MAPPING.md
docs/decisions/README.md
docs/briefs/README.md
docs/decisions/ADR-001-specification-driven-development-workflow.md
.claude/settings.json
.claude/agents/architect.md
.claude/agents/implementer.md
.claude/agents/reviewer.md
.claude/agents/tester.md
.claude/agents/researcher.md
.claude/skills/product-definition/SKILL.md
.claude/skills/product-definition/baseline-capabilities.md
.claude/skills/technical-foundation/SKILL.md
.claude/skills/develop/SKILL.md
.claude/skills/implement-requirement/SKILL.md
.claude/skills/verify-requirement/SKILL.md
.claude/skills/architecture-review/SKILL.md
.claude/skills/milestone-review/SKILL.md
.claude/skills/resume-project/SKILL.md
.claude/hooks/session-start.sh
.claude/hooks/stop-verify.sh
scripts/verify.sh
scripts/dev-container.sh
.devcontainer/Dockerfile
scripts/verify.d/10-requirements.sh
scripts/verify.d/15-evidence-tooling.sh
scripts/verify.d/20-backend.sh
scripts/verify.d/90-tooling.sh
scripts/verify.d/95-evidence.sh
scripts/evidence.py
backend/pyproject.toml
backend/uv.lock
backend/tests/evidence_plugin.py
scripts/check-project-control.sh
scripts/check_baseline.py
scripts/reqfile.py
scripts/requirements/import_baseline.py
scripts/lib/verify-state.sh
scripts/lib/media-tier-only.sh
'

# Check 7: docs/PROGRESS.md headings (exact lines).
PROGRESS_HEADINGS='# Current project state|## Current milestone|## Current objective|## In progress|## Recently completed|## Next recommended work|## Blockers|## Known failures|## Important recent decisions|## Verification status'
# Check 11: task brief headings (exact lines) in template order, from docs/briefs/README.md.
BRIEF_HEADINGS='## Requirements|## Input revision|## Allowed paths|## Forbidden paths|## Dependencies and constraints|## Test commands|## Handback schema'

ERRORS=0
WARNINGS=0
COUNT_REQUIRED=0
COUNT_EXECUTABLE=0
COUNT_AGENTS=0
COUNT_SKILLS=0
COUNT_MARKDOWN=0
COUNT_LINKS=0
COUNT_REQUIREMENTS=0
COUNT_ADRS=0
FILES=()
FILE_COUNT=0

# ------------------------------------------------------------------------------------------------
# Reporting
# ------------------------------------------------------------------------------------------------

error() {
  printf 'ERROR: %s: %s\n' "$1" "$2"
  ERRORS=$((ERRORS + 1))
}

warn() {
  printf 'WARN: %s: %s\n' "$1" "$2"
  WARNINGS=$((WARNINGS + 1))
}

# Prints the ERROR/WARN lines produced by an awk check and counts them.
relay() {
  local line
  [ -n "$1" ] || return 0
  while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
      ERROR:*) ERRORS=$((ERRORS + 1)) ;;
      WARN:*) WARNINGS=$((WARNINGS + 1)) ;;
    esac
  done <<EOF
$1
EOF
}

first_line() { printf '%s\n' "$1" | head -n 1; }
last_line() { printf '%s\n' "$1" | tail -n 1; }

# run_awk <check name> <awk arguments...> — runs an awk check and relays its findings.
run_awk() {
  local name="$1" output status
  shift
  output="$(awk "$@" </dev/null)"
  status=$?
  relay "$output"
  [ "$status" -eq 0 ] || error "$SELF" "the $name check could not run (awk exit $status)"
}

# ------------------------------------------------------------------------------------------------
# awk programs. AWK_LIB holds the helpers every program shares.
# ------------------------------------------------------------------------------------------------

IFS= read -r -d '' AWK_LIB <<'AWK' || true
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function rtrim(s) { sub(/[ \t]+$/, "", s); return s }

function unquote(s) {
  if (length(s) >= 2 && (s ~ /^".*"$/ || s ~ /^'.*'$/)) return substr(s, 2, length(s) - 2)
  return s
}

function err(path, msg) { printf "ERROR: %s: %s\n", path, msg }

# Reports an H1 h that is missing or does not start with "# <id>" followed by a space or the end.
function check_h1(path, h, id, title_hint,   next_char) {
  next_char = substr(h, length(id) + 3, 1)
  if (h == "") err(path, "missing H1 '# " id " — " title_hint "'")
  else if (substr(h, 1, length(id) + 2) != "# " id || (next_char != "" && next_char != " "))
    err(path, "H1 must start with '# " id "'")
}

# True when "value" is one of the "|"-separated entries of "list".
function in_list(value, list) { return index("|" list "|", "|" value "|") > 0 }

function basename(path) { sub(/.*\//, "", path); return path }

function run_length(s, ch,   n) {
  n = 0
  while (substr(s, n + 1, 1) == ch) n++
  return n
}

# Fenced code blocks (``` or ~~~, at any indentation so that fences nested in list items count).
# The closing fence is indented at most 3 spaces more than the opening one. Call for every line;
# returns 1 when the line opens, closes or lies inside a block. Reset fence_char to "" at the start
# of each file.
function in_fence(line,   indent, rest, ch, run) {
  match(line, /^ */)
  indent = RLENGTH
  rest = substr(line, indent + 1)
  ch = substr(rest, 1, 1)
  run = 0
  if (ch == "`" || ch == "~") run = run_length(rest, ch)
  if (fence_char == "") {
    if (run < 3 || (ch == "`" && index(substr(rest, run + 1), "`"))) return 0
    fence_char = ch
    fence_len = run
    fence_indent = indent
    return 1
  }
  if (ch == fence_char && run >= fence_len && indent <= fence_indent + 3 &&
      substr(rest, run + 1) ~ /^[ \t]*$/) fence_char = ""
  return 1
}

# Removes HTML comments; in_comment carries an unterminated "<!--" over to the next lines.
function strip_comments(s,   out, i) {
  out = ""
  while (s != "") {
    if (in_comment) {
      if (!(i = index(s, "-->"))) return out
      s = substr(s, i + 3)
      in_comment = 0
    } else {
      if (!(i = index(s, "<!--"))) return out s
      out = out substr(s, 1, i - 1)
      s = substr(s, i + 4)
      in_comment = 1
    }
  }
  return out
}

# Removes HTML comments and keeps inline code spans whole, so a "<!--" inside a code span opens no
# comment and the text of a code span stays readable; in_comment carries an unterminated comment
# over to the next lines.
function strip_comments_outside_spans(s,   out, i, j, n, rest, closing) {
  out = ""
  while (s != "") {
    if (in_comment) {
      if (!(i = index(s, "-->"))) return out
      s = substr(s, i + 3)
      in_comment = 0
      continue
    }
    i = index(s, "<!--")
    j = index(s, "`")
    if (j && (!i || j < i)) {
      n = run_length(substr(s, j), "`")
      rest = substr(s, j + n)
      closing = backtick_run_at(rest, n)
      if (closing) {
        out = out substr(s, 1, j + n - 1) substr(rest, 1, closing + n - 1)
        s = substr(rest, closing + n)
      } else {
        out = out substr(s, 1, j + n - 1)
        s = rest
      }
      continue
    }
    if (!i) return out s
    out = out substr(s, 1, i - 1)
    s = substr(s, i + 4)
    in_comment = 1
  }
  return out
}

# Removes inline code spans (a backtick run up to the next run of equal length).
function strip_code_spans(s,   out, i, n, rest, closing) {
  out = ""
  while ((i = index(s, "`")) > 0) {
    out = out substr(s, 1, i - 1)
    n = run_length(substr(s, i), "`")
    rest = substr(s, i + n)
    closing = backtick_run_at(rest, n)
    s = closing ? substr(rest, closing + n) : rest
  }
  return out s
}

# Position of the first run of exactly n backticks in s, or 0.
function backtick_run_at(s, n,   offset, i, len) {
  offset = 0
  while ((i = index(s, "`")) > 0) {
    len = run_length(substr(s, i), "`")
    if (len == n) return offset + i
    offset += i + len - 1
    s = substr(s, i + len)
  }
  return 0
}

# Frontmatter: one "key: value" per line between "---" lines at the top of the file. Values are
# unquoted; indented continuation lines (block scalars, folded text) join the previous key.
function fm_parse(fi, line,   key, val) {
  if (match(line, /^[A-Za-z_][A-Za-z0-9_-]*:/)) {
    key = substr(line, 1, RLENGTH - 1)
    fm[fi, key] = unquote(trim(substr(line, RLENGTH + 1)))
    fm_last = key
    return
  }
  if (line !~ /^[ \t]/ || fm_last == "") return
  val = trim(line)
  if (val == "") return
  if (fm[fi, fm_last] ~ /^[|>][-+0-9]*$/) fm[fi, fm_last] = val
  else fm[fi, fm_last] = fm[fi, fm_last] " " val
}

function fmv(fi, key) { return ((fi, key) in fm) ? fm[fi, key] : "" }

# Tracks the frontmatter block of file fi line by line; returns 1 while the line belongs to it.
# fm_state[fi]: 1 inside, 2 closed, 3 absent (first line is not "---").
function fm_track(fi, line) {
  if (FNR == 1) {
    fm_last = ""
    if (trim(line) == "---") { fm_state[fi] = 1; return 1 }
    fm_state[fi] = 3
    return 0
  }
  if (fm_state[fi] != 1) return 0
  if (trim(line) == "---") fm_state[fi] = 2
  else fm_parse(fi, line)
  return 1
}

# Reports a missing or unterminated frontmatter block; returns 1 when the block is usable.
function fm_usable(fi, path) {
  if (fm_state[fi] == 3) { err(path, "missing frontmatter (the first line must be ---)"); return 0 }
  if (fm_state[fi] == 1) { err(path, "unterminated frontmatter (no closing --- line)"); return 0 }
  return 1
}
AWK

# Checks 4 and 5. Variable kind=agent|skill. The expected name is the file's basename (agent) or
# its directory name (skill).
IFS= read -r -d '' AWK_IDENTITY <<'AWK' || true
FNR == 1 { n++; path[n] = FILENAME }
{ sub(/\r$/, ""); fm_track(n, $0) }
END { for (i = 1; i <= n; i++) check_identity(i) }

function check_identity(i,   expected, name) {
  expected = path[i]
  if (kind == "skill") { sub(/\/SKILL\.md$/, "", expected); expected = basename(expected) }
  else { expected = basename(expected); sub(/\.md$/, "", expected) }
  if (!fm_usable(i, path[i])) return
  name = fmv(i, "name")
  if (name != expected) err(path[i], "frontmatter name '" name "' must equal '" expected "'")
  if (fmv(i, "description") == "") err(path[i], "frontmatter description is missing or empty")
}
AWK

# Check 6: prints "<file>\t<line>\t<target>" for every relative link outside fenced code blocks,
# inline code spans and HTML comments: inline links and images, and reference definitions. Skips
# URLs with a scheme (http:, https:, mailto:, ...) and pure #anchors; strips #fragments and ?queries.
IFS= read -r -d '' AWK_LINKS <<'AWK' || true
FNR == 1 { fence_char = ""; in_comment = 0 }
{
  sub(/\r$/, "")
  if (!in_comment && in_fence($0)) next
  line = strip_comments(strip_code_spans($0))
  if (match(line, /^ *\[[^]^][^]]*\]:[ \t]*/)) emit(destination(substr(line, RSTART + RLENGTH)))
  while ((i = index(line, "](")) > 0) {
    line = substr(line, i + 2)
    emit(destination(line))
  }
}

function emit(target) {
  if (target == "" || target ~ /^#/ || target ~ /^[A-Za-z][A-Za-z0-9+.-]*:/) return
  sub(/[#?].*$/, "", target)
  gsub(/%20/, " ", target)
  if (target != "") printf "%s\t%d\t%s\n", FILENAME, FNR, target
}

# The link destination at the start of s: <...> or the text up to the first space or ")".
function destination(s,   j) {
  sub(/^[ \t]+/, "", s)
  if (substr(s, 1, 1) == "<") {
    j = index(s, ">")
    return j > 1 ? substr(s, 2, j - 2) : ""
  }
  match(s, /^[^ \t)]*/)
  return substr(s, 1, RLENGTH)
}
AWK

# Check 7. Variables: path, headings ("|"-separated exact heading lines).
IFS= read -r -d '' AWK_HEADINGS <<'AWK' || true
{
  sub(/\r$/, "")
  if (!in_fence($0)) seen[rtrim($0)] = 1
}
END {
  count = split(headings, want, "|")
  for (i = 1; i <= count; i++)
    if (!(want[i] in seen)) err(path, "missing heading '" want[i] "'")
}
AWK

# Check 7: docs/PROGRESS.md claims no ongoing execution (AVE-REQ-098 AC-3). Variable: path. A later
# session cannot check that work "is running"; delegated work in flight is recorded stop-safe
# ("launched <date>; verdict not recorded; on resume without a recorded verdict, re-run <exact
# command>"). Outside fenced blocks, HTML comments and code spans, a line fails with one of the
# wordings "running", "underway", "under way", "in flight", "ongoing", "still executing" or "runs
# now", in any letter case and with spaces, tabs or hyphens between the words; "nothing is
# running", "not running" and "no longer running" pass. The rule knows this list: another wording
# of the same claim is judged by the reader of the diff (commit review, verify-requirement).
IFS= read -r -d '' AWK_PROGRESS_CLAIMS <<'AWK' || true
FNR == 1 { fence_char = ""; in_comment = 0 }
{
  sub(/\r$/, "")
  if (!in_comment && in_fence($0)) next
  line = " " tolower(strip_comments(strip_code_spans($0))) " "
  gsub(/nothing is running|no longer running|not running/, "", line)
  if (line ~ /[^a-z](running|underway|under[ \t-]+way|in[ \t-]+flight|on-?going|still[ \t-]+executing|runs[ \t-]+now)[^a-z]/)
    err(path, "line " FNR ": claims ongoing execution ('running', 'underway', 'under way', 'in flight', 'ongoing', 'still executing' or 'runs now'), which no later session can check; record delegated work as 'launched <date>; verdict not recorded; on resume without a recorded verdict, re-run <exact command>'")
}
AWK

# Check 11. Variables: path, headings ("|"-separated exact heading lines in template order). Each
# heading appears once and in that order, each section holds a non-blank line, the Requirements
# section names an AVE-REQ ID, and the Input revision section names a commit: a token of 7 to 40
# lowercase hex digits with no letter, digit, "_" or "-" on either side (so the "af7078da" inside
# the branch name ccr-af7078da-q8r8mf counts as none), or the self-reference
# "git log -1 --format=%h -- <path of this brief>". An H1 or another H2 ends a section. HTML
# comments are removed first (outside fenced blocks and code spans): a heading, an ID, a commit or
# the only text of a section inside a comment counts as absent.
IFS= read -r -d '' AWK_BRIEF <<'AWK' || true
BEGIN {
  count = split(headings, want, "|")
  for (i = 1; i <= count; i++) rank[want[i]] = i
}
{
  sub(/\r$/, "")
  fenced = (!in_comment && in_fence($0))
  t = rtrim(fenced ? $0 : strip_comments_outside_spans($0))
  if (!fenced && t ~ /^##? /) {
    current = (t in rank) ? t : ""
    if (current == "") next
    if (rank[current] <= last_rank)
      err(path, "heading '" current "' follows '" last_heading "' (keep each heading once, in the order of the template in docs/briefs/README.md)")
    seen[current] = 1
    last_rank = rank[current]
    last_heading = current
    next
  }
  if (current == "" || t !~ /[^ \t]/) next
  filled[current] = 1
  if (current == "## Requirements" && t ~ /AVE-REQ-[0-9][0-9][0-9]/) names_id = 1
  if (current == "## Input revision" && names_commit(t)) commit_named = 1
}
END {
  for (i = 1; i <= count; i++) {
    if (!(want[i] in seen)) err(path, "missing heading '" want[i] "'")
    else if (!(want[i] in filled)) err(path, "section '" want[i] "' is empty")
  }
  if (("## Requirements" in seen) && !names_id)
    err(path, "section '## Requirements' names no requirement ID (AVE-REQ-NNN)")
  if (("## Input revision" in filled) && !commit_named)
    err(path, "section '## Input revision' names no commit (a hash of 7 to 40 hex digits, or the self-reference 'git log -1 --format=%h -- " path "')")
}

function word_char(ch) {
  return ch != "" && index("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-", ch) > 0
}

# True when s holds a delimited hex token of 7 to 40 digits or the self-reference to this brief.
function names_commit(s,   ref, i, after, rest, off, start, len, before) {
  ref = "git log -1 --format=%h -- " path
  if ((i = index(s, ref)) > 0) {
    after = substr(s, i + length(ref), 1)
    if (!word_char(after) && after != "." && after != "/") return 1
  }
  rest = s
  off = 0
  while (match(rest, /[0-9a-f]+/)) {
    start = off + RSTART
    len = RLENGTH
    before = start > 1 ? substr(s, start - 1, 1) : ""
    if (len >= 7 && len <= 40 && !word_char(before) && !word_char(substr(s, start + len, 1))) return 1
    off = start + len - 1
    rest = substr(s, off + 1)
  }
  return 0
}
AWK

# Check 12: policy of .claude/settings.json (AVE-REQ-098 AC-2, AC-4; AVE-REQ-097 AC-3), run by
# python3 with the file as its argument. Prints one ERROR line per violation; prints nothing for a
# file that is no valid JSON object (check 3 reports that). Hook matchers follow Claude Code: "",
# "*" or none match every source; letters, digits, "_", "-" and "|" only form a list of exact
# names; anything else (a comma-separated list included) is an unanchored regular expression.
# A hook command fails with the shell word "while" or "until", a "for ((" loop, "sleep", "nohup",
# "disown", "setsid", a background "&", "--dangerously-skip-permissions" or "--permission-mode".
# The rule knows this list: a loop or a bypass written another way (inside a script the command
# calls, for example) is judged by the reader of the diff (commit review, verify-requirement).
# The file checked is .claude/settings.json; the personal .claude/settings.local.json and the
# user-level settings lie outside the repository and outside this check.
IFS= read -r -d '' PY_SETTINGS_POLICY <<'PY' || true
import json
import re
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except (OSError, ValueError):
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)


def error(message):
    print(f"ERROR: {path}: {message}")


permissions = data.get("permissions")
mode = permissions.get("defaultMode") if isinstance(permissions, dict) else None
if mode in ("bypassPermissions", "dontAsk"):
    error(f"permissions.defaultMode '{mode}' runs tools without permission prompts (AVE-REQ-098 AC-4)")


def skipped_prompts(node, where):
    if isinstance(node, dict):
        for key, value in node.items():
            here = f"{where}.{key}" if where else key
            if re.fullmatch(r"skip\w*PermissionPrompt", key) and value not in (False, None):
                error(f"{here} skips a permission prompt (AVE-REQ-098 AC-4)")
            skipped_prompts(value, here)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            skipped_prompts(value, f"{where}[{index}]")


skipped_prompts(data, "")

UNBOUNDED = re.compile(
    r"(?<![\w./-])(?:while|until)(?![\w./-])|\bfor\s*\(\(|\b(?:sleep|nohup|disown|setsid)\b"
    r"|--dangerously-skip-permissions|--permission-mode|(?<![&|<>])&(?![&>])"
)
SESSION_SOURCES = ("startup", "resume", "compact")
SESSION_HOOK = ".claude/hooks/session-start.sh"


def as_list(value):
    return value if isinstance(value, list) else []


def matches(matcher, source):
    if matcher in (None, "", "*"):
        return True
    if not isinstance(matcher, str):
        return False
    if re.fullmatch(r"[A-Za-z0-9_\-|]+", matcher):
        return source in set(matcher.split("|"))
    try:
        return re.search(matcher, source) is not None
    except re.error:
        return False


hooks = data.get("hooks") if isinstance(data.get("hooks"), dict) else {}
covered = set()
registered = False
for event, groups in hooks.items():
    for number, group in enumerate(as_list(groups)):
        if not isinstance(group, dict):
            continue
        for handler in as_list(group.get("hooks")):
            if not isinstance(handler, dict):
                continue
            if handler.get("async") not in (None, False):
                error(
                    f"hooks.{event}[{number}] runs a hook asynchronously (\"async\": "
                    f"{json.dumps(handler.get('async'))}), which escapes its timeout (AVE-REQ-098 AC-4)"
                )
            if handler.get("type") != "command":
                continue
            command = str(handler.get("command", ""))
            found = UNBOUNDED.search(command)
            if found:
                error(
                    f"hooks.{event}[{number}] command {command!r} starts a loop, a sleep, a background "
                    f"job or a permission bypass ({found.group(0).strip()!r}; AVE-REQ-098 AC-4)"
                )
            if event == "SessionStart" and SESSION_HOOK in command:
                registered = True
                covered.update(s for s in SESSION_SOURCES if matches(group.get("matcher"), s))
# AVE-REQ-097 AC-3: the Stop gate is registered once, as a handler of type "command" whose command
# is exactly the registered one, and nothing in the settings file switches it off, loosens it or
# runs a heavier tier at every stop. Text after the command (" || true") would discard the gate's
# exit status, and a handler of another type would never start the script.
STOP_HOOK = ".claude/hooks/stop-verify.sh"
STOP_COMMAND = '"$CLAUDE_PROJECT_DIR"/' + STOP_HOOK
SHELL_VARIABLES = ("SHELLOPTS", "BASHOPTS", "BASH_ENV", "ENV")
stop_handlers = [
    handler
    for group in as_list(hooks.get("Stop"))
    if isinstance(group, dict)
    for handler in as_list(group.get("hooks"))
    if isinstance(handler, dict)
]
if len(stop_handlers) != 1:
    error(
        f"hooks.Stop holds {len(stop_handlers)} command(s); it holds exactly one, the Stop gate"
        f" {STOP_HOOK} (AVE-REQ-097 AC-3)"
    )
for handler in stop_handlers:
    command = str(handler.get("command", ""))
    if handler.get("type") != "command":
        error(
            f"hooks.Stop handler has type {json.dumps(handler.get('type'))}; the Stop gate is a"
            ' handler of type "command" (AVE-REQ-097 AC-3)'
        )
    if command != STOP_COMMAND:
        error(
            f"hooks.Stop command {command!r} must run the Stop gate {STOP_HOOK} and no other"
            f" verification command: it reads exactly {STOP_COMMAND}, with nothing before or after"
            " it (AVE-REQ-097 AC-3)"
        )
    if "CLAUDE_VERIFY_" in command:
        error(f"hooks.Stop command {command!r} sets a gate variable (AVE-REQ-097 AC-3)")
if data.get("disableAllHooks") not in (None, False):
    error("disableAllHooks switches the Stop gate and the SessionStart hook off (AVE-REQ-097 AC-3)")
environment = data.get("env") if isinstance(data.get("env"), dict) else {}
for key in sorted(environment):
    if key.startswith("CLAUDE_VERIFY_"):
        error(f"env.{key} changes the Stop gate from the settings file (AVE-REQ-097 AC-3)")
    elif key in SHELL_VARIABLES:
        error(
            f"env.{key} changes the shell that runs the hooks and verify.sh from the settings file"
            " (AVE-REQ-097 AC-3)"
        )
if not registered:
    error(f"no SessionStart hook runs {SESSION_HOOK} (AVE-REQ-098 AC-2)")
else:
    missing = [s for s in SESSION_SOURCES if s not in covered]
    if missing:
        error(
            f"the SessionStart hook {SESSION_HOOK} does not run on {', '.join(missing)}: "
            "its matcher excludes them (AVE-REQ-098 AC-2)"
        )
PY

# Checks 8 and 10. Operands: section=goals docs/PRODUCT.md, section=req <requirement files...>,
# section=trace docs/TRACEABILITY.md.
IFS= read -r -d '' AWK_REQUIREMENTS <<'AWK' || true
BEGIN {
  STATUSES = "proposed|ready|in-progress|verification|done|blocked|superseded|deferred"
  PRIORITIES = "must|should|could"
  TYPES = "functional|non-functional|constraint"
  SOURCES = "human|derived"
  REQ_HEADINGS = "## Intent|## Description|## Acceptance criteria|## Edge cases|## Dependencies|## Verification strategy|## Implementation evidence|## Test evidence|## Status"
  MATRIX_HEADER = "|Requirement|Status|Implementation|Tests|Evidence|ADRs|"
}

FNR == 1 { fence_char = ""; if (section == "req") start_requirement(); if (section == "trace") trace_path = FILENAME }
{ sub(/\r$/, "") }
section == "goals" { scan_goals($0); next }
section == "req" { scan_requirement($0); next }
section == "trace" { scan_trace($0); next }
END { validate_requirements(); validate_matrix() }

# --- docs/PRODUCT.md: GOAL IDs defined in § Product goals --------------------------------------
function scan_goals(line,   t) {
  if (in_fence(line)) return
  t = rtrim(line)
  if (t ~ /^##? /) { in_goals = (t == "## Product goals"); return }
  if (!in_goals) return
  while (match(t, /GOAL-[0-9][0-9][0-9]+/)) {
    goal[substr(t, RSTART, RLENGTH)] = 1
    t = substr(t, RSTART + RLENGTH)
  }
}

# --- requirement files ------------------------------------------------------------------------
function start_requirement(   base) {
  n++
  path[n] = FILENAME
  base = basename(FILENAME)
  valid[n] = (base ~ /^(AVE-EPIC-[0-9][0-9]+|AVE-FEAT-[0-9][0-9][0-9]+|AVE-REQ-[0-9][0-9][0-9]+)-[a-z0-9-]+\.md$/)
  if (!valid[n]) {
    err(FILENAME, "filename must match AVE-EPIC-NN-<slug>.md, AVE-FEAT-NNN-<slug>.md or AVE-REQ-NNN-<slug>.md (slug: [a-z0-9-]+)")
    return
  }
  match(base, /^AVE-[A-Z]+-[0-9]+/)
  fid[n] = substr(base, 1, RLENGTH)
  kind[n] = substr(fid[n], 5, index(substr(fid[n], 5), "-") - 1)
  in_ac = 0
  in_status = 0
}

function scan_requirement(line,   t, key) {
  if (!valid[n]) return
  # One value per key: a repeated key would give the file two readings (check_baseline.py owns
  # the full canonical form; this rule also holds when this checker runs alone).
  if (FNR > 1 && fm_state[n] == 1 && match(line, /^[A-Za-z_][A-Za-z0-9_-]*:/)) {
    key = substr(line, 1, RLENGTH - 1)
    if (((n, key) in fm_seen) && fm_dup[n] == "") fm_dup[n] = key
    fm_seen[n, key] = 1
  }
  if (fm_track(n, line) || in_fence(line)) return
  t = rtrim(line)
  if (t ~ /^# / && h1[n] == "") h1[n] = t
  if (t ~ /^## /) { heading[n, t] = 1; in_ac = (t == "## Acceptance criteria"); in_status = (t == "## Status") }
  else if (in_ac && (t ~ /^([-*+]|[0-9]+[.)])[ \t]/ || t ~ /^[ \t]*[-*+][ \t]+\[[ xX]\]/)) {
    ac_total[n]++
    if (t !~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+\[[xX]\]/) ac_open[n]++
    if (t !~ /^[ \t]*- \[[ xX]\] AC-[0-9]/ && !ac_bad[n]) ac_bad[n] = FNR
  }
  else if (in_status && t ~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] — /) {
    log_count[n]++
    log_status[n] = log_entry_status(t)
  }
  if (index(t, "_TBD") && !tbd_line[n]) tbd_line[n] = FNR
}

# The status field of a Status-log line "- YYYY-MM-DD — <status> — <reason>".
function log_entry_status(t,   sep, rest, j) {
  sep = " — "
  rest = substr(t, index(t, sep) + length(sep))
  j = index(rest, sep)
  return trim(j ? substr(rest, 1, j - 1) : rest)
}

function validate_requirements(   i) {
  for (i = 1; i <= n; i++) {
    if (!valid[i]) continue
    if (fid[i] in owner) err(path[i], "duplicate ID " fid[i] " (also used by " path[owner[fid[i]]] ")")
    else owner[fid[i]] = i
  }
  for (i = 1; i <= n; i++) if (valid[i]) validate_requirement(i)
}

function validate_requirement(i,   p, k, status) {
  p = path[i]
  k = kind[i]
  if (fm_usable(i, p)) {
    if (fm_dup[i] != "") err(p, "frontmatter key " fm_dup[i] " is repeated (one 'key: value' line per key)")
    if (fmv(i, "id") != fid[i]) err(p, "frontmatter id '" fmv(i, "id") "' must equal the filename ID " fid[i])
    if (fmv(i, "title") == "") err(p, "frontmatter title is missing or empty")
    check_enum(i, "status", STATUSES)
    check_enum(i, "priority", PRIORITIES)
    if (k == "REQ") {
      check_enum(i, "type", TYPES)
      check_enum(i, "source", SOURCES)
      check_parent(i, "^AVE-(FEAT-[0-9][0-9][0-9]+|EPIC-[0-9][0-9]+)$", "AVE-FEAT-NNN or AVE-EPIC-NN")
    }
    if (k == "FEAT") check_parent(i, "^AVE-EPIC-[0-9][0-9]+$", "AVE-EPIC-NN")
    if (k == "EPIC") check_goals(i)
    if (fmv(i, "status") == "superseded") check_superseded_by(i)
  }
  if (fm_state[i] == 1) return
  check_h1(p, h1[i], fid[i], "<Title>")
  check_status_log(i)
  if (k != "REQ") return
  check_headings(i)
  status = fmv(i, "status")
  if (!ac_total[i]) err(p, "no acceptance criterion line ('- [ ] AC-1 ...') under '## Acceptance criteria'")
  if (ac_bad[i]) err(p, "line " ac_bad[i] ": acceptance criterion lines read '- [ ] AC-<n> <behavior>'")
  if (status == "done" && ac_open[i]) err(p, "status done but " ac_open[i] " acceptance criterion line(s) are unticked")
  if (status == "done" && tbd_line[i]) err(p, "status done but a _TBD placeholder remains (line " tbd_line[i] ")")
}

# The newest (last) dated line under "## Status" records the current frontmatter status.
function check_status_log(i,   status) {
  if (!((i, "## Status") in heading)) {
    if (kind[i] != "REQ") err(path[i], "missing heading '## Status'")
    return
  }
  status = fmv(i, "status")
  if (!log_count[i]) err(path[i], "'## Status' has no log line '- YYYY-MM-DD — <status> — <reason>'")
  else if (status != "" && log_status[i] != status)
    err(path[i], "newest Status-log line records '" log_status[i] "' but frontmatter status is '" status "'")
}

function check_enum(i, key, allowed,   v) {
  v = fmv(i, key)
  if (v == "") err(path[i], "frontmatter " key " is missing")
  else if (!in_list(v, allowed)) err(path[i], "invalid " key " '" v "' (allowed: " allowed ")")
}

function check_parent(i, pattern, expected,   v) {
  v = fmv(i, "parent")
  if (v == "") err(path[i], "frontmatter parent is missing")
  else if (v !~ pattern) err(path[i], "invalid parent '" v "' (expected " expected ")")
  else if (!(v in owner)) err(path[i], "parent " v " has no file in docs/requirements/")
}

function check_goals(i,   v, count, list, j, g) {
  v = fmv(i, "goals")
  if (v !~ /^\[.*\]$/) { err(path[i], "frontmatter goals must be a flow list such as [GOAL-001]"); return }
  v = trim(substr(v, 2, length(v) - 2))
  if (v == "") { err(path[i], "frontmatter goals is empty (list at least one GOAL-NNN)"); return }
  count = split(v, list, ",")
  for (j = 1; j <= count; j++) {
    g = trim(list[j])
    if (g !~ /^GOAL-[0-9][0-9][0-9]+$/) err(path[i], "invalid goal '" g "' (expected GOAL-NNN)")
    else if (!(g in goal)) err(path[i], "goal " g " is not defined in docs/PRODUCT.md § Product goals")
  }
}

function check_superseded_by(i,   v) {
  v = fmv(i, "superseded_by")
  if (v == "") err(path[i], "status superseded requires frontmatter superseded_by")
  else if (!(v in owner)) err(path[i], "superseded_by " v " has no file in docs/requirements/")
}

function check_headings(i,   count, want, j) {
  count = split(REQ_HEADINGS, want, "|")
  for (j = 1; j <= count; j++)
    if (!((i, want[j]) in heading)) err(path[i], "missing heading '" want[j] "'")
}

# --- docs/TRACEABILITY.md: requirement matrix rows outside code fences ---------------------------
function scan_trace(line,   t, norm, cells) {
  if (in_fence(line)) { in_matrix = 0; return }
  t = trim(line)
  norm = t
  gsub(/[ \t]/, "", norm)
  if (norm == MATRIX_HEADER) { in_matrix = 1; matrix_found = 1; return }
  if (matrix_found && !in_matrix && substr(t, 1, 1) == "|" && t ~ /AVE-REQ-[0-9][0-9][0-9]/) {
    err(trace_path, "line " FNR ": matrix row separated from the table (remove the blank or text line above it)")
    return
  }
  if (!in_matrix) return
  if (substr(t, 1, 1) != "|") { in_matrix = 0; return }
  if (norm ~ /^\|[-:|]+\|$/) return
  split(t, cells, "|")
  rows++
  row_line[rows] = FNR
  row_status[rows] = trim(cells[3])
  row_id[rows] = match(cells[2], /AVE-REQ-[0-9][0-9][0-9]+/) ? substr(cells[2], RSTART, RLENGTH) : ""
}

function validate_matrix(   r, id, where, i) {
  if (trace_path == "") return
  if (!matrix_found)
    err(trace_path, "requirement matrix header '| Requirement | Status | Implementation | Tests | Evidence | ADRs |' not found outside code fences")
  for (r = 1; r <= rows; r++) {
    id = row_id[r]
    where = "line " row_line[r] ": "
    if (id == "") { err(trace_path, where "matrix row has no AVE-REQ-NNN ID in its first cell"); continue }
    if (id in row_seen) { err(trace_path, where "duplicate matrix row for " id); continue }
    row_seen[id] = 1
    if (!(id in owner)) { err(trace_path, where "no requirement file for " id); continue }
    if (row_status[r] != fmv(owner[id], "status"))
      err(trace_path, where id " status '" row_status[r] "' differs from its frontmatter status '" fmv(owner[id], "status") "'")
  }
  for (i = 1; i <= n; i++)
    if (valid[i] && kind[i] == "REQ" && fmv(i, "status") == "done" && !(fid[i] in row_seen) && owner[fid[i]] == i)
      err(trace_path, "done requirement " fid[i] " has no matrix row")
}
AWK

# Check 9: ADR files.
IFS= read -r -d '' AWK_ADRS <<'AWK' || true
BEGIN {
  ADR_HEADINGS = "## Status|## Context|## Decision|## Alternatives considered|## Consequences|## Related requirements"
  DATE = "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
}
FNR == 1 { start_adr() }
{ sub(/\r$/, ""); if (valid[n]) scan_adr($0) }
END { validate_adrs() }

function start_adr(   base) {
  n++
  path[n] = FILENAME
  fence_char = ""
  in_status = 0
  base = basename(FILENAME)
  valid[n] = (base ~ /^ADR-[0-9][0-9][0-9]+-[a-z0-9-]+\.md$/)
  if (!valid[n]) { err(FILENAME, "filename must match ADR-NNN-<slug>.md (slug: [a-z0-9-]+)"); return }
  match(base, /^ADR-[0-9]+/)
  aid[n] = substr(base, 1, RLENGTH)
}

function scan_adr(line,   t) {
  if (in_fence(line)) return
  t = trim(line)
  if (t ~ /^# / && h1[n] == "") h1[n] = t
  if (t ~ /^## /) { heading[n, t] = 1; in_status = (t == "## Status"); return }
  if (in_status && t != "" && !(n in status_line)) status_line[n] = t
}

function validate_adrs(   i) {
  for (i = 1; i <= n; i++) {
    if (!valid[i]) continue
    if (aid[i] in owner) err(path[i], "duplicate ID " aid[i] " (also used by " path[owner[aid[i]]] ")")
    else owner[aid[i]] = i
  }
  for (i = 1; i <= n; i++) if (valid[i]) validate_adr(i)
}

function validate_adr(i,   p, id, count, want, j, s, ref) {
  p = path[i]
  id = aid[i]
  check_h1(p, h1[i], id, "<Decision title>")
  count = split(ADR_HEADINGS, want, "|")
  for (j = 1; j <= count; j++)
    if (!((i, want[j]) in heading)) err(p, "missing heading '" want[j] "'")
  if (!((i, "## Status") in heading)) return
  s = (i in status_line) ? status_line[i] : ""
  if (s ~ ("^(Proposed|Accepted) — " DATE "$")) return
  if (s ~ ("^Superseded by ADR-[0-9][0-9][0-9]+ — " DATE "$")) {
    match(s, /ADR-[0-9]+/)
    ref = substr(s, RSTART, RLENGTH)
    if (ref == id) err(p, "an ADR cannot supersede itself")
    else if (!(ref in owner)) err(p, "superseded by " ref ", which has no file in docs/decisions/")
    return
  }
  err(p, "invalid status line '" s "' (expected 'Proposed — YYYY-MM-DD', 'Accepted — YYYY-MM-DD' or 'Superseded by ADR-NNN — YYYY-MM-DD')")
}
AWK

# ------------------------------------------------------------------------------------------------
# Checks
# ------------------------------------------------------------------------------------------------

check_required_files() {
  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    COUNT_REQUIRED=$((COUNT_REQUIRED + 1))
    [ -f "$file" ] || error "$file" "required file is missing"
  done <<EOF
$REQUIRED_FILES
EOF
}

# Check 1, second part: scripts/verify.d holds the registered component step files only.
# verify.sh sources the registered names; any other entry would be a step file no diff, status or
# required-file rule accounts for (AVE-REQ-097 AC-4).
check_step_files() {
  local file
  for file in scripts/verify.d/* scripts/verify.d/.[!.]*; do
    [ -e "$file" ] || [ -L "$file" ] || continue
    case "
$REQUIRED_FILES
" in
      *"
$file
"*) ;;
      *) error "$file" "is no registered component step file (list it in REQUIRED_FILES of scripts/check-project-control.sh, or remove it)" ;;
    esac
  done
}

# Check 2: the entry points, the files a command starts by path: scripts/*.sh, the hooks, the tooling
# suites with their runner and fixture builder (scripts/tests/*.sh) and the media stand-in of the
# fast tier. scripts/lib/ otherwise holds sourced libraries and scripts/verify.d/ sourced step
# files, which need no executable bit. For a tracked entry point the mode in the Git index counts
# too: a host without executable bits shows every file as executable through the container's
# mount, while CI checks out the mode the index holds.
check_executables() {
  local file mode
  for file in scripts/*.sh .claude/hooks/*.sh scripts/tests/*.sh scripts/lib/media-tier-only.sh; do
    [ -f "$file" ] || continue
    COUNT_EXECUTABLE=$((COUNT_EXECUTABLE + 1))
    [ -x "$file" ] || error "$file" "not executable (run: chmod +x '$file')"
    mode="$(git ls-files -s -- "$file" 2>/dev/null | awk '{ print $1 }')"
    case "$mode" in
      "" | 100755) ;;
      *) error "$file" "not executable in the Git index (mode $mode; run: git update-index --chmod=+x '$file')" ;;
    esac
  done
}

check_settings_json() {
  local file=".claude/settings.json" problem
  [ -f "$file" ] || return 0
  if command -v python3 >/dev/null 2>&1; then
    problem="$(python3 -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"), parse_constant=lambda c: sys.exit("invalid JSON constant " + c))' "$file" 2>&1)" ||
      error "$file" "invalid JSON: $(last_line "$problem")"
  elif command -v node >/dev/null 2>&1; then
    problem="$(node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$file" 2>&1)" ||
      error "$file" "invalid JSON: $(printf '%s\n' "$problem" | grep 'SyntaxError' | head -n 1)"
  elif command -v jq >/dev/null 2>&1; then
    # jq accepts a stream of values and an empty file; require exactly one value.
    problem="$(jq -n '[inputs] | if length == 1 then empty else error("expected one JSON value, found \(length)") end' "$file" 2>&1 >/dev/null)" ||
      error "$file" "invalid JSON: $(first_line "$problem")"
  else
    warn "$file" "JSON not validated (install python3, node or jq)"
  fi
}

# Collects the existing non-empty files among the arguments into FILES (FILE_COUNT entries),
# skipping README.md files; reports empty files.
collect_files() {
  local file
  FILES=()
  FILE_COUNT=0
  for file in "$@"; do
    [ -f "$file" ] || continue
    [ "${file##*/}" != "README.md" ] || continue
    if [ -s "$file" ]; then
      FILES+=("$file")
      FILE_COUNT=$((FILE_COUNT + 1))
    else
      error "$file" "file is empty"
    fi
  done
}

check_agents() {
  collect_files .claude/agents/*.md
  COUNT_AGENTS=$FILE_COUNT
  [ "$COUNT_AGENTS" -gt 0 ] || return 0
  run_awk "agent frontmatter" -v kind=agent "$AWK_LIB$AWK_IDENTITY" "${FILES[@]}"
}

check_skills() {
  local dir
  for dir in .claude/skills/*/; do
    [ -d "$dir" ] || continue
    [ -f "${dir}SKILL.md" ] || error "${dir%/}" "skill directory has no SKILL.md"
  done
  collect_files .claude/skills/*/SKILL.md
  COUNT_SKILLS=$FILE_COUNT
  [ "$COUNT_SKILLS" -gt 0 ] || return 0
  run_awk "skill frontmatter" -v kind=skill "$AWK_LIB$AWK_IDENTITY" "${FILES[@]}"
}

# Prints the Markdown files whose links are checked, sorted; .claude/worktrees/ is excluded.
list_markdown_files() {
  local file
  {
    for file in CLAUDE.md README.md; do
      [ -f "$file" ] && printf '%s\n' "$file"
    done
    [ -d docs ] && find docs -type f -name '*.md'
    [ -d .claude ] && find .claude -path .claude/worktrees -prune -o -type f -name '*.md' -print
  } | sort
}

check_links() {
  local file links status md_file lineno target base resolved
  FILES=()
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    FILES+=("$file")
    COUNT_MARKDOWN=$((COUNT_MARKDOWN + 1))
  done <<EOF
$(list_markdown_files)
EOF
  [ "$COUNT_MARKDOWN" -gt 0 ] || return 0
  links="$(awk "$AWK_LIB$AWK_LINKS" "${FILES[@]}" </dev/null)"
  status=$?
  [ "$status" -eq 0 ] || error "$SELF" "the link check could not run (awk exit $status)"
  [ -n "$links" ] || return 0
  while IFS="$TAB" read -r md_file lineno target; do
    COUNT_LINKS=$((COUNT_LINKS + 1))
    case "$md_file" in
      */*) base="${md_file%/*}" ;;
      *) base="." ;;
    esac
    case "$target" in
      /*) resolved=".$target" ;;
      *) resolved="$base/$target" ;;
    esac
    [ -e "$resolved" ] || error "$md_file" "line $lineno: broken link to '$target'"
  done <<EOF
$links
EOF
}

check_progress_headings() {
  local file="docs/PROGRESS.md"
  [ -f "$file" ] || return 0
  run_awk "PROGRESS.md heading" -v path="$file" -v headings="$PROGRESS_HEADINGS" \
    "$AWK_LIB$AWK_HEADINGS" "$file"
  run_awk "PROGRESS.md claim" -v path="$file" "$AWK_LIB$AWK_PROGRESS_CLAIMS" "$file"
}

# Check 11: every entry of docs/briefs/ is a brief (a visible *.md file, checked against the
# template), README.md, the directory drafts/ (briefs that name no input revision yet; unchecked)
# or the directory handbacks/. Anything else fails: a file with another extension, a hidden file
# or another directory would hold a brief no rule reads. The folder files an operating system
# leaves behind (.DS_Store, Thumbs.db; ignored by Git) are passed over here and in handbacks/.
check_briefs() {
  local file name
  for file in docs/briefs/* docs/briefs/.[!.]* docs/briefs/..?*; do
    [ -e "$file" ] || [ -L "$file" ] || continue
    name="${file##*/}"
    case "$name" in
      .DS_Store | Thumbs.db) continue ;;
      README.md) [ ! -f "$file" ] || continue ;;
      drafts | handbacks) [ ! -d "$file" ] || continue ;;
      .*) ;;
      *.md)
        if [ -f "$file" ]; then
          run_awk "task brief" -v path="$file" -v headings="$BRIEF_HEADINGS" \
            "$AWK_LIB$AWK_BRIEF" "$file"
          continue
        fi
        ;;
    esac
    error "$file" "is no task brief: docs/briefs/ holds briefs (visible *.md files), README.md, drafts/ and handbacks/ only"
  done
  check_handbacks
}

# Check 11, handbacks: each entry of docs/briefs/handbacks/, hidden ones included, is a file named
# <brief-slug>.md or <brief-slug>.part-<n>.md after the brief docs/briefs/<brief-slug>.md it answers.
check_handbacks() {
  local file name base slug rule="a handback is named <brief-slug>.md or <brief-slug>.part-<n>.md"
  for file in docs/briefs/handbacks/* docs/briefs/handbacks/.[!.]* docs/briefs/handbacks/..?*; do
    [ -e "$file" ] || [ -L "$file" ] || continue
    name="${file##*/}"
    base="${name%.md}"
    slug="$base"
    case "$name" in
      .DS_Store | Thumbs.db) continue ;;
      .*)
        error "$file" "$rule; a hidden file is none"
        continue
        ;;
    esac
    if [ "$base" = "$name" ] || [ ! -f "$file" ]; then
      error "$file" "$rule"
      continue
    fi
    case "$base" in
      *.part-*)
        slug="${base%.part-*}"
        case "${base##*.part-}" in
          "" | 0* | *[!0-9]*) error "$file" "$rule (n = 1, 2, …)"; continue ;;
        esac
        ;;
    esac
    if [ -z "$slug" ] || [ "$slug" = README ] || [ ! -f "docs/briefs/$slug.md" ]; then
      error "$file" "names no brief: docs/briefs/$slug.md is missing ($rule)"
    fi
  done
}

check_settings_policy() {
  local file=".claude/settings.json" output status
  [ -f "$file" ] || return 0
  if ! command -v python3 >/dev/null 2>&1; then
    warn "$file" "settings policy not checked (install python3)"
    return 0
  fi
  output="$(python3 -c "$PY_SETTINGS_POLICY" "$file" 2>&1)"
  status=$?
  relay "$output"
  [ "$status" -eq 0 ] || error "$SELF" "the settings policy check could not run (python3 exit $status)"
}

# Checks 8 and 10 in one awk run. Operands: section=goals [docs/PRODUCT.md] section=req
# [requirement files...] section=trace [docs/TRACEABILITY.md]. README.md (skipped by collect_files)
# and the generated IMPORT_MAPPING.md are no requirement files.
check_requirements() {
  local inputs=0 file
  set --
  for file in docs/requirements/*.md; do
    [ "$file" = docs/requirements/IMPORT_MAPPING.md ] || set -- "$@" "$file"
  done
  collect_files "$@"
  COUNT_REQUIREMENTS=$FILE_COUNT
  set -- section=goals
  if [ -f docs/PRODUCT.md ]; then set -- "$@" docs/PRODUCT.md; inputs=$((inputs + 1)); fi
  set -- "$@" section=req
  if [ "$FILE_COUNT" -gt 0 ]; then set -- "$@" "${FILES[@]}"; inputs=$((inputs + FILE_COUNT)); fi
  set -- "$@" section=trace
  if [ -f docs/TRACEABILITY.md ]; then set -- "$@" docs/TRACEABILITY.md; inputs=$((inputs + 1)); fi
  [ "$inputs" -gt 0 ] || return 0
  run_awk "requirement" "$AWK_LIB$AWK_REQUIREMENTS" "$@"
}

check_adrs() {
  collect_files docs/decisions/*.md
  COUNT_ADRS=$FILE_COUNT
  [ "$COUNT_ADRS" -gt 0 ] || return 0
  run_awk "ADR" "$AWK_LIB$AWK_ADRS" "${FILES[@]}"
}

print_summary() {
  if [ "$ERRORS" -gt 0 ]; then
    printf 'FAILED: %s error(s), %s warning(s) in project control files\n' "$ERRORS" "$WARNINGS"
    return 1
  fi
  printf 'OK: %s required files, %s executable scripts, %s agents, %s skills, %s links in %s Markdown files, %s requirement files, %s ADRs; %s warning(s)\n' \
    "$COUNT_REQUIRED" "$COUNT_EXECUTABLE" "$COUNT_AGENTS" "$COUNT_SKILLS" "$COUNT_LINKS" \
    "$COUNT_MARKDOWN" "$COUNT_REQUIREMENTS" "$COUNT_ADRS" "$WARNINGS"
}

main() {
  cd "$ROOT" || exit 2
  check_required_files
  check_step_files
  check_executables
  check_settings_json
  check_settings_policy
  check_agents
  check_skills
  check_links
  check_progress_headings
  check_briefs
  check_requirements
  check_adrs
  print_summary
}

if [ "$#" -gt 0 ]; then
  printf 'Usage: ./scripts/check-project-control.sh (no arguments)\n' >&2
  exit 2
fi
main
