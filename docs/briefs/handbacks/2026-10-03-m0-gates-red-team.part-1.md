# Handback — M0 gates red-team, part 1: lenses 093-A, 093-B and 093-C

Brief: [2026-10-03-m0-gates-red-team.md](../2026-10-03-m0-gates-red-team.md). Run `wf_98f469f7-ec5` at `35f99c5` ([script](../../workflows/m0-gates-red-team-wf_98f469f7-ec5.js)). Each finder worked read-only in a private clone; the reports below are theirs, unedited apart from local paths. The lead's disposition closes each section.

## Lens 093-A

### Scope, method and probes without a finding

```text
093-A — working-file text: frontmatter keys and values, sections, criterion lines and ticks, the Status log, and the differences between four readers of one file: the Python parser of scripts\check_baseline.py, the awk parser of scripts\check-project-control.sh, the requirement reader of scripts\evidence.py (it decides the done gate that AVE-REQ-093's Verification strategy cites for AC-4), and a CommonMark reader. Findings below use paths relative to the main checkout.

Method: clone at 35f99c5. About 120 single-mutation probes ran through a driver kept in the clone's gitignored var/redteam/: it copied the clone tree to /tmp/rt inside the clone's container, applied one edit to docs/, and ran `python3 -B scripts/check_baseline.py` and `bash scripts/check-project-control.sh` there (plus `scripts/evidence.py check-done` or `show` where named). Every probe that passed was then repeated in the clone's working tree in four batches (files backed up to var/redteam/backup and copied back; `git status --short` empty after each). "Clone" below means the working tree; "driver copy" means /tmp/rt/case. The reader view comes from markdown-it-py 4.2.0 (commonmark preset), installed with `uv pip install --no-cache --target /tmp/mdit` inside the clone's container only.

Root cause shared by findings 1, 2, 3 and 6: one file has three mechanical readings. check_baseline.py: universal newlines (a lone CR ends a line), frontmatter closed by the first line whose Unicode-stripped text is `---`, last key wins, values unquoted, ticks `[xX]`, section name `line[3:].strip()`. awk: LF records only, delimiter trimmed of space and tab only, last key wins, indented lines join the previous key, values unquoted, heading compared exactly. evidence.py: the first line anywhere that starts with `status:`, no unquoting, ticks `[ x]` only, heading compared exactly.

Accepted by both gates and judged harmless: quoted values such as `status: "ready"` (the root of finding 1), CRLF line endings, `[U01,U24 , D01]` spacing, a quoted title with trailing spaces, sections in another order, trailing spaces or NBSP after a criterion, a whitespace-only line of NBSP and form feed between criteria, lines the parsers skip as non-keys (`status: deferred` with a Cyrillic letter in the key, behind an invisible BOM, or indented after `scenarios:`).

Not probed: `- [X]` on a criterion that has tagged tests (the unknown-tag rule of the pytest plugin and of `record` may stop that run); rendering in GitHub or a browser; the release tier end to end (the release step is exactly the `check-done` command run here, scripts/verify.d/95-evidence.sh:7-8). Today's working files contain none of the probed patterns (grep for quoted values, duplicate keys, CR, NBSP, `[X]`, change markers and done lines returned nothing).
```

### Baseline

```text
Clone at 35f99c5, before the first probe, `git status --short` empty.
- `./scripts/verify.sh` → exit 0, `verify.sh: PASS — tier fast (9 of 9 steps passed)`; Project control files `OK: 49 required files, 6 executable scripts, 5 agents, 9 skills, 2419 links in 196 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)`; Requirements baseline integrity `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`; Evidence manifest `Evidence: PASS — 36 criteria tagged`.
- `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` → exit 0, `BASELINE TOTAL: pass=101 fail=0`.
- `./scripts/dev-container.sh python3 -B scripts/check_baseline.py` → exit 0, `by status: proposed 3, ready 84, in-progress 15, deferred 2`, `Acceptance criteria ticked: 0 of 404 (version one: 0 of 398)`, `OK: baseline intact; ...`.
The suite holds no case for any finding above (read in full: no duplicate key, quoted value, non-ASCII delimiter, lone CR, HTML comment, empty or indented heading, uppercase tick, or superseded-with-ticks case).
```

### Finding 093-A-1 (blocking) — The done gate reads status and ticks with its own parser: a done requirement ticked `- [X]` or written `status: "done"` passes check-done with no evidence

Criterion: AVE-REQ-093 AC-4 (Verification strategy: "`scripts/evidence.py check-done` (release tier) refuses a `done` requirement without this run's evidence"); AVE-REQ-097 AC-4

Reproduction:

```text
In the clone, after the baseline `./scripts/verify.sh` (it leaves a run directory in var/verify/runs/):

./scripts/dev-container.sh python3 - <<'EOF'
import glob
DASH = chr(0x2014)
path = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
t = t.replace("status: ready\n", "status: done\n", 1).replace("- [ ] AC-", "- [X] AC-")
t = "\n".join("- recorded." if line.startswith("_TBD") else line for line in t.split("\n"))
t += "- 2026-10-06 %s done %s verify-requirement PASS (lead)\n" % (DASH, DASH)
open(path, "w", encoding="utf-8", newline="").write(t)
trace = "docs/TRACEABILITY.md"
t = open(trace, encoding="utf-8", newline="").read()
sep = "|---|---|---|---|---|---|\n"
row = "| [AVE-REQ-001](requirements/%s) | done | x | x | x | x |\n" % path.split("/")[-1]
assert t.count(sep) == 1
open(trace, "w", encoding="utf-8", newline="").write(t.replace(sep, sep + row, 1))
EOF
./scripts/dev-container.sh bash scripts/check-project-control.sh
./scripts/dev-container.sh python3 -B scripts/check_baseline.py | tail -5
./scripts/dev-container.sh python3 -B scripts/evidence.py check-done --dir "$(ls -d var/verify/runs/*/ | tail -1)"
./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-001 --require-complete

Control, then the quoted variant:
./scripts/dev-container.sh bash -c 'sed -i "s/^- \[X\] AC-/- [x] AC-/" docs/requirements/AVE-REQ-001-*.md'
./scripts/dev-container.sh python3 -B scripts/evidence.py check-done --dir "$(ls -d var/verify/runs/*/ | tail -1)"
./scripts/dev-container.sh bash -c 'sed -i "s/^status: done$/status: \"done\"/" docs/requirements/AVE-REQ-001-*.md'
(then the three gate commands again)

Driver copy, same done state with one change each: `status: 'done'`; a line `status: in-progress` above `status: done`; a line `note: x<U+2028>status: ready` above `status: done`.
```

Observed:

```text
`- [X]` ticks (clone): check-project-control `OK: 49 required files, ... 134 requirement files, 9 ADRs; 0 warning(s)` exit 0. check_baseline `by status: proposed 3, ready 83, in-progress 15, done 1, deferred 2`, `Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)`, `OK: baseline intact; ...` exit 0. check-done `OK: every criterion of the 1 done requirements is evidenced by this run` exit 0. `show AVE-REQ-001 --require-complete` prints `AVE-REQ-001 (done)` with no criterion line, exit 0. AVE-REQ-001 has no implementation and no tagged test.

Control with `- [x]` (clone): `ERROR: AVE-REQ-001 AC-1: missing in this run` (and AC-2, AC-3, AC-4), `FAIL: 4 criteria of done requirements lack evidence in this run`, exit 1.

`status: "done"` with `- [x]` (clone): both checkers exit 0, check_baseline still counts `done 1`; check-done `OK: every criterion of the 0 done requirements is evidenced by this run` exit 0.

Driver copy: single-quoted status, the duplicate status key and the U+2028 line each give check-done exit 0 with `0 done requirements` while both checkers pass and count `done 1`.

Cause: scripts/evidence.py:118-134 takes the first line anywhere that starts with `status:` and does not unquote; scripts/evidence.py:83 `_AC_LINE = ^- \[[ x]\] (AC-\d+)\b` has no `X`. scripts/check_baseline.py:67,119-124 and the awk parser accept `[xX]`, unquote, and let the last key win.
```

Expected:

```text
check-done exits 1 with the four `missing in this run` errors for every file that check_baseline.py and check-project-control.sh accept as `done`.
```

Fix:

```text
Smallest: evidence.py reads status and criteria the way check_baseline.py does (the frontmatter block only, unquoted, `[xX]`), ideally through one shared reader; or both checkers reject `[X]`, quoted values and duplicate keys so only one spelling exists. Cases in scripts/tests/test_evidence.py: "done requirement ticked `- [X]` without evidence fails check-done", "`status: \"done\"` without evidence fails check-done", "a second status line does not hide a done requirement".
```

Lead's disposition: fixed. `scripts/evidence.py` reads requirement files through `scripts/reqfile.py`, the reader of `scripts/check_baseline.py`, and `check-done` and `show` fail on a file outside the canonical form; a capital-X tick, a quoted status and a repeated status key are outside that form. Cases: `scripts/tests/test_evidence.py` (nine spellings that hid `done` or a criterion), `scripts/tests/test-check-baseline.sh` section (b).

### Finding 093-A-2 (blocking) — The two checkers place the end of the frontmatter differently (`---` plus NBSP or form feed, lone CR): check_baseline.py never sees the status that check-project-control.sh validates

Criterion: AVE-REQ-093 AC-3 and AC-4 (Edge cases: "A future requirement made ready, or a version-one requirement deferred → fails"; "A version-one requirement superseded by a requirement that ... has a lower priority, or drops a baseline criterion ... → fails"; "A baseline feature or epic set to `superseded` while a baseline child under it is not superseded → fails"; "A criterion ticked on a requirement that never reached `done` → fails")

Reproduction:

```text
In the clone:

./scripts/dev-container.sh python3 - <<'EOF'
import glob
NBSP = chr(0xA0); DASH = chr(0x2014)
def edit(pattern, extra_keys, log):
    path = glob.glob("docs/requirements/" + pattern)[0]
    text = open(path, encoding="utf-8", newline="").read()
    head, rest = text.split("\n---\n", 1)          # the closing --- of the frontmatter
    text = head + "\n---" + NBSP + "\n" + extra_keys + "---\n" + rest + log
    open(path, "w", encoding="utf-8", newline="").write(text)
edit("AVE-REQ-001-*.md", "status: deferred\n", "- 2026-10-06 %s deferred %s moved out of version one (lead)\n" % (DASH, DASH))
edit("AVE-REQ-067-*.md", "status: ready\n", "- 2026-10-06 %s ready %s pulled into version one (lead)\n" % (DASH, DASH))
edit("AVE-REQ-003-*.md", "status: superseded\nsuperseded_by: AVE-REQ-102\n", "- 2026-10-06 %s superseded %s replaced by AVE-REQ-102 (lead)\n" % (DASH, DASH))
edit("AVE-EPIC-01-*.md", "status: superseded\nsuperseded_by: AVE-REQ-102\n", "- 2026-10-06 %s superseded %s retired (lead)\n" % (DASH, DASH))
EOF
./scripts/verify.sh
grep -H -e '^status:' -e '^superseded_by:' docs/requirements/AVE-REQ-001-*.md docs/requirements/AVE-REQ-067-*.md docs/requirements/AVE-REQ-003-*.md docs/requirements/AVE-EPIC-01-*.md

The frontmatter of AVE-REQ-001 then ends `baseline: ...AVE-REQ-001.md` / `---<NBSP>` / `status: deferred` / `---`.

Driver copy, one edit each on AVE-REQ-001 unless named: the same with `---<FF>`; `<NBSP>---` with `priority: could` behind it; `status: deferred` plus `scope: v1<CR>status: ready` (lone CR) and a deferred log line; `status: done` in the first block, `---<NBSP>`, `status: ready`, `---`, every criterion ticked, no done log line. Controls: each of the four clone edits written as one plain frontmatter; the `---<NBSP>` split with `status: deferred` behind it and no new log line.
```

Observed:

```text
Clone: `verify.sh: PASS — tier fast (9 of 9 steps passed)`, exit 0. Step output: `OK: 49 required files, ... 134 requirement files, 9 ADRs; 0 warning(s)` and `by status: proposed 3, ready 84, in-progress 15, deferred 2` (unchanged from the baseline), `Acceptance criteria ticked: 0 of 404`, `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`. grep shows `status: ready` then `status: deferred` for AVE-REQ-001, `deferred` then `ready` for AVE-REQ-067, `ready` then `superseded` + `superseded_by: AVE-REQ-102` for AVE-REQ-003 (a must, human requirement; AVE-REQ-102 is a derived `should` requirement that carries none of its criteria), `in-progress` then `superseded` for AVE-EPIC-01 whose features all live.

Controls (driver copy): split without the log line → check-project-control `newest Status-log line records 'ready' but frontmatter status is 'deferred'`, so the awk parser reads `deferred` while check_baseline passes. Plain frontmatter: AVE-REQ-067 `future-scope requirement must stay deferred (status 'ready')`; a plain supersession `AC-1 of the baseline is absent from the successor ...`; AVE-EPIC-01 `a baseline epic is superseded only when every baseline feature under it is superseded (AVE-FEAT-001 is 'in-progress')`; `status: deferred` as the last key `version-one requirement cannot be deferred (baseline scope v1)`.

Variants (driver copy): form feed, leading NBSP and the lone-CR form all pass both gates. The reverse split passes both gates with `by status: ... done 1` and `Acceptance criteria ticked: 4 of 404` while the awk parser reads `ready` and the Status log holds no done line.

Reading: the first-wins readers (evidence.py, `grep -m1`) agree with check_baseline here; the hidden value is the one check-project-control.sh holds against the Status log and the TRACEABILITY row.

Cause: scripts/check_baseline.py:110 `read_text` translates a lone CR into a line end and :114-116 closes the block on `lines[index].strip() == "---"` (Unicode whitespace); scripts/check-project-control.sh:268-279 reads LF records and trims space and tab only.
```

Expected:

```text
Each of the four edits fails check_baseline.py with the message its plain-frontmatter control gets; a requirement file has one frontmatter that both checkers read identically.
```

Fix:

```text
check_baseline.py opens the file with `newline=""`, fails on a lone CR, closes the frontmatter only on a line that equals `---` after removing spaces and tabs, and fails on a frontmatter line that is no `key: value` and on a non-blank line between the closing `---` and the H1; the awk parser fails on a non-key, non-indented line inside the frontmatter. Cases in scripts/tests/test-check-baseline.sh: "frontmatter closed by ---<NBSP> with a second status fails", "lone CR inside the frontmatter fails"; in scripts/tests/test-checker.sh: "non-key line inside the frontmatter fails".
```

Lead's disposition: fixed. The canonical form admits line feeds only and no character of the Unicode classes control, format, line separator or space other than U+0020; the frontmatter closes on a line that equals `---`, and one blank line and the H1 follow it. Cases: no-break space, form feed, lone carriage return, second block, line separator, byte-order mark.

### Finding 093-A-3 (blocking) — Duplicate frontmatter keys: both checkers read the last value, the milestone-review command and evidence.py read the first

Criterion: AVE-REQ-093 AC-3 (Edge cases: "A future requirement made ready, or a version-one requirement deferred → fails"; "a changed identity (title, type, priority, scope, ...) → the baseline check fails")

Reproduction:

```text
In the clone, one combined mutation of six files (findings 7 to 10 cite it as "the combined run"):

./scripts/dev-container.sh python3 - <<'EOF'
import glob
DASH = chr(0x2014); TICK = chr(96)
def load(pattern):
    path = glob.glob("docs/requirements/" + pattern)[0]
    return path, open(path, encoding="utf-8", newline="").read()
def save(path, text):
    open(path, "w", encoding="utf-8", newline="").write(text)
def log(date, status, reason):
    return "- %s %s %s %s %s\n" % (date, DASH, status, DASH, reason)
def lines_of(text, prefix):
    return [l for l in text.split("\n") if l.startswith(prefix)]
# AVE-REQ-005 (ready): every criterion ticked; a done line dated 0000-00-00 as the first Status line
p, t = load("AVE-REQ-005-*.md")
save(p, t.replace("- [ ] AC-", "- [x] AC-").replace("## Status\n", "## Status\n" + log("0000-00-00", "done", "x"), 1))
# AVE-REQ-006: AC-2 replaced; the only log line quotes the rule with its placeholder
p, t = load("AVE-REQ-006-*.md")
ac2 = lines_of(t, "- [ ] AC-2 ")[0]
save(p, t.replace(ac2, "- [ ] AC-2 Filtering works on a best-effort basis.", 1)
     + log("2026-10-06", "ready", "the checker requires " + TICK + "AC-2 changed: <reason>" + TICK + " lines (lead)"))
# AVE-REQ-007: a deferred line dated 2026-12-31 above the last (ready) line
p, t = load("AVE-REQ-007-*.md")
last = lines_of(t, "- 2026-10-01 ")[-1]
save(p, t.replace(last, log("2026-12-31", "deferred", "out of version one (lead)") + last, 1))
# AVE-REQ-008: duplicate keys, the demoting value first
p, t = load("AVE-REQ-008-*.md")
save(p, t.replace("status: ready\n", "status: deferred\nstatus: ready\n", 1)
     .replace("priority: must\n", "priority: could\npriority: must\n", 1)
     .replace("scope: v1\n", "scope: future\nscope: v1\n", 1))
# AVE-REQ-009: AC-1 replaced; the AC-1 changed line sits inside an HTML comment at the top of Status
p, t = load("AVE-REQ-009-*.md")
ac1 = lines_of(t, "- [ ] AC-1 ")[0]
save(p, t.replace(ac1, "- [ ] AC-1 Broken media is reported when convenient.", 1)
     .replace("## Status\n", "## Status\n<!--\n" + log("2026-10-06", "ready", "AC-1 changed: wording (lead)") + "-->\n", 1))
# AVE-FEAT-001: the AVE-REQ-002 link leaves Requirements and appears under Out of scope
p, t = load("AVE-FEAT-001-*.md")
link = [l for l in t.split("\n") if "](AVE-REQ-002-" in l][0]
save(p, t.replace(link + "\n", "", 1).replace("## Out of scope\n", "## Out of scope\n" + link + ": dropped from version one.\n", 1))
EOF
./scripts/dev-container.sh bash scripts/check-project-control.sh
./scripts/dev-container.sh python3 -B scripts/check_baseline.py | tail -7
grep -H -m1 '^status:' docs/requirements/AVE-REQ-008-*.md
./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-008

This finding is the AVE-REQ-008 edit. Driver copy: each duplicate alone on AVE-REQ-001 (status, priority, scope, origins), and the control with `status: deferred` as the later key.
```

Observed:

```text
Clone, all six edits applied: check-project-control `OK: 49 required files, ... 134 requirement files, 9 ADRs; 0 warning(s)` exit 0; check_baseline `by status: proposed 3, ready 84, in-progress 15, deferred 2`, `OK: baseline intact; ...` exit 0. AVE-REQ-008 holds line 5 `status: deferred`, 6 `status: ready`, 7 `priority: could`, 8 `priority: must`, 11 `scope: future`, 12 `scope: v1`. The command of .claude/skills/milestone-review/SKILL.md:49 prints `...AVE-REQ-008-reviewable-accidental-recording-detection.md:status: deferred`; `evidence.py show AVE-REQ-008` prints `AVE-REQ-008 (deferred)`.

Driver copy: each duplicate alone passes both gates; the control with `status: deferred` last fails with `version-one requirement cannot be deferred (baseline scope v1)`.

Cause: scripts/check_baseline.py:124 `self.fm[match.group(1)] = value` and the awk `fm[fi, key] = ...` overwrite silently; README § Frontmatter states "one `key: value` per line" and no check enforces it.
```

Expected:

```text
A repeated frontmatter key fails both checkers, so the value the gates accept is the value every reader of the file gets.
```

Fix:

```text
Both parsers report `duplicate frontmatter key <key>` (Working.__init__ in scripts/check_baseline.py, fm_parse in scripts/check-project-control.sh). Cases: scripts/tests/test-check-baseline.sh "duplicate status key fails", "duplicate priority key fails", "duplicate scope key fails"; scripts/tests/test-checker.sh "duplicate frontmatter key fails".
```

Lead's disposition: fixed. A repeated frontmatter key fails in the reader (and in `scripts/check-project-control.sh`, case "repeated frontmatter key"); keys follow the template's order and unknown keys fail.

### Finding 093-A-4 (blocking) — An HTML comment hides the verbatim Description and criteria; the rendered file shows a rewritten Description and a waiver inside § Acceptance criteria, and the checker reports no change

Criterion: AVE-REQ-093 AC-3 (Edge cases: "A criterion or the Description reworded or removed ... without a logged reason → fails"; "nothing can qualify or waive a criterion in place"; README § Baseline import and integrity rule 4)

Reproduction:

```text
In the clone (the AVE-REQ-002 edit belongs to finding 5):

./scripts/dev-container.sh python3 - <<'EOF'
import glob
WAIVER = "AC-2 and AC-4 are informational for version one: best-effort persistence is enough."
# AVE-REQ-001: the verbatim Description and criteria move into an HTML comment (opened at the end of
# Intent, closed at the start of Edge cases); visible copies follow under setext headings with a waiver.
path = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
desc = t.split("\n## Description\n", 1)[1].split("\n\n## Acceptance criteria\n", 1)[0]
crit = t.split("\n## Acceptance criteria\n", 1)[1].split("\n\n## Edge cases\n", 1)[0]
t = t.replace("\n## Description\n", "\n<!--\n\n## Description\n", 1)
visible = ("-->\n\nDescription\n-----------\nThe application may keep editing projects.\n\n"
           "Acceptance criteria\n-------------------\n" + crit + "\n\n" + WAIVER + "\n\nEdge cases\n----------\n")
t = t.replace("## Edge cases\n", "## Edge cases\n" + visible, 1)
open(path, "w", encoding="utf-8", newline="").write(t)
# AVE-REQ-002: an empty ATX heading ("## " and nothing else) after the last criterion, then a waiver.
path = glob.glob("docs/requirements/AVE-REQ-002-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
t = t.replace("\n\n## Edge cases\n", "\n## \nAC-1 is informational for version one: importing one clip at a time is enough.\n\n## Edge cases\n", 1)
open(path, "w", encoding="utf-8", newline="").write(t)
EOF
./scripts/dev-container.sh bash scripts/check-project-control.sh
./scripts/dev-container.sh python3 -B scripts/check_baseline.py | tail -4

Reader view: the file body after the frontmatter parsed with markdown-it-py 4.2.0 `MarkdownIt("commonmark").parse(...)`, text grouped under each H1/H2 (helper var/redteam/view.py, removed with the clone).

Driver copy: the same hiding with two weakened criteria as the only visible ones.
```

Observed:

```text
Clone: check-project-control `OK: ...` exit 0; check_baseline `Acceptance criteria ticked: 0 of 404 (version one: 0 of 398)`, `OK: baseline intact; ...` exit 0, no `Recorded change` line.

Reader view of AVE-REQ-001: headings `H1 'AVE-REQ-001 — Persistent projects and project settings' | H2 'Intent' | H2 'Description' | H2 'Acceptance criteria' | H2 'Edge cases' | ...`; section 'Description': `The application may keep editing projects.`; section 'Acceptance criteria': the four criteria followed by `AC-2 and AC-4 are informational for version one: best-effort persistence is enough.`

Driver copy: with the visible criteria reduced to `AC-1 A new project opens an empty collection.` and `AC-2 Saved projects are restored on a best-effort basis.`, both gates pass and the reader sees only those two.

The raw file still holds the verbatim text between `<!--` and `-->`, so a reviewer of the raw text or the diff can see it; the mechanical guard cannot. Neither requirement parser knows HTML comments or setext headings (scripts/check_baseline.py:130-150; scan_requirement in scripts/check-project-control.sh:593-608), although the link check of the same script strips comments.
```

Expected:

```text
check_baseline.py fails: the Description and the criteria a Markdown reader gets differ from the baseline with no logged reason, and a waiver stands inside the rendered § Acceptance criteria.
```

Fix:

```text
Smallest: check_baseline.py fails on `<!--` anywhere in a working requirement file (the import writes none); alternatively the parser drops commented text before it reads the Description, the criteria and the Status log. Cases in scripts/tests/test-check-baseline.sh: "baseline criteria inside an HTML comment fail", "Description inside an HTML comment fails".
```

Lead's disposition: fixed. A working file holds no HTML comment and no line that starts with `<`; cases for a comment around the criteria and one in the Status log.

### Finding 093-A-5 (blocking) — A done requirement with unticked criteria passes check-project-control.sh, and criteria without evidence disappear from `evidence.py show --require-complete`, through a lone CR or a `##  Acceptance criteria` heading

Criterion: AVE-REQ-093 AC-4 (README § Enforced checks item 10: "a `done` REQ with an unticked AC or a `_TBD` marker" fails); AVE-REQ-097 AC-4 (`show --require-complete`)

Reproduction:

```text
In the clone, continuing from the quoted-status state of finding 1 (AVE-REQ-001 done, matrix row present):

./scripts/dev-container.sh python3 - <<'EOF'
import glob
path = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
t = t.replace('status: "done"\n', "status: done\n", 1)
for n in "234":
    t = t.replace("- [x] AC-" + n, "- [ ] AC-" + n)
open(path, "w", encoding="utf-8", newline="").write(t)
EOF
./scripts/dev-container.sh bash scripts/check-project-control.sh      # control
./scripts/dev-container.sh python3 - <<'EOF'
import glob
path = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(path, encoding="utf-8", newline="").read()
for n in "234":
    t = t.replace("\n- [ ] AC-" + n, chr(13) + "- [ ] AC-" + n)
open(path, "w", encoding="utf-8", newline="").write(t)
EOF
./scripts/dev-container.sh bash scripts/check-project-control.sh
./scripts/dev-container.sh python3 -B scripts/check_baseline.py | tail -3

Driver copy: (a) AVE-REQ-001 done, `- [x] AC-1` under `## Acceptance criteria`, then a line `##  Acceptance criteria` (two spaces) above the unticked AC-2 to AC-4; (b) AVE-REQ-097 with AC-2 and AC-4 under `## Acceptance criteria` and AC-1 and AC-3 under `##  Acceptance criteria`, then `python3 -B scripts/evidence.py show AVE-REQ-097 --require-complete`; (c) a done requirement with a `_TBD:` line inside a fenced block.
```

Observed:

```text
Clone control: `ERROR: docs/requirements/AVE-REQ-001-persistent-projects-and-project-settings.md: status done but 3 acceptance criterion line(s) are unticked`, `FAILED: 1 error(s)`, exit 1. With the four criterion lines joined by lone CR: check-project-control `OK: ...` exit 0; check_baseline `Acceptance criteria ticked: 1 of 404 (version one: 1 of 398)`, `OK: baseline intact; ...` exit 0.

Driver copy: (a) both gates exit 0 with `done 1` and `ticked: 1 of 404`. (b) on the unchanged file `show AVE-REQ-097 --require-complete` lists `AC-1 missing`, `AC-2 passed`, `AC-3 missing`, `AC-4 passed` and exits 1; after the move both checkers exit 0 and the command lists only `AC-2 passed` and `AC-4 passed` and exits 0. (c) both checkers exit 0.

Cause: the awk parser sees the CR-joined lines as one ticked list record and compares the heading exactly (scripts/check-project-control.sh:597-602); check_baseline merges every section whose `line[3:].strip()` is `Acceptance criteria` (scripts/check_baseline.py:144-147); evidence.py compares `line.strip()` with the heading (scripts/evidence.py:107-115); the `_TBD` test skips fenced lines.
```

Expected:

```text
The CR-joined file and the two-heading file fail check 10; `show --require-complete` exits 1 while a criterion of the requirement has no evidence.
```

Fix:

```text
check_baseline.py accepts a section heading only when the line equals `## <name>` and fails on a second section of the same name and on a lone CR (the fix of finding 2); evidence.py takes its criteria from the same reader. Cases: scripts/tests/test-checker.sh "done with unticked criteria joined by CR fails"; scripts/tests/test-check-baseline.sh "`##  Acceptance criteria` heading fails"; scripts/tests/test_evidence.py "criteria under a second criteria heading still need evidence".
```

Lead's disposition: fixed. Carriage returns fail; every template heading stands once, written exactly, so a second or re-spaced criteria heading fails and the done gate lists every criterion; `check_baseline.py` fails a `done` requirement that holds `_TBD` anywhere, fenced text included.

### Finding 093-A-6 (blocking) — Ticks without done: a superseded requirement, or any `done` line in the Status log (any date, any position, inside an HTML comment), lets every criterion be ticked

Criterion: AVE-REQ-093 AC-4 (Edge case: "A criterion ticked on a requirement that never reached `done` → fails"; Verification strategy AC-4: "a ticked criterion on a requirement that never reached `done` fails")

Reproduction:

```text
Clone: the AVE-REQ-005 edit of the combined run in finding 3 (status stays `ready`, every criterion `- [x]`, `- 0000-00-00 — done — x` inserted as the first Status line).

Driver copy on AVE-REQ-001: (a) the done line inside `<!--` / `-->` at the top of `## Status`; (b) `status: superseded`, `superseded_by: AVE-REQ-002`, every criterion ticked, one appended line `- 2026-10-06 — superseded — AC-1 changed: x; AC-2 changed: x; AC-3 changed: x; AC-4 changed: x`; controls: ticks with no done line; ticks with a `ready` line whose reason starts with `done —`.
```

Observed:

```text
Clone: both gates exit 0; check_baseline `by status: proposed 3, ready 84, in-progress 15, deferred 2` and `Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)` with AVE-REQ-005 `ready`.

Driver copy: (a) passes with `ticked: 4 of 404`. (b) passes with `by status: proposed 3, ready 83, in-progress 15, superseded 1, deferred 2`, `ticked: 4 of 404`, and `Recorded change: AVE-REQ-001 AC-1 is absent from the successor AVE-REQ-002 — x; AC-2 changed: x; AC-3 changed: x; AC-4 changed: x` plus one such line for AC-2, AC-3 and AC-4: a must requirement that never reached done is retired with four ticks by one log line. Controls fail with `AC-1 is ticked while status is 'ready' and the Status log has no done line`.

Cause: scripts/check_baseline.py:597 allows ticks for `status in ("done", "superseded")` or any `done` word found by STATUS_LINE (`^- \d{4}-\d{2}-\d{2} — ([a-z-]+) — `) in the log, with no date, order or comment check. README rule 4 names the superseded exemption; the requirement's Edge case and Verification strategy state the rule without it, so the sentence is false as written. The fabricated done line by itself is boundary grade (a false log entry that the diff shows).
```

Expected:

```text
Per the Edge case: both forms fail. At least the sentence matches the implemented rule.
```

Fix:

```text
Smallest: a superseded requirement keeps ticks only with a `done` line in its log, and the Edge-case and Verification-strategy sentences name the rule as implemented. Tighter: log lines carry a valid calendar date in non-decreasing order and lines inside HTML comments do not count (finding 4). Cases in scripts/tests/test-check-baseline.sh: "superseded requirement with ticks and no done line fails", "done line dated 0000-00-00 fails".
```

Lead's disposition: fixed. Ticks stand only while the status is `done`, or `superseded` with a `done` line in the log; Status lines carry real, non-decreasing dates and comments are gone. The fabricated `done` line that precedes a supersession stays log text judged at commit review (stated in § Edge cases).

### Finding 093-A-7 (boundary) — Headings the parsers do not know place a waiver directly under the criteria or in a second rendered Acceptance criteria section

Criterion: AVE-REQ-093 AC-3 (Edge case: "Text inside § Acceptance criteria that is no criterion line ... → fails: the section holds criterion lines only, so nothing can qualify or waive a criterion in place"; the free-text limit names Intent, Edge cases, Verification strategy and the evidence sections only)

Reproduction:

```text
Clone: the AVE-REQ-002 edit in the heredoc of finding 4 (a line `## ` with nothing after the space, directly after AC-4, followed by `AC-1 is informational for version one: importing one clip at a time is enough.`), then both checkers and the reader view.

Driver copy on AVE-REQ-001, one edit each: `## <!-- -->` after AC-4 followed by a list-item waiver; `## ` after the Description followed by `Persistence is optional in version one.`; a new section `## Scope note` holding ` ## Acceptance criteria` (one leading space) and a waiver, placed before the real section; a setext heading `Acceptance criteria` / `-------------------` plus waiver inside Edge cases; `<h2>Acceptance criteria</h2>` and `### Acceptance criteria` with waivers inside Edge cases; `<!--` / three backticks / `-->` before and after a block `## Acceptance criteria` + `- [ ] AC-2 Saved projects are restored on a best-effort basis.` in Intent; the same block between two lines of three backticks followed by ` a`b`.
```

Observed:

```text
Clone: both gates exit 0. Reader view of AVE-REQ-002: `H2 'Acceptance criteria'` with the four criteria, then `H2 ''` holding `AC-1 is informational for version one: importing one clip at a time is enough.`, then `H2 'Edge cases'`. check_baseline ends the section at any column-0 `## ` line (scripts/check_baseline.py:144); the awk parser strips the trailing space, sees no heading and checks list items only.

Driver copy: every listed edit passes both gates. Reader headings for the indented-ATX, setext and both fence forms show two `H2 'Acceptance criteria'`, one of them holding the waiver or the weakened AC-2; the fence forms work because both parsers treat any line starting with three backticks as a fence toggle, also inside an HTML comment or with a backtick in the info string, where CommonMark opens no fence.

Held in the same family: ` ## Notes` (indented) + note after the criteria, `<h2>Notes</h2>`, a second H1, `<details>`, an HTML comment line and a `## ` between AC-1 and AC-2 all fail.
```

Expected:

```text
The documents claim a mechanical guard for notes "in place"; a heading outside the template set, an empty heading, or a second heading reading Acceptance criteria in any Markdown form fails, or the limit is stated.
```

Fix:

```text
check_baseline.py fails on an H2 that is no template heading of README § Templates (the empty one included), recognises ATX headings with up to three leading spaces, setext underlines and `<h1>` to `<h6>`, and opens a fence only where CommonMark does. Cases in scripts/tests/test-check-baseline.sh: "empty heading after the criteria fails", "indented Acceptance criteria heading in another section fails", "setext Acceptance criteria heading fails". Otherwise extend the free-text Edge case to every section other than Description and Acceptance criteria, whatever its heading.
```

Lead's disposition: fixed for every listed form: template headings only, written at column 0; indented, underlined, HTML, list-item and quote headings, empty headings and irregular fences fail. Bold text that imitates a heading stays free text (stated in § Edge cases).

### Finding 093-A-8 (boundary) — Recorded-change lines: the rule's own placeholder, another requirement's ID, or a line inside an HTML comment counts as the logged reason

Criterion: AVE-REQ-093 AC-3 (Edge case: "reworded or removed ... without a logged reason → fails; with a logged reason → reported")

Reproduction:

```text
Clone: the AVE-REQ-006 and AVE-REQ-009 edits of the combined run in finding 3.

Driver copy on AVE-REQ-001 with AC-2 changed to `...project metadata are mostly unchanged.`: a log line `- 2026-10-02 — ready — see AVE-REQ-002 AC-2 changed: tracked there (lead)`; the Description replaced by `The application may keep editing projects.` with a log line that only quotes `Description changed: <reason>` in backticks; AC-2 to AC-4 deleted with one line `AC-2 changed: x; AC-3 changed: x; AC-4 changed: x`; the log line under `##  Status` (two spaces) right after the H1; the log line joined to the previous one by a lone CR.
```

Observed:

```text
Clone: both gates exit 0 and check_baseline prints `Recorded change: AVE-REQ-006 AC-2 differs from the baseline text — <reason>` lines (lead)` (the reason is the placeholder of the quoted rule) and `Recorded change: AVE-REQ-009 AC-1 differs from the baseline text — wording (lead)` (the line sits between `<!--` and `-->`).

Driver copy: every listed form passes with a `Recorded change` line; the three deletions are covered by the single line (`ticked: 0 of 401`).

Held: no log line; hyphens instead of em dashes; the line inside a fenced block; the line under a setext `Status` heading in Edge cases; a reason of NBSP only.

The change is reported each time, so the stated behaviour holds; the reason is free text. A Status-log line that merely documents the rule for criterion n unlocks that criterion (scripts/check_baseline.py:200-210 searches the marker anywhere in the line).
```

Expected:

```text
Reported, as documented; a quoted rule or a line no reader sees should not count as the reason.
```

Fix:

```text
`recorded_change` requires the marker at the start of the reason field (`— AC-n changed: <reason>` directly after the status field) and rejects a reason that starts with `<`; commented lines do not count. Cases in scripts/tests/test-check-baseline.sh: "log line quoting the rule does not count", "marker behind another requirement ID does not count".
```

Lead's disposition: fixed. A marker opens the log line's text, covers one change, rejects the placeholder reason and carries a digest of the text it covers. The reason itself stays free text.

### Finding 093-A-9 (boundary) — The "newest" Status-log line is the last one by position; dates and order are unchecked

Criterion: AVE-REQ-093 AC-3 (README § Enforced checks item 9: "one whose newest log line records a status other than the frontmatter `status`"; § Status lifecycle rule 1)

Reproduction:

```text
Clone: the AVE-REQ-007 edit of the combined run in finding 3 (`- 2026-12-31 — deferred — out of version one (lead)` inserted above the last line, which is dated 2026-10-01 and reads `ready`).

Driver copy on AVE-REQ-001: a last line dated `9999-99-99`; an appended visible line `- 2026-10-06 — deferred — moved out of version one (lead)` followed by `<!--` / `- 2026-10-06 — ready — x` / `-->`.
```

Observed:

```text
Clone and driver copy: both gates exit 0 in every form. In the third form a Markdown reader gets `deferred` as the newest log line of a version-one requirement whose frontmatter says `ready`; the awk parser compares the commented line (scripts/check-project-control.sh:603-606, 657-666).
```

Expected:

```text
Item 9 as written fails a file whose newest dated line records another status.
```

Fix:

```text
The awk check validates the date, requires non-decreasing dates and ignores lines inside HTML comments; or item 9 says "last". Case in scripts/tests/test-checker.sh: "Status-log dates out of order fail".
```

Lead's disposition: fixed. The reader validates each date and requires dates that never decrease; § Status holds log lines only.

### Finding 093-A-10 (boundary) — The parent-link test is a whole-file substring: a child listed under Out of scope or inside an HTML comment satisfies "§ Requirements must link"

Criterion: AVE-REQ-093 AC-1 and AC-3 (check b of scripts/check_baseline.py: "each parent lists its baseline children"; suite case "feature no longer lists its requirement")

Reproduction:

```text
Clone: the AVE-FEAT-001 edit of the combined run in finding 3 (the AVE-REQ-002 line leaves `## Requirements` and appears under `## Out of scope` as `...: dropped from version one.`).

Driver copy: the same line wrapped in `<!-- ... -->` in place; control: the line removed.
```

Observed:

```text
Clone: both gates exit 0. Driver copy: the commented link passes check_baseline (the link count of check-project-control drops from 2419 to 2418, with no error); the control fails with `§ Requirements must link AVE-REQ-002-collection-based-batch-ingestion.md`.

Cause: scripts/check_baseline.py:360-361 tests `f"]({child.path.name})" in parent.text`.
```

Expected:

```text
A feature that lists a version-one requirement only as out of scope, or only inside a comment, fails.
```

Fix:

```text
`lists_child` reads the list items of `## Requirements` (features) and `## Features` (epics) outside comments. Case in scripts/tests/test-check-baseline.sh: "requirement link moved to Out of scope fails".
```

Lead's disposition: fixed. A parent links its child from a list item of its own list section (`## Requirements` or `## Features`); case "requirement link moved to Out of scope fails".

### Probes the gates rejected

```text
- `status: deferred` as the later duplicate key on a version-one requirement → check_baseline: version-one requirement cannot be deferred; awk: newest Status-log line records 'ready'
- `Priority: should` (capitalised key) in place of the priority key → check_baseline: priority '' must equal 'must'; awk: priority is missing
- `priority: Must` → both reject the value
- `status: deferred<NBSP>` → check_baseline: version-one requirement cannot be deferred; awk: invalid status 'deferred '
- `scope: v1<zero-width space>` → check_baseline: scope must equal 'v1'
- `priority: must` with a Cyrillic look-alike letter → both reject the value
- Byte-order mark at the start of the file, with and without a demoted priority → awk: missing frontmatter; check_baseline: every key ''
- Whole file with lone-CR line endings plus `priority: should` → check_baseline: priority 'should' must equal 'must'; awk: missing frontmatter
- Closing `---` removed → awk: unterminated frontmatter (check_baseline alone passes)
- `status: ready` followed by an indented line `deferred` → awk: invalid status 'ready deferred' (check_baseline alone passes)
- `status: >` with the value on an indented line → check_baseline: invalid status '>' (awk alone passes)
- `status: ready # deferred` → both: invalid status
- NUL byte inside the status value → both: invalid status
- Invalid UTF-8 byte in the file → check_baseline exits 1 with an uncaught UnicodeDecodeError traceback and no ERROR line (fails closed); awk passes
- Emptied working file → awk: file is empty; check_baseline: every identity error
- Second `## Acceptance criteria` section holding a waiver sentence → § Acceptance criteria holds a line that is no criterion
- `## Acceptance Criteria` (capital C) → AC-1 to AC-4 missing; awk: missing heading
- ` ## Notes` (indented heading) plus a note right after the criteria → both lines flagged as no criterion
- `## ` (empty heading) between AC-1 and AC-2 → AC-2 to AC-4 missing
- HTML comment line inside the criteria section → flagged as no criterion
- `##<TAB>Acceptance criteria` → criteria missing and Description differs
- `## Acceptance criteria<NBSP>` → awk: missing heading (check_baseline alone passes)
- `## Acceptance criteria ##` (closed ATX heading) → criteria missing
- `<details>` block, `<h2>Notes</h2>` or a second H1 with a note inside the criteria section → flagged as no criterion
- Second `## Description` or `##  Description` section with a weakening sentence → Description differs from the baseline statement
- Tilde fence opened in Intent that swallows Description and criteria → Description and AC-1 to AC-4 missing
- All criteria under `##  Acceptance criteria` plus an exact section with a new AC-9 → AC-9 is not a baseline criterion
- `- [X] AC-1` on a ready requirement → AC-1 is ticked while status is 'ready'
- `* [ ] AC-2`, `- [ ]  AC-2` (two spaces) and a fullwidth x in the box → AC missing plus a line that is no criterion; awk: criterion line format
- `- [ ] AC-02 <weakened>` in place of AC-2 → AC-2 missing and AC-02 is not a baseline criterion
- Added `- [ ] AC-<fullwidth 2> ...` line → not a baseline criterion; awk: criterion line format
- Cyrillic look-alike letter inside a criterion, ` <!-- informational -->` suffix, `~~strikethrough~~`, U+2028 plus a waiver on the criterion line → AC-2 differs from the baseline text
- Indented `- [ ] only when convenient` under a criterion, or a lone CR plus a waiver after a criterion → the extra line is flagged
- Weakened second AC-2 line before or after the verbatim one → duplicate acceptance criterion AC-2
- Ticks on a ready requirement with no done line, with a `ready — done — not yet` reason, or with a `blocked — done — waiting` line → AC-1 is ticked while status is 'ready'
- AC-2 reworded with no log line, with hyphen separators in the log line, with the log line inside a fenced block, under a setext `Status` heading in Edge cases, or with a reason of NBSP only → AC-2 differs and the Status log has no 'AC-2 changed: <reason>' line
- Parent feature no longer links its requirement → § Requirements must link AVE-REQ-002-collection-based-batch-ingestion.md
- AVE-REQ-001 set to done the plain way (ticks `[x]`, no `_TBD`, done log line, matrix row) with no evidence → check-done: 4 criteria of done requirements lack evidence in this run
- `status: done<NBSP>` → awk: invalid status 'done '; check-done still fails
- Done requirement with AC-2 to AC-4 unticked in the one section → awk: status done but 3 acceptance criterion line(s) are unticked
```

### Cleanup

```text
Clone restored after every batch (`git status --short` empty, `git diff --quiet`, HEAD 35f99c5), without git checkout, reset, stash or clean: mutated files were copied back from var/redteam/backup. Container stopped with `./scripts/dev-container.sh --stop` (`--status` then reported `state absent`); the renderer installed under /tmp/mdit went with it. Clone removed with `rm -rf .claude/worktrees/redteam-093-a`. No commit, no push, no `git worktree prune`.

Main checkout the main checkout: never written to; `git status --short` prints nothing. Its HEAD moved from bb94bf7 to 5650249 during the run ("docs: check the committed tree after a partial commit (WF-006); record the runs of 2026-10-06", authored 2026-10-06 10:26 +0900); that commit is not from this review. The other clones and worktrees under .claude/worktrees/ were not touched.

One file remains outside the repository: the baseline verify log in the session scratchpad (093a-verify-baseline.log).
```

## Lens 093-B

### Scope, method and probes without a finding

```text
093-B — lifecycle and planning (statuses and transitions of requirements, features and epics; superseded chains and cycles; deferred, blocked, done; derived requirements that shadow, narrow or absorb; parents and children; dependencies; primary gates; ROADMAP.md, TRACEABILITY.md and IMPORT_MAPPING.md gating; what milestone-review and develop then skip).

Method. Inputs the gates read in this lens: frontmatter status, superseded_by, scope, primary_gate, priority, parent, dependencies of every docs/requirements/AVE-*.md, the Status log, the criteria lines, TRACEABILITY.md matrix rows, IMPORT_MAPPING.md. Inputs no gate reads: docs/ROADMAP.md beyond its existence and links, § Dependencies of a requirement, priority and goals of features and epics, every key of a successor other than scope, status, priority and criteria. 61 probes ran in the clone's container on a `git archive HEAD` copy of the clone under /tmp (both checkers per probe); every finding was then reproduced in the clone's working tree at 35f99c5 (15 runs) with the commands printed in it. Results marked "copy run" come from the /tmp copy only. The release and media tiers were not run.

Notation used in the reproductions:
CHECKS = ./scripts/dev-container.sh python3 -B scripts/check_baseline.py ; ./scripts/dev-container.sh ./scripts/check-project-control.sh
Mutations ran as ./scripts/dev-container.sh python3 -B -c "$(cat <file>)"; the code is printed inline as -c '<code>' with U+2014 written as —. Restore between probes: git show HEAD:<path> > <path> for each modified file, rm for each new file, until git status --short is empty.
SUCC (creates AVE-REQ-105 as a copy of the derived AVE-REQ-103 with priority must and the four criteria of AVE-REQ-001 verbatim, and supersedes AVE-REQ-001 with a superseded log line; s and t are written by WRITE):
import glob, re
R = "docs/requirements/"
old = glob.glob(R + "AVE-REQ-001-*.md")[0]
t = open(old, encoding="utf-8").read()
crit = "\n".join(re.findall(r"(?m)^- \[ \] AC-\d+ .*$", t))
s = open(glob.glob(R + "AVE-REQ-103-*.md")[0], encoding="utf-8").read()
s = s.replace("AVE-REQ-103", "AVE-REQ-105").replace("priority: should", "priority: must")
head, rest = s.split("## Acceptance criteria\n", 1)
s = head + "## Acceptance criteria\n" + crit + "\n\n## Edge cases" + rest.split("\n\n## Edge cases", 1)[1]
t = t.replace("status: ready", "status: superseded", 1)
t = t.replace("\n---\n\n# AVE-REQ-001", "\nsuperseded_by: AVE-REQ-105\n---\n\n# AVE-REQ-001", 1)
t = t.rstrip("\n") + "\n- 2026-10-06 — superseded — replaced by AVE-REQ-105 (lead)\n"
WRITE:
open(R + "AVE-REQ-105-successor.md", "w", encoding="utf-8", newline="\n").write(s)
open(old, "w", encoding="utf-8", newline="\n").write(t)

Probes that passed both checkers with no criterion of AVE-REQ-093 violated (copy runs, no finding): AVE-REQ-001 set back to proposed (develop § 2.4 refines it again) or to blocked (PRODUCT.md completion item 2 names blocked); AVE-FEAT-001 and AVE-EPIC-01 set to done with no child done (milestone-review step 3.2 inspects the derivation); the TRACEABILITY.md row of the in-progress AVE-REQ-093 removed (rows are enforced for done only); a valid chain 001 → 105 (superseded) → 106 carrying every criterion (reported, as designed); AVE-FEAT-001 linking AVE-REQ-001 only under § Out of scope, or only inside an HTML comment (lists_child searches the whole file; the error text says § Requirements); a derived version-one must requirement asking for object tracking while AVE-REQ-101 stays deferred (free text; milestone-review step 6.3 compares with the non-goals); the working file of AVE-REQ-050 renamed with links updated and IMPORT_MAPPING.md regenerated (README § IDs rule 2 has no check; the mapping stays current); the derived AVE-REQ-104 deleted with every link to it (README § IDs rule 4 has no check for derived files).
```

### Baseline

```text
In the clone at 35f99c5, before the first probe: `./scripts/verify.sh` → 'verify.sh: PASS — tier fast (9 of 9 steps passed)', exit 0. `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` → 'BASELINE TOTAL: pass=101 fail=0', exit 0. `./scripts/dev-container.sh python3 -B scripts/check_baseline.py` → 'Working requirements: 104', 'by status: proposed 3, ready 84, in-progress 15, deferred 2', 'Acceptance criteria ticked: 0 of 404 (version one: 0 of 398)', 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files', exit 0, with no Gate change, Recorded change or Supersession line. `./scripts/check-project-control.sh` inside verify.sh → 'OK: 49 required files, 6 executable scripts, 5 agents, 9 skills, 2419 links in 196 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)'.
```

### Finding 093-B-1 (blocking) — ROADMAP.md is read by no gate and the review audit for it cannot fail: a version-one must requirement leaves every milestone with verify.sh green

Criterion: AVE-REQ-093 AC-3 (rules cited: ROADMAP.md § Phase 2 'A milestone is never a reduction of the version-one scope (99 requirements)'; README § Frontmatter primary_gate 'M0…M7 (milestones of ROADMAP.md)'; milestone-review step 11.3)

Reproduction:

```text
Clone at 35f99c5, clean.
1) ./scripts/dev-container.sh python3 -B -c 'p = "docs/ROADMAP.md"
t = open(p, encoding="utf-8").read()
link = "[AVE-REQ-001](requirements/AVE-REQ-001-persistent-projects-and-project-settings.md), "
assert t.count(link) == 1
open(p, "w", encoding="utf-8", newline="\n").write(t.replace(link, ""))'
2) CHECKS
3) grep -c -w AVE-REQ-001 docs/ROADMAP.md
4) ./scripts/dev-container.sh bash -c 'for f in docs/requirements/AVE-REQ-*.md; do grep -q "^status: superseded" "$f" && continue; id=$(basename "$f" | cut -d- -f1-2); grep -q -w "$id" docs/ROADMAP.md || echo "not on roadmap: $id"; done; echo "loop finished; last id searched: $id"'   (the loop of milestone-review step 11.3, plus one echo)
5) ./scripts/verify.sh
Variant in the clone (supersession to a successor on no list): ./scripts/dev-container.sh python3 -B -c 'SUCC
s = s.replace("parent: AVE-FEAT-001", "parent: AVE-FEAT-020", 1).replace("primary_gate: M1", "primary_gate: M99", 1)
p = "docs/ROADMAP.md"
r = open(p, encoding="utf-8").read()
link = "[AVE-REQ-001](requirements/AVE-REQ-001-persistent-projects-and-project-settings.md), "
assert r.count(link) == 1
open(p, "w", encoding="utf-8", newline="\n").write(r.replace(link, ""))
WRITE' ; CHECKS ; step 4 ; grep -c -w AVE-REQ-105 docs/ROADMAP.md
```

Observed:

```text
Step 2: check_baseline.py 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files', exit 0, no 'Gate change' line; check-project-control.sh 'OK: 49 required files, … 2418 links in 196 Markdown files, 134 requirement files, 9 ADRs; 0 warning(s)', exit 0. Step 3: 0. Step 4 prints only 'loop finished; last id searched: AVE-REQ': `cut -d- -f1-2` yields 'AVE-REQ' for every file, a word ROADMAP.md always contains, so the audit prints nothing for any input. Step 5: every step '<== PASS', 'verify.sh: PASS — tier fast (9 of 9 steps passed)', exit 0. AVE-REQ-001 stays status ready, priority must, primary_gate M1.
Variant: 'Supersession: AVE-REQ-001 → AVE-REQ-105 carries every baseline criterion or logs each change', 'by gate: … M99 1 (0 done)', 'OK: baseline intact…', both checkers exit 0; no milestone list names 001 or 105, ROADMAP.md never mentions AVE-REQ-105 (0), the loop prints nothing.
Copy runs, both checkers exit 0 each: AVE-REQ-001 moved from the M1 list to the M7 list with primary_gate M1 (no 'Gate change' line); primary_gate M99 on AVE-REQ-001 (only the note 'Gate change: AVE-REQ-001 primary_gate M99 (baseline M1)'); primary_gate M42 on the derived AVE-REQ-103 (no note; 'M42 1 (0 done)'); AVE-REQ-101 appended to the M3 list; the Deferred group deleted; ROADMAP.md reduced to '# Roadmap'; M0 set to Status done with 'Review: 2026-10-06 — PASS — follow-ups: none' and M1 to in-progress while the five M0 requirements are in-progress ('M0 5 (0 done)').
```

Expected:

```text
The gate fails when a version-one requirement that is not superseded stands on no milestone list, when its list differs from primary_gate, when primary_gate names no milestone of ROADMAP.md, when a future-scope requirement stands on a version-one list, and when a milestone with Status done lists an unfinished requirement; the step 11.3 loop prints 'not on roadmap: AVE-REQ-001'. develop § 2.2 takes candidates only from the current milestone's list, and develop § 11.2, ROADMAP.md planning rule 4 and the milestone exit criteria count only listed requirements, so the dropped must-have is skipped by every milestone and first surfaces at the final review (PRODUCT.md completion item 2), by inspection. For the variant, step 1.2's parent grep for the M1 features does not list AVE-REQ-105 (parent AVE-FEAT-020).
```

Fix:

```text
Smallest: `cut -d- -f1-3` in .claude/skills/milestone-review/SKILL.md step 11.3. Mechanical guard: scripts/check_baseline.py reads docs/ROADMAP.md and requires every working requirement with scope v1 and a status other than superseded on exactly one 'Requirements (dependency order)' list (a 'Proposed during' line while proposed) under the milestone its primary_gate names, future-scope requirements in the Deferred group only, and no unfinished requirement under a milestone with Status done. Suite cases in scripts/tests/test-check-baseline.sh (the fixture gains a roadmap): 'requirement dropped from the roadmap fails', 'roadmap milestone differs from primary_gate fails', 'primary_gate naming no roadmap milestone fails', 'exclusion on a version-one milestone list fails', 'done milestone with an unfinished requirement fails', 'successor of a superseded requirement absent from the roadmap fails'.
```

Lead's disposition: fixed. `check_baseline.py` reads the requirement lists of docs/ROADMAP.md (README § Enforced checks item 10, ROADMAP.md rule 8); the audit loop of milestone-review step 11.3 cuts three fields. Thirteen roadmap cases.

### Finding 093-B-2 (blocking) — A supersession carries the criteria only: the successor sheds the baseline Description, scenarios, origins and type and adds a qualifying criterion without a logged reason

Criterion: AVE-REQ-093 AC-3 (README § Superseding step 2: 'Supersession never demotes an explicit user requirement')

Reproduction:

```text
Clone at 35f99c5, clean.
./scripts/dev-container.sh python3 -B -c 'SUCC
s = s.replace("type: functional", "type: constraint", 1)
d_head, d_rest = s.split("## Description\n", 1)
s = d_head + "## Description\nThe application may keep projects when that is cheap.\n\n## Acceptance criteria" + d_rest.split("\n\n## Acceptance criteria", 1)[1]
s = s.replace("\n\n## Edge cases", "\n- [ ] AC-5 AC-1 to AC-4 are informational for version one.\n\n## Edge cases", 1)
WRITE'
CHECKS
grep -n -E '^(type|source|origins|scenarios):|^- \[ \] AC-5' docs/requirements/AVE-REQ-105-successor.md; grep -n -A1 '^## Description' docs/requirements/AVE-REQ-105-successor.md
```

Observed:

```text
check_baseline.py exit 0: 'by status: proposed 4, ready 83, in-progress 15, superseded 1, deferred 2', 'Supersession: AVE-REQ-001 → AVE-REQ-105 carries every baseline criterion or logs each change', 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files'. check-project-control.sh exit 0 ('OK: … 135 requirement files …'). AVE-REQ-105 holds 'type: constraint' (baseline functional), 'source: derived' (baseline human), 'origins: []' (baseline [U01, U24, D01]), 'scenarios: []' (baseline [AT-01, AT-22]), the Description 'The application may keep projects when that is cheap.' and '- [ ] AC-5 AC-1 to AC-4 are informational for version one.'; the Status log of AVE-REQ-001 holds no 'Description changed' and no 'AC-5 added' line. Copy run: the same successor with status blocked, parent AVE-FEAT-020 (the deferred future feature) and primary_gate M99 → both checkers exit 0.
```

Expected:

```text
Fail. The same edits made in the baseline working file fail ('frontmatter scenarios … must equal the baseline value', 'Description differs from the baseline statement and the Status log has no Description changed line', 'AC-5 is not a baseline criterion…'; suite cases 'changed scenarios', 'rewritten description without log line', 'additional criterion without log line fails'). develop and milestone-review skip a superseded file, so the successor is the live requirement: its empty scenarios remove AT-01 and AT-22 from TRACEABILITY.md audit 6, its Description replaces the human statement, and its source derived moves it from README § Changing requirements rule 2 (escalate) to rule 3 (the lead decides).
```

Fix:

```text
check_supersession in scripts/check_baseline.py, for a version-one baseline requirement: the successor's Description equals the baseline statement unless the old file logs 'Description changed: <reason>'; its scenarios and origins include the baseline's; its type equals the mapped baseline type; each successor criterion that is no baseline criterion needs 'AC-n added: <reason>' in the old file's Status log. Suite cases: 'successor without the baseline scenarios fails', 'successor with another Description fails without a logged change', 'successor adding a criterion unlogged fails'.
```

Lead's disposition: fixed. The successor keeps the type, source human, the origins and the scenarios, stands under a live feature, in its parent's list and on the roadmap, and carries the baseline Description; each difference needs its marker line in the old file. Cases in section (e).

### Finding 093-B-3 (blocking) — The deferred-dependency guard looks one hop deep and reads frontmatter only: a must-have waits on an exclusion with the gate green

Criterion: AVE-REQ-093 AC-3 (README § Enforced checks, check_baseline item 6; § Status lifecycle rule 7: 'no version-one requirement depends on it')

Reproduction:

```text
Clone at 35f99c5, clean.
(a) ./scripts/dev-container.sh python3 -B -c 'SUCC
s = re.sub(r"(?m)^dependencies: .*$", "dependencies: [AVE-REQ-067]", s)
p67 = glob.glob(R + "AVE-REQ-067-*.md")[0]
u = open(p67, encoding="utf-8").read()
crit67 = "\n".join(re.findall(r"(?m)^- \[ \] AC-\d+ .*$", u))
f = open(glob.glob(R + "AVE-REQ-103-*.md")[0], encoding="utf-8").read()
f = f.replace("AVE-REQ-103", "AVE-REQ-106").replace("status: proposed", "status: deferred").replace("priority: should", "priority: could")
f = f.replace("scope: v1", "scope: future").replace("primary_gate: M1", "primary_gate: FUTURE").replace(" — proposed — ", " — deferred — ")
f = re.sub(r"(?m)^dependencies: .*$", "dependencies: []", f)
fh, fr = f.split("## Acceptance criteria\n", 1)
f = fh + "## Acceptance criteria\n" + crit67 + "\n\n## Edge cases" + fr.split("\n\n## Edge cases", 1)[1]
open(R + "AVE-REQ-106-future-successor.md", "w", encoding="utf-8", newline="\n").write(f)
u = u.replace("status: deferred", "status: superseded", 1)
u = u.replace("\n---\n\n# AVE-REQ-067", "\nsuperseded_by: AVE-REQ-106\n---\n\n# AVE-REQ-067", 1)
u = u.rstrip("\n") + "\n- 2026-10-06 — superseded — replaced by AVE-REQ-106 (lead)\n"
open(p67, "w", encoding="utf-8", newline="\n").write(u)
WRITE' ; CHECKS
Control: ./scripts/dev-container.sh python3 -B -c 'SUCC
s = re.sub(r"(?m)^dependencies: .*$", "dependencies: [AVE-REQ-101]", s)
WRITE' ; CHECKS
(b) ./scripts/dev-container.sh python3 -B -c 'import glob
p = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(p, encoding="utf-8").read()
old = "## Dependencies\nNone.\n"
assert old in t
t = t.replace(old, "## Dependencies\n- [AVE-REQ-101 — Object and motion tracking](AVE-REQ-101-object-and-motion-tracking.md)\n")
open(p, "w", encoding="utf-8", newline="\n").write(t)' ; CHECKS
```

Observed:

```text
(a) check_baseline.py exit 0: 'Supersession: AVE-REQ-001 → AVE-REQ-105 carries every baseline criterion or logs each change', 'Supersession: AVE-REQ-067 → AVE-REQ-106 carries every baseline criterion or logs each change', 'OK: baseline intact…'; check-project-control.sh exit 0. State: AVE-REQ-105 status proposed, priority must, scope v1, dependencies [AVE-REQ-067]; AVE-REQ-067 scope future, status superseded, superseded_by AVE-REQ-106; AVE-REQ-106 scope future, status deferred.
Control: 'ERROR: docs/requirements/AVE-REQ-105-successor.md: version-one requirement depends on deferred AVE-REQ-101', 'FAILED: 1 baseline integrity error(s)', exit 1.
(b) both checkers exit 0 ('OK: baseline intact…'); the file reads 'dependencies: []' in frontmatter and '- [AVE-REQ-101 — Object and motion tracking](AVE-REQ-101-object-and-motion-tracking.md)' under § Dependencies.
Copy runs, both checkers exit 0: a derived version-one requirement with dependencies [AVE-REQ-067] after 067 was superseded by a deferred future requirement; § Dependencies of AVE-REQ-002 emptied to 'None.' while frontmatter keeps [AVE-REQ-001]; two derived requirements depending on each other, one of them also on itself.
```

Expected:

```text
(a) fails: the dependency names a future-scope requirement and resolves to the deferred AVE-REQ-106. (b) fails: § Dependencies and frontmatter dependencies differ. develop § 2.2 selects a requirement only when 'every ## Dependencies requirement is done', and a deferred or superseded requirement never reaches done: the must-have is parked without the status deferred, which 'version-one requirement cannot be deferred' forbids directly.
```

Fix:

```text
check_all_requirements in scripts/check_baseline.py: follow superseded_by from each dependency to the end of its chain and fail when the dependency or that end is future scope or deferred; fail when the AVE-REQ IDs linked under § Dependencies differ from frontmatter dependencies; fail on a self-dependency or a cycle. Suite cases: 'v1 requirement depends on a superseded exclusion fails', '§ Dependencies differs from frontmatter dependencies fails', 'dependency cycle fails'. develop § 2.2 then reads a superseded dependency as its replacement (a baseline dependent cannot be re-pointed: its dependencies equal the baseline).
```

Lead's disposition: fixed. A dependency resolves through `superseded_by`; a future-scope or deferred target or end fails; § Dependencies equals the frontmatter list; a self-dependency and a cycle fail.

### Finding 093-B-4 (blocking) — A superseded requirement that never reached done takes ticks, and the summary counts them

Criterion: AVE-REQ-093 AC-4 (§ Edge cases: 'A criterion ticked on a requirement that never reached done → fails')

Reproduction:

```text
Clone at 35f99c5, clean.
./scripts/dev-container.sh python3 -B -c 'SUCC
t = t.replace("- [ ] AC-", "- [x] AC-")
WRITE'
CHECKS
grep -n -E '^(status|superseded_by):|^- \[x\] AC-' docs/requirements/AVE-REQ-001-*.md; grep -c ' — done — ' docs/requirements/AVE-REQ-001-*.md
```

Observed:

```text
check_baseline.py exit 0: 'by status: proposed 4, ready 83, in-progress 15, superseded 1, deferred 2', 'Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)', 'Supersession: AVE-REQ-001 → AVE-REQ-105 carries every baseline criterion or logs each change', 'OK: baseline intact…'. check-project-control.sh exit 0. The file reads 'status: superseded', 'superseded_by: AVE-REQ-105', four '- [x] AC-n' lines; its Status log holds no done line (grep -c prints 0). Copy run: the exclusion AVE-REQ-101 superseded by a deferred future requirement and ticked → 'Acceptance criteria ticked: 3 of 404 (version one: 0 of 398)', exit 0.
```

Expected:

```text
'ERROR: … AC-1 is ticked while status is 'superseded' and the Status log has no done line', exit 1. The requirement's § Edge cases states that failure; README § Baseline import rule 4 and the checker's docstring list status superseded beside done as 'reached done', which a superseded requirement need not have.
```

Fix:

```text
check_all_requirements: `if ticked and status != "done" and "done" not in item.log_statuses()` (drop "superseded" from the tuple); reword README § Baseline import rule 4 and the docstring item c. Suite case: 'ticked criterion on a superseded requirement without a done line fails'.
```

Lead's disposition: fixed. A superseded requirement keeps ticks only with a `done` line in its log.

### Finding 093-B-5 (blocking) — check-done reads status and ticks differently from both checkers: a quoted status, a repeated status key or [X] ticks carry a done requirement past the release step without evidence

Criterion: AVE-REQ-093 AC-4 (Verification strategy: 'scripts/evidence.py check-done (release tier) refuses a done requirement without this run's evidence'); the same gate serves AVE-REQ-097 (overlaps lenses 093-A and 097-E)

Reproduction:

```text
Clone at 35f99c5, clean; once per V in plain (control), quoted, dupkey, capx, restoring in between.
./scripts/dev-container.sh python3 -B -c 'import glob
V = "quoted"
p = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(p, encoding="utf-8").read()
t = t.replace("- [ ] AC-", "- [X] AC-" if V == "capx" else "- [x] AC-").replace("_TBD", "TBD")
if V == "quoted":
    t = t.replace("status: ready", "status: \"done\"", 1)
elif V == "dupkey":
    t = t.replace("status: ready", "status: in-progress", 1).replace("\n---\n\n# AVE-REQ-001", "\nstatus: done\n---\n\n# AVE-REQ-001", 1)
else:
    t = t.replace("status: ready", "status: done", 1)
t = t.rstrip("\n") + "\n- 2026-10-06 — done — verify-requirement PASS (lead)\n"
open(p, "w", encoding="utf-8", newline="\n").write(t)
tr = "docs/TRACEABILITY.md"
s = open(tr, encoding="utf-8").read()
sep = "|---|---|---|---|---|---|\n"
row = "| [AVE-REQ-001](requirements/" + p.split("/")[-1] + ") | done | x | x | x | x |\n"
assert s.count(sep) == 1
open(tr, "w", encoding="utf-8", newline="\n").write(s.replace(sep, sep + row))'
CHECKS
./scripts/dev-container.sh bash -c 'mkdir -p var/empty-run && python3 -B scripts/evidence.py check-done --dir var/empty-run'   (the command of scripts/verify.d/95-evidence.sh on a run directory that holds no evidence)
```

Observed:

```text
All four variants: check_baseline.py exit 0 with 'by status: proposed 3, ready 83, in-progress 15, done 1, deferred 2', 'by gate: … M1 16 (1 done) …', 'Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)'; check-project-control.sh exit 0.
check-done: V=plain → 'ERROR: AVE-REQ-001 AC-1: missing in this run' (also AC-2, AC-3, AC-4), 'FAIL: 4 criteria of done requirements lack evidence in this run', exit 1. V=quoted (frontmatter 'status: "done"') → 'OK: every criterion of the 0 done requirements is evidenced by this run', exit 0. V=dupkey ('status: in-progress' at line 5, 'status: done' at line 15) → the same line, exit 0. V=capx ('- [X] AC-1 …') → 'OK: every criterion of the 1 done requirements is evidenced by this run', exit 0.
Copy runs: `grep -oE '^- \[[ x]\] AC-[0-9]+'` (milestone-review step 4.2 and the TRACEABILITY.md audit loop) lists no criterion of the [X] file; 'parent: "AVE-FEAT-001"' passes both checkers and is absent from step 1.2's `grep -l -E '^parent: (AVE-FEAT-001)$'`.
```

Expected:

```text
check-done exits 1 for the three variants as for the control, or the checkers reject the three notations (README § Frontmatter already says 'no quoting' and one key per line). The release tier itself was not run in this lens; the status test in done_problems precedes any evidence lookup, so the content of the run directory does not change the three results.
```

Fix:

```text
scripts/evidence.py read_requirement: read the frontmatter block only, let the last key win and strip quotes (the rule both checkers apply), and `_AC_LINE = re.compile(r"^- \[[ xX]\] (AC-\d+)\b")`; in addition check_baseline.py can reject a quoted value, a repeated key and `[X]`. Cases in scripts/tests/test_evidence.py: 'quoted done status needs evidence', 'repeated status key: the last one counts', 'capital-X tick is a criterion'. The greps of milestone-review steps 1.2 and 4.2 and of TRACEABILITY.md § Conventions follow (`\[[ xX]\]`).
```

Lead's disposition: fixed with 093-A-1. The greps of milestone-review and TRACEABILITY.md read `[ x]`, the only tick spellings of the canonical form.

### Finding 093-B-6 (blocking) — One 'AC-n changed' line covers every later change of that criterion: a deletion, or a successor's drop, passes on the reason of an older wording fix

Criterion: AVE-REQ-093 AC-3 (§ Edge cases: 'A criterion … reworded or removed … without a logged reason → fails'; IMPORT_MAPPING.md rule 4: 'fails on an unrecorded one'); overlaps lens 093-A

Reproduction:

```text
Clone at 35f99c5, clean.
Step 1 (a logged wording fix): ./scripts/dev-container.sh python3 -B -c 'import glob
p = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(p, encoding="utf-8").read()
assert "project metadata are unchanged." in t
t = t.replace("project metadata are unchanged.", "project metadata are unchanged after a restart.", 1)
t = t.rstrip("\n") + "\n- 2026-10-06 — ready — AC-2 changed: wording clarified (lead)\n"
open(p, "w", encoding="utf-8", newline="\n").write(t)' ; CHECKS
Step 2 (later, no new log line): ./scripts/dev-container.sh python3 -B -c 'import glob
p = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
lines = open(p, encoding="utf-8").read().split("\n")
kept = [l for l in lines if not l.startswith("- [ ] AC-2 ")]
assert len(kept) == len(lines) - 1
open(p, "w", encoding="utf-8", newline="\n").write("\n".join(kept))' ; CHECKS ; grep -n 'AC-2' docs/requirements/AVE-REQ-001-*.md
```

Observed:

```text
Step 1: check_baseline.py exit 0, 'Recorded change: AVE-REQ-001 AC-2 differs from the baseline text — wording clarified (lead)'. Step 2: check_baseline.py exit 0, 'Acceptance criteria ticked: 0 of 403 (version one: 0 of 397)', 'Recorded change: AVE-REQ-001 AC-2 is missing — wording clarified (lead)', 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files'; check-project-control.sh exit 0; the only AC-2 line left in the file is '54:- 2026-10-06 — ready — AC-2 changed: wording clarified (lead)'. Copy run: the same old line, then AVE-REQ-001 superseded by a successor without AC-2 → 'Recorded change: AVE-REQ-001 AC-2 is absent from the successor AVE-REQ-105 — wording clarified (lead)', 'Supersession: AVE-REQ-001 → AVE-REQ-105 carries every baseline criterion or logs each change', exit 0.
```

Expected:

```text
Step 2 fails: the removal has no logged reason; the note it prints gives the reason of another change. The same holds for the successor's drop, which the review-4 fix was to catch when unlogged.
```

Fix:

```text
recorded_change in scripts/check_baseline.py ties a line to the change it covers: a missing criterion needs 'AC-n removed: <reason>'; a successor's drop needs a line at or after the superseded line that names the successor; a reworded criterion's line carries a digest of the current text (for example 'AC-2 changed [1a2b3c4d]: <reason>', the first 8 hex digits of the SHA-256 of the line), so the next edit needs a new line. Suite cases: 'criterion removed under an earlier changed line fails', 'successor drop under a line older than the supersession fails', 'second rewording under the first line fails'.
```

Lead's disposition: fixed. `AC-n changed [<mark>]` names the digest of the current text, a removal needs `AC-n removed`, a successor's drop needs `AC-n dropped by <ID>`; cases for a second rewording, a removal and a successor's drop under an older line.

### Finding 093-B-7 (blocking) — A baseline feature or epic file keeps only its title, parent and deferred or superseded status: priority and goals change freely (low impact)

Criterion: AVE-REQ-093 AC-3 (§ Edge cases: 'A working file missing, duplicated or with a changed identity (title, type, priority, …) → the baseline check fails')

Reproduction:

```text
Clone at 35f99c5, clean.
./scripts/dev-container.sh bash -c 'sed -i -e "s/^priority: must$/priority: could/" -e "s/^goals: \[GOAL-001\]$/goals: [GOAL-010]/" docs/requirements/AVE-FEAT-001-*.md docs/requirements/AVE-EPIC-01-*.md && grep -H -E "^(priority|goals):" docs/requirements/AVE-FEAT-001-*.md docs/requirements/AVE-EPIC-01-*.md'
CHECKS
```

Observed:

```text
grep: 'AVE-FEAT-001-projects-and-media-collection.md:priority: could', 'AVE-EPIC-01-project-and-asset-management.md:priority: could', 'AVE-EPIC-01-project-and-asset-management.md:goals: [GOAL-010]'. check_baseline.py 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files', exit 0; check-project-control.sh 'OK: … 0 warning(s)', exit 0. Copy run: the future-scope AVE-EPIC-10 and AVE-FEAT-020 set to priority must → both checkers exit 0.
```

Expected:

```text
Fail, or the sentence names requirement files only (README § Baseline import rule 4 and the checker's docstring item b already say 'requirements keep the mapped type, priority and source'). Impact is small: develop § 2.3 orders by the requirement's own priority; the epic then serves another goal than TRACEABILITY.md § Goal coverage shows until milestone-review audit 1.
```

Fix:

```text
check_epics_features: `expect(item, "priority", "could" if future else "must")` and, for epics, `expect(item, "goals", [epic["goal"]])`; or reword the edge case to 'a working requirement file'. Suite cases: 'demoted feature priority fails', 'epic goals changed fails'.
```

Lead's disposition: fixed. Imported epics and features keep their priority; epics keep their goal.

### Finding 093-B-8 (boundary) — A done line and a reopening line added in one edit keep every tick on a requirement that was never verified

Criterion: AVE-REQ-093 AC-4 (§ Edge cases: 'A criterion ticked on a requirement that never reached done → fails (AC-4); a reopened requirement keeps the ticks its done log line covers')

Reproduction:

```text
Clone at 35f99c5, clean.
./scripts/dev-container.sh python3 -B -c 'import glob
p = glob.glob("docs/requirements/AVE-REQ-001-*.md")[0]
t = open(p, encoding="utf-8").read()
t = t.replace("status: ready", "status: in-progress", 1).replace("- [ ] AC-", "- [x] AC-")
t = t.rstrip("\n") + "\n- 2026-10-06 — done — verify-requirement PASS (lead)\n- 2026-10-06 — in-progress — reopened (lead)\n"
open(p, "w", encoding="utf-8", newline="\n").write(t)'
CHECKS
```

Observed:

```text
check_baseline.py exit 0: 'by status: proposed 3, ready 83, in-progress 16, deferred 2', 'Acceptance criteria ticked: 4 of 404 (version one: 4 of 398)', 'OK: baseline intact…'. check-project-control.sh exit 0.
```

Expected:

```text
Boundary, reported because the documents claim a mechanical guard for it: the guard reads Status-log text, so only the diff shows that no done state ever existed. No TRACEABILITY.md row, no _TBD rule and no check-done applies to an in-progress requirement, so nothing else looks at these ticks. README § Status lifecycle rule 5 says a reopening unticks the affected criteria, while the checker and the suite case 'ticked criterion after reopening passes' keep them.
```

Fix:

```text
Allow ticks only while status is done (rule 5 already unticks on reopening); the suite case 'ticked criterion after reopening passes' becomes 'ticked criterion after reopening fails'. Otherwise state in § Edge cases that the done line is free text judged at commit review.
```

Lead's disposition: fixed by the stricter rule: ticks stand only while the status is `done`, so a reopened requirement holds none (README § Status lifecycle rule 5 changed with a logged reason).

### Probes the gates rejected

```text
- Cycle: AVE-REQ-001 superseded_by 105 and 105 superseded_by 001 → check_baseline exit 1: 'superseded_by chain AVE-REQ-105 → AVE-REQ-001 names no replacement'
- AVE-REQ-001 superseded_by itself → exit 1: 'superseded_by chain AVE-REQ-001 names no replacement'
- Chain 001 → 105 (superseded) → 106 carrying none of the criteria → exit 1: four 'AC-n of the baseline is absent from the successor AVE-REQ-106 and the Status log has no AC-n changed line'
- Chain 001 → 105 (superseded) → 106 with scope future, status deferred → exit 1: 'a version-one requirement cannot be superseded by AVE-REQ-106 (scope 'future', status 'deferred')'
- Exclusion chain AVE-REQ-101 → 105 (future, then superseded) → 106 (v1, proposed) → exit 1: 'a future-scope requirement cannot be superseded by AVE-REQ-106 (scope 'v1', status 'proposed')'
- AVE-REQ-101 superseded by the baseline future AVE-REQ-067 without logged drops → exit 1: three 'absent from the successor AVE-REQ-067'
- AVE-REQ-001 superseded by the existing derived should AVE-REQ-103 → exit 1: 'a baseline must requirement cannot be superseded by a 'should' requirement (AVE-REQ-103)' plus four criterion errors
- AVE-REQ-001 set to superseded without superseded_by → both checkers exit 1: 'superseded_by chain (empty) names no replacement'; 'status superseded requires frontmatter superseded_by'
- AVE-REQ-001 superseded_by AVE-FEAT-002 → exit 1: 'superseded_by AVE-FEAT-002 has no working requirement file'
- AVE-REQ-101 set to proposed, in-progress, verification, done and blocked (five runs) → exit 1 each: 'future-scope requirement must stay deferred (status '…')'; done also fails check-project-control (unticked criteria, _TBD, no matrix row)
- AVE-FEAT-020 (future) set to superseded → exit 1: 'status must be deferred exactly when every child is future scope' and 'a baseline feature is superseded only when every baseline requirement under it is superseded (AVE-REQ-101 is 'deferred')'
- AVE-FEAT-001 parent set to AVE-EPIC-10 → exit 1: 'frontmatter parent 'AVE-EPIC-10' must equal the baseline value 'AVE-EPIC-01''
- Derived file AVE-REQ-0001-shadow.md with the criteria of AVE-REQ-001 → exit 1: 'AVE-REQ-0001 lies inside the baseline ID range but has no baseline entry; new REQ IDs continue after 101'
- Successor of AVE-REQ-001 depending directly on the deferred AVE-REQ-101 (clone) or on a deferred derived AVE-REQ-106 (copy) → exit 1: 'version-one requirement depends on deferred AVE-REQ-…'
- TRACEABILITY.md row of AVE-REQ-093 set to done while frontmatter is in-progress → check-project-control exit 1: 'line 204: AVE-REQ-093 status 'done' differs from its frontmatter status 'in-progress''
- AVE-REQ-001 done on paper with an unquoted status and lowercase ticks → both checkers pass (fast tier), `evidence.py check-done` on an empty run directory exit 1: 'FAIL: 4 criteria of done requirements lack evidence in this run'
- scripts/tests/test-check-baseline.sh at 35f99c5: 101 of 101 cases held, among them version-one requirement deferred, future requirement made ready, deferred feature with a v1 child, future epic made ready, FUTURE gate on a v1 requirement, invalid gate M1.5, superseded by a missing, weaker or future-scope requirement, successor dropping a criterion unlogged, feature and epic superseded while children live, v1 requirement depending on a deferred one, stale and missing IMPORT_MAPPING.md
```

### Cleanup

```text
Clone restored after every probe (git status --short empty; modified files rewritten with `git show HEAD:<path> > <path>`, new files removed), last check before removal: 0 lines at 35f99c5. Container stopped with `./scripts/dev-container.sh --stop` (exit 0; --status then reports 'state absent'). Clone removed with `cd <repository> && rm -rf .claude/worktrees/redteam-093-b` (exit 0; the directory is gone, the other lenses' clones and both worktrees are untouched). Main checkout the main checkout: `git status --short` empty; this lens made no commit, push or `git worktree prune` and wrote no file there. Its HEAD moved from bb94bf7 to 5650249 during the run through a commit of the lead's session ('docs: check the committed tree after a partial commit (WF-006); record the runs of 2026-10-06'); from 35f99c5 to 5650249, scripts/, docs/requirements/README.md, docs/ROADMAP.md and .claude/skills/milestone-review/SKILL.md are unchanged (the diff touches docs/TRACEABILITY.md audit 6 and .claude/skills/develop/SKILL.md only), so the findings apply to the current head. Probe helpers lived under the clone's gitignored var/ and went with it. Run logs remain outside the repository in <session scratchpad> (093b-baseline-verify.log, 093b-baseline-suite.log, 093b-baseline-check.log, 093b-confirm-1.log, 093b-confirm-2.log). The backend environment that verify.sh created for the clone stays on the shared state volume ave-dev-state.
```

## Lens 093-C

### Scope, method and probes without a finding

```text
093-C — package and repository state: the manifest and its entries, file kinds and modes, links, nested repositories and gitlinks, ignored and untracked files, .gitattributes and Git filters, name case and normalization, how import_baseline.py reads the package versus the package validator, and the environment variables or working directory that change what check_baseline.py reads.
```

### Baseline

```text
./scripts/verify.sh (clone, fast tier) -> 'verify.sh: PASS - tier fast (9 of 9 steps passed)'. ./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh -> 'BASELINE TOTAL: pass=101 fail=0' (exit 0). ./scripts/dev-container.sh python3 -B scripts/check_baseline.py -> 'OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files' (exit 0), 'Baseline files: PASS ... all 133 manifest entries'. Host: Windows 11 + Git Bash; checks ran inside the Linux dev container (Python 3.12.3, git 2.55.0, uid 0, core.filemode=false, core.ignorecase=true). The 097 evidence/suite baseline commands are out of this lens and were not run.
```

### Finding 093-C-1 (blocking) — A gitignored bytecode cache for the import tool makes ./scripts/verify.sh report a demoted/rewritten baseline requirement as intact, and the cache never appears in git status or the commit diff

Criterion: AVE-REQ-093 AC-1, AC-3

Reproduction:

```text
In the clone, in the container: (1) demote a committed working file: `sed -i 's/^priority: must$/priority: should/' docs/requirements/AVE-REQ-001-*.md`. (2) `python3 -B scripts/check_baseline.py` -> exit 1, 'frontmatter priority should must equal the mapped baseline value must' (gate works). (3) Build a modified copy of scripts/requirements/import_baseline.py whose priority mapping returns 'should' for AVE-REQ-001, and `py_compile.compile(mod, cfile='scripts/requirements/__pycache__/import_baseline.cpython-312.pyc', dfile=<real path>, invalidation_mode=UNCHECKED_HASH)` (a timestamp-matched cache behaves identically). (4) `git status --short` shows only the one working-file edit; `git status --short --ignored -- scripts` shows `!! scripts/requirements/__pycache__/`. (5) `python3 -B scripts/check_baseline.py` -> exit 0 'OK: baseline intact'. (6) `./scripts/verify.sh` -> 'verify.sh: PASS - tier fast (9 of 9 steps passed)', with the demotion still committed. The same route with a gitignored `scripts/hashlib.pyc` (sourceless, UNCHECKED_HASH) that shadows stdlib hashlib and lies about SHA-256 makes an edited baseline file in ai-video-editor-requirements/ pass identically.
```

Observed:

```text
check_baseline.py: 'Baseline manifest: PASS ... Baseline files: PASS ... Baseline package: PASS ... OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files' (exit 0) while AVE-REQ-001 carries priority: should; ./scripts/verify.sh: 'verify.sh: PASS - tier fast (9 of 9 steps passed)'. load_importer() loads the sibling import tool through importlib.util.spec_from_file_location, whose SourceFileLoader uses a valid __pycache__ entry without recompiling; `python3 -B` disables writing bytecode, not reading it.
```

Expected:

```text
A committed priority demotion must fail AVE-REQ-093 AC-3 ('frontmatter priority ... must equal the mapped baseline value must'), and an edited baseline file must fail AVE-REQ-093 AC-1 ('baseline changed'), regardless of any bytecode cache present on disk. The requirement's Edge cases say gate tampering 'shows in the diff that verify-requirement reviews' - but the .pyc is matched by .gitignore (__pycache__/, *.pyc), so it is absent from git status and the commit diff, and the documented commit-review inspection cannot see it. Caveat the lead should weigh: a fresh checkout (CI release tier) has no __pycache__ and recompiles from source, so CI catches this; the bypass is of the local fast tier and the Stop gate only.
```

Fix:

```text
Invoke the checker and its validator subprocess in isolated mode: change scripts/verify.d/10-requirements.sh to `python3 -I -B scripts/check_baseline.py` (-I implies -E, -s and safe_path, dropping the script dir from sys.path[0]), and change check_baseline.run_package_validator's subprocess to `[sys.executable, '-I', '-B', validator, ...]`; load the import tool from source bytes (e.g. compile(IMPORTER.read_bytes(), ...) and exec, instead of SourceFileLoader) so no .pyc is ever consulted. Suite case for scripts/tests/test-check-baseline.sh: a case that plants `scripts/requirements/__pycache__/import_baseline.<tag>.pyc` built from a modified importer (and a case that plants `scripts/hashlib.py`) over a demoted/weakened baseline and asserts check_baseline.py still exits 1 with the demotion/'baseline changed' message.
```

Lead's disposition: fixed. The checker restarts itself in Python's isolated mode, verify.sh starts it with `-I`, and it loads the import tool and the reader from their source text; cases plant a tampered bytecode cache and a lying `hashlib` beside the checker.

### Finding 093-C-2 (blocking) — PYTHONPATH and PYTHONPYCACHEPREFIX in the environment inject a shadow hashlib or a tampered import-tool cache, so the gate reports an edited baseline as intact

Criterion: AVE-REQ-093 AC-1, AC-3

Reproduction:

```text
In a scratch copy of the clone's checker, importer, package and working files (container filesystem), with AC-2 weakened in both ai-video-editor-requirements/spec/requirements.json and spec/requirements/AVE-REQ-001.md and the working file: (1) clean env -> `python3 -B scripts/check_baseline.py` exit 1, three 'baseline changed: SHA-256 ... differs' errors. (2) write /tmp/shadow/hashlib.py that wraps the real hashlib and returns the manifest's recorded digest for the two edited files; `PYTHONPATH=/tmp/shadow python3 -B scripts/check_baseline.py` -> exit 0 'OK: baseline intact'. Separately, with a committed priority demotion: build /pfx/<abs>/scripts/requirements/__pycache__/import_baseline.<tag>.pyc from a modified importer and `PYTHONPYCACHEPREFIX=/pfx python3 -B scripts/check_baseline.py` -> exit 0 'OK: baseline intact'. Both vectors are closed by adding -I: `python3 -I -B scripts/check_baseline.py` -> exit 1 (confirmed).
```

Observed:

```text
'Baseline manifest: PASS ... Baseline files: PASS ... Baseline package: PASS ... OK: baseline intact' (exit 0) under PYTHONPATH naming a shadow hashlib while two baseline files are edited; identical OK under PYTHONPYCACHEPREFIX with a planted cache while a priority is demoted. The gate command `python3 -B scripts/check_baseline.py` runs without -I/-E/-P, so it honors PYTHONPATH (module shadowing) and PYTHONPYCACHEPREFIX (cache location).
```

Expected:

```text
An edited baseline must fail AC-1 and a demotion AC-3 regardless of environment variables; the brief's scope rule names 'the environment' as a non-gate change that must not let a gate pass. Reachability caveat for the lead: on this Windows host `./scripts/verify.sh` re-execs into the container and scripts/dev-container.sh forwards only UV_PROJECT_ENVIRONMENT, AVE_HEAVY_LOCK and VERIFY_TIER, so host PYTHONPATH/PYTHONPYCACHEPREFIX do NOT reach the gate through the standard verify.sh path; the vector is live when check_baseline.py is run directly with the variable set (a native-Linux verify.sh or the Stop gate, which inherit the shell environment, or a direct `./scripts/dev-container.sh bash -c 'export PYTHONPATH=...; python3 -B scripts/check_baseline.py'`).
```

Fix:

```text
Same root cause and fix as the bytecode-cache finding: run the checker and the validator subprocess with `python3 -I -B` (isolated mode ignores PYTHONPATH, PYTHONPYCACHEPREFIX and user site and drops the script dir from sys.path), and load the import tool from source bytes rather than via a cacheable SourceFileLoader. Suite case: add to scripts/tests/test-check-baseline.sh a case that runs the checker with `PYTHONPATH=<shadow>` (and one with `PYTHONPYCACHEPREFIX`) over an edited baseline and asserts exit 1 'baseline changed'.
```

Lead's disposition: fixed with 093-C-1; cases for `PYTHONPATH` and `PYTHONPYCACHEPREFIX`. § Edge cases names what stays trusted: the interpreter, the shell and the tools on `PATH` of the container and of CI, with CI on a fresh checkout admitting commits to `main`.

### Probes the gates rejected

```text
- Empty directory / nested empty dirs added in the package -> OK exit 0: they carry no bytes and no manifest entry, so no baseline content can be altered this way (os.walk records only files).
- Hard link to a package file under a new name (ln README.md spec/README-copy.md) -> fail 'the file is absent from the manifest'.
- FIFO / named pipe added in the package -> fail 'the file is absent from the manifest'.
- __pycache__/*.pyc or a sourceless json.pyc placed INSIDE the package (tools/) -> fail 'the file is absent from the manifest'.
- Gitignored-name decoys (.DS_Store, Thumbs.db) placed inside the package -> fail 'the file is absent from the manifest' (os.walk ignores .gitignore).
- Nested repository (.git directory) or a .git gitfile inside the package -> fail 'the file is absent from the manifest'.
- Lower-case manifest.json beside or below MANIFEST.json -> fail 'absent from the manifest'; a MANIFEST.json directory in a subdir -> fail 'a file the package inventory skips was added' (the rglob('MANIFEST.json') guard).
- Case-variant twin or rename of a manifest entry on this ignorecase host (Requirements.json) -> fail ('absent from the manifest', and the rename also fails as 'missing from the package').
- NFD look-alike twin of a manifest entry (READM E + combining acute) -> fail 'absent from the manifest'.
- MANIFEST.json or any package text file converted to CRLF -> fail on SHA-256 (the pin for MANIFEST.json, the manifest entry for others); .gitattributes already pins eol=lf and dev-container.sh refuses a CRLF MANIFEST.json checkout.
- A manifest entry replaced by a directory -> fail 'the file is missing from the package'.
- A manifest-listed file, MANIFEST.json, or a package subdirectory replaced by a symlink to an identical external copy -> fail 'a symbolic link was added' (os.walk entry.is_symlink()).
- A Windows directory junction created inside the package (mklink /J) -> fail 'a symbolic link was added' (the 9p mount presents it to the container as a symlink).
- mtime-only touch of a package file (identical bytes) -> OK exit 0, correct: only size and SHA-256 are checked.
- A file with an undecodable byte in its name added to the package -> fail (caught as absent from the manifest / validator failure).
- Executable bit set on package files -> OK exit 0, correct: file mode is not hashed and git core.filemode is false.
- Extra file hidden in a chmod-000 directory, checker run as an unprivileged uid -> masks the file for that user, but fails as root and in CI; an unreadable manifest-listed file raises PermissionError (exit 1) and an unreadable manifest-listed directory fails 'missing from the package' -> not a silent pass on the authoritative run.
- Package root, docs/requirements/, or a single working file replaced by a symlink to an identical external copy -> gate and verify.sh pass, but git status shows the 134 tracked files as deleted plus an untracked symlink, so commit review sees it (bytes identical, so no AC behavior violated).
- Decoy ai-video-editor-requirements/ in another working directory, checker started from there -> OK against the REAL package: ROOT is derived from the script path, not cwd, so cwd does not redirect what is read.
- Package untracked via an alternate index plus a local .git/info/exclude entry -> gate passes on the working-tree bytes, but a checkout of that index has no package and fails, and git status shows all 134 files deleted.
- Weakened package blobs staged in an alternate index and hidden with git update-index --skip-worktree or a clean/smudge filter -> gate passes because the working-tree bytes stay pristine; a fresh checkout without the local filter fails on SHA-256 and git status shows the staged M.
- Package recorded as a gitlink (mode 160000) -> gate still hashes the on-disk files and passes, and git status shows the gitlink added plus 134 deletions; its only effect is to skip the 'Working tree unchanged' fingerprint (a 097 Stop-gate concern), not to alter baseline content.
- A second AVE-REQ-001 copy with a weakened AC-2 placed in docs/requirements/archive/ -> both checkers pass because they glob only docs/requirements/*.md (top level); the canonical requirement is unchanged, so no criterion is demoted, though the stray copy escapes every format and baseline check.
```

### Cleanup

```text
Scratch artifacts removed (var/rt/ in the clone and /tmp/rt in the container deleted). Every probe ran in the private clone or its container /tmp; the clone was restored to a clean tree (git status --short empty, 0 skip-worktree entries) after each probe. Container stopped (./scripts/dev-container.sh --stop, rc 0). Private clone removed (rm -rf .claude/worktrees/redteam-093-c). Main checkout C:/dev/AI-Video-Editor untouched (git status --short empty). No commits, pushes, or git worktree prune.
```
