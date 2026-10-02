# scripts/verify.d/10-requirements.sh — sourced by scripts/verify.sh.
# Requirements baseline integrity (AVE-REQ-093, AVE-REQ-097): MANIFEST.json equals the hash pinned in
# scripts/check_baseline.py, the immutable package validates against its MANIFEST.json hashes, and every
# working requirement still carries the baseline's statement and acceptance criteria.
# shellcheck shell=bash

fast_step "Requirements baseline integrity" python3 -B scripts/check_baseline.py
