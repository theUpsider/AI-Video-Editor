# scripts/verify.d/95-evidence.sh — sourced by scripts/verify.sh.
# Every tier: no requirement with status `done` has a criterion with failed, contract-only or missing
# evidence in this run; the release tier, which runs every test, also fails on a tagged test that did
# not run, so there each criterion has a passing non-contract test or a recorded inspection
# (scripts/evidence.py check-done). Runs after every test step, so the evidence is this run's, never
# an older one.
# shellcheck shell=bash

fast_step "Done requirements evidenced by this run" \
  python3 -B scripts/evidence.py check-done --dir "$AVE_EVIDENCE_DIR" --tier "$TIER"
