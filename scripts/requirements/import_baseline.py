#!/usr/bin/env python3
"""Import the immutable requirements baseline into the working requirement files.

Usage:  python3 scripts/requirements/import_baseline.py          create missing working files
        python3 scripts/requirements/import_baseline.py --check  report what an import would change

Reads ai-video-editor-requirements/ (never writes to it) and generates, in docs/requirements/:
  - one working file per baseline epic (AVE-EPIC-NN), feature (AVE-FEAT-NNN) and requirement
    (AVE-REQ-NNN), named <ID>-<slug>.md with the slug taken from the baseline title;
  - IMPORT_MAPPING.md, the generated ID / file / scope / gate / initial-status table.
An existing working file is always kept (its lifecycle state belongs to the lead); only missing
files are created. IMPORT_MAPPING.md is regenerated when its content differs. The output is
deterministic, so a second run creates nothing.

Exit: 0 success (with --check: nothing would change) · 1 --check found changes · 2 baseline or
usage error. Python 3.8+ standard library only. Format: docs/requirements/README.md.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PKG_NAME = "ai-video-editor-requirements"
PKG = ROOT / PKG_NAME
OUT = ROOT / "docs" / "requirements"
MAPPING = OUT / "IMPORT_MAPPING.md"

IMPORT_DATE = "2026-10-01"
BASELINE_VERSION = "1.0"
# Relative prefix from docs/requirements/ to the baseline package.
PKG_REL = "../../" + PKG_NAME

# Baseline value -> working value (recorded in docs/requirements/README.md § Baseline import).
TYPE_MAP = {"functional": "functional", "nonfunctional": "non-functional", "delivery": "constraint"}
PRIORITY_MAP = {"must": "must", "future": "could"}
STATUS_MAP = {"ready": "ready", "deferred": "deferred"}

# Lead decision (ADR-003): each baseline epic serves one product goal of docs/PRODUCT.md.
EPIC_GOALS = {
    "AVE-EPIC-01": "GOAL-001",
    "AVE-EPIC-02": "GOAL-002",
    "AVE-EPIC-03": "GOAL-003",
    "AVE-EPIC-04": "GOAL-004",
    "AVE-EPIC-05": "GOAL-005",
    "AVE-EPIC-06": "GOAL-006",
    "AVE-EPIC-07": "GOAL-007",
    "AVE-EPIC-08": "GOAL-008",
    "AVE-EPIC-09": "GOAL-009",
    "AVE-EPIC-10": "GOAL-010",
}

# docs/PRODUCT.md § Core user journeys served by each feature (initial mapping; the lead owns it).
FEATURE_JOURNEYS = {
    "AVE-FEAT-001": ["UJ-001"],
    "AVE-FEAT-002": ["UJ-003"],
    "AVE-FEAT-003": ["UJ-002", "UJ-003"],
    "AVE-FEAT-004": ["UJ-002"],
    "AVE-FEAT-005": ["UJ-002", "UJ-003"],
    "AVE-FEAT-006": ["UJ-002", "UJ-003"],
    "AVE-FEAT-007": ["UJ-002", "UJ-003", "UJ-005"],
    "AVE-FEAT-008": ["UJ-002", "UJ-003"],
    "AVE-FEAT-009": ["UJ-002", "UJ-003"],
    "AVE-FEAT-010": ["UJ-006"],
    "AVE-FEAT-011": ["UJ-002", "UJ-004"],
    "AVE-FEAT-012": ["UJ-003", "UJ-006"],
    "AVE-FEAT-013": ["UJ-002", "UJ-004"],
    "AVE-FEAT-014": ["UJ-002"],
    "AVE-FEAT-015": ["UJ-005"],
    "AVE-FEAT-016": ["UJ-004"],
    "AVE-FEAT-017": ["UJ-005"],
    "AVE-FEAT-018": ["UJ-001", "UJ-002", "UJ-003", "UJ-004", "UJ-005", "UJ-006"],
}
JOURNEY_NOTES = {
    "AVE-FEAT-018": "Cross-cutting: the reliability, security and operability of every journey.",
    "AVE-FEAT-019": "None: a delivery-process feature serving GOAL-009 with no end-user journey.",
    "AVE-FEAT-020": (
        "None: explicit future scope (GOAL-010), kept outside every version-one journey."
    ),
}


class BaselineError(Exception):
    """The baseline package is missing data or holds a value this importer cannot map."""


# --------------------------------------------------------------------------------------------
# Baseline loading
# --------------------------------------------------------------------------------------------


def load_json(relative: str):
    path = PKG / relative
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise BaselineError(f"cannot read {PKG_NAME}/{relative}: {exc}") from exc


def baseline_frontmatter(path: Path) -> dict:
    """Key/value pairs of a baseline requirement file's frontmatter (values unquoted)."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise BaselineError(f"{path.relative_to(ROOT)}: missing frontmatter")
    block = text.split("---", 2)[1]
    result = {}
    for line in block.splitlines():
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", line)
        if match:
            value = match.group(2).strip()
            if len(value) >= 2 and value[0] == value[-1] == '"':
                value = value[1:-1]
            result[match.group(1)] = value
    return result


def mapped(table: dict, value: str, what: str, owner: str) -> str:
    if value not in table:
        raise BaselineError(
            f"{owner}: baseline {what} '{value}' has no mapping (known: {sorted(table)})"
        )
    return table[value]


def load_baseline() -> dict:
    reqs_doc = load_json("spec/requirements.json")
    feats_doc = load_json("spec/features.json")
    clauses = load_json("spec/source_clauses.json")

    epics = []
    for key, title in sorted(feats_doc["epics"].items()):
        eid = f"AVE-EPIC-{key}"
        if eid not in EPIC_GOALS:
            raise BaselineError(f"{eid}: no product goal assigned in EPIC_GOALS")
        epics.append({"id": eid, "title": title, "goal": EPIC_GOALS[eid], "features": []})
    epic_by_id = {e["id"]: e for e in epics}

    features = []
    for item in feats_doc["features"]:
        if item["epic"] not in epic_by_id:
            raise BaselineError(f"{item['id']}: unknown epic {item['epic']}")
        feature = {"id": item["id"], "title": item["title"], "epic": item["epic"], "reqs": []}
        features.append(feature)
        epic_by_id[item["epic"]]["features"].append(feature)
    feat_by_id = {f["id"]: f for f in features}

    reqs = []
    for item in reqs_doc["requirements"]:
        rid = item["id"]
        md = PKG / "spec" / "requirements" / f"{rid}.md"
        fm = baseline_frontmatter(md)
        if item["feature"] not in feat_by_id:
            raise BaselineError(f"{rid}: unknown feature {item['feature']}")
        req = {
            "id": rid,
            "title": item["title"],
            "statement": item["statement"],
            "feature": item["feature"],
            "epic": item["epic"],
            "gate": item["milestone"],
            "scope": item["scope"],
            "origins": list(item["origins"]),
            "dependencies": list(item["dependencies"]),
            "scenarios": list(item["scenarios"]),
            "criteria": [(c["id"], c["text"]) for c in item["acceptance_criteria"]],
            "type": mapped(TYPE_MAP, fm.get("type", ""), "type", rid),
            "priority": mapped(PRIORITY_MAP, item["priority"], "priority", rid),
            "status": mapped(STATUS_MAP, item["status"], "status", rid),
            "source": source_of(item["origins"]),
        }
        if req["scope"] not in ("v1", "future"):
            raise BaselineError(f"{rid}: unknown scope '{req['scope']}'")
        if (req["scope"] == "future") != (req["status"] == "deferred"):
            raise BaselineError(
                f"{rid}: scope '{req['scope']}' and status '{req['status']}' disagree"
            )
        for origin in req["origins"]:
            if origin not in clauses:
                raise BaselineError(f"{rid}: unknown origin clause {origin}")
        reqs.append(req)
        feat_by_id[item["feature"]]["reqs"].append(req)

    # Statuses of epics and features derive from their children (README § Status lifecycle).
    for feature in features:
        feature["status"] = derived_status(feature["reqs"])
    for epic in epics:
        epic["status"] = derived_status([r for f in epic["features"] for r in f["reqs"]])

    return {
        "epics": epics,
        "features": features,
        "reqs": reqs,
        "req_by_id": {r["id"]: r for r in reqs},
        "feat_by_id": feat_by_id,
        "epic_by_id": epic_by_id,
        "clauses": clauses,
        "prepared": reqs_doc.get("prepared", ""),
    }


def source_of(origins) -> str:
    """human when an origin is a user clause (U..); derived when all are derived clauses (D..)."""
    return "human" if any(o.startswith("U") for o in origins) else "derived"


def derived_status(children) -> str:
    return "deferred" if all(c["status"] == "deferred" for c in children) else "ready"


# --------------------------------------------------------------------------------------------
# Naming and links
# --------------------------------------------------------------------------------------------


def slugify(title: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")


def heading_anchor(heading: str) -> str:
    """GitHub-style anchor of a Markdown heading (the baseline validator uses the same rule)."""
    cleaned = re.sub(r"[^\w\- ]", "", heading.lower())
    return re.sub(r"\s", "-", cleaned)


def flow_list(values) -> str:
    return "[" + ", ".join(values) + "]"


def working_name(item_id: str, title: str) -> str:
    """The existing working file for an ID (its slug is fixed), or the name an import gives it."""
    existing = sorted(OUT.glob(f"{item_id}-*.md"))
    if existing:
        return existing[0].name
    return f"{item_id}-{slugify(title)}.md"


def link(item: dict) -> str:
    return f"[{item['id']} — {item['title']}]({working_name(item['id'], item['title'])})"


def clause_link(clause: str) -> str:
    return f"[{clause}]({PKG_REL}/intake/USER_BRIEF.md#{clause.lower()})"


def scenario_link(scenario: str) -> str:
    return f"[{scenario}]({PKG_REL}/spec/ACCEPTANCE_TESTS.md#{scenario.lower()})"


def baseline_req_path(rid: str) -> str:
    return f"{PKG_REL}/spec/requirements/{rid}.md"


def epic_anchor(epic: dict) -> str:
    return (
        f"{PKG_REL}/spec/EPICS_AND_FEATURES.md#{heading_anchor(epic['id'] + ' - ' + epic['title'])}"
    )


def feature_anchor(feature: dict) -> str:
    return f"{PKG_REL}/spec/EPICS_AND_FEATURES.md#{feature['id'].lower()}"


def goal_link(goal: str) -> str:
    return f"[{goal}](../PRODUCT.md#product-goals)"


def unique(values):
    seen = []
    for value in values:
        if value not in seen:
            seen.append(value)
    return seen


def plural(count: int, noun: str) -> str:
    return f"{count} {noun}" + ("" if count == 1 else "s")


def scenario_sort_key(scenario: str):
    return int(scenario.split("-")[1])


def gate_sort_key(gate: str):
    return (1, 0) if gate == "FUTURE" else (0, int(gate[1:]))


# --------------------------------------------------------------------------------------------
# Working file content
# --------------------------------------------------------------------------------------------


def status_log(status: str, requirement: bool = False) -> list:
    if status == "deferred":
        return [f"- {IMPORT_DATE} — deferred — future scope in baseline (lead)"]
    lines = [f"- {IMPORT_DATE} — ready — imported from baseline v{BASELINE_VERSION} (lead)"]
    if requirement:
        lines.append(
            f"- {IMPORT_DATE} — ready — baseline ready means specified for planning; Edge cases"
            " and the dependency order are settled before work starts (lead)"
        )
    return lines


def epic_content(epic: dict) -> str:
    reqs = [r for f in epic["features"] for r in f["reqs"]]
    v1 = [r for r in reqs if r["scope"] == "v1"]
    future = [r for r in reqs if r["scope"] == "future"]
    gates = sorted({r["gate"] for r in reqs}, key=gate_sort_key)
    scenarios = sorted({s for r in v1 for s in r["scenarios"]}, key=scenario_sort_key)
    priority = "could" if epic["status"] == "deferred" else "must"
    lines = [
        "---",
        f"id: {epic['id']}",
        f"title: {epic['title']}",
        f"status: {epic['status']}",
        f"priority: {priority}",
        f"goals: [{epic['goal']}]",
        "---",
        "",
        f"# {epic['id']} — {epic['title']}",
        "",
        "## Goal",
        f"Serves {goal_link(epic['goal'])}. Baseline epic "
        f"[{epic['id']} — {epic['title']}]({epic_anchor(epic)}) (package v{BASELINE_VERSION}).",
        "",
        "## Scope",
        f"The features below and their {plural(len(reqs), 'requirement')} ({len(v1)} version one,"
        f" {len(future)} future), with primary {'gates' if len(gates) > 1 else 'gate'}"
        f" {', '.join(gates)}.",
    ]
    if future:
        lines.append(
            "Deferred future scope inside this epic: " + ", ".join(link(r) for r in future) + "."
        )
    lines += ["", "## Features"]
    lines += [f"- {link(f)}" for f in epic["features"]]
    lines += ["", "## Success criteria"]
    if v1:
        lines.append(
            "- Every version-one requirement of the features above is `done` with recorded"
            " evidence."
        )
        lines.append(
            "- Acceptance scenarios "
            + ", ".join(scenario_link(s) for s in scenarios)
            + " pass on real rendered output in milestone-review."
        )
    for req in future:
        lines.append(
            f"- {req['id']} stays `deferred`: no version-one gate depends on it, and the"
            " product never advertises it as implemented."
        )
    lines += ["", "## Status", *status_log(epic["status"])]
    return "\n".join(lines) + "\n"


def feature_content(feature: dict, base: dict) -> str:
    epic = base["epic_by_id"][feature["epic"]]
    reqs = feature["reqs"]
    v1 = [r for r in reqs if r["scope"] == "v1"]
    future = [r for r in reqs if r["scope"] == "future"]
    origins = sorted({o for r in reqs for o in r["origins"]}, key=lambda c: (c[0] != "U", c))
    scenarios = sorted({s for r in v1 for s in r["scenarios"]}, key=scenario_sort_key)
    priority = "could" if feature["status"] == "deferred" else "must"
    lines = [
        "---",
        f"id: {feature['id']}",
        f"title: {feature['title']}",
        f"status: {feature['status']}",
        f"priority: {priority}",
        f"parent: {feature['epic']}",
        "---",
        "",
        f"# {feature['id']} — {feature['title']}",
        "",
        "## Intent",
        f"Baseline feature [{feature['id']} — {feature['title']}]({feature_anchor(feature)}) of "
        f"{link(epic)}, serving {goal_link(epic['goal'])}. User-brief clauses covered by its"
        " requirements: " + ", ".join(clause_link(c) for c in origins) + ".",
        "",
        "## User journey",
    ]
    journeys = FEATURE_JOURNEYS.get(feature["id"], [])
    if journeys:
        lines.append("- " + ", ".join(f"[{j}](../PRODUCT.md#core-user-journeys)" for j in journeys))
    if feature["id"] in JOURNEY_NOTES:
        lines.append(f"- {JOURNEY_NOTES[feature['id']]}")
    if scenarios:
        lines.append(
            "- Acceptance scenarios: " + ", ".join(scenario_link(s) for s in scenarios) + "."
        )
    lines += ["", "## Requirements"]
    lines += [f"- {link(r)}" for r in reqs]
    lines += ["", "## Out of scope"]
    if future:
        lines += [f"- {link(r)}: deferred future scope in the baseline." for r in future]
    else:
        lines.append(
            "- Object and motion tracking and advanced continuous video understanding, deferred"
            f" to a later version ([scope]({PKG_REL}/spec/SCOPE_AND_ASSUMPTIONS.md))."
        )
    lines += ["", "## Feature acceptance"]
    if v1:
        lines.append(
            "- [ ] Every version-one requirement above is `done`, and its acceptance scenarios"
            " pass on real rendered output in milestone-review."
        )
    for req in future:
        lines.append(
            f"- [ ] {req['id']} stays `deferred` and unadvertised; version one ships without it."
        )
    lines += ["", "## Status", *status_log(feature["status"])]
    return "\n".join(lines) + "\n"


def requirement_content(req: dict, base: dict) -> str:
    feature = base["feat_by_id"][req["feature"]]
    epic = base["epic_by_id"][req["epic"]]
    criteria = req["criteria"]
    first, last = criteria[0][0], criteria[-1][0]
    span = first if first == last else f"{first}–{last}"  # noqa: RUF001 (en dash: a range)
    lines = [
        "---",
        f"id: {req['id']}",
        f"title: {req['title']}",
        f"type: {req['type']}",
        f"status: {req['status']}",
        f"priority: {req['priority']}",
        f"parent: {req['feature']}",
        f"source: {req['source']}",
        f"scope: {req['scope']}",
        f"primary_gate: {req['gate']}",
        f"origins: {flow_list(req['origins'])}",
        f"dependencies: {flow_list(req['dependencies'])}",
        f"scenarios: {flow_list(req['scenarios'])}",
        f"baseline: {baseline_req_path(req['id'])}",
        "---",
        "",
        f"# {req['id']} — {req['title']}",
        "",
        "## Intent",
        f"Serves {goal_link(epic['goal'])} through {link(feature)}."
        " Origin clauses in the user brief:",
    ]
    lines += [f"- {clause_link(c)} — {base['clauses'][c]}" for c in req["origins"]]
    lines += [
        "",
        f"Imported from the immutable baseline [{req['id']}]({baseline_req_path(req['id'])})"
        f" (package v{BASELINE_VERSION}); primary gate {req['gate']}, scope {req['scope']}.",
        "",
        "## Description",
        req["statement"],
        "",
        "## Acceptance criteria",
    ]
    lines += [f"- [ ] {cid} {text}" for cid, text in criteria]
    lines += [
        "",
        "## Edge cases",
        "_TBD: refined when implementation starts._",
        "",
        "## Dependencies",
    ]
    if req["dependencies"]:
        lines += [f"- {link(base['req_by_id'][d])}" for d in req["dependencies"]]
    else:
        lines.append("None.")
    lines += [
        "",
        "## Verification strategy",
        f"- {span} — criterion-level tests tagged `{req['id']} AC-n`, one tag per criterion;"
        " the level of each (unit, integration, end-to-end, inspection) is recorded when"
        " implementation starts.",
        "- Acceptance scenarios "
        + ", ".join(scenario_link(s) for s in req["scenarios"])
        + " — run on real rendered output and tagged `AT-NN`; a scenario counts as evidence once it"
        " passes on the current tree.",
    ]
    if req["status"] == "deferred":
        lines.append("- Deferred: version one keeps this capability excluded (GOAL-010).")
    lines += [
        "",
        "## Implementation evidence",
        "_TBD: filled by the implementer when the implementation is complete._",
        "",
        "## Test evidence",
        "_TBD: filled by the lead from the verify-requirement report._",
        "",
        "## Status",
        *status_log(req["status"], requirement=True),
    ]
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------------------------
# IMPORT_MAPPING.md
# --------------------------------------------------------------------------------------------


def mapping_content(base: dict) -> str:
    reqs = base["reqs"]
    v1 = sum(r["scope"] == "v1" for r in reqs)
    future = sum(r["scope"] == "future" for r in reqs)
    criteria = sum(len(r["criteria"]) for r in reqs)
    derived = [r["id"] for r in reqs if r["source"] == "derived"]

    def file_cell(item):
        name = working_name(item["id"], item["title"])
        return f"[{name}]({name})"

    def row(cells):
        return "| " + " | ".join(cells) + " |"

    header = row(
        ["AVE ID", "Title", "Working file", "Baseline file", "Scope", "Gate", "Initial status"]
    )
    separator = "|---|---|---|---|---|---|---|"
    lines = [
        "# Requirements baseline import mapping",
        "",
        "Generated by [import_baseline.py](../../scripts/requirements/import_baseline.py)"
        " from the immutable"
        f" baseline [{PKG_NAME}/]({PKG_REL}/README.md) (package v{BASELINE_VERSION}, prepared"
        f" {base['prepared']}). Regenerate it with"
        " `python3 scripts/requirements/import_baseline.py`; edits by hand are overwritten."
        " [check_baseline.py](../../scripts/check_baseline.py) verifies"
        " the working files against the baseline. The format of the working files lives in"
        " [README.md](README.md).",
        "",
        "## Counts",
        "",
        "| Item | Count |",
        "|---|---|",
        f"| Epics | {len(base['epics'])} |",
        f"| Features | {len(base['features'])} |",
        f"| Requirements | {len(reqs)} |",
        f"| Version-one requirements (initial status `ready`) | {v1} |",
        f"| Future requirements (status `deferred`) | {future} |",
        f"| Acceptance criteria | {criteria} |",
        "",
        "## Rules for changing a working requirement",
        "",
        f"1. `{PKG_NAME}/` stays byte-for-byte unchanged; `scripts/check_baseline.py` pins the SHA-256 of its"
        " MANIFEST.json and verifies the inventory and every file hash itself.",
        "2. The working files in this directory hold the lifecycle state. The Initial status column"
        " below records the import; frontmatter `status` is current.",
        "3. Log every change to a working requirement in its `## Status` section with the reason"
        " ([README.md](README.md) § Changing requirements).",
        "4. A changed, removed or added criterion needs its marker line in the Status log"
        " (`AC-n changed [<mark>]: <reason>`, `AC-n removed: <reason>`,"
        " `AC-n added [<mark>]: <reason>`; [README.md](README.md) § Changing requirements rule 1);"
        " check_baseline.py reports it as a recorded change and fails on an unrecorded one. Added"
        " criteria take the next free AC number.",
        "5. `scope`, `parent`, `dependencies`, `origins` and `scenarios` equal the baseline"
        " values.",
        "6. Requirements discovered later continue at AVE-REQ-102, AVE-FEAT-021 and AVE-EPIC-11"
        " with"
        " `source: derived`; this table lists the baseline only.",
        "",
        "## Value mappings",
        "",
        "| Field | Baseline value | Working value |",
        "|---|---|---|",
    ]
    lines += [f"| type | {k} | {v} |" for k, v in TYPE_MAP.items()]
    lines += [f"| priority | {k} | {v} |" for k, v in PRIORITY_MAP.items()]
    lines += [f"| status | {k} | {v} |" for k, v in STATUS_MAP.items()]
    lines += [
        "| source | origins include a user clause (U01–U27) | human |",  # noqa: RUF001
        "| source | origins hold derived clauses (D01–D05) only | derived |",  # noqa: RUF001
        "",
        f"Requirements with `source: derived`: {', '.join(derived)}.",
        "",
        "## Epics",
        "",
        header,
        separator,
    ]
    for epic in base["epics"]:
        reqs_of = [r for f in epic["features"] for r in f["reqs"]]
        scope = "v1" if any(r["scope"] == "v1" for r in reqs_of) else "future"
        gates = ", ".join(sorted({r["gate"] for r in reqs_of}, key=gate_sort_key))
        lines.append(
            row(
                [
                    epic["id"],
                    epic["title"],
                    file_cell(epic),
                    f"[EPICS_AND_FEATURES.md]({epic_anchor(epic)})",
                    scope,
                    gates,
                    epic["status"],
                ]
            )
        )
    lines += ["", "## Features", "", header, separator]
    for feature in base["features"]:
        reqs_of = feature["reqs"]
        scope = "v1" if any(r["scope"] == "v1" for r in reqs_of) else "future"
        gates = ", ".join(sorted({r["gate"] for r in reqs_of}, key=gate_sort_key))
        lines.append(
            row(
                [
                    feature["id"],
                    feature["title"],
                    file_cell(feature),
                    f"[EPICS_AND_FEATURES.md]({feature_anchor(feature)})",
                    scope,
                    gates,
                    feature["status"],
                ]
            )
        )
    lines += ["", "## Requirements", "", header, separator]
    for req in reqs:
        lines.append(
            row(
                [
                    req["id"],
                    req["title"],
                    file_cell(req),
                    f"[{req['id']}.md]({baseline_req_path(req['id'])})",
                    req["scope"],
                    req["gate"],
                    req["status"],
                ]
            )
        )
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------


def planned_files(base: dict):
    """(item ID, target path, generated content) for every working file, in ID order."""
    plan = []
    for epic in base["epics"]:
        plan.append((epic["id"], OUT / working_name(epic["id"], epic["title"]), epic_content(epic)))
    for feature in base["features"]:
        plan.append(
            (
                feature["id"],
                OUT / working_name(feature["id"], feature["title"]),
                feature_content(feature, base),
            )
        )
    for req in base["reqs"]:
        plan.append(
            (req["id"], OUT / working_name(req["id"], req["title"]), requirement_content(req, base))
        )
    return plan


def read_text(path: Path) -> str:
    with path.open(encoding="utf-8", newline="") as handle:
        return handle.read()


def write_text(path: Path, content: str) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--check",
        action="store_true",
        help="report what an import would create or regenerate; write nothing",
    )
    args = parser.parse_args()

    if not PKG.is_dir():
        print(f"ERROR: baseline directory not found: {PKG}", file=sys.stderr)
        return 2
    try:
        base = load_baseline()
    except (BaselineError, KeyError, TypeError, ValueError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    OUT.mkdir(parents=True, exist_ok=True)

    duplicates = [
        i
        for i in [e["id"] for e in base["epics"]]
        + [f["id"] for f in base["features"]]
        + [r["id"] for r in base["reqs"]]
        if len(list(OUT.glob(f"{i}-*.md"))) > 1
    ]
    if duplicates:
        for item_id in duplicates:
            print(
                f"ERROR: several working files for {item_id}: "
                + ", ".join(p.name for p in sorted(OUT.glob(f"{item_id}-*.md"))),
                file=sys.stderr,
            )
        return 2

    created = kept = differing = 0
    for _item_id, path, content in planned_files(base):
        rel = path.relative_to(ROOT).as_posix()
        if path.exists():
            kept += 1
            same = read_text(path) == content
            differing += not same
            note = "" if same else " (differs from a fresh import: lifecycle edits are kept)"
            print(f"kept: {rel}{note}")
            continue
        created += 1
        if args.check:
            print(f"would create: {rel}")
        else:
            write_text(path, content)
            print(f"created: {rel}")

    # The mapping names the working files, so it is generated after they exist.
    mapping = mapping_content(base)
    rel = MAPPING.relative_to(ROOT).as_posix()
    current = read_text(MAPPING) if MAPPING.exists() else None
    mapping_stale = current != mapping
    if not mapping_stale:
        print(f"unchanged: {rel}")
    elif args.check:
        print(f"would {'create' if current is None else 'regenerate'}: {rel}")
    else:
        write_text(MAPPING, mapping)
        print(f"{'created' if current is None else 'regenerated'}: {rel}")

    total = len(base["epics"]) + len(base["features"]) + len(base["reqs"])
    verb = "would create" if args.check else "created"
    print(
        f"Summary: {total} baseline items ({len(base['epics'])} epics,"
        f" {len(base['features'])} features, {len(base['reqs'])} requirements);"
        f" {verb} {created}, kept {kept}"
        f" ({differing} differ from a fresh import)."
    )
    if args.check and (created or mapping_stale):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
