# scripts/verify.d/95-evidence.sh — sourced by scripts/verify.sh.
# Release tier: every requirement with status `done` has, for each acceptance criterion, a passing
# non-contract test in this run or a recorded inspection (scripts/evidence.py check-done). Runs after
# every test step, so the evidence is this run's, never an older one.
# shellcheck shell=bash

release_step "Done requirements evidenced by this run" \
  python3 -B scripts/evidence.py check-done --dir "$AVE_EVIDENCE_DIR"
