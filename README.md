# AI Video Editor (working title)

_Working title taken from the repository name and unconfirmed; the product definition sets the real name._

**Status:** bootstrapped for autonomous, specification-driven development. No product is defined yet; the repository awaits the product prompt.

## How it is developed

Claude Code develops this repository autonomously. You provide product goals and important constraints. Claude expands them into a product specification, requirements with acceptance criteria, an architecture and a roadmap, then implements one requirement at a time, verifies each with `./scripts/verify.sh` and an independent review, and records evidence and traceability in the repository. All durable state lives in versioned Markdown, so every new session resumes from the repository alone. Claude asks you only about irreversible decisions, choices that change the product, credentials or access, information it cannot know, and significant destructive risk.

## How to drive it

1. Start Claude Code in the repository and describe the product goals and must-have features (or run `/product-definition <goals>`).
2. `/develop` continues the implementation loop.
3. `/resume-project` re-anchors Claude after a break, compaction or new session (the SessionStart hook prompts it automatically).
4. `/milestone-review` checks a finished milestone against the product definition.

## Where things live

| Path | Contents |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Rules every Claude session follows |
| [docs/PRODUCT.md](docs/PRODUCT.md) | Product definition |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Architecture and stack |
| [docs/ROADMAP.md](docs/ROADMAP.md), [docs/PROGRESS.md](docs/PROGRESS.md) | Plan and current state |
| [docs/requirements/](docs/requirements/README.md) | Epics, features, requirements |
| [docs/decisions/](docs/decisions/README.md) | Architecture decision records |
| [docs/TRACEABILITY.md](docs/TRACEABILITY.md), [docs/ASSUMPTIONS.md](docs/ASSUMPTIONS.md) | Requirement → code → test → evidence; recorded assumptions |
| `.claude/agents/`, `.claude/skills/`, `.claude/hooks/` | Subagents, workflow skills, hooks ([settings](.claude/settings.json)) |
| [scripts/verify.sh](scripts/verify.sh) | Verification entry point |
| [scripts/dev-container.sh](scripts/dev-container.sh) | Runs a command in the Linux development container (Windows and macOS hosts) |

## Verification

```sh
./scripts/verify.sh
```

Runs every repository check; today these are the project-control checks and a check that verification leaves the working tree unchanged; stack checks arrive with the technical foundation. CI runs the same script.

## Hooks

The hooks in `.claude/settings.json` activate once you trust the workspace in Claude Code:
- **SessionStart** injects the current project state and points Claude to `resume-project`.
- **Stop** runs `./scripts/verify.sh` when files changed and keeps Claude repairing until it passes; after 3 consecutive failed runs it releases with a warning.

To disable the Stop gate for a session, launch with `CLAUDE_VERIFY_GATE=off claude`.
