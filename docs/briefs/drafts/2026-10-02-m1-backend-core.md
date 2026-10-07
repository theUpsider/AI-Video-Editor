# Brief — M1 backend core: persistence, originals, import, command service, history

## Requirements
Implement every acceptance criterion that the backend can satisfy for these requirements (working files in
`docs/requirements/AVE-REQ-NNN-*.md` hold the verbatim ACs, Edge cases and Verification strategy; read each in
full before coding):
- AVE-REQ-001 Persistent projects and project settings (AC-1–AC-4).
- AVE-REQ-002 Collection-based batch ingestion (backend of AC-1–AC-4: per-file states, resumable chunked uploads
  with bounded memory, one failure never blocks the batch, server-path import limited to configured roots after
  realpath resolution; browser filenames never trusted as paths).
- AVE-REQ-003 Immutable originals and stable asset identities (AC-1–AC-4: content-addressed read-only originals,
  re-import of identical bytes returns the existing asset, references survive renames, derived records carry
  source checksum, revision and settings).
- AVE-REQ-004 AC-1 (persist the probe in project storage; probing itself exists in `ave.media.probe`).
- AVE-REQ-009 Broken media and relinking (AC-1–AC-4).
- AVE-REQ-048 One typed editing command service (AC-1–AC-4; AC-1's analysis, profile, subtitle, section and
  render-job operations get their schema entries now and their behavior in the milestones that own them — mark
  each unimplemented operation with UNSUPPORTED_CAPABILITY, never a silent no-op).
- AVE-REQ-015 Undo, redo, autosave and revisions (AC-1–AC-4 at the service level; AC-4 pins a revision that the
  M1 export job will consume).
- AVE-REQ-018 AC-3 wiring (provisional 30/1 until the first import resolves the rate; never silently changed by a
  later import; uses `ave.domain.rates`), AVE-REQ-020 AC-3 (save and apply a layout preset).
Contracts: `ai-video-editor-requirements/spec/EDITING_API.md`, `DATA_AND_TIMING_MODEL.md`, `THREAT_MODEL.md`;
ADR-004 (composition document, revision snapshots, linear undo), ADR-006 (SQLite revisions; jobs come in the next
task). Error vocabulary: REVISION_CONFLICT, LOCKED_OBJECT, INVALID_TIME_RANGE, MISSING_ASSET,
SOURCE_OUT_OF_BOUNDS, UNSUPPORTED_CAPABILITY, INSUFFICIENT_SYNC_EVIDENCE, VALIDATION_ERROR (with operation index,
affected IDs, safe message, retryable flag and corrective action).

## Input revision
The `ccr-af7078da-q8r8mf` commit that closes M0 (media-core fixes merged, test tags converted to markers, M0
review recorded); the launching prompt names its hash. Isolated worktree created by the runtime from that HEAD.
Confirm `git log --oneline -1` shows that hash before changing anything; report a mismatch as BLOCKED. Commit on the
worktree branch when verification passes; never push, merge or rebase.

## Allowed paths
- New: `backend/src/ave/config.py`, `backend/src/ave/storage/**` (SQLite, numbered SQL migrations with a
  pre-migration backup, content-addressed media store, uploads), `backend/src/ave/domain/operations.py`,
  `backend/src/ave/domain/service.py`, `backend/src/ave/services/**`, `backend/tests/storage/**`,
  `backend/tests/service/**`.
- Changed: `backend/src/ave/domain/model.py` (fields the operations need: locks, layout presets, track flags;
  keep serialized compositions without new fields valid), `backend/pyproject.toml` / `backend/uv.lock` only to add
  a dependency the ADRs name (none expected for this task; report any other).

## Forbidden paths
`backend/src/ave/sync/**`, `backend/src/ave/fixtures/**`, `backend/src/ave/domain/sync_layout.py`,
`backend/src/ave/domain/coverage.py`, `backend/tests/sync/**` (the concurrent M2 synchronization task owns them);
`backend/src/ave/render/**` (report needed changes); `docs/**`, `scripts/**`, `.github/**`, `.claude/**`,
`CLAUDE.md`, `ai-video-editor-requirements/**`.

## Dependencies and constraints
- Read the existing modules first (`ave.timebase`, `ave.media`, `ave.domain.model/layout/rates/sync_layout`,
  `ave.render`, `ave.proc`, `ave.errors`, `ave.paths`) and extend them; never duplicate them.
- Originals: stored once under the data root at `originals/<sha256[:2]>/<sha256>`, mode 0444, written through a
  temp file, fsync and atomic rename; the original filename is untrusted display metadata only.
- Transactions: validate every operation on a copy; commit the new immutable revision snapshot and the
  transaction row atomically; idempotent replay returns the original result; the same key with a different
  payload is an error; `actor` is `user | ai | mcp` and never changes the semantics of an operation.
- No operation accepts shell strings, filesystem paths or raw filter graphs.
- Every test that verifies a criterion carries `@pytest.mark.req("AVE-REQ-NNN AC-n", ...)` (one full tag per
  criterion; the plugin rejects unknown tags); scenario tests also `@pytest.mark.scenario("AT-NN")`. Persistence
  across restart is tested with a new process or a fresh connection on the same data root.
- One heavy media job at a time; this task needs few media runs.
- Host and gates: on this Windows host `./scripts/verify.sh` enters the Linux development container by itself
  (ADR-009); every other check or test command takes the prefix `./scripts/dev-container.sh`. The fast tier
  resolves FFmpeg and FFprobe to a stand-in that exits 1, so every test that calls a media tool carries
  `@pytest.mark.media` (populations `slow`). A run fails on a skipped, expected-to-fail or deselected test, on
  a tag that names no criterion, and on every file outside the fingerprint whose path the list in
  `scripts/verify.sh` does not admit ([ASM-036](../../ASSUMPTIONS.md)): outputs, caches and scratch files go
  below `var/` or into the container's `/tmp`, and the tree holds one `.gitignore`, at its root. ruff, mypy and
  pytest read `backend/pyproject.toml` by name. A new `ave` module that the fixture generator imports joins the
  generator digest, so the fixtures regenerate once.
- Shared container: the worktrees of the main checkout use one development container. Stop a process only by
  its process ID or by a working directory of your own; when your worktree already holds edits (the run started
  the task again), read `git status` and `git diff` before changing anything
  ([WF-012](../../WORKFLOW_LOG.md)).
- Statement audit: before the handback, go through § Edge cases, § Verification strategy and § Implementation
  evidence of each requirement file you propose text for. Every sentence that states what the code or a test
  does names a test that fails without it (run the one-line mutant), or is reworded to what holds, or is worded
  as a limit with its inspection; the handback holds the table and the mutation list in full
  ([WF-010](../../WORKFLOW_LOG.md)).

## Test commands
- `./scripts/verify.sh --tier media` must pass (it runs pytest with `--forbid-skips`).
- `./scripts/dev-container.sh python3 -B scripts/evidence.py show AVE-REQ-001 AVE-REQ-002 AVE-REQ-003 AVE-REQ-009
  AVE-REQ-015 AVE-REQ-048 --tier media` after that run: report the per-criterion states in the handback.

## Handback schema
`## Result: COMPLETE | PARTIAL | BLOCKED`, then: branch and commit hash; per requirement and AC: status
(implemented / partial / not started), the tests (node IDs) and what they prove; commands run with results;
decisions taken (proposed ASSUMPTIONS entries); deviations and proposed follow-up requirements; documentation
updates for the lead (ARCHITECTURE sections, Implementation evidence lines). The lead writes the returned report
to `docs/briefs/handbacks/` (the task changes no file under `docs/`).
