# ADR-007 — Separate provider, agent-runtime, analysis and MCP integrations behind the command service

## Status
Accepted — 2026-10-01

## Context
The user asked for OpenAI-compatible endpoints, Claude Code and Codex as selectable backends, Hugging Face
analysis models and a standardized AI interface (U08, U25, U26). The baseline separates direct LLM providers,
agent runtimes, analysis adapters and external MCP clients ([EDITING_API.md](../../ai-video-editor-requirements/spec/EDITING_API.md),
baseline ASM-14/15). This environment has no application credentials and blocks Hugging Face downloads.

## Decision
1. All AI paths mutate projects only through the typed command service (dry-run, expected revision,
   idempotency key, scope, locks, undo).
2. **Direct providers:** Anthropic Messages and OpenAI-compatible chat adapters over HTTPS with structured
   outputs, usage accounting, budgets, retries, timeouts and cancellation.
3. **Agent runtimes:** Claude Agent SDK and Codex SDK/app-server adapters run in a constrained working directory
   with only the editor's operations exposed; they use their own documented authentication, never the developer's
   coding-session login.
4. **External MCP clients** connect to the editor's MCP server (stdio locally, authenticated Streamable HTTP
   remotely) with project/operation scopes.
5. **Analysis adapters** (ASR, translation, vision, model registry) report capabilities; Hugging Face models are
   pinned by revision with license and resource display, no remote code by default.
6. Every adapter returns `PROVIDER_UNAVAILABLE` or `UNSUPPORTED_CAPABILITY` when its dependency is missing; no
   adapter fabricates success. Contract tests use local fake servers; live tests run only with configured
   credentials and are reported separately.

## Alternatives considered
- One generic "AI backend" abstraction for providers and agent runtimes — rejected: different auth, tool and
  isolation semantics.
- Letting a model emit renderer filtergraphs or shell commands — rejected: unsafe and untestable.

## Consequences
- The capability matrix in the handover lists each integration as implemented / contract-tested / live-tested.
- Without credentials the editor stays fully usable manually, with a rule-based assembly and honest AI status.

## Related requirements
- [AVE-REQ-049 — MCP editing interface and external agent clients](../requirements/AVE-REQ-049-mcp-editing-interface-and-external-agent-clients.md)
- [AVE-REQ-050 — Provider-neutral language-model adapters](../requirements/AVE-REQ-050-provider-neutral-language-model-adapters.md)
- [AVE-REQ-051 — Claude Agent runtime adapter](../requirements/AVE-REQ-051-claude-agent-runtime-adapter.md)
- [AVE-REQ-052 — Codex runtime adapter](../requirements/AVE-REQ-052-codex-runtime-adapter.md)
- [AVE-REQ-056 — Tool authorization and credential boundaries](../requirements/AVE-REQ-056-tool-authorization-and-credential-boundaries.md)
