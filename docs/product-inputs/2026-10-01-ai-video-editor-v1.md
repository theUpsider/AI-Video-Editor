# Product input — 2026-10-01 — AI Video Editor version one

- **Received:** 2026-10-01 — session message with the attached package `ai-video-editor-requirements.zip`
- **Mode:** initial

The attached package is committed unchanged as the immutable baseline in
[ai-video-editor-requirements/](../../ai-video-editor-requirements/README.md) (commit `6160278`). Its
`intake/USER_BRIEF.md` holds the meaning-preserving user brief (clauses U01–U27, D01–D05) and its
`IMPLEMENTATION_PROMPT.md` the full operating instruction.

## Verbatim input

```text
The bootstrap is complete. Implement the AI Video Editor specified in the
extracted `ai-video-editor-requirements/` directory.

Read and follow
`ai-video-editor-requirements/IMPLEMENTATION_PROMPT.md`.

Treat its product requirements and acceptance criteria as the implementation
contract, while preserving the repository's existing instructions and useful
setup.

This is an implementation request, not a request to produce another plan.
Integrate the specification into the existing project documents, audit the
real cloud capabilities, then start the first real CPU-rendering and
synchronization slice and continue through the full version-one roadmap.

Use Claude Code's native dynamic workflows where they are actually available
and useful, with bounded isolated implementation tasks and independent
verification. Otherwise use the same lifecycle through subagents or
sequential work.

Improve repository-local workflows only through measured, reviewed changes.
Never weaken requirements, tests, security gates, or completion criteria.

Keep all 99 version-one requirements in scope. The two future requirements
remain deferred.

Preserve original media and make AI edits transactional, scoped,
revision-safe, and undoable. Validate actual rendered video and audio,
not only UI state or mocked jobs.

Do not invent available GPUs, credentials, model entitlements, or successful
integrations. Document genuine external verification gaps, continue
independent work, and leave an exact resumable state if the session reaches
a real limit.

Begin implementation now.
```
