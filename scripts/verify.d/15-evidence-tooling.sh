# scripts/verify.d/15-evidence-tooling.sh — sourced by scripts/verify.sh.
# Unit tests of the evidence tooling (scripts/tests/test_*.py): Python standard library, fast tier.
# `evidence.py unittest` fails the step when a test fails, is skipped, is expected to fail or passes
# unexpectedly, and writes one suite result per file into the run's evidence directory: the file's
# tags count only through that result (AVE-REQ-097).
# shellcheck shell=bash

fast_step "Evidence tooling unit tests" python3 -B scripts/evidence.py unittest \
  --dir "$AVE_EVIDENCE_DIR" scripts/tests
