# Handback — M0 gates red-team, part 5: review of AVE-REQ-093 after the fixes

Run `wf_7d9d015c-906` ([script](../../workflows/verify-m0-final-wf_7d9d015c-906.js)), the final review round of M0 launched 2026-10-06: `verify-requirement` for AVE-REQ-093 at `2df637f` by an independent reviewer in a private clone. The report is the reviewer's, unedited apart from local paths. The run had no brief of its own ([WF-008](../../WORKFLOW_LOG.md)); the report is filed with the brief whose work it reviews. The fixes follow in [the fix brief](../2026-10-06-m0-final-review-fixes.md).

## Review

Verdict: **FAIL** — AVE-REQ-093 — Adopt and preserve the supplied requirements baseline (reviewed at 2df637f in a private clone; the main checkout moved to 547754e during the review through another session and was never written to)

### AC-1 Preserve this input package as an immutable baseline and map every AVE-REQ ID to its canonical working requirement file. — PASS

```text
Test: scripts/tests/test-check-baseline.sh (comment tags AVE-REQ-093 AC-1; sections (a) immutability, (c) one working file per ID, mapping) passed in my release run (213 of 213 checks) and standalone (213 of 213, 188 s). Real tree: `python3 -I -B scripts/check_baseline.py` exit 0, manifest pin PASS, 133 manifest entries verified, 10 epics / 20 features / 101 requirements match. Inspection: `git diff --quiet 6160278 HEAD -- ai-video-editor-requirements` is empty; the only commit touching the package is 6160278; SHA-256 of MANIFEST.json at HEAD and at 6160278 equals the pinned 140307b86ab7...6e05. Own oracle (my own parser, baseline Markdown instead of the JSON the importer reads): 101 baseline IDs, each with exactly one working file and an IMPORT_MAPPING.md row linking it, 0 problems. Own constructions, each exit 1 with the expected message: byte appended to spec/ACCEPTANCE_TESTS.md, same-size edit of intake/USER_BRIEF.md, empty file added under spec/requirements/, file removed behind an edited validator (validator not run), validator removed, file edited with its manifest entry re-hashed (pin fails), file replaced by a directory, working file renamed / removed / duplicated, IMPORT_MAPPING.md row edited by hand. Handback 093-C-1 and 093-C-2 reproductions rejected. Mutants of the pin, the second-file rule, the restart and the source loading each fail a named case. Caveat: this holds for the isolated start that verify.sh and CI use; blocking finding 3 covers the start without -I.
```

### AC-2 Populate the existing PRODUCT, ARCHITECTURE, ROADMAP, PROGRESS, ASSUMPTIONS, and TRACEABILITY documents without losing meaningful existing content. — PASS

```text
Inspection (the level § Verification strategy names; automation cannot judge 'meaningful'). For each document I compared the bootstrap version (`git show f605c6c:docs/<file>`) with HEAD: commits since f605c6c 1/10/5/23/9/12; lines 105→256, 151→339, 94→212, 52→94, 73→341, 160→211; `_TBD` placeholders 15/14/2/0/0/0 → 0 in all six. Every bootstrap H2 heading is still present in PRODUCT, ARCHITECTURE, PROGRESS, ASSUMPTIONS and TRACEABILITY (diff of heading lists: identical sets); in ROADMAP only the placeholder section `## Product phases` is gone, replaced by `## Phase 2 — Version-one product delivery` as that placeholder instructed. I read every removed bootstrap line (`git diff f605c6c HEAD -- docs/<file> | grep '^-'`): placeholders, superseded status lines, and rules rewritten for the AVE ID scheme. Spot checks of rewritten rules in ARCHITECTURE.md: deterministic tests, 'Never weaken', CLAUDE_VERIFY_MAX_ATTEMPTS, CLAUDE_VERIFY_GATE, manual dispatch, the Stop gate all still stated; PRODUCT.md completion list keeps items 1-7 and extends them; ASM-001 to ASM-003 kept with their confirmations.
```

### AC-3 Explicit user requirements and exclusions cannot be demoted or rewritten merely to fit an easier implementation. — FAIL

```text
Current state is clean: my oracle finds all 101 working requirements equal to the baseline Markdown in title, mapped type and priority, parent, scope, origins, scenarios, dependencies, source, primary gate, Description and all 404 criteria; no marker line, no gate change, no supersession. The suite's AC-3 cases passed in the release run, every handback finding I repeated (093-A-1/2/3/4/6/8/10, 093-B-1/2/3/4/6/7/8) is rejected now, and 34 of 35 mutants die on a named case. The criterion still fails because two rules the requirement states as enforced do not hold for other spellings: (1) headings outside the template in list-item and quote form pass both checkers and the done gate, so § Edge cases of AVE-REQ-001 can carry a second rendered `Acceptance criteria` heading with a weakened AC-2, and AVE-FEAT-001 can show ten of its must requirements under a rendered `Out of scope for version one` heading (blocking finding 1); (2) a milestone whose Status reads `done.`, `Done` or `done, reviewed ...` passes while its five requirements are in-progress (blocking finding 2). § Verification strategy AC-3 says these forms 'all fail'.
```

### AC-4 Requirement implementation status starts unverified; package validation is not product verification. — PASS

```text
Tests: scripts/tests/test-check-baseline.sh (tags AVE-REQ-093 AC-4: fresh import reports `by status: ready 99, deferred 2` and `ticked: 0 of 404`; tick rules; capital-X tick, quoted or repeated status, second criteria heading) and scripts/tests/test_evidence.py (three tests tagged AVE-REQ-093 AC-4; 32 tests OK) passed in my release run; `evidence.py show AVE-REQ-093 --require-fresh --tier release` lists AC-4 passed with both files. Real tree: 0 done requirements, 0 of 404 criteria ticked (checker and my oracle agree); step 'Done requirements evidenced by this run' is separate from the package checks. Probes on a copy of the tree, `check-done --tier release` on a run without evidence: plain done-on-paper AVE-REQ-001 exit 1 (four `missing in this run`), capital-X ticks exit 1, quoted status exit 1, AVE-REQ-0110 beside a done AVE-REQ-011 exit 1, four free-text inspection lines under a strategy that names tests exit 1. Mutants of the tick rule, the done-with-_TBD rule and the criteria-only rule each fail a named case. Caveat: the strategy's sentence about every tier is false for the fast and media tiers (blocking finding 4).
```

### Verification runs

```text
- Setup: private clone .claude\worktrees\verify-ave-req-093 at 2df637f, `git status --porcelain` empty before every evidence run; probes and mutants ran only in the clone's container under /tmp (a `git archive HEAD` copy and per-mutant copies).
- `./scripts/verify.sh --tier release` → exit 0, `verify.sh: PASS — tier release (13 of 13 steps passed)`. Requirements baseline integrity PASS (`Baseline files: PASS ... all 133 manifest entries`, `OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files`); Evidence tooling unit tests PASS (32 tests OK); Backend media and population tests PASS; test-check-baseline.sh PASS (`BASELINE TOTAL: pass=213 fail=0`); Done requirements evidenced by this run PASS (0 done requirements); Working tree unchanged PASS; Evidence manifest PASS (58 criteria tagged).
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 --require-fresh --tier release` → exit 0, `Freshness: FRESH`, AC-1 passed (scripts/tests/test-check-baseline.sh), AC-2 missing (inspection only), AC-3 passed (same suite), AC-4 passed (the suite and scripts/tests/test_evidence.py).
- `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` → exit 0, `BASELINE TOTAL: pass=213 fail=0`.
- `./scripts/dev-container.sh python3 -I -B scripts/check_baseline.py` → exit 0: 104 working requirements, `by status: proposed 3, ready 84, in-progress 15, deferred 2`, `Acceptance criteria ticked: 0 of 404 (version one: 0 of 398)`, no Recorded change, Gate change or Supersession line.
- Own oracle (my parser over the 101 baseline Markdown files and the working files) → 0 problems; 404 baseline criteria, 404 working criteria, 0 ticked; statuses ready 84, in-progress 15, deferred 2.
- Git inspection → package unchanged since 6160278, pinned hash equals the manifest hash at 6160278; six documents compared with f605c6c (AC-2).
- Handback reproductions, all rejected now: 093-A-1 (capital-X ticks, quoted status: canonical-form errors and check-done exit 1), 093-A-2 (`---` plus no-break space), 093-A-3 (repeated keys, both checkers), 093-A-4 (HTML comment around Description and criteria), 093-A-6 (0000-00-00 done line), 093-A-8 (quoted rule, other requirement ID, one line for three removals), 093-A-10 (link under Out of scope); 093-B-1 (dropped from ROADMAP, successor on no list, M0 done, exclusion on M3), 093-B-2, 093-B-3(a)(b), 093-B-4, 093-B-6 (second edit and the old unmarked line), 093-B-7, 093-B-8; 093-C-1 (planted __pycache__ of the import tool; hashlib beside the checker), 093-C-2 (PYTHONPYCACHEPREFIX, hashlib on PYTHONPATH), each also with `python3 -B` and plain `python3`; critic-093-1 (AVE-REQ-0110 beside a done AVE-REQ-011: check-done exit 1), critic-093-2 (free-text inspection lines: check-done exit 1).
- New probes that the gates accept (exit 0): five heading forms in list items and quotes (N2a-e) and the feature-file variant; inline `<details>` and `<s>` mid-line; invisible reason characters U+3164, U+2800, U+034F, U+115F; M0 Status `done.`, `done, reviewed 2026-10-06`, `Done`, `**done**`, `complete`, `` `done` `` with five in-progress requirements; a list line labelled 'Requirements removed from version one (not built)'; the M1 list inside a tilde fence; successor of AVE-REQ-001 under M7 without a Gate change note; AVE-REQ-0103 beside AVE-REQ-103; AVE-REQ-001 back to `proposed` on a Proposed-during line; AVE-FEAT-002 set to done with its acceptance box ticked. `python3 scripts/check_baseline.py` and `python3 -B scripts/check_baseline.py` print `OK: baseline intact` (exit 0) over a demoted priority with `scripts/__future__.py`, with `__future__.py` on PYTHONPATH and with `sitecustomize.py` on PYTHONPATH; `python3 -I -B` exits 1 in all three. `check-done --tier fast` and `--tier media` exit 0 for a done AVE-REQ-093 on an empty run directory; `--tier release` exits 1.
- New probes that the gates reject (exit 1): heading inside a quote inside a list continuation, heading on the marker line, two-space continuation heading, `<details>` at a line start, empty marker reason, dependency on a derived requirement whose replacement is deferred (`whose replacement is the deferred AVE-REQ-107`), eleven package and mapping constructions (AC-1 row). A faithful chain 001 → 105 → 106 exits 1 (non-blocking finding 4).
- Mutation, one replacement per copy under /tmp/mut, every __pycache__ deleted, then the suite there: 35 valid mutants, 34 fail on named cases. scripts/reqfile.py: space class, repeated key, HTML comment, container heading, log order, marker anywhere, criteria-only section, mark of 7 digits, key order, blank line and H1, placeholder reason, HTML line, underline. scripts/check_baseline.py: ticks after reopening, listed twice, done milestone, successor scenarios, cycles, second derived file, no restart (fails 'hashlib beside the checker is ignored' and 'hashlib on PYTHONPATH is ignored'), cached import, exclusion on a milestone, Dependencies section, manifest pin, exclusion supersession, Proposed line, done with _TBD, link anywhere, roadmap comment, roadmap link text, successor priority, superseded log line, under a deferred feature, listed without a file. Survivor: `elif end is None or end.get("status") == "deferred" or end.get("scope") == "future":` → `elif False:` leaves `BASELINE TOTAL: pass=213 fail=0`. One mutant of mine was syntactically broken by my own escaping and is discarded; its corrected form is counted.
- Cleanup: `./scripts/dev-container.sh --stop` exit 0 (`state absent`), clone removed with `rm -rf`, main checkout `git status --porcelain` empty; no commit, no push, no `git worktree prune`.
```

### Blocking findings (4)

1.

```text
location: scripts\reqfile.py:94-96, 109-113, 235-266; docs\requirements\AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md:52-57 (§ Edge cases) and :109 (§ Verification strategy AC-3); docs\requirements\README.md:83-91 (§ Canonical form rules 1 and 3)
defect: The canonical form admits headings that a CommonMark reader renders, although the requirement says a heading outside the template fails 'in any Markdown form' and that list-item and quote forms 'all fail'. Accepted by the reader, by both checkers and by the done gate: an ATX heading on a list-item continuation line indented four or more spaces (ordered marker or wide bullet marker), a setext heading inside a quote (`===` or `---`), a setext heading inside a list item. Invisible characters outside the classes Cc, Cf, Zl, Zp, Zs also pass, against 'an invisible character → fails' and README rule 1 ('zero-width characters included'), and a marker line whose reason is one such character counts as a logged reason.
evidence: On a `git archive HEAD` copy, `python3 -I -B scripts/check_baseline.py` → exit 0 `OK: baseline intact` (and `bash scripts/check-project-control.sh` → exit 0) after inserting under `## Edge cases` of AVE-REQ-001 each of: (a) `10. See the revised list.` / `    ## Acceptance criteria` / `    - [ ] AC-2 Saved projects are restored on a best-effort basis.`; (b) `-   Revised list.` / `    ## Acceptance criteria`; (c) `> Acceptance criteria` / `> ===` / `> AC-2 is informational for version one.`; (d) the same with `> ---`; (e) `10. Acceptance criteria` / `    ===`. markdown-it-py 4.2.0 (commonmark preset) lists for each a second heading `Acceptance criteria` (h2 or h1) between `Edge cases` and `Dependencies`. Controls fail as documented: `- ## Acceptance criteria`, `- x` / `  ## Acceptance criteria`, `    > ## Acceptance criteria`. Feature file: in AVE-FEAT-001 § Requirements, `> Out of scope for version one` / `> ---` inserted before the AVE-REQ-002 item → both checkers exit 0; the reader shows `Requirements (1 requirement link) | Out of scope for version one (10 requirement links)`. Characters: AC-4 of AVE-REQ-001 removed with the log line `AC-4 removed: <U+3164>` (also U+2800, U+034F, U+115F) → exit 0, `Recorded change: AVE-REQ-001 AC-4 is missing — <invisible>`; the control with an empty reason exits 1.
fix: In scripts/reqfile.py test for a heading after removing every leading space and container marker, whatever the indentation: fail an unfenced line that matches `^ *(?:(?:>|[-*+]|\d{1,9}[.)]) *)*#{1,6}(?: |$)` unless it is a template heading at column 0, and fail a line that matches `^ *(?:> *)*(?:=+|-+) *$`. For characters, either reject by an allow-list (printable ASCII plus the punctuation the files use) or reject default-ignorable and blank-glyph characters (U+034F, U+115F, U+1160, U+3164, U+FFA0, U+2800 and the Mn class outside composed letters) and require a marker reason to hold a letter or digit; otherwise reword 'an invisible character' and 'zero-width characters included' to the classes actually rejected. Add suite cases for the five heading forms, the feature-file variant and one invisible reason.
```

2.

```text
location: scripts\check_baseline.py:747-748 and :808-809; docs\requirements\AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md:74-77 (§ Edge cases) and :109; docs\ROADMAP.md:24-29 (rule 8)
defect: The rule 'a milestone with Status done that lists an unfinished requirement → fails' fires only when the first word after `- **Status:**` is exactly `done`. Any other spelling of a finished milestone disables it, and no gate validates the Status word against the template's `planned | in-progress | done`. This reopens the state of finding 093-B-1 (a milestone closed over unfinished must requirements, which `develop` then leaves behind) by another spelling.
evidence: On the copy: `### M0` set to `- **Status:** done.` with `- **Review:** 2026-10-06 — PASS — follow-ups: none` and M1 set to in-progress, AVE-REQ-093/094/096/097/098 all in-progress → `python3 -I -B scripts/check_baseline.py` exit 0 `OK: baseline intact`, `bash scripts/check-project-control.sh` exit 0. Same result for `done, reviewed 2026-10-06`, `Done`, `**done**`, `complete`, `` `done` ``. Control with the exact word `done` → exit 1, `ERROR: docs/ROADMAP.md: milestone M0 has Status done while AVE-REQ-093 is 'in-progress'` (five lines). Cause: line 748 takes `split()[0]` of the rest of the line and line 808 compares it with `"done"`.
fix: Read the Status line of each milestone entry with one pattern, for example `^- \*\*Status:\*\* (planned|in-progress|done)(?: — .*)?$`, and fail any other Status line of a `### M<n>` entry (missing included). Suite cases: 'milestone Status `done.` with an unfinished requirement fails', 'capitalised Done fails', 'unknown Status word fails'.
```

3.

```text
location: scripts\check_baseline.py:54-62 (and the docstring :48-51); docs\requirements\AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md:92-96 (§ Edge cases) and :107; docs\requirements\README.md:546-548
defect: 'A module beside the checker, or a Python variable of the environment (PYTHONPATH, PYTHONPYCACHEPREFIX) → changes no result' is false when the checker starts without -I, the case its self-restart exists for and the suite exercises (default command `python3 scripts/check_baseline.py`). `from __future__ import annotations` on line 54 runs before the restart on line 59, so a `__future__.py` beside the checker or on PYTHONPATH executes first; a `sitecustomize.py` on PYTHONPATH runs before any line of the script. The gate command of verify.sh and CI (`python3 -I -B`) is unaffected.
evidence: On the copy, with `priority: must` of AVE-REQ-001 changed to `should`: (a) `scripts/__future__.py` that loads the real module, prints the OK line and exits 0 → `python3 scripts/check_baseline.py` exit 0 `OK: baseline intact; ...`, `python3 -B scripts/check_baseline.py` exit 0, `python3 -I -B scripts/check_baseline.py` exit 1 `frontmatter priority 'should' must equal the mapped baseline value 'must'`; (b) the same file in a directory named by PYTHONPATH → same three results; (c) `sitecustomize.py` on PYTHONPATH → `python3 -B scripts/check_baseline.py` exit 0, `-I -B` exit 1. Python 3.12.3 in the container: `os` is frozen, `__future__` is not loaded at startup. The suite's cases 'hashlib beside the checker is ignored' and 'hashlib on PYTHONPATH is ignored' run without -I (my mutant that removes the restart fails exactly these two), so the claimed scope includes this start. scripts/evidence.py:208 tells the reader to run `python3 scripts/check_baseline.py`.
fix: Remove the `__future__` import from scripts/check_baseline.py (or otherwise make `import os, sys` and the restart the first executed statements), and add suite cases '`__future__` beside the checker is ignored' and '`__future__` on PYTHONPATH is ignored'. A hostile PYTHONPATH still wins through `sitecustomize` before the script runs, so scope the statement in § Edge cases, § Verification strategy AC-1, the README and the docstring: the guarantee holds for the isolated start `python3 -I -B` that verify.sh and CI use; started without -I, the restart covers a module beside the checker and PYTHONPYCACHEPREFIX, and PYTHONPATH stays trusted. Change the hint in scripts/evidence.py:208 to the isolated command.
```

4.

```text
location: docs\requirements\AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md:110 (§ Verification strategy AC-4); behaviour in scripts\evidence.py:804-810 and scripts\verify.d\95-evidence.sh
defect: The sentence '`scripts/evidence.py check-done` (every tier) refuses a `done` requirement with a criterion that has neither a passing test in this run nor a recorded inspection that its Verification strategy line names' is false for the fast and media tiers: there a criterion whose tagged tests exist and did not run is accepted. Only the release tier refuses it. README § Definition of Done item 4 and the comment of 95-evidence.sh state the rule correctly; test-check-baseline.sh, the only test of AC-1 and AC-3, runs in the release tier alone.
evidence: On the copy: AVE-REQ-093 set to done on paper (ticks, done log line, one `AC-2 → inspection:` line), run directory empty. `python3 -B scripts/evidence.py check-done --dir <empty> --tier fast` → exit 0 `OK: no criterion of the 1 done requirements has failed, contract-only or missing evidence in this run (tier fast; ...)`; `--tier media` → exit 0; `--tier release` → exit 1 with `AVE-REQ-093 AC-1: 1 tagged test(s) did not run in this run` (also AC-3, AC-4). AC-1 has neither a passing test in that run nor an inspection, and the fast and media tiers do not refuse.
fix: Reword the AC-4 line: check-done refuses, in every tier, a `done` requirement with a criterion whose evidence in this run is failed, contract-only or missing; the release tier also refuses a tagged test that did not run, so there every criterion has a passing test or a recorded inspection that its Verification strategy line names.
```

### Non-blocking findings (9)

1.

```text
location: scripts\reqfile.py:97-98, 267-270; docs\requirements\README.md:92 (rule 4)
defect: Rule 4 rejects HTML comments and lines that start with `<`; raw HTML in the middle of a line passes. An unclosed `<details>` or `<s>` at the end of § Intent leaves the Description and the criteria inside that element for an HTML renderer. I did not render this in a browser: the claim about collapsing rests on the HTML parsing rules, the checker results are measured.
evidence: `... Details follow. <details>` appended to the last Intent line of AVE-REQ-001 → both checkers exit 0; markdown-it output: `<details></p>` followed by `<h2>Description</h2>`. Same for `<s>`. Combined with finding 1 (`</details>` mid-line in Edge cases, then the list-item heading): both checkers and check-done exit 0; reader HTML order is Intent with `<details>`, Description, Acceptance criteria, Edge cases with `</details>`, then `<ol start="10">` holding `<h2>Acceptance criteria</h2>` and the weakened AC-2. Control `<details>` at a line start → exit 1.
fix: Fail any raw HTML tag outside fenced blocks and code spans (`<` followed by a letter, `/`, `!` or `?`), with a suite case; or state the limit in rule 4 and § Edge cases.
```

2.

```text
location: scripts\check_baseline.py:729-755
defect: Any line that starts with `- **Requirements` counts as a requirement list, whatever its label, and a list inside a `~~~` fence counts although a Markdown reader sees a code sample.
evidence: AVE-REQ-001 moved to a second M1 line `- **Requirements removed from version one (not built):** [AVE-REQ-001](...)` → both checkers exit 0. The M1 list wrapped in `~~~` → exit 0.
fix: Accept the template labels only (`- **Requirements (dependency order):**`, `- **Requirements:**` in the Deferred group, `- **Proposed during ...:**`), one of each per entry, and treat or reject tilde fences; suite cases.
```

3.

```text
location: scripts\check_baseline.py:401-405 and 456-565
defect: A successor may stand under another milestone than the baseline gate of the requirement it replaces without a `Gate change` note; README § Baseline import rule 4 says a moved gate is reported.
evidence: Faithful successor AVE-REQ-105 of AVE-REQ-001 (baseline gate M1) with `primary_gate: M7`, listed under M7 → exit 0, only `Supersession: AVE-REQ-001 → AVE-REQ-105 ...`.
fix: Print `Gate change: AVE-REQ-001 → AVE-REQ-105 primary_gate M7 (baseline M1)` in check_supersession; suite case.
```

4.

```text
location: scripts\check_baseline.py:575-607
defect: A faithful chain fails: `human_successors` holds only the end of the chain, so the retired middle file must be relabelled `source: derived`, against README § Enforced checks item 9 ('human when it replaces a human baseline requirement'). Fails closed.
evidence: AVE-REQ-001 → AVE-REQ-105 (superseded, source human) → AVE-REQ-106, both carrying Description and criteria → exit 1, `AVE-REQ-105-successor.md: a requirement added after the import has source derived, or human when it replaces a human baseline requirement (expected 'derived')`, beside `Supersession: AVE-REQ-001 → AVE-REQ-106 carries ...`.
fix: Add every ID visited by chain_end to human_successors; suite case 'faithful chain through a superseded successor is reported'.
```

5.

```text
location: scripts\tests\test-check-baseline.sh:623-624; scripts\check_baseline.py:689-694
defect: No suite case needs the chain-end dependency rule (README check 8, 'through a superseded one'): the case 'v1 requirement depends on a superseded exclusion fails' is satisfied by the direct future-scope branch. The lead's statement that every mutant of the new rules fails a named case does not hold for this rule. The behaviour itself exists.
evidence: Mutant `elif end is None or end.get("status") == "deferred" or end.get("scope") == "future":` → `elif False:` → `BASELINE TOTAL: pass=213 fail=0`. Unmutated checker on my construction (derived v1 AVE-REQ-105 depends on derived v1 AVE-REQ-106, superseded by the deferred future AVE-REQ-107) → exit 1 `version-one requirement depends on AVE-REQ-106, whose replacement is the deferred AVE-REQ-107`.
fix: Add that construction as a case expecting `whose replacement is the deferred`, and one for a missing replacement.
```

6.

```text
location: scripts\check_baseline.py:91, 582-598
defect: The one-file rule compares ID strings, so two derived files with one number and different zero padding pass (README § IDs rule 1: numbers are allocated once).
evidence: `AVE-REQ-0103-twin.md` (copy of AVE-REQ-103 with the ID replaced), linked from its feature and the roadmap → both checkers exit 0, `Working requirements: 105`.
fix: Key the rule by kind and number, or fix the width per kind; suite case.
```

7.

```text
location: scripts\check_baseline.py:802-807 and check_epics_features
defect: Two status moves pass without any note: a baseline must requirement set back to `proposed` and parked on a `Proposed during` line (the lifecycle has no arrow from ready to proposed), and a feature set to `done` with its Feature acceptance box ticked while no child is done (README § Status lifecycle rule 6).
evidence: AVE-REQ-001 `status: proposed` with a log line, moved to the M1 Proposed-during line → both checkers exit 0, no note. AVE-FEAT-002 `status: done`, box ticked, done log line → both checkers exit 0.
fix: Propose follow-up requirements or checker rules: an imported requirement never returns to `proposed` (or the move is reported); an epic or feature is `done` only when every live child is done, and its acceptance boxes are ticked only then.
```

8.

```text
location: scripts\reqfile.py:104-106
defect: The mark is 32 bits. A deliberate search of about 2^32 SHA-256 values finds a second text with the mark of an existing line, which would let a later edit pass under the old line. Not attempted; the note printed on every run still shows the change.
evidence: Reasoning from `hexdigest()[:8]`.
fix: Use 16 hex digits, or accept and state the limit in § Edge cases.
```

9.

```text
location: docs\requirements\AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md:5 and :141; docs\decisions\ADR-003-requirements-baseline-import.md:24-26; scripts\requirements\import_baseline.py:558 (IMPORT_MAPPING.md:22)
defect: Documentation: frontmatter `status` is `in-progress` and no `verification` log line precedes this review (verify-requirement step 9 expects `verification`); ADR-003 decision 5 names the old marker `AC-n changed:` without the mark; IMPORT_MAPPING.md rule 5 says `dependencies` equal the baseline values while the README admits derived additions.
evidence: Read at 2df637f; TRACEABILITY.md row 207 matches the frontmatter status; ADR-003 is Accepted; ASM-004 exists; every file named in § Implementation evidence exists.
fix: Log the `verification` transition before the next review request; correct ADR-003 decision 5 to `AC-n changed [<mark>]:`; reword rule 5 in import_baseline.py and regenerate IMPORT_MAPPING.md.
```

### Test quality

```text
Checklist of skill section 8, per criterion.

AC-1 (scripts/tests/test-check-baseline.sh, comment tags): each case starts from a fresh import and the unedited package, applies one mutation and asserts the exit code and one specific output line, so nothing is taken from the repository's own working files. Real unit under test, no mocks. Executed in the release run (213 checks) and credited through the suite result. Mutants of the manifest pin, the restart, the source loading and the second-file rule fail named cases. My own constructions (other files, same-size edit, file to directory, removed validator, re-hashed entry) agree. Gap: no case plants `__future__` or `sitecustomize` (blocking finding 3).

AC-2: no test by design; the inspection is justified in § Verification strategy and I performed it from Git history.

AC-3 (same suite plus inspection): assertions are specific (exact error text with the expected mark computed independently by `sha256sum`). 34 of 35 mutants of the reader and the checker fail on cases whose names match the removed rule, so the suite is not vacuous. Gaps: no case for a heading on an indented list continuation, a setext heading in a quote or list item, an invisible non-space character, a milestone Status other than the exact word `done`, or the chain-end dependency rule (the one surviving mutant). The inspection part (criteria bind as written, reasons are free text, gate changes show in the diff) is sound as a limit statement; at this commit the checker prints no recorded change, so there is no reason to judge.

AC-4 (same suite, scripts/tests/test_evidence.py): the three tagged unit tests call the real `read_requirement` and `done_problems` on files they write, assert the exact problem list (`AVE-REQ-050 AC-1: missing in this run`) and nine spellings that must be outside the canonical form; the only patch is the requirements directory. No skips (32 tests OK). Mutants of the tick rule and the criteria-only rule fail named cases. Gap: no test states what the fast and media tiers accept, which is where the strategy sentence went wrong (blocking finding 4).

Tags: all present as comment lines (suite) and comment lines above tests (unit file); `evidence.py show` credits them. Determinism: two full suite runs and 35 mutant runs gave consistent totals; three ran in parallel without a spurious failure.

AT-29 and AT-30 (final review): nothing at this commit contradicts them. Package checks certify no completion (0 done requirements, the done gate is a separate step), and the bootstrap documents were extended, not replaced.
```

### Evidence for the requirement file

```text
None — verdict FAIL.
```
