#!/usr/bin/env bash
# scripts/dev-container.sh — runs a command inside the Linux development container.
#
# Usage:  ./scripts/dev-container.sh <command> [args...]
#         ./scripts/dev-container.sh --status        prints the image, the container and its state
#         ./scripts/dev-container.sh --stop          stops and removes the container (volume kept)
# Example: ./scripts/dev-container.sh uv run --frozen --directory backend pytest -q tests/unit
#
# Hosts without the Linux toolchain (Windows with Git Bash, macOS) verify and test inside one
# container built from .devcontainer/Dockerfile, which installs what CI installs. On a Windows
# host ./scripts/verify.sh re-executes itself through this script; every other command (pytest,
# scripts/evidence.py, scripts/probe-environment.sh, the tooling suites) is passed explicitly.
#
# Layout: the main checkout is mounted at /workspace, so every worktree under .claude/worktrees/
# is visible, and the command runs in the directory that corresponds to the caller's. Each
# worktree gets its own backend environment (UV_PROJECT_ENVIRONMENT) on the state volume, beside
# the shared uv cache. One container serves every agent of a checkout; a private clone (a
# reviewer's copy with its own .git directory) gets its own container. The state volume is
# shared by all of them, and so is the heavy-media lock file on it (AVE_HEAVY_LOCK), which keeps
# one media or release tier running at a time across every checkout of the host. The container
# name carries a checksum of the Dockerfile and the checkout path: a changed Dockerfile gets a
# new image and container.
# Requires: a reachable Docker daemon; worktrees created with relative links
# (`git config worktree.useRelativePaths true`), which Git inside the container resolves.
# Exit:   the command's exit status · 2 usage error · 3 container unavailable

set -uo pipefail

IMAGE_NAME="ave-dev"
STATE_VOLUME="ave-dev-state"

die() {
  printf 'dev-container.sh: %s\n' "$1" >&2
  exit "${2:-3}"
}

# Prints directory $1 as the Docker daemon addresses it (the Windows form under Git Bash).
daemon_path() {
  (cd "$1" 2>/dev/null && { pwd -W 2>/dev/null || pwd -P; })
}

# Docker arguments are container paths: keep Git Bash from rewriting them as Windows paths.
docker_cli() {
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' docker "$@"
}

container_running() {
  [ "$(docker_cli inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]
}

# Builds the image when absent and starts the container when it is not running. Concurrent
# callers are safe: a lost creation race ends at the container the other caller started.
ensure_container() {
  docker_cli info >/dev/null 2>&1 || die "the Docker daemon is unreachable: start Docker and retry"
  if ! docker_cli image inspect "$IMAGE" >/dev/null 2>&1; then
    printf 'dev-container.sh: building %s from .devcontainer/Dockerfile\n' "$IMAGE" >&2
    docker_cli build -q -t "$IMAGE" "$(daemon_path "$TOP/.devcontainer")" >&2 ||
      die "the image build failed"
  fi
  container_running "$CONTAINER" && return 0
  docker_cli start "$CONTAINER" >/dev/null 2>&1 ||
    docker_cli run -d --init --name "$CONTAINER" \
      -v "$(daemon_path "$MAIN_ROOT"):/workspace" -v "$STATE_VOLUME:/state" \
      "$IMAGE" sleep infinity >/dev/null 2>&1 ||
    docker_cli start "$CONTAINER" >/dev/null 2>&1
  container_running "$CONTAINER" || die "the container $CONTAINER did not start"
}

[ "$#" -ge 1 ] || die "usage: ./scripts/dev-container.sh <command> [args...] | --status | --stop" 2
command -v docker >/dev/null 2>&1 || die "docker is not installed"

HERE="$(pwd -P)"
GIT_COMMON="$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P)" ||
  die "run it inside the repository" 2
MAIN_ROOT="$(dirname "$GIT_COMMON")"
TOP="$(cd "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null && pwd -P)" ||
  die "run it inside a work tree" 2
case "$HERE" in
  "$MAIN_ROOT" | "$MAIN_ROOT"/*) ;;
  *) die "$HERE lies outside the main checkout $MAIN_ROOT (worktrees belong under .claude/worktrees/)" 2 ;;
esac
[ -f "$TOP/.devcontainer/Dockerfile" ] || die "$TOP/.devcontainer/Dockerfile is missing" 2

TAG="$(cksum <"$TOP/.devcontainer/Dockerfile" | cut -d ' ' -f 1)"
IMAGE="$IMAGE_NAME:$TAG"
CONTAINER="$IMAGE_NAME-$TAG-$(printf '%s' "$MAIN_ROOT" | cksum | cut -d ' ' -f 1)"
TREE="${TOP#"$MAIN_ROOT"}"
VENV="/state/venvs/$(printf '%s' "$MAIN_ROOT$TREE" | cksum | cut -d ' ' -f 1)"

case "$1" in
  --status)
    STATE="$(docker_cli inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)" || STATE="absent"
    printf 'image      %s\ncontainer  %s\nstate      %s\n' "$IMAGE" "$CONTAINER" "$STATE"
    exit 0
    ;;
  --stop)
    docker_cli rm -f "$CONTAINER" >/dev/null 2>&1
    exit 0
    ;;
  -*) die "unknown option: $1" 2 ;;
esac

ensure_container
ENV_ARGS=(-e "UV_PROJECT_ENVIRONMENT=$VENV" -e "AVE_HEAVY_LOCK=/state/ave-heavy-media.lock")
[ -n "${VERIFY_TIER:-}" ] && ENV_ARGS+=(-e "VERIFY_TIER=$VERIFY_TIER")
docker_cli exec -i "${ENV_ARGS[@]}" -w "/workspace${HERE#"$MAIN_ROOT"}" "$CONTAINER" "$@"
