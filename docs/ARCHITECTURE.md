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

### `ave.timebase` — in progress (M0)
Exact rationals, half-open intervals, frame/sample grid functions (ADR-004).

### `ave.media` — in progress (M0)
FFprobe parsing into typed `ProbeInfo` (exact dimensions, rotation, rational rates, VFR detection, color
tags), safe subprocess execution (argv lists, timeouts), decoded-frame/audio extraction.

### `ave.domain` — in progress
Composition model (sequences, tracks, clips, regions/fit, sync groups, overlays, sections, looks, subtitle
tracks, derived shorts), layout geometry, operation schemas and validation, the command service with revisions,
idempotency, locks, scope and undo/redo (ADR-004, ADR-006).

### `ave.sync` — in progress (M0, audio offset); planned (drift, visual events, manual anchors)
Audio-based offset estimation with confidence and insufficient-evidence results; multi-anchor affine drift;
visual flash events; manual anchors.

### `ave.render` — in progress (M0, split/full/split CPU export); planned (overlays, transitions, color, captions)
Segmented render compiler, FFmpeg execution, audio routing/mixing, decoded-output validation, atomic publish
(ADR-005).

### `ave.fixtures` — in progress (M0)
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
  defaults to `./var/data` (gitignored).
- **CI:** GitHub Actions ([verify.yml](../.github/workflows/verify.yml), [ASM-003](ASSUMPTIONS.md)) runs
  `./scripts/verify.sh`.
- **Self-hosted reference:** Linux CPU host; a container profile is planned (no Docker daemon in the
  development environment to test it).

### Local development

```sh
cd backend && uv sync && uv run pytest          # backend tests (media tests need FFmpeg)
./scripts/verify.sh                             # full repository verification
```

API, worker and frontend commands are added with M1.

## Testing strategy

- Unit tests (pytest) for timebase, layout geometry, operations/validation, sync estimation, caption mapping.
- Media integration tests (marker `media`) render real outputs from synthetic fixtures and validate decoded
  frames and audio against oracles computed from the fixture manifest and spec math, never from the compiler.
- Browser end-to-end tests (Playwright) for the user journeys once the UI exists.
- Contract tests for AI adapters against local fake servers; live tests only with configured credentials,
  reported separately.

In effect:

1. Every acceptance criterion has at least one automated test, or a documented verification
   when automation is impractical.
2. Tests carry `AVE-REQ-NNN AC-n` (and scenario tags `AT-NN`) in their name or docstring, so
   `git grep -n -w --untracked "AVE-REQ-NNN"` finds them; see [TRACEABILITY.md](TRACEABILITY.md).
3. Tests are deterministic and run non-interactively. Fix flaky tests at the root; never
   skip them to get green.
4. `./scripts/verify.sh` runs every test level; core user journeys run as end-to-end or smoke
   tests.
5. `./scripts/verify.sh` never needs credentials or paid services. External services run on
   their fakes; live-service checks run through a separate command documented here.

Commands: `cd backend && uv run pytest -m "not media"` (fast), `uv run pytest -m media` (media integration),
`uv run pytest tests/path::name` (one test), `uv run pytest -k "AVE-REQ-024"` (one requirement where test names
carry the tag).

## Verification pipeline

In effect since bootstrap
([ADR-001](decisions/ADR-001-specification-driven-development-workflow.md)).

1. **Single entry point.** [scripts/verify.sh](../scripts/verify.sh) is the one command
   humans, Claude, the Stop hook and CI run. It runs every step, prints a summary, and exits
   non-zero when any step fails.
2. **Current steps.** "Project control files" runs
   [scripts/check-project-control.sh](../scripts/check-project-control.sh), which enforces
   document invariants (required files, agent and skill frontmatter, relative links,
   PROGRESS.md headings, requirement and ADR formats, traceability consistency). The final
   step, "Working tree unchanged by verification", fails when any step changed the working
   tree outside .gitignore-d paths, which would otherwise invalidate the Stop-gate cache.
   Product tiers (fast, media, release) are added during M0 integration.
3. **Target step order** once the stack exists: formatting check (read-only), lint, static
   analysis and security scan, type checking, unit tests, integration tests, build,
   end-to-end/smoke tests of core user journeys, other stack-specific validation.
4. **Stop gate.** [.claude/hooks/stop-verify.sh](../.claude/hooks/stop-verify.sh) runs
   verify.sh when Claude finishes a turn and the working tree differs from the last passing
   tree. A failure blocks stopping and feeds the log tail back to Claude; after
   `CLAUDE_VERIFY_MAX_ATTEMPTS` (default 3) consecutive failures the gate releases with a
   warning. `CLAUDE_VERIFY_GATE=off` disables it for humans. Results and the full log live in
   `.git/claude-verify/` (one per worktree).
5. **Session start.** [.claude/hooks/session-start.sh](../.claude/hooks/session-start.sh)
   reports the last verification result and whether it matches the current tree. Both hooks
   activate after workspace trust ([ASM-001](ASSUMPTIONS.md)) and are thin adapters over
   [scripts/lib/verify-state.sh](../scripts/lib/verify-state.sh), which holds the working-tree
   fingerprint and the state records; verify.sh uses the same fingerprint.
6. **CI.** [.github/workflows/verify.yml](../.github/workflows/verify.yml) runs
   `./scripts/verify.sh` on push, pull request and manual dispatch.
7. **Rules.** verify.sh stays non-interactive, deterministic, read-only toward the working tree
   (outputs go to gitignored paths) and identical locally and in CI. Add commands only for
   selected technologies, each as a `run_step`. Never weaken, skip or suppress a check to get
   green; fix the root cause.

## Risks and technical debt

- **No live AI, GPU, Hugging Face or multilingual ASR in the development environment** — provider, agent-runtime,
  vision, translation and GPU criteria stay externally unverified until a configured host runs them; tracked in the
  release capability matrix (AVE-REQ-099).
- **Stop-gate cost grows with media tests** — verify.sh tiers keep the default run fast; heavy media and release
  tiers run in CI and at milestone gates (mitigation planned in M0 integration).
- **Concat-copy assembly** depends on identical segment encoder settings; validated per export, with a
  lossless-intermediate fallback if a codec misbehaves (ADR-005).
