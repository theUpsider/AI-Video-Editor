#!/usr/bin/env bash
# scripts/tests/test-checker.sh [--all-awks] — positive and negative fixtures for
# scripts/check-project-control.sh. Each case builds a fresh fixture (make-fixture.sh) in a temp
# dir, applies one mutation and checks the exit code and one expected output line.
# Default: the system awk. --all-awks: every installed awk among mawk, gawk, original-awk and
# busybox awk. Exit 0 when every case passes.
# Checks and mutations are strings run by eval, which reads the variables they name.
# shellcheck disable=SC2016,SC2034
set -uo pipefail
# quiet <grep arguments> — a grep that prints nothing and reads its whole input. `grep -q` stops at the
# first match; under pipefail the writer of the pipeline can then die of SIGPIPE, which fails a positive
# check and passes a negated one by chance.
quiet() { grep "$@" >/dev/null; }
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_AWKS=0
case "${1:-}" in
  "") ;;
  --all-awks) ALL_AWKS=1 ;;
  *) printf 'Usage: %s [--all-awks]\n' "$0" >&2; exit 2 ;;
esac
# AVE-REQ-097 AC-4: the JSON validator cases need jq and node. Without one of them the suite stops
# here, before any case and without a TOTAL line, so a host that lacks the tool reports no passing
# suite (the case that starts this file without the tool stands under "the suite's own guards").
for tool in jq node; do
  command -v "$tool" >/dev/null 2>&1 ||
    { printf 'test-checker.sh: %s is not installed: the %s validator cases cannot run\n' "$tool" "$tool" >&2; exit 2; }
done
T="$(mktemp -d "${TMPDIR:-/tmp}/checker-tests.XXXXXX")" || exit 2
trap 'rm -rf "$T"' EXIT
# The fixtures are Git repositories of their own: with a temp dir inside a work tree their Git commands
# would act on that tree (AVE-REQ-097: a suite leaves the working tree unchanged).
if git -C "$T" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "test-checker.sh: the temporary directory $T lies inside a Git work tree; set TMPDIR outside it" >&2
  exit 2
fi
export GIT_CEILING_DIRECTORIES="$T"
PASS=0; FAIL=0
# Set by this suite only: a value of the caller's environment never replaces the checker's PATH or
# the fixture mode.
SHIM=""
CHECK_PATH=""
unset FIXTURE_MODE
R=docs/requirements
sub() { python3 - "$1" "$2" "$3" <<'PY'
import sys
p, old, new = sys.argv[1:4]
s = open(p, newline='').read()
assert old in s, (p, old)
open(p, 'w', newline='').write(s.replace(old, new, 1))
PY
}
# jedit <python statement> — edits .claude/settings.json, parsed as d, and writes it back. A file it
# cannot edit (no JSON, a top-level value that is no object, a statement that fails) is reported by
# one line that names this helper, and the case then counts as a setup failure: the cases on such
# files write the file themselves and assert the checker's own error line.
jedit() { python3 - "$1" <<'PY'
import json, sys
p = '.claude/settings.json'
try:
    d = json.load(open(p, encoding='utf-8'))
    if not isinstance(d, dict):
        raise TypeError(f'the top-level value is a {type(d).__name__}; this helper edits a JSON object')
    exec(sys.argv[1])
except Exception as error:
    sys.exit(f'jedit: {p} not edited by {sys.argv[1]!r}: {type(error).__name__}: {error}')
open(p, 'w', encoding='utf-8').write(json.dumps(d, indent=2) + '\n')
PY
}
# fence_line <file> <line> — wraps the exact line <line> in a fenced code block.
fence_line() { python3 - "$1" "$2" <<'PY'
import sys
p, line = sys.argv[1:3]
s = open(p, newline='').read()
assert "\n" + line + "\n" in s, (p, line)
open(p, 'w', newline='').write(s.replace("\n" + line + "\n", "\n```\n" + line + "\n```\n", 1))
PY
}
# expect <name> <exit> <grep-substring or ""> <mutation...>
expect() {
  local name="$1" want_exit="$2" want="$3" out code
  shift 3
  # FIXTURE_MODE="" builds the fixture without requirements; CHECK_PATH replaces PATH for the checker.
  # shellcheck disable=SC2086  # an empty FIXTURE_MODE must expand to no argument
  "$W/make-fixture.sh" "$T/case" ${FIXTURE_MODE-with-reqs} >/dev/null ||
    { echo "SETUP FAIL (no fixture): $name"; FAIL=$((FAIL+1)); return; }
  ( cd "$T/case" && eval "$*" ) || { echo "SETUP FAIL: $name"; FAIL=$((FAIL+1)); return; }
  out="$(cd "$T/case" && PATH="${CHECK_PATH:-${SHIM:+$SHIM:}$PATH}" ./scripts/check-project-control.sh 2>&1)"; code=$?
  if [ "$code" = "$want_exit" ] && { [ -z "$want" ] || printf '%s\n' "$out" | quiet -F -- "$want"; }; then
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
expect "repeated frontmatter key"          1 "AVE-REQ-001-done-requirement.md: frontmatter key status is repeated" "sub $R/AVE-REQ-001-done-requirement.md 'status: done' \"\$(printf 'status: ready\\nstatus: done')\""
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
# AVE-REQ-098 AC-1: PROGRESS.md keeps every heading of its template. The ten headings are written
# out here, apart from the checker's own list, so a heading dropped from that list fails its case.
for h in "# Current project state" "## Current milestone" "## Current objective" "## In progress" \
  "## Recently completed" "## Next recommended work" "## Blockers" "## Known failures" \
  "## Important recent decisions" "## Verification status"; do
  expect "PROGRESS without '$h'" 1 "ERROR: docs/PROGRESS.md: missing heading '$h'" "grep -vx '$h' docs/PROGRESS.md > p.tmp && mv p.tmp docs/PROGRESS.md"
done
expect "PROGRESS heading with CRLF"        0 "OK:" "sed 's/\$/\r/' docs/PROGRESS.md > p.tmp && mv p.tmp docs/PROGRESS.md"
# A heading that stands only inside a fenced block or an HTML comment is absent for the reader of
# the rendered file, and for the rule.
expect "PROGRESS heading only inside a fence" 1 "ERROR: docs/PROGRESS.md: missing heading '## Blockers'" "fence_line docs/PROGRESS.md '## Blockers'"
expect "PROGRESS heading only inside an HTML comment" 1 "ERROR: docs/PROGRESS.md: missing heading '## Blockers'" "sub docs/PROGRESS.md '## Blockers' '<!--
## Blockers
-->'"
expect "PROGRESS heading beside an HTML comment counts" 0 "OK:" "sub docs/PROGRESS.md '## Blockers' '## Blockers <!-- two open -->'"
expect "missing required file"             1 "ERROR: docs/ROADMAP.md: required file is missing" "rm docs/ROADMAP.md"
expect "non-executable hook"               1 "ERROR: .claude/hooks/stop-verify.sh: not executable" "chmod -x .claude/hooks/stop-verify.sh"
expect "non-executable script"             1 "ERROR: scripts/verify.sh: not executable" "chmod -x scripts/verify.sh"
# AVE-REQ-097 AC-1: the release tier starts the suite runner and the suites by path, the fast tier the
# media stand-in; CI checks out the mode the Git index holds, whatever the file system of the host shows.
expect "non-executable suite runner"       1 "ERROR: scripts/tests/run.sh: not executable (run: chmod" "mkdir -p scripts/tests && printf '#!/bin/sh\n' > scripts/tests/run.sh"
expect "non-executable media stand-in"     1 "ERROR: scripts/lib/media-tier-only.sh: not executable (run: chmod" "chmod -x scripts/lib/media-tier-only.sh"
expect "entry point without the executable bit in the index" 1 "ERROR: scripts/verify.sh: not executable in the Git index (mode 100644; run: git update-index --chmod=+x 'scripts/verify.sh')" "git init -q && git add -A && git update-index --chmod=-x scripts/verify.sh"
expect "suite without the executable bit in the index" 1 "ERROR: scripts/tests/test-one.sh: not executable in the Git index (mode 100644" "mkdir -p scripts/tests && printf '#!/bin/sh\n' > scripts/tests/test-one.sh && chmod +x scripts/tests/test-one.sh && git init -q && git add -A && git update-index --chmod=-x scripts/tests/test-one.sh"
expect "entry points executable in the index pass" 0 "OK:" "git init -q && git add -A"
expect "sourced library without the executable bit passes" 0 "OK:" "chmod -x scripts/lib/verify-state.sh && git init -q && git add -A"
expect "agent name mismatch"               1 "ERROR: .claude/agents/architect.md: frontmatter name 'architekt' must equal 'architect'" "sub .claude/agents/architect.md 'name: architect' 'name: architekt'"
expect "agent without description"         1 "frontmatter description is missing or empty" "sub .claude/agents/tester.md 'description: Stub tester agent.' 'description:'"
expect "agent without frontmatter"         1 "ERROR: .claude/agents/reviewer.md: missing frontmatter" "printf 'You are the reviewer.\n' > .claude/agents/reviewer.md"
expect "skill name mismatch"               1 "ERROR: .claude/skills/milestone-review/SKILL.md: frontmatter name 'milestone' must equal 'milestone-review'" "sub .claude/skills/milestone-review/SKILL.md 'name: milestone-review' 'name: milestone'"
expect "skill dir without SKILL.md"        1 "ERROR: .claude/skills/orphan: skill directory has no SKILL.md" "mkdir .claude/skills/orphan"
# AVE-REQ-098 AC-4: agent and skill frontmatter holds the keys of a written list. A permission mode, a
# hook block or any other key fails, and so does a line the checker's reader takes no key from.
A_KEYS="(name, description, tools, model, color, skills)"
S_KEYS="(name, description, when_to_use, argument-hint, context, agent, background)"
HOOK_BLOCK='hooks:
  Stop:
    - hooks:
        - type: command
          command: scripts/loop-forever.sh'
expect "agent frontmatter with a permission mode" 1 "ERROR: .claude/agents/implementer.md: frontmatter key 'permissionMode' (line 6) is outside the keys of agent frontmatter $A_KEYS" "sub .claude/agents/implementer.md 'model: inherit' 'model: inherit
permissionMode: bypassPermissions'"
expect "agent frontmatter with a hook block" 1 "ERROR: .claude/agents/tester.md: frontmatter key 'hooks' (line 3) is outside the keys of agent frontmatter $A_KEYS" "sub .claude/agents/tester.md 'name: tester' 'name: tester
$HOOK_BLOCK'"
expect "skill frontmatter with a hook block" 1 "ERROR: .claude/skills/develop/SKILL.md: frontmatter key 'hooks' (line 3) is outside the keys of skill frontmatter $S_KEYS" "sub .claude/skills/develop/SKILL.md 'name: develop' 'name: develop
$HOOK_BLOCK'"
expect "skill frontmatter with a permission mode" 1 "ERROR: .claude/skills/resume-project/SKILL.md: frontmatter key 'permissionMode' (line 3) is outside the keys of skill frontmatter $S_KEYS" "sub .claude/skills/resume-project/SKILL.md 'name: resume-project' 'name: resume-project
permissionMode: dontAsk'"
expect "skill frontmatter with a key of the agent list" 1 "ERROR: .claude/skills/milestone-review/SKILL.md: frontmatter key 'tools' (line 3) is outside the keys of skill frontmatter $S_KEYS" "sub .claude/skills/milestone-review/SKILL.md 'name: milestone-review' 'name: milestone-review
tools: Read, Bash'"
expect "agent frontmatter with a key of the skill list" 1 "ERROR: .claude/agents/architect.md: frontmatter key 'context' (line 3) is outside the keys of agent frontmatter $A_KEYS" "sub .claude/agents/architect.md 'name: architect' 'name: architect
context: fork'"
expect "agent frontmatter with every listed key accepted" 0 "OK:" "sub .claude/agents/implementer.md 'model: inherit' 'model: inherit
color: blue
skills: [implement-requirement]'"
expect "skill frontmatter with every listed key accepted" 0 "OK:" "sub .claude/skills/verify-requirement/SKILL.md 'name: verify-requirement' 'name: verify-requirement
when_to_use: Before a requirement moves to done.
context: fork
agent: reviewer
background: false'"
NO_KEY_LINE="is no 'key: value' line at column 0, no indented continuation of the key above it and no blank line"
expect "frontmatter with a quoted key"     1 "ERROR: .claude/skills/develop/SKILL.md: frontmatter line 3 $NO_KEY_LINE" "sub .claude/skills/develop/SKILL.md 'name: develop' 'name: develop
\"hooks\": {}'"
expect "frontmatter key with a space before the colon" 1 "ERROR: .claude/agents/reviewer.md: frontmatter line 3 $NO_KEY_LINE" "sub .claude/agents/reviewer.md 'name: reviewer' 'name: reviewer
permissionMode : bypassPermissions'"
expect "frontmatter that opens with an indented line" 1 "ERROR: .claude/agents/researcher.md: frontmatter line 2 $NO_KEY_LINE" "sub .claude/agents/researcher.md '---
name: researcher' '---
  hooks: {}
name: researcher'"
expect "frontmatter with a folded value and a blank line accepted" 0 "OK:" "sub .claude/skills/develop/SKILL.md '  folded.' '  folded.

argument-hint: x'"
expect "README.md among the agent files"   1 "ERROR: .claude/agents/README.md: is read by Claude Code as an agent definition and by check 4 as none" "printf -- '---\nname: notes\ndescription: Notes.\npermissionMode: bypassPermissions\n---\n' > .claude/agents/README.md"
expect "frontmatter with an indented closing line" 1 "ERROR: .claude/agents/tester.md: frontmatter line 4 is an indented '---' line" "sub .claude/agents/tester.md 'description: Stub tester agent.' 'description: Stub tester agent.
  ---
permissionMode: bypassPermissions'"
# An agent file or a skill directory whose name opens with a dot is read like every other one.
expect "agent file whose name opens with a dot" 1 "ERROR: .claude/agents/.extra.md: frontmatter key 'permissionMode' (line 4) is outside the keys of agent frontmatter $A_KEYS" "printf -- '---\nname: .extra\ndescription: Hidden.\npermissionMode: bypassPermissions\n---\n' > .claude/agents/.extra.md"
expect "skill directory whose name opens with a dot" 1 "ERROR: .claude/skills/.extra/SKILL.md: frontmatter key 'hooks' (line 4) is outside the keys of skill frontmatter $S_KEYS" "mkdir .claude/skills/.extra && printf -- '---\nname: .extra\ndescription: Hidden.\nhooks: {}\n---\n' > .claude/skills/.extra/SKILL.md"
expect "skill directory whose name opens with a dot, without SKILL.md" 1 "ERROR: .claude/skills/.orphan: skill directory has no SKILL.md" "mkdir .claude/skills/.orphan"
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
# AVE-REQ-096 AC-1: a task brief holds every template heading once, in order, each section filled,
# and names its requirements.
BRIEF='# Brief — stub task\n\n## Requirements\nAVE-REQ-001 AC-1\n\n## Input revision\nabc1234\n\n## Allowed paths\nsrc/\n\n## Forbidden paths\ndocs/\n\n## Dependencies and constraints\nNone.\n\n## Test commands\n./scripts/verify.sh\n\n## Handback schema\nResult line.\n'
BRIEF_SWAPPED='# Brief — stub task\n\n## Requirements\nAVE-REQ-001 AC-1\n\n## Input revision\nabc1234\n\n## Forbidden paths\ndocs/\n\n## Allowed paths\nsrc/\n\n## Dependencies and constraints\nNone.\n\n## Test commands\n./scripts/verify.sh\n\n## Handback schema\nResult line.\n'
B=docs/briefs/2026-10-02-stub.md
expect "complete task brief accepted"      0 "OK:" "printf '$BRIEF' > $B"
for h in "## Requirements" "## Input revision" "## Allowed paths" "## Forbidden paths" \
  "## Dependencies and constraints" "## Test commands" "## Handback schema"; do
  expect "brief without '$h'" 1 "ERROR: $B: missing heading '$h'" "printf '$BRIEF' | grep -vx '$h' > $B"
  expect "brief with an empty '$h'" 1 "ERROR: $B: section '$h' is empty" "printf '$BRIEF' | sed '/^$h\$/{n;d;}' > $B"
done
expect "brief heading only in a fence"     1 "missing heading '## Handback schema'" "printf '$BRIEF' > $B && fence_line $B '## Handback schema'"
expect "brief headings out of order"       1 "ERROR: $B: heading '## Allowed paths' follows '## Forbidden paths'" "printf '$BRIEF_SWAPPED' > $B"
expect "brief with a repeated heading"     1 "ERROR: $B: heading '## Requirements' follows '## Handback schema'" "printf '${BRIEF}\n## Requirements\nAVE-REQ-002 AC-1\n' > $B"
expect "brief requirements without an ID"  1 "ERROR: $B: section '## Requirements' names no requirement ID (AVE-REQ-NNN)" "printf '$BRIEF' | sed 's/^AVE-REQ-001 AC-1\$/Fix the findings./' > $B"
expect "brief ID outside Requirements"     1 "section '## Requirements' names no requirement ID" "printf '$BRIEF' | sed -e 's/^AVE-REQ-001 AC-1\$/Fix the findings./' -e 's/^None\\.\$/After AVE-REQ-002./' > $B"
expect "brief with a heading repeated directly" 1 "ERROR: $B: heading '## Allowed paths' follows '## Allowed paths'" "printf '$BRIEF' > $B && sub $B 'src/' 'src/

## Allowed paths
lib/'"
expect "brief with an extra section after the template" 0 "OK:" "printf '${BRIEF}\n## Notes\nFree text.\n' > $B"
# An H1 or an H2 outside the template ends the section above it: text below such a heading fills no
# template section.
expect "brief section emptied by a foreign H2" 1 "ERROR: $B: section '## Allowed paths' is empty" "printf '$BRIEF' > $B && sub $B 'src/' '## Notes
src/'"
expect "brief section emptied by an H1"    1 "ERROR: $B: section '## Allowed paths' is empty" "printf '$BRIEF' > $B && sub $B 'src/' '# Notes
src/'"
# AVE-REQ-096 AC-1: HTML comments are removed before a section is judged: text, a requirement ID or a
# heading inside a comment is absent for the reader of the rendered brief, and for the rule.
expect "brief section holding only an HTML comment" 1 "ERROR: $B: section '## Allowed paths' is empty" "printf '$BRIEF' | sed 's|^src/\$|<!-- later -->|' > $B"
expect "brief requirement ID only in an HTML comment" 1 "ERROR: $B: section '## Requirements' is empty" "printf '$BRIEF' | sed 's/^AVE-REQ-001 AC-1\$/<!-- AVE-REQ-001 AC-1 -->/' > $B"
expect "brief requirement ID in a comment beside other text" 1 "ERROR: $B: section '## Requirements' names no requirement ID (AVE-REQ-NNN)" "printf '$BRIEF' | sed 's/^AVE-REQ-001 AC-1\$/<!-- AVE-REQ-001 AC-1 --> Fix the findings./' > $B"
expect "brief heading inside a multi-line HTML comment" 1 "ERROR: $B: missing heading '## Handback schema'" "printf '$BRIEF' > $B && sub $B '## Handback schema' '<!--
## Handback schema' && printf -- '-->\n' >> $B"
expect "brief section text inside a multi-line HTML comment" 1 "ERROR: $B: section '## Test commands' is empty" "printf '$BRIEF' > $B && sub $B './scripts/verify.sh' '<!--
./scripts/verify.sh
-->'"
expect "brief text beside an HTML comment counts" 0 "OK:" "printf '$BRIEF' | sed 's|^src/\$|<!-- the task owns --> src/|' > $B"
expect "brief comment marker inside a code span opens no comment" 0 "OK:" "printf '$BRIEF' | sed 's|^src/\$|\`src/\` (the text \`<!--\` in a code span is text)|' > $B"
expect "brief fence marker inside an HTML comment opens no fence" 0 "OK:" "printf '$BRIEF' > $B && sub $B 'src/' '<!--
\`\`\`
-->
src/'"
# AVE-REQ-096 AC-1: docs/briefs/ holds briefs, README.md, drafts/ and handbacks/ only, so no file
# there looks like a brief while no rule reads it.
expect "brief with another extension"      1 "ERROR: docs/briefs/2026-10-02-stub.markdown: is no task brief" "printf '$BRIEF' > $B && printf 'No sections.\n' > docs/briefs/2026-10-02-stub.markdown"
expect "brief in another subdirectory"     1 "ERROR: docs/briefs/extra: is no task brief" "mkdir docs/briefs/extra && printf 'No sections.\n' > docs/briefs/extra/2026-10-02-stub.md"
expect "hidden brief"                      1 "ERROR: docs/briefs/.2026-10-02-stub.md: is no task brief" "printf 'No sections.\n' > docs/briefs/.2026-10-02-stub.md"
expect "file in place of the drafts directory" 1 "ERROR: docs/briefs/drafts: is no task brief" "printf 'No sections.\n' > docs/briefs/drafts"
expect "directory named like a brief"      1 "ERROR: $B: is no task brief" "mkdir $B"
expect "draft without sections left alone" 0 "OK:" "mkdir docs/briefs/drafts && printf 'No sections yet.\n' > docs/briefs/drafts/2026-10-02-later.md"
expect "folder files of an operating system passed over" 0 "OK:" "printf '$BRIEF' > $B && mkdir -p docs/briefs/handbacks && : > docs/briefs/.DS_Store && : > docs/briefs/Thumbs.db && : > docs/briefs/handbacks/.DS_Store"
# AVE-REQ-096 AC-1, AVE-REQ-096 AC-2: the input revision names a commit: a delimited hash of 7 to 40
# hex digits, or the self-reference to the commit that adds the brief.
NO_COMMIT="ERROR: $B: section '## Input revision' names no commit"
expect "input revision without a commit"   1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/The commit that closes M0; the launching prompt names it./' > $B"
expect "input revision: branch name only"  1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/Branch \`ccr-af7078da-q8r8mf\` at the commit that adds this brief./' > $B"
expect "input revision: six hex digits"    1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/\`abc123\` on the working branch./' > $B"
expect "input revision: 41 hex digits"     1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/0123456789abcdef0123456789abcdef012345678/' > $B"
expect "input revision: commit only in an HTML comment" 1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/<!-- abc1234 --> The launching prompt names it./' > $B"
expect "input revision: abbreviated hash accepted" 0 "OK:" "printf '$BRIEF' | sed 's/^abc1234\$/\`6736401\` on \`ccr-af7078da-q8r8mf\`; isolated worktree./' > $B"
expect "input revision: full hash accepted" 0 "OK:" "printf '$BRIEF' | sed 's/^abc1234\$/a62e197b41ebd83adb000349347ca9fd0209b7eb, main working tree./' > $B"
expect "input revision: self-reference accepted" 0 "OK:" "printf '$BRIEF' | sed 's|^abc1234\$|Branch \`ccr-af7078da-q8r8mf\` at the commit that adds this brief (\`git log -1 --format=%h -- $B\`).|' > $B"
expect "input revision: self-reference to another brief" 1 "$NO_COMMIT" "printf '$BRIEF' | sed 's|^abc1234\$|Branch \`ccr-af7078da-q8r8mf\` (\`git log -1 --format=%h -- docs/briefs/2026-10-01-other.md\`).|' > $B"
# The self-reference ends at the brief's path: a path that goes on (a suffix, a longer name, a path
# below it) names another file. A hex token counts with a delimiter on both sides, and only under
# Input revision.
for suffix in .bak -old /x x; do
  expect "input revision: self-reference followed by $suffix" 1 "$NO_COMMIT" "printf '$BRIEF' | sed 's|^abc1234\$|Branch \`ccr-af7078da-q8r8mf\` (\`git log -1 --format=%h -- $B$suffix\`).|' > $B"
done
expect "input revision: branch name that ends in hex" 1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/Branch \`worktree-agent-ace5eb07e8aecbfbf\` only./' > $B"
expect "input revision: hash with a suffix" 1 "$NO_COMMIT" "printf '$BRIEF' | sed 's/^abc1234\$/\`abc1234_wip\` on the working branch./' > $B"
expect "input revision: commit named under Requirements only" 1 "$NO_COMMIT" "printf '$BRIEF' | sed -e 's/^AVE-REQ-001 AC-1\$/AVE-REQ-001 AC-1 at abc1234/' -e 's/^abc1234\$/The prompt names it./' > $B"
# AVE-REQ-096 AC-1: a handback persists in docs/briefs/handbacks/, named after the brief it answers.
HB=docs/briefs/handbacks
expect "handback and part handbacks of a brief accepted" 0 "OK:" "printf '$BRIEF' > $B && mkdir -p $HB && printf '# Handback\n' > $HB/2026-10-02-stub.md && printf '# Handback, part 2\n' > $HB/2026-10-02-stub.part-2.md && printf '# Handback, part 10\n' > $HB/2026-10-02-stub.part-10.md"
for part in 0 01; do
  expect "handback part $part"             1 "ERROR: $HB/2026-10-02-stub.part-$part.md: a handback is named <brief-slug>.md or <brief-slug>.part-<n>.md (n = 1, 2, …)" "printf '$BRIEF' > $B && mkdir -p $HB && printf '# Handback\n' > $HB/2026-10-02-stub.part-$part.md"
done
expect "handback without its brief"        1 "ERROR: $HB/2026-10-02-other.md: names no brief: docs/briefs/2026-10-02-other.md is missing" "printf '$BRIEF' > $B && mkdir -p $HB && printf '# Handback\n' > $HB/2026-10-02-other.md"
expect "handback part without a number"    1 "ERROR: $HB/2026-10-02-stub.part-x.md: a handback is named <brief-slug>.md or <brief-slug>.part-<n>.md" "printf '$BRIEF' > $B && mkdir -p $HB && printf '# Handback\n' > $HB/2026-10-02-stub.part-x.md"
expect "handback that is no Markdown file" 1 "ERROR: $HB/2026-10-02-stub.txt: a handback is named" "printf '$BRIEF' > $B && mkdir -p $HB && printf 'x\n' > $HB/2026-10-02-stub.txt"
expect "handback named after the README"   1 "ERROR: $HB/README.md: names no brief" "mkdir -p $HB && printf '# Handbacks\n' > $HB/README.md"
expect "hidden handback of a brief"        1 "ERROR: $HB/.2026-10-02-stub.part-1.md: a handback is named <brief-slug>.md or <brief-slug>.part-<n>.md; a hidden file is none" "printf '$BRIEF' > $B && mkdir -p $HB && printf '# Handback\n' > $HB/.2026-10-02-stub.part-1.md"
expect "hidden handback without a slug"    1 "ERROR: $HB/.part-1.md: a handback is named <brief-slug>.md or <brief-slug>.part-<n>.md; a hidden file is none" "printf '$BRIEF' > $B && mkdir -p $HB && printf '# Handback\n' > $HB/.part-1.md"
expect "directory named like a handback"   1 "ERROR: $HB/2026-10-02-stub.md: a handback is named <brief-slug>.md or <brief-slug>.part-<n>.md" "printf '$BRIEF' > $B && mkdir -p $HB/2026-10-02-stub.md"
# AVE-REQ-098 AC-3: PROGRESS.md never claims that work is running; in-flight work is recorded
# stop-safe ("launched <date>; verdict not recorded; … re-run <exact command>").
P=docs/PROGRESS.md
expect "PROGRESS: review running"          1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
- Review of AVE-REQ-001 running as a workflow.'"
for claim in 'Running: the release tier of the merge.' '- Implementer in flight on branch x.' \
  '- Implementer in-flight on branch x.' '- Media-tier run underway.' '- The review is still RUNNING.' \
  '- Media-tier run under way.' '- Media-tier run under-way since noon.' '- The review is still executing.' \
  '- Ongoing: the release tier of the merge.' '- The on-going review of AVE-REQ-001.' \
  '- The release tier runs now.' '- The review is still-executing.' '- The release tier runs-now.'; do
  expect "PROGRESS claim: $claim" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
$claim'"
done
for claim in 'Media-tier run under\tway.' 'Implementer in\tflight on branch x.' 'The review is still\texecuting.' \
  'The release tier runs\tnow.'; do
  expect "PROGRESS claim with a tab between the words: $claim" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' \"\$(printf '## In progress\\n- $claim')\""
done
# AVE-REQ-098 AC-3: a wording that a line wrap splits is the same claim. Check 7 joins consecutive
# lines, up to a blank line or a fenced block, before it matches, so a wrapped paragraph or list item
# is read whole; the error names the line on which the wording begins.
for claim in 'The review of AVE-REQ-001 is still|executing in the workflow.' 'Media-tier run under|way since noon.' \
  'Implementer in|flight on branch x.' 'The release tier runs|now.'; do
  expect "PROGRESS claim split by a line wrap: ${claim%%|*} / ${claim#*|}" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
- ${claim%%|*}
  ${claim#*|}'"
done
expect "PROGRESS claim split by a line wrap in a paragraph" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
The review of AVE-REQ-001 is still
executing in the workflow.'"
expect "PROGRESS claim split by a line wrap in a quote" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
> The review of AVE-REQ-001 is still
> executing in the workflow.'"
expect "PROGRESS claim split by a hard line break" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
- The review of AVE-REQ-001 is still\\
  executing in the workflow.'"
expect "PROGRESS claim split by a hyphen at the line end" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
- The review of AVE-REQ-001 is still-
  executing in the workflow.'"
expect "PROGRESS claim: the error names the line on which the wording begins" 1 "ERROR: $P: line 8: claims ongoing execution" "sub $P '## In progress' '## In progress
- Review of AVE-REQ-001: launched 2026-10-02.
  It is still
  executing in the workflow.'"
expect "PROGRESS claim: one error for each line on which a wording begins" 1 "FAILED: 2 error(s)" "sub $P '## In progress' '## In progress
- The review is underway and the media tier is running.
  The release tier is ongoing.'"
expect "PROGRESS: a code span that a line wrap splits is read as text" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
- The words \`still
  executing\` stand in a code span that a wrap splits.'"
expect "PROGRESS: negations in capitals accepted" 0 "OK:" "sub $P '## In progress' '## In progress
- Nothing is running; the old job is Not Running and NO LONGER RUNNING.'"
expect "PROGRESS: negations split by a line wrap accepted" 0 "OK:" "sub $P '## In progress' \"\$(printf '## In progress\\n- The old job is not  \\n  running, nothing is\\n  running and the first run is no longer\\n  running.')\""
expect "PROGRESS claim split over two list items" 1 "ERROR: $P: line 7: claims ongoing execution" "sub $P '## In progress' '## In progress
- The review of AVE-REQ-001 is still
- executing in the workflow.'"
expect "PROGRESS: a blank line and a fenced block end the joined text" 0 "OK:" "sub $P '## In progress' '## In progress
- The suite runs

  now and then.
> The plan is still
>
> executing the plan is next; the way leads under
\`\`\`text
code
\`\`\`
way.'"
expect "PROGRESS: stop-safe in-flight line accepted" 0 "OK:" "sub $P '## In progress' '## In progress
- Review of AVE-REQ-001: launched 2026-10-02; verdict not recorded. On resume without a recorded verdict nothing is running: re-run \`/verify-requirement AVE-REQ-001\`.'"
expect "PROGRESS: claim words in comments, fences and code spans accepted" 0 "OK:" "sub $P '## In progress' '## In progress
<!-- never write that a review is running -->
<!--
a run underway
-->
Use \`running\` only in code.
\`\`\`
review running
\`\`\`'"
expect "PROGRESS: rerunning and not running accepted" 0 "OK:" "sub $P '## In progress' '## In progress
- Next: rerunning the media tier; the old job is not running and no longer running.'"
expect "PROGRESS: words that only contain a claim word accepted" 0 "OK:" "sub $P '## In progress' '## In progress
- Next: the suite runs nowhere else; the outgoing brief names the way under the bridge; executing the plan is still open.'"
# AVE-REQ-098 AC-4: settings start no permission bypass; hook commands start no loop, sleep or
# background job, and no hook runs asynchronously.
expect "settings: bypassPermissions default mode" 1 "ERROR: .claude/settings.json: permissions.defaultMode 'bypassPermissions' runs tools without permission prompts" "jedit \"d['permissions']['defaultMode'] = 'bypassPermissions'\""
expect "settings: dontAsk default mode"    1 "permissions.defaultMode 'dontAsk' runs tools without permission prompts" "jedit \"d['permissions']['defaultMode'] = 'dontAsk'\""
expect "settings: auto default mode accepted" 0 "OK:" "jedit \"d['permissions']['defaultMode'] = 'auto'\""
expect "settings: skipped bypass-mode prompt" 1 "ERROR: .claude/settings.json: skipDangerousModePermissionPrompt skips a permission prompt" "jedit \"d['skipDangerousModePermissionPrompt'] = True\""
expect "settings: skipped auto-mode prompt" 1 "skipAutoPermissionPrompt skips a permission prompt" "jedit \"d['skipAutoPermissionPrompt'] = True\""
expect "settings: prompt kept (false)"     0 "OK:" "jedit \"d['skipDangerousModePermissionPrompt'] = False\""
for cmd in 'while true; do .claude/hooks/stop-verify.sh; done' 'sleep 600' 'nohup .claude/hooks/stop-verify.sh' \
  '.claude/hooks/stop-verify.sh; disown' 'setsid .claude/hooks/stop-verify.sh' '.claude/hooks/stop-verify.sh &' \
  'claude -p go --dangerously-skip-permissions'; do
  expect "hook command: $cmd" 1 "starts a loop, a sleep, a background job or a permission bypass" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] = '$cmd'\""
done
# The same forms and the further ones on a hook of another event, where no rule on the Stop command
# takes part: the exit status follows from the command's wording alone.
for cmd in 'while true; do scripts/note.sh; done' 'while :; do scripts/note.sh; done' \
  'while [ 1 ]; do scripts/note.sh; done' 'true; while [ -e x ]; do scripts/note.sh; done' \
  'until false; do scripts/note.sh; done' '(until scripts/note.sh; do :; done)' \
  'for ((;;)); do scripts/note.sh; done' 'for (( i = 0; ; i++ )); do scripts/note.sh; done' \
  'for((;;)); do scripts/note.sh; done' 'scripts/sleep-check.sh' \
  'sleep 600' 'scripts/note.sh &' 'claude -p go --dangerously-skip-permissions' \
  'claude -p go --allow-dangerously-skip-permissions' \
  'claude -p go --permission-mode bypassPermissions' 'claude -p go --permission-mode=acceptEdits' \
  'scripts/note.sh --mode=until' 'cat scripts/a+while+b.sh' 'scripts/note.sh --run:while'; do
  expect "tool hook command: $cmd" 1 "ERROR: .claude/settings.json: hooks.PreToolUse[0] command '$cmd' starts a loop, a sleep, a background job or a permission bypass" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': '$cmd'}]}]\""
done
expect "hook command with redirects and && accepted" 0 "OK:" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': 'scripts/note.sh 2>&1 && true'}]}]\""
# An "&" inside "&&", "|&", ">&", "<&" or "&>" starts no background job, and "sleep" inside a longer
# word (a letter, a digit or "_" beside it) is another word.
expect "hook command with every & form that starts no background job accepted" 0 "OK:" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': 'scripts/note.sh 2>&1 <&0 && true |& cat &>note.log'}]}]\""
expect "hook command with sleep inside longer words accepted" 0 "OK:" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': 'scripts/asleep.sh usleep sleep_ms 9sleep'}]}]\""
expect "hook command with a list loop and loop words inside names accepted" 0 "OK:" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': 'for f in a b; do scripts/wait-until-ready.sh --meanwhile || true; done'}]}]\""
# A loop word with a letter, a digit, "_", ".", "/" or "-" directly before or after it is no shell
# word: one token for each of the six characters on each side.
expect "hook command with each character that makes a loop word part of a name accepted" 0 "OK:" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': 'scripts/run ./until x.while --until 9while _until awhile while.sh until/x while-x untilx while9 until_'}]}]\""
expect "hook entry with async true"        1 "ERROR: .claude/settings.json: hooks.Stop[0] runs a hook asynchronously (\"async\": true), which escapes its timeout" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['async'] = True\""
expect "hook entry with async false accepted" 0 "OK:" "jedit \"d['hooks']['PreToolUse'] = [{'hooks': [{'type': 'command', 'command': 'scripts/note.sh', 'async': False}]}]\""
# AVE-REQ-097 AC-3: the Stop gate is registered once; nothing in the settings file switches it off,
# loosens it or runs a heavier tier at every stop.
expect "Stop hook removed"                 1 "ERROR: .claude/settings.json: hooks.Stop holds 0 command(s); it holds exactly one, the Stop gate .claude/hooks/stop-verify.sh" "jedit \"del d['hooks']['Stop']\""
expect "Stop command replaced"             1 "must run the Stop gate .claude/hooks/stop-verify.sh and no other verification command" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] = 'true'\""
expect "second Stop command"               1 "hooks.Stop holds 2 command(s)" "jedit \"d['hooks']['Stop'].append({'hooks': [{'type': 'command', 'command': 'scripts/verify.sh --tier release'}]})\""
expect "Stop command with a heavier tier"  1 "must run the Stop gate .claude/hooks/stop-verify.sh and no other verification command" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] = '.claude/hooks/stop-verify.sh; scripts/verify.sh --tier release'\""
expect "Stop command sets a gate variable" 1 "sets a gate variable" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] = 'CLAUDE_VERIFY_GATE=off .claude/hooks/stop-verify.sh'\""
expect "disableAllHooks"                   1 "disableAllHooks switches the Stop gate and the SessionStart hook off" "jedit \"d['disableAllHooks'] = True\""
expect "settings env switches the gate off" 1 "env.CLAUDE_VERIFY_GATE changes the Stop gate from the settings file" "jedit \"d['env'] = {'CLAUDE_VERIFY_GATE': 'off'}\""
expect "settings env loosens the gate"     1 "env.CLAUDE_VERIFY_MAX_ATTEMPTS changes the Stop gate from the settings file" "jedit \"d['env'] = {'CLAUDE_VERIFY_MAX_ATTEMPTS': '1'}\""
# AVE-REQ-097 AC-3: the Stop gate is a handler of type command whose command is exactly the registered
# one; text after it, another spelling of it or another handler type would switch the gate off.
STOP_EXACT='reads exactly "$CLAUDE_PROJECT_DIR"/.claude/hooks/stop-verify.sh, with nothing before or after it'
expect "Stop command with || true appended" 1 "$STOP_EXACT" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] += ' || true'\""
expect "Stop command with a redirect appended" 1 "$STOP_EXACT" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] += ' >/dev/null 2>&1'\""
expect "Stop command with text before it"  1 "$STOP_EXACT" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] = 'exec ' + d['hooks']['Stop'][0]['hooks'][0]['command']\""
expect "Stop command without the project directory" 1 "$STOP_EXACT" "jedit \"d['hooks']['Stop'][0]['hooks'][0]['command'] = '.claude/hooks/stop-verify.sh'\""
expect "Stop handler of type prompt"       1 'ERROR: .claude/settings.json: hooks.Stop handler has type "prompt"; the Stop gate is a handler of type "command"' "jedit \"d['hooks']['Stop'][0]['hooks'][0]['type'] = 'prompt'\""
expect "Stop handler without a type"       1 'hooks.Stop handler has type null; the Stop gate is a handler of type "command"' "jedit \"del d['hooks']['Stop'][0]['hooks'][0]['type']\""
# AVE-REQ-097 AC-3: no setting changes the shell that runs the hooks and verify.sh (SHELLOPTS=noexec
# makes a script exit 0 without running a command).
for key in SHELLOPTS BASHOPTS BASH_ENV ENV; do
  expect "settings env sets $key"          1 "ERROR: .claude/settings.json: env.$key changes the shell that runs the hooks and verify.sh from the settings file" "jedit \"d['env'] = {'$key': 'noexec'}\""
done
expect "settings env with other variables accepted" 0 "OK:" "jedit \"d['env'] = {'ENVIRONMENT': 'dev', 'AVE_NOTE': 'x', 'BASH_ENVIRONMENT': 'y'}\""
# AVE-REQ-097 AC-4: scripts/verify.d holds the registered step files only.
expect "unregistered step file"            1 "ERROR: scripts/verify.d/99-local.sh: is no registered component step file" "printf '# x\\n' > scripts/verify.d/99-local.sh"
expect "unregistered hidden step file"     1 "ERROR: scripts/verify.d/.local.sh: is no registered component step file" "printf '# x\\n' > scripts/verify.d/.local.sh"
expect "unregistered step file whose name opens with two dots" 1 "ERROR: scripts/verify.d/..local.sh: is no registered component step file" "printf '# x\\n' > scripts/verify.d/..local.sh"
expect "unregistered directory among the step files" 1 "ERROR: scripts/verify.d/extra: is no registered component step file" "mkdir scripts/verify.d/extra"
# AVE-REQ-098 AC-2: the SessionStart hook runs at startup, after resume, after /clear and after
# compaction.
SS="d['hooks']['SessionStart']"
NOT_ON="ERROR: .claude/settings.json: the SessionStart hook .claude/hooks/session-start.sh does not run on"
expect "SessionStart matcher startup only" 1 "$NOT_ON resume, clear, compact: its matcher excludes them" "jedit \"${SS}[0]['matcher'] = 'startup'\""
expect "SessionStart matcher without compact" 1 "$NOT_ON compact: its matcher excludes them" "jedit \"${SS}[0]['matcher'] = 'startup|resume|clear'\""
expect "SessionStart matcher without clear" 1 "$NOT_ON clear: its matcher excludes them" "jedit \"${SS}[0]['matcher'] = 'startup|resume|compact'\""
expect "SessionStart matcher without startup" 1 "$NOT_ON startup: its matcher excludes them" "jedit \"${SS}[0]['matcher'] = 'resume|clear|compact'\""
expect "SessionStart regex matcher without resume" 1 "$NOT_ON resume: its matcher excludes them" "jedit \"${SS}[0]['matcher'] = '^(startup|clear|compact)\$'\""
expect "SessionStart comma list is a regex matching nothing" 1 "$NOT_ON startup, resume, clear, compact" "jedit \"${SS}[0]['matcher'] = 'startup, resume, clear, compact'\""
expect "SessionStart pipe list accepted"    0 "OK:" "jedit \"${SS}[0]['matcher'] = 'startup|resume|clear|compact'\""
expect "SessionStart regex matcher accepted" 0 "OK:" "jedit \"${SS}[0]['matcher'] = '^(startup|resume|clear|compact)\$'\""
expect "SessionStart matcher * accepted"   0 "OK:" "jedit \"${SS}[0]['matcher'] = '*'\""
expect "SessionStart groups that cover the four sources together accepted" 0 "OK:" "jedit \"${SS} = [{'matcher': 'startup|resume', 'hooks': ${SS}[0]['hooks']}, {'matcher': 'clear|compact', 'hooks': ${SS}[0]['hooks']}]\""
expect "SessionStart hook removed"         1 "ERROR: .claude/settings.json: no SessionStart hook runs .claude/hooks/session-start.sh" "jedit \"del ${SS}\""
expect "SessionStart without a group"      1 "ERROR: .claude/settings.json: no SessionStart hook runs .claude/hooks/session-start.sh" "jedit \"${SS} = []\""
expect "settings without the hooks object" 1 "ERROR: .claude/settings.json: no SessionStart hook runs .claude/hooks/session-start.sh" "jedit \"del d['hooks']\""
expect "settings whose hooks value is a list" 1 "ERROR: .claude/settings.json: no SessionStart hook runs .claude/hooks/session-start.sh" "jedit \"d['hooks'] = [d['hooks']]\""
# AVE-REQ-098 AC-2: the SessionStart command is exactly the registered one. A command that names the
# hook script and never starts it, or that discards what the script prints, injects no state.
SS_COMMAND="${SS}[0]['hooks'][0]['command']"
SS_EXACT='must run the SessionStart hook .claude/hooks/session-start.sh and nothing else: it reads exactly "$CLAUDE_PROJECT_DIR"/.claude/hooks/session-start.sh, with nothing before or after it'
expect "SessionStart command with its output discarded" 1 "$SS_EXACT" "jedit \"$SS_COMMAND += ' >/dev/null'\""
expect "SessionStart command piped into head" 1 "$SS_EXACT" "jedit \"$SS_COMMAND += ' | head -n 1'\""
expect "SessionStart command behind false &&" 1 "$SS_EXACT" "jedit \"$SS_COMMAND = 'false && ' + $SS_COMMAND\""
expect "SessionStart command that names the hook in a comment" 1 "$SS_EXACT" "jedit \"$SS_COMMAND = 'true # .claude/hooks/session-start.sh'\""
expect "SessionStart command that prints the hook's path" 1 "$SS_EXACT" "jedit \"$SS_COMMAND = 'echo .claude/hooks/session-start.sh'\""
expect "SessionStart command without the project directory" 1 "$SS_EXACT" "jedit \"$SS_COMMAND = '.claude/hooks/session-start.sh'\""
expect "a command that names the hook registers no SessionStart hook" 1 "ERROR: .claude/settings.json: no SessionStart hook runs .claude/hooks/session-start.sh" "jedit \"$SS_COMMAND = 'true # .claude/hooks/session-start.sh'\""
expect "SessionStart handler of type prompt" 1 'ERROR: .claude/settings.json: hooks.SessionStart handler has type "prompt"; the SessionStart hook is a handler of type "command"' "jedit \"${SS}[0]['hooks'][0]['type'] = 'prompt'\""
expect "second SessionStart command"       1 "hooks.SessionStart command 'scripts/note.sh' must run the SessionStart hook .claude/hooks/session-start.sh and nothing else" "jedit \"${SS}.append({'hooks': [{'type': 'command', 'command': 'scripts/note.sh'}]})\""
# AVE-REQ-098 AC-2, AVE-REQ-097 AC-3: the two registrations hold the keys of the written form only: a
# group "hooks" (SessionStart also "matcher"), a handler "type", "command" and optionally "timeout".
ST="d['hooks']['Stop']"
expect "SessionStart group with a foreign key" 1 'ERROR: .claude/settings.json: hooks.SessionStart[0] holds the key "if"; a group of hooks.SessionStart holds "hooks", "matcher" only (AVE-REQ-098 AC-2)' "jedit \"${SS}[0]['if'] = 'false'\""
expect "SessionStart handler with a foreign key" 1 'ERROR: .claude/settings.json: hooks.SessionStart[0] handler holds the key "once"; a handler of hooks.SessionStart holds "type", "command", "timeout" only (AVE-REQ-098 AC-2)' "jedit \"${SS}[0]['hooks'][0]['once'] = True\""
expect "SessionStart handler with async false" 1 'hooks.SessionStart[0] handler holds the key "async"' "jedit \"${SS}[0]['hooks'][0]['async'] = False\""
expect "Stop group with a foreign key"     1 'ERROR: .claude/settings.json: hooks.Stop[0] holds the key "matcher"; a group of hooks.Stop holds "hooks" only (AVE-REQ-097 AC-3)' "jedit \"${ST}[0]['matcher'] = ''\""
expect "Stop handler with a foreign key"   1 'ERROR: .claude/settings.json: hooks.Stop[0] handler holds the key "shell"; a handler of hooks.Stop holds "type", "command", "timeout" only (AVE-REQ-097 AC-3)' "jedit \"${ST}[0]['hooks'][0]['shell'] = 'powershell'\""
expect "SessionStart handler with a timeout accepted" 0 "OK:" "jedit \"${SS}[0]['hooks'][0]['timeout'] = 60\""
expect "SessionStart group that is no object" 1 "ERROR: .claude/settings.json: hooks.SessionStart[1] is no group object" "jedit \"${SS}.append('x')\""
expect "Stop group that is no object"      1 "ERROR: .claude/settings.json: hooks.Stop[1] is no group object" "jedit \"${ST}.append([])\""
expect "SessionStart group whose handlers are no list" 1 'ERROR: .claude/settings.json: hooks.SessionStart[1] holds no list of handlers under "hooks"' "jedit \"${SS}.append({'hooks': {}})\""
expect "Stop handler that is no object"    1 "ERROR: .claude/settings.json: hooks.Stop[0] holds a handler that is no object" "jedit \"${ST}[0]['hooks'].append('x')\""
expect "SessionStart handler that is no object" 1 "ERROR: .claude/settings.json: hooks.SessionStart[0] holds a handler that is no object" "jedit \"${SS}[0]['hooks'].append(['x'])\""
# AVE-REQ-098 AC-2, AVE-REQ-097 AC-3: the settings file is one JSON object. A list, null, a string, a
# number or a boolean is valid JSON and registers no hook.
NO_OBJECT="ERROR: .claude/settings.json: the top-level value is"
ONE_OBJECT="the settings file is one JSON object, and any other value registers no SessionStart hook and no Stop gate"
expect "settings: top-level list"          1 "$NO_OBJECT a list; $ONE_OBJECT" "printf '[]\\n' > .claude/settings.json"
expect "settings: top-level null"          1 "$NO_OBJECT null; $ONE_OBJECT" "printf 'null\\n' > .claude/settings.json"
expect "settings: top-level string"        1 "$NO_OBJECT a string; $ONE_OBJECT" "printf '\"hooks\"\\n' > .claude/settings.json"
expect "settings: a list that holds the settings object" 1 "$NO_OBJECT a list; $ONE_OBJECT" "{ printf '[' && cat .claude/settings.json && printf ']\\n'; } > s.tmp && mv s.tmp .claude/settings.json"
expect "settings: top-level number"        1 "$NO_OBJECT a number; $ONE_OBJECT" "printf '7\\n' > .claude/settings.json"
expect "settings: top-level boolean"       1 "$NO_OBJECT a boolean; $ONE_OBJECT" "printf 'true\\n' > .claude/settings.json"
# AVE-REQ-098 AC-3: .env.example documents the product variables an unblock action names.
expect "missing .env.example"              1 "ERROR: .env.example: required file is missing" "rm .env.example"
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
  AWKS_RUN=0
  for impl in mawk gawk original-awk busybox; do
    if ! command -v "$impl" >/dev/null 2>&1; then echo "### awk = $impl: not installed, skipped"; continue; fi
    SHIM="$T/shim-$impl"; rm -rf "$SHIM"; mkdir -p "$SHIM"
    if [ "$impl" = busybox ]; then printf '#!/bin/sh\nexec busybox awk "$@"\n' > "$SHIM/awk"; chmod +x "$SHIM/awk"; else ln -s "$(command -v "$impl")" "$SHIM/awk"; fi
    echo "### awk = $impl"
    AWKS_RUN=$((AWKS_RUN + 1))
    # The cases below run the checker with this shim first on PATH: the awk it finds is this one.
    if [ "$(PATH="${CHECK_PATH:-$SHIM:$PATH}" command -v awk)" = "$SHIM/awk" ]; then
      PASS=$((PASS+1)); echo "  ok   the checker's PATH resolves awk to the $impl shim"
    else
      FAIL=$((FAIL+1)); echo "  FAIL the checker's PATH resolves awk to the $impl shim"
    fi
    run_suite
  done
  # AVE-REQ-097 AC-4: a suite whose cases were all skipped establishes nothing.
  if [ "$AWKS_RUN" -ge 1 ]; then
    PASS=$((PASS+1)); echo "  ok   --all-awks ran $AWKS_RUN awk implementation(s)"
  else
    FAIL=$((FAIL+1)); echo "  FAIL --all-awks ran no awk implementation (install mawk, gawk, original-awk or busybox)"
  fi
else
  echo "### awk = system ($(command -v awk))"
  run_suite
fi
# The edit helper names itself when it cannot edit the settings file and leaves the file as it was,
# so a setup failure of a settings case is told apart from a verdict of the checker.
echo "### edit helper"
mkdir -p "$T/helper/.claude" && printf '[]\n' > "$T/helper/.claude/settings.json"
HELPER_OUT="$(cd "$T/helper" && jedit "d['hooks'] = {}" 2>&1)"; HELPER_CODE=$?
if [ "$HELPER_CODE" != 0 ] && printf '%s\n' "$HELPER_OUT" | quiet -F "jedit: .claude/settings.json not edited by" &&
  [ "$(cat "$T/helper/.claude/settings.json")" = "[]" ]; then
  PASS=$((PASS+1)); echo "  ok   the edit helper reports a file it cannot edit by its own line"
else
  FAIL=$((FAIL+1)); printf '  FAIL the edit helper reports a file it cannot edit by its own line (exit=%s)\n%s\n' "$HELPER_CODE" "$HELPER_OUT"
fi
# S8: the other JSON validators, each alone on PATH (run once; system awk)
make_path() {  # make_path <dir> [extra tools...]
  local d="$T/$1" t
  shift
  rm -rf "$d"; mkdir -p "$d"
  for t in awk bash cat dirname env find grep head sed sort tail tr "$@"; do ln -s "$(command -v "$t")" "$d/$t"; done
}
SHIM=""
# AVE-REQ-097 AC-4: the suite's own guards. Started without jq or without node on PATH, this file
# stops with status 2 before any case and names the missing tool.
echo "### the suite's own guards"
for tool in jq node; do
  if [ "$tool" = jq ]; then make_path "path-no-$tool" node; else make_path "path-no-$tool" jq; fi
  GUARD_OUT="$(PATH="$T/path-no-$tool" bash "$W/test-checker.sh" 2>&1)"; GUARD_CODE=$?
  if [ "$GUARD_CODE" = 2 ] && [ "$GUARD_OUT" = "test-checker.sh: $tool is not installed: the $tool validator cases cannot run" ]; then
    PASS=$((PASS+1)); echo "  ok   the suite stops with status 2 when $tool is missing"
  else
    FAIL=$((FAIL+1)); printf '  FAIL the suite stops with status 2 when %s is missing (exit=%s)\n%s\n' "$tool" "$GUARD_CODE" "$GUARD_OUT" | head -n 12
  fi
done
# jq and node are present here: the guard at the top of this file stops the suite without them.
echo "### JSON validators"
make_path path-jq jq
CHECK_PATH="$T/path-jq" expect "jq: valid settings"                0 "OK:" true
CHECK_PATH="$T/path-jq" expect "jq: two concatenated objects"      1 "expected one JSON value, found 2" "cat .claude/settings.json .claude/settings.json > s.tmp && mv s.tmp .claude/settings.json"
CHECK_PATH="$T/path-jq" expect "jq: empty file"                    1 "expected one JSON value, found 0" ": > .claude/settings.json"
CHECK_PATH="$T/path-jq" expect "jq: syntax error"                  1 "ERROR: .claude/settings.json: invalid JSON" "sub .claude/settings.json '\"Bash(git show *)\"' '\"Bash(git show *)\",'"
make_path path-node node
CHECK_PATH="$T/path-node" expect "node: valid settings"            0 "OK:" true
CHECK_PATH="$T/path-node" expect "node: two concatenated objects"  1 "ERROR: .claude/settings.json: invalid JSON: SyntaxError" "cat .claude/settings.json .claude/settings.json > s.tmp && mv s.tmp .claude/settings.json"
CHECK_PATH="$T/path-node" expect "node: empty file"                1 "ERROR: .claude/settings.json: invalid JSON: SyntaxError" ": > .claude/settings.json"
make_path path-none
CHECK_PATH="$T/path-none" expect "no validator: warning only"      0 "WARN: .claude/settings.json: JSON not validated (install python3, node or jq)" true
CHECK_PATH="$T/path-none" expect "no python3: settings policy warning" 0 "WARN: .claude/settings.json: settings policy not checked (install python3)" true
echo "CHECKER TOTAL: pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
