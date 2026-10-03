#!/usr/bin/env bash
# scripts/tests/test-check-baseline.sh — positive and negative cases for scripts/check_baseline.py
# and scripts/requirements/import_baseline.py. Each case starts from the baseline package, both
# scripts and a fresh import of the working requirement files (never the repository's working
# files, whose statuses and logs change as the project progresses), applies one mutation and checks
# the exit code and one expected output line. Needs python3. Exit 0 when every case passes.
# Checks and mutations are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$W/../.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/baseline-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
command -v python3 >/dev/null 2>&1 || { echo "test-check-baseline.sh: python3 is required" >&2; exit 2; }
PASS=0; FAIL=0
C="$T/case"
R=docs/requirements
B=ai-video-editor-requirements

# A fresh import, made once and copied into every case.
FRESH="$T/fresh"
mkdir -p "$FRESH/scripts/requirements" "$FRESH/$R"
cp "$REPO/scripts/check_baseline.py" "$FRESH/scripts/"
cp "$REPO/scripts/requirements/import_baseline.py" "$FRESH/scripts/requirements/"
cp -R "$REPO/$B" "$FRESH/$B"
(cd "$FRESH" && python3 -B scripts/requirements/import_baseline.py >/dev/null) ||
  { echo "test-check-baseline.sh: the fresh import failed" >&2; exit 2; }

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

# expect <name> <exit> <expected substring or ""> <mutation...> — runs check_baseline.py.
expect() { run_case check "$@"; }
# expect_import <name> <exit> <expected substring> <mutation...> — runs import_baseline.py --check.
expect_import() { run_case import "$@"; }

# NOT_WANT=<extended regex> before a call: the case also fails when the output matches it.
run_case() {
  local tool="$1" name="$2" want_exit="$3" want="$4" out code
  shift 4
  build
  ( cd "$C" && eval "$*" ) || { echo "  SETUP FAIL $name"; FAIL=$((FAIL + 1)); return; }
  if [ "$tool" = check ]; then
    out="$(cd "$C" && python3 scripts/check_baseline.py 2>&1)"; code=$?
  else
    out="$(cd "$C" && python3 scripts/requirements/import_baseline.py --check 2>&1)"; code=$?
  fi
  if [ "$code" = "$want_exit" ] && { [ -z "$want" ] || printf '%s\n' "$out" | grep -qF -- "$want"; } &&
    { [ -z "${NOT_WANT:-}" ] || ! printf '%s\n' "$out" | grep -Eq -- "$NOT_WANT"; }; then
    PASS=$((PASS + 1)); printf '  ok   %-50s %s\n' "$name" "$(printf '%s\n' "$out" | grep -F -m1 -- "${want:-OK:}" | cut -c1-150)"
  else
    FAIL=$((FAIL + 1)); printf '  FAIL %-50s exit=%s (want %s)\n%s\n' "$name" "$code" "$want_exit" "$(printf '%s\n' "$out" | tail -25)"
  fi
}

R001="$R/AVE-REQ-001-*.md"
R067="$R/AVE-REQ-067-*.md"
# successor <priority> <all|three> [source glob] — writes AVE-REQ-102 as the replacement of the
# source requirement (default AVE-REQ-001) with the given priority and the source's criteria (all,
# or all without AC-4).
successor() {
  local crit
  crit="$(grep -h '^- \[ \] AC-' ${3:-$R001})"
  [ "$2" = three ] && crit="$(printf '%s\n' "$crit" | grep -v '^- \[ \] AC-4 ')"
  printf '%s\n' "$DERIVED" | sed "s/^priority: should\$/priority: $1/" |
    awk -v crit="$crit" '/^- \[ \] AC-1 Something$/ { print crit; next } { print }' > "$R"/AVE-REQ-102-derived-stub.md
}
STATEMENT="The application shall create, name, reopen, duplicate, and persist editing projects, including their media references, timeline, output settings, and revisions."
AC2="- [ ] AC-2 After saving and restarting the application, timeline content, output settings, selected profiles, and project metadata are unchanged."
AC4="- [ ] AC-4 Project deletion clearly distinguishes deleting editing data from deleting original media; originals are not deleted by default."
LOG_LAST="- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)"
DERIVED='---
id: AVE-REQ-102
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

# AVE-REQ-102 — Derived stub

## Acceptance criteria
- [ ] AC-1 Something

## Status
- 2026-10-02 — proposed — found during implementation (lead)'

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
NOT_WANT="Baseline package: PASS|package validation failed" expect "edited package validator is never run" 1 "$B/tools/validate_package.py: baseline changed: SHA-256" "$NEUTERED"
expect "symbolic link added fails"                   1 "$B/spec/dangling: baseline changed: a symbolic link was added" "ln -s nowhere $B/spec/dangling"
expect "symlinked directory added fails"             1 "$B/spec/linkdir: baseline changed: a symbolic link was added" "mkdir -p outside && printf 'x\n' > outside/f && ln -s ../../outside $B/spec/linkdir"
# (b) one working file per baseline item, same identity
# AVE-REQ-093 AC-1: every baseline ID maps to exactly one working file.
# AVE-REQ-093 AC-3: priority, scope, type, source and exclusions cannot be demoted or rewritten.
expect "missing working requirement"                 1 "AVE-REQ-050 must have exactly one working file" "rm $R/AVE-REQ-050-*.md"
expect "missing working feature"                     1 "AVE-FEAT-020 must have exactly one working file" "rm $R/AVE-FEAT-020-*.md"
expect "missing working epic"                        1 "AVE-EPIC-10 must have exactly one working file" "rm $R/AVE-EPIC-10-*.md"
expect "duplicate working file"                      1 "AVE-REQ-001 must have exactly one working file" "cp $R001 $R/AVE-REQ-001-copy.md"
expect "changed title"                               1 "frontmatter title 'Persistent projects' must equal the baseline title" "sub '$R001' 'title: Persistent projects and project settings' 'title: Persistent projects'"
expect "changed H1"                                  1 "H1 must read '# AVE-REQ-001 — Persistent projects and project settings'" "sub '$R001' '# AVE-REQ-001 — Persistent projects and project settings' '# AVE-REQ-001 — Projects'"
expect "changed type"                                1 "frontmatter type 'non-functional' must equal the mapped baseline value 'functional'" "sub '$R001' 'type: functional' 'type: non-functional'"
expect "demoted priority"                            1 "frontmatter priority 'should' must equal the mapped baseline value 'must'" "sub '$R001' 'priority: must' 'priority: should'"
expect "changed source"                              1 "frontmatter source 'derived' must equal the origin-derived value 'human'" "sub '$R001' 'source: human' 'source: derived'"
expect "D-only origins map to derived"               1 "frontmatter source 'human' must equal the origin-derived value 'derived'" "sub '$R/AVE-REQ-085-*.md' 'source: derived' 'source: human'"
expect "changed parent"                              1 "frontmatter parent 'AVE-FEAT-002' must equal the baseline value 'AVE-FEAT-001'" "sub '$R001' 'parent: AVE-FEAT-001' 'parent: AVE-FEAT-002'"
expect "changed dependencies"                        1 "frontmatter dependencies '[AVE-REQ-002]' must equal the baseline value '[]'" "sub '$R001' 'dependencies: []' 'dependencies: [AVE-REQ-002]'"
expect "changed origins"                             1 "frontmatter origins '[U01, U24]' must equal the baseline value '[U01, U24, D01]'" "sub '$R001' 'origins: [U01, U24, D01]' 'origins: [U01, U24]'"
expect "changed scenarios"                           1 "frontmatter scenarios '[AT-01]' must equal the baseline value '[AT-01, AT-22]'" "sub '$R001' 'scenarios: [AT-01, AT-22]' 'scenarios: [AT-01]'"
expect "changed scope"                               1 "frontmatter scope 'future' must equal the baseline value 'v1'" "sub '$R001' 'scope: v1' 'scope: future'"
expect "changed baseline path"                       1 "frontmatter baseline" "sub '$R001' 'spec/requirements/AVE-REQ-001.md' 'spec/requirements/AVE-REQ-002.md'"
expect "future requirement made ready"               1 "future-scope requirement must stay deferred (status 'ready')" "sub '$R067' 'status: deferred' 'status: ready'"
expect "version-one requirement deferred"            1 "version-one requirement cannot be deferred (baseline scope v1)" "sub '$R001' 'status: ready' 'status: deferred'"
expect "deferred feature with a v1 child"            1 "status must be deferred exactly when every child is future scope" "sub '$R/AVE-FEAT-001-*.md' 'status: ready' 'status: deferred'"
expect "future epic made ready"                      1 "status must be deferred exactly when every child is future scope" "sub '$R/AVE-EPIC-10-*.md' 'status: deferred' 'status: ready'"
expect "feature no longer lists its requirement"     1 "§ Requirements must link AVE-REQ-002-collection-based-batch-ingestion.md" "sub '$R/AVE-FEAT-001-*.md' '](AVE-REQ-002-collection-based-batch-ingestion.md)' '](AVE-REQ-003-immutable-originals-and-stable-asset-identities.md)'"
expect "epic no longer lists its feature"            1 "§ Features must link AVE-FEAT-003-canvas-and-mixed-layouts.md" "sub '$R/AVE-EPIC-02-*.md' '](AVE-FEAT-003-canvas-and-mixed-layouts.md)' '](AVE-FEAT-002-manual-timeline-and-history.md)'"
expect "moved primary gate is reported"              0 "Gate change: AVE-REQ-001 primary_gate M2 (baseline M1)" "sub '$R001' 'primary_gate: M1' 'primary_gate: M2'"
expect "FUTURE gate on a v1 requirement"             1 "primary_gate FUTURE belongs to future scope only" "sub '$R001' 'primary_gate: M1' 'primary_gate: FUTURE'"
expect "invalid gate"                                1 "frontmatter primary_gate 'M1.5' must be M<n> or FUTURE" "sub '$R001' 'primary_gate: M1' 'primary_gate: M1.5'"
# (c) acceptance criteria
# AVE-REQ-093 AC-3: criteria stay verbatim unless a reasoned change is logged.
# AVE-REQ-093 AC-4: a criterion is ticked only once the requirement reached done.
expect "ticked criterion on a ready requirement fails" 1 "AC-1 is ticked while status is 'ready'" "sub '$R001' '- [ ] AC-1 A new project' '- [x] AC-1 A new project'"
expect "ticked criterion with status done passes"    0 "Acceptance criteria ticked: 1 of 404" "sub '$R001' '- [ ] AC-1 A new project' '- [x] AC-1 A new project' && sub '$R001' 'status: ready' 'status: done' && printf -- '- 2026-10-03 — done — verify-requirement PASS (lead)\n' >> $R001"
expect "ticked criterion after reopening passes"     0 "Acceptance criteria ticked: 1 of 404" "sub '$R001' '- [ ] AC-1 A new project' '- [x] AC-1 A new project' && sub '$R001' 'status: ready' 'status: in-progress' && printf -- '- 2026-10-03 — done — verify-requirement PASS (lead)\n- 2026-10-04 — in-progress — reopened by the milestone review (lead)\n' >> $R001"
expect "altered criterion without log line"          1 "AC-2 differs from the baseline text and the Status log has no 'AC-2 changed: <reason>' line" "sub '$R001' 'project metadata are unchanged.' 'project metadata are mostly unchanged.'"
expect "removed criterion without log line"          1 "AC-4 is missing and the Status log has no 'AC-4 changed: <reason>' line" "sub '$R001' '$AC4' ''"
expect "renumbered criterion fails"                  1 "AC-2 is missing" "sub '$R001' '- [ ] AC-2 After saving' '- [ ] AC-5 After saving'"
expect "bold criterion markup fails"                 1 "AC-2 is missing" "sub '$R001' '- [ ] AC-2 After' '- [ ] **AC-2:** After'"
expect "altered criterion with recorded change"      0 "Recorded change: AVE-REQ-001 AC-2 differs from the baseline text — wording clarified" "sub '$R001' 'project metadata are unchanged.' 'project metadata are unchanged after a restart.' && printf -- '- 2026-10-02 — ready — AC-2 changed: wording clarified (lead)\n' >> $R001"
expect "removed criterion with recorded change"      0 "Recorded change: AVE-REQ-001 AC-4 is missing — split into AVE-REQ-102" "sub '$R001' '$AC4' '' && printf -- '- 2026-10-02 — ready — AC-4 changed: split into AVE-REQ-102 (lead)\n' >> $R001"
expect "recorded change needs a reason"              1 "AC-2 differs from the baseline text" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — AC-2 changed:\n' >> $R001"
expect "AC-12 log line does not cover AC-2"          1 "AC-2 differs from the baseline text" "sub '$R001' 'project metadata are unchanged.' 'x.' && printf -- '- 2026-10-02 — ready — AC-12 changed: other (lead)\n' >> $R001"
expect "log line outside ## Status does not count"   1 "AC-2 differs from the baseline text" "sub '$R001' 'project metadata are unchanged.' 'x.' && sub '$R001' '## Edge cases' '## Edge cases
- 2026-10-02 — ready — AC-2 changed: misplaced (lead)'"
# AVE-REQ-093 AC-3: an added criterion needs a logged reason, so no criterion line can qualify another unlogged.
expect "additional criterion without log line fails" 1 "AC-5 is not a baseline criterion and the Status log has no 'AC-5 added: <reason>' line" "sub '$R001' '$AC4' '$AC4
- [ ] AC-5 Added behavior.'"
expect "additional criterion with recorded addition" 0 "Recorded addition: AVE-REQ-001 AC-5 — split from AC-4" "sub '$R001' '$AC4' '$AC4
- [ ] AC-5 Added behavior.' && printf -- '- 2026-10-02 — ready — AC-5 added: split from AC-4 (lead)\n' >> $R001"
# AVE-REQ-093 AC-3: superseding a version-one requirement cannot demote it or drop its criteria unlogged.
SUPERSEDE="sub '$R001' 'status: ready' 'status: superseded' && sub '$R001' 'spec/requirements/AVE-REQ-001.md' 'spec/requirements/AVE-REQ-001.md
superseded_by: AVE-REQ-102' && printf -- '- 2026-10-03 — superseded — replaced by AVE-REQ-102 (lead)\n' >> $R001"
expect "superseded by a missing requirement fails"   1 "superseded_by AVE-REQ-404 has no working requirement file" "$SUPERSEDE && sub '$R001' 'superseded_by: AVE-REQ-102' 'superseded_by: AVE-REQ-404'"
expect "superseded by a weaker requirement fails"    1 "a baseline must requirement cannot be superseded by a 'should' requirement (AVE-REQ-102)" "$SUPERSEDE && successor should all"
expect "superseded by a future-scope requirement fails" 1 "a version-one requirement cannot be superseded by AVE-REQ-102 (scope 'future'" "$SUPERSEDE && successor must all && sub $R/AVE-REQ-102-derived-stub.md 'scope: v1' 'scope: future' && sub $R/AVE-REQ-102-derived-stub.md 'primary_gate: M1' 'primary_gate: FUTURE' && sub $R/AVE-REQ-102-derived-stub.md 'status: proposed' 'status: deferred'"
expect "successor dropping a criterion unlogged fails" 1 "AC-4 of the baseline is absent from the successor AVE-REQ-102 and the Status log has no 'AC-4 changed: <reason>' line" "$SUPERSEDE && successor must three"
expect "successor carrying every criterion is reported" 0 "Supersession: AVE-REQ-001 → AVE-REQ-102 carries every baseline criterion" "$SUPERSEDE && successor must all"
expect "successor dropping a criterion with a logged change" 0 "Recorded change: AVE-REQ-001 AC-4 is absent from the successor AVE-REQ-102 — deletion moves to AVE-REQ-103" "$SUPERSEDE && successor must three && printf -- '- 2026-10-03 — superseded — AC-4 changed: deletion moves to AVE-REQ-103 (lead)\n' >> $R001"
# AVE-REQ-093 AC-3: an exclusion (future scope) never enters version one through a supersession.
SUPERSEDE67="sub '$R067' 'status: deferred' 'status: superseded' && sub '$R067' 'spec/requirements/AVE-REQ-067.md' 'spec/requirements/AVE-REQ-067.md
superseded_by: AVE-REQ-102' && printf -- '- 2026-10-03 — superseded — replaced by AVE-REQ-102 (lead)\n' >> $R067"
FUTURE102="sub $R/AVE-REQ-102-derived-stub.md 'scope: v1' 'scope: future' && sub $R/AVE-REQ-102-derived-stub.md 'primary_gate: M1' 'primary_gate: FUTURE' && sub $R/AVE-REQ-102-derived-stub.md 'status: proposed' 'status: deferred'"
expect "future requirement superseded into version one fails" 1 "a future-scope requirement cannot be superseded by AVE-REQ-102 (scope 'v1', status 'proposed')" "$SUPERSEDE67 && successor must all '$R067'"
expect "future requirement superseded by a ready future one fails" 1 "a future-scope requirement cannot be superseded by AVE-REQ-102 (scope 'future', status 'proposed')" "$SUPERSEDE67 && successor could all '$R067' && sub $R/AVE-REQ-102-derived-stub.md 'scope: v1' 'scope: future' && sub $R/AVE-REQ-102-derived-stub.md 'primary_gate: M1' 'primary_gate: FUTURE'"
expect "future requirement superseded by a deferred future one is reported" 0 "Supersession: AVE-REQ-067 → AVE-REQ-102 carries every baseline criterion" "$SUPERSEDE67 && successor could all '$R067' && $FUTURE102"
# AVE-REQ-093 AC-3: a baseline feature or epic leaves delivery only together with its baseline children.
expect "feature superseded while its requirements live fails" 1 "a baseline feature is superseded only when every baseline requirement under it is superseded (AVE-REQ-001 is 'ready')" "sub '$R/AVE-FEAT-001-*.md' 'status: ready' 'status: superseded'"
expect "epic superseded while its features live fails" 1 "a baseline epic is superseded only when every baseline feature under it is superseded (AVE-FEAT-001 is 'ready')" "sub '$R/AVE-EPIC-01-*.md' 'status: ready' 'status: superseded'"
expect "superseded without a superseded log line fails" 1 "Status log has no 'superseded' line" "sub '$R001' 'status: ready' 'status: superseded' && sub '$R001' 'spec/requirements/AVE-REQ-001.md' 'spec/requirements/AVE-REQ-001.md
superseded_by: AVE-REQ-102' && successor must all"
expect "duplicate criterion ID"                      1 "duplicate acceptance criterion AC-2" "sub '$R001' '$AC2' '$AC2
$AC2'"
# AVE-REQ-093 AC-3: the criteria section holds criterion lines only, so no note can qualify or waive one.
expect "continuation line under a criterion fails"   1 "Acceptance criteria holds a line that is no criterion ('Waived for version one" "sub '$R001' '$AC2' '$AC2
  Waived for version one: best-effort persistence is enough.'"
expect "fenced block in the criteria section fails"  1 "Acceptance criteria holds a line that is no criterion ('~~~')" "sub '$R001' '$AC2' '$AC2
~~~
AC-1 to AC-4 are informational for M1.
~~~'"
expect "sub-heading in the criteria section fails"   1 "Acceptance criteria holds a line that is no criterion ('### Informational" "sub '$R001' '## Acceptance criteria' '## Acceptance criteria
### Informational for version one'"
expect "note in a derived criteria section fails"    1 "AVE-REQ-102-derived-stub.md: § Acceptance criteria holds a line that is no criterion" "printf '%s\n' '$DERIVED' | sed 's/^- \[ \] AC-1 Something$/- [ ] AC-1 Something\n  Informational./' > $R/AVE-REQ-102-derived-stub.md"
# AVE-REQ-093 AC-3: the Description stays the baseline statement unless a reasoned change is logged.
expect "rewritten description without log line"      1 "Description differs from the baseline statement and the Status log has no 'Description changed: <reason>' line" "sub '$R001' '$STATEMENT' 'The application may keep projects.'"
expect "extended description without log line"       1 "Description differs from the baseline statement" "sub '$R001' '$STATEMENT' '$STATEMENT
Persistence is optional.'"
expect "fenced block added to the description fails" 1 "Description differs from the baseline statement" "sub '$R001' '$STATEMENT' '$STATEMENT
~~~
Persistence is optional.
~~~'"
expect "emptied description without log line"        1 "Description is missing and the Status log has no 'Description changed: <reason>' line" "sub '$R001' '$STATEMENT' ''"
expect "rewritten description with recorded change"  0 "Recorded change: AVE-REQ-001 Description differs from the baseline statement — duplication moved to AVE-REQ-102" "sub '$R001' '$STATEMENT' 'The application shall create, name, reopen and persist editing projects.' && printf -- '- 2026-10-02 — ready — Description changed: duplication moved to AVE-REQ-102 (lead)\n' >> $R001"
expect "description change needs a reason"           1 "Description differs from the baseline statement" "sub '$R001' '$STATEMENT' 'x.' && printf -- '- 2026-10-02 — ready — Description changed:\n' >> $R001"
expect "AC log line does not cover the description"  1 "Description differs from the baseline statement" "sub '$R001' '$STATEMENT' 'x.' && printf -- '- 2026-10-02 — ready — AC-2 changed: other (lead)\n' >> $R001"
expect "description log line outside ## Status"      1 "Description differs from the baseline statement" "sub '$R001' '$STATEMENT' 'x.' && sub '$R001' '## Edge cases' '## Edge cases
- 2026-10-02 — ready — Description changed: misplaced (lead)'"
# (d) deferred dependencies and derived requirements
expect "derived requirement accepted"                0 "OK: baseline intact" "printf '%s\n' '$DERIVED' > $R/AVE-REQ-102-derived-stub.md"
expect "v1 requirement depends on a deferred one"    1 "version-one requirement depends on deferred AVE-REQ-067" "printf '%s\n' '$DERIVED' | sed 's/dependencies: \[AVE-REQ-001\]/dependencies: [AVE-REQ-001, AVE-REQ-067]/' > $R/AVE-REQ-102-derived-stub.md"
expect "future requirement may depend on v1 work"    0 "OK: baseline intact" true
expect "dependency without a working file"           1 "dependency AVE-REQ-404 has no working requirement file" "printf '%s\n' '$DERIVED' | sed 's/dependencies: \[AVE-REQ-001\]/dependencies: [AVE-REQ-404]/' > $R/AVE-REQ-102-derived-stub.md"
expect "derived requirement must be source derived"  1 "a requirement added after the import has source derived" "printf '%s\n' '$DERIVED' | sed 's/source: derived/source: human/' > $R/AVE-REQ-102-derived-stub.md"
expect "derived requirement needs scope"             1 "frontmatter scope is missing" "printf '%s\n' '$DERIVED' | grep -v '^scope:' > $R/AVE-REQ-102-derived-stub.md"
expect "derived deferred needs future scope"         1 "status deferred requires scope future" "printf '%s\n' '$DERIVED' | sed 's/status: proposed/status: deferred/' > $R/AVE-REQ-102-derived-stub.md"
expect "second file for a baseline feature"          1 "AVE-FEAT-015 must have exactly one working file" "cp $R/AVE-FEAT-015-*.md $R/AVE-FEAT-015-other.md"
expect "new ID inside the baseline range"            1 "AVE-REQ-000 lies inside the baseline ID range but has no baseline entry" "printf '%s\n' '$DERIVED' | sed 's/AVE-REQ-102/AVE-REQ-000/g' > $R/AVE-REQ-000-derived-stub.md"
expect "new epic after the baseline range accepted"  0 "OK: baseline intact" "sed 's/AVE-EPIC-10/AVE-EPIC-11/g' $R/AVE-EPIC-10-*.md > $R/AVE-EPIC-11-new-epic.md"
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
- [ ] AC-5 Added behavior.' && printf -- '- 2026-10-02 — ready — AC-5 added: kept (lead)\n' >> $R001 && python3 scripts/requirements/import_baseline.py >/dev/null"
expect "import leaves the baseline untouched"        0 "Baseline package: PASS" "python3 scripts/requirements/import_baseline.py >/dev/null && python3 scripts/requirements/import_baseline.py >/dev/null"
echo "BASELINE TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
