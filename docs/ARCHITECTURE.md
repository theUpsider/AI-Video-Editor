# Architecture

**Status:** current — stack selected 2026-10-01.

This file describes the AI Video Editor architecture. Significant decisions live in `docs/decisions/`
([index](decisions/README.md)); [ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md) records what the
development environment can execute. Component status markers: **built** (implemented and tested in this
repository), **in progress**, **planned**.

## Principles

1. Choose the simplest architecture that satisfies the current requirements.
2. Avoid speculative infrastructure: add a component, layer or service only when a
   requirement needs it.
3. Record every significant decision as an ADR in `docs/decisions/`
   ([format](decisions/README.md)) and link it here. This file describes the current
   architecture; ADRs record why it looks this way.
4. Update this file in the same commit as any change that alters the architecture, and delete
   obsolete content. `architecture-review`
   ([SKILL.md](../.claude/skills/architecture-review/SKILL.md)) checks for drift at every
   milestone review.

## Overview

A single-owner, self-hosted browser editor. A Python backend (`backend/`, package `ave`) owns the domain:
projects, immutable assets, a typed versioned composition document, a single command service for every edit
(UI, AI, MCP), synchronization analysis, captions and the render compiler. A separate worker process executes
durable jobs (probing, proxies, analysis, renders) with FFmpeg on CPU. A React/TypeScript client (`frontend/`)
provides the collection, timeline, preview, inspector, AI panel and exports. Core journey: import → probe →
sync estimate → (AI or rule-based) draft as one transaction → manual/conversational revisions → segmented CPU
render → decoded validation → atomic publish.

## Architectural drivers

- Exact time across source, sync-reference, project, section/short and output domains; 60 ≠ 60000/1001;
  half-open intervals; VFR via presentation timestamps (AVE-REQ-012, ADR-004).
- Real rendered output with independent decoded verification of geometry, timing and audio (AVE-REQ-072,
  075, 078, 083, AT-02/AT-04).
- Originals immutable; derived data rebuildable; safe cleanup (AVE-REQ-003, 080).
- One typed command service with revisions, idempotency, locks, scope and undo for UI, AI and MCP
  (AVE-REQ-015, 016, 046, 048, 049).
- CPU-only operation on a 4-vCPU/8-GiB reference worker within a 6-GiB render budget; GPU only when
  capability-tested (AVE-REQ-075, 076, 084, AT-23).
- Offline manual editing and export; external AI off until configured, consented and budgeted
  (AVE-REQ-087, 091, 054).
- Honest capability reporting: missing credentials/models/devices never produce fake success (AVE-REQ-099,
  ADR-007).

## System context

```text
            browser (React/TS UI)                external MCP client (Claude Code, Codex, …)
                    │ HTTP/JSON                         │ stdio (local) / Streamable HTTP + token
                    ▼                                   ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ backend API (FastAPI) ── command service ── domain (composition)  │
   │      │                        │                                   │
   │      │ SQLite (WAL): projects, revisions, transactions, assets,   │
   │      │ jobs, analysis, provider profiles, audit                   │
   └──────┼────────────────────────┼───────────────────────────────────┘
          │ job rows               │ configured, consented calls only
          ▼                        ▼
   worker process (FFmpeg/FFprobe, sync, ASR, keyframes, renders)      AI providers / agent runtimes
          │
          ▼
   data root: originals/ (content-addressed, read-only) derived/ exports/ tmp/ models/ db
```

## Components and boundaries

Dependency direction: `api`, `mcp`, `worker` → `services` → `domain`, `media`, `sync`, `render`, `analysis`,
`ai` → `timebase`. The domain never imports the API, worker or UI. Components interact through typed Python
interfaces and the command service.

### `ave.timebase` — built (M0)
Exact rationals, half-open intervals, frame/sample grid functions (ADR-004).

### `ave.media` — built (M0)
FFprobe parsing into typed `ProbeInfo` (exact dimensions, rotation, rational rates, VFR detection, color
tags), safe subprocess execution (argv lists, timeouts), decoded-frame/audio extraction.

### `ave.domain` — in progress
Composition model (sequences, tracks, clips, regions/fit, sync groups, overlays, sections, looks, subtitle
tracks, derived shorts), layout geometry, operation schemas and validation, the command service with revisions,
idempotency, locks, scope and undo/redo (ADR-004, ADR-006).

### `ave.sync` — built (M0, audio offset); planned (drift, visual events, manual anchors)
Audio-based offset estimation with confidence and insufficient-evidence results; multi-anchor affine drift;
visual flash events; manual anchors.

### `ave.render` — built (M0, split/full/split CPU export); planned (overlays, transitions, color, captions)
Segmented render compiler, FFmpeg execution, audio routing/mixing, decoded-output validation, atomic publish
(ADR-005).

### `ave.fixtures` — built (M0)
Deterministic synthetic media with ground-truth manifests (markers, flashes, impulses, pilot tones) for tests
and demos; clearly labeled synthetic.

### `ave.storage`, `ave.jobs`, `ave.api`, `ave.worker` — planned (M1)
SQLite persistence and migrations, durable jobs with leases and cancellation, FastAPI routes, worker loop.

### `ave.analysis`, `ave.captions`, `ave.ai`, `ave.mcp` — planned (M3–M6)
ASR adapters (ADR-008), transcripts, subtitle tracks and retiming, keyframes/shots, accidental-recording
detection, provider/agent adapters and planning (ADR-007), MCP server.

### `frontend/` — planned (M1)
React/TypeScript/Vite client: collection, timeline, preview (proxy playback plus backend reference frames),
inspector, AI panel, jobs and exports.

## Data model and persistence

- Entities follow the baseline [data model](../ai-video-editor-requirements/spec/DATA_AND_TIMING_MODEL.md):
  project, media asset (sha256, probe, capture metadata, provenance), derived asset, sequence, track, clip,
  sync group, overlay, color profile, transcript, subtitle track, section, transaction, job, provider profile.
- Storage: SQLite (WAL) with numbered SQL migrations (ADR-006); composition revisions are immutable JSON
  snapshots; originals are content-addressed files under the data root, made read-only after import.
- Retention: deleting project data never deletes originals by default; derived files are tracked in a registry
  and deleted only inside application-owned roots.

## Integration points

- **FFmpeg/FFprobe 6.1** (system binaries): probing, proxies, analysis audio, renders; argv only.
- **AI providers** (Anthropic Messages, OpenAI-compatible): HTTPS with server-side credentials from environment
  variables listed in `.env.example`; budgets, timeouts, retries, cancellation (ADR-007).
- **Agent runtimes** (Claude Agent SDK, Codex SDK/app-server): optional, constrained to editor operations.
- **MCP**: official Python SDK; stdio and authenticated Streamable HTTP.
- **Hugging Face Hub**: pinned model downloads through the model registry with consent (blocked in this
  development environment).
Failure handling: every integration reports `PROVIDER_UNAVAILABLE`/`UNSUPPORTED_CAPABILITY` with a corrective
action.

## Technology stack

Selection rules, applied by `technical-foundation`:

1. Derive technical requirements from the actual product requirements.
2. Research uncertain or fast-changing technologies first (researcher subagent): versions,
   maintenance status, licenses.
3. Select the simplest appropriate option, optimizing for correctness, maintainability,
   development speed, testability, ecosystem maturity, deployment practicality and the
   actual workload.
4. Never select a technology because it is fashionable.
5. Record each significant choice as an ADR before scaffolding.

| Concern | Choice | ADR |
|---|---|---|
| Backend language/runtime | Python 3.11 (uv-managed, locked) | [ADR-002](decisions/ADR-002-technology-stack.md) |
| API framework and schemas | FastAPI + Pydantic v2 | [ADR-002](decisions/ADR-002-technology-stack.md) |
| Time and composition model | Exact rationals, typed versioned document | [ADR-004](decisions/ADR-004-exact-time-and-composition-model.md) |
| Persistence and jobs | SQLite WAL, SQL migrations, durable job table + worker | [ADR-006](decisions/ADR-006-sqlite-revisions-and-durable-jobs.md) |
| Media processing | FFmpeg/FFprobe 6.1, segmented CPU renderer | [ADR-005](decisions/ADR-005-segmented-cpu-reference-renderer.md) |
| Signal analysis | NumPy + SciPy | [ADR-002](decisions/ADR-002-technology-stack.md) |
| Speech recognition | faster-whisper when cached; PocketSphinx offline floor | [ADR-008](decisions/ADR-008-local-speech-recognition.md) |
| AI integrations | Provider, agent-runtime, analysis and MCP adapters | [ADR-007](decisions/ADR-007-ai-integration-boundaries.md) |
| Frontend | React + TypeScript + Vite, Zustand, pnpm | [ADR-002](decisions/ADR-002-technology-stack.md) |
| Tests | pytest, ruff, mypy; Playwright for browser journeys | [ADR-002](decisions/ADR-002-technology-stack.md) |
| Requirements baseline | AVE IDs over an immutable package | [ADR-003](decisions/ADR-003-requirements-baseline-import.md) |
| Development on Windows/macOS | Linux development container mirroring CI | [ADR-009](decisions/ADR-009-linux-development-container-for-other-hosts.md) |

## Cross-cutting concerns

### Security

Media, names, transcripts, subtitles and model output are untrusted data: typed operations only, argv-only
subprocesses, UTF-8 text files for rendered text, path allowlists inside the data root, generated storage IDs,
size/time limits on media workers, prompt-injection boundaries for AI context. Remote API/MCP access requires
authentication and scopes. Baseline threat model:
[THREAT_MODEL.md](../ai-video-editor-requirements/spec/THREAT_MODEL.md).

In effect: never commit secrets; never weaken a security check to make tests pass.

### Error handling

Structured errors with codes from the baseline API (`REVISION_CONFLICT`, `LOCKED_OBJECT`, `INVALID_TIME_RANGE`,
`MISSING_ASSET`, `SOURCE_OUT_OF_BOUNDS`, `UNSUPPORTED_CAPABILITY`, `INSUFFICIENT_SYNC_EVIDENCE`,
`PROVIDER_UNAVAILABLE`, `BUDGET_EXCEEDED`, `UNAUTHORIZED`, `CANCELLED`, `RENDER_VALIDATION_FAILED`), operation
index, affected IDs, retryability and corrective action. Jobs record stage, progress and a redacted diagnostic.

### Observability

Structured logs with opaque IDs and redacted secrets/paths; job state transitions and diagnostics stored with
the job; a health endpoint; render reports with commands, durations and validation results.

### Configuration and secrets

Configuration from environment variables and a settings file under the data root; credentials only from the
environment (names in `.env.example`), referenced by provider profiles and never returned to the browser.
[.claude/settings.json](../.claude/settings.json) denies Claude reads of local `.env` files.

## Deployment and environments

- **Local development:** `backend/` via `uv`, `frontend/` via `pnpm`, system FFmpeg 6.1; the data root
  defaults to `./var/data` (gitignored). Linux is the supported platform; a Windows or macOS host works inside
  the development container ([ADR-009](decisions/ADR-009-linux-development-container-for-other-hosts.md)).
- **CI:** GitHub Actions ([verify.yml](../.github/workflows/verify.yml), [ASM-003](ASSUMPTIONS.md)) runs
  `./scripts/verify.sh`.
- **Self-hosted reference:** Linux CPU host; a container profile is planned.

### Local development

```sh
cd backend && uv sync && uv run pytest          # backend tests (media tests need FFmpeg)
./scripts/verify.sh                             # full repository verification
```

On a Windows host `./scripts/verify.sh` runs inside the development container by itself; every other
command takes the prefix `./scripts/dev-container.sh`, for example
`./scripts/dev-container.sh uv run --frozen --directory backend pytest -q tests/unit`. One-time checkout
settings there: `git config core.autocrlf false`, `git config core.eol lf`,
`git config worktree.useRelativePaths true`.

API, worker and frontend commands are added with M1.

## Testing strategy

- Unit tests (pytest) for timebase, layout geometry, operations/validation, sync estimation, caption mapping.
- Media integration tests (marker `media`) render real outputs from synthetic and derived fixtures (other
  containers, late streams, timestamp gaps, VFR, long GOPs) and validate decoded frames and audio against
  oracles computed from the fixture manifest, the files' own timestamps and spec math, never from the compiler.
- Population tests (marker `slow`) run seeded families of synthetic signals (unrelated, lattice-structured,
  few-event) and count outcomes: a wrong offset is never acceptable, sensitivity has a floor.
- Browser end-to-end tests (Playwright) for the user journeys once the UI exists.
- Contract tests for AI adapters against local fake servers, marked `contract`; live tests only with configured
  credentials, reported separately.

In effect:

1. Every acceptance criterion has at least one automated test, or a documented verification
   when automation is impractical.
2. Python tests carry their criteria as `@pytest.mark.req("AVE-REQ-NNN AC-n", …)` and scenarios as
   `@pytest.mark.scenario("AT-NN")`; tooling tests in `scripts/tests/` use `# AVE-REQ-NNN AC-n` comment lines.
   The evidence plugin ([backend/tests/evidence_plugin.py](../backend/tests/evidence_plugin.py)) rejects a tag
   that names no existing criterion or scenario before any test runs; see [TRACEABILITY.md](TRACEABILITY.md).
   A tooling tag counts only through a suite result of the run (file, exit status, numbers of checks and of
   failed checks, tags; a suite that exited 0 without running a check, or with a failed check in its own
   total, counts against its tags), which [scripts/tests/run.sh](../scripts/tests/run.sh) writes for each shell
   suite it runs and `scripts/evidence.py unittest` for each unit-test file; a tooling tag that names no
   existing criterion fails the "Evidence manifest" step with its file and line. Tags of a shell suite count
   per file; in a unit-test file each tag stands directly above the test it names. A test that exists and did
   not run in a tier (deselected, or a tooling file without a suite result) is recorded as `not-run` and
   evidences nothing.
3. Tests are deterministic and run non-interactively. verify.sh runs pytest with the configuration of
   `backend/pyproject.toml` alone and with `--forbid-skips`: a skipped, expected-to-fail or unexpectedly
   passing test, a module skipped at collection, or a selected test that never ran fails the run, and each
   pytest step fails without a report that holds executed tests; a test file Git ignores stops the session.
   The tooling unit tests run under `scripts/evidence.py unittest`, each file in its own interpreter with
   warnings as errors, which applies the same rule and also fails a file without tests. Fix flaky tests at
   the root; in shell suites a check never pipes into `grep -q` (under `pipefail` the writer can die of
   SIGPIPE and flip the check): the suites' `quiet` reads its whole input.
4. `./scripts/verify.sh` runs every test level; core user journeys run as end-to-end or smoke
   tests.
5. `./scripts/verify.sh` never needs credentials or paid services. External services run on
   their fakes (tests marked `contract`, which never evidence a criterion alone); live-service checks run
   through a separate command documented here.
6. One heavy media job runs at a time on a host (AVE-REQ-096 AC-4; `develop` § 4 Concurrency limits). The
   heavy-media lock is the file `${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}`. A media or
   release tier run of `./scripts/verify.sh` holds an exclusive `flock` on it from its first step to its
   summary, prints one line `verify.sh: waiting for the heavy-media lock …` while another job holds it,
   and exports `AVE_HEAVY_LOCK_HELD=1` to its steps; the fast tier takes no lock. Every other heavy media
   command (a targeted `-m "media or slow"` run, a reproduction that renders or decodes media) runs as
   `flock "${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}" <command>` in the environment that runs
   the checks (on a host that verifies in the development container:
   `./scripts/dev-container.sh bash -c 'flock "${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}" <command>'`).
   A command that already holds the lock and starts verify.sh's media or release tier sets
   `AVE_HEAVY_LOCK_HELD=1`, so the run takes no second lock; the run first confirms that the lock is held and
   fails before any step when nobody holds it. `scripts/tests/test-verify-tiers.sh` tests the lock.

Commands: `cd backend && uv run pytest -m "not media and not slow"` (fast),
`flock "${AVE_HEAVY_LOCK:-${TMPDIR:-/tmp}/ave-heavy-media.lock}" uv run pytest -m "media or slow"` (media and
population, under the heavy-media lock of item 6), `uv run pytest tests/path::name` (one test),
`uv run pytest -m req -k …` or `python3 scripts/evidence.py show AVE-REQ-NNN` after a verify.sh run (the
criteria of one requirement with their tests and outcomes), `python3 -B scripts/evidence.py unittest` (the
evidence tooling unit tests), `scripts/tests/run.sh` (the tooling regression suites),
`./scripts/probe-environment.sh` (re-measure the environment,
[ENVIRONMENT_CAPABILITIES.md](ENVIRONMENT_CAPABILITIES.md)).

## Verification pipeline

In effect since bootstrap
([ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)), tiered since M0.

1. **Single entry point.** [scripts/verify.sh](../scripts/verify.sh) is the one command
   humans, Claude, the Stop hook and CI run. It runs every step of its tier, prints a summary, and exits
   1 when any step fails (2 on a usage error).
2. **Tiers.** `--tier fast` (default): project control files, no ignored file among sources, tests,
   scripts and hooks, requirements baseline integrity, evidence tooling tests, backend format/lint/types,
   unit tests (their media tools are a stand-in that exits 1, so the fast tier renders nothing).
   `--tier media` adds the real-media and population tests. `--tier release` adds the tooling regression suites ([scripts/tests/run.sh](../scripts/tests/run.sh),
   every installed awk). Every tier ends its checks with the step "Done requirements evidenced by this run":
   a `done` requirement with failed, contract-only or missing evidence fails it, and in the release tier,
   which runs every test, a tagged test that did not run fails it too. Component steps live in
   [scripts/verify.d/](../scripts/verify.d/); each is a required file, verify.sh sources exactly the required
   ones, a step file that cannot be loaded fails the run, and the checker fails on any other entry there.
   A run clears the caller's Git, Python and pytest variables, loads no pytest plugin by itself, keeps
   bytecode and the type checker's cache in a scratch directory outside the tree, keeps the directory of a
   script out of every Python module path and selects tests by marker expression only
   ([ASM-023](ASSUMPTIONS.md) names what stays trusted).
   The media and release tiers hold the heavy-media lock for their whole run (§ Testing strategy item 6); in the
   development container the lock file lives on the shared state volume (`AVE_HEAVY_LOCK`).
3. **Evidence.** Each run records a new directory `var/verify/runs/<run-id>/`: the step log, one pytest
   report per test step, one suite result per tooling test file that ran, and `manifest.json`, written once,
   which ties the results to the commit, the tree fingerprint, the toolchain (the media tools the product
   resolves and a digest of the installed backend packages), the configuration hashes, the pytest invocations
   and every criterion and scenario tag ([scripts/evidence.py](../scripts/evidence.py);
   `var/verify/latest-<tier>.json` holds the newest of each tier). `evidence.py show` takes the heaviest
   manifest that is fresh and reports a manifest STALE once the tree or the toolchain changes: stale evidence
   certifies nothing, and `--require-complete` fails for a failed fresh run of any tier and for a tagged test
   that did not run. A tree the fingerprint cannot see (index flags, filter attributes, ignore rules outside
   `.gitignore`, an embedded repository) has no fingerprint, so nothing is fresh there. The steps "Working
   tree unchanged by verification" and "Evidence manifest" run last.
4. **Stop gate.** [.claude/hooks/stop-verify.sh](../.claude/hooks/stop-verify.sh) runs
   `verify.sh --tier fast` when Claude finishes a turn and the working tree differs from the last passing
   tree, so no turn triggers media renders. A failure blocks stopping and feeds the log tail back to
   Claude; after `CLAUDE_VERIFY_MAX_ATTEMPTS` (default 3; 1 to 10) consecutive failures the gate releases with
   a warning. `CLAUDE_VERIFY_GATE=off` disables it for humans; check 12 fails a settings file that sets a gate
   variable, removes the gate or adds a second Stop command. Results and the full log live in
   `.git/claude-verify/` (one per worktree).
5. **Session start.** [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh)
   reports the uncommitted paths (a bounded list), the last verification result and whether it matches the
   current tree. Both hooks
   activate after workspace trust ([ASM-001](ASSUMPTIONS.md)) and are thin adapters over
   [scripts/lib/verify-state.sh](../scripts/lib/verify-state.sh), which holds the working-tree
   fingerprint and the state records; verify.sh and the evidence manifest use the same fingerprint.
6. **CI.** [.github/workflows/verify.yml](../.github/workflows/verify.yml) installs FFmpeg, the awk
   implementations and the locked backend environment, then runs `./scripts/verify.sh --tier release` on
   push, pull request and manual dispatch.
7. **Rules.** verify.sh stays non-interactive, deterministic, read-only toward the working tree
   (outputs go to gitignored paths) and identical locally and in CI. Never weaken, skip or suppress a check
   to get green; fix the root cause.

## Risks and technical debt

- **No live AI, GPU, Hugging Face or multilingual ASR in the development environment** — provider, agent-runtime,
  vision, translation and GPU criteria stay externally unverified until a configured host runs them; tracked in the
  release capability matrix (AVE-REQ-099).
- **Stop-gate cost grows with media tests** — verify.sh tiers keep the default run fast; heavy media and release
  tiers run in CI and at milestone gates (mitigation planned in M0 integration).
- **Concat-copy assembly** depends on identical segment encoder settings; validated per export, with a
  lossless-intermediate fallback if a codec misbehaves (ADR-005).
