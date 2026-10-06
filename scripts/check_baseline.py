#!/usr/bin/env python3
"""Verify the working requirement files against the immutable requirements baseline.

Usage:  python3 -I -B scripts/check_baseline.py   (no arguments; run by ./scripts/verify.sh)

Checks (rules: docs/requirements/README.md § Baseline import and integrity, § Canonical form):
  a  the SHA-256 of ai-video-editor-requirements/MANIFEST.json equals BASELINE_MANIFEST_SHA256,
     the trust anchor this script keeps outside the package; this script then verifies the
     manifest's inventory and the size and SHA-256 of every listed file itself, and only then runs
     ai-video-editor-requirements/tools/validate_package.py (package consistency) when that file's
     own bytes verified; together they prove the baseline is unchanged ("baseline changed"
     otherwise), and no package file takes part in proving it;
  b  every working file is in canonical form (scripts/reqfile.py, the one reader this script and
     scripts/evidence.py share): characters of the reader's allow-list, one frontmatter with the
     template's keys once each, the template's headings once each, no HTML comment, no other
     heading form, a dated Status log; so both gates and a Markdown reader see the same status,
     Description and criteria;
  c  every baseline epic, feature and requirement has exactly one working file in docs/requirements/
     with the same ID and title, and one number of a kind names one ID, whatever its zero padding;
     requirements keep the mapped type, priority and source, and their
     scope, parent, origins, scenarios and baseline path equal the baseline; their dependencies
     hold the baseline's and, beyond them, derived requirements only; an imported requirement
     never returns to proposed; epics and features keep
     their priority, goal and parent; scope future <=> status deferred; each
     parent lists its children in its own list section; an epic or feature is done, and a box of
     its acceptance section ticked, only when every child that is neither superseded nor deferred
     is done; IMPORT_MAPPING.md is current;
  d  every baseline acceptance criterion appears verbatim ("- [ ] AC-n <text>", ticked or unticked)
     unless a Status-log line records the change and names the text it covers: "AC-n changed
     [<mark>]: <reason>" for a reworded criterion, "AC-n removed: <reason>" for a removed one,
     "AC-n added [<mark>]: <reason>" for an added one and "Description changed [<mark>]: <reason>"
     for the Description (<mark>: reqfile.digest of the current text, printed by the error, so a
     later edit needs a new line); each is reported; the Acceptance criteria section holds
     criterion lines only; a criterion is ticked only while the requirement is done (or superseded
     after it was done);
  e  a superseded baseline requirement logs a "superseded" line and names a replacement that
     exists: for version one the replacement is version-one, undeferred, of a priority not below
     the baseline's; for future scope it is future-scope and deferred; either way it keeps the
     type, the source human, the origins and the scenarios, carries the Description and every
     baseline criterion verbatim, and the old file logs each difference ("AC-n dropped by <ID>:",
     "<ID> AC-m added [<mark>]:", "Description replaced by <ID> [<mark>]:"); a replacement under
     another milestone than the baseline gate is reported as a gate change; a baseline feature or
     epic is superseded only when every baseline child under it is superseded;
  f  no version-one requirement depends on a deferred or future-scope requirement, directly or
     through a superseded one; § Dependencies names the frontmatter dependencies; no dependency
     cycle; requirements added after the import (AVE-REQ-102 onward) are source derived (human
     for every requirement on the supersession chain of a human baseline requirement), carry
     scope and gate keys and stand in their parent's list;
  g  docs/ROADMAP.md lists every live version-one requirement exactly once, under the milestone
     its primary_gate names, and the exclusions in the Deferred group only; the lists are the
     lines with the template's labels, one of each per entry; every milestone entry holds one
     Status line "- **Status:** planned", "in-progress" or "done", and a milestone with Status
     done lists finished requirements only; fence lines follow the reader's rule;
  h  a summary: requirements by status and by gate, acceptance criteria ticked.
Output: "ERROR: <path>: <message>" per violation, then the summary and "OK: ..." or "FAILED: ...".
Exit:   0 no violations · 1 violations found · 2 usage, or a baseline unreadable before any violation.
Read-only; Python 3.8+ standard library only. The script runs in Python's isolated mode and loads
the import tool and the reader from their source text. For the isolated start `python3 -I -B`
(verify.sh and CI) no module path, bytecode cache or Python variable of the environment decides
what it checks. Started as `python3 scripts/check_baseline.py` or with -B alone, its first
statements restart it with -I -B before it imports anything else, so a module beside it, a module
on PYTHONPATH that it imports and a bytecode cache of its tools take no part. Code the interpreter
loads at its own start (a sitecustomize module on PYTHONPATH) runs before the first line of this
script: for every start other than the isolated one the Python variables of the environment are
local state the caller answers for.
"""

# AVE-REQ-093: these two imports and the restart are the first statements this script executes.
# For the starts the docstring names, the interpreter holds os and sys before it reads this file,
# so the restart needs no module from the script's directory, from PYTHONPATH or from a bytecode
# cache; every other import follows it.
import os
import sys

if not sys.flags.isolated:
    os.execv(sys.executable, [sys.executable, "-I", "-B", os.path.abspath(__file__), *sys.argv[1:]])

import hashlib
import json
import re
import subprocess
import types
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKDIR = ROOT / "docs" / "requirements"
ROADMAP = ROOT / "docs" / "ROADMAP.md"
IMPORTER = ROOT / "scripts" / "requirements" / "import_baseline.py"
READER = ROOT / "scripts" / "reqfile.py"


def load_source(name: str, path: Path):
    """Runs a repository tool from its source text: no bytecode cache decides what it does."""
    module = types.ModuleType(name)
    module.__file__ = str(path)
    sys.modules[name] = module
    exec(compile(path.read_bytes(), str(path), "exec"), module.__dict__)
    return module


reqfile = load_source("ave_reqfile", READER)

STATUSES = reqfile.STATUSES
ID_PATTERN = re.compile(r"^(AVE-EPIC-\d{2,}|AVE-FEAT-\d{3,}|AVE-REQ-\d{3,})-[a-z0-9-]+\.md$")
MILESTONE = re.compile(r"^### (M\d+) — ")
# The one Status line of a milestone entry (docs/ROADMAP.md § Milestone entry template).
MILESTONE_STATUS = re.compile(r"^- \*\*Status:\*\* (planned|in-progress|done)$")
# The requirement lists of an entry, by the template's labels: (group, key, label pattern).
ROADMAP_LISTS = (
    ("milestone", "listed", re.compile(r"^- \*\*Requirements \(dependency order\):\*\*(?: |$)")),
    ("milestone", "proposed", re.compile(r"^- \*\*Proposed during [A-Za-z0-9 ]+:\*\*(?: |$)")),
    ("deferred", "listed", re.compile(r"^- \*\*Requirements:\*\*(?: |$)")),
)
# A line that presents itself as a requirement list: any bullet, indentation and letter case.
LIST_LIKE = re.compile(r"^ *[-*+] +\*\*(?:requirements|proposed)", re.IGNORECASE)
# A ticked box of § Feature acceptance or § Success criteria, in any list form.
TICKED_BOX = re.compile(r"^ *(?:[-*+]|\d{1,9}[.)]) +\[[xX]\]")
ROADMAP_LINK = re.compile(r"\[(AVE-REQ-\d{3,})\]\(requirements/(AVE-REQ-\d{3,})-[a-z0-9-]+\.md\)")
DEPENDENCY_LINK = re.compile(r"\]\((AVE-REQ-\d{3,})-[a-z0-9-]+\.md\)")
PRIORITY_RANK = {"must": 3, "should": 2, "could": 1}
GATE = re.compile(r"^(M\d+|FUTURE)$")
# Highest baseline number per kind; later IDs are derived work.
BASELINE_MAX = {"EPIC": 10, "FEAT": 20, "REQ": 101}
# AVE-REQ-093: SHA-256 of ai-video-editor-requirements/MANIFEST.json for package v1.0. The manifest
# pins every other package file, and this value pins the manifest from outside the package. It
# changes only when the human supplies a new baseline version (docs/requirements/README.md
# § Baseline import and integrity).
BASELINE_MANIFEST_SHA256 = "140307b86ab7b9e070088adc469888fe8a7fbfdb5a0c4dffa2c6a04846696e05"

errors = []
notes = []


def error(path, message: str) -> None:
    rel = path.relative_to(ROOT).as_posix() if isinstance(path, Path) else str(path)
    errors.append(f"ERROR: {rel}: {message}")


def load_importer():
    """The import tool's baseline loader and value mappings (one definition for both scripts)."""
    return load_source("import_baseline", IMPORTER)


# --------------------------------------------------------------------------------------------
# Working file parsing
# --------------------------------------------------------------------------------------------


def load_working():
    files = {}
    for path in sorted(WORKDIR.rglob("AVE-*.md")):
        if path.parent != WORKDIR:
            error(
                path,
                "requirement files sit flat in docs/requirements/; a copy below it is read by no"
                " check",
            )
            continue
        if not ID_PATTERN.match(path.name):
            continue  # check-project-control.sh reports malformed names
        item = reqfile.read(path)
        files.setdefault(item.id, []).append(item)
    return files


def check_form(files) -> None:
    """Check b: every working file is in canonical form and its H1 names its ID and title."""
    for found in files.values():
        for item in found:
            for problem in item.problems:
                error(item.path, f"canonical form: {problem}")
            if item.get("id") != item.id:
                error(item.path, f"frontmatter id '{item.get('id')}' must equal {item.id}")
            if item.h1 != f"# {item.id} — {item.get('title')}":
                error(item.path, f"H1 must read '# {item.id} — {item.get('title')}'")


def check_numbers(files) -> None:
    """One number of a kind names one ID: AVE-REQ-0103 beside AVE-REQ-103 is a second file."""
    by_number = {}
    for found in files.values():
        for item in found:
            by_number.setdefault((item.kind, item.number), []).append(item)
    for (kind, number), items in sorted(by_number.items()):
        if len({item.id for item in items}) > 1:
            error(
                WORKDIR,
                f"AVE-{kind} number {number} names several working files ("
                + ", ".join(sorted(item.path.name for item in items))
                + "); a number is allocated once per kind, whatever its zero padding",
            )


def marker_error(item, what: str, marker: str) -> None:
    error(
        item.path,
        f"{what} and the Status log has no line '- <date> — <status> — {marker}: <reason>'",
    )


# --------------------------------------------------------------------------------------------
# Checks
# --------------------------------------------------------------------------------------------


def check_manifest_pin(pkg: Path) -> None:
    """The manifest equals the pinned hash and is the only file the package inventory skips."""
    manifest = pkg / "MANIFEST.json"
    try:
        actual = hashlib.sha256(manifest.read_bytes()).hexdigest()
    except OSError:
        error(manifest, "baseline changed: the manifest is missing or unreadable")
        return
    for extra in sorted(pkg.rglob("MANIFEST.json")):
        if extra != manifest:
            error(extra, "baseline changed: a file the package inventory skips was added")
    if actual != BASELINE_MANIFEST_SHA256:
        error(
            manifest,
            f"baseline changed: SHA-256 {actual} differs from the pinned"
            f" {BASELINE_MANIFEST_SHA256} (BASELINE_MANIFEST_SHA256 in scripts/check_baseline.py)",
        )
    else:
        print("Baseline manifest: PASS (SHA-256 equals the value pinned in check_baseline.py)")


def check_package_files(pkg: Path) -> bool:
    """Verify the manifest's inventory and every file's size and SHA-256 from outside the package.

    The package validator repeats this check, but it is a package file itself: an edited validator
    must fail here, before it runs (AVE-REQ-093 AC-1, AC-3). Returns whether the validator's own
    bytes equal its manifest entry, so the caller runs only an unchanged validator.
    """
    manifest = pkg / "MANIFEST.json"
    try:
        inventory = json.loads(manifest.read_text(encoding="utf-8"))["files"]
        entries = {str(item["path"]): (int(item["bytes"]), str(item["sha256"])) for item in inventory}
    except (OSError, ValueError, KeyError, TypeError):
        error(manifest, "baseline changed: the manifest is unreadable or lists no files")
        return False
    if len(entries) != len(inventory):
        error(manifest, "baseline changed: the manifest lists a path twice")
    root = pkg.resolve()
    on_disk = set()
    for dirpath, dirnames, filenames in os.walk(pkg, followlinks=False):
        here = Path(dirpath)
        for name in sorted(dirnames + filenames):
            entry = here / name
            if entry.is_symlink():
                error(entry, "baseline changed: a symbolic link was added")
            elif name in filenames and name != "MANIFEST.json":
                on_disk.add(entry.relative_to(pkg).as_posix())
    for name in sorted(entries.keys() - on_disk):
        error(pkg / name, "baseline changed: the file is missing from the package")
    for name in sorted(on_disk - entries.keys()):
        error(pkg / name, "baseline changed: the file is absent from the manifest")
    verified = 0
    validator_ok = False
    for name in sorted(entries.keys() & on_disk):
        path = pkg / name
        try:
            path.resolve().relative_to(root)
        except ValueError:
            error(path, "baseline changed: the manifest path leaves the package")
            continue
        size, digest = entries[name]
        data = path.read_bytes()
        actual = hashlib.sha256(data).hexdigest()
        if actual != digest:
            error(path, f"baseline changed: SHA-256 {actual} differs from the manifest entry {digest}")
        elif len(data) != size:
            error(path, f"baseline changed: size {len(data)} differs from the manifest entry {size}")
        else:
            verified += 1
            validator_ok = validator_ok or name == "tools/validate_package.py"
    if verified == len(entries) == len(on_disk):
        print(
            f"Baseline files: PASS (check_baseline.py verified the size and SHA-256 of all {verified}"
            " manifest entries and found no other file)"
        )
    return validator_ok


def run_package_validator(pkg: Path) -> None:
    validator = pkg / "tools" / "validate_package.py"
    if not validator.is_file():
        error(validator, "package validator is missing")
        return
    result = subprocess.run(
        [sys.executable, "-I", "-B", str(validator), "--root", str(pkg)],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        detail = [line for line in (result.stderr or result.stdout).splitlines() if line.strip()]
        error(
            validator,
            f"package validation failed (exit {result.returncode}); the baseline changed"
            " or is incomplete",
        )
        errors.extend("       " + line for line in detail[:40])
    else:
        print("Baseline package: PASS (validate_package.py: consistency and MANIFEST.json hashes)")


def single_file(files, item_id: str, title: str):
    found = files.get(item_id, [])
    if len(found) != 1:
        where = ", ".join(f.path.name for f in found) or "none"
        error(
            WORKDIR,
            f"{item_id} must have exactly one working file {item_id}-<slug>.md (found: {where})",
        )
        return None
    item = found[0]
    if item.get("title") != title:
        error(
            item.path,
            f"frontmatter title '{item.get('title')}' must equal the baseline title '{title}'",
        )
    if item.get("status") not in STATUSES:
        error(item.path, f"invalid status '{item.get('status')}'")
    return item


def expect(item, key: str, expected, label: str = "the baseline") -> None:
    actual = item.flow(key) if isinstance(expected, list) else item.get(key)
    if actual != expected:
        shown = "[" + ", ".join(expected) + "]" if isinstance(expected, list) else expected
        error(item.path, f"frontmatter {key} '{item.get(key)}' must equal {label} value '{shown}'")


def lists_child(parent, child) -> bool:
    """The parent links the child from a list item of its own list section."""
    section = "Requirements" if parent.kind == "FEAT" else "Features"
    target = f"]({child.path.name})"
    return any(
        line.startswith("- [") and target in line for line in parent.sections.get(section, [])
    )


def chain_end(files, start: str):
    """Follows superseded_by from requirement <start>; returns (end file or None, IDs visited)."""
    seen, current = [], start
    while current and current not in seen:
        seen.append(current)
        found = files.get(current, [])
        if len(found) != 1 or found[0].kind != "REQ":
            return None, seen
        if found[0].get("status") != "superseded":
            return found[0], seen
        current = found[0].get("superseded_by")
    return None, seen


def check_parent_supersession(item, kind: str, child_kind: str, child_ids, files) -> None:
    """A baseline epic or feature leaves delivery only together with every baseline child."""
    for child_id in child_ids:
        found = files.get(child_id, [])
        status = found[0].get("status") if len(found) == 1 else "missing"
        if status != "superseded":
            error(
                item.path,
                f"a baseline {kind} is superseded only when every baseline {child_kind} under it"
                f" is superseded ({child_id} is '{status}')",
            )
            return


def check_epics_features(base, files) -> None:
    epic_files = {}
    for epic in base["epics"]:
        item = single_file(files, epic["id"], epic["title"])
        if item is None:
            continue
        epic_files[epic["id"]] = item
        future = all(r["scope"] == "future" for f in epic["features"] for r in f["reqs"])
        expect(item, "priority", "could" if future else "must")
        expect(item, "goals", [epic["goal"]])
        if future != (item.get("status") == "deferred"):
            error(item.path, "status must be deferred exactly when every child is future scope")
        if item.get("status") == "superseded":
            check_parent_supersession(item, "epic", "feature", [f["id"] for f in epic["features"]], files)
    for feature in base["features"]:
        item = single_file(files, feature["id"], feature["title"])
        if item is None:
            continue
        expect(item, "parent", feature["epic"])
        future = all(r["scope"] == "future" for r in feature["reqs"])
        expect(item, "priority", "could" if future else "must")
        if future != (item.get("status") == "deferred"):
            error(item.path, "status must be deferred exactly when every child is future scope")
        if item.get("status") == "superseded":
            check_parent_supersession(
                item, "feature", "requirement", [r["id"] for r in feature["reqs"]], files
            )
        parent = epic_files.get(feature["epic"])
        if parent is not None and not lists_child(parent, item):
            error(parent.path, f"§ Features must link {item.path.name}")


def check_parent_completion(files) -> None:
    """An epic or feature (baseline or derived) is done, and a box of its acceptance section
    ticked, only when every child that is neither superseded nor deferred is done."""
    children = {}
    for found in files.values():
        for item in found:
            if item.kind != "EPIC":
                children.setdefault(item.get("parent"), []).append(item)
    for item_id, found in sorted(files.items()):
        for item in found:
            if item.kind == "REQ":
                continue
            status = item.get("status")
            section = "Feature acceptance" if item.kind == "FEAT" else "Success criteria"
            was_done = "done" in item.log_statuses()
            ticked = any(TICKED_BOX.match(line) for line in item.sections.get(section, []))
            if ticked and not (was_done and status in ("done", "superseded")):
                error(
                    item.path,
                    f"a box of § {section} is ticked while status is '{status}'"
                    + ("" if was_done else " and the Status log has no done line")
                    + "; the boxes are ticked only while the file is done",
                )
            if status != "done":
                continue
            unfinished = [
                child
                for child in sorted(children.get(item_id, []), key=lambda child: child.path.name)
                if child.get("status") not in ("done", "superseded", "deferred")
            ]
            if unfinished:
                error(
                    item.path,
                    f"status done while {unfinished[0].id} is '{unfinished[0].get('status')}'"
                    f" ({len(unfinished)} unfinished of {len(children[item_id])} children); an"
                    " epic or feature is done only when every child that is neither superseded"
                    " nor deferred is done",
                )


def check_requirements(importer, base, files):
    """Checks b and c for the baseline requirements; returns the AC totals."""
    totals = Counter()
    imported = {r["id"] for r in base["reqs"]}
    # Successor ID -> every baseline criterion text of the baseline requirements it replaces.
    absorbed = {}
    for req in base["reqs"]:
        found = files.get(req["id"], [])
        if len(found) == 1 and found[0].get("status") == "superseded":
            successor, _seen = chain_end(files, found[0].get("superseded_by"))
            if successor is not None:
                texts = absorbed.setdefault(successor.id, set())
                texts.update(text for _id, text in req["criteria"])
    for req in base["reqs"]:
        item = single_file(files, req["id"], req["title"])
        if item is None:
            continue
        expect(item, "type", req["type"], "the mapped baseline")
        expect(item, "priority", req["priority"], "the mapped baseline")
        expect(item, "source", req["source"], "the origin-derived")
        expect(item, "parent", req["feature"])
        expect(item, "scope", req["scope"])
        expect(item, "origins", req["origins"])
        dependencies = item.flow("dependencies")
        if dependencies is None or [
            dep for dep in dependencies if dep in imported or dep.startswith(("AVE-FEAT", "AVE-EPIC"))
        ] != req["dependencies"]:
            error(
                item.path,
                f"frontmatter dependencies '{item.get('dependencies')}' must hold the baseline value"
                f" '[{', '.join(req['dependencies'])}]' and, beyond it, derived requirements only",
            )
        expect(item, "scenarios", req["scenarios"])
        expect(item, "baseline", importer.baseline_req_path(req["id"]))
        status = item.get("status")
        if req["scope"] == "future" and status not in ("deferred", "superseded"):
            error(item.path, f"future-scope requirement must stay deferred (status '{status}')")
        if req["scope"] == "v1" and status == "deferred":
            error(item.path, "version-one requirement cannot be deferred (baseline scope v1)")
        if status == "proposed":
            error(
                item.path,
                "an imported requirement starts ready and never returns to proposed (the"
                " lifecycle holds no such move)",
            )
        if item.get("primary_gate") != req["gate"]:
            notes.append(
                f"Gate change: {req['id']} primary_gate {item.get('primary_gate')}"
                f" (baseline {req['gate']})"
            )
        feature_file = files.get(req["feature"], [None])[0]
        if feature_file is not None and not lists_child(feature_file, item):
            error(feature_file.path, f"§ Requirements must link {item.path.name}")

        criteria = item.criteria()
        for ac_id, text in req["criteria"]:
            working = criteria.get(ac_id)
            if working is not None and working[1] == text:
                continue
            if working is None:
                what, marker = "is missing", f"{ac_id} removed"
            else:
                what = "differs from the baseline text"
                marker = f"{ac_id} changed [{reqfile.digest(working[1])}]"
            reason = item.recorded(marker)
            if reason:
                notes.append(f"Recorded change: {req['id']} {ac_id} {what} — {reason}")
            else:
                marker_error(item, f"{ac_id} {what}", marker)
        description = item.description()
        if description != req["statement"].strip():
            marker = f"Description changed [{reqfile.digest(description)}]"
            reason = item.recorded(marker)
            what = "is missing" if not description else "differs from the baseline statement"
            if reason:
                notes.append(f"Recorded change: {req['id']} Description {what} — {reason}")
            else:
                marker_error(item, f"Description {what}", marker)
        baseline_ids = {ac_id for ac_id, _ in req["criteria"]}
        for ac_id, (_ticked, text) in criteria.items():
            if ac_id in baseline_ids:
                continue
            marker = f"{ac_id} added [{reqfile.digest(text)}]"
            reason = item.recorded(marker)
            if reason:
                notes.append(f"Recorded addition: {req['id']} {ac_id} — {reason}")
            else:
                marker_error(item, f"{ac_id} is not a baseline criterion", marker)
        if status == "superseded":
            check_supersession(item, req, files, absorbed)
        scope = item.get("scope")
        for ticked, _text in criteria.values():
            totals["all"] += 1
            totals["ticked"] += ticked
            if scope == "v1":
                totals["v1"] += 1
                totals["v1_ticked"] += ticked
    return totals


def check_supersession(item, req, files, absorbed) -> None:
    """A superseded baseline requirement names a replacement that keeps its identity and criteria."""
    if "superseded" not in item.log_statuses():
        error(item.path, "Status log has no 'superseded' line with the reason")
    successor, seen = chain_end(files, item.get("superseded_by"))
    if successor is None:
        last = files.get(seen[-1], []) if seen else []
        if seen and (len(last) != 1 or last[0].kind != "REQ"):
            error(item.path, f"superseded_by {seen[-1]} has no working requirement file")
        else:
            error(
                item.path,
                f"superseded_by chain {' → '.join(seen) or '(empty)'} names no replacement",
            )
        return
    name = successor.id
    if successor.get("primary_gate") != req["gate"]:
        notes.append(
            f"Gate change: {req['id']} → {name} primary_gate {successor.get('primary_gate')}"
            f" (baseline {req['gate']})"
        )
    if req["scope"] == "future" and (
        successor.get("scope") != "future" or successor.get("status") != "deferred"
    ):
        error(
            item.path,
            f"a future-scope requirement cannot be superseded by {name} (scope"
            f" '{successor.get('scope')}', status '{successor.get('status')}'): entering version"
            " one is a product change the human makes with a new baseline",
        )
    if req["scope"] == "v1":
        if successor.get("scope") != "v1" or successor.get("status") == "deferred":
            error(
                item.path,
                f"a version-one requirement cannot be superseded by {name} (scope"
                f" '{successor.get('scope')}', status '{successor.get('status')}'): leaving version"
                " one is a product change",
            )
        if PRIORITY_RANK.get(successor.get("priority"), 0) < PRIORITY_RANK.get(req["priority"], 0):
            error(
                item.path,
                f"a baseline {req['priority']} requirement cannot be superseded by a"
                f" '{successor.get('priority')}' requirement ({name})",
            )
    if successor.get("type") != req["type"]:
        error(
            item.path,
            f"the successor {name} has type '{successor.get('type')}'; the baseline type is"
            f" '{req['type']}'",
        )
    if req["source"] == "human" and successor.get("source") != "human":
        error(
            item.path,
            f"the successor {name} of a human requirement keeps source human (it has"
            f" '{successor.get('source')}'), so its changes stay the human's to decide",
        )
    for key in ("origins", "scenarios"):
        lost = [value for value in req[key] if value not in (successor.flow(key) or [])]
        if lost:
            error(item.path, f"the successor {name} drops {key} {', '.join(lost)} of the baseline")
    flaws = 0
    description = successor.description()
    if description != req["statement"].strip():
        marker = f"Description replaced by {name} [{reqfile.digest(description)}]"
        reason = item.recorded(marker)
        if reason:
            notes.append(
                f"Recorded change: {req['id']} Description differs in the successor {name} —"
                f" {reason}"
            )
        else:
            flaws += 1
            marker_error(
                item,
                f"the Description of the successor {name} differs from the baseline statement",
                marker,
            )
    carried = {text for _ticked, text in successor.criteria().values()}
    for ac_id, text in req["criteria"]:
        if text in carried:
            continue
        marker = f"{ac_id} dropped by {name}"
        reason = item.recorded(marker)
        if reason:
            notes.append(
                f"Recorded change: {req['id']} {ac_id} is absent from the successor {name} —"
                f" {reason}"
            )
        else:
            flaws += 1
            marker_error(
                item, f"{ac_id} of the baseline is absent from the successor {name}", marker
            )
    known = absorbed.get(name, set())
    for ac_id, (_ticked, text) in successor.criteria().items():
        if text in known:
            continue
        marker = f"{name} {ac_id} added [{reqfile.digest(text)}]"
        reason = item.recorded(marker)
        if reason:
            notes.append(
                f"Recorded addition: {name} {ac_id} beside the criteria of {req['id']} — {reason}"
            )
        else:
            flaws += 1
            marker_error(
                item,
                f"{ac_id} of the successor {name} is no criterion of a requirement it replaces",
                marker,
            )
    if not flaws:
        notes.append(
            f"Supersession: {req['id']} → {name} carries the baseline Description and criteria or"
            " logs each change"
        )


def check_derived(base, files) -> None:
    """Working files added after the import: numbering, source and required keys."""
    baseline_ids = (
        {e["id"] for e in base["epics"]}
        | {f["id"] for f in base["features"]}
        | {r["id"] for r in base["reqs"]}
    )
    # Every requirement on the supersession chain of a human baseline requirement, the retired
    # ones in its middle included: each replaced a human requirement and keeps source human.
    human_successors = set()
    for req in base["reqs"]:
        found = files.get(req["id"], [])
        if req["source"] == "human" and len(found) == 1 and found[0].get("status") == "superseded":
            successor, seen = chain_end(files, found[0].get("superseded_by"))
            if successor is not None:
                human_successors.update(seen)
    for item_id, found in sorted(files.items()):
        if item_id in baseline_ids:
            continue
        if len(found) != 1:
            error(
                WORKDIR,
                f"{item_id} must have exactly one working file (found: "
                + ", ".join(item.path.name for item in found)
                + ")",
            )
        for item in found:
            if item.number <= BASELINE_MAX[item.kind]:
                error(
                    item.path,
                    f"{item_id} lies inside the baseline ID range but has no baseline entry;"
                    f" new {item.kind} IDs continue after {BASELINE_MAX[item.kind]}",
                )
            if item.kind != "REQ":
                continue
            expected = "human" if item_id in human_successors else "derived"
            if item.get("source") != expected:
                error(
                    item.path,
                    "a requirement added after the import has source derived, or human when it"
                    f" replaces a human baseline requirement (expected '{expected}')",
                )
            for key in ("scope", "primary_gate", "dependencies"):
                if key not in item.fm:
                    error(item.path, f"frontmatter {key} is missing")


def check_all_requirements(base, files):
    """Ticks, scope, gate, parent and dependencies of every working requirement (baseline and
    derived).

    check_requirements reports scope/status conflicts of the baseline requirements themselves.
    """
    imported = {r["id"] for r in base["reqs"]}
    reqs = {item_id: found[0] for item_id, found in files.items() if found[0].kind == "REQ"}
    for item_id, item in sorted(reqs.items()):
        scope, gate, status = item.get("scope"), item.get("primary_gate"), item.get("status")
        live = status not in ("deferred", "superseded")
        ticked = [ac_id for ac_id, (is_ticked, _text) in item.criteria().items() if is_ticked]
        was_done = "done" in item.log_statuses()
        if ticked and not (was_done and status in ("done", "superseded")):
            error(
                item.path,
                f"{ticked[0]} is ticked while status is '{status}'"
                + ("" if was_done else " and the Status log has no done line")
                + "; criteria are ticked only after a verify-requirement PASS, with status done,"
                " and a reopened requirement unticks them",
            )
        if status == "done" and "_TBD" in item.text:
            error(item.path, "status done but a _TBD placeholder remains (fenced text included)")
        if scope not in ("v1", "future"):
            error(item.path, f"frontmatter scope '{scope}' must be v1 or future")
        if not GATE.match(gate):
            error(item.path, f"frontmatter primary_gate '{gate}' must be M<n> or FUTURE")
        elif (gate == "FUTURE") != (scope == "future"):
            error(item.path, "primary_gate FUTURE belongs to future scope only")
        if item_id not in imported and status == "deferred" and scope != "future":
            error(item.path, "status deferred requires scope future")
        if (
            item_id not in imported
            and scope == "future"
            and status not in ("deferred", "superseded")
        ):
            error(item.path, f"future-scope requirement must be deferred (status '{status}')")
        parent = files.get(item.get("parent"), [None])[0]
        if parent is not None:
            if item_id not in imported and not lists_child(parent, item):
                section = "Requirements" if parent.kind == "FEAT" else "Features"
                error(parent.path, f"§ {section} must link {item.path.name}")
            if scope == "v1" and live and parent.get("status") == "deferred":
                error(item.path, f"a version-one requirement stands under the deferred {parent.id}")
        dependencies = item.flow("dependencies")
        if dependencies is None:
            if "dependencies" in item.fm:
                error(
                    item.path, "frontmatter dependencies must be a flow list such as [AVE-REQ-012]"
                )
            continue
        linked = set()
        for line in item.sections.get("Dependencies", []):
            linked.update(DEPENDENCY_LINK.findall(line))
        if linked != set(dependencies):
            error(
                item.path,
                "§ Dependencies links "
                + (", ".join(sorted(linked)) or "no requirement")
                + " while frontmatter dependencies names "
                + (", ".join(sorted(dependencies)) or "none"),
            )
        for dep in dependencies:
            target = reqs.get(dep)
            if target is None:
                error(item.path, f"dependency {dep} has no working requirement file")
                continue
            if dep == item_id:
                error(item.path, f"{item_id} depends on itself")
            if scope != "v1" or not live:
                continue
            end, _seen = chain_end(files, dep)
            if target.get("status") == "deferred":
                error(item.path, f"version-one requirement depends on deferred {dep}")
            elif target.get("scope") == "future":
                error(item.path, f"version-one requirement depends on the future-scope {dep}")
            elif end is None or end.get("status") == "deferred" or end.get("scope") == "future":
                error(
                    item.path,
                    f"version-one requirement depends on {dep}, whose replacement is"
                    f" {'missing' if end is None else 'the deferred ' + end.id}",
                )
    check_dependency_cycles(reqs)
    return reqs


def check_dependency_cycles(reqs) -> None:
    """Reports every requirement that reaches itself through frontmatter dependencies."""
    graph = {
        item_id: [dep for dep in (item.flow("dependencies") or []) if dep in reqs]
        for item_id, item in reqs.items()
    }
    for start in sorted(graph):
        stack, seen = [(dep, [start, dep]) for dep in graph[start] if dep != start], set()
        while stack:
            node, path = stack.pop()
            if node == start:
                error(reqs[start].path, "dependency cycle: " + " → ".join(path))
                break
            if node in seen:
                continue
            seen.add(node)
            stack.extend((dep, [*path, dep]) for dep in graph[node])


def read_roadmap():
    """The milestone entries of docs/ROADMAP.md: (milestone -> entry, problems).

    entry: {"status": the word of the entry's Status line, "listed": [IDs of its requirement
    list], "proposed": [IDs of its 'Proposed during' line]}; the Deferred group is the entry
    FUTURE. The gate reads the lines with the template's labels (ROADMAP_LISTS), one of each per
    entry, and the one Status line of a milestone entry (MILESTONE_STATUS); fence lines follow
    the rule of the requirement files, so a list the gate reads is a list readers see.
    """
    entries, problems = {}, []
    current, name, fenced = None, "", False
    text = ROADMAP.read_text(encoding="utf-8")
    if "<!--" in text:
        problems.append("an HTML comment (<!--) hides text from readers; the roadmap holds none")
    for number, line in enumerate(text.split("\n"), 1):
        if fenced:
            if line == reqfile.FENCE_CLOSE:
                fenced = False
            elif reqfile.FENCE_LIKE.match(line):
                problems.append(
                    f"line {number}: a fenced block closes with ``` at column 0 and holds no other"
                    " fence line"
                )
            continue
        if reqfile.FENCE_LIKE.match(line):
            if reqfile.FENCE_OPEN.match(line):
                fenced = True
            else:
                problems.append(
                    f"line {number}: a fence line reads ``` or ```<language> at column 0"
                    f" ('{line[:20]}'); a list inside any other fence is a code sample to readers"
                )
            continue
        match = MILESTONE.match(line)
        if match or line.startswith("### Deferred "):
            name = match.group(1) if match else "FUTURE"
            if name in entries:
                problems.append(f"milestone {name} has two entries")
            current = entries.setdefault(
                name, {"status": "", "status_lines": 0, "listed": [], "proposed": [], "lists": []}
            )
            continue
        if line.startswith("#"):
            current = None
            continue
        if current is None:
            continue
        where = "the Deferred group" if name == "FUTURE" else f"milestone {name}"
        if name != "FUTURE" and "**status" in line.lower():
            current["status_lines"] += 1
            match = MILESTONE_STATUS.match(line)
            if match:
                current["status"] = match.group(1)
            else:
                problems.append(
                    f"{where}: the Status line reads '- **Status:** planned', 'in-progress' or"
                    f" 'done' and nothing else ('{line[:60]}')"
                )
            continue
        group = "deferred" if name == "FUTURE" else "milestone"
        key = next((k for g, k, label in ROADMAP_LISTS if g == group and label.match(line)), None)
        label = line.split(":**")[0] + ":**" if ":**" in line else line[:60]
        if key is None:
            if LIST_LIKE.match(line):
                problems.append(
                    f"{where}: '{label}' is no requirement-list label of the template"
                    " ('- **Requirements (dependency order):**' and"
                    " '- **Proposed during <reviews>:**' under a milestone,"
                    " '- **Requirements:**' in the Deferred group)"
                )
            continue
        if key in current["lists"]:
            problems.append(f"{where} holds two '{label}' lines; an entry holds one list of a kind")
        current["lists"].append(key)
        for text_id, target_id in ROADMAP_LINK.findall(line):
            if text_id != target_id:
                problems.append(f"the link text {text_id} names another file than {target_id}")
            current[key].append(target_id)
    if fenced:
        problems.append("a fenced block stays open at the end of the file")
    for name, entry in entries.items():
        if name != "FUTURE" and entry["status_lines"] != 1:
            problems.append(
                f"milestone {name} holds {entry['status_lines']} Status lines; every milestone"
                " entry holds one, '- **Status:** planned', 'in-progress' or 'done'"
            )
    return entries, problems


def check_roadmap(reqs) -> None:
    """Check g: the roadmap schedules every live version-one requirement under its gate."""
    if not ROADMAP.is_file():
        error(ROADMAP, "missing; every version-one requirement stands on a milestone list")
        return
    entries, problems = read_roadmap()
    for problem in problems:
        error(ROADMAP, problem)
    places = {}
    for name, entry in entries.items():
        for key in ("listed", "proposed"):
            for item_id in entry[key]:
                places.setdefault(item_id, []).append((name, key))
    for item_id in sorted(places):
        if item_id not in reqs:
            error(ROADMAP, f"{item_id} is listed and has no working requirement file")
    for item_id, item in sorted(reqs.items()):
        status, scope, gate = item.get("status"), item.get("scope"), item.get("primary_gate")
        found = places.get(item_id, [])
        if status == "superseded":
            continue
        if len(found) != 1:
            where = ", ".join(name for name, _key in found) or "no list"
            error(
                ROADMAP,
                f"{item_id} stands on {where}; a requirement that is not superseded stands on"
                " exactly one requirement list",
            )
            continue
        name, key = found[0]
        if scope == "future":
            if name != "FUTURE":
                error(
                    ROADMAP,
                    f"the exclusion {item_id} stands under {name}; it belongs to the Deferred group",
                )
            continue
        if name == "FUTURE":
            error(ROADMAP, f"the version-one requirement {item_id} stands in the Deferred group")
        elif gate not in entries:
            error(item.path, f"primary_gate {gate} names no milestone of docs/ROADMAP.md")
        elif name != gate:
            error(ROADMAP, f"{item_id} stands under {name} while its primary_gate is {gate}")
        elif key == "proposed" and status != "proposed":
            error(
                ROADMAP,
                f"{item_id} is '{status}' and still stands on a 'Proposed during' line of {name};"
                " it moves to the milestone's requirement list",
            )
        elif entries[name]["status"] == "done" and status != "done":
            error(ROADMAP, f"milestone {name} has Status done while {item_id} is '{status}'")


def check_mapping(importer, base) -> None:
    mapping = importer.MAPPING
    if not mapping.is_file():
        error(mapping, "missing; run python3 scripts/requirements/import_baseline.py")
    elif importer.read_text(mapping) != importer.mapping_content(base):
        error(
            mapping, "stale; run python3 scripts/requirements/import_baseline.py to regenerate it"
        )


def gate_key(gate: str):
    return (1, 0) if not gate.startswith("M") or not gate[1:].isdigit() else (0, int(gate[1:]))


def print_summary(reqs, totals) -> None:
    statuses = Counter(item.get("status") for item in reqs.values())
    print(f"Working requirements: {len(reqs)}")
    print("  by status: " + ", ".join(f"{s} {statuses[s]}" for s in STATUSES if statuses[s]))
    gates = {}
    for item in reqs.values():
        gates.setdefault(item.get("primary_gate"), Counter())[item.get("status")] += 1
    ordered = sorted(gates.items(), key=lambda g: gate_key(g[0]))
    print(
        "  by gate:   " + "; ".join(f"{g} {sum(c.values())} ({c['done']} done)" for g, c in ordered)
    )
    print(
        f"Acceptance criteria ticked: {totals['ticked']} of {totals['all']}"
        f" (version one: {totals['v1_ticked']} of {totals['v1']})"
    )
    for note in notes:
        print(note)


def main() -> int:
    if len(sys.argv) > 1:
        print("Usage: python3 -I -B scripts/check_baseline.py (no arguments)", file=sys.stderr)
        return 2
    try:
        importer = load_importer()
    except (OSError, SyntaxError, ImportError) as exc:
        print(
            f"ERROR: {IMPORTER.relative_to(ROOT)}: cannot load the import tool: {exc}",
            file=sys.stderr,
        )
        return 2
    check_manifest_pin(importer.PKG)
    if check_package_files(importer.PKG):
        run_package_validator(importer.PKG)
    try:
        base = importer.load_baseline()
    except (importer.BaselineError, KeyError, TypeError, ValueError, OSError) as exc:
        print("\n".join(errors))
        print(f"ERROR: {importer.PKG_NAME}: unreadable baseline: {exc}", file=sys.stderr)
        return 1 if any(line.startswith("ERROR:") for line in errors) else 2
    files = load_working()
    check_form(files)
    check_numbers(files)
    check_epics_features(base, files)
    check_parent_completion(files)
    totals = check_requirements(importer, base, files)
    check_derived(base, files)
    reqs = check_all_requirements(base, files)
    check_roadmap(reqs)
    check_mapping(importer, base)
    print_summary(reqs, totals)
    for line in errors:
        print(line)
    count = sum(line.startswith("ERROR:") for line in errors)
    if count:
        print(f"FAILED: {count} baseline integrity error(s)")
        return 1
    print(
        f"OK: baseline intact; {len(base['epics'])} epics, {len(base['features'])} features and"
        f" {len(base['reqs'])} requirements match their working files"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
