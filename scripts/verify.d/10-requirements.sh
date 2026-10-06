# scripts/verify.d/10-requirements.sh — sourced by scripts/verify.sh.
# Requirements baseline integrity (AVE-REQ-093, AVE-REQ-097): MANIFEST.json equals the hash pinned in
# scripts/check_baseline.py, the checker verifies the manifest's inventory and every file hash itself before the
# package's own validator runs, every working file is in canonical form (scripts/reqfile.py), every working
# requirement still carries the baseline's statement and acceptance criteria, and the roadmap schedules every
# version-one requirement. -I: Python's isolated mode, so no module path, bytecode cache or Python variable of
# the environment takes part.
# shellcheck shell=bash

fast_step "Requirements baseline integrity" python3 -I -B scripts/check_baseline.py
