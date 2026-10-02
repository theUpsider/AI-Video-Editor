#!/usr/bin/env bash
# scripts/tests/make-fixture.sh <dir> [with-reqs] — builds a minimal valid project tree in <dir>
# (deleted and recreated) from the repository's real scripts and hooks. with-reqs adds an epic, a
# feature, two requirements (one done, one CRLF cross-cutting) and their traceability rows.
# Used by test-checker.sh, test-stop-hook.sh and test-session-start.sh; <dir> lies in a temp dir.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
D="${1:?usage: make-fixture.sh <dir> [with-reqs]}"; MODE="${2:-}"
case "$D" in
  / | "$REPO" | "$REPO"/*) printf 'make-fixture.sh: refusing to build a fixture in %s\n' "$D" >&2; exit 2 ;;
esac
rm -rf "$D"; mkdir -p "$D"; cd "$D"
mkdir -p docs/requirements docs/decisions docs/briefs .claude/agents .claude/hooks scripts/lib scripts/requirements .github/workflows .devcontainer
cp "$REPO/scripts/verify.sh" "$REPO/scripts/check-project-control.sh" "$REPO/scripts/dev-container.sh" scripts/
cp "$REPO/.devcontainer/Dockerfile" .devcontainer/
cp "$REPO/.claude/hooks/session-start.sh" "$REPO/.claude/hooks/stop-verify.sh" .claude/hooks/
cp "$REPO/scripts/lib/verify-state.sh" scripts/lib/
# The baseline tools are required files; their checks need the real requirements package, so the
# fixture holds passing stand-ins (these suites test the gate mechanics).
printf '#!/usr/bin/env python3\nprint("OK: baseline check stand-in for test fixtures")\n' > scripts/check_baseline.py
printf '#!/usr/bin/env python3\nprint("import stand-in for test fixtures")\n' > scripts/requirements/import_baseline.py
# Component step files and backend project files are required files; the fixture holds stand-ins
# (these suites test the verify.sh core and the hook mechanics, not the product components).
mkdir -p scripts/verify.d backend
for step in 10-requirements 15-evidence-tooling 20-backend 90-tooling 95-evidence; do
  printf '# stand-in component step file for test fixtures (registers no steps)\n' > "scripts/verify.d/$step.sh"
done
printf '[project]\nname = "fixture-stand-in"\n' > backend/pyproject.toml
printf '# stand-in lock file for test fixtures\n' > backend/uv.lock
mkdir -p backend/tests
printf '"""stand-in evidence plugin for test fixtures"""\n' > backend/tests/evidence_plugin.py
printf '# Task briefs\n\nTemplate and rules for task briefs (stand-in).\n' > docs/briefs/README.md
# verify.sh records every run with the real evidence tool (standard library only).
cp "$REPO/scripts/evidence.py" scripts/
cp "$REPO/.claude/settings.json" .claude/
cp "$REPO/.gitignore" "$REPO/.gitattributes" .
cp "$REPO/.github/workflows/verify.yml" .github/workflows/
chmod +x scripts/*.sh scripts/check_baseline.py scripts/requirements/import_baseline.py .claude/hooks/*.sh

cat > CLAUDE.md <<'EOF'
# Project instructions
See [PROGRESS](docs/PROGRESS.md) and [the requirements format](docs/requirements/README.md#ids).
External: [site](https://example.com), [mail](mailto:a@b.c), [anchor](#top).
Inline code is ignored: `[x](missing-in-code-span.md)`.
EOF
cat > README.md <<'EOF'
# Working title
Read [CLAUDE.md](CLAUDE.md) and [docs](docs/) and ![img](</docs/PRODUCT.md>).
[ref]: docs/ROADMAP.md
[^1]: A footnote that is not a link.

```markdown
[example](docs/requirements/AVE-REQ-999-example.md)
```
~~~~
[example](also-missing.md)
```
still inside the tilde fence
~~~~
EOF
cat > docs/PRODUCT.md <<'EOF'
# Product definition

## Product goals

| ID | Goal | Success signal |
|---|---|---|
| GOAL-001 | Stub goal | Stub signal |

## Core user journeys
Mentions GOAL-002 outside the goals section.
EOF
printf '# Architecture\n\nSee [ADR-001](decisions/ADR-001-specification-driven-development-workflow.md).\n' > docs/ARCHITECTURE.md
printf '# Roadmap\n\n_TBD: populated by product-definition._\n' > docs/ROADMAP.md
printf '# Assumptions\r\n\r\n### ASM-001 — Stub\r\n' > docs/ASSUMPTIONS.md
cat > docs/PROGRESS.md <<'EOF'
# Current project state
_Last updated: 2026-10-01 — stub_
## Current milestone
None.
## Current objective
## In progress
## Recently completed
## Next recommended work
## Blockers
## Known failures
## Important recent decisions
## Verification status
EOF
cat > docs/TRACEABILITY.md <<'EOF'
# Traceability

```markdown
| [AVE-REQ-012](requirements/AVE-REQ-012-example-slug.md) | done | x | y | z | — |
```

## Goal coverage

| Goal | Epics |
|---|---|

_No entries yet._

## Requirement matrix

| Requirement | Status | Implementation | Tests | Evidence | ADRs |
|---|---|---|---|---|---|

_No entries yet._
EOF
printf '# Requirements\n\nFormat lives here. [Traceability](../TRACEABILITY.md)\n' > docs/requirements/README.md
# Generated mapping: link-checked, never parsed as a requirement file.
printf '# Requirements baseline import mapping\n\n| AVE ID | Working file |\n|---|---|\n| AVE-REQ-001 | [README.md](README.md) |\n' > docs/requirements/IMPORT_MAPPING.md
: > docs/requirements/.gitkeep
printf '# Architecture decision records\n\n| [ADR-001](ADR-001-specification-driven-development-workflow.md) | x |\n' > docs/decisions/README.md
: > docs/decisions/.gitkeep
cat > docs/decisions/ADR-001-specification-driven-development-workflow.md <<'EOF'
# ADR-001 — Specification-driven development workflow

## Status
Accepted — 2026-10-01

## Context
Stub.
## Decision
Stub.
## Alternatives considered
Stub.
## Consequences
Stub.
## Related requirements
None (process-level).
EOF
for a in architect implementer reviewer tester researcher; do
  printf -- '---\nname: %s\ndescription: Stub %s agent.\ntools: Read, Grep\nmodel: inherit\n---\n\nYou are the %s.\n' "$a" "$a" "$a" > ".claude/agents/$a.md"
done
for s in product-definition technical-foundation develop implement-requirement verify-requirement architecture-review milestone-review resume-project; do
  mkdir -p ".claude/skills/$s"
  printf -- '---\nname: %s\ndescription: Stub skill %s.\nargument-hint: "[AVE-REQ-NNN]"\n---\n\n# %s\n' "$s" "$s" "$s" > ".claude/skills/$s/SKILL.md"
done
# a folded description must count as non-empty
printf -- '---\nname: develop\ndescription: >-\n  Runs the loop,\n  folded.\n---\n\nBody links to [resume](../resume-project/SKILL.md).\n' > .claude/skills/develop/SKILL.md
printf '# Baseline capabilities\n' > .claude/skills/product-definition/baseline-capabilities.md

if [ "$MODE" = "with-reqs" ]; then
  cat > docs/requirements/AVE-EPIC-01-stub-epic.md <<'EOF'
---
id: AVE-EPIC-01
title: Stub epic
status: in-progress
priority: must
goals: [GOAL-001]
---

# AVE-EPIC-01 — Stub epic

## Goal
## Scope
## Features
- [AVE-FEAT-001 — Stub feature](AVE-FEAT-001-stub-feature.md)
## Success criteria
## Status
- 2026-10-01 — proposed — stub
- 2026-10-02 — in-progress — stub
EOF
  cat > docs/requirements/AVE-FEAT-001-stub-feature.md <<'EOF'
---
id: AVE-FEAT-001
title: Stub feature
status: in-progress
priority: must
parent: AVE-EPIC-01
---

# AVE-FEAT-001 — Stub feature

## Intent
## User journey
## Requirements
- [AVE-REQ-001 — Done requirement](AVE-REQ-001-done-requirement.md)
## Out of scope
## Feature acceptance
## Status
- 2026-10-02 — in-progress — stub
EOF
  cat > docs/requirements/AVE-REQ-001-done-requirement.md <<'EOF'
---
id: AVE-REQ-001
title: Done requirement
type: functional
status: done
priority: must
parent: AVE-FEAT-001
source: human
---

# AVE-REQ-001 — Done requirement

## Intent
Stub.
## Description
Stub.
## Acceptance criteria
- [x] AC-1 First behavior
- [X] AC-2 Second behavior
## Edge cases
None.
## Dependencies
None.
## Verification strategy
- AC-1 — unit
## Implementation evidence
- `src/x` — stub
## Test evidence
- verify-requirement: PASS — 2026-10-02

```text
_TBD inside a fence is ignored; - [ ] AC-9 too
```
## Status
- 2026-10-01 — in-progress — stub — with a third field
- 2026-10-02 — done — stub
EOF
  # CRLF requirement file, cross-cutting parent EPIC
  printf -- '---\r\nid: AVE-REQ-002\r\ntitle: "Quoted title"\r\ntype: non-functional\r\nstatus: proposed\r\npriority: should\r\nparent: AVE-EPIC-01\r\nsource: derived\r\n---\r\n\r\n# AVE-REQ-002 — Quoted title\r\n\r\n## Intent\r\n## Description\r\n## Acceptance criteria\r\n- [ ] AC-1 Something\r\n## Edge cases\r\n## Dependencies\r\n## Verification strategy\r\n## Implementation evidence\r\n_TBD: later._\r\n## Test evidence\r\n## Status\r\n- 2026-10-01 — proposed — stub\r\n' > docs/requirements/AVE-REQ-002-crlf-requirement.md
  python3 - <<'PY'
p='docs/TRACEABILITY.md'
s=open(p).read()
s=s.replace("""| Goal | Epics |
|---|---|

_No entries yet._""","""| Goal | Epics |
|---|---|
| GOAL-001 | [AVE-EPIC-01](requirements/AVE-EPIC-01-stub-epic.md) |""")
s=s.replace("""|---|---|---|---|---|---|

_No entries yet._""","""|---|---|---|---|---|---|
| [AVE-REQ-001](requirements/AVE-REQ-001-done-requirement.md) | done | `src/x` | `test/x` | PASS 2026-10-02 — [Test evidence](requirements/AVE-REQ-001-done-requirement.md#test-evidence) | — |""")
open(p,'w').write(s)
PY
fi
