#!/usr/bin/env bash
# scripts/tests/test-checker.sh [--all-awks] — positive and negative fixtures for
# scripts/check-project-control.sh. Each case builds a fresh fixture (make-fixture.sh) in a temp
# dir, applies one mutation and checks the exit code and one expected output line.
# Default: the system awk. --all-awks: every installed awk among mawk, gawk, original-awk and
# busybox awk. Exit 0 when every case passes.
# Checks and mutations are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_AWKS=0
case "${1:-}" in
  "") ;;
  --all-awks) ALL_AWKS=1 ;;
  *) printf 'Usage: %s [--all-awks]\n' "$0" >&2; exit 2 ;;
esac
T="$(mktemp -d "${TMPDIR:-/tmp}/checker-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
SHIM=""
R=docs/requirements
sub() { python3 - "$1" "$2" "$3" <<'PY'
import sys
p, old, new = sys.argv[1:4]
s = open(p, newline='').read()
assert old in s, (p, old)
open(p, 'w', newline='').write(s.replace(old, new, 1))
PY
}
# expect <name> <exit> <grep-substring or ""> <mutation...>
expect() {
  local name="$1" want_exit="$2" want="$3" out code
  shift 3
  # FIXTURE_MODE="" builds the fixture without requirements; CHECK_PATH replaces PATH for the checker.
  # shellcheck disable=SC2086  # an empty FIXTURE_MODE must expand to no argument
  "$W/make-fixture.sh" "$T/case" ${FIXTURE_MODE-with-reqs} >/dev/null
  ( cd "$T/case" && eval "$*" ) || { echo "SETUP FAIL: $name"; FAIL=$((FAIL+1)); return; }
  out="$(cd "$T/case" && PATH="${CHECK_PATH:-${SHIM:+$SHIM:}$PATH}" ./scripts/check-project-control.sh 2>&1)"; code=$?
  if [ "$code" = "$want_exit" ] && { [ -z "$want" ] || printf '%s\n' "$out" | grep -qF -- "$want"; }; then
    PASS=$((PASS+1)); printf '  ok   %-44s %s\n' "$name" "$(printf '%s\n' "$out" | grep -F -m1 -- "${want:-OK:}")"
  else
    FAIL=$((FAIL+1)); printf '  FAIL %-44s exit=%s (want %s)\n%s\n' "$name" "$code" "$want_exit" "$out"
  fi
}
run_suite() {
expect "valid tree with requirements"      0 "OK:" true
expect "status log mismatch"               1 "newest Status-log line records 'verification' but frontmatter status is 'done'" "sub $R/AVE-REQ-001-done-requirement.md '- 2026-10-02 — done — stub' '- 2026-10-02 — verification — stub'"
expect "status log missing (FEAT)"         1 "ERROR: $R/AVE-FEAT-001-stub-feature.md: '## Status' has no log line" "sub $R/AVE-FEAT-001-stub-feature.md '- 2026-10-02 — in-progress — stub' 'no dated line'"
expect "status log CRLF mismatch"          1 "newest Status-log line records 'proposed' but frontmatter status is 'ready'" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: ready'"
expect "status log line in fence ignored"  1 "newest Status-log line records 'done' but frontmatter status is 'ready'" "sub $R/AVE-REQ-001-done-requirement.md 'status: done' 'status: ready' && printf '\\n\\140\\140\\140\\n- 2026-10-03 — ready — fenced\\n\\140\\140\\140\\n' >> $R/AVE-REQ-001-done-requirement.md && sub docs/TRACEABILITY.md 'done-requirement.md) | done |' 'done-requirement.md) | ready |'"
expect "bad filename (digits)"             1 "ERROR: $R/AVE-REQ-3-bad.md: filename must match" "cp $R/AVE-REQ-002-crlf-requirement.md $R/AVE-REQ-3-bad.md"
expect "bad filename (slug case)"          1 "ERROR: $R/AVE-REQ-003-Bad_Slug.md: filename must match" "cp $R/AVE-REQ-002-crlf-requirement.md $R/AVE-REQ-003-Bad_Slug.md"
expect "id mismatch"                       1 "frontmatter id 'AVE-REQ-009' must equal the filename ID AVE-REQ-001" "sub $R/AVE-REQ-001-done-requirement.md 'id: AVE-REQ-001' 'id: AVE-REQ-009'"
expect "invalid status"                    1 "invalid status 'started'" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: started'"
expect "invalid priority"                  1 "invalid priority 'high'" "sub $R/AVE-REQ-002-crlf-requirement.md 'priority: should' 'priority: high'"
expect "invalid type"                      1 "invalid type 'feature'" "sub $R/AVE-REQ-002-crlf-requirement.md 'type: non-functional' 'type: feature'"
expect "invalid source"                    1 "invalid source 'ai'" "sub $R/AVE-REQ-002-crlf-requirement.md 'source: derived' 'source: ai'"
expect "missing key (title)"               1 "frontmatter title is missing" "sub $R/AVE-REQ-002-crlf-requirement.md 'title: \"Quoted title\"' 'titel: x'"
expect "inline comment in value"           1 "invalid status 'proposed  # comment'" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: proposed  # comment'"
expect "missing parent"                    1 "parent AVE-FEAT-007 has no file in docs/requirements/" "sub $R/AVE-REQ-002-crlf-requirement.md 'parent: AVE-EPIC-01' 'parent: AVE-FEAT-007'"
expect "REQ parent of wrong kind"          1 "invalid parent 'AVE-REQ-001' (expected AVE-FEAT-NNN or AVE-EPIC-NN)" "sub $R/AVE-REQ-002-crlf-requirement.md 'parent: AVE-EPIC-01' 'parent: AVE-REQ-001'"
expect "FEAT parent must be EPIC"          1 "invalid parent 'AVE-FEAT-001' (expected AVE-EPIC-NN)" "sub $R/AVE-FEAT-001-stub-feature.md 'parent: AVE-EPIC-01' 'parent: AVE-FEAT-001'"
expect "EPIC goal outside goals section"   1 "goal GOAL-002 is not defined in docs/PRODUCT.md" "sub $R/AVE-EPIC-01-stub-epic.md 'goals: [GOAL-001]' 'goals: [GOAL-001, GOAL-002]'"
expect "EPIC empty goals"                  1 "frontmatter goals is empty" "sub $R/AVE-EPIC-01-stub-epic.md 'goals: [GOAL-001]' 'goals: []'"
expect "EPIC goals not a list"             1 "goals must be a flow list" "sub $R/AVE-EPIC-01-stub-epic.md 'goals: [GOAL-001]' 'goals: GOAL-001'"
expect "superseded without superseded_by"  1 "status superseded requires frontmatter superseded_by" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: superseded'"
expect "superseded_by missing file"        1 "superseded_by AVE-REQ-404 has no file" "sub $R/AVE-REQ-002-crlf-requirement.md 'source: derived' \"\$(printf 'source: derived\\r\\nsuperseded_by: AVE-REQ-404')\" && sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: superseded'"
expect "superseded with valid successor"   0 "OK:" "sub $R/AVE-REQ-002-crlf-requirement.md 'source: derived' \"\$(printf 'source: derived\\r\\nsuperseded_by: AVE-REQ-001')\" && sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: superseded' && printf -- '- 2026-10-03 — superseded — replaced by AVE-REQ-001\\r\\n' >> $R/AVE-REQ-002-crlf-requirement.md"
expect "H1 id mismatch"                    1 "$R/AVE-REQ-002-crlf-requirement.md: H1 must start with '# AVE-REQ-002'" "sub $R/AVE-REQ-002-crlf-requirement.md '# AVE-REQ-002 —' '# AVE-REQ-0021 —'"
expect "missing H1"                        1 "missing H1 '# AVE-FEAT-001" "sub $R/AVE-FEAT-001-stub-feature.md '# AVE-FEAT-001 — Stub feature' 'AVE-FEAT-001 — Stub feature'"
expect "missing REQ heading"               1 "missing heading '## Edge cases'" "sub $R/AVE-REQ-001-done-requirement.md '## Edge cases' '## Edge-cases'"
expect "heading only inside fence"         1 "missing heading '## Dependencies'" "sub $R/AVE-REQ-001-done-requirement.md '## Dependencies' '\`\`\`
## Dependencies
\`\`\`'"
expect "no AC line"                        1 "no acceptance criterion line" "sub $R/AVE-REQ-002-crlf-requirement.md '- [ ] AC-1 Something' 'AC-1 Something'"
expect "done REQ with unticked AC"         1 "status done but 1 acceptance criterion line(s) are unticked" "sub $R/AVE-REQ-001-done-requirement.md '- [X] AC-2' '- [ ] AC-2'"
expect "done REQ with _TBD"                1 "status done but a _TBD placeholder remains (line 27)" "sub $R/AVE-REQ-001-done-requirement.md '- \`src/x\` — stub' '_TBD: filled later._'"
expect "done REQ missing traceability row" 1 "ERROR: docs/TRACEABILITY.md: done requirement AVE-REQ-001 has no matrix row" "grep -v '^| \\[AVE-REQ-001\\]' docs/TRACEABILITY.md > t.tmp && mv t.tmp docs/TRACEABILITY.md"
expect "traceability status mismatch"      1 "AVE-REQ-001 status 'verification' differs from its frontmatter status 'done'" "sub docs/TRACEABILITY.md 'done-requirement.md) | done |' 'done-requirement.md) | verification |'"
expect "traceability row without file"     1 "no requirement file for AVE-REQ-077" "sub docs/TRACEABILITY.md '| \`src/x\`' '| x |
| AVE-REQ-077 | proposed | — | — | — | — |
| y | \`src/x\`'"
expect "traceability duplicate row"        1 "duplicate matrix row for AVE-REQ-001" "printf '| AVE-REQ-001 | done | a | b | c | — |\n' > row.tmp && python3 -c \"p='docs/TRACEABILITY.md';s=open(p).read();i=s.index('| [AVE-REQ-001]');open(p,'w').write(s[:i]+open('row.tmp').read()+s[i:])\" && rm row.tmp"
expect "traceability matrix header absent" 1 "requirement matrix header" "sub docs/TRACEABILITY.md '| Requirement | Status |' '| Req | Status |'"
expect "traceability row in fence ignored" 0 "OK:" true
expect "duplicate ID"                      1 "duplicate ID AVE-REQ-002 (also used by" "cp $R/AVE-REQ-002-crlf-requirement.md $R/AVE-REQ-002-dup-copy.md"
expect "empty requirement file"            1 "ERROR: $R/AVE-REQ-005-empty.md: file is empty" ": > $R/AVE-REQ-005-empty.md"
expect "requirement without frontmatter"   1 "missing frontmatter (the first line must be ---)" "printf '# AVE-REQ-006 — x\n' > $R/AVE-REQ-006-no-frontmatter.md"
expect "unterminated frontmatter"          1 "unterminated frontmatter" "printf -- '---\nid: AVE-REQ-007\n# AVE-REQ-007 — x\n' > $R/AVE-REQ-007-open.md"
expect "broken relative link"              1 "ERROR: docs/ARCHITECTURE.md: line 5: broken link to 'nope.md'" "printf '\nSee [x](nope.md#frag).\n' >> docs/ARCHITECTURE.md"
expect "broken link in .claude"            1 "ERROR: .claude/agents/tester.md: line 10: broken link to '../missing.md'" "printf '\n[m](../missing.md)\n' >> .claude/agents/tester.md"
expect "broken link-ref definition"        1 "broken link to 'docs/GONE.md'" "printf '\n[gone]: docs/GONE.md\n' >> README.md"
expect "broken image link"                 1 "broken link to 'img/x.png'" "printf '\n![i](img/x.png \"title\")\n' >> CLAUDE.md"
expect "link with spaces resolves"         0 "OK:" "mkdir -p 'docs/a b' && : > 'docs/a b/c d.md' && printf '\n[s](<a b/c d.md>) [t](a%%20b/c%%20d.md)\n' >> docs/ARCHITECTURE.md"
expect "link inside fence ignored"         0 "OK:" "printf '\n\`\`\`\n[x](fenced-missing.md)\n\`\`\`\n' >> docs/ARCHITECTURE.md"
expect "link inside code span ignored"     0 "OK:" "printf '\nUse \`\`[x](span-missing.md)\`\` and \`[y](z.md)\`.\n' >> docs/ARCHITECTURE.md"
expect "inline triple-backtick span is no fence" 1 "broken link to 'missing-after.md'" "printf '\n\`\`\` \`inline\` \`\`\` then [x](missing-after.md)\n' >> docs/ARCHITECTURE.md"
expect "worktrees excluded"                0 "OK:" "mkdir -p .claude/worktrees/w/.claude/agents && printf '[x](missing.md)\n' > .claude/worktrees/w/bad.md && printf 'no frontmatter\n' > .claude/worktrees/w/.claude/agents/x.md"
expect "missing PROGRESS heading"          1 "ERROR: docs/PROGRESS.md: missing heading '## Blockers'" "sub docs/PROGRESS.md '## Blockers' '## Blocker'"
expect "PROGRESS heading with CRLF"        0 "OK:" "sed 's/\$/\r/' docs/PROGRESS.md > p.tmp && mv p.tmp docs/PROGRESS.md"
expect "missing required file"             1 "ERROR: docs/ROADMAP.md: required file is missing" "rm docs/ROADMAP.md"
expect "non-executable hook"               1 "ERROR: .claude/hooks/stop-verify.sh: not executable" "chmod -x .claude/hooks/stop-verify.sh"
expect "non-executable script"             1 "ERROR: scripts/verify.sh: not executable" "chmod -x scripts/verify.sh"
expect "agent name mismatch"               1 "ERROR: .claude/agents/architect.md: frontmatter name 'architekt' must equal 'architect'" "sub .claude/agents/architect.md 'name: architect' 'name: architekt'"
expect "agent without description"         1 "frontmatter description is missing or empty" "sub .claude/agents/tester.md 'description: Stub tester agent.' 'description:'"
expect "agent without frontmatter"         1 "ERROR: .claude/agents/reviewer.md: missing frontmatter" "printf 'You are the reviewer.\n' > .claude/agents/reviewer.md"
expect "skill name mismatch"               1 "ERROR: .claude/skills/milestone-review/SKILL.md: frontmatter name 'milestone' must equal 'milestone-review'" "sub .claude/skills/milestone-review/SKILL.md 'name: milestone-review' 'name: milestone'"
expect "skill dir without SKILL.md"        1 "ERROR: .claude/skills/orphan: skill directory has no SKILL.md" "mkdir .claude/skills/orphan"
expect "invalid ADR status"                1 "invalid status line 'Approved — 2026-10-01'" "sub docs/decisions/ADR-001-specification-driven-development-workflow.md 'Accepted — 2026-10-01' 'Approved — 2026-10-01'"
expect "ADR status with hyphen"            1 "invalid status line 'Accepted - 2026-10-01'" "sub docs/decisions/ADR-001-specification-driven-development-workflow.md 'Accepted — 2026-10-01' 'Accepted - 2026-10-01'"
expect "superseded ADR missing target"     1 "superseded by ADR-007, which has no file in docs/decisions/" "sub docs/decisions/ADR-001-specification-driven-development-workflow.md 'Accepted — 2026-10-01' 'Superseded by ADR-007 — 2026-11-02'"
expect "superseded ADR valid target"       0 "OK:" "sed 's/ADR-001 —/ADR-002 —/' docs/decisions/ADR-001-specification-driven-development-workflow.md > docs/decisions/ADR-002-successor.md && sub docs/decisions/ADR-001-specification-driven-development-workflow.md 'Accepted — 2026-10-01' 'Superseded by ADR-002 — 2026-11-02'"
expect "ADR H1 mismatch"                   1 "H1 must start with '# ADR-002'" "cp docs/decisions/ADR-001-specification-driven-development-workflow.md docs/decisions/ADR-002-copy.md"
expect "ADR missing heading"               1 "missing heading '## Alternatives considered'" "sub docs/decisions/ADR-001-specification-driven-development-workflow.md '## Alternatives considered' '## Alternatives'"
expect "ADR bad filename"                  1 "ERROR: docs/decisions/adr-2-x.md: filename must match ADR-NNN-<slug>.md" "printf '# x\n' > docs/decisions/adr-2-x.md"
expect "ADR duplicate ID"                  1 "duplicate ID ADR-001" "sed 's/x/x/' docs/decisions/ADR-001-specification-driven-development-workflow.md > docs/decisions/ADR-001-again.md"
expect "invalid JSON settings"             1 "ERROR: .claude/settings.json: invalid JSON" "sub .claude/settings.json '\"Bash(git show *)\"' '\"Bash(git show *)\",'"
expect "many errors collected"             1 "FAILED: 5 error(s)" "chmod -x scripts/verify.sh && rm docs/ROADMAP.md && sub .claude/agents/architect.md 'name: architect' 'name: x' && printf '[a](b.md)\n' >> CLAUDE.md"
# scripts/lib/verify-state.sh: required, sourced (no executable bit needed)
expect "missing verify-state library"      1 "ERROR: scripts/lib/verify-state.sh: required file is missing" "rm scripts/lib/verify-state.sh"
expect "sourced library needs no +x"       0 "OK:" "chmod -x scripts/lib/verify-state.sh"
expect "executable library is harmless"    0 "OK:" "chmod +x scripts/lib/verify-state.sh"
# S5: every list item under ## Acceptance criteria is a criterion; malformed ones are reported
expect "done REQ with - [ ] **AC-3**"      1 "status done but 1 acceptance criterion line(s) are unticked" "sub $R/AVE-REQ-001-done-requirement.md '- [X] AC-2 Second behavior' '- [X] AC-2 Second behavior
- [ ] **AC-3** Third behavior'"
expect "done REQ with - [ ] **AC-3** (format)" 1 "AVE-REQ-001-done-requirement.md: line 20: acceptance criterion lines read '- [ ] AC-<n> <behavior>'" "sub $R/AVE-REQ-001-done-requirement.md '- [X] AC-2 Second behavior' '- [X] AC-2 Second behavior
- [ ] **AC-3** Third behavior'"
expect "unnumbered - [ ] Given ... AC"     1 "AVE-REQ-002-crlf-requirement.md: line 17: acceptance criterion lines read '- [ ] AC-<n> <behavior>'" "sub $R/AVE-REQ-002-crlf-requirement.md '- [ ] AC-1 Something' \"\$(printf -- '- [ ] AC-1 Something\\r\\n- [ ] Given a clip, when trimmed, then shorter')\""
expect "star bullet AC"                    1 "acceptance criterion lines read" "sub $R/AVE-REQ-002-crlf-requirement.md '- [ ] AC-1 Something' '* [ ] AC-1 Something'"
expect "AC with two spaces"                1 "acceptance criterion lines read" "sub $R/AVE-REQ-002-crlf-requirement.md '- [ ] AC-1 Something' '- [ ]  AC-1 Something'"
expect "numbered item under ACs"           1 "acceptance criterion lines read" "sub $R/AVE-REQ-002-crlf-requirement.md '- [ ] AC-1 Something' \"\$(printf -- '- [ ] AC-1 Something\\r\\n1. AC-2 Numbered')\""
expect "done REQ with ticked * [x] AC"     1 "acceptance criterion lines read" "sub $R/AVE-REQ-001-done-requirement.md '- [X] AC-2 Second behavior' '* [x] AC-2 Second behavior'"
expect "indented note under an AC is fine" 0 "OK:" "sub $R/AVE-REQ-001-done-requirement.md '- [X] AC-2 Second behavior' '- [X] AC-2 Second behavior
  - note: measured on the sample clip
  Continuation text.'"
# S7: HTML comments and fences nested in list items
expect "link inside HTML comment ignored"  0 "OK:" "printf '\n<!-- [x](commented-missing.md) -->\n' >> docs/ARCHITECTURE.md"
expect "link in multi-line comment ignored" 0 "OK:" "printf '\n<!--\n[x](commented-missing.md)\n![i](img/missing.png)\n-->\n' >> docs/ARCHITECTURE.md"
expect "link after a comment reported"     1 "broken link to 'after-comment-missing.md'" "printf '\n<!-- note --> [y](after-comment-missing.md)\n' >> docs/ARCHITECTURE.md"
expect "fence nested in list item ignored" 0 "OK:" "printf '\n- item\n\n    \140\140\140\n    [x](listfence-missing.md)\n    \140\140\140\n- next [ok](PRODUCT.md)\n' >> docs/ARCHITECTURE.md"
expect "link after md block with indented fence reported" 1 "broken link to 'after-block-missing.md'" "printf '\n\140\140\140markdown\n    \140\140\140\n[x](inside-block-missing.md)\n\140\140\140\n[y](after-block-missing.md)\n' >> docs/ARCHITECTURE.md"
expect "md block with indented fence: inner link ignored" 1 "FAILED: 1 error(s)" "printf '\n\140\140\140markdown\n    \140\140\140\n[x](inside-block-missing.md)\n\140\140\140\n[y](after-block-missing.md)\n' >> docs/ARCHITECTURE.md"
# S8: python3 validator (first choice)
expect "settings: two concatenated objects" 1 "ERROR: .claude/settings.json: invalid JSON" "cat .claude/settings.json .claude/settings.json > s.tmp && mv s.tmp .claude/settings.json"
expect "settings: empty file"              1 "ERROR: .claude/settings.json: invalid JSON" ": > .claude/settings.json"
expect "settings: NaN constant"            1 "invalid JSON: invalid JSON constant NaN" "sub .claude/settings.json '\"timeout\": 1800' '\"timeout\": NaN'"
# S9: EPIC and FEAT need '## Status' too; a REQ reports it once
expect "FEAT without ## Status"            1 "ERROR: $R/AVE-FEAT-001-stub-feature.md: missing heading '## Status'" "sub $R/AVE-FEAT-001-stub-feature.md '## Status
- 2026-10-02 — in-progress — stub
' ''"
expect "EPIC with ## Status renamed"       1 "ERROR: $R/AVE-EPIC-01-stub-epic.md: missing heading '## Status'" "sub $R/AVE-EPIC-01-stub-epic.md '## Status' '## State'"
expect "REQ without ## Status: one error"  1 "FAILED: 1 error(s)" "sub $R/AVE-REQ-001-done-requirement.md '## Status' '## Notes'"
# S10: matrix rows must follow the header directly
expect "matrix row after a blank line"     1 "ERROR: docs/TRACEABILITY.md: line 18: matrix row separated from the table" "sub docs/TRACEABILITY.md '| [AVE-REQ-001]' \"\$(printf '\n| [AVE-REQ-001]')\""
expect "matrix row after _No entries yet._" 1 "matrix row separated from the table" "sub docs/TRACEABILITY.md '| [AVE-REQ-001]' \"\$(printf '\n_No entries yet._\n| [AVE-REQ-001]')\""
expect "matrix row directly below separator" 0 "OK:" true
# AVE ID scheme: filename patterns, parent kinds, deferred status, matrix IDs, IMPORT_MAPPING.md
expect "retired REQ kind filename"         1 "ERROR: $R/REQ-003-old-kind.md: filename must match AVE-EPIC-NN-<slug>.md, AVE-FEAT-NNN-<slug>.md or AVE-REQ-NNN-<slug>.md" "cp $R/AVE-REQ-002-crlf-requirement.md $R/REQ-003-old-kind.md"
expect "retired EPIC kind filename"        1 "ERROR: $R/EPIC-002-old-epic.md: filename must match" "cp $R/AVE-EPIC-01-stub-epic.md $R/EPIC-002-old-epic.md"
expect "epic with one digit"               1 "ERROR: $R/AVE-EPIC-2-short.md: filename must match" "cp $R/AVE-EPIC-01-stub-epic.md $R/AVE-EPIC-2-short.md"
expect "feature with two digits"           1 "ERROR: $R/AVE-FEAT-02-short.md: filename must match" "cp $R/AVE-FEAT-001-stub-feature.md $R/AVE-FEAT-02-short.md"
expect "requirement with two digits"       1 "ERROR: $R/AVE-REQ-03-short.md: filename must match" "cp $R/AVE-REQ-002-crlf-requirement.md $R/AVE-REQ-03-short.md"
expect "unknown AVE kind"                  1 "ERROR: $R/AVE-TASK-001-x.md: filename must match" "cp $R/AVE-REQ-002-crlf-requirement.md $R/AVE-TASK-001-x.md"
expect "four-digit requirement accepted"   0 "OK:" "sed 's/AVE-REQ-002/AVE-REQ-1002/g' $R/AVE-REQ-002-crlf-requirement.md > $R/AVE-REQ-1002-wide.md"
expect "two-digit epic id mismatch"        1 "frontmatter id 'AVE-EPIC-1' must equal the filename ID AVE-EPIC-01" "sub $R/AVE-EPIC-01-stub-epic.md 'id: AVE-EPIC-01' 'id: AVE-EPIC-1'"
expect "REQ parent of retired kind"        1 "invalid parent 'FEAT-001' (expected AVE-FEAT-NNN or AVE-EPIC-NN)" "sub $R/AVE-REQ-001-done-requirement.md 'parent: AVE-FEAT-001' 'parent: FEAT-001'"
expect "REQ parent epic without file"      1 "parent AVE-EPIC-02 has no file in docs/requirements/" "sub $R/AVE-REQ-002-crlf-requirement.md 'parent: AVE-EPIC-01' 'parent: AVE-EPIC-02'"
expect "REQ parent with one-digit epic"    1 "invalid parent 'AVE-EPIC-1' (expected AVE-FEAT-NNN or AVE-EPIC-NN)" "sub $R/AVE-REQ-002-crlf-requirement.md 'parent: AVE-EPIC-01' 'parent: AVE-EPIC-1'"
expect "FEAT parent of REQ kind"           1 "invalid parent 'AVE-REQ-001' (expected AVE-EPIC-NN)" "sub $R/AVE-FEAT-001-stub-feature.md 'parent: AVE-EPIC-01' 'parent: AVE-REQ-001'"
expect "FEAT parent of retired kind"       1 "invalid parent 'EPIC-001' (expected AVE-EPIC-NN)" "sub $R/AVE-FEAT-001-stub-feature.md 'parent: AVE-EPIC-01' 'parent: EPIC-001'"
expect "deferred requirement accepted"     0 "OK:" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: deferred' && printf -- '- 2026-10-03 — deferred — future scope\\r\\n' >> $R/AVE-REQ-002-crlf-requirement.md"
expect "deferred status without log line"  1 "newest Status-log line records 'proposed' but frontmatter status is 'deferred'" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: deferred'"
expect "deferred epic and feature accepted" 0 "OK:" "sub $R/AVE-EPIC-01-stub-epic.md 'status: in-progress' 'status: deferred' && printf -- '- 2026-10-03 — deferred — future scope\\n' >> $R/AVE-EPIC-01-stub-epic.md && sub $R/AVE-FEAT-001-stub-feature.md 'status: in-progress' 'status: deferred' && printf -- '- 2026-10-03 — deferred — future scope\\n' >> $R/AVE-FEAT-001-stub-feature.md"
expect "misspelled deferred status"        1 "invalid status 'defered'" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: defered'"
expect "matrix row for a deferred requirement" 0 "OK:" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: deferred' && printf -- '- 2026-10-03 — deferred — future scope\\r\\n' >> $R/AVE-REQ-002-crlf-requirement.md && printf '| [AVE-REQ-002](requirements/AVE-REQ-002-crlf-requirement.md) | deferred | — | — | — | — |\\n' >> docs/TRACEABILITY.md"
expect "matrix row deferred status mismatch" 1 "AVE-REQ-002 status 'ready' differs from its frontmatter status 'deferred'" "sub $R/AVE-REQ-002-crlf-requirement.md 'status: proposed' 'status: deferred' && printf -- '- 2026-10-03 — deferred — future scope\\r\\n' >> $R/AVE-REQ-002-crlf-requirement.md && printf '| [AVE-REQ-002](requirements/AVE-REQ-002-crlf-requirement.md) | ready | — | — | — | — |\\n' >> docs/TRACEABILITY.md"
expect "matrix row with a retired REQ ID"  1 "matrix row has no AVE-REQ-NNN ID in its first cell" "printf '| REQ-002 | proposed | — | — | — | — |\\n' >> docs/TRACEABILITY.md"
expect "matrix row for unknown AVE ID"     1 "no requirement file for AVE-REQ-102" "printf '| [AVE-REQ-102](requirements/AVE-REQ-002-crlf-requirement.md) | proposed | — | — | — | — |\\n' >> docs/TRACEABILITY.md"
expect "separated AVE row after the table" 1 "matrix row separated from the table" "printf '\\nText.\\n| AVE-REQ-002 | proposed | — | — | — | — |\\n' >> docs/TRACEABILITY.md"
expect "IMPORT_MAPPING.md is no requirement file" 0 "OK:" "printf 'no frontmatter, AVE-REQ-001 mentioned\\n- [ ] AC-1 x\\n' >> $R/IMPORT_MAPPING.md"
expect "IMPORT_MAPPING.md links are checked" 1 "ERROR: $R/IMPORT_MAPPING.md: line 6: broken link to 'AVE-REQ-404-missing.md'" "printf '| AVE-REQ-404 | [x](AVE-REQ-404-missing.md) |\\n' >> $R/IMPORT_MAPPING.md"
expect "IMPORT_MAPPING.md is required"     1 "ERROR: docs/requirements/IMPORT_MAPPING.md: required file is missing" "rm $R/IMPORT_MAPPING.md"
expect "baseline check script is required" 1 "ERROR: scripts/check_baseline.py: required file is missing" "rm scripts/check_baseline.py"
expect "other non-requirement name still rejected" 1 "ERROR: $R/NOTES.md: filename must match" "printf '# Notes\\n' > $R/NOTES.md"
FIXTURE_MODE='' expect "baseline fixture without requirements" 0 "OK:" true
}
if [ "$ALL_AWKS" -eq 1 ]; then
  for impl in mawk gawk original-awk busybox; do
    if ! command -v "$impl" >/dev/null 2>&1; then echo "### awk = $impl: not installed, skipped"; continue; fi
    SHIM="$T/shim-$impl"; rm -rf "$SHIM"; mkdir -p "$SHIM"
    if [ "$impl" = busybox ]; then printf '#!/bin/sh\nexec busybox awk "$@"\n' > "$SHIM/awk"; chmod +x "$SHIM/awk"; else ln -s "$(command -v "$impl")" "$SHIM/awk"; fi
    echo "### awk = $impl"
    run_suite
  done
else
  echo "### awk = system ($(command -v awk))"
  run_suite
fi
# S8: the other JSON validators, each alone on PATH (run once; system awk)
make_path() {  # make_path <dir> [extra tools...]
  local d="$T/$1" t
  shift
  rm -rf "$d"; mkdir -p "$d"
  for t in awk bash cat dirname env find grep head sed sort tail tr "$@"; do ln -s "$(command -v "$t")" "$d/$t"; done
}
SHIM=""
echo "### JSON validators"
if command -v jq >/dev/null 2>&1; then
  make_path path-jq jq
  CHECK_PATH="$T/path-jq" expect "jq: valid settings"                0 "OK:" true
  CHECK_PATH="$T/path-jq" expect "jq: two concatenated objects"      1 "expected one JSON value, found 2" "cat .claude/settings.json .claude/settings.json > s.tmp && mv s.tmp .claude/settings.json"
  CHECK_PATH="$T/path-jq" expect "jq: empty file"                    1 "expected one JSON value, found 0" ": > .claude/settings.json"
  CHECK_PATH="$T/path-jq" expect "jq: syntax error"                  1 "ERROR: .claude/settings.json: invalid JSON" "sub .claude/settings.json '\"Bash(git show *)\"' '\"Bash(git show *)\",'"
else
  echo "  jq not installed: jq validator cases skipped"
fi
if command -v node >/dev/null 2>&1; then
  make_path path-node node
  CHECK_PATH="$T/path-node" expect "node: valid settings"            0 "OK:" true
  CHECK_PATH="$T/path-node" expect "node: two concatenated objects"  1 "ERROR: .claude/settings.json: invalid JSON: SyntaxError" "cat .claude/settings.json .claude/settings.json > s.tmp && mv s.tmp .claude/settings.json"
  CHECK_PATH="$T/path-node" expect "node: empty file"                1 "ERROR: .claude/settings.json: invalid JSON: SyntaxError" ": > .claude/settings.json"
else
  echo "  node not installed: node validator cases skipped"
fi
make_path path-none
CHECK_PATH="$T/path-none" expect "no validator: warning only"      0 "WARN: .claude/settings.json: JSON not validated (install python3, node or jq)" true
echo "CHECKER TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
