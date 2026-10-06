# Handback — M0 gates red-team, part 3: completeness critic of AVE-REQ-093

Brief: [2026-10-03-m0-gates-red-team.md](../2026-10-03-m0-gates-red-team.md). Run `wf_98f469f7-ec5` at `35f99c5` ([script](../../workflows/m0-gates-red-team-wf_98f469f7-ec5.js)). Each finder worked read-only in a private clone; the reports below are theirs, unedited apart from local paths. The lead's disposition closes each section.

## Lens critic AVE-REQ-093

### Scope, method and probes without a finding

```text
critic AVE-REQ-093 — completeness pass over lenses 093-A, 093-B and 093-C at 35f99c5.

What the three finders left out, and what I probed (clone .claude\worktrees\redteam-critic-ave-req-093, removed at the end):
1. The width of a requirement ID. A and B varied how scripts\evidence.py reads the status and the ticks; nobody varied how it derives the ID (`path.name[:11]`, scripts/evidence.py:134). Finding 1.
2. The inspection path of the done gate that the Verification strategy cites for AC-4 (`_INSPECTION_LINE`, scripts/evidence.py:84). Finding 2.
3. The other audit loops of milestone-review. B showed the step 11.3 loop cannot fail; nobody ran the untagged-criterion loop of step 4.2 and docs/TRACEABILITY.md § Conventions. Finding 3 (it under-reports on the unmodified tree).
4. Whether the suite credited for AC-1, AC-3 and AC-4 notices a removed rule. The finders listed the cases missing for their own findings; none mutated the checker. Finding 4.
5. Verification-strategy and Implementation-evidence claims nobody ran: "a file removed behind an edited validator" (held), "committed unchanged at 6160278" and "Git history since f605c6c" (read-only: `git log -- ai-video-editor-requirements` shows the single commit 6160278 and `git diff --stat 6160278 HEAD -- ai-video-editor-requirements` is empty; f605c6c is the bootstrap commit; ASM-004 and ADR-003 exist).
6. Lens 093-C named "a field one reads and the other ignores" and reported no probe of it. Read-only comparison in the clone: for all 101 requirements the 12 fields the import tool takes from spec/requirements.json (title, scope, priority, status, parent, epic, gate, origins, dependencies, scenarios, statement, criteria) equal the frontmatter and body of spec/requirements/AVE-REQ-NNN.md (0 differences), and the Description and criteria of all 101 working files equal the baseline Markdown (0 differing). No finding.

Each finding states whether it still reproduces on the committed branch head f894bbf; I tested that on a `git archive f894bbf` copy in the clone's container, never in the main checkout, and the uncommitted changes of the main checkout were not tested.

Not probed: the media and release tiers end to end (the release step is the `check-done` command run here; `fast_step` in scripts/verify.sh:120 runs the baseline step in every tier by reading, not by a run); AC-2 (outside the brief); the suite of f894bbf under mutation (the seven mutations ran at 35f99c5 only). One line of probing was dropped: I planned to extend 093-C's environment findings to the interpreter environment inside the container, and that response was stopped by a safety classifier before any command ran, so nothing in this report covers it.
```

### Baseline

```text
Clone at 35f99c5, before the first probe, `git status --short` empty.
- `./scripts/verify.sh` → exit 0, `verify.sh: PASS — tier fast (9 of 9 steps passed)`; Project control files `OK: 49 required files, 6 executable scripts, 5 agents, 9 skills, 2419 links in 196 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)`; Requirements baseline integrity `Baseline files: PASS (... all 133 manifest entries ...)`, `by status: proposed 3, ready 84, in-progress 15, deferred 2`, `Acceptance criteria ticked: 0 of 404 (version one: 0 of 398)`, `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`; Evidence manifest `Evidence: PASS — 36 criteria tagged`.
- `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` → exit 0, `BASELINE TOTAL: pass=101 fail=0`.
- `./scripts/dev-container.sh python3 -B scripts/check_baseline.py` → exit 0, `Working requirements: 104`, `by gate: M0 5 (0 done); M1 16 (0 done); ... FUTURE 2 (0 done)`, `OK: baseline intact; ...`.
- Extracted tree of f894bbf (container /tmp/head), unmodified: check_baseline `OK: baseline intact; ...` exit 0; check-project-control `OK: 50 required files, ... 2437 links in 198 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)` exit 0; `evidence.py check-done --dir var/empty-run` → `OK: every criterion of the 0 done requirements is evidenced by this run` exit 0.
The branch moved after the brief's commit: 4413e4a ("one reader and a canonical form for requirement files; fix the red-team findings of the baseline gate") and f894bbf. Of my four findings, finding 1 no longer reproduces at f894bbf (no suite case holds the correction); findings 2 and 3 reproduce at f894bbf; finding 4 was run at 35f99c5 only.
```

### Finding critic-093-1 (blocking) — A derived requirement whose four-digit ID starts with the three digits of a done requirement hides that requirement from check-done

Criterion: AVE-REQ-093 AC-4 (Verification strategy: "`scripts/evidence.py check-done` (release tier) refuses a `done` requirement without this run's evidence"); AVE-REQ-097 AC-4

Reproduction:

```text
Clone at 35f99c5, after the baseline `./scripts/verify.sh` (it leaves var/verify/runs/<run>/).

Step 1, AVE-REQ-011 done on paper:
./scripts/dev-container.sh python3 - <<'EOF'
import glob
DASH = chr(0x2014)
path = glob.glob("docs/requirements/AVE-REQ-011-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
t = t.replace("status: ready\n", "status: done\n", 1).replace("- [ ] AC-", "- [x] AC-")
t = "\n".join("- recorded." if line.startswith("_TBD") else line for line in t.split("\n"))
t += "- 2026-10-06 %s done %s verify-requirement PASS (lead)\n" % (DASH, DASH)
open(path, "w", encoding="utf-8", newline="").write(t)
trace = "docs/TRACEABILITY.md"
t = open(trace, encoding="utf-8", newline="").read()
sep = "|---|---|---|---|---|---|\n"
row = "| [AVE-REQ-011](requirements/%s) | done | x | x | x | x |\n" % path.split("/")[-1]
assert t.count(sep) == 1
open(trace, "w", encoding="utf-8", newline="").write(t.replace(sep, sep + row, 1))
EOF

Step 2, control (GATES):
./scripts/dev-container.sh bash scripts/check-project-control.sh | tail -2
./scripts/dev-container.sh python3 -B scripts/check_baseline.py | tail -4
./scripts/dev-container.sh python3 -B scripts/evidence.py check-done --dir "$(ls -d var/verify/runs/*/ | tail -1)"

Step 3, one new derived file (a copy of AVE-REQ-103, status proposed):
./scripts/dev-container.sh python3 - <<'EOF'
import glob
src = glob.glob("docs/requirements/AVE-REQ-103-*.md")[0]
s = open(src, encoding="utf-8", newline="").read().replace("AVE-REQ-103", "AVE-REQ-0110")
open("docs/requirements/AVE-REQ-0110-follow-up.md", "w", encoding="utf-8", newline="").write(s)
EOF

Step 4: GATES again; `./scripts/verify.sh`; check-done on the new run directory; `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-011 --require-complete`.

Variant on the clean clone: the same copy written as docs/requirements/AVE-REQ-1000-follow-up.md (replace "AVE-REQ-103" by "AVE-REQ-1000"), both checkers, then `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-100`.

Branch head: inside the container `git archive f894bbf | tar -x -C /tmp/head`, steps 1 and 3 there (`sed "s/AVE-REQ-103/AVE-REQ-0110/g"`), both checkers and `python3 -B scripts/evidence.py check-done --dir var/empty-run`.
```

Observed:

```text
Step 2 (control): check-project-control `OK: ... 134 requirement files, 9 ADRs; 0 warning(s)` exit 0; check_baseline `by status: proposed 3, ready 83, in-progress 15, done 1, deferred 2`, `Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)`, `OK: baseline intact; ...` exit 0; check-done `ERROR: AVE-REQ-011 AC-1: missing in this run` (also AC-2, AC-3, AC-4), `FAIL: 4 criteria of done requirements lack evidence in this run`, exit 1.

Step 4, with AVE-REQ-0110-follow-up.md (`id: AVE-REQ-0110`, `status: proposed`, `source: derived`): check-project-control `OK: ... 2425 links in 197 Markdown files, 135 requirement files ...` exit 0; check_baseline `Working requirements: 105`, `by status: proposed 4, ready 83, in-progress 15, done 1, deferred 2`, `by gate: ... M2 18 (1 done) ...`, `OK: baseline intact; ...` exit 0; `./scripts/verify.sh` → `verify.sh: PASS — tier fast (9 of 9 steps passed)` exit 0; check-done `OK: every criterion of the 0 done requirements is evidenced by this run`, exit 0. `show AVE-REQ-011 --require-complete` prints `AVE-REQ-011 (proposed)` with three criteria (`AC-1 missing`, `AC-2 missing`, `AC-3 missing`): the status and the criteria of the other file. AVE-REQ-011 has four criteria, no implementation and no tagged test.

Variant: with AVE-REQ-1000-follow-up.md both checkers exit 0 and `show AVE-REQ-100` prints `AVE-REQ-100 (proposed)` with three criteria, while AVE-REQ-100 is `ready` with four.

Cause: scripts/evidence.py:134 names a requirement `path.name[:11]` and :139-140 builds a dict over the sorted files, so `AVE-REQ-0110-follow-up.md` sorts after `AVE-REQ-011-non-destructive-...md` and replaces it under the key AVE-REQ-011. Both checkers accept the new file: the filename pattern allows three or more digits (scripts/check_baseline.py:66, scripts/check-project-control.sh:581), 110 lies above the baseline range (scripts/check_baseline.py:565), and README § IDs rule 1 ("allocated sequentially") has no check.

Branch head f894bbf: the same probe gives check-done `ERROR: AVE-REQ-011 AC-1: missing in this run` (four lines), `FAIL: 4 problem(s): ...`, exit 1; the shared reader of 4413e4a takes the ID from the whole file name. check_baseline there also reports the new file as absent from its parent and from ROADMAP.md. `git grep -n -E 'AVE-REQ-[0-9]{4}' f894bbf -- scripts/tests` finds only the test-checker.sh case "four-digit requirement accepted": no evidence test holds the corrected ID reading.
```

Expected:

```text
check-done exits 1 with the four `missing in this run` lines for every tree in which both checkers count AVE-REQ-011 as done; `show AVE-REQ-011` shows AVE-REQ-011.
```

Fix:

```text
At 35f99c5: read_requirement takes the ID from the full name match (`^(AVE-REQ-\d{3,})-`), as the reader of f894bbf does. At f894bbf: add the missing case to scripts\tests\test_evidence.py, "a requirement file whose four-digit ID starts with the digits of a done requirement does not hide it from check-done" (two files AVE-REQ-011-a.md done and AVE-REQ-0110-b.md proposed; done_problems reports AVE-REQ-011). Decide in the same change whether IDs above 999 are allowed: `CRITERION_TAG` and `_TAG_IN_TEXT` accept exactly three digits, so a four-digit requirement accepted by both checkers can carry no test tag.
```

Lead's disposition: fixed with 097-E-3: requirement IDs come from the shared reader with any width, and two files with one ID stop the evidence tool.

### Finding critic-093-2 (blocking) — check-done passes a done requirement on four free-text inspection lines with an empty run, whatever level the Verification strategy names; the cited sentence says it refuses

Criterion: AVE-REQ-093 AC-4 (Verification strategy: "`scripts/evidence.py check-done` (release tier) refuses a `done` requirement without this run's evidence"); AVE-REQ-097 AC-4

Reproduction:

```text
Clone at 35f99c5, clean, after the baseline `./scripts/verify.sh`.
./scripts/dev-container.sh python3 - <<'EOF'
import glob
DASH = chr(0x2014); ARROW = chr(0x2192)
path = glob.glob("docs/requirements/AVE-REQ-011-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
t = t.replace("status: ready\n", "status: done\n", 1).replace("- [ ] AC-", "- [x] AC-")
tbd_test = "_TBD: filled by the lead from the verify-requirement report._"
assert t.count(tbd_test) == 1
t = t.replace(tbd_test, "\n".join("- AC-%d %s inspection: read by the lead %s pass" % (n, ARROW, DASH) for n in (1, 2, 3, 4)), 1)
t = "\n".join("- recorded." if line.startswith("_TBD") else line for line in t.split("\n"))
t += "- 2026-10-06 %s done %s verify-requirement PASS (lead)\n" % (DASH, DASH)
open(path, "w", encoding="utf-8", newline="").write(t)
trace = "docs/TRACEABILITY.md"
t = open(trace, encoding="utf-8", newline="").read()
sep = "|---|---|---|---|---|---|\n"
row = "| [AVE-REQ-011](requirements/%s) | done | x | x | x | x |\n" % path.split("/")[-1]
assert t.count(sep) == 1
open(trace, "w", encoding="utf-8", newline="").write(t.replace(sep, sep + row, 1))
EOF
./scripts/dev-container.sh bash scripts/check-project-control.sh | tail -1
./scripts/dev-container.sh python3 -B scripts/check_baseline.py | tail -2
./scripts/dev-container.sh python3 -B scripts/evidence.py check-done --dir "$(ls -d var/verify/runs/*/ | tail -1)"
./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-011 --require-complete

Branch head: the same edit on the `git archive f894bbf` copy in the container (/tmp/head), both checkers, `python3 -B scripts/evidence.py check-done --dir var/empty-run` (an empty directory).
```

Observed:

```text
35f99c5: check-project-control `OK: ...` exit 0; check_baseline `Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)`, `OK: baseline intact; ...` exit 0; check-done `OK: every criterion of the 1 done requirements is evidenced by this run`, exit 0; `show AVE-REQ-011 --require-complete` prints `AVE-REQ-011 (done)` and `AC-1 inspected` to `AC-4 inspected`, exit 0. The file's § Verification strategy still reads `AC-1–AC-4 — criterion-level tests tagged `AVE-REQ-011 AC-n`, one tag per criterion; ...`, and no test in the tree carries an AVE-REQ-011 tag.

f894bbf: the same; check_baseline exit 0, check-project-control exit 0, check-done `OK: every criterion of the 1 done requirements is evidenced by this run` exit 0 on the empty run directory. The AC-4 line of AVE-REQ-093 at f894bbf still ends "`scripts/evidence.py check-done` (release tier) refuses a `done` requirement without this run's evidence".

Cause: scripts/evidence.py:84 and :129-133 count any § Test evidence line `- AC-n → inspection:` and criterion_state (:356-364) returns `inspected` for it; nothing compares the line with the level § Verification strategy names. README § Writing requirements says "Inspection needs a reason why automation is impractical" and verify-requirement step 3 asks for "a justified inspection in § Verification strategy": both are reader rules.
```

Expected:

```text
As the sentence is written: exit 1, the run evidences none of the four criteria. The inspection text itself is free text for verify-requirement to judge, so the lead may weigh this as a limit of the guard; the sentence and the gate's own message ("is evidenced by this run") are false for an inspected criterion in either reading.
```

Fix:

```text
Smallest mechanical tie: evidence.py counts an inspection line only for a criterion whose § Verification strategy line names the level `inspection` (`- AC-n — inspection — ...`, or a range line that names it), and the check-done message reads "evidenced by this run or by a recorded inspection (N inspected)". Cases in scripts\tests\test_evidence.py: "an inspection line for a criterion whose Verification strategy names a test level fails check-done", "an inspection line for a criterion planned as inspection passes". Otherwise reword the AC-4 line of AVE-REQ-093: "refuses a `done` requirement whose criterion has neither a passing test in this run nor an inspection line in § Test evidence; the inspection is judged by verify-requirement".
```

Lead's disposition: fixed: an inspection line counts only for a criterion whose Verification strategy line names inspection; the done gate's message names both kinds of evidence, and the AC-4 line of AVE-REQ-093's strategy states the rule as implemented.

### Finding critic-093-3 (boundary) — The untagged-criterion audit loop treats fixture strings of the tooling suites as tagged tests: on the unmodified tree it reports one of the four untested criteria of AVE-REQ-001

Criterion: AVE-REQ-093 AC-4 ("package validation is not product verification"; the inspection that milestone-review step 4.2 and docs/TRACEABILITY.md § Conventions, audit 3, name for criteria without tests)

Reproduction:

```text
Clone at 35f99c5, clean (`git status --short` empty), no edit:
./scripts/dev-container.sh bash -c 'for id in AVE-REQ-001; do for ac in $(grep -oE "^- \[[ x]\] AC-[0-9]+" docs/requirements/"$id"-*.md | grep -oE "AC-[0-9]+"); do git grep -q -w --untracked "$id $ac" -- ":!*.md" || echo "no tagged test: $id $ac"; done; done; echo "loop finished"'
(the loop of .claude/skills/milestone-review/SKILL.md:82-86 and docs/TRACEABILITY.md:103-105, plus one echo)
./scripts/dev-container.sh bash -c 'git grep -n -w --untracked -e "AVE-REQ-001 AC-1" -e "AVE-REQ-001 AC-2" -e "AVE-REQ-001 AC-4" -- ":!*.md"'
./scripts/dev-container.sh python3 -B -c 'import json; m = json.load(open("var/verify/latest-fast.json", encoding="utf-8")); print([k for k in sorted(m["criteria"]) if k[:11] == "AVE-REQ-001"])'
Branch head, in the clone: for ac in AC-1 AC-2 AC-3 AC-4; do git grep -q -w "AVE-REQ-001 $ac" f894bbf -- ':!*.md' && echo "matches: AVE-REQ-001 $ac" || echo "no tagged test: AVE-REQ-001 $ac"; done
```

Observed:

```text
The loop prints `no tagged test: AVE-REQ-001 AC-3` and `loop finished`: AC-1, AC-2 and AC-4 count as tagged. Their matches are expected-output and fixture strings, no test of AVE-REQ-001: scripts/tests/test-checker.sh:205-206 (`sed 's/^AVE-REQ-001 AC-1...`, the brief fixture), scripts/tests/test-check-baseline.sh:197 (`"Recorded change: AVE-REQ-001 AC-2 differs from the baseline text ..."`), :198 and :216 (`"Recorded change: AVE-REQ-001 AC-4 is missing ..."`, `"... AVE-REQ-001 AC-4 is absent from the successor ..."`). AVE-REQ-001 is `ready` with no implementation. The evidence manifest of the fast run credits no AVE-REQ-001 criterion (`[]`): the mechanical side (comment tags and pytest markers) is not misled, so `check-done` still reports the four criteria of a done AVE-REQ-001 (the control of lens 093-A).

f894bbf: `matches: AVE-REQ-001 AC-1`, `matches: AVE-REQ-001 AC-2`, `no tagged test: AVE-REQ-001 AC-3`, `matches: AVE-REQ-001 AC-4`; the loop text of docs/TRACEABILITY.md:102-105 is unchanged there.

Reading: step 4.2 says "Each reported AC needs an `inspection` line in `## Test evidence`; otherwise it is unevidenced (blocking)". For AVE-REQ-001 the reviewer following the step is told three criteria have tests that do not exist.
```

Expected:

```text
The loop prints `no tagged test:` for AC-1, AC-2, AC-3 and AC-4 of AVE-REQ-001.
```

Fix:

```text
The audit reads what the evidence tooling credits instead of any mention in a non-Markdown file: replace the loop in docs/TRACEABILITY.md § Conventions and milestone-review step 4.2 by `python3 -B scripts/evidence.py show <ID> --tier release --require-complete` (it lists `missing` per criterion), or restrict the grep to the two tag forms (`req("... <ID> <AC> ...")` markers and `# ... <ID> <AC>` comment lines). Case in scripts\tests\test_evidence.py: "a tag inside a non-comment string of a tooling suite credits no criterion" (it pins the reading the audit then relies on).
```

Lead's disposition: fixed: the audits of docs/TRACEABILITY.md, milestone-review step 4.2 and verify-requirement read `evidence.py show`, which lists a criterion without a tagged test as `missing`; a unit test pins that only comment lines tag a tooling case.

### Finding critic-093-4 (boundary) — Seven rules of check_baseline.py can be removed with the suite still at 101 of 101; README § Enforced checks claims two of them

Criterion: AVE-REQ-093 AC-3 (evidence credited through scripts/tests/test-check-baseline.sh; README § Enforced checks, check_baseline items 4 and 7)

Reproduction:

```text
Clone at 35f99c5. For each mutation, inside the container: copy scripts/requirements/import_baseline.py, scripts/tests/test-check-baseline.sh and ai-video-editor-requirements/ to /tmp/mut/<name>/ at the same relative paths, write scripts/check_baseline.py there with one replacement (each old text occurs once, asserted), delete every __pycache__, then `cd /tmp/mut/<name> && bash scripts/tests/test-check-baseline.sh`.
m0 (sanity) `if ticked and status not in ("done", "superseded") and "done" not in item.log_statuses():` → `if False:`
m1 `        expect(item, "parent", feature["epic"])` → `        pass`
m2 in check_all_requirements, `and status not in ("deferred", "superseded")` of the `scope == "future"` test for later requirements → `and False`
m3 `    if item.get("id") != item_id:` → `    if False:`
m4 `        if scope not in ("v1", "future"):` → `        if False:`
m5 `    if item.get("status") not in STATUSES:` → `    if False:`
m6 `for key in ("scope", "primary_gate", "dependencies"):` → `for key in ("scope",):`
m7 `            if "dependencies" in item.fm:` → `            if False:`
m0 ran alone; m1 to m7 ran in parallel once, then m1, m2 and m3 again one at a time.
Direct probes of the unmutated checker on a fresh import (/tmp/fx): the held lines 3 to 7 below.
```

Observed:

```text
m0: suite exit 1, `FAIL ticked criterion on a ready requirement fails  exit=0 (want 1)`, `BASELINE TOTAL: pass=100 fail=1`: the harness detects a removed rule.
m4, m5, m6, m7 (parallel run): suite exit 0, `BASELINE TOTAL: pass=101 fail=0` each.
m1, m2, m3 (run one at a time): suite exit 0, `BASELINE TOTAL: pass=101 fail=0` each.
So the suite has no case for: the parent of a baseline feature; a later future-scope requirement that is not deferred (README item 4: "a future requirement in a status other than `deferred` or `superseded`", held only for the baseline form by "future requirement made ready"); a frontmatter id that differs from the file's ID; a scope value other than v1 or future; an invalid status in check_baseline.py; a later requirement without `primary_gate` or `dependencies` (README item 7 names both; only "derived requirement needs scope" exists); a dependencies value that is no flow list. The unmutated checker rejects each of these today (held lines 3 to 7; lens 093-B held the feature parent).

Side observation, parallel run only: m1, m2 and m3 each showed one failed case unrelated to its mutation (`FAIL feature no longer lists its requirement  exit=1 (want 1)`, `FAIL derived requirement must be source derived  exit=1 (want 1)`, `FAIL invalid gate  exit=1 (want 1)`), and each of those output blocks holds the expected line once (`grep -c -F` prints 1): the exit code and the text were right and the case still counted as failed. The single reruns were clean. The suite at 35f99c5 tests the text with `printf ... | grep -qF` under `set -o pipefail` (scripts/tests/test-check-baseline.sh:9, :82-83); commit f894bbf on the branch ("read the whole input in suite checks that grep piped text") changes this suite, and I did not rerun the load at f894bbf.
```

Expected:

```text
Each rule the README lists as enforced has a suite case that fails when the rule is removed. The path needs an edit of the gate's code, which the diff shows, so this is a coverage limit of the credited evidence, reported because README § Enforced checks states the rejections.
```

Fix:

```text
Cases in scripts\tests\test-check-baseline.sh, each a one-line mutation of the fixture: "feature parent changed fails" (`frontmatter parent 'AVE-EPIC-10' must equal the baseline value 'AVE-EPIC-01'`), "later future-scope requirement made ready fails" (`future-scope requirement must be deferred (status 'ready')`), "later requirement without dependencies fails" (`frontmatter dependencies is missing`), "later requirement without primary_gate fails", "scope v2 fails" (`frontmatter scope 'v2' must be v1 or future`), "dependencies that are no flow list fail", "frontmatter id differs from the file's ID fails" (`frontmatter id 'AVE-REQ-999' must equal AVE-REQ-001`).
```

Lead's disposition: fixed: suite cases for a changed feature parent, an invalid status, a derived requirement without primary gate or dependencies, with scope v2, with dependencies that are no flow list, future-scope and not deferred, and a second file for a derived ID (the checker now requires one file per derived ID). The mutation check of the lead (126 mutants) holds each new rule by a named case.

### Probes the gates rejected

```text
- Fixture (fresh import in the container): package validator edited (`sys.exit(0)` before `def validate(`) and spec/ACCEPTANCE_TESTS.md removed → check_baseline exit 1: 'baseline changed: the file is missing from the package' and 'tools/validate_package.py: baseline changed: SHA-256 ... differs', no 'Baseline package' line (the edited validator did not run). The suite's removed-file case runs without the edited validator; the Verification strategy names the combination.
- Clone: second file docs/requirements/AVE-REQ-103-zz-second-file.md for the derived AVE-REQ-103, with AC-1 ticked and a continuation line under it → check-project-control exit 1: 'duplicate ID AVE-REQ-103 (also used by ...)'. check_baseline alone exits 0: it reads the first file per ID, so its criteria-section and tick rules rest on this duplicate check.
- Fixture: later requirement AVE-REQ-102 with scope future, primary_gate FUTURE and status ready → check_baseline exit 1: 'future-scope requirement must be deferred (status 'ready')'
- Fixture: later requirement without a dependencies key → exit 1: 'frontmatter dependencies is missing'
- Fixture: later requirement with scope v2 → exit 1: 'frontmatter scope 'v2' must be v1 or future'
- Fixture: later requirement with `dependencies: AVE-REQ-001` (no flow list) → exit 1: 'frontmatter dependencies must be a flow list such as [AVE-REQ-012]'
- Fixture: working file of AVE-REQ-001 with `id: AVE-REQ-999` → exit 1: 'frontmatter id 'AVE-REQ-999' must equal AVE-REQ-001'
- Checker copy with the tick rule removed → the suite exits 1: 'FAIL ticked criterion on a ready requirement fails', 100 of 101 (the suite holds the AC-4 tick rule)
- Branch head f894bbf (git archive copy): AVE-REQ-011 done on paper plus AVE-REQ-0110-follow-up.md → check-done exit 1 with four 'AVE-REQ-011 AC-n: missing in this run' lines (the shared reader of 4413e4a reads the ID from the whole file name)
```

### Cleanup

```text
Clone restored after every probe without git checkout, reset, stash or clean: modified files rewritten with `git show HEAD:<path> > <path>`, new files removed; before removal `git status --short` was empty, `git diff --quiet` succeeded and HEAD was 35f99c5. Probe helpers lived in the clone's gitignored var/critic/ and in the container's /tmp (fixtures, mutated checker copies, the f894bbf extract); both went with the clone and the container. Container stopped with `./scripts/dev-container.sh --stop` (exit 0; `--status` then reported `state absent`). Clone removed with `cd <repository> && rm -rf .claude/worktrees/redteam-critic-ave-req-093` (exit 0; the directory is gone). No commit, no push, no `git worktree prune`; nothing was written to the shared state volume beyond the clone's own backend environment that verify.sh creates.

Main checkout the main checkout: this review wrote nothing there. Its `git status --short` listed one modified file at my start (scripts/evidence.py) and lists 16 at my end (.claude/hooks/stop-verify.sh, backend/tests/evidence_plugin.py, backend/tests/unit/test_evidence_plugin.py, backend/tests/unit/test_rates.py, scripts/check-project-control.sh, scripts/evidence.py, scripts/lib/verify-state.sh, scripts/tests/run.sh, scripts/tests/test-checker.sh, scripts/tests/test-session-start.sh, scripts/tests/test-stop-hook.sh, scripts/tests/test-verify-tiers.sh, scripts/tests/test_evidence.py, scripts/verify.d/20-backend.sh, scripts/verify.d/95-evidence.sh, scripts/verify.sh); HEAD is f894bbf. Those edits come from another session working in the main checkout during this run; I neither made nor tested them.

Three run logs remain outside the repository in <session scratchpad>: 093critic-baseline-verify.log, 093critic-baseline-suite.log, 093critic-p2-verify.log.
```
