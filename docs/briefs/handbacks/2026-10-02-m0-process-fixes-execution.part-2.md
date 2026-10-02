# Handback — M0 process fixes, part 2 (evidence tooling): items 6, 7, 11, 19, 20, 21

Brief: `docs/briefs/2026-10-02-m0-process-fixes-execution.md` (part 2) with the findings of
`docs/briefs/2026-10-02-m0-process-verification-fixes.md`. Branch `m0-process-fixes` (worktree
`.claude/worktrees/m0-process-fixes`), built on part 1 (`fb61875`). Commit: the commit that adds this file,
subject "AVE-REQ-097: credit tooling evidence only from suites that ran and validate its tags"
(`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.part-2.md`).

## Items

### Item 6 — AVE-REQ-097 AC-4: tooling evidence only from suites that ran (done)
- Change: `scripts/evidence.py` — `SUITE_STEPS` and `suite_tags()` removed; a suite result
  `suite-<file>.json` (schema, file, exit status, comment tags with line numbers) per tooling test file that
  ran is the only source of tooling evidence: `write_suite_result()` and the command `record-suite`,
  `read_suite_results()`, `collect()` credits each tag of a result once per file with that file's exit status;
  the manifest lists the suites (`"suites"`). New command `unittest [--dir DIR] [DIRECTORY]`
  (`run_unit_tests()`): each `test_*.py` file runs as one suite; a file fails on a failing or erroring test,
  a skip (test, class or module), an expected failure, an unexpected success, or when no test ran; with DIR
  (default `$AVE_EVIDENCE_DIR`) it writes each file's result. `scripts/tests/run.sh` — `record_suite()` writes a
  result for each suite it runs when `AVE_EVIDENCE_DIR` is set (inside verify.sh); a failed write fails the run.
  `scripts/verify.d/15-evidence-tooling.sh` — the "Evidence tooling unit tests" step runs
  `python3 -B scripts/evidence.py unittest --dir "$AVE_EVIDENCE_DIR" scripts/tests`. `scripts/verify.sh` header
  comment. `docs/ARCHITECTURE.md` § Testing strategy items 2, 3 and Commands. AVE-REQ-097 § Edge cases,
  § Verification strategy (AC-4), § Implementation evidence.
- Tests (`scripts/tests/test_evidence.py`, tagged `AVE-REQ-097 AC-4`):
  `test_a_skipped_unit_test_fails_the_unit_test_step_and_evidences_nothing` (subtests: skipped test, skipped
  class, skipped module — the reviewer's `@unittest.skip` probe: exit 1, tag "failed", `done_problems()` refuses);
  `test_a_suite_that_run_sh_never_runs_gives_no_evidence` (runs a copy of `run.sh` over stubs of every suite it
  lists plus a tagged `test-placeholder.sh` with body `exit 1` that it never runs — the reviewer's probe: the
  placeholder's tag is absent and `done_problems()` reports it "missing"; the failing listed stub counts
  "failed"); `test_the_unit_test_step_fails_on_every_test_that_did_not_pass` (subtests: failing, erroring,
  expected failure, unexpected success, file without tests, no test file; control: a passing file exits 0 and
  its tag passes); `test_tooling_tags_count_only_through_a_suite_result_of_the_run` (every step PASS and no
  result: no evidence; result content with line numbers; a failing result counts against every tag).
- Mutations (`var/mutations/mutate.py`, gitignored; `__pycache__` deleted before each run; file restored from
  the in-memory copy, SHA-256 checked equal after each):
  M1 `collect()` credits every result as passed → 10 failures (all six cases above with their subtests);
  M2 `run.sh` records every `test-*.sh` as passed → 1 failure (`…run_sh_never_runs…`);
  M3 `run.sh` records nothing → 1 error (`…run_sh_never_runs…`);
  M4 runner ignores skips → 3 failures (skipped test, class, module);
  M5 ignores expected failures → 1 failure; M6 ignores unexpected successes → 1 failure;
  M7 accepts a file without tests → 1 failure; M8 ignores failing tests → 1 failure.
- Real-tree probes (probe files created, run, deleted): `scripts/tests/test_probe_skip.py` with a skipped test
  tagged `AVE-REQ-012 AC-2` → `evidence.py unittest` exit 1, "skipped: test_probe_skip.T.test_a", the tag
  collected as "failed"; `scripts/tests/test-placeholder.sh` (`exit 1`, tagged `AVE-REQ-012 AC-1`, absent from
  run.sh) with the six results of a recorded run.sh run → "no evidence".

### Item 7 — AVE-REQ-097 AC-2: tooling tags validated; unknown IDs in `show` (done)
- Change: `scripts/evidence.py` — `comment_tags()` and `tooling_tag_problems()`: `collect()` validates with
  `tag_problems()` every tag of the run's suite results and of every tooling test file in `scripts/tests/`
  (whether or not it ran), and raises `EvidenceError` listing `file:line: problem`; `record` (the "Evidence
  manifest" step of every tier) and `check-done` exit 2 and write no manifest. `cmd_show` checks every
  requirement ID it shows (named or taken from the manifest) and reports an unknown one as an `EvidenceError`
  ("unknown requirement IDs: … (no file in docs/requirements/)", exit 2); the `KeyError` is gone. AVE-REQ-097
  § Edge cases, § Verification strategy (AC-2), § Implementation evidence.
- Tests (`scripts/tests/test_evidence.py`, tagged `AVE-REQ-097 AC-2`):
  `test_tooling_tags_that_name_no_criterion_stop_the_run_with_file_and_line` (the reviewer's probe: tags
  `AC-9` of an existing requirement and an unknown ID → `record` raises with `file:4` and `file:5`, writes no
  manifest and no latest copy; `record` and `check-done` commands exit 2; a suite result outside
  `scripts/tests/` is validated with its file and line); `test_show_reports_an_unknown_requirement_id_as_an_error`
  (manifest naming an ID without a file: `show` and `show <ID>` exit 2 with the message; `show <known ID>` exits 0).
- Mutations: M9 validation result replaced by `[]` → 1 failure; M10 scan of files that did not run removed →
  1 failure; M11 `show` checks only the named IDs → 1 error (`KeyError`, the finding's crash).
- Real-tree probe: `test-placeholder.sh` with `# AVE-REQ-097 AC-9` and `# AVE-REQ-999 AC-1` →
  `evidence.py check-done` exit 2, "scripts/tests/test-placeholder.sh:4: 'AVE-REQ-097 AC-9': … has no such
  criterion", ":5: 'AVE-REQ-999 AC-1' names no requirement file". The real tooling files have no invalid tag.

### Item 11 — AVE-REQ-093: no real tag as a fixture string in `test_evidence.py` (done)
- Change: `scripts/tests/test_evidence.py` — synthetic IDs and tags are built at run time by `_id()` and
  `_tag()`; the file holds no literal requirement ID or tag outside the comment tags of its own cases.
- Test: inspection — `grep -n "AVE-REQ-[0-9]" scripts/tests/test_evidence.py` prints only the twelve
  `# AVE-REQ-097 AC-n` comment lines; `comment_tags()` on the file returns only `AVE-REQ-097` tags.
  Mutation: not applicable (source text).

### Item 19 — AVE-REQ-097 AC-4: `--forbid-skips` sees modules skipped at collection (done)
- Change: `backend/tests/evidence_plugin.py` — `EvidenceRecorder.pytest_collectreport()` records a skipped
  collector (module-level `pytest.skip(allow_module_level=True)`, `pytest.importorskip`) as one `skipped`
  entry, which the report lists and `--forbid-skips` fails; module docstring.
- Tests (`backend/tests/unit/test_evidence_plugin.py`, module tags `AVE-REQ-097 AC-2`, `AVE-REQ-097 AC-4`):
  `test_forbid_skips_fails_a_session_with_a_test_that_did_not_run[module-level-skip]` and `[importorskip]`
  (pytester: a passing module plus the skipped module; without the option exit OK and the report records
  `test_generated.py` as skipped; with `--forbid-skips` exit TESTS_FAILED).
- Mutation M13 (hook renamed so pytest never calls it) → 2 failed ("1 passed, 1 skipped", the finding's
  result).

### Item 20 — AVE-REQ-097 AC-4: a failed run never certifies completeness (done)
- Change: `scripts/evidence.py` `cmd_show` — `--require-complete` exits 1 when the manifest's result is FAIL
  and prints "Completeness: the run FAILED; …"; `--require-fresh` keeps checking freshness only. Docstring.
- Test: `scripts/tests/test_evidence.py::test_a_failed_run_never_certifies_a_requirement_complete`
  (`AVE-REQ-097 AC-4`): every criterion passed, a failed step → `show <ID> --require-fresh --require-complete`
  exits 1; the same run with every step passed → 0.
- Mutation M12 (failed result ignored) → 1 failure.

### Item 21 — AVE-REQ-097 AC-4: one module per not-run category (done)
- Change: `backend/tests/unit/test_evidence_plugin.py` — the mixed skip-and-xfail case replaced by
  `test_forbid_skips_fails_a_session_with_a_test_that_did_not_run`, parametrized over skip-only, xfail-only,
  xpass-only, module-level-skip and importorskip modules, each beside a passing module; each asserts the
  report's outcomes, exit OK without the option and TESTS_FAILED with it.
- Mutations of `_NOT_RUN`: M14 without `skipped` → 3 failed (skip-only, module-level-skip, importorskip);
  M15 without `xfailed` → 1 failed (xfail-only); M16 without `xpassed` → 1 failed (xpass-only).

## Commands and results
- `./scripts/dev-container.sh python3 -B scripts/evidence.py unittest scripts/tests` — 13 tests OK,
  "evidence.py unittest: PASS (1 file(s))".
- `./scripts/dev-container.sh bash -c "cd backend && uv run --frozen --quiet ruff format --check . ; uv run --frozen --quiet ruff check . ; uv run --frozen --quiet mypy; uv run --frozen --quiet pytest -q -p no:cacheprovider --forbid-skips tests/unit/test_evidence_plugin.py"`
  — formatted; lint E501 on one new line, fixed and rerun clean by verify.sh; mypy no issues; 12 passed.
- `./scripts/dev-container.sh python3 -B var/mutations/mutate.py` — M1–M16 each caught (results above);
  `git diff` after the run holds the intended change only.
- `./scripts/verify.sh` (fast tier) — `verify.sh: PASS — tier fast (9 of 9 steps passed)`; the manifest lists
  the suite result of `scripts/tests/test_evidence.py`.
- `./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks` — `scripts/tests/run.sh: PASS (6 suites)`
  (CHECKER 512/0, BASELINE 75/0, STOP HOOK 71/0, SESSION START 28/0, VERIFY TIERS 12/0, PROBE 14/0).
- `./scripts/dev-container.sh env AVE_EVIDENCE_DIR=var/mutations/rundir bash scripts/tests/run.sh` — PASS;
  six `suite-*.json` results; `collect()` credits 093 AC-1/3/4, 094 AC-1, 096 AC-1, 097 AC-1–AC-4, 098 AC-2/4
  from them; `evidence.py check-done --dir var/mutations/rundir` — "OK: every criterion of the 0 done
  requirements is evidenced by this run".
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-097 --require-fresh --require-complete`
  after the fast run — FRESH; AC-2, AC-4 passed; AC-1, AC-3 missing (their suites run in the release tier);
  exit 1.
- Release tier: not run in this part (the brief runs it after part 4); its two changed paths (run.sh inside
  verify.sh with `AVE_EVIDENCE_DIR`, `check-done` with validation) were exercised by the two commands above.

## Proposed updates for the lead-owned documents
- `docs/TRACEABILITY.md` § Conventions 1 — after "as a `# AVE-REQ-NNN AC-n` comment line directly above the
  case": "; a tooling tag counts only through a suite result of the run, with that file's exit status
  (`scripts/tests/run.sh` for the shell suites it lists, `scripts/evidence.py unittest` for `test_*.py`), and
  one naming no existing criterion stops the run with its file and line".
- `docs/TRACEABILITY.md` — AVE-REQ-097 row: Implementation cell adds `scripts/tests/run.sh`; Tests cell
  unchanged.
- `docs/ARCHITECTURE.md` § Verification pipeline item 3 (outside this part's allowed section): "the step log,
  one pytest report per test step, one suite result per tooling test file that ran and `manifest.json`".
- `docs/ASSUMPTIONS.md` — new entry: tooling evidence is credited per file — assumption: a suite result
  credits every comment tag of the file with the file's exit status — reason: the fix brief's per-suite result
  contract; the shell suites have no per-case runner — impact: one failing case fails every criterion its file
  tags; a shell-suite tag counts only in the release tier, a unit-test tag in every tier.
- `docs/ASSUMPTIONS.md` — new entry: `evidence.py unittest` fails a file in which no test ran — reason: a
  never-collected test gives no evidence (AVE-REQ-097 edge case) — impact: an empty `test_*.py` file in
  `scripts/tests/` fails the fast tier.
- `docs/ASSUMPTIONS.md` — new entry: tooling tags are validated by scanning every tooling test file at
  `record` and `check-done` — reason: the fast tier runs no shell suite, and a bad tag must stop every tier —
  impact: a tag in a release-only suite that names no criterion fails the fast tier's "Evidence manifest" step.
- `docs/ASSUMPTIONS.md` — new entry: `show --require-complete` exits 1 for a failed run; `--require-fresh`
  alone checks freshness only — reason: certifying completeness needs a passing run, freshness is a property
  of the tree — impact: a reviewer certifies with both flags.
- `.claude/skills/verify-requirement/SKILL.md:61` (part 4 or the lead): the reviewer's command can add
  `--require-complete`, so a failed or incomplete run exits 1.
- AVE-REQ-097 § Status — optional log line: Edge cases, Verification strategy and Implementation evidence
  updated for suite results, tooling-tag validation, collection-time skips and failed runs (fix brief items 6,
  7, 19, 20, 21); status stays `in-progress` until the remaining parts land.
- `docs/PROGRESS.md` — part 2 of the M0 process fixes committed on `m0-process-fixes`.

## Open questions
None.
