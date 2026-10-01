# scripts/verify.d/90-tooling.sh — sourced by scripts/verify.sh.
# Regression suites of the verification tooling itself (checker on every installed awk, baseline
# checker, Stop and SessionStart hooks): the gates are tested, not only the product (AVE-REQ-097).
# shellcheck shell=bash

release_step "Verification tooling regression suites" scripts/tests/run.sh --all-awks
