# ADR-002 — Use Python/FastAPI, SQLite, FFmpeg and React/TypeScript as the version-one stack

## Status
Accepted — 2026-10-01

## Context
The repository held no application stack. The baseline recommends a self-hostable browser editor with a typed
backend/domain service, a durable worker, immutable media storage, CPU FFmpeg rendering, local speech analysis
and provider-neutral AI adapters ([TECHNICAL_DEFAULTS.md](../../ai-video-editor-requirements/spec/TECHNICAL_DEFAULTS.md)).
The measured environment ([ENVIRONMENT_CAPABILITIES.md](../ENVIRONMENT_CAPABILITIES.md)) offers Python 3.11,
uv, Node.js 22, pnpm, FFmpeg 6.1.1 with the needed encoders/filters, Playwright Chromium, PyPI and npm access,
no GPU, no Docker daemon and no Hugging Face access. Drivers: exact timing (AVE-REQ-012), real renders
(AVE-REQ-072/075), local operation (AVE-REQ-082/091), one typed command service (AVE-REQ-048), MCP (AVE-REQ-049).

## Decision
- **Backend:** Python 3.11 package `ave` under `backend/` (src layout), managed and locked by `uv`.
  FastAPI + Pydantic v2 for the HTTP API and typed schemas; NumPy/SciPy for signal analysis; `fractions.Fraction`
  for exact time. Quality tooling: pytest, ruff (lint + format), mypy.
- **Persistence:** SQLite in WAL mode on local disk, accessed through the standard `sqlite3` module with
  versioned SQL migrations and short transactions.
- **Worker:** a separate Python process consuming durable job records (ADR-006).
- **Media:** FFprobe/FFmpeg 6.1 invoked with argv lists only; a typed render compiler (ADR-005).
- **Frontend:** React + TypeScript + Vite under `frontend/`, pnpm-managed and locked; a small explicit store
  (Zustand) for selection and optimistic interaction only; Playwright for browser end-to-end tests.
- **MCP:** the official `mcp` Python SDK in the backend (stdio + authenticated Streamable HTTP).
- **Runtime layout:** application data under a configurable data root (default `./var/data`): originals
  (content-addressed, read-only), derived files, exports, temporary files, model cache, database.

## Alternatives considered
- Node.js/TypeScript backend — rejected: weaker numerical/audio-analysis ecosystem and the ASR/model
  ecosystem is Python-first.
- SQLAlchemy/ORM — rejected for now: the domain stores versioned composition documents; plain SQL with
  migrations is smaller and transparent.
- Redis/Celery or another queue service — rejected: no measured need; durable DB records with atomic claims
  satisfy AVE-REQ-077 on one host (baseline guidance).
- Desktop packaging (Electron/Tauri) — rejected for version one: the baseline default is a browser editor with
  a local service; an ADR can revisit it.

## Consequences
- One language for domain, rendering, analysis, AI adapters and MCP; the browser is a client of the same API.
- `./scripts/verify.sh` gains Python and frontend tiers; CI installs uv, Node/pnpm and FFmpeg.
- Python 3.11 is pinned to the measured interpreter; upgrading is a deliberate change.
- Revisit when distribution beyond one host, a desktop shell or a different database becomes a requirement.

## Related requirements
- [AVE-REQ-048 — One typed editing command service](../requirements/AVE-REQ-048-one-typed-editing-command-service.md)
- [AVE-REQ-077 — Durable asynchronous jobs](../requirements/AVE-REQ-077-durable-asynchronous-jobs.md)
- [AVE-REQ-082 — Self-hostable browser application and CPU reference setup](../requirements/AVE-REQ-082-self-hostable-browser-application-and-cpu-reference-setup.md)
- [AVE-REQ-088 — Pinned dependencies and license inventory](../requirements/AVE-REQ-088-pinned-dependencies-and-license-inventory.md)
