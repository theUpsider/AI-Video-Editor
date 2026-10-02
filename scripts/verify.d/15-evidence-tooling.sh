# scripts/verify.d/15-evidence-tooling.sh — sourced by scripts/verify.sh.
# Unit tests of the evidence tooling (scripts/evidence.py): Python standard library, fast tier.
# shellcheck shell=bash

fast_step "Evidence tooling unit tests" python3 -B -m unittest discover -s scripts/tests -p 'test_*.py'
