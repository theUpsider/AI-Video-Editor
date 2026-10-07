---
id: AVE-REQ-093
title: Adopt and preserve the supplied requirements baseline
type: constraint
status: in-progress
priority: must
parent: AVE-FEAT-019
source: human
scope: v1
primary_gate: M0
origins: [U27, D05]
dependencies: []
scenarios: [AT-29, AT-30]
baseline: ../../ai-video-editor-requirements/spec/requirements/AVE-REQ-093.md
---

# AVE-REQ-093 — Adopt and preserve the supplied requirements baseline

## Intent
Serves [GOAL-009](../PRODUCT.md#product-goals) through [AVE-FEAT-019 — Autonomous implementation workflow](AVE-FEAT-019-autonomous-implementation-workflow.md). Origin clauses in the user brief:
- [U27](../../ai-video-editor-requirements/intake/USER_BRIEF.md#u27) — Use the already-created Claude Code project bootstrap and implement through dynamic, self-improving, optimally adapted workflows.
- [D05](../../ai-video-editor-requirements/intake/USER_BRIEF.md#d05) — Derived delivery requirement: durable progress, immutable requirements baseline, independent review, and bounded workflow improvement.

Imported from the immutable baseline [AVE-REQ-093](../../ai-video-editor-requirements/spec/requirements/AVE-REQ-093.md) (package v1.0); primary gate M0, scope v1.

## Description
The implementing agent shall integrate this specification into the existing bootstrapped repository without re-running or replacing the bootstrap.

## Acceptance criteria
- [ ] AC-1 Preserve this input package as an immutable baseline and map every AVE-REQ ID to its canonical working requirement file.
- [ ] AC-2 Populate the existing PRODUCT, ARCHITECTURE, ROADMAP, PROGRESS, ASSUMPTIONS, and TRACEABILITY documents without losing meaningful existing content.
- [ ] AC-3 Explicit user requirements and exclusions cannot be demoted or rewritten merely to fit an easier implementation.
- [ ] AC-4 Requirement implementation status starts unverified; package validation is not product verification.

## Edge cases
- A baseline file edited, added or removed, the package's own validator included → the baseline check fails
  with "baseline changed": the checker verifies the manifest's inventory and every file's size and SHA-256 itself
  before it runs the package validator, and it runs the validator only when the validator's own bytes verified
  (AC-1, AC-3).
- MANIFEST.json edited, removed or duplicated inside the package, or a baseline edit with a re-hashed
  MANIFEST.json → the baseline check fails with "baseline changed": the checker pins the manifest's SHA-256
  outside the package (AC-1, AC-3).
- The working file of a baseline requirement, feature or epic missing, a second file for a baseline requirement
  or feature, a changed identity (the title, type, priority, scope, source, parent, origins, scenarios,
  baseline path, frontmatter id, H1 or Description of a requirement; the title, priority or parent of a
  feature; the title, priority or goal of an epic), a baseline dependency dropped or another baseline
  requirement added as a dependency → the baseline check fails; a Description change passes only with a
  logged reason, and a derived requirement may join the dependencies (AC-1, AC-3).
- One number of a kind under two IDs (`AVE-REQ-0102` beside `AVE-REQ-102`, `AVE-REQ-0001` beside
  `AVE-REQ-001`) → fails: the one-file rule counts by kind and number (AC-1).
- A criterion or the Description reworded or removed, or text added to the Description (a fenced block
  included), without its marker line in the Status log (`AC-n changed [<mark>]: <reason>`,
  `AC-n removed: <reason>`, `Description changed [<mark>]: <reason>`) → fails; with the line → reported. The
  marker opens the log line's text and the mark is the first sixteen hex digits of the SHA-256 of the new
  text, so a line that quotes the rule, names another requirement, stands outside § Status or covers an
  earlier edit records nothing; a reason without a letter or a digit of U+0020 to U+007E, and the
  template's placeholder as the reason, record nothing either (AC-3).
- A working file outside the canonical form (README § Canonical form) → fails: `scripts/reqfile.py` reads
  every working file for the baseline gate and the done gate, so a file they accept has one reading
  (AC-3, AC-4). The forms the suite pins: a repeated, quoted or unknown frontmatter key or one outside the
  template's order, a second block or a stray character at the frontmatter's end; a character outside the
  allow-list of `scripts/reqfile.py`, which holds U+0020 to U+007E, the line feed and seven listed signs (a
  carriage return, a tab, a byte-order mark, a line separator, a no-break space, a form feed, a delete
  character, a unit separator, four invisible characters of other Unicode classes and a letter outside the
  list fail); a heading outside the template, a template heading repeated, out of order or missing, text
  before the first heading; an HTML comment, a line that starts with `<`, a tag outside code spans (`<`
  before a letter, `/`, `!` or `?`), a run of backticks unpaired on its line; footnote syntax; a fence line
  outside the one form; a Status log with a free-text line, a line with hyphens for the dashes, dates out of
  order, an impossible date or an unknown status; a copy of a requirement file in a subdirectory.
- A heading in a form a Markdown reader renders → fails: a line is judged after its leading spaces and again
  after each container marker (`>`, `-`, `*`, `+`, `N.`, `N)`), so an ATX heading at any indentation, on a
  continuation line of a list item, inside a list item or a quote, a run of `=` or of `-` alone in any of
  these places, and an HTML heading tag (levels 1 to 6, either letter case, opening or closing, in a code
  span too) on a line outside fenced blocks all fail (AC-3, AC-4).
- Footnote syntax (`[^`, and the inline form `^[` of other Markdown readers) outside code spans and fenced
  blocks → fails, in a requirement and in a feature file: a footnote definition is a container whose first
  line opens a heading, a quote or a list item for GitHub, and the canonical form holds none (AC-3, AC-4).
- A fenced block outside the one form → fails: three backticks at column 0, alone or with one word of
  letters, digits, `_` or `-`, open a block and three backticks at column 0 close it. Every other line that
  opens with three or more backticks or tildes behind leading spaces or a container marker fails (a fence
  behind one or four spaces, in a quote, in a list item, a tilde fence, also behind an ordered marker, four
  backticks, a plus sign, a dot or a backtick in the info word, a space before it, a code span of three
  backticks at a line start), inside a block too (a second fence line, a tilde line, a fence line in a
  quote, spaces behind the closing backticks, a closing line of four backticks), as does a block left open.
  A refused line opens no block, so the lines behind it are judged as lines of the file. The reader and a
  Markdown reader so agree on every line that opens or closes a fenced block (AC-3, AC-4).
- A tag inside a line (`<details>`, `<s>`, a closing tag, a declaration, a processing instruction, a
  placeholder in angle brackets) → fails outside code spans and fenced blocks, behind a backslash and
  between escaped backticks too; a code span opens and closes on one line, so the spans the reader pairs
  are the spans a Markdown reader pairs (AC-3).
- What a Markdown reader shows beside what the gates read → the rules above leave one reading of the
  headings, the Description, the criteria and the Status log; inspection covers that claim: a comparison of
  the gate with cmark-gfm (GitHub's Markdown, footnotes on) and markdown-it-py, recorded in part 1 of the
  handback of the fix brief `2026-10-07-m0-review-2-fixes`, found each compared construct either refused by
  the gate or shown as read (AC-3, AC-4, inspection). Limits: GitHub shows the frontmatter as a table of its
  own; what GitHub renders beyond CommonMark and its Markdown specification (math delimiters, diagrams in
  fenced blocks) was compared with no renderer; a construct outside the comparison is judged by the rule's
  text in `scripts/reqfile.py`, which `verify-requirement` reviews.
- Text inside § Acceptance criteria that is no criterion line (a continuation line under a criterion, a fenced
  block, a capital-X tick) → fails: the section holds criterion lines only, so nothing can qualify or waive a
  criterion in place (AC-3).
- A symbolic link added inside the package (a file or a directory) → fails with "baseline changed" (AC-1).
- A future requirement made ready, or a version-one requirement deferred → fails (AC-3).
- A version-one requirement superseded by a requirement that does not exist, is `proposed`, future scope or
  deferred, has a lower priority, another type, source `derived` for a human requirement, fewer origins or
  scenarios, another Description, a criterion of its own or a missing baseline criterion without the marker
  line in the old file's Status log
  (`AC-n dropped by <ID>`, `<ID> AC-m added [<mark>]`, `Description replaced by <ID> [<mark>]`),
  or superseded without a `superseded` log line → fails; a replacement that carries the baseline Description
  and every baseline criterion is reported as a supersession. Through a chain of replacements the rules hold
  for the end of the chain: every requirement on the chain of a human requirement keeps source `human`, and
  a replacement under another milestone than the baseline gate is reported as a gate change. `proposed` is
  the status the rule of the imported file closes to its replacement; a replacement that is `blocked` is
  reported like the others (AC-3).
- A future-scope requirement (an exclusion) superseded by a requirement that is version-one scope or not
  `deferred` → fails: an exclusion enters version one only through a new baseline from the human (AC-3).
- A baseline feature or epic set to `superseded` while a baseline child under it is not superseded → fails (AC-3).
- A criterion added to a baseline requirement without an `AC-n added [<mark>]: <reason>` log line → fails;
  with the line → reported (AC-3).
- A requirement that is not superseded and stands on no ROADMAP.md list or on two, a version-one requirement
  under another milestone than its primary gate or in the Deferred group, an exclusion on a milestone list, a
  primary gate that names no milestone, a requirement past `proposed` on a Proposed line, a listed ID
  without a working file, or a milestone with Status done that lists an unfinished requirement → fails (AC-3).
- `docs/ROADMAP.md` outside the form the gate reads (ROADMAP.md § Rules 8) → fails (AC-3). The file: a
  character outside the allow-list of the requirement files and the horizontal ellipsis, written out or as a
  character reference (a Cyrillic letter in a label, a tab, a carriage return, a no-break space as a
  reference); an HTML comment; raw HTML outside code spans (a processing instruction around a Status line
  or a link, `details` around an entry, a closing tag); a run of backticks unpaired on its line; footnote
  syntax; a fence line outside the one form of the requirement files (a tilde fence, four backticks, an
  indented fence, a fence in a quote, a dot in the info word, a fence line inside a block, a block left
  open); a line of `=` or of `-` alone, in a quote too; a link outside the one form `[<words>](<path>)` (a
  link without words, an image, a reference link of two bracket pairs, a target with parentheses or a title).
- A heading of `docs/ROADMAP.md` that the gate would read otherwise than a Markdown reader → fails (AC-3): a
  heading behind a space, in a quote or on a continuation line; a heading that reads as an entry heading
  (its letters and digits, link targets and digits at the start aside, open with `M` and a digit or with
  `Deferred`) outside the template form `### M<n> — <name>` or `### Deferred — <text>` (a hyphen for the
  dash, a leading zero, level 2 or 4, bold, the letter as a character reference, a number or a link before
  it, no name, `Deferred` with a colon); a second entry for a milestone or for the Deferred group. An entry
  runs to the next heading of level 1 to 3: a sub-heading and hashes without a space end none, and a Status
  line under a phase heading is free text.
- A milestone entry of `docs/ROADMAP.md` without exactly one Status line that reads `- **Status:** planned`,
  `- **Status:** in-progress` or `- **Status:** done` (another letter case, a full stop or a note after the
  word, bold around it, another word, an indented line, no line, a second line) → fails. Every line of the
  entry whose letters open with `status`, read with character references resolved and without link targets
  and ticked task boxes, counts as a Status line, so a second line in another form fails beside the true one
  (underscore bold, star emphasis, no emphasis, upper case, a quote, a star bullet, an ordered marker, no
  bullet, a nested item, a table row, a code span or a link as its label, a link or a ticked task box before
  it, a character reference, escaped stars, text behind a hard line break), as does a continuation of the
  Status line (an indented line, a text line); the Status line of the Deferred group is free text (AC-3).
- A requirement list of `docs/ROADMAP.md` outside the template → fails (AC-3): a line of an entry whose
  letters open with `requirement` or `proposed` under another label than the template's three (another
  wording, bullet, indentation or letter case, underscore bold, no emphasis, the singular, a quote, a
  character reference, the label of the other group), a second list of one kind; a requirement list that
  holds anything besides its links (a struck link, a link in a code span, behind a backslash or with a
  title, text or spaces behind the list, no link), in the Deferred group too; a Proposed line that holds
  anything besides links and plain words (a struck word, a code span, emphasis); a continuation of a list
  line (a nested item, a paragraph behind a blank line, an indented line under a Proposed line); a link
  text that names another file than its target. A list inside a fenced block is no list for the gate.
- What a Markdown reader shows of `docs/ROADMAP.md` beside what the gate reads → the four rules above make
  the entries, the Status of a milestone and the links of its lists the ones a reader sees, so the rule for
  a finished milestone holds for the Status a reader sees; inspection covers that claim: the comparison
  named above found each compared construct either refused by the gate or shown as read (AC-3, inspection).
  Limits, free text that the diff review judges: the word Status or a milestone number behind other words
  of a line or a heading, another word for a label, bold text that imitates a heading, a code sample, an
  entry under another milestone number, and what GitHub renders beyond CommonMark and its Markdown
  specification (an emoji shortcode before a label, for example).
- A baseline requirement set back to `proposed` → fails. An epic or feature set to `done`, or a box of its
  acceptance section ticked, while a child that is neither superseded nor deferred is not `done` → fails
  (AC-3, AC-4).
- A version-one requirement that depends on an exclusion, directly or through a superseded requirement, on a
  superseded requirement whose replacement is deferred or missing, a dependency on itself or in a cycle,
  § Dependencies that differs from the frontmatter, a derived requirement missing from its parent's list, or
  a version-one requirement under a deferred feature → fails (AC-3).
- A feature that links a requirement only outside § Requirements (under Out of scope, for example) → fails
  (AC-1, AC-3).
- Text in Intent, Edge cases, Verification strategy or the evidence sections that narrows or waives a criterion,
  whatever its typography (bold text that imitates a heading included) → outside the mechanical guard (free
  text): README § Changing requirements rule 6 makes criteria binding as written, and `verify-requirement`
  judges against them exactly as written (AC-3, inspection). The reason of a marker line and the text of a
  log line are free text too: the checker reports each recorded change, and commit review judges the reason.
- A change to the gate itself (`scripts/check_baseline.py` and its pinned hash, `scripts/reqfile.py`,
  `scripts/requirements/import_baseline.py` and its value mappings, the verify step that runs them) → outside
  the mechanical guard: the diff shows it, and `verify-requirement` and the commit review judge it; a new
  baseline version comes only from the human (AC-1, AC-3, inspection).
- A bytecode cache of a gate tool, a module beside the checker, or a Python variable of the environment
  (`PYTHONPATH`, `PYTHONPYCACHEPREFIX`) → changes no result of the isolated start
  `python3 -I -B scripts/check_baseline.py`, the command of verify.sh and CI: the checker runs in Python's
  isolated mode and loads its tools from their source text (AC-1, AC-3). Started as
  `python3 scripts/check_baseline.py` or with `-B` alone, the checker's first statements restart it in
  isolated mode before it imports anything else; the suite pins that start for a module beside the checker
  (`hashlib`, `__future__`), the same modules on `PYTHONPATH` and a cache of the import tool under
  `PYTHONPYCACHEPREFIX`. Code the interpreter loads at its own start (a `sitecustomize` module on
  `PYTHONPATH`) runs before the first line of the script, so for every start other than the isolated one
  the Python variables of the environment are local state the caller answers for. The interpreter, the
  shell and the tools on `PATH` of the development container and of CI are trusted; CI on a fresh checkout
  is the run that admits a commit to `main`.
- A criterion ticked on a requirement that is not `done` → fails (AC-4): reopening unticks every criterion, and
  a requirement superseded after it was done keeps its ticks. The `done` line of the Status log is log text:
  the diff shows it and commit review judges it.
- Package validation passing while no requirement is verified → statuses stay unverified (AC-4).
- Existing bootstrap content kept when documents are populated (AC-2, inspection).
- A derived requirement (`AVE-REQ-102` onward) set to `superseded` → held by `scripts/check-project-control.sh` (a `superseded_by` that names an existing file) and by the dependency rule; the replacement rules of this gate apply to the requirements of the baseline, which are the ones it protects (AC-3).

## Dependencies
None.

## Verification strategy
- AC-1 — integration — `scripts/tests/test-check-baseline.sh` (tagged comment lines): immutability of the package (the checker verifies the manifest's inventory and every file's size and SHA-256 itself and pins the manifest hash outside the package, so an edited, removed, duplicated or re-hashed MANIFEST.json, a manifest with another size entry, an edited package validator, a file edited or added behind an edited validator, a removed file and a symbolic link added inside the package fail with "baseline changed"; an edited validator is never run; started as `python3 scripts/check_baseline.py`, a planted bytecode cache of the import tool, a `hashlib` or a `__future__` beside the checker or on `PYTHONPATH` and a cache under `PYTHONPYCACHEPREFIX` change no result, and the isolated start `python3 -I -B` passes on a clean import; a `sitecustomize` module on `PYTHONPATH` lies outside every start but the isolated one, as § Edge cases states), exactly one working file per baseline ID and one ID per number of a kind, each child linked from its parent's own list section, a current IMPORT_MAPPING.md; inspection: `scripts/verify.d/10-requirements.sh` declares the fast step "Requirements baseline integrity", which runs `python3 -I -B scripts/check_baseline.py` on the real repository.
- AC-2 — inspection — the six documents are populated from the baseline and keep their bootstrap content (Git history of each file since `f605c6c`); automation cannot judge "meaningful content".
- AC-3 — integration and inspection — `scripts/tests/test-check-baseline.sh`: each form that § Edge cases maps to AC-3 as failing, passing or reported is a case of the suite. Its groups: the identity and frontmatter of requirements, features and epics; criteria, the Description and their marker lines; the canonical form (characters, frontmatter, headings behind leading spaces and container markers, raw HTML and code spans, footnote syntax, the one fence form, the criteria section, the Status log); supersession, its chains and the status of the replacement; the statuses of requirements, features and epics; dependencies; the roadmap (placement of requirements, the file's characters, raw HTML, backtick runs, footnote syntax, fences and links, headings and entry headings, Status lines, requirement lists, items of one line). Inspection for what no checker can read: criteria bind as written (README § Changing requirements rule 6, reviewer rule 4), the reason of a recorded change is free text, a change to the checker, the reader, the pin or the import mappings shows in the diff that `verify-requirement` reviews, and what a Markdown reader shows beside what the gate reads rests on the comparison with two renderers that § Edge cases names, with the limits stated there.
- AC-4 — integration and inspection — `scripts/tests/test-check-baseline.sh` (import starts unverified: statuses `ready`/`deferred`, 0 of 404 criteria ticked; a ticked criterion on a requirement that is not `done` fails, after a reopening and on a superseded requirement that never was done included; a capital-X tick, a quoted or repeated status key and a second criteria heading fail as outside the canonical form; an epic or feature that is `done`, or carries a ticked acceptance box, before its children are done fails); `scripts/tests/test_evidence.py` (the done gate reads requirement files through the same reader: a `done` requirement without evidence fails it, and so do the nine spellings of its unit test that hide `done` or a criterion; `done_problems` refuses a criterion of a `done` requirement whose evidence in the run is failed, contract-only or missing; the fast and media tiers accept a criterion whose tagged tests exist and did not run, and the release tier refuses it); so in the release tier every criterion of a `done` requirement has a passing non-contract test or a recorded inspection that its Verification strategy line names (`scripts/verify.d/95-evidence.sh`, README § Definition of Done item 4); the inspection itself is judged by `verify-requirement`.
- Acceptance scenarios [AT-29](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-29), [AT-30](../../ai-video-editor-requirements/spec/ACCEPTANCE_TESTS.md#at-30) — whole-product scenarios (application walkthrough, handover, final review); they run at the final milestone review (M7, AVE-REQ-100) and count as evidence once they pass on the current tree. This requirement's criteria are evidenced now by the levels above.

## Implementation evidence
- `ai-video-editor-requirements/` — the baseline package, committed unchanged at `6160278`; its MANIFEST.json lists every file's size and SHA-256, and its `tools/validate_package.py` checks package consistency (AC-1)
- `scripts/check_baseline.py` — the manifest hash pinned outside the package (`BASELINE_MANIFEST_SHA256`), the inventory and every file's size and SHA-256 verified by the checker itself before the package validator runs, package validation, and working-file integrity (canonical form, identity, one ID per number of a kind, Description, criteria, marker lines bound to the text they cover, ticks, supersession, its chains and the status of the replacement, dependencies, statuses of requirements, features and epics, mapping); the roadmap reader `read_roadmap` (characters by allow-list with character references resolved, the reader's fence and inline rules, one link form, headings at column 0, entry headings of the template form, Status lines and list labels found by the letters a line opens with (`roadmap_key`), lists of links only, items of one line); the restart into isolated mode as the first statements, and tools loaded from source (AC-1, AC-3, AC-4)
- `scripts/reqfile.py` — the one reader of working requirement files, shared by `scripts/check_baseline.py` and `scripts/evidence.py`; it reports the forms outside the canonical form: characters by allow-list (`EXTRA_CHARACTERS`), headings and underlines judged after leading spaces and container markers (`readings`), raw HTML, backtick runs and footnote syntax outside code spans (`inline_problems`), fence lines by the one form (`fence_like`, `FENCE_OPEN`), marks of sixteen hex digits (`digest`), marker reasons with a letter or a digit (`recorded`) (AC-3, AC-4)
- `scripts/requirements/import_baseline.py`, `docs/requirements/IMPORT_MAPPING.md`, the 131 imported `docs/requirements/AVE-*.md` files (derived requirements continue at AVE-REQ-102) — the import that keeps every existing working file, and the ID mapping (AC-1, AC-4)
- `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PROGRESS.md`, `docs/ASSUMPTIONS.md`, `docs/TRACEABILITY.md` — populated from the baseline, bootstrap content kept (AC-2)
- `scripts/evidence.py` (`check-done`), `scripts/verify.d/95-evidence.sh` — completion is judged by the done gate, a verify step apart from the package checks (AC-4)
- Tests: `scripts/tests/test-check-baseline.sh` — AVE-REQ-093 AC-1, AVE-REQ-093 AC-3, AVE-REQ-093 AC-4; `scripts/tests/test_evidence.py` — AVE-REQ-093 AC-4 (a done requirement needs evidence of the run, and nine spellings that hide `done` or a criterion fail the done gate)
- Decisions: [ADR-003](../decisions/ADR-003-requirements-baseline-import.md), [ASM-004](../ASSUMPTIONS.md)

## Test evidence
_TBD: filled by the lead from the verify-requirement report._

## Status
- 2026-10-01 — ready — imported from baseline v1.0 (lead)
- 2026-10-01 — ready — baseline ready means specified for planning; Edge cases and the dependency order are settled before work starts (lead)
- 2026-10-02 — ready — Edge cases settled; dependency order per ROADMAP.md (lead)
- 2026-10-02 — in-progress — M0 delivery-process gates implemented; criterion evidence under review (lead)
- 2026-10-02 — in-progress — verification levels recorded per criterion; AT-29/AT-30 run at the final review (lead)
- 2026-10-02 — verification — implementation evidence complete; independent verification requested (lead)
- 2026-10-02 — in-progress — verify-requirement FAIL at `4d9ef9a` (workflow `wf_b0c34bba-a20`); blocking findings and fixes in [the fix brief](../briefs/2026-10-02-m0-process-verification-fixes.md) (lead)
- 2026-10-03 — in-progress — verify-requirement FAIL at `d4d3883` (workflow `wf_ed1f5104-63a`): the file hashes were verified only by `tools/validate_package.py`, a package file, so editing it disabled the check; `scripts/check_baseline.py` now verifies the inventory and every hash itself before running the validator, with suite cases for an edited validator (lead)
- 2026-10-03 — verification — fix in place, `scripts/tests/test-check-baseline.sh` 79 of 79; independent verification requested again (lead)
- 2026-10-03 — in-progress — verify-requirement PASS at `97a8d20` (workflow `wf_e3b34e48-f7e`) refuted by its skeptic: text inside § Acceptance criteria that is no criterion line (a continuation line, a fenced block, a sub-heading) could qualify a criterion unnoticed by both checkers; the checker now rejects any such line in every working requirement, reports symbolic links in the package (the reviewer's gap) and never runs an edited validator, with suite cases for each; stale wording in ADR-003, IMPORT_MAPPING.md and `scripts/verify.d/10-requirements.sh` corrected (lead)
- 2026-10-03 — verification — `scripts/tests/test-check-baseline.sh` 86 of 86; independent verification requested a fourth time (lead)
- 2026-10-03 — in-progress — verify-requirement PASS at `08237ac` (workflow `wf_eabbb2f5-6a0`) refuted by its skeptic: a version-one human requirement set to `superseded` with `superseded_by` naming a weaker derived requirement that carries none of its criteria passed every checker and the fast tier; the checker now requires a replacement that exists, keeps version-one scope and priority and carries every baseline criterion or logs each drop, plus a `superseded` log line; from the reviewer's findings an added criterion needs `AC-n added: <reason>` and a tick needs a `done` status or log line (lead)
- 2026-10-03 — verification — `scripts/tests/test-check-baseline.sh` 96 of 96; independent verification requested a fifth time (lead)
- 2026-10-03 — in-progress — verify-requirement PASS at `442f68c` (workflow `wf_b5fa6671-c21`, review 5); a session restart cut its skeptic off without a verdict; the lead inspected the skeptic's clone and reproduced its unfinished probe: the future-scope AVE-REQ-101 superseded by a derived version-one requirement passed the checker; the checker now requires a future-scope, deferred replacement for a future-scope requirement and rejects a superseded baseline feature or epic whose baseline children live on; Edge cases state the limits of the mechanical guard (free text, the gate's own code) and the inspection that covers them (lead)
- 2026-10-06 — in-progress — red-team pass (workflow `wf_98f469f7-ec5` at `35f99c5`, lenses 093-A, 093-B and 093-C; [handback part 1](../briefs/handbacks/2026-10-03-m0-gates-red-team.part-1.md)): twenty findings, among them three readings of one file (a quoted or repeated status key, a capital-X tick, a no-break space at the frontmatter's end, a carriage return, an HTML comment around the criteria), marker lines that covered later edits, a roadmap no gate read, a supersession that kept the criteria only, a dependency on a superseded exclusion, and a bytecode cache that replaced the import tool; `scripts/reqfile.py` now reads every working file for both gates and `scripts/check_baseline.py` enforces the canonical form, binds each marker line to its text, checks the roadmap lists, the successor's identity, dependencies through supersession and parent lists, runs isolated and loads its tools from source; ticks stand only while the status is `done` (README § Status lifecycle rule 5 changed: reopening unticks every criterion); Edge cases, Verification strategy and Implementation evidence follow (lead)
- 2026-10-06 — in-progress — verify-requirement FAIL at `2df637f` (workflow `wf_7d9d015c-906`; [handback part 5](../briefs/handbacks/2026-10-03-m0-gates-red-team.part-5.md)): AC-3 — headings in list-item and quote form that a Markdown reader renders passed the canonical form, as did invisible characters outside five Unicode classes, and a milestone Status spelled `done.` or `Done` escaped the rule for finished milestones; two statements were false (a module named `__future__` beside the checker ran before its restart, and the done step refuses a test that did not run in the release tier only). Fixes through [the fix brief](../briefs/2026-10-06-m0-final-review-fixes.md) (lead)
- 2026-10-06 — in-progress — fixes of the final review merged on branch `m0-final-integration` ([fix brief](../briefs/2026-10-06-m0-final-review-fixes.md), [handback part 1](../briefs/handbacks/2026-10-06-m0-final-review-fixes.part-1.md)): characters by allow-list, headings judged behind leading spaces and container markers, raw HTML outside code spans refused, one exact Status line per milestone entry, roadmap lists by template label, the restart as the checker's first statements with the guarantee scoped to the isolated start, marks of sixteen digits, status rules for imported requirements, features and epics. ADR-003 decision 5 names the change marker by its opening words and stays as accepted (an accepted ADR admits typo and link fixes); `docs/requirements/README.md` holds the full form of each marker (lead)
- 2026-10-06 — verification — fixes of the final review integrated on branch `m0-final-integration`; independent verification with a skeptic requested from [the review brief](../briefs/2026-10-06-m0-final-review-2.md) (lead)
- 2026-10-07 — in-progress — verify-requirement FAIL at `f996c17` (workflow `wf_b18a5f3e-54e`, briefed in [the review brief](../briefs/2026-10-06-m0-final-review-2b.md); [handback part 1](../briefs/handbacks/2026-10-06-m0-final-review-2b.part-1.md)): AC-3 — a heading on the first line of a footnote definition passes the canonical form while GitHub renders it, and in `docs/ROADMAP.md` raw HTML other than a comment and a Status line in another emphasis form pass, so two consequences that § Edge cases states do not hold; AC-1, AC-2 and AC-4 PASS, and the blocking findings of the first round are closed. The fixes go through [the fix brief](../briefs/2026-10-07-m0-review-2-fixes.md), track A (lead)
