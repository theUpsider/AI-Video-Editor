# Handback — M0 process fixes, final check of the four parts

Brief: `docs/briefs/2026-10-02-m0-process-fixes-execution.md` § Test commands, with items 1–26 of
`docs/briefs/2026-10-02-m0-process-verification-fixes.md`. Branch `m0-process-fixes` (worktree
`.claude/worktrees/m0-process-fixes`, created from `6736401`), checked at `a5c81d3`, the commit of part 4, on top
of parts 1 (`fb61875`), 2 (`3f7c44d`) and 3 (`a62e197`). Commit: the commit that adds this file, subject
"docs: record the final check of the M0 process fixes"
(`git log -1 --format=%h -- docs/briefs/handbacks/2026-10-02-m0-process-fixes-execution.md`).

Result: the three test commands pass at `a5c81d3`; no fix was needed, so this check adds no code commit. Five
items keep a piece that belongs to the lead (§ Open and partly done items).

File name: the launch prompt named `handbacks/2026-10-02-m0-process-fixes-execution.final.md`. Check 11 accepts
`<brief-slug>.md` and `<brief-slug>.part-<n>.md` only: a probe file under the `.final.md` name failed
`./scripts/dev-container.sh ./scripts/check-project-control.sh` with "names no brief:
docs/briefs/2026-10-02-m0-process-fixes-execution.final.md is missing" and was deleted. This final handback
therefore carries the brief-level name `<brief-slug>.md` (`docs/briefs/README.md` § Handbacks).

## Commands and results (at `a5c81d3`, tree clean)

1. `./scripts/verify.sh --tier release` — `verify.sh: PASS — tier release (12 of 12 steps passed)`, exit 0;
   2026-10-03 01:38:44–01:50:08 UTC. The run first printed `verify.sh: waiting for the heavy-media lock
   /tmp/ave-heavy-media.lock (…)` once, then took the lock and ran every step. Steps: Project control files
   PASS (8 s); Requirements baseline integrity PASS (24 s; "Baseline manifest: PASS", "OK: baseline intact");
   Evidence tooling unit tests PASS (15 s); Backend format check, lint, type check PASS; Backend unit tests
   PASS (108 passed, 62 deselected, 11 s); Backend media and population tests PASS (62 passed, 108 deselected,
   317 s); Verification tooling regression suites PASS (285 s; CHECKER 769/0, BASELINE 75/0, STOP HOOK 72/0,
   SESSION START 31/0, VERIFY TIERS 23/0, PROBE 28/0); Done requirements evidenced by this run PASS; Working
   tree unchanged by verification PASS; Evidence manifest PASS (`var/verify/latest-release.json`, recorded
   2026-10-03T01:50:07Z).
2. `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-093 AVE-REQ-094 AVE-REQ-096 AVE-REQ-097 AVE-REQ-098 --require-fresh`
   — exit 0; "Evidence: var/verify/latest-release.json — tier release, PASS, commit a5c81d3602bb";
   "Freshness: FRESH — the tree is unchanged since this run"; states below.
3. `./scripts/dev-container.sh bash scripts/tests/run.sh --all-awks` — `scripts/tests/run.sh: PASS (6 suites)`,
   exit 0 (CHECKER 769/0 over every installed awk, BASELINE 75/0, STOP HOOK 72/0, SESSION START 31/0, VERIFY
   TIERS 23/0, PROBE 28/0).
- `git status --short` after the three commands: empty.

## Per-criterion evidence states (release-tier manifest at `a5c81d3`)

| Criterion | State | Evidence in the run |
|---|---|---|
| AVE-REQ-093 AC-1 | passed | `scripts/tests/test-check-baseline.sh` |
| AVE-REQ-093 AC-2 | missing | inspection criterion; Test evidence line pending (item 26) |
| AVE-REQ-093 AC-3 | passed | `scripts/tests/test-check-baseline.sh` |
| AVE-REQ-093 AC-4 | passed | `scripts/tests/test-check-baseline.sh` |
| AVE-REQ-094 AC-1 | passed | `scripts/tests/test-probe-environment.sh` |
| AVE-REQ-094 AC-2 | missing | inspection criterion; Test evidence line pending (item 26) |
| AVE-REQ-094 AC-3 | missing | inspection criterion; Test evidence line pending (item 26) |
| AVE-REQ-094 AC-4 | missing | inspection criterion; Test evidence line pending (item 26) |
| AVE-REQ-096 AC-1 | passed | `scripts/tests/test-checker.sh` |
| AVE-REQ-096 AC-2 | passed | `scripts/tests/test-checker.sh` |
| AVE-REQ-096 AC-3 | missing | inspection criterion; Test evidence line pending (item 26) |
| AVE-REQ-096 AC-4 | passed | `scripts/tests/test-verify-tiers.sh` |
| AVE-REQ-097 AC-1 | passed | `scripts/tests/test-verify-tiers.sh` |
| AVE-REQ-097 AC-2 | passed | 14 results: `test-stop-hook.sh`, `test_evidence.py`, `backend/tests/unit/test_evidence_plugin.py` (3 functions) |
| AVE-REQ-097 AC-3 | passed | `scripts/tests/test-stop-hook.sh` |
| AVE-REQ-097 AC-4 | passed | 15 results: `test-stop-hook.sh`, `test-verify-tiers.sh`, `test_evidence.py`, `backend/tests/unit/test_evidence_plugin.py` (3 functions) |
| AVE-REQ-098 AC-1 | passed | `scripts/tests/test-session-start.sh` |
| AVE-REQ-098 AC-2 | passed | `scripts/tests/test-checker.sh`, `scripts/tests/test-session-start.sh` |
| AVE-REQ-098 AC-3 | passed | `scripts/tests/test-checker.sh`, `scripts/tests/test-probe-environment.sh` |
| AVE-REQ-098 AC-4 | passed | `scripts/tests/test-checker.sh`, `scripts/tests/test-stop-hook.sh` |

The five missing criteria are the ones the requirements verify by inspection. Each has a proposed
`- AC-n → inspection: …` line in the part-4 handback § Item 26; once the lead writes those lines into
`## Test evidence`, the manifest shows them as "inspected" and
`evidence.py show … --require-fresh --require-complete` can exit 0.

## Items 1–26 against `git diff 6736401..HEAD`

| Item | Requirement | State | Evidence |
|---|---|---|---|
| 1 | 093 AC-1, AC-3 | done | `scripts/check_baseline.py` `BASELINE_MANIFEST_SHA256`, `check_manifest_pin()`; `scripts/tests/test-check-baseline.sh` "edited MANIFEST.json fails", "baseline edit with a re-hashed manifest fails"; part-1 handback § Item 1 |
| 2 | 093 AC-3 | done | `check_requirements()` Description comparison and `Description changed: <reason>`; README § Baseline import and integrity rule 4, § Enforced checks 3; 093 § Edge cases; 8 suite cases; part-1 § Item 2 |
| 3 | 094 AC-1 | partial | Permissions and Models rows in `docs/ENVIRONMENT_CAPABILITIES.md`; probe § Claude Code and session with suite cases; 094 § Verification strategy AC-1; part-3 § Item 3. Open: the Models row names no run ID |
| 4 | 096 AC-1 | done | `CLAUDE.md` § Delegation "Brief before delegating"; develop § 3 steps 4–5, § 4 "Brief first", § 5 step 2, § 7; agent inputs; ENVIRONMENT_CAPABILITIES § Limits 3; part-4 § Item 4 |
| 5 | 096 AC-4 | done | `scripts/verify.sh` `hold_heavy_lock`; `scripts/tests/test-verify-tiers.sh` lock section (11 cases); develop § 4 Concurrency limits; delivery skill step 4; WF-003 corrected, WF-005; part-4 § Item 5; the release run above waited on the lock once |
| 6 | 097 AC-4 | done | `scripts/evidence.py` suite results, `record-suite`, `unittest`; `scripts/tests/run.sh` `record_suite`; `scripts/verify.d/15-evidence-tooling.sh`; four `test_evidence.py` cases; part-2 § Item 6 |
| 7 | 097 AC-2 | done | `tooling_tag_problems()` in `collect()`; `cmd_show` unknown IDs as `EvidenceError`; two `test_evidence.py` cases; part-2 § Item 7 |
| 8 | 098 AC-3 | partial | `CLAUDE.md` § Git; develop § Parallel work and § 13; 098 § Verification strategy AC-3 inspection; part-4 § Item 8. Open: PROGRESS.md names two local-only branches |
| 9 | 098 AC-3 | done | develop § 13; resume-project step 5 "Delegated work"; check 7 claim rule with 8 checker cases; part-4 § Item 9 |
| 10 | 093 | done | 093 § Implementation evidence names `ai-video-editor-requirements/tools/validate_package.py` (line 61) |
| 11 | 093 | done | `scripts/tests/test_evidence.py` builds IDs with `_id()`, `_tag()`; `grep -n "AVE-REQ-[0-9]"` prints only its twelve `# AVE-REQ-097 AC-n` comments |
| 12 | 094 AC-1 | done | probe verdict `accelerator: none (no device)`; `test-probe-environment.sh` cpus, memory, disk, verdict cases; part-3 § Item 12 |
| 13 | 094 | done | probe `claude --version`; version row 2.1.282 (the execution brief's host facts); workflows row cites three completed runs with results; resume-project step 6 "Environment"; part-3 § Item 13 |
| 14 | 094 AC-4 | done | `CLAUDE.md` § Delegation fallback; develop § 6 step 3; delivery skill step 6; part-4 § Item 14 |
| 15 | 096 AC-1, AC-2 | done | check 11 `AWK_BRIEF`: seven headings, order, empty sections, an ID, a commit; `test-checker.sh` heading loop and input-revision cases; part-3 § Item 15 and part-4 § Lead decisions (a) |
| 16 | 096 AC-2 | done | develop § 4 prompt and § Parallel work step 2, `.claude/agents/implementer.md`: `git rev-parse HEAD` by equality; part-4 § Item 16 |
| 17 | 096 AC-1 | partial | `docs/briefs/README.md` § Handbacks; check 11 `check_handbacks` with 5 cases; WF-001 wording corrected; part-4 § Item 17. Open: the review of each WF entry |
| 18 | 096 AC-2, AC-4 | done | WORKFLOW_LOG operating baseline; develop § 4 Concurrency limits; ENVIRONMENT_CAPABILITIES § Limits 3; 096 § Edge cases; part-4 § Item 18 |
| 19 | 097 AC-4 | done | `backend/tests/evidence_plugin.py` `pytest_collectreport`; `[module-level-skip]`, `[importorskip]` cases; part-2 § Item 19 |
| 20 | 097 AC-4 | done | `cmd_show --require-complete` exits 1 for a FAIL manifest; `test_a_failed_run_never_certifies_a_requirement_complete`; part-2 § Item 20 |
| 21 | 097 AC-4 | done | `backend/tests/unit/test_evidence_plugin.py` parametrized over five not-run modules; part-2 § Item 21 |
| 22 | 097 AC-3 | done | `scripts/tests/test-stop-hook.sh` marker steps per tier, "gate ran no media or release marker step"; part-3 § Item 22 |
| 23 | 098 AC-2, AC-4 | done | check 12 `PY_SETTINGS_POLICY` (modes, skipped prompts, hook commands, SessionStart coverage, async hooks); `test-checker.sh` cases; part-3 § Item 23 and part-4 (c) |
| 24 | 098 AC-1, AC-2 | done | `.claude/hooks/session-start.sh` `print_uncommitted_paths` (20 lines); `test-session-start.sh` three cases; 098 § Verification strategy AC-1; part-3 § Item 24 |
| 25 | 098 AC-3 | partial | `.env.example`; ENVIRONMENT_CAPABILITIES § External gaps; check for `.env.example`; probe case; part-3 § Item 25. Open: PROGRESS.md § Blockers and § Verification status |
| 26 | all five | partial | release-tier evidence: the run above; proposed inspection lines and the order: part-4 § Item 26. Open: `## Test evidence` of the five requirements |

## Open and partly done items

- Item 3: the Models row records the override check by "the workflow run of the M0 process fixes" with no run
  ID; the execution brief leaves the run ID to the lead after the run.
- Item 8: every hash in `docs/PROGRESS.md` is on the remote (the § Verification strategy AC-3 command printed
  nothing), and PROGRESS.md § In progress names the branches `m0-process-fixes` and `m0-media-follow-ups`,
  which `git branch -r` lacks (it lists `origin/main` and `origin/ccr-af7078da-q8r8mf`). Missing: push both
  branches alongside the working branch, or list them under § Blockers with the push command.
- Item 17: WF-001 to WF-005 each say "Review of this log entry: pending (the lead records it)" or "Independent
  review result: pending". Missing: an independent review of each entry with its result (AT-29).
- Item 25: PROGRESS.md § Blockers points to ENVIRONMENT_CAPABILITIES § Limits, and § Verification status names
  "the commit that adds ADR-009" with no hash. Missing: § Blockers points to § External gaps, and § Verification
  status names the commit and tier of a run (for example the release run of this check).
- Item 26: the five requirements' `## Test evidence` sections still hold the `_TBD` placeholder. Missing: the
  lead writes them after the reviews (inspection lines for 093 AC-2, 094 AC-2–AC-4, 096 AC-3 make those
  criteria "inspected"), then the moves to `done` in the order 093 → 094 → 096/097/098.

## Proposed updates for the lead-owned documents

- `docs/PROGRESS.md` — § In progress: parts 1–4 committed and checked on `m0-process-fixes`; next the
  re-verification in the order 093 → 094 → 096/097/098; push `m0-process-fixes` and `m0-media-follow-ups`
  (`git push origin m0-process-fixes m0-media-follow-ups`) or list them under § Blockers. § Blockers: point to
  `ENVIRONMENT_CAPABILITIES.md` § External gaps. § Verification status: `./scripts/verify.sh --tier release`
  PASS on branch `m0-process-fixes` in the development container (arm64; 12 of 12 steps; 108 unit, 62 media and
  population tests; 6 tooling suites) at the commit that adds this handback. § Next recommended work item 1:
  the fix brief is implemented; the reviews remain.
- The five requirement files, `## Test evidence`: the lines of the part-4 handback § Item 26, after the
  `verify-requirement` PASS of each.
- `docs/ENVIRONMENT_CAPABILITIES.md` Models row: the run ID of the workflow run of the M0 process fixes.
- `docs/WORKFLOW_LOG.md`: the review result of WF-001 to WF-005.
- `docs/TRACEABILITY.md`, `docs/ASSUMPTIONS.md`, `docs/ARCHITECTURE.md` § Verification pipeline,
  ADR-003, the IMPORT_MAPPING generator: the proposals of the part-1 to part-4 handbacks, unchanged.

## Open questions

1. Handback name for a final check: this file takes `<brief-slug>.md` because check 11 rejects `.final.md`.
   Recommended: launch prompts name `<brief-slug>.md` for the brief-level handback; a `.final` suffix needs a
   check-11 rule, a test case and a line in `docs/briefs/README.md` § Handbacks first.
