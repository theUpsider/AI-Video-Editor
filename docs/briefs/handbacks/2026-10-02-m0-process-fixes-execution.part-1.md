# Handback — M0 process fixes, part 1 (baseline checker): items 1, 2, 10

Brief: `docs/briefs/2026-10-02-m0-process-fixes-execution.md` (part 1) with the findings of
`docs/briefs/2026-10-02-m0-process-verification-fixes.md`. Branch `m0-process-fixes` (worktree
`.claude/worktrees/m0-process-fixes`, created from `6736401`). Commit: the commit that adds this file,
subject "AVE-REQ-093: pin the baseline outside the package and guard requirement descriptions"
(`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-1.md`).

Resumed from the uncommitted edits of an interrupted agent: every hunk was judged against the briefs and
kept; none was a leftover mutation (the pinned value equals `sha256sum ai-video-editor-requirements/MANIFEST.json`,
the suite passed 74/74 before any change). Added in this run: the Description comparison reads the whole
section with fenced blocks, one more suite case, and the Description placed in the README identity lists.

## Items

### Item 1 — AVE-REQ-093 AC-1, AC-3: trust anchor outside the package (done)
- Change: `scripts/check_baseline.py` — `BASELINE_MANIFEST_SHA256 = "140307b8…6e05"` (the SHA-256 of
  `ai-video-editor-requirements/MANIFEST.json`, package v1.0) and `check_manifest_pin()`, run before the
  package validator: a different hash, a missing or unreadable manifest, or a second `MANIFEST.json` inside
  the package (the validator's inventory skips every file of that name) fails with "baseline changed".
  `docs/requirements/README.md` § Baseline import and integrity (intro, rule 1: a new baseline version
  updates the pin in its adopting commit) and § Enforced checks item 1. `scripts/verify.d/10-requirements.sh`
  header comment. AVE-REQ-093 § Edge cases and § Verification strategy (AC-1, AC-3).
- Tests (`scripts/tests/test-check-baseline.sh`, tagged `AVE-REQ-093 AC-1, AVE-REQ-093 AC-3`):
  "edited MANIFEST.json fails" (the reviewer's probe: version 1.1 plus an added excludes entry),
  "baseline edit with a re-hashed manifest fails" (the reviewer's probe: AVE-REQ-001 AC-2 weakened in the
  baseline .md, requirements.json and the working file, manifest re-hashed by the `rehash` helper),
  "re-hashed manifest: the pin is the only failure" (proves the probe passes every other check),
  "removed MANIFEST.json fails", "second MANIFEST.json in the package fails".
- Mutation M1 (call `check_manifest_pin(importer.PKG)` replaced by `pass`): 5 FAIL, 70 pass — the edited and
  re-hashed cases exit 0 as in the finding. Mutation M2 (second-manifest test `if False:`): 1 FAIL
  ("second MANIFEST.json in the package fails", exit 0). Both restored from the saved copy; SHA-256 of the
  restored file equals the pre-mutation copy (`8e073a7e…`).

### Item 2 — AVE-REQ-093 AC-3: Description guarded (done)
- Change: `scripts/check_baseline.py` — `Working.description()` returns the whole `## Description`
  section (fenced blocks included, via `raw_sections`); `check_requirements()` compares it with the
  baseline statement; a difference needs a Status-log line `Description changed: <reason>` (printed as
  "Recorded change: <ID> Description …"), otherwise an error ("Description differs from the baseline
  statement …" or "Description is missing …"). `recorded_change()` takes the subject (AC-n or Description).
  `docs/requirements/README.md` § Changing requirements rule 1, § Baseline import and integrity rule 4
  (Description in the identity list; only it may change with a logged reason), § Enforced checks item 3.
  AVE-REQ-093 § Edge cases (Description in the identity list; reworded, removed or extended Description)
  and § Verification strategy AC-3.
- Tests (`scripts/tests/test-check-baseline.sh`, tagged `AVE-REQ-093 AC-3`): "rewritten description without
  log line", "extended description without log line", "fenced block added to the description fails",
  "emptied description without log line", "rewritten description with recorded change" (exit 0, reported),
  "description change needs a reason", "AC log line does not cover the description", "description log line
  outside ## Status".
- Mutation M3 (comparison `if False:`): 8 FAIL, 67 pass (every Description case). Mutation M4
  (`description()` reads the fence-free `sections`): 1 FAIL ("fenced block added to the description fails",
  exit 0). Mutation M5 (`reason = ""`): 1 FAIL ("rewritten description with recorded change", exit 1). Each
  restored from the saved copy; restored SHA-256 `8e073a7e…` equals the pre-mutation copy.
- The real repository passes: no working requirement's Description differs from its baseline statement.

### Item 10 — AVE-REQ-093 Implementation evidence path (done)
- Change: AVE-REQ-093 § Implementation evidence names `ai-video-editor-requirements/tools/validate_package.py`
  and lists the pinned hash and the Description check under `scripts/check_baseline.py`.
- Test: inspection — the path exists (`test -f ai-video-editor-requirements/tools/validate_package.py`), and
  `grep -n validate_package docs/requirements/AVE-REQ-093-*.md` prints the full package path only.
  Mutation: not applicable (document path).

## Commands and results
- `./scripts/dev-container.sh python3 -B scripts/check_baseline.py` — exit 0, "Baseline manifest: PASS",
  "OK: baseline intact; 10 epics, 20 features and 101 requirements match their working files".
- `./scripts/dev-container.sh bash scripts/tests/test-check-baseline.sh` — `BASELINE TOTAL: pass=75 fail=0`.
- Mutations M1–M5 (`__pycache__` deleted before each run): results above; `git diff` after restore holds
  the intended change only.
- `./scripts/verify.sh` (fast tier) — `verify.sh: PASS — tier fast (9 of 9 steps passed)`.
- `./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks` — `scripts/tests/run.sh: PASS (6 suites)`
  (CHECKER 512/0, BASELINE 75/0, STOP HOOK 71/0, SESSION START 28/0, VERIFY TIERS 12/0, PROBE 14/0).

## Proposed updates for the lead-owned documents
- `docs/ASSUMPTIONS.md` — new entry: the baseline trust anchor is the SHA-256 of
  `ai-video-editor-requirements/MANIFEST.json` pinned as `BASELINE_MANIFEST_SHA256` in
  `scripts/check_baseline.py` — reason: of the two anchors the fix brief offers, the hash works in every
  checkout and in the suite's non-Git fixture copies with the standard library alone — impact: adopting a
  new baseline version from the human needs a commit that updates the pin and cites the human's input.
- `docs/ASSUMPTIONS.md` — new entry: the Description check compares the whole `## Description` section,
  fenced blocks included, with trailing whitespace of each line and blank lines around the section ignored —
  reason: text added in a fenced block changes the statement as much as plain text — impact: any visible
  Description edit of an imported requirement needs a `Description changed: <reason>` line.
- `docs/decisions/ADR-003-requirements-baseline-import.md` — decision 1: the pinned manifest hash in
  `scripts/check_baseline.py` anchors immutability together with the manifest hashes and
  `tools/validate_package.py`; decision 5: the check also fails on a Description that differs from the
  baseline statement without a `Description changed: <reason>` line.
- `docs/requirements/IMPORT_MAPPING.md` (generated by `scripts/requirements/import_baseline.py`, rules 1 and
  4): rule 1 can name the pinned manifest hash and rule 4 the `Description changed: <reason>` line; the change
  is in the generator plus a regenerated mapping, outside this part's allowed paths.
- `docs/TRACEABILITY.md` — AVE-REQ-093 row: no change needed (Implementation and Tests cells still name
  `scripts/check_baseline.py` and `scripts/tests/test-check-baseline.sh` (AC-1, AC-3, AC-4)).
- AVE-REQ-093 § Status — optional log line: Edge cases, Verification strategy and Implementation evidence
  updated for the pinned manifest hash and the Description check (fix brief items 1, 2, 10); status stays
  `in-progress` until the remaining parts land.
- `docs/PROGRESS.md` — part 1 of the M0 process fixes committed on `m0-process-fixes`.

## Open questions
None.
