#!/usr/bin/env bash
# scripts/check-project-control.sh — enforces the mechanical invariants of the project-control files.
#
# Usage:  ./scripts/check-project-control.sh      (run by ./scripts/verify.sh; no arguments)
# Checks: 1 required files exist                    6 relative Markdown links resolve
#         2 scripts and hooks are executable        7 docs/PROGRESS.md headings
#         3 .claude/settings.json is valid JSON     8 requirement files (docs/requirements/README.md)
#         4 agent frontmatter                       9 ADR files (docs/decisions/README.md)
#         5 skill frontmatter                      10 requirement matrix in docs/TRACEABILITY.md
#                                                  11 task brief headings (docs/briefs/README.md)
# Output: every violation as "ERROR: <path>: <message>", "WARN: ..." for a check that could not
#         run, then an "OK: ..." or "FAILED: ..." summary.
# Exit:   0 no errors · 1 errors found · 2 usage error
# Portability: bash 3.2+, POSIX awk/grep/sed (mawk, gawk, BSD awk, busybox); CRLF tolerant.
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
scripts/requirements/import_baseline.py
scripts/lib/verify-state.sh
'

# Check 7: docs/PROGRESS.md headings (exact lines).
PROGRESS_HEADINGS='# Current project state|## Current milestone|## Current objective|## In progress|## Recently completed|## Next recommended work|## Blockers|## Known failures|## Important recent decisions|## Verification status'
# Check 11: task brief headings (exact lines), from the template in docs/briefs/README.md.
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

function scan_requirement(line,   t) {
  if (!valid[n] || fm_track(n, line) || in_fence(line)) return
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

# Check 2: the entry points. scripts/lib/ holds sourced libraries, which need no executable bit.
check_executables() {
  local file
  for file in scripts/*.sh .claude/hooks/*.sh; do
    [ -f "$file" ] || continue
    COUNT_EXECUTABLE=$((COUNT_EXECUTABLE + 1))
    [ -x "$file" ] || error "$file" "not executable (run: chmod +x '$file')"
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
}

check_briefs() {
  local file
  for file in docs/briefs/*.md; do
    [ -f "$file" ] && [ "$file" != docs/briefs/README.md ] || continue
    run_awk "brief heading" -v path="$file" -v headings="$BRIEF_HEADINGS" \
      "$AWK_LIB$AWK_HEADINGS" "$file"
  done
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
  check_executables
  check_settings_json
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
