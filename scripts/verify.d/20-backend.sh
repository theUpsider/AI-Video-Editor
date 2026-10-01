# scripts/verify.d/20-backend.sh — sourced by scripts/verify.sh.
# Backend (Python package `ave`, uv-managed): read-only format check, lint, type check, unit tests
# (fast tier); real-media integration tests with decoded-output oracles (media tier).
# `--frozen` keeps uv from rewriting uv.lock; the environment lives in the gitignored backend/.venv.
# shellcheck shell=bash

backend_uv() { uv run --frozen --quiet --directory backend "$@"; }

fast_step "Backend format check" backend_uv ruff format --check .
fast_step "Backend lint" backend_uv ruff check .
fast_step "Backend type check" backend_uv mypy
fast_step "Backend unit tests" backend_uv pytest -q -m "not media" -p no:cacheprovider
media_step "Backend media integration tests" backend_uv pytest -q -m media -p no:cacheprovider
