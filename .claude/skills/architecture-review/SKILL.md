---
name: architecture-review
description: Reviews the architecture as built against docs/ARCHITECTURE.md, Accepted ADRs and the actual requirements in a forked architect context. Reports complexity, duplication, boundary, coupling, scalability, security, data-consistency, operational and ADR findings with evidence and the smallest fix, headed by ARCHITECTURE HEALTHY, ATTENTION or ACTION-REQUIRED.
when_to_use: Inside milestone-review at every milestone end, and before a refactor that moves a module boundary, changes a shared interface, the data model or a persistence format, or spans several components.
argument-hint: "[scope: path, module, or milestone]"
context: fork
agent: architect
background: false
---

# Architecture review

Scope argument: `$ARGUMENTS`

Review the architecture as built against the architecture as documented and the requirements that actually exist, then return the report defined under Output. You advise; the lead decides and applies. Paths are relative to the repository root; dates come from `date -u +%F`.

## Ground rules

1. Write no files. One exception: when the scope argument explicitly asks for ADR drafts, draft each new or superseding ADR you recommend as `Proposed` per `docs/decisions/README.md` and list the paths under § ADR review.
2. Use Bash for read-only inspection: `git log`, `git grep`, `git ls-files`, `git diff`, dependency listings, line counts. Never install packages, build into tracked paths, commit, or change the working tree.
3. Every finding cites evidence (`path:line`, or a document and section) and ties its impact to a requirement, an Accepted ADR, an architectural driver or a named quality attribute: correctness, security, data integrity, maintainability, testability, performance, operability.
4. Never propose a rewrite, restructuring or renaming for stylistic preference, taste or fashion. Recommend the smallest change that removes the stated impact; "keep as is" is a valid conclusion.
5. Judge scalability and performance only against measurable targets in requirements or `docs/PRODUCT.md` § Performance expectations. Hypothetical future load is out of scope.
6. Requirements and Accepted ADRs are the baseline. When one of them looks wrong, say so as a recommendation for the lead; never design around it silently.
7. An undocumented component, boundary or significant decision is itself a finding. Never guess intent.

## 1. Resolve the scope

Split the argument into a scope (first word) and optional instructions (the rest, e.g. `M3 with ADR drafts`).

| Scope | Review |
|---|---|
| empty | the whole repository |
| `M<n>` | the milestone entry in `docs/ROADMAP.md`: its requirements, the components their `## Implementation evidence` and `docs/TRACEABILITY.md` rows name, and every file changed since the previous milestone review (commands below) |
| path or module name | those files, their direct callers and their direct dependencies |

```sh
# M<n> scope: base = the previous milestone's review commit, else the root commit
base=$(git log -1 --format=%H --grep='^docs: complete milestone M<n-1> review')
[ -n "$base" ] || base=$(git rev-list --max-parents=0 HEAD | tail -n 1)
echo "base $base"; git diff --stat "$base"..HEAD | tail -n 40
```

Whatever the scope, the drift check in section 4 covers every section of `docs/ARCHITECTURE.md` at component level.

## 2. Read the documented architecture

1. `docs/ARCHITECTURE.md` in full. When its `**Status:**` line reads `placeholder`, no system architecture exists yet: review only the ADR set (section 4, Obsolete ADRs), state this in § Summary, and skip the code sections.
2. The index in `docs/decisions/README.md`. Read every Accepted ADR in full for a whole-repository scope; for a narrower scope, read those that govern it (`grep -rl -e "<component or path>" -e "AVE-REQ-NNN" docs/decisions/`). Note every Proposed ADR.
3. The requirement set:

   ```sh
   grep -H -E '^(title|type|status|priority):' docs/requirements/AVE-REQ-*.md
   grep -l -E '^type: (non-functional|constraint)' docs/requirements/AVE-REQ-*.md
   ```

   Read in full every non-functional and constraint requirement that is not `superseded`, and, for an `M<n>` scope, the milestone's requirements. Read `docs/PRODUCT.md` § Product boundaries, § Security and privacy expectations, § Performance expectations and § Deployment assumptions.
4. Assumptions behind ADRs: `grep -n -E '^### ASM-|Status:\*\* (open|invalidated)' docs/ASSUMPTIONS.md`.
5. Write a working note before reading code: the expected components, their boundaries and dependency direction, data ownership, integration points, and the quality targets that apply. Judge the code against this note.

## 3. Map the code as built

```sh
git ls-files | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -n 40     # files per directory
git ls-files -z | xargs -0 wc -l 2>/dev/null | sort -rn | head -n 25          # largest files
git log -n 200 --format= --name-only | grep . | sort | uniq -c | sort -rn | head -n 25   # churn hotspots
```

1. Identify entry points, components (top-level modules or packages), dependency manifests and lockfiles.
2. Derive the actual dependency direction between components from their import statements (`git grep -n` on the language's import syntax). Note every cycle and every edge against the documented direction.
3. Locate persistence (schemas, migrations, file formats, storage paths), external-service clients, configuration and secret loading, background or long-running work, and error-handling conventions.
4. For an `M<n>` scope, read `git diff <base>..HEAD -- <paths>` for the changed files at the boundaries they cross; `<base>` is the hash printed in section 1, because shell variables do not persist between Bash calls.

## 4. Evaluate each dimension

| Dimension | Look for |
|---|---|
| Architecture drift | Components, boundaries, dependency directions, data stores, integrations or stack entries in the code that `docs/ARCHITECTURE.md` omits or describes differently; documented elements that no longer exist; deferrals (`Deferred to M<n>`) now due; § Local development and § Testing strategy commands that no longer work |
| Unnecessary complexity | Layers, abstractions, configuration options, generic mechanisms, indirection, processes or services that no requirement or Accepted ADR needs; an interface with a single implementation, external-service boundaries with their test fakes excepted |
| Duplicated abstractions | Two mechanisms for one concern: clients, configuration loaders, error models, validation paths, parallel models of one entity, copied modules |
| Poor boundaries | A component reading another's internals or storage; domain logic inside interface or I/O code; a module with unrelated responsibilities; data without a clear owner |
| Coupling | Dependency cycles; dependencies against the documented direction; shared mutable state; vendor or framework types crossing component boundaries; files that always change together across components (churn) |
| Scalability (actual requirements) | Algorithms, data structures, I/O patterns or resource use that cannot meet a stated target (input size, latency, throughput, concurrency, memory); cite the target and estimate the gap |
| Security | Trust boundaries without input validation; where authentication and authorization are enforced; secret loading and logging; injection surfaces (shell, query, path); unsafe deserialization; data protection required by `docs/PRODUCT.md` § Security and privacy expectations |
| Data consistency | Several writers to one store; missing transactions or atomic writes; partial failure leaving inconsistent state; retried operations without idempotency; cache invalidation; schema migration discipline; cleanup of temporary and derived data |
| Operational complexity | Processes, services, runtime dependencies and manual steps beyond what deployment needs; configuration sprawl; observability promised in `docs/ARCHITECTURE.md` and missing; verify.sh or CI duration growth |
| Obsolete ADRs | Accepted ADRs the code no longer follows; ADRs whose related requirements are all superseded or whose assumptions were invalidated; ADRs naming technology absent from the manifests; Proposed ADRs awaiting a decision; significant decisions visible in code without an ADR; index rows out of sync with ADR files |

## 5. Classify

Severity:
- **blocking**: the built system violates a requirement (including non-functional and constraint requirements), an Accepted ADR or a documented boundary; contains a security or data-integrity defect; or prevents a planned requirement from being met without rework. Resolve before the milestone closes.
- **important**: materially raises cost, risk or defect likelihood for upcoming requirements: documentation drift, duplicated mechanisms, coupling against the documented direction, obsolete or missing ADRs, operational burden without need. Schedule within the next milestone.
- **minor**: a local improvement with low impact; a candidate for `docs/ARCHITECTURE.md` § Risks and technical debt.

Effort: **S** a fraction of one focused session; **M** about one requirement; **L** several requirements, planned as roadmap work.

Drop a candidate finding when you cannot name its impact. Merge duplicates. Order findings by severity, then impact.

Verdict: `ACTION-REQUIRED` when any finding is blocking; `ATTENTION` when any is important; `HEALTHY` otherwise.

## 6. Recommend, without applying

- **ARCHITECTURE.md corrections**: section and the replacement content in one or two sentences each.
- **ADR actions**: supersede `ADR-NNN` (with the proposed decision), a new ADR for an undocumented significant decision, or a decision on a pending Proposed ADR. Draft files only under ground rule 1.
- **Follow-up requirements**: title, type, priority, parent (`AVE-FEAT-NNN` or `AVE-EPIC-NN`), intent and the source finding. The lead allocates IDs and creates them as `proposed`.
- **Technical-debt entries** for minor findings worth tracking.
- **Escalations**: only decisions meeting a criterion in `CLAUDE.md` § Autonomy and escalation, each with a recommended default.

## Output

Your final message is the report alone, in exactly this format; nothing precedes the first line.

```text
ARCHITECTURE: HEALTHY | ATTENTION | ACTION-REQUIRED
Scope: <resolved scope> — HEAD <short hash> — YYYY-MM-DD
## Summary
<2–4 sentences: fitness for the current requirements and the main risks>
## Findings
### Blocking
1. <title> — <dimension>
   - Evidence: <path:line, or document § section>
   - Impact: <AVE-REQ-NNN | ADR-NNN | driver | quality attribute> — <consequence>
   - Change: <smallest recommended change>
   - Effort: S | M | L
### Important
### Minor
## Architecture drift
| ARCHITECTURE.md section | Documented | Actual | Recommended action |
## ADR review
| ADR | Status | Assessment | Recommendation |
## Recommended follow-up requirements
| Title | Type | Priority | Parent | Intent | Source finding |
## Recommended ARCHITECTURE.md updates
## Proposed technical-debt entries
## Escalation
## Checked without findings
<one line per dimension with no finding: what you checked>
```

- First line: exactly one of `ARCHITECTURE: HEALTHY`, `ARCHITECTURE: ATTENTION`, `ARCHITECTURE: ACTION-REQUIRED`.
- Write "None." under every empty heading.
- Keep the report under ~800 words unless the findings need more.
