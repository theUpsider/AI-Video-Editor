# Handback — M0 final review fixes, part 1: track A, the baseline gate (AVE-REQ-093)

Brief: [2026-10-06-m0-final-review-fixes.md](../2026-10-06-m0-final-review-fixes.md). Run `wf_5cd13360-464` ([script](../../workflows/m0-final-review-fixes.js)), branch `m0-final-fixes-a` from `41973c5`. The report below is the writer's, unedited apart from local paths and the level of its headings. The lead applied the two patches of § Open item on the integration branch `m0-final-integration`: the raw-HTML rule with its cases, and the two lines of AVE-REQ-098.

## Report

### Result: PARTIAL

Track A of `docs/briefs/2026-10-06-m0-final-review-fixes.md` (part 5, AVE-REQ-093). All four blocking findings and non-blocking findings 2 to 8 are fixed on the branch, and the track A share of finding 9 is done. One decision of the brief is open: the rule "raw HTML fails outside code spans and fenced blocks" (non-blocking 1, folded into Track A item 1). It flags two lines of `docs/requirements/AVE-REQ-098-persistent-progress-and-bounded-autonomous-continuation.md`, a file outside this track's paths, so the committed tree states the limit and the tested patch waits for the lead (§ Open item).

### Requirements
- AVE-REQ-093 — Adopt and preserve the supplied requirements baseline — status `in-progress` at the start, no dependencies — ACs worked on: AC-1, AC-3, AC-4 (AC-2 is inspection, untouched); open among the ACs: none; open among the brief's decisions: the raw-HTML rule — proposed status `verification` once the lead has decided the open item.

### Branch and commits
- Branch `m0-final-fixes-a`, tip `48b5e9d6949f3f505366a833e5728ae51e7a68f4`, two commits on the base `41973c503730a0d017fc2d319e8cd33cd02e8c60` (`git rev-parse HEAD` printed exactly this hash before the first change):
  - `6ee69da01a2b36307277aab4fa8e7bbd3215b61d` — AVE-REQ-093: close the findings of the final review on the baseline gate
  - `48b5e9d6949f3f505366a833e5728ae51e7a68f4` — AVE-REQ-093: pin every form of the new baseline-gate rules with a suite case
- Nothing pushed, merged or rebased; the working tree is clean; only the eight files of the allowed list changed.

### Findings of part 5 — disposition, files, named cases
All cases live in `scripts/tests/test-check-baseline.sh` (213 cases before, 294 now).

**Blocking 1 (headings a reader renders; invisible characters; empty marker reason) — fixed**, apart from the raw-HTML sentence of the decision (see non-blocking 1).
- `scripts/reqfile.py`: `readings()` judges a line after its leading spaces and again after each container marker (`CONTAINER`: `>`, `-`, `*`, `+`, `N.`, `N)`); `ATX` and `UNDERLINE` apply to every reading; `EXTRA_CHARACTERS` plus U+0020 to U+007E is the allow-list (`_bad_character`); `REASON` in `recorded()` requires a letter or digit.
- The allow-list holds seven signs, found by a scan of the 134 working files (the baseline package is ASCII): U+00A7, U+00B1, U+2013, U+2014, U+2192, U+2265, U+2282.
- Documents: `docs/requirements/README.md` § Canonical form rules 1 and 3; AVE-REQ-093 § Edge cases, § Verification strategy AC-3.
- Heading cases: "heading on an ordered-list continuation line fails", "heading on a wide bullet continuation line fails", "heading behind a wide list marker fails", "heading behind an ordered marker in a quote fails", "heading behind a star bullet fails", "heading behind a plus bullet fails", "heading behind an ordered marker fails", "heading right behind a quote sign fails", "bare hashes in a quote fail", "bare hashes on a line fail", "underlined heading inside a quote fails", "dash-underlined heading inside a quote fails", "underlined heading inside a list item fails", "underline behind a list marker fails", "underline with trailing spaces fails", "one-character underline fails", "underlined heading in a feature's list section fails", "list items and quotes without a heading pass".
- Character cases: "Hangul filler fails", "braille blank fails", "combining grapheme joiner fails", "Hangul choseong filler fails", "letter outside the allow-list fails", "tab fails", "delete character fails", "unit separator fails", "signs of the allow-list pass".
- Reason cases: "reason of punctuation alone does not count", "reason of one invisible character does not count".

**Blocking 2 (milestone Status in other spellings) — fixed.**
- `scripts/check_baseline.py`: `MILESTONE_STATUS` and `read_roadmap()`. Every `### M<n>` entry holds exactly one line `- **Status:** planned|in-progress|done`; any other line of the entry that holds `**Status` in any letter case fails; none or two fail.
- Documents: `docs/ROADMAP.md` § Rules 8; README § Enforced checks item 10; AVE-REQ-093 § Edge cases.
- Cases: "milestone Status done with a full stop fails", "capitalised milestone Status fails", "milestone Status with a note fails", "bold milestone Status word fails", "unknown milestone Status word fails", "indented milestone Status line fails", "milestone without a Status line fails", "milestone with two Status lines fails", "milestone Status in-progress passes".

**Blocking 3 (`__future__` ran before the restart) — fixed for the checker and its documents; the hint in `scripts/evidence.py` belongs to track B2.**
- `scripts/check_baseline.py`: `import os`, `import sys` and the restart are the first executed statements; the `__future__` import is gone; the usage text names the isolated command.
- Documents: the checker's docstring, README § Enforced checks (closing paragraph), AVE-REQ-093 § Edge cases and § Verification strategy AC-1. They scope the guarantee to `python3 -I -B`, name the three pinned cases of the start without `-I`, and name a `sitecustomize` module on `PYTHONPATH` as local state for every other start.
- Cases: "__future__ beside the checker is ignored", "__future__ on PYTHONPATH is ignored", "__future__ beside the checker is ignored with -B".

**Blocking 4 (AC-4 strategy sentence false for the fast and media tiers) — fixed.** AVE-REQ-093 § Verification strategy AC-4 now states the rule as `scripts/verify.d/95-evidence.sh` and README § Definition of Done item 4 hold it. Document only.

**Non-blocking 1 (raw HTML inside a line) — stated as a limit in the committed tree; the decided rule is open.** README § Canonical form rule 4 and AVE-REQ-093 § Edge cases and § Verification strategy AC-3 say that a tag inside a line is outside the reader's rules and who judges it. Reason and patch: § Open item.

**Non-blocking 2 (list labels, tilde fences) — fixed.** `ROADMAP_LISTS`, `LIST_LIKE` and the fence handling of `read_roadmap()`. Cases: "requirement list under another label fails", "requirement list with another bullet fails", "milestone list under the Deferred label fails", "Deferred list under the milestone label fails", "Proposed line in the Deferred group fails", "Proposed line under another label fails", "indented upper-case list under a plus bullet fails", "second requirement list in one entry fails", "second Proposed line in one entry fails", "tilde fence around a roadmap list fails", "four-backtick fence in the roadmap fails", "indented fence in the roadmap fails", "roadmap list inside a fenced block is no list", "unclosed fence in the roadmap fails", "longer fence line inside a roadmap fence fails".

**Non-blocking 3 (gate change of a successor) — fixed.** `check_supersession()`. Cases: "successor under another milestone is reported", "successor under the baseline gate reports no gate change".

**Non-blocking 4 (faithful chain fails) — fixed.** `check_derived()` takes every ID the chain visits. Cases: "faithful chain through a superseded successor is reported", "derived requirement in the middle of a human chain fails".

**Non-blocking 5 (no case needs the chain-end dependency rule) — fixed.** Cases: "v1 requirement depends on one replaced by a deferred requirement fails", "v1 requirement depends on one whose replacement is missing fails", "v1 requirement depends on one replaced by a version-one requirement passes". The reviewer's surviving mutant now fails the first two.

**Non-blocking 6 (one number, two paddings) — fixed.** `check_numbers()`. Cases: "second ID for one number fails", "baseline number under another padding fails".

**Non-blocking 7 (status moves without a note) — fixed.** `check_requirements()` (imported requirement in `proposed`) and `check_parent_completion()`. Cases: "imported requirement set back to proposed fails", "feature done while its requirements are unfinished fails", "feature done with one unfinished requirement fails", "epic done while a feature is unfinished fails", "feature box ticked before done fails", "capital-X feature box under a plus bullet fails", "star-bullet feature box before done fails", "indented ordered feature box before done fails", "feature box ticked without a done log line fails", "epic box ticked before done fails", "feature box ticked after reopening fails", "done feature with every requirement done passes", "done feature leaves its deferred requirement out", "done feature leaves a superseded requirement out", "feature superseded after done keeps its ticks".

**Non-blocking 8 (mark of 32 bits) — fixed.** `digest()` returns sixteen hex digits. Case: "mark of eight digits does not count"; every case that asserts a printed marker computes sixteen digits with `sha256sum`.

**Non-blocking 9 — track A share fixed.** Rule 5 of the mapping is reworded in `scripts/requirements/import_baseline.py` and `docs/requirements/IMPORT_MAPPING.md` is regenerated (one line differs). ADR-003 decision 5 and the `verification` log line are the lead's (§ Proposed text).

### Changes (file — purpose)
- `scripts/reqfile.py` — character allow-list; headings and underlines judged on every reading of a line; marker reason with a letter or digit; marks of sixteen digits; docstring.
- `scripts/check_baseline.py` — restart as the first statements; `check_numbers`; `check_parent_completion`; imported requirement never `proposed`; gate-change note for a successor; `source: human` along a whole chain; `read_roadmap` with the exact Status line, template labels and fence rule; usage text; docstring.
- `scripts/requirements/import_baseline.py` — rule 5 of the mapping text.
- `docs/requirements/IMPORT_MAPPING.md` — regenerated.
- `scripts/tests/test-check-baseline.sh` — 81 new cases; helpers `parent_done`, `rep_entry`, `milestone_status`, `wrap_milestone`, `planted_future`; marks of sixteen digits; `link()` reads the ID by pattern.
- `docs/requirements/README.md` — § IDs and files rule 1; § Canonical form intro and rules 1, 3, 4; § Status lifecycle rules 6 and 8; § Changing requirements rule 1; § Superseding step 2; § Baseline import rule 4; § Enforced checks items 3, 5, 9, 10 and the closing paragraph.
- `docs/ROADMAP.md` — § Rules rule 8 only.
- `docs/requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md` — § Edge cases, § Verification strategy (AC-1, AC-3, AC-4), § Implementation evidence.

### Tests (AVE-REQ-093 AC-n → test location)
- AVE-REQ-093 AC-1 → `scripts/tests/test-check-baseline.sh`, comment-tagged blocks: immutability, the isolation block with the three `__future__` cases, "second ID for one number fails", "baseline number under another padding fails".
- AVE-REQ-093 AC-2 → inspection (unchanged; judged by `verify-requirement`).
- AVE-REQ-093 AC-3 → `scripts/tests/test-check-baseline.sh`, comment-tagged blocks: canonical form, marker reason and mark, supersession chain and gate change, chain-end dependencies, roadmap Status lines, labels and fences.
- AVE-REQ-093 AC-4 → `scripts/tests/test-check-baseline.sh`, block tagged `AVE-REQ-093 AC-3, AVE-REQ-093 AC-4` (imported requirement back in `proposed`, epic and feature completion, ticked boxes); `scripts/tests/test_evidence.py` unchanged.

### Mutation list (mutant → failing case)
One replacement per copy under the container's `/tmp`, every `__pycache__` deleted first. Each mutant ran against the cases whose names match a filter plus "clean import passes"; the filter exists only in the copy's `run_case`. The unmutated suite passes whole (294 of 294). The list below is the rerun on the tip `48b5e9d`: 52 mutants, 52 fail a named case, and "clean import passes" holds under every one.

`scripts/reqfile.py`
- R1a every character above U+007F allowed → "Hangul filler fails", "braille blank fails", "combining grapheme joiner fails", "Hangul choseong filler fails", "letter outside the allow-list fails" (and the no-break space, line separator and byte-order mark cases)
- R1b U+2282 removed from `EXTRA_CHARACTERS` → "signs of the allow-list pass"
- R1c lower bound moved to the tab → "tab fails" (and the form feed and two carriage-return cases)
- R12a upper bound moved to U+007F → "delete character fails"
- R12b lower bound moved to U+001F → "unit separator fails"
- R2 at most three leading spaces stripped → "heading on an ordered-list continuation line fails", "heading on a wide bullet continuation line fails", "underlined heading inside a list item fails"
- R3 underline judged on the first reading only → "underlined heading inside a quote fails", "dash-underlined heading inside a quote fails", "underline behind a list marker fails", "underlined heading in a feature's list section fails"
- R4 one space consumed after a marker → "heading behind a wide list marker fails", "heading behind an ordered marker in a quote fails"
- R5 no `N)` marker → "heading behind an ordered marker in a quote fails"
- R10 no `N.` marker → "heading behind an ordered marker fails"
- R5b no `>` marker → "heading inside a quote fails", "heading right behind a quote sign fails" (and four more)
- R9 dash bullets only → "heading behind a star bullet fails", "heading behind a plus bullet fails"
- R8 a heading needs a space after the hashes → "bare hashes in a quote fail", "bare hashes on a line fail"
- R11a underline without trailing spaces → "underline with trailing spaces fails"
- R11b underline of two or more characters → "one-character underline fails"
- R6 any non-empty reason → "reason of punctuation alone does not count", "reason of one invisible character does not count"
- R7 mark of eight digits → "mark of eight digits does not count", "altered criterion with recorded change", "rewritten description with recorded change"

`scripts/check_baseline.py`
- C1 `from __future__ import annotations` before `import os` → "__future__ beside the checker is ignored", "__future__ on PYTHONPATH is ignored", "__future__ beside the checker is ignored with -B"
- C2 number rule off → "second ID for one number fails", "baseline number under another padding fails"
- C3 imported-proposed rule off → "imported requirement set back to proposed fails"
- C4 unfinished-children rule off → "feature done while its requirements are unfinished fails", "feature done with one unfinished requirement fails", "epic done while a feature is unfinished fails"
- C4b deferred children count as unfinished → "done feature leaves its deferred requirement out"
- C4c superseded children count as unfinished → "done feature leaves a superseded requirement out"
- C5 ticked-box rule off → "feature box ticked before done fails", "feature box ticked after reopening fails" (and four more)
- C5b small x only → "capital-X feature box under a plus bullet fails"
- C5c section fixed to Feature acceptance → "epic box ticked before done fails"
- C5d ticks only while `done` → "feature superseded after done keeps its ticks"
- C5e no done log line needed → "feature box ticked without a done log line fails"
- C5f dash bullets only → "capital-X feature box under a plus bullet fails", "star-bullet feature box before done fails"
- C5g no ordered markers → "indented ordered feature box before done fails"
- C5h column 0 only → "indented ordered feature box before done fails"
- C6 successor gate note off → "successor under another milestone is reported"
- C7 chain end only → "faithful chain through a superseded successor is reported", "derived requirement in the middle of a human chain fails"
- C8a text allowed after the Status word → "milestone Status done with a full stop fails", "milestone Status with a note fails"
- C8b count rule off → "milestone without a Status line fails", "milestone with two Status lines fails"
- C8c Status lines found by the prefix only → "indented milestone Status line fails"
- C8d any letter case → "capitalised milestone Status fails"
- C8e any lower-case word → "unknown milestone Status word fails"
- C9a any label that opens with `- **Requirements` → "requirement list under another label fails", "milestone list under the Deferred label fails"
- C9b label problem off → the seven label cases
- C9c second-list rule off → "second requirement list in one entry fails", "second Proposed line in one entry fails"
- C9d `- **Requirements:**` accepted under a milestone → "milestone list under the Deferred label fails"
- C9e any label that opens with `- **Proposed` → "Proposed line under another label fails" (this mutant survived at `6ee69da`; the second commit adds the case)
- C9f, C9g, C9h `LIST_LIKE` case-sensitive, column 0 only, without `+` → "indented upper-case list under a plus bullet fails"
- C10a fence lines found by a leading run of three backticks only → "tilde fence around a roadmap list fails", "indented fence in the roadmap fails"
- C10b every fence-like line opens a block → "tilde fence around a roadmap list fails", "four-backtick fence in the roadmap fails", "indented fence in the roadmap fails"
- C10c open fence at the end accepted → "unclosed fence in the roadmap fails"
- C10d a fence never opens → "roadmap list inside a fenced block is no list"
- C10e fence lines inside a fence accepted → "longer fence line inside a roadmap fence fails"
- C11 chain-end dependency rule off (the reviewer's survivor) → "v1 requirement depends on one replaced by a deferred requirement fails", "v1 requirement depends on one whose replacement is missing fails"

No mutant for the reworded rule 5: it is text; `check_mapping` fails a stale `IMPORT_MAPPING.md` on the real tree.

### Verification (command — result)
- `./scripts/verify.sh --tier release` on the final tree (the tree of `48b5e9d`, run before that commit, tree unchanged since) — PASS, `verify.sh: PASS — tier release (13 of 13 steps passed)`; test-check-baseline.sh 294 checks, test-checker.sh 822, test-stop-hook.sh 98, test-session-start.sh 31, test-verify-tiers.sh 48, test-probe-environment.sh 28; Backend media and population tests PASS; Working tree unchanged PASS; Evidence manifest PASS.
- `./scripts/verify.sh --tier release` on the tree of `6ee69da` before that commit — PASS, 13 of 13 steps, test-check-baseline.sh 276 checks.
- `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` at the tip — PASS, `BASELINE TOTAL: pass=294 fail=0`.
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py` at the tip — PASS, exit 0, `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`; 104 working requirements, 0 of 404 criteria ticked, no Recorded change, Gate change or Supersession line.
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 --require-fresh --tier release` at the tip — exit 0, `Freshness: FRESH`; AC-1 passed, AC-2 missing (inspection only), AC-3 passed, AC-4 passed.
- `./scripts/dev-container.sh bash scripts/check-project-control.sh` — PASS, 0 warnings.
- `./scripts/dev-container.sh python3 -B scripts/requirements/import_baseline.py --check` — `unchanged: docs/requirements/IMPORT_MAPPING.md`, would create 0.
- Reference: the suite on the base tree — `BASELINE TOTAL: pass=213 fail=0`.
- Scan of the 134 working files with the tightened rules — no line flagged by the character, heading or underline rules; the raw-HTML rule flags AVE-REQ-098 lines 47 and 48 and nothing else.

### Open item: the raw-HTML rule
- Decision of the brief: "Raw HTML (`<` before a letter, `/`, `!` or `?`) fails outside code spans and fenced blocks."
- Why it is absent from the commits: the rule flags AVE-REQ-098 § Edge cases, line 47 (`launched <date>;`) and line 48 (`re-run <exact command>`). Both placeholders stand in quoted text outside code spans; a Markdown reader takes them for tags and drops them. The file is on the forbidden list of every track, and the commit instruction requires a passing release tier, so the rule cannot land on this branch before the lead changes those two lines.
- What the lead gets: two patches made against the tip, tested on a copy of the tree in the container.
  - `req098.clean.patch` (SHA-256 `a3f5b6d07849232fc01d74a6955d6f0d7fe1660e6745560077cc6345a1cd37e9`) — the two lines of AVE-REQ-098, text under § Proposed text item 1.
  - `rule.clean.patch` (SHA-256 `9b1852e20e437bb8553a7e85bc8ed5e2dbce11a52f325d0fdb9d63bd9c2fb732`, 175 lines) — `scripts/reqfile.py`, 11 suite cases, README § Canonical form (intro sentence and rule 4), AVE-REQ-093 § Edge cases and § Verification strategy AC-3.
  - Locations: the container directory `/tmp/track-a/html/` (it lives as long as the development container of this checkout), and the scratchpad directory of the launching session as `a_req098.patch` and `a_html_rule.patch` (same hashes). `git apply --check` passes for both on the tip.
- Results on the copy with both patches: `python3 -I -B scripts/check_baseline.py` → `OK: baseline intact`; the suite → `BASELINE TOTAL: pass=305 fail=0`. With the rule and without the AVE-REQ-098 change the checker ends with exactly two errors (lines 47 and 48, `raw HTML outside a code span`).
- Mutants of the patch (six, each fails a named case): no `/` in the pattern → "closing tag inside a line fails"; no `!` and `?` → "declaration inside a line fails", "processing instruction inside a line fails"; unpaired runs accepted → "tag between spans of two lines fails", "run of backticks unpaired on its line fails"; no backslash handling → "tag behind escaped backticks fails"; rule off → eight cases; code spans ignored → "tags inside code spans and fenced blocks pass".
- The rule needs a second rule to be exact: a code span opens and closes on one line (a run of backticks that stays unpaired on its line fails). Without it a span that reaches over a line end pairs differently for a Markdown reader than for a line-by-line reader, and a tag between two such spans passes. No working file holds an unpaired run today.
- Core of the patch, should both copies be gone. Constants and function in `scripts/reqfile.py`:

````python
# Raw HTML outside code spans: "<" before a letter, "/", "!" or "?".
RAW_HTML = re.compile(r"<[A-Za-z/!?]")
# The characters a backslash makes plain text (CommonMark: ASCII punctuation).
ESCAPABLE = frozenset("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")


def outside_code_spans(line: str):
    """(The text of a line outside its code spans, whether a run of backticks stays unpaired)."""
    kept, position, unpaired = [], 0, False
    while position < len(line):
        char = line[position]
        if char == "\\" and line[position + 1 : position + 2] in ESCAPABLE:
            kept.append(line[position : position + 2])
            position += 2
            continue
        if char != "`":
            kept.append(char)
            position += 1
            continue
        end = position
        while line[end : end + 1] == "`":
            end += 1
        closer = None
        for run in re.finditer(r"`+", line[end:]):
            if len(run.group()) == end - position:
                closer = end + run.end()
                break
        if closer is None:
            unpaired = True
            kept.append(line[position:end])
            position = end
        else:
            kept.append(" ")
            position = closer
    return "".join(kept), unpaired
````

  and in `ReqFile._body`, directly before `forms = readings(line)` (so the H1 and the template headings are judged too):

````python
            plain, unpaired = outside_code_spans(line)
            if unpaired:
                self._problem(
                    f"line {number}: a run of backticks stays unpaired; a code span opens and"
                    f" closes on one line ('{line[:50]}')"
                )
            if RAW_HTML.search(plain):
                self._problem(
                    f"line {number}: raw HTML outside a code span"
                    f" ('{plain[RAW_HTML.search(plain).start() :][:30]}')"
                )
````

- Cases of the patch: "tag at the end of a line fails", "strike tag inside a line fails", "closing tag inside a line fails", "declaration inside a line fails", "processing instruction inside a line fails", "placeholder in angle brackets fails", "tag behind escaped backticks fails", "tag between spans of two lines fails", "run of backticks unpaired on its line fails", "tag in the title of a derived requirement fails", "tags inside code spans and fenced blocks pass".
- After the patch, text the lead or the other tracks add to any requirement file fails when it holds `<` before a letter outside a code span or a code span wrapped over a line end; rerun the checker after the proposed texts for AVE-REQ-096, AVE-REQ-097 and AVE-REQ-098 are in.
- Recommended resolution: in the merge, apply `req098.clean.patch` and `rule.clean.patch`, then run `./scripts/verify.sh --tier release` (expected: test-check-baseline.sh 305 checks). The alternative is to keep the limit as committed; the reviewer's finding names both resolutions.

### Proposed text for lead-owned documents
1. `docs/requirements/AVE-REQ-098-…md` § Edge cases, lines 47 and 48 (the two placeholders move into code spans, each on its own line):

````text
- Delegated work in flight when the session stops → PROGRESS.md records it stop-safe ("launched `<date>`;
  verdict not recorded; on resume without a recorded verdict, re-run `<exact command>`"); check 7 fails on a
````

2. `docs/decisions/ADR-003-requirements-baseline-import.md` decision 5 (part 5 non-blocking 9): replace "an acceptance criterion differs from the baseline without a logged `AC-n changed:` line" by "an acceptance criterion or the Description differs from the baseline without its marker line (`AC-n changed [<mark>]: <reason>`, `AC-n removed: <reason>`, `AC-n added [<mark>]: <reason>`, `Description changed [<mark>]: <reason>`; the mark is the first sixteen hex digits of the SHA-256 of the new text)".
3. `docs/TRACEABILITY.md` lines 112 and 155: `python3 scripts/check_baseline.py` → `python3 -I -B scripts/check_baseline.py` (the isolated start is the one the documents guarantee).
4. AVE-REQ-093 `## Status`: a line for this round, and the `verification` line before the next review request (part 5 non-blocking 9). Suggested text of the first: "fixes of the final review from branch `m0-final-fixes-a`: characters by allow-list, headings judged behind leading spaces and container markers, one exact Status line per milestone entry, roadmap lists by template label, the restart as the checker's first statements, marks of sixteen digits, status rules for imported requirements, features and epics; the rule for a tag inside a line is decided with the handback".
5. `docs/ASSUMPTIONS.md` — proposed entries:
   - Characters of requirement files — assumption: the seven signs the working files held on 2026-10-06 suffice beside U+0020 to U+007E — reason: an allow-list closes every invisible class at once (decision of the fix brief) — impact: any other character (an accented letter, a typographic quote, `≤`, `×`, sample text for AVE-REQ-036) fails "Requirements baseline integrity" until `EXTRA_CHARACTERS` in `scripts/reqfile.py` grows in a reviewed change.
   - Children that count for a `done` epic or feature — assumption: every child that is neither superseded nor deferred (README § Status lifecycle rule 6) — reason: AVE-FEAT-014 holds the deferred AVE-REQ-067, and "every non-superseded child" read literally would bar it from `done` for good — impact: a deferred child never blocks its parent.
   - Marker reason — assumption: a reason holds a letter or digit of U+0020 to U+007E — reason: Python's `str.isalnum()` counts U+3164 and U+115F as letters — impact: none for text inside the allow-list.
   - Roadmap entry form — assumption: one `Proposed during …` line per milestone entry, none in the Deferred group, and fence lines as in the requirement files — reason: "one of each per entry" in the fix brief — impact: a later round of proposals under one milestone extends the existing line.
   - Mark width — assumption: sixteen hex digits (64 bits) — reason: a deliberate search for a second text with one mark costs about 2^64 SHA-256 evaluations — impact: none, no working file holds a mark yet.
6. `docs/TRACEABILITY.md` row AVE-REQ-093: no change (same implementation and test files).
7. Track B2: the hint in `scripts/evidence.py` (`form_problems`) names `python3 scripts/check_baseline.py`; the documents now guarantee the isolated command only.

### Deviations, open issues, discovered work
- Open: the raw-HTML rule (§ Open item). It is the one decision of Track A that the commits do not carry.
- "every non-superseded child is `done`" of the brief is implemented as "every child that is neither superseded nor deferred", following README § Status lifecycle rule 6 (assumption 2 above). Recommended resolution: keep; cases "done feature leaves its deferred requirement out" and "done feature leaves a superseded requirement out" pin both exemptions.
- Roadmap rules beyond the wording of the brief, all inside its decisions' intent: the fence rule is the whole rule of the requirement files (tilde, longer, indented and unclosed fences and a fence line inside a fence fail); the Deferred group accepts no Proposed line; a list-like line under any other label fails with a message of its own (without that message it would fail as "stands on no list" only when it carried a requirement).
- The ticked-box rule mirrors the requirement rule: a box needs status `done` and a `done` log line; a file superseded after it was done keeps its ticks.
- The brief names `import os, sys`; the checker holds two import lines, `import os` and `import sys`, followed by the restart.
- Two commits: the mutant of the Proposed-line label survived the first set of cases, so a second commit adds 18 cases and ends the three label patterns at the label. The release tier passed again on the final tree before that commit.
- Mutation runs executed filtered subsets of the suite (see § Mutation list); the whole suite ran unmutated on both commits.
- Once, for a style comparison with the base tree, I ran `git stash` and `git stash pop` in the worktree. Stashes are shared by all worktrees of the repository; the stash list was empty afterwards and the diff was intact. No further stash use.
- This report gives repository-relative paths, following the brief's rule that no file holds a local user path.
- Discovered work, proposed follow-ups:
  - Supersession of derived requirements (parent AVE-FEAT-019): `check_baseline.py` checks the replacement and the `superseded` log line for baseline requirements only; a derived requirement (AVE-REQ-102 onward) set to `superseded` is covered by the dependency rule and by check 6 of `check-project-control.sh`. Either a rule or a stated limit.
  - Track B2, from the reviewer's test-quality note on AC-4: a unit test in `scripts/tests/test_evidence.py` that states what `check-done --tier fast` and `--tier media` accept (a criterion whose tagged tests exist and did not run).
  - Runtime: the baseline suite takes about six minutes in the release tier with 294 cases (213 before).
- Pre-existing failures: none observed.
