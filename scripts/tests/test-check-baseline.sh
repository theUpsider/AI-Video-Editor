#!/usr/bin/env bash
# scripts/tests/test-check-baseline.sh — positive and negative cases for scripts/check_baseline.py,
# scripts/reqfile.py and scripts/requirements/import_baseline.py. Each case starts from the baseline
# package, the scripts, a fresh import of the working requirement files (never the repository's
# working files, whose statuses and logs change as the project progresses) and a roadmap generated
# from that import, applies one mutation and checks the exit code and one expected output line.
# Needs python3. Exit 0 when every case passes.
# Checks and mutations are strings run by eval, which reads the variables they name; `mut '<code>'`
# runs Python statements with the helpers of MUT_PRELUDE below.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$W/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/baseline-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
command -v python3 >/dev/null 2>&1 || { echo "test-check-baseline.sh: python3 is required" >&2; exit 2; }
PASS=0; FAIL=0
C="$T/case"
R=docs/requirements
B=ai-video-editor-requirements

# Helpers of every Python mutation (cwd: the case directory).
MUT_PRELUDE='
import glob, hashlib, importlib.util, os, py_compile, re, sys
R = "docs/requirements/"
B = "ai-video-editor-requirements/"
ROADMAP = "docs/ROADMAP.md"
DASH = chr(0x2014)
NBSP = chr(0xA0)
CR = chr(13)
FF = chr(12)
BT = chr(96)
BS = chr(92)
TICKS = BT * 3

def one(pattern):
    paths = glob.glob(pattern)
    assert len(paths) == 1, (pattern, paths)
    return paths[0]

def read(pattern):
    with open(one(pattern), encoding="utf-8", newline="") as handle:
        return handle.read()

def put(path, text):
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(text)

def rep(pattern, old, new, count=1):
    text = read(pattern)
    assert old in text, (pattern, old)
    put(one(pattern), text.replace(old, new, count))

def req(number):
    return R + "AVE-REQ-%03d-*.md" % number

def log(date, status, text):
    return "- %s %s %s %s %s" % (date, DASH, status, DASH, text)

def add_log(pattern, date, status, text):
    put(one(pattern), read(pattern).rstrip("\n") + "\n" + log(date, status, text) + "\n")

def mark(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]

def criteria(pattern):
    return re.findall(r"(?m)^- \[[ x]\] (AC-\d+) (.*)$", read(pattern))

def description(pattern):
    return read(pattern).split("\n## Description\n", 1)[1].split("\n\n## Acceptance criteria", 1)[0]

def link(pattern):
    name = os.path.basename(one(pattern))
    return "[%s](requirements/%s)" % (re.match(r"AVE-[A-Z]+-\d+", name).group(0), name)

def unschedule(pattern):
    text, item = read(ROADMAP), link(pattern)
    assert item in text, item
    put(ROADMAP, text.replace(", " + item, "").replace(item + ", ", "").replace(item, ""))

def schedule(pattern, group, key="Requirements"):
    """Appends the requirement to a list line of a roadmap group (M<n> or Deferred)."""
    lines = read(ROADMAP).split("\n")
    inside = False
    for index, line in enumerate(lines):
        if line.startswith("### "):
            inside = line.startswith("### " + group + " ")
        elif inside and line.startswith("- **" + key):
            lines[index] = line + ", " + link(pattern)
            put(ROADMAP, "\n".join(lines))
            return
    raise AssertionError((group, key))

def move(pattern, group, key="Requirements"):
    unschedule(pattern)
    schedule(pattern, group, key)

STUB = """---
id: {ID}
title: Derived stub
type: functional
status: proposed
priority: should
parent: AVE-FEAT-001
source: derived
scope: v1
primary_gate: M1
origins: []
dependencies: [AVE-REQ-001]
scenarios: []
---

# {ID} — Derived stub

## Intent
Found during implementation.

## Description
A derived behavior.

## Acceptance criteria
- [ ] AC-1 Something

## Edge cases
None.

## Dependencies
- [AVE-REQ-001 — Persistent projects and project settings](AVE-REQ-001-persistent-projects-and-project-settings.md)

## Verification strategy
- AC-1 — unit.

## Implementation evidence
_TBD: pending._

## Test evidence
_TBD: pending._

## Status
- 2026-10-02 — proposed — found during implementation (lead)
"""

def stub(text=STUB, rid="AVE-REQ-102", feature="AVE-FEAT-001", group="M1", key="Proposed during"):
    """Writes a derived requirement, links it from its feature and schedules it on the roadmap."""
    path = R + rid + "-derived-stub.md"
    put(path, text.replace("{ID}", rid))
    if feature:
        rep(R + feature + "-*.md", "\n\n## Out of scope",
            "\n- [%s %s Derived stub](%s-derived-stub.md)\n\n## Out of scope" % (rid, DASH, rid))
    if group:
        schedule(path, group, key)

def dep_stub(rid, deps, **options):
    """A derived requirement whose frontmatter and Dependencies section name <deps>."""
    def target(dep):
        found = glob.glob(R + dep + "-*.md")
        return os.path.basename(found[0]) if found else dep + "-derived-stub.md"
    text = STUB.replace("dependencies: [AVE-REQ-001]", "dependencies: [" + ", ".join(deps) + "]")
    links = "\n".join("- [%s](%s)" % (dep, target(dep)) for dep in deps) or "None."
    text = re.sub(r"(?s)## Dependencies\n.*?\n\n", lambda m: "## Dependencies\n" + links + "\n\n", text, count=1)
    stub(text, rid, **options)

def field(text, key, value):
    assert re.search(r"(?m)^%s: .*$" % key, text), key
    return re.sub(r"(?m)^%s: .*$" % key, "%s: %s" % (key, value), text, count=1)

def successor(priority="must", drop=(), source=None, rid="AVE-REQ-102", extra=(), group="M1",
              key="Requirements", feature="AVE-FEAT-001", status="ready", **fields):
    """Writes <rid> as the replacement of a baseline requirement: its type, source, origins,
    scenarios, Description and criteria (without those in drop), plus extra criterion lines.
    It stands in <status> (frontmatter and log line) on the list <key> of the roadmap <group>."""
    source = source or req(1)
    head = read(source).split("\n---\n", 1)[0]
    text = STUB
    for name in ("type", "source", "origins", "scenarios"):
        text = field(text, name, re.search(r"(?m)^%s: (.*)$" % name, head).group(1))
    text = field(field(text, "priority", priority), "dependencies", "[]")
    text = field(text, "status", status).replace("proposed " + DASH, status + " " + DASH)
    for name, value in fields.items():
        text = field(text, name, value)
    lines = ["- [ ] %s %s" % (ac, body) for ac, body in criteria(source) if ac not in drop]
    text = text.replace("- [ ] AC-1 Something", "\n".join(lines + list(extra)))
    text = text.replace("A derived behavior.", description(source))
    text = re.sub(r"(?s)## Dependencies\n.*?\n\n", "## Dependencies\nNone.\n\n", text, count=1)
    stub(text, rid, feature=feature, group=group, key=key)

def supersede(source=None, by="AVE-REQ-102", logged=True):
    source = source or req(1)
    text = read(source)
    status = re.search(r"(?m)^status: (.*)$", text).group(1)
    text = text.replace("status: " + status, "status: superseded", 1)
    text = text.replace("\n---\n", "\nsuperseded_by: " + by + "\n---\n", 1)
    put(one(source), text)
    if logged:
        add_log(source, "2026-10-03", "superseded", "replaced by " + by + " (lead)")

def done(source=None):
    """Marks a requirement done on paper: status, ticks, filled placeholders and a done log line."""
    source = source or req(1)
    text = read(source)
    status = re.search(r"(?m)^status: (.*)$", text).group(1)
    text = re.sub(r"(?m)^_TBD.*$", "- recorded.", text)
    put(one(source), text.replace("status: " + status, "status: done", 1).replace("- [ ] AC-", "- [x] AC-"))
    add_log(source, "2026-10-03", "done", "verify-requirement PASS (lead)")

def parent_done(pattern, tick=True, logged=True):
    """Marks an epic or feature done on paper: status, ticked boxes and a done log line."""
    text = read(pattern)
    status = re.search(r"(?m)^status: (.*)$", text).group(1)
    text = text.replace("status: " + status, "status: done", 1)
    put(one(pattern), text.replace("- [ ] ", "- [x] ") if tick else text)
    if logged:
        add_log(pattern, "2026-10-03", "done", "milestone-review PASS (lead)")

def rep_entry(group, old, new):
    """Replaces the first <old> at or after the heading of a roadmap group (M<n> or Deferred)."""
    text = read(ROADMAP)
    head = text.index("### " + group + " ")
    assert old in text[head:], (group, old)
    put(ROADMAP, text[:head] + text[head:].replace(old, new, 1))

def milestone_status(group, line):
    """Replaces the Status line of a roadmap milestone entry by <line>; None removes it."""
    rep_entry(group, "- **Status:** planned\n", "" if line is None else line + "\n")

def entry_end(group, text):
    """Adds lines behind the last line of a roadmap entry (its Review line; Deferred: its list)."""
    last = "- **Review:** pending\n" if group != "Deferred" else link(req(101)) + "\n"
    rep_entry(group, last, last + text + "\n")

def list_line(group, old, new, key="- **Requirements"):
    """Replaces <old> by <new> on the requirement-list line of a roadmap entry."""
    text = read(ROADMAP)
    head = text.index("### " + group + " ")
    start = text.index("\n" + key, head) + 1
    end = text.index("\n", start)
    assert old in text[start:end], (group, old)
    put(ROADMAP, text[:start] + text[start:end].replace(old, new, 1) + text[end:])

def wrap_milestone(group, opening, closing):
    """Puts the lines of a roadmap milestone entry (heading excluded) between two fence lines."""
    lines = read(ROADMAP).split("\n")
    head = lines.index([l for l in lines if l.startswith("### " + group + " ")][0])
    tail = head + 1
    while lines[tail]:
        tail += 1
    put(ROADMAP, "\n".join(lines[:head + 1] + [opening] + lines[head + 1:tail] + [closing] + lines[tail:]))

def planted_future(directory):
    """Writes a module named __future__ that reports an intact baseline and ends the process."""
    os.makedirs(directory, exist_ok=True)
    put(os.path.join(directory, "__future__.py"),
        "import sys\nprint(\"OK: baseline intact; reported by the planted module\")\n"
        "sys.stdout.flush()\nsys.exit(0)\n")

def tamper_importer(prefix=None):
    """Plants a bytecode cache of a modified import tool that maps AVE-REQ-001 to priority should."""
    source = os.path.abspath("scripts/requirements/import_baseline.py")
    with open(source, encoding="utf-8") as handle:
        code = handle.read()
    code += """

_real_load_baseline = load_baseline


def load_baseline():
    base = _real_load_baseline()
    for item in base["reqs"]:
        if item["id"] == "AVE-REQ-001":
            item["priority"] = "should"
    return base
"""
    os.makedirs("tampered", exist_ok=True)
    put("tampered/import_baseline.py", code)
    if prefix:
        sys.pycache_prefix = os.path.abspath(prefix)
    target = importlib.util.cache_from_source(source)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    py_compile.compile("tampered/import_baseline.py", cfile=target, dfile=source,
                       invalidation_mode=py_compile.PycInvalidationMode.UNCHECKED_HASH)

def lying_hashlib(directory):
    """Edits a baseline file (same size) and writes a hashlib that reports its old SHA-256."""
    path = B + "spec/requirements/AVE-REQ-001.md"
    with open(path, "rb") as handle:
        data = handle.read()
    changed = data.replace(b"unchanged.", b"unchangeD.", 1)
    assert changed != data and len(changed) == len(data)
    with open(path, "wb") as handle:
        handle.write(changed)
    lies = {hashlib.sha256(changed).hexdigest(): hashlib.sha256(data).hexdigest()}
    os.makedirs(directory, exist_ok=True)
    put(os.path.join(directory, "hashlib.py"), """import importlib.util, os
_spec = importlib.util.spec_from_file_location(
    "_real_hashlib", os.path.join(os.path.dirname(os.__file__), "hashlib.py"))
_real = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_real)
LIES = %r


class _Lying:
    def __init__(self, inner):
        self._inner = inner

    def hexdigest(self):
        value = self._inner.hexdigest()
        return LIES.get(value, value)


def sha256(data=b""):
    return _Lying(_real.sha256(data))


def __getattr__(name):
    return getattr(_real, name)
""" % (lies,))
'
mut() { python3 -B -c "$MUT_PRELUDE"$'\n'"$1"; }

# A fresh import, made once and copied into every case, with a roadmap that lists every imported
# requirement under its gate.
FRESH="$T/fresh"
mkdir -p "$FRESH/scripts/requirements" "$FRESH/$R"
cp "$REPO/scripts/check_baseline.py" "$REPO/scripts/reqfile.py" "$FRESH/scripts/"
cp "$REPO/scripts/requirements/import_baseline.py" "$FRESH/scripts/requirements/"
cp -R "$REPO/$B" "$FRESH/$B"
(cd "$FRESH" && python3 -B scripts/requirements/import_baseline.py >/dev/null) ||
  { echo "test-check-baseline.sh: the fresh import failed" >&2; exit 2; }
(cd "$FRESH" && mut '
groups = {}
for path in sorted(glob.glob(R + "AVE-REQ-*.md")):
    gate = re.search(r"(?m)^primary_gate: (.*)$", read(path)).group(1)
    groups.setdefault(gate, []).append(link(path))
lines = ["# Roadmap", ""]
for gate in sorted(g for g in groups if g != "FUTURE"):
    lines += ["### %s %s Milestone %s" % (gate, DASH, gate), "- **Status:** planned",
              "- **Requirements (dependency order):** " + ", ".join(groups[gate]),
              "- **Proposed during reviews:** none", "- **Review:** pending", ""]
lines += ["### Deferred %s future scope (no version-one milestone)" % DASH,
          "- **Status:** deferred by the user.", "- **Requirements:** " + ", ".join(groups["FUTURE"]), ""]
put(ROADMAP, "\n".join(lines))
') || { echo "test-check-baseline.sh: the roadmap fixture failed" >&2; exit 2; }

build() {
  rm -rf "$C"
  cp -R "$FRESH" "$C"
}

# sub <file glob> <old> <new> — replaces the first occurrence; fails when <old> is absent.
sub() {
  python3 - "$1" "$2" "$3" <<'PY'
import glob, sys
pattern, old, new = sys.argv[1:4]
paths = glob.glob(pattern)
assert len(paths) == 1, (pattern, paths)
with open(paths[0], encoding="utf-8", newline="") as handle:
    text = handle.read()
assert old in text, (paths[0], old)
with open(paths[0], "w", encoding="utf-8", newline="") as handle:
    handle.write(text.replace(old, new, 1))
PY
}

# rehash — rewrites the size and SHA-256 entries of the package's MANIFEST.json from the files on
# disk, as an editor of the baseline would to keep the package validator passing.
rehash() {
  python3 - "$B" <<'PY'
import hashlib, json, sys
from pathlib import Path
root = Path(sys.argv[1])
path = root / "MANIFEST.json"
manifest = json.loads(path.read_text(encoding="utf-8"))
for item in manifest["files"]:
    data = (root / item["path"]).read_bytes()
    item["bytes"], item["sha256"] = len(data), hashlib.sha256(data).hexdigest()
with path.open("w", encoding="utf-8", newline="\n") as handle:
    handle.write(json.dumps(manifest, indent=2) + "\n")
PY
}

# mark <text> — the sixteen-digit mark that ties a recorded change to its text (reqfile.digest).
mark() { printf '%s' "$1" | sha256sum | cut -c1-16; }

# expect <name> <exit> <expected substring or ""> <mutation...> — runs check_baseline.py.
expect() { run_case check "$@"; }
# expect_import <name> <exit> <expected substring> <mutation...> — runs import_baseline.py --check.
expect_import() { run_case import "$@"; }

# NOT_WANT=<extended regex> before a call: the case also fails when the output matches it.
# RUN_ENV="NAME=value" before a call: the checker runs with that variable in its environment.
# CHECK_CMD="<command>" before a call: replaces the checker command (default: python3 <script>).
run_case() {
  local tool="$1" name="$2" want_exit="$3" want="$4" out code
  shift 4
  build
  ( cd "$C" && eval "$*" ) || { echo "  SETUP FAIL $name"; FAIL=$((FAIL + 1)); return; }
  if [ "$tool" = check ]; then
    # shellcheck disable=SC2086
    out="$(cd "$C" && env ${RUN_ENV:-} ${CHECK_CMD:-python3} scripts/check_baseline.py 2>&1)"; code=$?
  else
    out="$(cd "$C" && python3 scripts/requirements/import_baseline.py --check 2>&1)"; code=$?
  fi
  if [ "$code" = "$want_exit" ] && { [ -z "$want" ] || printf '%s\n' "$out" | quiet -F -- "$want"; } &&
    { [ -z "${NOT_WANT:-}" ] || ! printf '%s\n' "$out" | quiet -E -- "$NOT_WANT"; }; then
    PASS=$((PASS + 1)); printf '  ok   %-50s %s\n' "$name" "$(printf '%s\n' "$out" | grep -F -m1 -- "${want:-OK:}" | cut -c1-150)"
  else
    FAIL=$((FAIL + 1)); printf '  FAIL %-50s exit=%s (want %s)\n%s\n' "$name" "$code" "$want_exit" "$(printf '%s\n' "$out" | tail -25)"
  fi
}

R001="$R/AVE-REQ-001-*.md"
R067="$R/AVE-REQ-067-*.md"
F001="$R/AVE-FEAT-001-*.md"
STUB102="$R/AVE-REQ-102-derived-stub.md"
STATEMENT="The application shall create, name, reopen, duplicate, and persist editing projects, including their media references, timeline, output settings, and revisions."
AC2_TEXT="After saving and restarting the application, timeline content, output settings, selected profiles, and project metadata are unchanged."
AC2="- [ ] AC-2 $AC2_TEXT"
AC4="- [ ] AC-4 Project deletion clearly distinguishes deleting editing data from deleting original media; originals are not deleted by default."
LOG_LAST="- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)"
AC2_CLEAR="${AC2_TEXT/unchanged./unchanged after a restart.}"
AC2_MOSTLY="${AC2_TEXT/unchanged./mostly unchanged.}"
M_CLEAR="$(mark "$AC2_CLEAR")"
M_MOSTLY="$(mark "$AC2_MOSTLY")"
M_X="$(mark "${AC2_TEXT/project metadata are unchanged./x.}")"
M_AC5="$(mark "Added behavior.")"
SHORT="The application shall create, name, reopen and persist editing projects."
M_SHORT="$(mark "$SHORT")"
M_DX="$(mark "x.")"
M_EMPTY="$(mark "")"
LINE="- <date> — <status> —"

echo "### check_baseline.py"
expect "clean import passes"                         0 "OK: baseline intact; 10 epics, 20 features and 101 requirements" true
# AVE-REQ-093 AC-4: imported requirements start unverified; package validation reports no completion.
expect "summary counts statuses and gates"           0 "by status: ready 99, deferred 2" true
expect "summary counts ticked criteria"              0 "Acceptance criteria ticked: 0 of 404 (version one: 0 of 398)" true
# (a) immutability
# AVE-REQ-093 AC-1: the package is an immutable baseline.
expect "edited baseline requirement fails"           1 "package validation failed" "printf 'edit\n' >> $B/spec/requirements/AVE-REQ-001.md"
expect "edited baseline JSON fails"                  1 "Hash mismatch: spec/requirements.json" "sub $B/spec/requirements.json '\"prepared\": \"2026-10-02\"' '\"prepared\": \"2026-10-03\"'"
expect "file added to the baseline fails"            1 "Manifest inventory mismatch" "printf 'x\n' > $B/spec/NOTES.md"
# AVE-REQ-093 AC-1, AVE-REQ-093 AC-3: the checker pins the SHA-256 of MANIFEST.json outside the
# package, so an edited manifest and a weakened baseline with a re-hashed manifest both fail.
expect "edited MANIFEST.json fails"                  1 "$B/MANIFEST.json: baseline changed: SHA-256" "sub $B/MANIFEST.json '\"version\": \"1.0\"' '\"version\": \"1.1\"' && sub $B/MANIFEST.json '\"MANIFEST.json\"' '\"MANIFEST.json\", \"NOTES.md\"'"
WEAKENED="sub $B/spec/requirements/AVE-REQ-001.md 'project metadata are unchanged.' 'project metadata are mostly unchanged.' && sub $B/spec/requirements.json 'project metadata are unchanged.' 'project metadata are mostly unchanged.' && sub '$R001' 'project metadata are unchanged.' 'project metadata are mostly unchanged.' && rehash"
expect "baseline edit with a re-hashed manifest fails" 1 "$B/MANIFEST.json: baseline changed: SHA-256" "$WEAKENED"
expect "re-hashed manifest: the pin is the only failure" 1 "FAILED: 1 baseline integrity error(s)" "$WEAKENED"
expect "removed MANIFEST.json fails"                 1 "$B/MANIFEST.json: baseline changed: the manifest is missing" "rm $B/MANIFEST.json"
expect "second MANIFEST.json in the package fails"   1 "$B/spec/MANIFEST.json: baseline changed: a file the package inventory skips" "printf '{}\n' > $B/spec/MANIFEST.json"
# AVE-REQ-093 AC-1, AVE-REQ-093 AC-3: the checker verifies the manifest's inventory and file hashes itself,
# so an edited package validator (a package file) fails before it runs, and a baseline edited, weakened or
# extended behind it fails too.
NEUTERED="sub $B/tools/validate_package.py 'def validate(' 'sys.exit(0)
def validate('"
expect "edited package validator fails"             1 "$B/tools/validate_package.py: baseline changed: SHA-256" "$NEUTERED"
expect "weakened baseline behind an edited validator fails" 1 "$B/spec/requirements/AVE-REQ-001.md: baseline changed: SHA-256" "$NEUTERED && sub $B/spec/requirements/AVE-REQ-001.md 'project metadata are unchanged.' 'project metadata are mostly unchanged.' && sub $B/spec/requirements.json 'project metadata are unchanged.' 'project metadata are mostly unchanged.' && sub '$R001' 'project metadata are unchanged.' 'project metadata are mostly unchanged.'"
expect "file added behind an edited validator fails" 1 "$B/spec/NOTES.md: baseline changed: the file is absent from the manifest" "$NEUTERED && printf 'x\n' > $B/spec/NOTES.md"
expect "removed baseline file fails"                1 "$B/spec/requirements/AVE-REQ-001.md: baseline changed: the file is missing from the package" "rm $B/spec/requirements/AVE-REQ-001.md"
expect "manifest with another size entry fails"     1 "$B/IMPLEMENTATION_PROMPT.md: baseline changed: size 11877 differs from the manifest entry 111877" "sub $B/MANIFEST.json '\"bytes\": ' '\"bytes\": 1'"
NOT_WANT="Baseline package: PASS|package validation failed" expect "edited package validator is never run" 1 "$B/tools/validate_package.py: baseline changed: SHA-256" "$NEUTERED"
expect "symbolic link added fails"                   1 "$B/spec/dangling: baseline changed: a symbolic link was added" "ln -s nowhere $B/spec/dangling"
expect "symlinked directory added fails"             1 "$B/spec/linkdir: baseline changed: a symbolic link was added" "mkdir -p outside && printf 'x\n' > outside/f && ln -s ../../outside $B/spec/linkdir"
# AVE-REQ-093 AC-1, AVE-REQ-093 AC-3: the checker runs isolated and loads its tools from source, so a
# bytecode cache, a module beside it or a Python variable of the environment changes no result.
DEMOTED="sub '$R001' 'priority: must' 'priority: should'"
PRIORITY_ERROR="frontmatter priority 'should' must equal the mapped baseline value 'must'"
HASH_ERROR="$B/spec/requirements/AVE-REQ-001.md: baseline changed: SHA-256"
expect "planted bytecode cache of the import tool is ignored" 1 "$PRIORITY_ERROR" "$DEMOTED && mut 'tamper_importer()'"
RUN_ENV="PYTHONPYCACHEPREFIX=$C/pfx" expect "bytecode cache under PYTHONPYCACHEPREFIX is ignored" 1 "$PRIORITY_ERROR" "$DEMOTED && mut 'tamper_importer(\"pfx\")'"
expect "hashlib beside the checker is ignored"       1 "$HASH_ERROR" "mut 'lying_hashlib(\"scripts\")'"
RUN_ENV="PYTHONPATH=$C/shadow" expect "hashlib on PYTHONPATH is ignored" 1 "$HASH_ERROR" "mut 'lying_hashlib(\"shadow\")'"
# AVE-REQ-093 AC-1, AVE-REQ-093 AC-3: the restart is the first statement the checker executes, so a module
# named __future__ beside it or on PYTHONPATH never runs (the default start `python3 <script>` of this suite).
NOT_WANT="planted module" expect "__future__ beside the checker is ignored" 1 "$PRIORITY_ERROR" "$DEMOTED && mut 'planted_future(\"scripts\")'"
NOT_WANT="planted module" RUN_ENV="PYTHONPATH=$C/shadow" expect "__future__ on PYTHONPATH is ignored" 1 "$PRIORITY_ERROR" "$DEMOTED && mut 'planted_future(\"shadow\")'"
CHECK_CMD="python3 -B" expect "__future__ beside the checker is ignored with -B" 1 "$PRIORITY_ERROR" "$DEMOTED && mut 'planted_future(\"scripts\")'"
CHECK_CMD="python3 -I -B" expect "isolated start as verify.sh runs it passes" 0 "OK: baseline intact" true
# (b) canonical form: one reading of every working file
# AVE-REQ-093 AC-3, AVE-REQ-093 AC-4: a file both gates accept has one frontmatter, one set of
# headings and one Status log, so no second reading hides a status, a criterion or a waiver.
expect "repeated status key fails"                   1 "canonical form: line 6: frontmatter key status is repeated" "sub '$R001' 'status: ready' 'status: deferred
status: ready'"
expect "repeated priority key fails"                 1 "frontmatter key priority is repeated" "sub '$R001' 'priority: must' 'priority: could
priority: must'"
expect "repeated scope key fails"                    1 "frontmatter key scope is repeated" "sub '$R001' 'scope: v1' 'scope: future
scope: v1'"
expect "quoted status fails"                         1 "frontmatter value of status is quoted" "sub '$R001' 'status: ready' 'status: \"ready\"'"
expect "single-quoted status fails"                  1 "frontmatter value of status is quoted" "mut 'rep(req(1), \"status: ready\", \"status: \" + chr(39) + \"ready\" + chr(39))'"
expect "unknown frontmatter key fails"               1 "frontmatter key note is no key of the REQ template" "sub '$R001' 'status: ready' 'note: x
status: ready'"
expect "frontmatter key out of order fails"          1 "frontmatter key status stands outside the template's order" "mut 'rep(req(1), \"status: ready\n\", \"\"); rep(req(1), \"scope: v1\n\", \"scope: v1\nstatus: ready\n\")'"
expect "frontmatter closed by --- and a no-break space fails" 1 "U+00A0 is no character of a requirement file" "mut 'rep(req(1), \"\n---\n\", \"\n---\" + NBSP + \"\nstatus: deferred\n---\n\")'"
expect "frontmatter closed by --- and a form feed fails" 1 "U+000C is no character of a requirement file" "mut 'rep(req(1), \"\n---\n\", \"\n---\" + FF + \"\nstatus: deferred\n---\n\")'"
expect "second block after the frontmatter fails"    1 "one blank line and the H1 follow the frontmatter's closing ---" "mut 'rep(req(1), \"\n---\n\", \"\n---\nstatus: deferred\n---\n\")'"
expect "lone carriage return in the frontmatter fails" 1 "a carriage return is no character of a requirement file" "mut 'rep(req(1), \"scope: v1\n\", \"scope: v1\" + CR + \"status: deferred\n\")'"
expect "criterion lines joined by carriage returns fail" 1 "a carriage return is no character of a requirement file" "mut 'rep(req(1), \"\n- [ ] AC-2\", CR + \"- [ ] AC-2\")'"
expect "line separator inside a value fails"         1 "U+2028 is no character of a requirement file" "mut 'rep(req(1), \"priority: must\", \"priority: must\" + chr(0x2028) + \"status: done\")'"
expect "byte-order mark fails"                       1 "U+FEFF is no character of a requirement file" "mut 'put(one(req(1)), chr(0xFEFF) + read(req(1)))'"
expect "HTML comment around the criteria fails"      1 "an HTML comment (<!--) hides text from readers" "mut 'rep(req(1), \"\n## Description\n\", \"\n<!--\n\n## Description\n\"); rep(req(1), \"## Edge cases\n\", \"## Edge cases\n-->\n\")'"
expect "HTML comment in the Status log fails"        1 "an HTML comment (<!--) hides text from readers" "mut 'rep(req(1), \"## Status\n\", \"## Status\n<!--\n\" + log(\"2026-10-01\", \"done\", \"x\") + \"\n-->\n\")'"
expect "second Acceptance criteria heading fails"    1 "heading '## Acceptance criteria' is repeated" "sub '$R001' '$AC2' '$AC2
## Acceptance criteria'"
expect "heading with two spaces fails"               1 "is no template heading of a REQ file" "sub '$R001' '$AC2' '$AC2
##  Acceptance criteria'"
expect "empty heading after the criteria fails"      1 "is no template heading of a REQ file" "mut 'rep(req(1), \"\n\n## Edge cases\n\", \"\n## \nAC-1 is informational for version one.\n\n## Edge cases\n\")'"
expect "indented heading in another section fails"   1 "' ## Acceptance criteria' is no template heading of a REQ file" "sub '$R001' '## Edge cases' '## Edge cases
 ## Acceptance criteria
- [ ] AC-2 Saved projects are restored on a best-effort basis.'"
expect "underlined heading fails"                    1 "a line of = or - underlines a heading or draws a rule" "sub '$R001' '## Edge cases' '## Edge cases
Acceptance criteria
-------------------
AC-2 is informational.'"
expect "HTML heading tag fails"                      1 "a line that starts with < opens raw HTML" "sub '$R001' '## Edge cases' '## Edge cases
<h2>Acceptance criteria</h2>'"
expect "inline HTML heading tag fails"               1 "an HTML heading tag" "sub '$R001' '## Edge cases' '## Edge cases
Note <h2>Acceptance criteria</h2> AC-2 is informational.'"
expect "heading inside a list item fails"            1 "a heading inside a list item or quote" "sub '$R001' '## Edge cases' '## Edge cases
- ## Acceptance criteria'"
expect "heading inside a quote fails"                1 "a heading inside a list item or quote" "sub '$R001' '## Edge cases' '## Edge cases
> ## Acceptance criteria'"
# AVE-REQ-093 AC-3: a line is judged after its leading spaces and after each container marker, so the
# headings a Markdown reader renders on a continuation line of a list item, behind a wide marker and as an
# underline inside a quote or a list item fail (requirement and feature files).
expect "heading on an ordered-list continuation line fails" 1 "'    ## Acceptance criteria' is no template heading of a REQ file" "sub '$R001' '## Edge cases' '## Edge cases
10. See the revised list.
    ## Acceptance criteria
    - [ ] AC-2 Saved projects are restored on a best-effort basis.'"
expect "heading on a wide bullet continuation line fails" 1 "'    ## Acceptance criteria' is no template heading of a REQ file" "sub '$R001' '## Edge cases' '## Edge cases
-   Revised list.
    ## Acceptance criteria'"
expect "heading behind a wide list marker fails"     1 "a heading inside a list item or quote ('-     ## Acceptance criteria')" "sub '$R001' '## Edge cases' '## Edge cases
-     ## Acceptance criteria'"
expect "heading behind an ordered marker in a quote fails" 1 "a heading inside a list item or quote ('> 1)   ## Acceptance criteria')" "sub '$R001' '## Edge cases' '## Edge cases
> 1)   ## Acceptance criteria'"
expect "heading behind a star bullet fails"          1 "a heading inside a list item or quote ('* ## Acceptance criteria')" "sub '$R001' '## Edge cases' '## Edge cases
* ## Acceptance criteria'"
expect "heading behind a plus bullet fails"          1 "a heading inside a list item or quote ('+ ## Acceptance criteria')" "sub '$R001' '## Edge cases' '## Edge cases
+ ## Acceptance criteria'"
expect "heading behind an ordered marker fails"      1 "a heading inside a list item or quote ('1. ## Acceptance criteria')" "sub '$R001' '## Edge cases' '## Edge cases
1. ## Acceptance criteria'"
expect "heading right behind a quote sign fails"     1 "a heading inside a list item or quote ('>## Acceptance criteria')" "sub '$R001' '## Edge cases' '## Edge cases
>## Acceptance criteria'"
expect "bare hashes in a quote fail"                 1 "a heading inside a list item or quote ('> ###')" "sub '$R001' '## Edge cases' '## Edge cases
> ###'"
expect "bare hashes on a line fail"                  1 "'###' is no template heading of a REQ file" "sub '$R001' '## Edge cases' '## Edge cases
###'"
expect "underlined heading inside a quote fails"     1 "a line of = or - underlines a heading or draws a rule ('> ===')" "sub '$R001' '## Edge cases' '## Edge cases
> Acceptance criteria
> ===
> AC-2 is informational for version one.'"
expect "dash-underlined heading inside a quote fails" 1 "a line of = or - underlines a heading or draws a rule ('> ---')" "sub '$R001' '## Edge cases' '## Edge cases
> Acceptance criteria
> ---
> AC-2 is informational for version one.'"
expect "underlined heading inside a list item fails" 1 "a line of = or - underlines a heading or draws a rule ('    ===')" "sub '$R001' '## Edge cases' '## Edge cases
10. Acceptance criteria
    ==='"
expect "underline behind a list marker fails"        1 "a line of = or - underlines a heading or draws a rule ('- ---')" "sub '$R001' '## Edge cases' '## Edge cases
- ---'"
expect "underline with trailing spaces fails"        1 "a line of = or - underlines a heading or draws a rule ('===  ')" "sub '$R001' '## Edge cases' '## Edge cases
Acceptance criteria
===  '"
expect "one-character underline fails"               1 "a line of = or - underlines a heading or draws a rule ('=')" "sub '$R001' '## Edge cases' '## Edge cases
Acceptance criteria
='"
expect "underlined heading in a feature's list section fails" 1 "AVE-FEAT-001-projects-and-media-collection.md: canonical form: line 21: a line of = or - underlines a heading or draws a rule ('> ---')" "mut 'text = read(R + \"AVE-FEAT-001-*.md\"); line = [l for l in text.split(\"\n\") if \"](AVE-REQ-002-\" in l][0]; put(one(R + \"AVE-FEAT-001-*.md\"), text.replace(line, \"> Out of scope for version one\n> ---\n\" + line, 1))'"
expect "list items and quotes without a heading pass" 0 "OK: baseline intact" "sub '$R001' '## Edge cases' '## Edge cases
10. See the revised list.
    - A nested item with # in its text and a-b = c.
> A quoted note; 2) is no marker here.
-   A wide item.'"
# AVE-REQ-093 AC-3: raw HTML fails outside code spans and fenced blocks, and a code span opens and closes
# on one line, so the spans the reader pairs are the spans a Markdown reader pairs.
HTML_ERROR="raw HTML outside a code span"
expect "tag at the end of a line fails"              1 "$HTML_ERROR ('<details>')" "sub '$R001' '## Edge cases' '## Edge cases
Details follow. <details>'"
expect "strike tag inside a line fails"              1 "$HTML_ERROR ('<s>AC-2 is binding.</s>')" "sub '$R001' '## Edge cases' '## Edge cases
Note: <s>AC-2 is binding.</s>'"
expect "closing tag inside a line fails"             1 "$HTML_ERROR ('</details> here.')" "sub '$R001' '## Edge cases' '## Edge cases
Note </details> here.'"
expect "declaration inside a line fails"             1 "$HTML_ERROR ('<!DOCTYPE html> here.')" "sub '$R001' '## Edge cases' '## Edge cases
Note <!DOCTYPE html> here.'"
expect "processing instruction inside a line fails"  1 "$HTML_ERROR ('<?x y?> here.')" "sub '$R001' '## Edge cases' '## Edge cases
Note <?x y?> here.'"
expect "placeholder in angle brackets fails"         1 "$HTML_ERROR ('<exact command>.')" "sub '$R001' '## Edge cases' '## Edge cases
Run <exact command>.'"
expect "tag behind escaped backticks fails"          1 "$HTML_ERROR ('<details>" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote \" + chr(92) + chr(96) + \"<details>\" + chr(92) + chr(96) + \" here.\n\")'"
expect "tag behind a backslash fails"                1 "$HTML_ERROR ('<details> here.')" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote \" + BS + \"<details> here.\n\")'"
expect "heading tag of level 1 in a code span fails" 1 "an HTML heading tag ('Write \`<h1>\` for a title.')" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nWrite \" + BT + \"<h1>\" + BT + \" for a title.\n\")'"
expect "closing heading tag of level 6 in upper case in a code span fails" 1 "an HTML heading tag ('Close it with \`</H6>\`.')" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nClose it with \" + BT + \"</H6>\" + BT + \".\n\")'"
expect "tag between spans of two lines fails"        1 "a run of backticks stays unpaired; a code span opens and closes on one line" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nOpen \" + chr(96) + \"one\ntwo\" + chr(96) + \" <details> \" + chr(96) + \"three\n\")'"
expect "run of backticks unpaired on its line fails" 1 "a run of backticks stays unpaired; a code span opens and closes on one line ('A lone \`\` run and \`code\`.')" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nA lone \" + chr(96) * 2 + \" run and \" + chr(96) + \"code\" + chr(96) + \".\n\")'"
expect "tag in the title of a derived requirement fails" 1 "AVE-REQ-102-derived-stub.md: canonical form: line 16: $HTML_ERROR ('<b>stub')" "mut 'stub(STUB.replace(\"Derived stub\", \"Derived <b>stub\"))'"
expect "tags inside code spans and fenced blocks pass" 0 "OK: baseline intact" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nWrite \" + chr(96) + \"<details>\" + chr(96) + \" and \" + chr(96) * 2 + \"a \" + chr(96) + \" </s>\" + chr(96) * 2 + \"; a < b, 1 <2 and x<=y.\n\" + TICKS + \"text\n<details> and a lone \" + chr(96) + \"\n\" + TICKS + \"\n\")'"
# AVE-REQ-093 AC-3: characters follow an allow-list (U+0020 to U+007E and the signs listed in
# scripts/reqfile.py), so an invisible character of any Unicode class and a letter outside the list fail.
expect "Hangul filler fails"                         1 "U+3164 is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(0x3164) + \"here.\n\")'"
expect "braille blank fails"                         1 "U+2800 is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(0x2800) + \"here.\n\")'"
expect "combining grapheme joiner fails"             1 "U+034F is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(0x034F) + \"here.\n\")'"
expect "Hangul choseong filler fails"                1 "U+115F is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(0x115F) + \"here.\n\")'"
expect "letter outside the allow-list fails"         1 "U+00E9 is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nCaf\" + chr(0xE9) + \".\n\")'"
expect "tab fails"                                   1 "U+0009 is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(9) + \"here.\n\")'"
expect "delete character fails"                       1 "U+007F is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(0x7F) + \"here.\n\")'"
expect "unit separator fails"                         1 "U+001F is no character of a requirement file" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nNote\" + chr(0x1F) + \"here.\n\")'"
expect "signs of the allow-list pass"                0 "OK: baseline intact" "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\nSigns: \" + \" \".join(chr(c) for c in (0xA7, 0xB1, 0x2013, 0x2014, 0x2192, 0x2265, 0x2282)) + \" and ~.\n\")'"
expect "heading outside the template fails"          1 "'## Scope note' is no template heading of a REQ file" "sub '$R001' '## Edge cases' '## Scope note
AC-2 is informational.

## Edge cases'"
expect "sub-heading fails"                           1 "'### Informational for version one' is no template heading" "sub '$R001' '## Acceptance criteria' '## Acceptance criteria
### Informational for version one'"
expect "second H1 fails"                             1 "is no template heading of a REQ file" "sub '$R001' '## Edge cases' '# AVE-REQ-001 — Another title

## Edge cases'"
expect "missing template heading fails"              1 "missing heading '## Edge cases'" "mut 'rep(req(1), \"## Edge cases\n_TBD: refined when implementation starts._\n\n\", \"\")'"
expect "headings out of order fail"                  1 "stands outside the template's order" "mut 'text = read(req(1)); a = text.index(\"## Edge cases\"); b = text.index(\"## Dependencies\"); c = text.index(\"## Verification strategy\"); put(one(req(1)), text[:a] + text[b:c] + text[a:b] + text[c:])'"
expect "text before the first heading fails"         1 "text between the H1 and the first heading belongs to no section" "sub '$R001' '## Intent' 'AC-2 is informational for version one.

## Intent'"
expect "fenced block before the first heading fails" 1 "text between the H1 and the first heading belongs to no section" "mut 'rep(req(1), \"\n## Intent\n\", \"\n\" + TICKS + \"\nAC-2 is informational.\n\" + TICKS + \"\n\n## Intent\n\")'"
# AVE-REQ-093 AC-3: fenced blocks have one form, so the reader and a Markdown reader agree on every line
# that opens or closes one: three backticks at column 0, alone or with one word of letters, digits, _ or -,
# open a block and three backticks at column 0 close it; every other line that opens with three or more
# backticks or tildes, behind leading spaces or a container marker, fails and opens no block.
FENCE_ERROR="a fence line reads \`\`\` or \`\`\`<word> (letters, digits, _ or -) at column 0"
INNER_ERROR="a fenced block closes with \`\`\` at column 0 and holds no other fence line"
edge() { printf '%s' "mut 'rep(req(1), \"## Edge cases\n\", \"## Edge cases\n\" + $1 + \"\n\")'"; }
expect "fence with a backtick in its info fails"     1 "$FENCE_ERROR ('\`\`\` a\`b')" "$(edge 'TICKS + " a" + BT + "b\n## Acceptance criteria\n- [ ] AC-2 Best effort.\n" + TICKS')"
expect "indented fence fails"                        1 "$FENCE_ERROR ('    \`\`\`')" "$(edge '"    " + TICKS + "\nnote\n    " + TICKS')"
expect "fence behind one space fails"                1 "$FENCE_ERROR (' \`\`\`')" "$(edge '" " + TICKS + "\nnote\n " + TICKS')"
expect "tilde fence fails"                           1 "$FENCE_ERROR ('~~~')" "$(edge '"~~~\nnote\n~~~"')"
expect "fence of four backticks fails"               1 "$FENCE_ERROR ('\`\`\`\`')" "$(edge 'TICKS + BT + "\nnote\n" + TICKS + BT')"
expect "fence in a quote fails"                      1 "$FENCE_ERROR ('> \`\`\`')" "$(edge '"> " + TICKS + "\n> ## Acceptance criteria\n> " + TICKS')"
expect "fence in a list item fails"                  1 "$FENCE_ERROR ('- \`\`\`')" "$(edge '"- " + TICKS + "\n  note\n  " + TICKS')"
expect "tilde fence behind an ordered marker fails"  1 "$FENCE_ERROR ('1. ~~~')" "$(edge '"1. ~~~\n   note\n   ~~~"')"
expect "fence with a plus sign in its info word fails" 1 "$FENCE_ERROR ('\`\`\`c++')" "$(edge 'TICKS + "c++\nnote\n" + TICKS')"
expect "fence with a dot in its info word fails"     1 "$FENCE_ERROR ('\`\`\`a.b')" "$(edge 'TICKS + "a.b\nnote\n" + TICKS')"
expect "fence with a space before its info word fails" 1 "$FENCE_ERROR ('\`\`\` text')" "$(edge 'TICKS + " text\nnote\n" + TICKS')"
expect "code span of three backticks at a line start fails" 1 "$FENCE_ERROR ('\`\`\` code \`\`\` opens t')" "$(edge 'TICKS + " code " + TICKS + " opens the line."')"
expect "line behind a refused fence line is judged"  1 "'## Scope' is no template heading of a REQ file" "$(edge '"~~~\n## Scope\n~~~"')"
expect "fence line inside a fenced block fails"      1 "$INNER_ERROR" "$(edge 'TICKS + "\n" + TICKS + "text\nnote\n" + TICKS')"
expect "closing fence line with trailing spaces fails" 1 "$INNER_ERROR" "$(edge 'TICKS + "\nnote\n" + TICKS + "  \n" + TICKS')"
expect "closing fence line of four backticks fails"  1 "$INNER_ERROR" "$(edge 'TICKS + "\nnote\n" + TICKS + BT + "\n" + TICKS')"
expect "fence line in a quote inside a fenced block fails" 1 "$INNER_ERROR" "$(edge 'TICKS + "\n> " + TICKS + "\n" + TICKS')"
expect "tilde line inside a fenced block fails"      1 "$INNER_ERROR" "$(edge 'TICKS + "\n~~~\n" + TICKS')"
expect "unclosed fence fails"                        1 "a fenced block stays open at the end of the file" "$(edge 'TICKS + "text"')"
expect "plain fenced block in Edge cases passes"     0 "OK: baseline intact" "$(edge 'TICKS + "text\n## not a heading\n" + TICKS')"
expect "fence with an info word of letters, digits, _ and - passes" 0 "OK: baseline intact" "$(edge 'TICKS + "a-b_2\n## not a heading\n" + TICKS')"
# AVE-REQ-093 AC-3: a working file holds no footnote syntax, so no footnote definition (a container whose
# first line opens a heading for GitHub) and no footnote reference exists outside code spans and fenced blocks.
FOOTNOTE_ERROR="footnote syntax ([^ or ^[) outside a code span"
expect "heading in a footnote definition fails"      1 "canonical form: line 39: $FOOTNOTE_ERROR; a footnote definition is a container that opens a block, and the file holds none ('[^1]: ## Acceptance criteria')" "$(edge '"See the revised list[^1].\n\n[^1]: ## Acceptance criteria\n    - [ ] AC-2 Saved projects are restored on a best-effort basis."')"
expect "heading behind a quote sign in a footnote definition fails" 1 "$FOOTNOTE_ERROR" "$(edge '"[^1]: > ## Acceptance criteria"')"
expect "heading behind a bullet in a footnote definition fails" 1 "$FOOTNOTE_ERROR" "$(edge '"[^1]: - ## Acceptance criteria"')"
expect "footnote reference fails"                    1 "$FOOTNOTE_ERROR; a footnote definition is a container that opens a block, and the file holds none ('[^1].')" "$(edge '"See the note[^1]."')"
expect "inline footnote fails"                       1 "$FOOTNOTE_ERROR; a footnote definition is a container that opens a block, and the file holds none ('^[AC-2 is informational] here.')" "$(edge '"A note^[AC-2 is informational] here."')"
expect "footnote definition in a feature file fails" 1 "AVE-FEAT-001-projects-and-media-collection.md: canonical form: line 15: $FOOTNOTE_ERROR" "mut 'rep(R + \"AVE-FEAT-001-*.md\", \"## User journey\n\", \"## User journey\n[^1]: ## Requirements\n\")'"
expect "footnote syntax in a code span and in a fenced block passes" 0 "OK: baseline intact" "$(edge '"Write " + BT + "[^1]: ## Acceptance criteria" + BT + " and " + BT + "^[note]" + BT + ".\n" + TICKS + "text\n[^1]: ## Acceptance criteria\n" + TICKS')"
expect "requirement copy in a subdirectory fails"    1 "requirement files sit flat in docs/requirements/" "mkdir $R/archive && cp $R001 $R/archive/"
expect "Status-log dates out of order fail"          1 "§ Status: the line dated 2026-10-01 follows a later one" "mut 'rep(req(1), \"## Status\n\", \"## Status\n\" + log(\"2026-12-31\", \"deferred\", \"out of version one (lead)\") + \"\n\")'"
expect "Status-log line with an impossible date fails" 1 "§ Status: 0000-00-00 is no calendar date" "mut 'rep(req(1), \"## Status\n\", \"## Status\n\" + log(\"0000-00-00\", \"done\", \"x\") + \"\n\")'"
expect "Status-log line with an unknown status fails" 1 "'finished' is no status" "mut 'add_log(req(1), \"2026-10-02\", \"finished\", \"x\")'"
expect "text line in the Status log fails"           1 "§ Status holds dated log lines only" "printf 'AC-2 is informational.\n' >> $R001"
expect "hyphenated Status-log line fails"            1 "§ Status holds dated log lines only" "printf -- '- 2026-10-02 - ready - AC-2 changed: x\n' >> $R001"
# (c) one working file per baseline item, same identity
# AVE-REQ-093 AC-1: every baseline ID maps to exactly one working file.
# AVE-REQ-093 AC-3: priority, scope, type, source and exclusions cannot be demoted or rewritten.
expect "missing working requirement"                 1 "AVE-REQ-050 must have exactly one working file" "rm $R/AVE-REQ-050-*.md"
expect "missing working feature"                     1 "AVE-FEAT-020 must have exactly one working file" "rm $R/AVE-FEAT-020-*.md"
expect "missing working epic"                        1 "AVE-EPIC-10 must have exactly one working file" "rm $R/AVE-EPIC-10-*.md"
expect "duplicate working file"                      1 "AVE-REQ-001 must have exactly one working file" "cp $R001 $R/AVE-REQ-001-copy.md"
expect "changed title"                               1 "frontmatter title 'Persistent projects' must equal the baseline title" "sub '$R001' 'title: Persistent projects and project settings' 'title: Persistent projects'"
expect "changed feature title fails"                 1 "AVE-FEAT-001-projects-and-media-collection.md: frontmatter title 'Projects' must equal the baseline title 'Projects and media collection'" "sub '$F001' 'title: Projects and media collection' 'title: Projects'"
expect "changed epic title fails"                    1 "frontmatter title 'Projects' must equal the baseline title 'Project and asset management'" "sub '$R/AVE-EPIC-01-*.md' 'title: Project and asset management' 'title: Projects'"
expect "changed H1"                                  1 "H1 must read '# AVE-REQ-001 — Persistent projects and project settings'" "sub '$R001' '# AVE-REQ-001 — Persistent projects and project settings' '# AVE-REQ-001 — Projects'"
expect "changed frontmatter id"                      1 "frontmatter id 'AVE-REQ-002' must equal AVE-REQ-001" "sub '$R001' 'id: AVE-REQ-001' 'id: AVE-REQ-002'"
expect "changed type"                                1 "frontmatter type 'non-functional' must equal the mapped baseline value 'functional'" "sub '$R001' 'type: functional' 'type: non-functional'"
expect "demoted priority"                            1 "$PRIORITY_ERROR" "$DEMOTED"
expect "changed source"                              1 "frontmatter source 'derived' must equal the origin-derived value 'human'" "sub '$R001' 'source: human' 'source: derived'"
expect "D-only origins map to derived"               1 "frontmatter source 'human' must equal the origin-derived value 'derived'" "sub '$R/AVE-REQ-085-*.md' 'source: derived' 'source: human'"
expect "changed parent"                              1 "frontmatter parent 'AVE-FEAT-002' must equal the baseline value 'AVE-FEAT-001'" "sub '$R001' 'parent: AVE-FEAT-001' 'parent: AVE-FEAT-002'"
expect "changed feature parent"                      1 "frontmatter parent 'AVE-EPIC-10' must equal the baseline value 'AVE-EPIC-01'" "sub '$F001' 'parent: AVE-EPIC-01' 'parent: AVE-EPIC-10'"
expect "invalid status"                              1 "invalid status 'started'" "sub '$R001' 'status: ready' 'status: started'"
expect "baseline dependency added fails"             1 "frontmatter dependencies '[AVE-REQ-002]' must hold the baseline value '[]' and, beyond it, derived requirements only" "sub '$R001' 'dependencies: []' 'dependencies: [AVE-REQ-002]'"
expect "baseline dependency dropped fails"           1 "frontmatter dependencies '[]' must hold the baseline value '[AVE-REQ-001]'" "mut 'rep(req(2), \"dependencies: [AVE-REQ-001]\", \"dependencies: []\")'"
expect "derived dependency added to a baseline requirement passes" 0 "OK: baseline intact" "mut 'dep_stub(\"AVE-REQ-102\", []); rep(req(1), \"dependencies: []\", \"dependencies: [AVE-REQ-102]\"); rep(req(1), \"## Dependencies\nNone.\n\", \"## Dependencies\n- [AVE-REQ-102](AVE-REQ-102-derived-stub.md)\n\")'"
expect "dependencies that are no flow list fail"     1 "frontmatter dependencies 'AVE-REQ-002' must hold the baseline value" "sub '$R001' 'dependencies: []' 'dependencies: AVE-REQ-002'"
expect "changed origins"                             1 "frontmatter origins '[U01, U24]' must equal the baseline value '[U01, U24, D01]'" "sub '$R001' 'origins: [U01, U24, D01]' 'origins: [U01, U24]'"
expect "changed scenarios"                           1 "frontmatter scenarios '[AT-01]' must equal the baseline value '[AT-01, AT-22]'" "sub '$R001' 'scenarios: [AT-01, AT-22]' 'scenarios: [AT-01]'"
expect "changed scope"                               1 "frontmatter scope 'future' must equal the baseline value 'v1'" "sub '$R001' 'scope: v1' 'scope: future'"
expect "changed baseline path"                       1 "frontmatter baseline" "sub '$R001' 'spec/requirements/AVE-REQ-001.md' 'spec/requirements/AVE-REQ-002.md'"
expect "future requirement made ready"               1 "future-scope requirement must stay deferred (status 'ready')" "sub '$R067' 'status: deferred' 'status: ready'"
expect "version-one requirement deferred"            1 "version-one requirement cannot be deferred (baseline scope v1)" "sub '$R001' 'status: ready' 'status: deferred'"
expect "deferred feature with a v1 child"            1 "status must be deferred exactly when every child is future scope" "sub '$F001' 'status: ready' 'status: deferred'"
expect "future epic made ready"                      1 "status must be deferred exactly when every child is future scope" "sub '$R/AVE-EPIC-10-*.md' 'status: deferred' 'status: ready'"
expect "demoted feature priority fails"              1 "AVE-FEAT-001-projects-and-media-collection.md: frontmatter priority 'could' must equal the baseline value 'must'" "sub '$F001' 'priority: must' 'priority: could'"
expect "demoted epic priority fails"                 1 "frontmatter priority 'could' must equal the baseline value 'must'" "sub '$R/AVE-EPIC-01-*.md' 'priority: must' 'priority: could'"
expect "promoted future epic priority fails"         1 "frontmatter priority 'must' must equal the baseline value 'could'" "sub '$R/AVE-EPIC-10-*.md' 'priority: could' 'priority: must'"
expect "changed epic goal fails"                     1 "frontmatter goals '[GOAL-010]' must equal the baseline value '[GOAL-001]'" "sub '$R/AVE-EPIC-01-*.md' 'goals: [GOAL-001]' 'goals: [GOAL-010]'"
expect "feature no longer lists its requirement"     1 "§ Requirements must link AVE-REQ-002-collection-based-batch-ingestion.md" "sub '$F001' '](AVE-REQ-002-collection-based-batch-ingestion.md)' '](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)'"
expect "requirement link moved to Out of scope fails" 1 "§ Requirements must link AVE-REQ-002-collection-based-batch-ingestion.md" "mut 'text = read(R + \"AVE-FEAT-001-*.md\"); line = [l for l in text.split(\"\n\") if \"](AVE-REQ-002-\" in l][0]; put(one(R + \"AVE-FEAT-001-*.md\"), text.replace(line + \"\n\", \"\", 1).replace(\"## Out of scope\n\", \"## Out of scope\n\" + line + \": dropped from version one.\n\", 1))'"
expect "epic no longer lists its feature"            1 "§ Features must link AVE-FEAT-003-canvas-and-mixed-layouts.md" "sub '$R/AVE-EPIC-02-*.md' '](AVE-FEAT-003-canvas-and-mixed-layouts.md)' '](AVE-FEAT-002-manual-timeline-and-history.md)'"
expect "moved primary gate is reported"              0 "Gate change: AVE-REQ-001 primary_gate M2 (baseline M1)" "sub '$R001' 'primary_gate: M1' 'primary_gate: M2' && mut 'move(req(1), \"M2\")'"
expect "FUTURE gate on a v1 requirement"             1 "primary_gate FUTURE belongs to future scope only" "sub '$R001' 'primary_gate: M1' 'primary_gate: FUTURE'"
expect "invalid gate"                                1 "frontmatter primary_gate 'M1.5' must be M<n> or FUTURE" "sub '$R001' 'primary_gate: M1' 'primary_gate: M1.5'"
# (d) acceptance criteria
# AVE-REQ-093 AC-3: criteria stay verbatim unless a reasoned change is logged for the text it covers.
# AVE-REQ-093 AC-4: a criterion is ticked only while the requirement is done.
expect "ticked criterion on a ready requirement fails" 1 "AC-1 is ticked while status is 'ready' and the Status log has no done line" "sub '$R001' '- [ ] AC-1 A new project' '- [x] AC-1 A new project'"
expect "ticked criteria with status done pass"        0 "Acceptance criteria ticked: 4 of 404" "mut 'done()'"
expect "done requirement with a fenced placeholder fails" 1 "status done but a _TBD placeholder remains (fenced text included)" "mut 'done(); rep(req(1), \"## Test evidence\n\", \"## Test evidence\n\" + TICKS + \"text\n_TBD: pending.\n\" + TICKS + \"\n\")'"
expect "status done without a done log line fails"   1 "AC-1 is ticked while status is 'done' and the Status log has no done line" "sub '$R001' '- [ ] AC-1 A new project' '- [x] AC-1 A new project' && sub '$R001' 'status: ready' 'status: done'"
expect "ticked criterion after reopening fails"      1 "AC-1 is ticked while status is 'in-progress'; criteria are ticked only after" "sub '$R001' '- [ ] AC-1 A new project' '- [x] AC-1 A new project' && sub '$R001' 'status: ready' 'status: in-progress' && printf -- '- 2026-10-03 — done — verify-requirement PASS (lead)\n- 2026-10-04 — in-progress — reopened by the milestone review (lead)\n' >> $R001"
expect "ticked criterion on a superseded requirement that never was done fails" 1 "AC-1 is ticked while status is 'superseded' and the Status log has no done line" "mut 'supersede(); successor(); rep(req(1), \"- [ ] AC-\", \"- [x] AC-\", 9)'"
expect "superseded after done keeps its ticks"       0 "Acceptance criteria ticked: 4 of 404" "mut 'done(); supersede(); successor()'"
expect "capital-X tick fails"                        1 "Acceptance criteria holds a line that is no criterion ('- [X] AC-1" "sub '$R001' '- [ ] AC-1 A new project' '- [X] AC-1 A new project'"
expect "altered criterion without log line"          1 "AC-2 differs from the baseline text and the Status log has no line '$LINE AC-2 changed [$M_MOSTLY]: <reason>'" "sub '$R001' 'project metadata are unchanged.' 'project metadata are mostly unchanged.'"
expect "removed criterion without log line"          1 "AC-4 is missing and the Status log has no line '$LINE AC-4 removed: <reason>'" "sub '$R001' '$AC4' ''"
expect "renumbered criterion fails"                  1 "AC-2 is missing and the Status log has no line" "sub '$R001' '- [ ] AC-2 After saving' '- [ ] AC-5 After saving'"
expect "bold criterion markup fails"                 1 "AC-2 is missing and the Status log has no line" "sub '$R001' '- [ ] AC-2 After' '- [ ] **AC-2:** After'"
expect "altered criterion with recorded change"      0 "Recorded change: AVE-REQ-001 AC-2 differs from the baseline text — wording clarified" "sub '$R001' 'project metadata are unchanged.' 'project metadata are unchanged after a restart.' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_CLEAR]: wording clarified (lead)\n' >> $R001"
expect "removed criterion with recorded change"      0 "Recorded change: AVE-REQ-001 AC-4 is missing — split into AVE-REQ-102" "sub '$R001' '$AC4' '' && printf -- '- 2026-10-02 — ready — AC-4 removed: split into AVE-REQ-102 (lead)\n' >> $R001"
expect "recorded change needs a reason"              1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_X]: \n' >> $R001"
expect "recorded change needs the mark of the text"  1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — AC-2 changed: other (lead)\n' >> $R001"
expect "AC-12 log line does not cover AC-2"          1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — AC-12 changed [$M_X]: other (lead)\n' >> $R001"
expect "log line outside ## Status does not count"   1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && sub '$R001' '## Edge cases' '## Edge cases
- 2026-10-02 — ready — AC-2 changed [$M_X]: misplaced (lead)'"
expect "log line quoting the rule does not count"    1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — the checker requires \`AC-2 changed [$M_X]: <reason>\` lines (lead)\n' >> $R001"
expect "placeholder reason does not count"           1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_X]: <reason>\n' >> $R001"
expect "marker behind another requirement ID does not count" 1 "AC-2 differs from the baseline text and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — see AVE-REQ-002 AC-2 changed [$M_X]: tracked there (lead)\n' >> $R001"
# AVE-REQ-093 AC-3: a marker reason holds a letter or a digit, and the mark has sixteen digits.
expect "reason of punctuation alone does not count"  1 "AC-4 is missing and the Status log has no line '$LINE AC-4 removed: <reason>'" "sub '$R001' '$AC4' '' && printf -- '- 2026-10-02 — ready — AC-4 removed: — (...)\n' >> $R001"
expect "reason of one invisible character does not count" 1 "AC-4 is missing and the Status log has no line '$LINE AC-4 removed: <reason>'" "sub '$R001' '$AC4' '' && mut 'add_log(req(1), \"2026-10-02\", \"ready\", \"AC-4 removed: \" + chr(0x3164))'"
expect "mark of eight digits does not count"         1 "AC-2 differs from the baseline text and the Status log has no line '$LINE AC-2 changed [$M_CLEAR]: <reason>'" "sub '$R001' 'project metadata are unchanged.' 'project metadata are unchanged after a restart.' && printf -- '- 2026-10-02 — ready — AC-2 changed [${M_CLEAR:0:8}]: wording clarified (lead)\n' >> $R001"
expect "one line does not cover several removals"    1 "AC-3 is missing and the Status log has no line" "mut 'text = read(req(1)); put(one(req(1)), \"\n\".join(l for l in text.split(\"\n\") if not l.startswith((\"- [ ] AC-2 \", \"- [ ] AC-3 \")))); add_log(req(1), \"2026-10-02\", \"ready\", \"AC-2 removed: x; AC-3 removed: x\")'"
expect "second rewording under the first line fails" 1 "AC-2 differs from the baseline text and the Status log has no line '$LINE AC-2 changed [$M_MOSTLY]: <reason>'" "sub '$R001' 'project metadata are unchanged.' 'project metadata are mostly unchanged.' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_CLEAR]: wording clarified (lead)\n' >> $R001"
expect "criterion removed under an earlier changed line fails" 1 "AC-2 is missing and the Status log has no line '$LINE AC-2 removed: <reason>'" "sub '$R001' '$AC2
' '' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_CLEAR]: wording clarified (lead)\n' >> $R001"
# AVE-REQ-093 AC-3: an added criterion needs a logged reason, so no criterion line can qualify another unlogged.
expect "additional criterion without log line fails" 1 "AC-5 is not a baseline criterion and the Status log has no line '$LINE AC-5 added [$M_AC5]: <reason>'" "sub '$R001' '$AC4' '$AC4
- [ ] AC-5 Added behavior.'"
expect "additional criterion with recorded addition" 0 "Recorded addition: AVE-REQ-001 AC-5 — split from AC-4" "sub '$R001' '$AC4' '$AC4
- [ ] AC-5 Added behavior.' && printf -- '- 2026-10-02 — ready — AC-5 added [$M_AC5]: split from AC-4 (lead)\n' >> $R001"
expect "added criterion reworded under its first line fails" 1 "AC-5 is not a baseline criterion and the Status log has no line" "sub '$R001' '$AC4' '$AC4
- [ ] AC-5 AC-1 to AC-4 are informational.' && printf -- '- 2026-10-02 — ready — AC-5 added [$M_AC5]: split from AC-4 (lead)\n' >> $R001"
expect "duplicate criterion ID"                      1 "canonical form: acceptance criterion AC-2 is repeated" "sub '$R001' '$AC2' '$AC2
$AC2'"
# AVE-REQ-093 AC-3: the criteria section holds criterion lines only, so no note can qualify or waive one.
expect "continuation line under a criterion fails"   1 "Acceptance criteria holds a line that is no criterion ('Waived for version one" "sub '$R001' '$AC2' '$AC2
  Waived for version one: best-effort persistence is enough.'"
expect "fenced block in the criteria section fails"  1 "Acceptance criteria holds a line that is no criterion ('AC-1 to AC-4 are informational for M1.')" "mut 'rep(req(1), \"\n- [ ] AC-3\", \"\n\" + TICKS + \"\nAC-1 to AC-4 are informational for M1.\n\" + TICKS + \"\n- [ ] AC-3\")'"
expect "note in a derived criteria section fails"    1 "AVE-REQ-102-derived-stub.md: canonical form: § Acceptance criteria holds a line that is no criterion" "mut 'stub(STUB.replace(\"- [ ] AC-1 Something\", \"- [ ] AC-1 Something\n  Informational.\"))'"
# AVE-REQ-093 AC-3: the Description stays the baseline statement unless a reasoned change is logged.
expect "rewritten description without log line"      1 "Description differs from the baseline statement and the Status log has no line '$LINE Description changed [$(mark 'The application may keep projects.')]: <reason>'" "sub '$R001' '$STATEMENT' 'The application may keep projects.'"
expect "extended description without log line"       1 "Description differs from the baseline statement and the Status log has no line" "sub '$R001' '$STATEMENT' '$STATEMENT
Persistence is optional.'"
expect "fenced block added to the description fails" 1 "Description differs from the baseline statement and the Status log has no line" "mut 'rep(req(1), \"\n\n## Acceptance criteria\", \"\n\" + TICKS + \"\nPersistence is optional.\n\" + TICKS + \"\n\n## Acceptance criteria\")'"
expect "emptied description without log line"        1 "Description is missing and the Status log has no line '$LINE Description changed [$M_EMPTY]: <reason>'" "sub '$R001' '$STATEMENT' ''"
expect "rewritten description with recorded change"  0 "Recorded change: AVE-REQ-001 Description differs from the baseline statement — duplication moved to AVE-REQ-102" "sub '$R001' '$STATEMENT' '$SHORT' && printf -- '- 2026-10-02 — ready — Description changed [$M_SHORT]: duplication moved to AVE-REQ-102 (lead)\n' >> $R001"
expect "second description edit under the first line fails" 1 "Description differs from the baseline statement and the Status log has no line" "sub '$R001' '$STATEMENT' 'The application may keep projects.' && printf -- '- 2026-10-02 — ready — Description changed [$M_SHORT]: duplication moved to AVE-REQ-102 (lead)\n' >> $R001"
expect "description change needs a reason"           1 "Description differs from the baseline statement and the Status log has no line" "sub '$R001' '$STATEMENT' 'x.' && printf -- '- 2026-10-02 — ready — Description changed [$M_DX]: \n' >> $R001"
expect "AC log line does not cover the description"  1 "Description differs from the baseline statement and the Status log has no line" "sub '$R001' '$STATEMENT' 'x.' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_DX]: other (lead)\n' >> $R001"
expect "description log line outside ## Status"      1 "Description differs from the baseline statement and the Status log has no line" "sub '$R001' '$STATEMENT' 'x.' && sub '$R001' '## Edge cases' '## Edge cases
- 2026-10-02 — ready — Description changed [$M_DX]: misplaced (lead)'"
# (e) supersession
# AVE-REQ-093 AC-3: superseding a version-one requirement cannot demote it, rewrite it or drop its criteria unlogged.
expect "superseded by a missing requirement fails"   1 "superseded_by AVE-REQ-404 has no working requirement file" "mut 'supersede(by=\"AVE-REQ-404\")'"
expect "superseded by itself fails"                  1 "superseded_by chain AVE-REQ-001 names no replacement" "mut 'supersede(by=\"AVE-REQ-001\")'"
expect "superseded by a weaker requirement fails"    1 "a baseline must requirement cannot be superseded by a 'should' requirement (AVE-REQ-102)" "mut 'supersede(); successor(\"should\")'"
expect "superseded by a future-scope requirement fails" 1 "a version-one requirement cannot be superseded by AVE-REQ-102 (scope 'future', status 'ready')" "mut 'supersede(); successor(group=\"Deferred\", scope=\"future\", primary_gate=\"FUTURE\")'"
expect "superseded by a deferred requirement fails"  1 "a version-one requirement cannot be superseded by AVE-REQ-102 (scope 'v1', status 'deferred')" "mut 'supersede(); successor(status=\"deferred\")'"
expect "successor dropping a criterion unlogged fails" 1 "AC-4 of the baseline is absent from the successor AVE-REQ-102 and the Status log has no line '$LINE AC-4 dropped by AVE-REQ-102: <reason>'" "mut 'supersede(); successor(drop=(\"AC-4\",))'"
expect "successor carrying every criterion is reported" 0 "Supersession: AVE-REQ-001 → AVE-REQ-102 carries the baseline Description and criteria" "mut 'supersede(); successor()'"
expect "successor dropping a criterion with a logged change" 0 "Recorded change: AVE-REQ-001 AC-4 is absent from the successor AVE-REQ-102 — deletion moves to AVE-REQ-103" "mut 'supersede(); successor(drop=(\"AC-4\",)); add_log(req(1), \"2026-10-03\", \"superseded\", \"AC-4 dropped by AVE-REQ-102: deletion moves to AVE-REQ-103 (lead)\")'"
expect "successor drop under an older changed line fails" 1 "AC-2 of the baseline is absent from the successor AVE-REQ-102 and the Status log has no line" "sub '$R001' 'project metadata are unchanged.' 'project metadata are unchanged after a restart.' && printf -- '- 2026-10-02 — ready — AC-2 changed [$M_CLEAR]: wording clarified (lead)\n' >> $R001 && mut 'supersede(); successor(drop=(\"AC-2\",))'"
expect "successor of another type fails"             1 "the successor AVE-REQ-102 has type 'constraint'; the baseline type is 'functional'" "mut 'supersede(); successor(type=\"constraint\")'"
expect "derived successor of a human requirement fails" 1 "the successor AVE-REQ-102 of a human requirement keeps source human (it has 'derived')" "mut 'supersede(); successor(); rep(R + \"AVE-REQ-102-*.md\", \"source: human\", \"source: derived\")'"
expect "successor without the baseline scenarios fails" 1 "the successor AVE-REQ-102 drops scenarios AT-22 of the baseline" "mut 'supersede(); successor(scenarios=\"[AT-01]\")'"
expect "successor without the baseline origins fails" 1 "the successor AVE-REQ-102 drops origins U01, U24, D01 of the baseline" "mut 'supersede(); successor(origins=\"[]\")'"
expect "successor with another Description fails"    1 "the Description of the successor AVE-REQ-102 differs from the baseline statement and the Status log has no line '$LINE Description replaced by AVE-REQ-102 [$(mark 'The application may keep projects when that is cheap.')]: <reason>'" "mut 'supersede(); successor(); rep(R + \"AVE-REQ-102-*.md\", description(req(1)), \"The application may keep projects when that is cheap.\")'"
expect "successor with another Description and a logged change" 0 "Recorded change: AVE-REQ-001 Description differs in the successor AVE-REQ-102 — merged wording" "mut 'supersede(); successor(); rep(R + \"AVE-REQ-102-*.md\", description(req(1)), \"The application keeps projects.\"); add_log(req(1), \"2026-10-03\", \"superseded\", \"Description replaced by AVE-REQ-102 [\" + mark(\"The application keeps projects.\") + \"]: merged wording (lead)\")'"
expect "successor adding a criterion unlogged fails" 1 "AC-5 of the successor AVE-REQ-102 is no criterion of a requirement it replaces and the Status log has no line '$LINE AVE-REQ-102 AC-5 added [$(mark 'AC-1 to AC-4 are informational for version one.')]: <reason>'" "mut 'supersede(); successor(extra=(\"- [ ] AC-5 AC-1 to AC-4 are informational for version one.\",))'"
expect "successor adding a criterion with a logged addition" 0 "Recorded addition: AVE-REQ-102 AC-5 beside the criteria of AVE-REQ-001 — new export rule" "mut 'supersede(); successor(extra=(\"- [ ] AC-5 Exports name the project.\",)); add_log(req(1), \"2026-10-03\", \"superseded\", \"AVE-REQ-102 AC-5 added [\" + mark(\"Exports name the project.\") + \"]: new export rule (lead)\")'"
expect "successor under a deferred feature fails"    1 "a version-one requirement stands under the deferred AVE-FEAT-020" "mut 'supersede(); successor(parent=\"AVE-FEAT-020\", feature=\"AVE-FEAT-020\")'"
expect "successor absent from the roadmap fails"     1 "AVE-REQ-102 stands on no list" "mut 'supersede(); successor(group=None)'"
expect "superseded without a superseded log line fails" 1 "Status log has no 'superseded' line" "mut 'supersede(logged=False); successor()'"
expect "chain to a successor that drops a criterion fails" 1 "AC-4 of the baseline is absent from the successor AVE-REQ-103 and the Status log has no line" "mut 'supersede(); successor(); successor(rid=\"AVE-REQ-103\", drop=(\"AC-4\",)); supersede(R + \"AVE-REQ-102-*.md\", by=\"AVE-REQ-103\")'"
# AVE-REQ-093 AC-3: every requirement on the chain of a human requirement keeps source human, and a
# replacement under another milestone than the baseline gate is reported.
CHAIN="supersede(); successor(); successor(rid=\"AVE-REQ-103\"); supersede(R + \"AVE-REQ-102-*.md\", by=\"AVE-REQ-103\")"
expect "faithful chain through a superseded successor is reported" 0 "Supersession: AVE-REQ-001 → AVE-REQ-103 carries the baseline Description and criteria" "mut '$CHAIN'"
expect "derived requirement in the middle of a human chain fails" 1 "AVE-REQ-102-derived-stub.md: a requirement added after the import has source derived, or human when it replaces a human baseline requirement (expected 'human')" "mut '$CHAIN; rep(R + \"AVE-REQ-102-*.md\", \"source: human\", \"source: derived\")'"
expect "successor under another milestone is reported" 0 "Gate change: AVE-REQ-001 → AVE-REQ-102 primary_gate M7 (baseline M1)" "mut 'supersede(); successor(primary_gate=\"M7\", group=\"M7\")'"
NOT_WANT="Gate change" expect "successor under the baseline gate reports no gate change" 0 "Supersession: AVE-REQ-001 → AVE-REQ-102" "mut 'supersede(); successor()'"
# AVE-REQ-093 AC-3: the rule that keeps an imported requirement out of proposed holds for the end of its
# supersession chain; every other status of the imported file stays open to its replacement.
PROPOSED_ERROR="is 'proposed'; an imported requirement never returns to proposed, and the rule holds for the end of its supersession chain"
expect "successor in proposed fails"                 1 "AVE-REQ-001-persistent-projects-and-project-settings.md: the successor AVE-REQ-102 $PROPOSED_ERROR" "mut 'supersede(); successor(status=\"proposed\", key=\"Proposed during\")'"
expect "chain that ends in a proposed requirement fails" 1 "the successor AVE-REQ-103 $PROPOSED_ERROR" "mut 'supersede(); successor(); successor(rid=\"AVE-REQ-103\", status=\"proposed\", key=\"Proposed during\"); supersede(R + \"AVE-REQ-102-*.md\", by=\"AVE-REQ-103\")'"
expect "successor in blocked is reported"            0 "Supersession: AVE-REQ-001 → AVE-REQ-102 carries the baseline Description and criteria" "mut 'supersede(); successor(status=\"blocked\")'"
# AVE-REQ-093 AC-3: an exclusion (future scope) never enters version one through a supersession.
FUTURE102="successor(\"could\", source=req(67), group=\"Deferred\", scope=\"future\", primary_gate=\"FUTURE\", status=\"deferred\")"
expect "future requirement superseded into version one fails" 1 "a future-scope requirement cannot be superseded by AVE-REQ-102 (scope 'v1', status 'ready')" "mut 'supersede(req(67)); successor(source=req(67))'"
expect "future requirement superseded by a ready future one fails" 1 "a future-scope requirement cannot be superseded by AVE-REQ-102 (scope 'future', status 'ready')" "mut 'supersede(req(67)); successor(\"could\", source=req(67), group=\"Deferred\", scope=\"future\", primary_gate=\"FUTURE\")'"
expect "future requirement superseded by a deferred version-one requirement fails" 1 "a future-scope requirement cannot be superseded by AVE-REQ-102 (scope 'v1', status 'deferred')" "mut 'supersede(req(67)); successor(source=req(67), status=\"deferred\")'"
expect "future requirement superseded by a deferred future one is reported" 0 "Supersession: AVE-REQ-067 → AVE-REQ-102 carries the baseline Description and criteria" "mut 'supersede(req(67)); $FUTURE102'"
# AVE-REQ-093 AC-3: a baseline feature or epic leaves delivery only together with its baseline children.
expect "feature superseded while its requirements live fails" 1 "a baseline feature is superseded only when every baseline requirement under it is superseded (AVE-REQ-001 is 'ready')" "sub '$F001' 'status: ready' 'status: superseded'"
expect "epic superseded while its features live fails" 1 "a baseline epic is superseded only when every baseline feature under it is superseded (AVE-FEAT-001 is 'ready')" "sub '$R/AVE-EPIC-01-*.md' 'status: ready' 'status: superseded'"
# (f) dependencies and derived requirements
# AVE-REQ-093 AC-3: no version-one requirement waits on an exclusion, directly or through a replacement.
expect "derived requirement accepted"                0 "OK: baseline intact" "mut 'stub()'"
expect "derived requirement missing from its parent's list fails" 1 "§ Requirements must link AVE-REQ-102-derived-stub.md" "mut 'stub(feature=None)'"
expect "v1 requirement depends on a deferred one"    1 "version-one requirement depends on deferred AVE-REQ-067" "mut 'dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-001\", \"AVE-REQ-067\"])'"
expect "v1 requirement depends on a superseded exclusion fails" 1 "version-one requirement depends on the future-scope AVE-REQ-067" "mut 'supersede(req(67), by=\"AVE-REQ-103\"); successor(\"could\", source=req(67), rid=\"AVE-REQ-103\", group=\"Deferred\", scope=\"future\", primary_gate=\"FUTURE\", status=\"deferred\"); dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-067\"])'"
# AVE-REQ-093 AC-3: a dependency on a superseded version-one requirement counts through the end of its
# chain: a deferred replacement or a missing one fails.
FUTURE_STUB="stub(STUB.replace(\"scope: v1\", \"scope: future\").replace(\"primary_gate: M1\", \"primary_gate: FUTURE\").replace(\"status: proposed\", \"status: deferred\").replace(\"proposed \" + DASH, \"deferred \" + DASH), rid=\"AVE-REQ-104\", group=\"Deferred\", key=\"Requirements\")"
expect "v1 requirement depends on one replaced by a deferred requirement fails" 1 "AVE-REQ-102-derived-stub.md: version-one requirement depends on AVE-REQ-103, whose replacement is the deferred AVE-REQ-104" "mut 'dep_stub(\"AVE-REQ-103\", []); $FUTURE_STUB; supersede(R + \"AVE-REQ-103-*.md\", by=\"AVE-REQ-104\"); dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-103\"])'"
expect "v1 requirement depends on one whose replacement is missing fails" 1 "AVE-REQ-102-derived-stub.md: version-one requirement depends on AVE-REQ-103, whose replacement is missing" "mut 'dep_stub(\"AVE-REQ-103\", []); supersede(R + \"AVE-REQ-103-*.md\", by=\"AVE-REQ-404\"); dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-103\"])'"
expect "v1 requirement depends on one replaced by a version-one requirement passes" 0 "OK: baseline intact" "mut 'dep_stub(\"AVE-REQ-103\", []); dep_stub(\"AVE-REQ-104\", []); supersede(R + \"AVE-REQ-103-*.md\", by=\"AVE-REQ-104\"); dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-103\"])'"
expect "Dependencies section without the frontmatter dependency fails" 1 "§ Dependencies links no requirement while frontmatter dependencies names AVE-REQ-001" "mut 'stub(re.sub(r\"(?s)## Dependencies\n.*?\n\n\", \"## Dependencies\nNone.\n\n\", STUB, count=1))'"
expect "Dependencies section with an unlisted dependency fails" 1 "§ Dependencies links AVE-REQ-101 while frontmatter dependencies names none" "mut 'rep(req(1), \"## Dependencies\nNone.\n\", \"## Dependencies\n- [AVE-REQ-101](AVE-REQ-101-object-and-motion-tracking.md)\n\")'"
expect "self-dependency fails"                       1 "AVE-REQ-102 depends on itself" "mut 'dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-102\"])'"
expect "dependency cycle fails"                      1 "dependency cycle: AVE-REQ-102 → AVE-REQ-103 → AVE-REQ-102" "mut 'dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-103\"]); dep_stub(\"AVE-REQ-103\", [\"AVE-REQ-102\"])'"
expect "future requirement may depend on v1 work"    0 "OK: baseline intact" true
expect "dependency without a working file"           1 "dependency AVE-REQ-404 has no working requirement file" "mut 'dep_stub(\"AVE-REQ-102\", [\"AVE-REQ-404\"])'"
expect "derived requirement must be source derived"  1 "a requirement added after the import has source derived" "mut 'stub(STUB.replace(\"source: derived\", \"source: human\"))'"
expect "derived requirement needs scope"             1 "frontmatter scope is missing" "mut 'stub(STUB.replace(\"scope: v1\n\", \"\"))'"
expect "derived requirement needs a primary gate"    1 "frontmatter primary_gate is missing" "mut 'stub(STUB.replace(\"primary_gate: M1\n\", \"\"))'"
expect "derived requirement needs dependencies"      1 "frontmatter dependencies is missing" "mut 'stub(STUB.replace(\"dependencies: [AVE-REQ-001]\n\", \"\"))'"
expect "derived requirement with scope v2 fails"     1 "frontmatter scope 'v2' must be v1 or future" "mut 'stub(STUB.replace(\"scope: v1\", \"scope: v2\"))'"
expect "derived dependencies that are no flow list fail" 1 "AVE-REQ-102-derived-stub.md: frontmatter dependencies must be a flow list such as [AVE-REQ-012]" "mut 'stub(STUB.replace(\"dependencies: [AVE-REQ-001]\", \"dependencies: AVE-REQ-001\"))'"
expect "derived future-scope requirement that is not deferred fails" 1 "future-scope requirement must be deferred (status 'proposed')" "mut 'stub(STUB.replace(\"scope: v1\", \"scope: future\").replace(\"primary_gate: M1\", \"primary_gate: FUTURE\"), group=\"Deferred\", key=\"Requirements\")'"
expect "second file for a derived requirement fails" 1 "AVE-REQ-102 must have exactly one working file (found: AVE-REQ-102-derived-stub.md, AVE-REQ-102-second.md)" "mut 'stub()' && cp $STUB102 $R/AVE-REQ-102-second.md"
expect "derived deferred needs future scope"         1 "status deferred requires scope future" "mut 'stub(STUB.replace(\"status: proposed\", \"status: deferred\").replace(\"proposed \" + DASH, \"deferred \" + DASH))'"
expect "second file for a baseline feature"          1 "AVE-FEAT-015 must have exactly one working file" "cp $R/AVE-FEAT-015-*.md $R/AVE-FEAT-015-other.md"
expect "new ID inside the baseline range"            1 "AVE-REQ-000 lies inside the baseline ID range but has no baseline entry" "mut 'stub(rid=\"AVE-REQ-000\")'"
expect "new epic after the baseline range accepted"  0 "OK: baseline intact" "sed 's/AVE-EPIC-10/AVE-EPIC-11/g' $R/AVE-EPIC-10-*.md > $R/AVE-EPIC-11-new-epic.md"
# AVE-REQ-093 AC-1: one number of a kind names one working file, whatever its zero padding.
expect "second ID for one number fails"              1 "AVE-REQ number 102 names several working files (AVE-REQ-0102-derived-stub.md, AVE-REQ-102-derived-stub.md)" "mut 'stub(); stub(rid=\"AVE-REQ-0102\")'"
expect "baseline number under another padding fails" 1 "AVE-REQ number 1 names several working files (AVE-REQ-0001-derived-stub.md, AVE-REQ-001-persistent-projects-and-project-settings.md)" "mut 'stub(rid=\"AVE-REQ-0001\")'"
# AVE-REQ-093 AC-3, AVE-REQ-093 AC-4: no status move hides unfinished work: an imported requirement never
# returns to proposed, and an epic or feature is done, with its boxes ticked, only when every child that
# is neither superseded nor deferred is done.
expect "imported requirement set back to proposed fails" 1 "an imported requirement starts ready and never returns to proposed" "sub '$R001' 'status: ready' 'status: proposed' && mut 'add_log(req(1), \"2026-10-02\", \"proposed\", \"back to refinement (lead)\"); move(req(1), \"M1\", \"Proposed during\")'"
expect "feature done while its requirements are unfinished fails" 1 "AVE-FEAT-002-manual-timeline-and-history.md: status done while AVE-REQ-011 is 'ready' (7 unfinished of 7 children)" "mut 'parent_done(R + \"AVE-FEAT-002-*.md\")'"
expect "feature done with one unfinished requirement fails" 1 "AVE-FEAT-014-visual-indexing-and-understanding.md: status done while AVE-REQ-066 is 'ready' (1 unfinished of 3 children)" "mut 'done(req(65)); parent_done(R + \"AVE-FEAT-014-*.md\")'"
expect "epic done while a feature is unfinished fails" 1 "AVE-EPIC-02-editing-and-composition.md: status done while AVE-FEAT-002 is 'ready' (2 unfinished of 2 children)" "mut 'parent_done(R + \"AVE-EPIC-02-*.md\")'"
expect "feature box ticked before done fails"        1 "AVE-FEAT-002-manual-timeline-and-history.md: a box of § Feature acceptance is ticked while status is 'ready' and the Status log has no done line" "mut 'rep(R + \"AVE-FEAT-002-*.md\", \"- [ ] \", \"- [x] \")'"
expect "capital-X feature box under a plus bullet fails" 1 "a box of § Feature acceptance is ticked while status is 'ready'" "mut 'rep(R + \"AVE-FEAT-002-*.md\", \"- [ ] \", \"+ [X] \")'"
expect "star-bullet feature box before done fails"   1 "a box of § Feature acceptance is ticked while status is 'ready'" "mut 'rep(R + \"AVE-FEAT-002-*.md\", \"- [ ] \", \"* [x] \")'"
expect "indented ordered feature box before done fails" 1 "a box of § Feature acceptance is ticked while status is 'ready'" "mut 'rep(R + \"AVE-FEAT-002-*.md\", \"- [ ] \", \"  1. [x] \")'"
expect "feature box ticked without a done log line fails" 1 "AVE-FEAT-016-publication-metadata.md: a box of § Feature acceptance is ticked while status is 'done' and the Status log has no done line" "mut 'done(req(71)); parent_done(R + \"AVE-FEAT-016-*.md\", logged=False)'"
expect "epic box ticked before done fails"           1 "AVE-EPIC-02-editing-and-composition.md: a box of § Success criteria is ticked while status is 'ready'" "mut 'rep(R + \"AVE-EPIC-02-*.md\", \"## Success criteria\n\", \"## Success criteria\n- [x] Every feature shipped.\n\")'"
expect "feature box ticked after reopening fails"    1 "a box of § Feature acceptance is ticked while status is 'in-progress'; the boxes are ticked only while the file is done" "mut 'done(req(71)); parent_done(R + \"AVE-FEAT-016-*.md\"); rep(R + \"AVE-FEAT-016-*.md\", \"status: done\", \"status: in-progress\"); add_log(R + \"AVE-FEAT-016-*.md\", \"2026-10-04\", \"in-progress\", \"reopened (lead)\")'"
expect "done feature with every requirement done passes" 0 "OK: baseline intact" "mut 'done(req(71)); parent_done(R + \"AVE-FEAT-016-*.md\")'"
expect "done feature leaves its deferred requirement out" 0 "OK: baseline intact" "mut 'done(req(65)); done(req(66)); parent_done(R + \"AVE-FEAT-014-*.md\")'"
expect "done feature leaves a superseded requirement out" 0 "Supersession: AVE-REQ-071 → AVE-REQ-102 carries the baseline Description and criteria" "mut 'supersede(req(71)); successor(source=req(71), parent=\"AVE-FEAT-016\", feature=\"AVE-FEAT-016\", group=\"M6\", key=\"Requirements\", primary_gate=\"M6\"); done(R + \"AVE-REQ-102-*.md\"); parent_done(R + \"AVE-FEAT-016-*.md\")'"
expect "feature superseded after done keeps its ticks" 0 "Supersession: AVE-REQ-071 → AVE-REQ-102 carries the baseline Description and criteria" "mut 'done(req(71)); parent_done(R + \"AVE-FEAT-016-*.md\"); supersede(req(71)); successor(source=req(71), parent=\"AVE-FEAT-015\", feature=\"AVE-FEAT-015\", group=\"M6\", key=\"Requirements\", primary_gate=\"M6\"); supersede(R + \"AVE-FEAT-016-*.md\", by=\"AVE-FEAT-015\")'"
# (g) roadmap
# AVE-REQ-093 AC-3: no version-one requirement leaves the plan and no exclusion enters it through the roadmap.
expect "requirement dropped from the roadmap fails"  1 "docs/ROADMAP.md: AVE-REQ-001 stands on no list; a requirement that is not superseded stands on exactly one requirement list" "mut 'unschedule(req(1))'"
expect "requirement listed twice fails"              1 "AVE-REQ-001 stands on M1, M7" "mut 'schedule(req(1), \"M7\")'"
expect "roadmap milestone differs from primary_gate fails" 1 "AVE-REQ-001 stands under M7 while its primary_gate is M1" "mut 'move(req(1), \"M7\")'"
expect "moved gate without the roadmap fails"        1 "AVE-REQ-001 stands under M1 while its primary_gate is M2" "sub '$R001' 'primary_gate: M1' 'primary_gate: M2'"
expect "primary_gate naming no roadmap milestone fails" 1 "primary_gate M99 names no milestone of docs/ROADMAP.md" "sub '$R001' 'primary_gate: M1' 'primary_gate: M99'"
expect "exclusion on a version-one milestone list fails" 1 "the exclusion AVE-REQ-101 stands under M3; it belongs to the Deferred group" "mut 'move(req(101), \"M3\")'"
expect "version-one requirement in the Deferred group fails" 1 "the version-one requirement AVE-REQ-001 stands in the Deferred group" "mut 'move(req(1), \"Deferred\")'"
expect "done milestone with an unfinished requirement fails" 1 "milestone M1 has Status done while AVE-REQ-001 is 'ready'" "mut 'text = read(ROADMAP); head = text.index(\"### M1 \"); put(ROADMAP, text[:head] + text[head:].replace(\"- **Status:** planned\", \"- **Status:** done\", 1))'"
# AVE-REQ-093 AC-3: every milestone entry holds one Status line with one of three words and nothing else,
# so no spelling of a finished milestone escapes the rule above.
STATUS_ERROR="docs/ROADMAP.md: milestone M1: the Status line reads '- **Status:** planned', 'in-progress' or 'done' and nothing else"
expect "milestone Status done with a full stop fails" 1 "$STATUS_ERROR ('- **Status:** done.')" "mut 'milestone_status(\"M1\", \"- **Status:** done.\")'"
expect "capitalised milestone Status fails"          1 "$STATUS_ERROR ('- **Status:** Done')" "mut 'milestone_status(\"M1\", \"- **Status:** Done\")'"
expect "milestone Status with a note fails"          1 "$STATUS_ERROR ('- **Status:** done, reviewed 2026-10-06')" "mut 'milestone_status(\"M1\", \"- **Status:** done, reviewed 2026-10-06\")'"
expect "bold milestone Status word fails"            1 "$STATUS_ERROR ('- **Status:** **done**')" "mut 'milestone_status(\"M1\", \"- **Status:** **done**\")'"
expect "unknown milestone Status word fails"         1 "$STATUS_ERROR ('- **Status:** complete')" "mut 'milestone_status(\"M1\", \"- **Status:** complete\")'"
expect "indented milestone Status line fails"        1 "$STATUS_ERROR ('  - **Status:** done')" "mut 'milestone_status(\"M1\", \"  - **Status:** done\")'"
expect "milestone without a Status line fails"       1 "docs/ROADMAP.md: milestone M1 holds 0 Status lines" "mut 'milestone_status(\"M1\", None)'"
expect "milestone with two Status lines fails"       1 "docs/ROADMAP.md: milestone M1 holds 2 Status lines" "mut 'milestone_status(\"M1\", \"- **Status:** done\n- **Status:** planned\")'"
expect "milestone Status in-progress passes"         0 "OK: baseline intact" "mut 'milestone_status(\"M1\", \"- **Status:** in-progress\")'"
# AVE-REQ-093 AC-3: a line of a milestone entry whose letters open with "status" is a Status line, whatever
# its emphasis, bullet, container, letter case, character references or escapes (link targets, which a
# Markdown reader does not show, leave the letters first), so a second line that a reader takes for the
# Status line fails beside the true one. m1_end adds lines behind the last line of the M1 entry (line 14).
m1_end() { printf '%s' "mut 'entry_end(\"M1\", $1)'"; }
expect "underscore-bold second Status line fails"    1 "$STATUS_ERROR ('- __Status:__ done')" "$(m1_end '"- __Status:__ done"')"
expect "star-emphasis second Status line fails"      1 "$STATUS_ERROR ('- *Status:* done')" "$(m1_end '"- *Status:* done"')"
expect "plain second Status line fails"              1 "$STATUS_ERROR ('- Status: done')" "$(m1_end '"- Status: done"')"
expect "upper-case second Status line fails"         1 "$STATUS_ERROR ('- STATUS: done')" "$(m1_end '"- STATUS: done"')"
expect "second Status line in a quote fails"         1 "$STATUS_ERROR ('> - **Status:** done')" "$(m1_end '"> - **Status:** done"')"
expect "second Status line under a star bullet fails" 1 "$STATUS_ERROR ('* **Status:** done')" "$(m1_end '"* **Status:** done"')"
expect "second Status line under an ordered marker fails" 1 "$STATUS_ERROR ('1. **Status:** done')" "$(m1_end '"1. **Status:** done"')"
expect "Status text without a bullet fails"          1 "$STATUS_ERROR ('**Status:** done')" "$(m1_end '"**Status:** done"')"
expect "second Status line in a table row fails"     1 "$STATUS_ERROR ('| **Status:** | done |')" "$(m1_end '"\n| **Status:** | done |\n|:--|:--|"')"
expect "second Status line with a code span as its label fails" 1 "$STATUS_ERROR ('- \`Status:\` done')" "$(m1_end '"- " + BT + "Status:" + BT + " done"')"
expect "second Status line with a link as its label fails" 1 "$STATUS_ERROR ('- [Status](PROGRESS.md): done')" "$(m1_end '"- [Status](PROGRESS.md): done"')"
expect "second Status line behind a plain link fails" 1 "$STATUS_ERROR ('- [1](PROGRESS.md) **Status:** done')" "$(m1_end '"- [1](PROGRESS.md) **Status:** done"')"
expect "second Status line behind a ticked task box fails" 1 "$STATUS_ERROR ('- [x] **Status:** done')" "$(m1_end '"- [x] **Status:** done"')"
expect "second Status line behind a task box ticked with a capital X fails" 1 "$STATUS_ERROR ('- [X] **Status:** done')" "$(m1_end '"- [X] **Status:** done"')"
expect "second Status line with a character reference fails" 1 "$STATUS_ERROR ('- **St&#97;tus:** done')" "$(m1_end '"- **St&#97;tus:** done"')"
expect "second Status line behind escaped stars fails" 1 "$STATUS_ERROR ('- \\*\\*Status:\\*\\* done')" "$(m1_end '"- " + BS + "*" + BS + "*Status:" + BS + "*" + BS + "* done"')"
expect "Status text behind a hard line break fails"  1 "$STATUS_ERROR ('  **Status:** done')" "mut 'rep_entry(\"M1\", \"- **Review:** pending\n\", \"- **Review:** pending\" + BS + \"\n  **Status:** done\n\")'"
expect "Status word in a nested item fails"          1 "$STATUS_ERROR ('  - status: done')" "$(m1_end '"  - status: done"')"
expect "hidden Status line beside a second one in other emphasis fails" 1 "docs/ROADMAP.md: milestone M0: the Status line reads '- **Status:** planned', 'in-progress' or 'done' and nothing else ('- __Status:__ done')" "mut 'milestone_status(\"M0\", \"<?x\n- **Status:** planned\n?>\n- __Status:__ done\")'"
# AVE-REQ-093 AC-3: every line of the roadmap outside fenced blocks follows the reader's rules for raw HTML,
# backtick runs and footnote syntax, and every character stands on the reader's allow-list or is the
# horizontal ellipsis, written out or as a character reference; so nothing hides a line the gate reads.
CHAR_ERROR="is no character of the roadmap, written out or as a character reference"
expect "roadmap Status line inside a processing instruction fails" 1 "docs/ROADMAP.md: line 10: raw HTML outside a code span ('<?x')" "mut 'milestone_status(\"M1\", \"<?x\n- **Status:** planned\n?>\")'"
expect "roadmap link inside a processing instruction fails" 1 "docs/ROADMAP.md: line 11: raw HTML outside a code span ('<?x [AVE-REQ-001](requirements" "mut 'item = link(req(1)); list_line(\"M1\", item + \", \", \"<?x \" + item + \", ?>\")'"
expect "roadmap entry inside details fails"          1 "docs/ROADMAP.md: line 10: raw HTML outside a code span ('<details>')" "mut 'wrap_milestone(\"M1\", \"<details>\", \"</details>\")'"
expect "closing tag in the roadmap fails"            1 "docs/ROADMAP.md: line 14: raw HTML outside a code span ('</details> here.')" "$(m1_end '"Note </details> here."')"
expect "run of backticks unpaired on a roadmap line fails" 1 "docs/ROADMAP.md: line 14: a run of backticks stays unpaired; a code span opens and closes on one line ('A lone \` run.')" "$(m1_end '"A lone " + BT + " run."')"
expect "footnote definition in the roadmap fails"    1 "docs/ROADMAP.md: line 14: footnote syntax ([^ or ^[) outside a code span" "$(m1_end '"[^1]: a note"')"
expect "tags and footnote marks in code spans of the roadmap pass" 0 "OK: baseline intact" "$(m1_end '"- **Notes:** write " + BT + "<details>" + BT + " and " + BT + "[^1]" + BT + " in code spans; a < b."')"
expect "second Status line with a Cyrillic letter fails" 1 "docs/ROADMAP.md: line 14: U+0430 $CHAR_ERROR" "$(m1_end '"- **St" + chr(0x430) + "tus:** done"')"
expect "Cyrillic letter as a character reference in the roadmap fails" 1 "docs/ROADMAP.md: line 14: U+0430 $CHAR_ERROR" "$(m1_end '"- **St&#x430;tus:** done"')"
expect "no-break space as a character reference in the roadmap fails" 1 "docs/ROADMAP.md: line 14: U+00A0 $CHAR_ERROR" "$(m1_end '"- **Notes:**&nbsp;none"')"
expect "tab in the roadmap fails"                    1 "docs/ROADMAP.md: line 14: U+0009 $CHAR_ERROR" "$(m1_end '"Note" + chr(9) + "here."')"
expect "carriage returns in the roadmap fail"        1 "docs/ROADMAP.md: line 10: a carriage return $CHAR_ERROR" "mut 'milestone_status(\"M1\", \"- **Status:** done\" + CR + \"\n- **Status:** planned\")'"
expect "horizontal ellipsis and the signs of the allow-list pass in the roadmap" 0 "OK: baseline intact" "$(m1_end '"- **Notes:** M1, M2, " + chr(0x2026) + " and " + " ".join(chr(c) for c in (0xA7, 0xB1, 0x2013, 0x2014, 0x2192, 0x2265, 0x2282)) + "."')"
expect "character references to characters of the allow-list pass in the roadmap" 0 "OK: baseline intact" "$(m1_end '"- **Notes:** R&amp;D and 5 &#62; 4."')"
# AVE-REQ-093 AC-3: a link of the roadmap has one form, so the letters of a line that a reader does not see
# are its link targets only: an image, a reference link, a link without words and a target with other
# characters fail.
LINK_ERROR="a link of the roadmap reads '[<words>](<path>)'"
expect "second Status line behind a link without words fails" 1 "docs/ROADMAP.md: line 14: $LINK_ERROR" "$(m1_end '"- [](PROGRESS.md)**Status:** done"')"
expect "second Status line behind an image fails"    1 "docs/ROADMAP.md: line 14: $LINK_ERROR" "$(m1_end '"- ![a picture](x.png)**Status:** done"')"
expect "second Status line behind a reference link fails" 1 "docs/ROADMAP.md: line 14: $LINK_ERROR" "$(m1_end '"- [][s]**Status:** done"')"
expect "link whose target holds parentheses fails"   1 "docs/ROADMAP.md: line 14: $LINK_ERROR" "$(m1_end '"- **Notes:** see [x](a(b)c)."')"
expect "link with a title fails"                     1 "docs/ROADMAP.md: line 14: $LINK_ERROR" "$(m1_end '"- **Notes:** see [x](PROGRESS.md " + chr(34) + "Status" + chr(34) + ")."')"
expect "plain links in an entry pass"                0 "OK: baseline intact" "$(m1_end '"- **Notes:** see [the log](PROGRESS.md#log), [ADR-001](decisions/ADR-001-x_y.md) and [a site](https://example.com/a-b)."')"
# AVE-REQ-093 AC-3: the headings the gate reads are the headings a reader sees: a heading stands at column 0,
# no line of = or - underlines one, a heading that reads as an entry heading has the template form, and an
# entry runs to the next heading of level 1 to 3.
HEAD_ERROR="a heading stands at column 0, outside list items and quotes"
ENTRY_ERROR="reads as an entry heading; an entry heading reads '### M<n> — <name>' (the number without a leading zero) or '### Deferred — <text>'"
expect "roadmap heading in a quote fails"            1 "docs/ROADMAP.md: line 14: $HEAD_ERROR ('> ### M1 — Second entry')" "$(m1_end '"> ### M1 " + DASH + " Second entry\n> - **Status:** done"')"
expect "indented roadmap heading fails"              1 "docs/ROADMAP.md: line 14: $HEAD_ERROR (' ## Later')" "$(m1_end '" ## Later"')"
expect "roadmap heading on a continuation line fails" 1 "docs/ROADMAP.md: line 14: $HEAD_ERROR ('  ### M1 — Second entry')" "$(m1_end '"  ### M1 " + DASH + " Second entry"')"
expect "underline in the roadmap fails"              1 "docs/ROADMAP.md: line 16: a line of = or - underlines a heading or draws a rule ('---')" "$(m1_end '"\nM0 " + DASH + " Adopt the contract\n---"')"
expect "underline in a quote of the roadmap fails"   1 "docs/ROADMAP.md: line 15: a line of = or - underlines a heading or draws a rule ('> ===')" "$(m1_end '"> M0 " + DASH + " Adopt the contract\n> ==="')"
expect "milestone heading with a hyphen fails"       1 "docs/ROADMAP.md: line 15: '### M0 - Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n### M0 - Adopt the contract\n- **Status:** done"')"
expect "milestone heading with a leading zero fails" 1 "'### M00 — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n### M00 " + DASH + " Adopt the contract\n- **Status:** done"')"
expect "milestone heading of level 4 fails"          1 "'#### M0 — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n#### M0 " + DASH + " Adopt the contract"')"
expect "milestone heading of level 2 fails"          1 "'## M0 — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n## M0 " + DASH + " Adopt the contract\n- **Status:** done"')"
expect "bold milestone heading fails"                1 "'### **M0** — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n### **M0** " + DASH + " Adopt the contract\n- **Status:** done"')"
expect "milestone heading with its letter as a character reference fails" 1 "'### &#77;0 — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n### &#77;0 " + DASH + " Adopt the contract\n- **Status:** done"')"
expect "milestone heading behind a plain link fails" 1 "'### [1](PROGRESS.md) M0 — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n### [1](PROGRESS.md) M0 " + DASH + " Adopt the contract\n- **Status:** done"')"
expect "milestone heading behind a number fails"     1 "'### 1 M0 — Adopt the contract' $ENTRY_ERROR" "$(m1_end '"\n### 1 M0 " + DASH + " Adopt the contract\n- **Status:** done"')"
expect "milestone heading without a name fails"      1 "'### M9 —' $ENTRY_ERROR" "$(m1_end '"\n### M9 " + DASH')"
expect "Deferred heading with a colon fails"         1 "'### Deferred: out of version one' $ENTRY_ERROR" "$(m1_end '"\n### Deferred: out of version one\n- **Requirements:** " + link(req(1))')"
expect "second entry for one milestone fails"        1 "docs/ROADMAP.md: milestone M0 has two entries" "$(m1_end '"\n### M0 " + DASH + " Adopt the contract\n- **Status:** planned"')"
expect "second Deferred group fails"                 1 "docs/ROADMAP.md: the Deferred group has two entries" "$(m1_end '"\n### Deferred " + DASH + " moved out of version one\n- **Requirements:** " + link(req(1))')"
expect "second Status line under a sub-heading of the entry fails" 1 "docs/ROADMAP.md: milestone M1 holds 2 Status lines" "$(m1_end '"#### Notes\n- **Status:** done"')"
expect "hashes without a space end no entry"         1 "docs/ROADMAP.md: milestone M1 holds 2 Status lines" "$(m1_end '"#note\n- **Status:** done"')"
expect "Status line under a phase heading is free text" 0 "OK: baseline intact" "$(m1_end '"\n## Phase 9 " + DASH + " Later\n- **Status:** done " + DASH + " 2026-10-01"')"
# AVE-REQ-093 AC-3: a line the gate reads is a list item of one line: the next line with text opens a list
# item at column 0 or is a heading, so no continuation line adds a word to a Status line or a link to a list.
CONTINUES="a line the gate reads is a list item of one line, and the next line with text opens a list item at column 0 ('- ') or is a heading"
expect "continuation line under the Status line fails" 1 "docs/ROADMAP.md: line 11: '  done since the review' continues the line '- **Status:** planned'; $CONTINUES" "mut 'milestone_status(\"M1\", \"- **Status:** planned\n  done since the review\")'"
expect "text line under the Status line fails"       1 "docs/ROADMAP.md: line 11: 'and done since the review' continues the line '- **Status:** planned'; $CONTINUES" "mut 'milestone_status(\"M1\", \"- **Status:** planned\nand done since the review\")'"
expect "nested item under a requirement list fails"  1 "docs/ROADMAP.md: line 12: '  - [AVE-REQ-101](requirements/AVE-REQ-1' continues the line '- **Requirements (dependency order):**'; $CONTINUES" "mut 'rep_entry(\"M1\", \"\n- **Proposed during reviews:** none\", \"\n  - \" + link(req(101)) + \"\n- **Proposed during reviews:** none\")'"
expect "paragraph behind a blank line under a requirement list fails" 1 "docs/ROADMAP.md: line 13: '  and one more' continues the line '- **Requirements (dependency order):**'; $CONTINUES" "mut 'rep_entry(\"M1\", \"\n- **Proposed during reviews:** none\", \"\n\n  and one more\n- **Proposed during reviews:** none\")'"
expect "continuation line under a Proposed line fails" 1 "docs/ROADMAP.md: line 13: '  and more' continues the line '- **Proposed during reviews:**'; $CONTINUES" "mut 'rep_entry(\"M1\", \"- **Proposed during reviews:** none\n\", \"- **Proposed during reviews:** none\n  and more\n\")'"
expect "heading right behind the Deferred list passes" 0 "OK: baseline intact" "mut 'put(ROADMAP, read(ROADMAP) + \"## Re-planning log\n\")'"
# AVE-REQ-093 AC-3: the gate reads the lists with the template's labels, one of each per entry; a line of an
# entry whose letters open with "requirement" or "proposed" is such a line in the template's exact form: a
# requirement list of links only, a Proposed line of links and plain words. A fence line of the roadmap
# follows the rule of the requirement files. So a list the gate reads is a list readers see.
LABEL_ERROR="is no requirement-list label of the template"
LINKS_ERROR="holds requirement links '[AVE-REQ-NNN](requirements/AVE-REQ-NNN-<slug>.md)' separated by ', ' and nothing else"
WORDS_ERROR="holds requirement links and plain words (letters, digits, spaces and ( ) , . ; : -) and nothing else"
M1_LIST="docs/ROADMAP.md: milestone M1: the line '- **Requirements (dependency order):**'"
M1_PROPOSED="docs/ROADMAP.md: milestone M1: the line '- **Proposed during reviews:**'"
expect "underscore-bold requirement list fails"      1 "docs/ROADMAP.md: milestone M1: '- __Requirements (dependency order):__ [AVE-REQ-001](require' $LABEL_ERROR" "mut 'rep_entry(\"M1\", \"- **Requirements (dependency order):**\", \"- __Requirements (dependency order):__\")'"
expect "second list under a label in the singular fails" 1 "docs/ROADMAP.md: milestone M1: '- **Requirement list:**' $LABEL_ERROR" "$(m1_end '"- **Requirement list:** " + link(req(101))')"
expect "second list without emphasis fails"          1 "docs/ROADMAP.md: milestone M1: '- Requirements (dependency order): none' $LABEL_ERROR" "$(m1_end '"- Requirements (dependency order): none"')"
expect "requirement list in a quote fails"           1 "docs/ROADMAP.md: milestone M1: '> - **Requirements (dependency order):**' $LABEL_ERROR" "mut 'rep_entry(\"M1\", \"- **Requirements (dependency order):**\", \"> - **Requirements (dependency order):**\")'"
expect "second Proposed line with a character reference fails" 1 "docs/ROADMAP.md: milestone M1: '- **&#80;roposed during reviews:**' $LABEL_ERROR" "$(m1_end '"- **&#80;roposed during reviews:** none"')"
expect "struck requirement link fails"               1 "$M1_LIST $LINKS_ERROR" "mut 'item = link(req(1)); list_line(\"M1\", item, \"~~\" + item + \"~~\")'"
expect "requirement link in a code span fails"       1 "$M1_LIST $LINKS_ERROR" "mut 'item = link(req(1)); list_line(\"M1\", item, BT + item + BT)'"
expect "requirement link behind a backslash fails"   1 "$M1_LIST $LINKS_ERROR" "mut 'item = link(req(1)); list_line(\"M1\", item, BS + item)'"
expect "requirement link with a title fails"         1 "$M1_LIST $LINKS_ERROR" "mut 'item = link(req(1)); list_line(\"M1\", item, item[:-1] + \" \" + chr(34) + \"x\" + chr(34) + \")\")'"
expect "text behind a requirement list fails"        1 "$M1_LIST $LINKS_ERROR" "mut 'rep_entry(\"M1\", \"\n- **Proposed during reviews:** none\", \" (the last two move later)\n- **Proposed during reviews:** none\")'"
expect "spaces behind a requirement list fail"       1 "$M1_LIST $LINKS_ERROR" "mut 'rep_entry(\"M1\", \"\n- **Proposed during reviews:** none\", \"  \n- **Proposed during reviews:** none\")'"
expect "requirement list without a link fails"       1 "docs/ROADMAP.md: milestone M0: the line '- **Requirements (dependency order):**' $LINKS_ERROR" "mut 'text = read(ROADMAP); line = [l for l in text.split(\"\n\") if l.startswith(\"- **Requirements\")][0]; put(ROADMAP, text.replace(line, \"- **Requirements (dependency order):** none\", 1))'"
expect "text behind the Deferred list fails"         1 "docs/ROADMAP.md: the Deferred group: the line '- **Requirements:**' $LINKS_ERROR" "mut 'put(ROADMAP, read(ROADMAP).rstrip(\"\n\") + \" (deferred by the user)\n\")'"
expect "struck word on a Proposed line fails"        1 "$M1_PROPOSED $WORDS_ERROR" "mut 'rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Proposed during reviews:** ~~none~~\")'"
expect "code span on a Proposed line fails"          1 "$M1_PROPOSED $WORDS_ERROR" "mut 'rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Proposed during reviews:** \" + BT + \"none\" + BT)'"
expect "emphasis on a Proposed line fails"           1 "$M1_PROPOSED $WORDS_ERROR" "mut 'rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Proposed during reviews:** *none*\")'"
expect "Proposed line with links and plain words passes" 0 "OK: baseline intact" "mut 'stub(); rep_entry(\"M1\", \"none, \", \"\"); rep_entry(\"M1\", \"-derived-stub.md)\", \"-derived-stub.md) (found in review 2; a note), to refine with the M1 work: x-y.\")'"
expect "requirement list under another label fails"  1 "docs/ROADMAP.md: milestone M1: '- **Requirements removed from version one (not built):**' $LABEL_ERROR" "mut 'item = link(req(1)); unschedule(req(1)); rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Requirements removed from version one (not built):** \" + item + \"\n- **Proposed during reviews:** none\")'"
expect "requirement list with another bullet fails"  1 "docs/ROADMAP.md: milestone M1: '* **Requirements (dependency order):**' $LABEL_ERROR" "mut 'rep_entry(\"M1\", \"- **Requirements (dependency order):**\", \"* **Requirements (dependency order):**\")'"
expect "milestone list under the Deferred label fails" 1 "docs/ROADMAP.md: milestone M1: '- **Requirements:**' $LABEL_ERROR" "mut 'rep_entry(\"M1\", \"- **Requirements (dependency order):**\", \"- **Requirements:**\")'"
expect "Deferred list under the milestone label fails" 1 "docs/ROADMAP.md: the Deferred group: '- **Requirements (dependency order):**' $LABEL_ERROR" "mut 'rep_entry(\"Deferred\", \"- **Requirements:**\", \"- **Requirements (dependency order):**\")'"
expect "Proposed line in the Deferred group fails"   1 "docs/ROADMAP.md: the Deferred group: '- **Proposed during reviews:**' $LABEL_ERROR" "mut 'put(ROADMAP, read(ROADMAP) + \"- **Proposed during reviews:** none\n\")'"
expect "Proposed line under another label fails"     1 "docs/ROADMAP.md: milestone M1: '- **Proposed removals:**' $LABEL_ERROR" "mut 'rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Proposed removals:** none\")'"
expect "indented upper-case list under a plus bullet fails" 1 "docs/ROADMAP.md: milestone M1: '  + **REQUIREMENTS (dependency order):**' $LABEL_ERROR" "mut 'rep_entry(\"M1\", \"- **Requirements (dependency order):**\", \"  + **REQUIREMENTS (dependency order):**\")'"
expect "second requirement list in one entry fails"  1 "docs/ROADMAP.md: milestone M1 holds two '- **Requirements (dependency order):**' lines" "mut 'item = link(req(1)); unschedule(req(1)); rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Requirements (dependency order):** \" + item + \"\n- **Proposed during reviews:** none\")'"
expect "second Proposed line in one entry fails"     1 "docs/ROADMAP.md: milestone M1 holds two '- **Proposed during later reviews:**' lines" "mut 'rep_entry(\"M1\", \"- **Proposed during reviews:** none\", \"- **Proposed during reviews:** none\n- **Proposed during later reviews:** none\")'"
SAMPLE="; a list inside any other fence is a code sample to readers"
expect "tilde fence around a roadmap list fails"     1 "docs/ROADMAP.md: line 10: $FENCE_ERROR ('~~~')$SAMPLE" "mut 'wrap_milestone(\"M1\", \"~~~\", \"~~~\")'"
expect "four-backtick fence in the roadmap fails"    1 "docs/ROADMAP.md: line 10: $FENCE_ERROR ('\`\`\`\`')$SAMPLE" "mut 'wrap_milestone(\"M1\", TICKS + BT, TICKS + BT)'"
expect "indented fence in the roadmap fails"         1 "docs/ROADMAP.md: line 10: $FENCE_ERROR ('  \`\`\`')$SAMPLE" "mut 'wrap_milestone(\"M1\", \"  \" + TICKS, \"  \" + TICKS)'"
expect "fence in a quote around a roadmap list fails" 1 "docs/ROADMAP.md: line 10: $FENCE_ERROR ('> \`\`\`')$SAMPLE" "mut 'wrap_milestone(\"M1\", \"> \" + TICKS, \"> \" + TICKS)'"
expect "roadmap fence with a dot in its info word fails" 1 "docs/ROADMAP.md: line 10: $FENCE_ERROR ('\`\`\`a.b')$SAMPLE" "mut 'wrap_milestone(\"M1\", TICKS + \"a.b\", TICKS)'"
expect "roadmap list inside a fenced block is no list" 1 "docs/ROADMAP.md: AVE-REQ-001 stands on no list" "mut 'wrap_milestone(\"M1\", TICKS, TICKS)'"
expect "unclosed fence in the roadmap fails"         1 "docs/ROADMAP.md: a fenced block stays open at the end of the file" "mut 'put(ROADMAP, read(ROADMAP) + TICKS + \"text\n\")'"
NOT_WANT="docs/requirements/" expect "longer fence line inside a roadmap fence fails" 1 "$INNER_ERROR" "mut 'put(ROADMAP, read(ROADMAP) + \"## Notes\n\" + TICKS + \"\n\" + TICKS + BT + \"\n\" + TICKS + \"\n\")'"
NOT_WANT="docs/requirements/" expect "fence line in a quote inside a roadmap fence fails" 1 "$INNER_ERROR" "mut 'put(ROADMAP, read(ROADMAP) + \"## Notes\n\" + TICKS + \"\n> \" + TICKS + \"\n\" + TICKS + \"\n\")'"
expect "fenced block with an info word in the roadmap passes" 0 "OK: baseline intact" "mut 'put(ROADMAP, read(ROADMAP) + \"## Notes\n\" + TICKS + \"text\n### M1 \" + DASH + \" a sample\n- **Status:** done\n\" + TICKS + \"\n\")'"
expect "derived requirement absent from the roadmap fails" 1 "AVE-REQ-102 stands on no list" "mut 'stub(group=None)'"
expect "ready requirement on a Proposed line fails"  1 "AVE-REQ-102 is 'ready' and still stands on a 'Proposed during' line of M1" "mut 'stub(STUB.replace(\"status: proposed\", \"status: ready\").replace(\"proposed \" + DASH, \"ready \" + DASH))'"
expect "listed requirement without a working file fails" 1 "AVE-REQ-404 is listed and has no working requirement file" "mut 'rep(ROADMAP, \"- **Proposed during reviews:** none\", \"- **Proposed during reviews:** [AVE-REQ-404](requirements/AVE-REQ-404-gone.md)\")'"
expect "roadmap link text naming another file fails" 1 "the link text AVE-REQ-002 names another file than AVE-REQ-001" "mut 'rep(ROADMAP, \"[AVE-REQ-001](\", \"[AVE-REQ-002](\")'"
expect "roadmap list inside an HTML comment fails"   1 "docs/ROADMAP.md: an HTML comment (<!--) hides text from readers" "mut 'text = read(ROADMAP); head = text.index(\"### M1 \"); tail = text.index(\"### M2 \"); put(ROADMAP, text[:head] + \"<!--\n\" + text[head:tail] + \"-->\n\" + text[tail:])'"
expect "missing roadmap fails"                       1 "docs/ROADMAP.md: missing" "rm docs/ROADMAP.md"
# AVE-REQ-093 AC-1: IMPORT_MAPPING.md maps every ID and stays current.
expect "stale import mapping"                        1 "IMPORT_MAPPING.md: stale" "printf 'edit\n' >> $R/IMPORT_MAPPING.md"
expect "missing import mapping"                      1 "IMPORT_MAPPING.md: missing" "rm $R/IMPORT_MAPPING.md"
echo "### import_baseline.py"
expect_import "complete import: --check reports nothing" 0 "would create 0, kept 131 (0 differ from a fresh import)" true
expect_import "missing file: --check reports it"     1 "would create: docs/requirements/AVE-REQ-050-" "rm $R/AVE-REQ-050-*.md"
expect_import "lifecycle edits are kept"             0 "kept: docs/requirements/AVE-REQ-001-persistent-projects-and-project-settings.md (differs from a fresh import" "sub '$R001' '$LOG_LAST' '$LOG_LAST
- 2026-10-02 — in-progress — work starts (lead)' && sub '$R001' 'status: ready' 'status: in-progress'"
expect_import "stale mapping: --check reports it"    1 "would regenerate: docs/requirements/IMPORT_MAPPING.md" "printf 'edit\n' >> $R/IMPORT_MAPPING.md"
expect "import restores a deleted file"              0 "OK: baseline intact" "rm $R/AVE-REQ-050-*.md && python3 scripts/requirements/import_baseline.py >/dev/null"
expect "import never overwrites a working file"      0 "Recorded addition: AVE-REQ-001 AC-5 — kept" "sub '$R001' '$AC4' '$AC4
- [ ] AC-5 Added behavior.' && printf -- '- 2026-10-02 — ready — AC-5 added [$M_AC5]: kept (lead)\n' >> $R001 && python3 scripts/requirements/import_baseline.py >/dev/null"
expect "import leaves the baseline untouched"        0 "Baseline package: PASS" "python3 scripts/requirements/import_baseline.py >/dev/null && python3 scripts/requirements/import_baseline.py >/dev/null"
echo "BASELINE TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
