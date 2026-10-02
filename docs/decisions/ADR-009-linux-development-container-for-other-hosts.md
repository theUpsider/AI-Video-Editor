# ADR-009 — Verify on Windows and macOS hosts inside a Linux development container

## Status
Accepted — 2026-10-02

## Context
Development moved from a Linux cloud container to a Windows 11 ARM64 laptop
([ENVIRONMENT_CAPABILITIES.md](../ENVIRONMENT_CAPABILITIES.md)). Measured on that host with Git Bash: no
`python3`, no FFmpeg, files checked out with CRLF by the system Git configuration, and the fast tier of
`./scripts/verify.sh` failed 5 of 9 steps (three steps found no `python3`; the backend unit tests failed because
the media model validates POSIX absolute paths). The product targets a self-hosted Linux service
([ADR-002](ADR-002-technology-stack.md), AVE-REQ-082); CI verifies on Ubuntu 24.04 with FFmpeg 6.1. The gates of
AVE-REQ-097 require one verification entry point with identical behavior for humans, the coding agent, the Stop
hook and CI, and parallel agents work in Git worktrees under `.claude/worktrees/` (AVE-REQ-096).

## Decision
- Linux stays the only supported runtime and verification platform for version one.
- `.devcontainer/Dockerfile` defines one development image with what CI installs: Ubuntu 24.04, FFmpeg 6.1 and
  the awk implementations from the Ubuntu archive, uv 0.8.17, Python 3.11, plus Git 2.48 or newer from the Git
  maintainers' PPA.
- `scripts/dev-container.sh <command>` builds the image, keeps one container per checkout running, mounts the
  main checkout at `/workspace` and runs the command in the directory that corresponds to the caller's. Each
  worktree gets its own backend environment on a named state volume beside the shared uv cache.
- On a Windows host (`uname -s` reports MINGW, MSYS or CYGWIN) `./scripts/verify.sh` re-executes itself through
  that script, so the Stop gate and every agent run the same tiers there. On Linux and in CI nothing changes.
- A checkout used with the container sets, in its local Git configuration, `core.autocrlf false`,
  `core.eol lf` (LF working files) and `worktree.useRelativePaths true` (worktree links that resolve on the host
  and inside the container).

## Alternatives considered
- Native Windows support — rejected: it adds a second platform to the product and its tests (path semantics,
  process handling, FFmpeg builds) that no requirement asks for.
- A WSL distribution holding its own clone — rejected: the coding session, its file tools and its worktrees
  operate on the Windows checkout, so two copies of every change would need synchronizing.
- Verifying only through CI — rejected: a five-minute round trip per check, and no local media runs for
  synchronization and render work.
- A shared backend environment for all worktrees — rejected: the editable `ave` install points at one source
  tree, so concurrent worktrees would test each other's code.

## Consequences
- A Windows or macOS contributor needs Docker and Git 2.48 or newer; the first run downloads about 1.3 GB.
- The image mirrors CI by construction of its package list; a toolchain change updates the CI workflow and the
  Dockerfile together.
- The bind mount is slower than a native file system for file-heavy steps; tests write their media to the
  container's own `/tmp`.
- One container serves every agent of a checkout: heavy media jobs share its CPUs and can share a lock file.
- A command interrupted on the host can leave its process running in the container; `scripts/dev-container.sh
  --stop` removes the container.
- Revisit when a requirement asks for a native Windows or macOS runtime, or when the container image and CI
  drift.

## Related requirements
- [AVE-REQ-094 — Capability-aware native dynamic workflows](../requirements/AVE-REQ-094-capability-aware-native-dynamic-workflows.md)
- [AVE-REQ-096 — Isolated bounded tasks and independent review](../requirements/AVE-REQ-096-isolated-bounded-tasks-and-independent-review.md)
- [AVE-REQ-097 — Verification gates that cannot pass as placeholders](../requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)
