# scripts/verify.d/20-backend.sh — sourced by scripts/verify.sh.
# Backend (Python package `ave`, uv-managed): read-only format check, lint, type check, unit tests
# (fast tier); real-media integration tests with decoded-output oracles and seeded population tests
# (media tier).
# `--frozen` keeps uv from rewriting uv.lock; the environment lives in the gitignored backend/.venv.
# Every pytest run takes its configuration from backend/pyproject.toml alone (`-c`: no pytest.ini, no
# option from the environment; verify.sh clears PYTEST_ADDOPTS and loads no plugin by itself), forbids
# skips and writes its per-test evidence report into the run's evidence directory
# (backend/tests/evidence_plugin.py); the step fails when the session left no report with executed
# tests (`evidence.py check-report`). Plugin options take the `--option=value` form: pytest reads the
# command line before it loads the plugin, and a separate value would be taken for a test path.
# The type checker reads no cache from the tree (`--cache-dir` inside the run's scratch directory).
# shellcheck shell=bash

backend_uv() { uv run --frozen --quiet --directory backend "$@"; }

# backend_pytest <report name> <pytest arguments…>
backend_pytest() {
  local report="$AVE_EVIDENCE_DIR/pytest-$1.json"
  shift
  backend_uv pytest -c pyproject.toml -q -p no:cacheprovider --forbid-skips \
    --evidence-report="$report" "$@" &&
    python3 -B scripts/evidence.py check-report --file "$report"
}

fast_step "Backend format check" backend_uv ruff format --check .
fast_step "Backend lint" backend_uv ruff check .
fast_step "Backend type check" backend_uv mypy --cache-dir="$AVE_RUN_SCRATCH/mypy-cache"
# The fast tier renders nothing (AVE-REQ-097 AC-3): its tests see media tools that refuse to run,
# so a test that calls FFmpeg without the `media` marker fails here.
fast_pytest() {
  AVE_FFMPEG="$PWD/scripts/lib/media-tier-only.sh" AVE_FFPROBE="$PWD/scripts/lib/media-tier-only.sh" \
    backend_pytest unit -m "not media and not slow"
}

fast_step "Backend unit tests" fast_pytest
media_step "Backend media and population tests" backend_pytest media -m "media or slow"
