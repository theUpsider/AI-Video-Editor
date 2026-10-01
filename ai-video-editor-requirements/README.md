# AI Video Editor - requirements and implementation package

**Version:** 1.0 | **Prepared:** 2026-10-02 | **Purpose:** input to an already-bootstrapped Claude Code repository.

This package specifies the requested product. It is **not an implemented editor** and does not certify any application, model integration, or GPU path as tested.

## Start here

1. Extract this archive into the repository root. It creates the separate `ai-video-editor-requirements/` directory and does not overwrite `CLAUDE.md`, `.claude/`, application code, or existing project documentation.
2. Give the implementing agent `IMPLEMENTATION_PROMPT.md`, or paste the short launcher in that file's final section. The agent must adopt the package, plan the work, **and begin implementing**, not stop after producing another specification.
3. Keep this input directory as the original baseline. Maintain working requirements and implementation evidence in the repository's existing `docs/` structure, using the same stable AVE-REQ IDs and an explicit import mapping.

If file upload is not available in the coding interface, add the extracted directory to the repository/branch that the agent can read. A conversation attachment is useful only when that environment actually exposes its files.

## What is inside

| File or directory | Purpose |
| --- | --- |
| `IMPLEMENTATION_PROMPT.md` | Complete execution instruction for Claude Code. |
| `RESUME_PROMPT.md` | Recovery instruction for a new or interrupted session. |
| `intake/USER_BRIEF.md` | Meaning-preserving user brief and source-clause IDs. |
| `spec/PRODUCT.md` | Product experience, boundaries, success criteria, and defaults. |
| `spec/REQUIREMENTS_INDEX.md` | Navigable index of 101 requirements. |
| `spec/requirements/` | One Markdown file per requirement; 99 version-one and 2 future requirements. |
| `spec/requirements.json` | The same 101 requirements as structured data, with 404 acceptance criteria. |
| `spec/TRACEABILITY.md` | User-clause coverage and requirement-to-scenario mapping. |
| `spec/SCOPE_AND_ASSUMPTIONS.md` | Resolved ambiguities, honest limitations, and exclusions. |
| `spec/TECHNICAL_DEFAULTS.md` | Recommended implementation defaults, changeable by justified ADR. |
| `spec/DATA_AND_TIMING_MODEL.md` | Temporal invariants, synchronization sign conventions, revisions, and entities. |
| `spec/EDITING_API.md` | Provider-neutral operations and safe AI transactions. |
| `spec/ACCEPTANCE_TESTS.md` | 31 real-output scenario specifications and fixture expectations. |
| `spec/ROADMAP.md` | Risk-first vertical slices and release gates. |
| `spec/AGENT_WORKFLOW.md` | Native dynamic workflows, bounded fallback, and controlled self-improvement. |
| `spec/THREAT_MODEL.md` | Security and trust boundaries. |
| `spec/DELIVERY_CHECKLIST.md` | Completion evidence and conditional integration reporting. |
| `spec/SOURCES.md` | Dated primary documentation supporting technical choices. |
| `workflow/ai-video-editor-delivery/` | Optional compact delivery skill, to merge with existing skills rather than overwrite them. |
| `workflow/skill.zip` | Portable copy of that one skill. |
| `tools/validate_package.py` | Standard-library validator for package consistency, not the application. |
| `PACKAGE_VALIDATION.md` | Results of package checks and their limits. |
| `MANIFEST.json` | File inventory and SHA-256 integrity hashes. |

## Authority and scope

The user's explicit requested behavior and exclusions are authoritative. Requirement acceptance criteria define completion. Technical defaults and deployment assumptions can change through an ADR if the alternative preserves the requested behavior, safety, and testability. They are not permission to reduce scope.

`ready` in this input package means specified enough for planning, **not implemented**, and not necessarily unblocked by dependencies. The dependency graph is acyclic. Milestone labels identify a primary completion gate; prerequisite subsets may be built earlier.

Object/motion tracking and advanced continuous video understanding are the two explicitly deferred requirements. Bounded keyframes, source transcripts, optional frame captioning, initial AI drafting, subtitles, synchronization, shorts, profiles, manual editing, and real exports belong to version one.

## Validate the package

From this directory, run:

```bash
python3 tools/validate_package.py
```

This verifies IDs, links, criteria, scope, dependencies, coverage, and hashes. It does not run or validate a media editor. No user videos, credentials, models, or font files are included.
