# ADR-003 — Adopt the AVE requirement IDs as working IDs over an immutable baseline

## Status
Accepted — 2026-10-01

## Context
The human supplied a complete requirements package (101 requirements, 404 acceptance criteria, 31 scenarios)
with stable AVE IDs and asked to integrate it into the existing working structure without renumbering,
weakening or omitting requirements, keeping the package as an immutable baseline (AVE-REQ-093). The
bootstrap format used generic `EPIC-/FEAT-/REQ-NNN` IDs and had no product files yet.

## Decision
1. Commit the package unchanged under `ai-video-editor-requirements/`; `BASELINE_MANIFEST_SHA256` in
   `scripts/check_baseline.py` pins its `MANIFEST.json`, and the checker verifies the manifest's inventory and
   every file hash itself before it runs `tools/validate_package.py` (package consistency), so immutability is
   proven from outside the package.
2. Working IDs are the baseline IDs verbatim (`AVE-EPIC-NN`, `AVE-FEAT-NNN`, `AVE-REQ-NNN`); the generic kinds
   are retired from the format. Discovered work continues at `AVE-REQ-102`.
3. `scripts/requirements/import_baseline.py` generates one working file per epic, feature and requirement in
   `docs/requirements/` with baseline statements and acceptance criteria verbatim and writes
   [IMPORT_MAPPING.md](../requirements/IMPORT_MAPPING.md). It never overwrites a working file.
4. A new status `deferred` holds the two future requirements (AVE-REQ-067, AVE-REQ-101); version-one
   requirements start `ready`.
5. `scripts/check_baseline.py` (run by `./scripts/verify.sh`) fails when the baseline changed, a requirement is
   missing, an acceptance criterion differs from the baseline without a logged `AC-n changed:` line, or a
   version-one requirement depends on a deferred one.

## Alternatives considered
- Renumber into `REQ-001…` with a mapping column — rejected: the human asked for the same stable AVE IDs.
- Edit the package files in place as the working copy — rejected: destroys the immutable baseline.
- Keep requirements only in the package and track status elsewhere — rejected: the repository's lifecycle,
  evidence and checker operate on working files.

## Consequences
- Test tags use `AVE-REQ-NNN AC-n` and scenario tags `AT-NN`.
- Any change to a working acceptance criterion is visible to the checker and needs a logged reason; changes that
  alter human intent go to the human.
- The checker and its regression suite cover the AVE ID scheme.

## Related requirements
- [AVE-REQ-093 — Adopt and preserve the supplied requirements baseline](../requirements/AVE-REQ-093-adopt-and-preserve-the-supplied-requirements-baseline.md)
- [AVE-REQ-097 — Verification gates that cannot pass as placeholders](../requirements/AVE-REQ-097-verification-gates-that-cannot-pass-as-placeholders.md)
