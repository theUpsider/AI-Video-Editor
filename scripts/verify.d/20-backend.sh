# scripts/verify.d/20-backend.sh — sourced by scripts/verify.sh.
# Backend (Python package `ave`, uv-managed): read-only format check, lint, type check, unit tests
# (fast tier); real-media integration tests with decoded-output oracles and seeded population tests
# (media tier).
# `--frozen` keeps uv from rewriting uv.lock; the environment lives in the gitignored backend/.venv, or
# where UV_PROJECT_ENVIRONMENT names it. `--no-env-file`: uv adds no variable from a file to the
# process it starts (UV_ENV_FILE of the caller is outside the named set of verify.sh as well).
# Every pytest run takes its configuration from backend/pyproject.toml alone (`-c`: no pytest.ini, no
# option from the environment; verify.sh clears PYTEST_ADDOPTS and loads no plugin by itself), forbids
# skips and writes its per-test evidence report into the run's evidence directory
# (backend/tests/evidence_plugin.py); the step fails when the session left no report with executed
# tests (`evidence.py check-report`). Plugin options take the `--option=value` form: pytest reads the
# command line before it loads the plugin, and a separate value would be taken for a test path.
# Each tool takes its configuration from backend/pyproject.toml by name (ruff `--config`, mypy
# `--config-file`, pytest `-c`), so a file that the tool would find ahead of it takes no part: a
# ruff.toml or .ruff.toml beside it, a ruff.toml or pyproject.toml in a directory below, a mypy.ini
# or .mypy.ini, a pytest.ini or .pytest.ini. uv finds a backend/uv.toml and a
# backend/.python-version ahead of pyproject.toml: each is a file of the tree, which the fingerprint
# names or the step "No file outside the fingerprint and the listed paths" fails.
# ruff reads no ignore file (`--no-respect-gitignore`): with one it passes over a tracked file that a
# rule of .git/info/exclude or of an .ignore file, in the tree or above it, names. Its built-in
# exclusions stay: .venv and the cache directories, and a directory named dist, venv, node_modules,
# _build or site-packages.
# No tool reads or writes a cache in the tree: ruff starts with `--no-cache`, mypy with `--cache-dir`
# inside the run's scratch directory, pytest with `-p no:cacheprovider`.
# (Measured with the tools of uv.lock on 2026-10-07; scripts/tests/test-verify-tiers.sh starts the
# real ruff and mypy with these options beside such files.)
# shellcheck shell=bash

backend_uv() { uv run --frozen --quiet --no-env-file --directory backend "$@"; }

# backend_pytest <report name> <pytest arguments…>
backend_pytest() {
  local report="$AVE_EVIDENCE_DIR/pytest-$1.json"
  shift
  backend_uv pytest -c pyproject.toml -q -p no:cacheprovider --forbid-skips \
    --evidence-report="$report" "$@" &&
    python3 -B scripts/evidence.py check-report --file "$report"
}

fast_step "Backend format check" backend_uv ruff format --check --config pyproject.toml \
  --no-respect-gitignore --no-cache .
fast_step "Backend lint" backend_uv ruff check --config pyproject.toml --no-respect-gitignore --no-cache .
fast_step "Backend type check" backend_uv mypy --config-file pyproject.toml \
  --cache-dir="$AVE_RUN_SCRATCH/mypy-cache"
# The fast tier renders nothing (AVE-REQ-097 AC-3): its tests see media tools that refuse to run,
# through the two variables that ave.proc reads and through PATH, where a directory with `ffmpeg`
# and `ffprobe` stand-ins, built in the run's scratch directory, comes first. So a test that calls
# FFmpeg or FFprobe by name without the `media` marker fails here. Two forms reach the real tool:
# a test that names a media tool by an absolute path, and a test that starts a process with a PATH
# of its own. The review of the test judges both.
# The function body is a subshell: the three variables end with this step.
fast_pytest() (
  stub="$PWD/scripts/lib/media-tier-only.sh"
  tools="$AVE_RUN_SCRATCH/media-tier-only"
  mkdir -p "$tools" && cp "$stub" "$tools/ffmpeg" && cp "$stub" "$tools/ffprobe" &&
    chmod +x "$tools/ffmpeg" "$tools/ffprobe" || exit 1
  export PATH="$tools:$PATH" AVE_FFMPEG="$stub" AVE_FFPROBE="$stub"
  backend_pytest unit -m "not media and not slow"
)

fast_step "Backend unit tests" fast_pytest
media_step "Backend media and population tests" backend_pytest media -m "media or slow"
