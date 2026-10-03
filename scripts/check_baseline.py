#!/usr/bin/env python3
"""Verify the working requirement files against the immutable requirements baseline.

Usage:  python3 scripts/check_baseline.py      (no arguments; run by ./scripts/verify.sh)

Checks (rules: docs/requirements/README.md § Baseline import and integrity):
  a  the SHA-256 of ai-video-editor-requirements/MANIFEST.json equals BASELINE_MANIFEST_SHA256,
     the trust anchor this script keeps outside the package ("baseline changed" otherwise), and
     ai-video-editor-requirements/tools/validate_package.py passes: package consistency and the
     manifest's SHA-256 hash of every file; together they prove the baseline is unchanged;
  b  every baseline epic, feature and requirement has exactly one working file in docs/requirements/
     with the same ID and title; requirements keep the mapped type, priority and source, and their
     scope, parent, dependencies, origins, scenarios and baseline path equal the baseline; scope
     future <=> status deferred; each parent lists its baseline children; IMPORT_MAPPING.md is
     current;
  c  every baseline acceptance criterion appears verbatim ("- [ ] AC-n <text>", ticked or unticked)
     unless the file's Status log records "AC-n changed: <reason>" (reported as a recorded change);
     additional working criteria are allowed and reported; the Description equals the baseline
     statement unless the Status log records "Description changed: <reason>" (reported likewise);
  d  no deferred requirement is a dependency of a version-one working requirement; requirements
     added after the import (AVE-REQ-102 onward) are source derived and carry scope and gate keys;
  e  a summary: requirements by status and by gate, acceptance criteria ticked.
Output: "ERROR: <path>: <message>" per violation, then the summary and "OK: ..." or "FAILED: ...".
Exit:   0 no violations · 1 violations found · 2 usage or unreadable baseline.
Read-only; Python 3.8+ standard library only.
"""

from __future__ import annotations

import hashlib
import importlib.util
import re
import subprocess
import sys
from collections import Counter, OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKDIR = ROOT / "docs" / "requirements"
IMPORTER = ROOT / "scripts" / "requirements" / "import_baseline.py"

STATUSES = (
    "proposed",
    "ready",
    "in-progress",
    "verification",
    "done",
    "blocked",
    "superseded",
    "deferred",
)
ID_PATTERN = re.compile(r"^(AVE-EPIC-\d{2,}|AVE-FEAT-\d{3,}|AVE-REQ-\d{3,})-[a-z0-9-]+\.md$")
AC_LINE = re.compile(r"^- \[([ xX])\] (AC-\d+) (.*)$")
LOG_LINE = re.compile(r"^- \d{4}-\d{2}-\d{2} — ")
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
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("import_baseline", IMPORTER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# --------------------------------------------------------------------------------------------
# Working file parsing
# --------------------------------------------------------------------------------------------


class Working:
    """One working EPIC/FEAT/REQ file: frontmatter, H1, sections (outside code fences)."""

    def __init__(self, path: Path):
        self.path = path
        match = re.match(r"^(AVE-(EPIC|FEAT|REQ)-(\d+))-", path.name)
        self.id, self.kind, self.number = match.group(1), match.group(2), int(match.group(3))
        text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
        lines = text.split("\n")
        self.fm = OrderedDict()
        body_start = 0
        if lines and lines[0].strip() == "---":
            for index in range(1, len(lines)):
                if lines[index].strip() == "---":
                    body_start = index + 1
                    break
                match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", lines[index])
                if match:
                    value = match.group(2).strip()
                    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                        value = value[1:-1]  # the project-control checker unquotes values too
                    self.fm[match.group(1)] = value
        self.h1 = ""
        self.sections = OrderedDict()
        self.raw_sections = OrderedDict()  # the same sections with their fenced lines
        current = None
        fence = ""
        for line in lines[body_start:]:
            stripped = line.lstrip(" ")
            marker = re.match(r"^(`{3,}|~{3,})", stripped)
            if (fence or marker) and current is not None:
                self.raw_sections[current].append(line.rstrip())
            if fence:
                if marker and marker.group(1)[0] == fence[0] and len(marker.group(1)) >= len(fence):
                    fence = ""
                continue
            if marker:
                fence = marker.group(1)
                continue
            if line.startswith("# ") and not self.h1:
                self.h1 = line.rstrip()
            elif line.startswith("## "):
                current = line[3:].strip()
                self.sections.setdefault(current, [])
                self.raw_sections.setdefault(current, [])
            elif current is not None:
                self.sections[current].append(line.rstrip())
                self.raw_sections[current].append(line.rstrip())
        self.text = text

    def get(self, key: str) -> str:
        return self.fm.get(key, "")

    def flow(self, key: str):
        value = self.get(key)
        if not (value.startswith("[") and value.endswith("]")):
            return None
        inner = value[1:-1].strip()
        return [item.strip() for item in inner.split(",")] if inner else []

    def criteria(self):
        """AC ID -> (ticked, text) in file order; duplicate IDs are reported."""
        found = OrderedDict()
        for line in self.sections.get("Acceptance criteria", []):
            match = AC_LINE.match(line)
            if not match:
                continue
            ac_id = match.group(2)
            if ac_id in found:
                error(self.path, f"duplicate acceptance criterion {ac_id}")
                continue
            found[ac_id] = (match.group(1) in "xX", match.group(3))
        return found

    def log(self):
        return [line for line in self.sections.get("Status", []) if LOG_LINE.match(line)]

    def description(self) -> str:
        """The whole ## Description section, fenced blocks included."""
        return "\n".join(self.raw_sections.get("Description", [])).strip()

    def recorded_change(self, subject: str) -> str:
        """The reason of the Status-log line '<subject> changed: <reason>' (AC-n or Description)."""
        pattern = re.compile(r"(?<![A-Za-z0-9-])" + re.escape(subject) + r" changed:\s*(\S.*)$")
        for line in self.log():
            match = pattern.search(line)
            if match:
                return match.group(1)
        return ""


def load_working():
    files = {}
    for path in sorted(WORKDIR.glob("AVE-*.md")):
        if not ID_PATTERN.match(path.name):
            continue  # check-project-control.sh reports malformed names
        item = Working(path)
        files.setdefault(item.id, []).append(item)
    return files


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


def run_package_validator(pkg: Path) -> None:
    validator = pkg / "tools" / "validate_package.py"
    if not validator.is_file():
        error(validator, "package validator is missing")
        return
    result = subprocess.run(
        [sys.executable, "-B", str(validator), "--root", str(pkg)],
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
    if item.get("id") != item_id:
        error(item.path, f"frontmatter id '{item.get('id')}' must equal {item_id}")
    if item.get("title") != title:
        error(
            item.path,
            f"frontmatter title '{item.get('title')}' must equal the baseline title '{title}'",
        )
    if item.h1 != f"# {item_id} — {title}":
        error(item.path, f"H1 must read '# {item_id} — {title}'")
    if item.get("status") not in STATUSES:
        error(item.path, f"invalid status '{item.get('status')}'")
    return item


def expect(item, key: str, expected, label: str = "the baseline") -> None:
    actual = item.flow(key) if isinstance(expected, list) else item.get(key)
    if actual != expected:
        shown = "[" + ", ".join(expected) + "]" if isinstance(expected, list) else expected
        error(item.path, f"frontmatter {key} '{item.get(key)}' must equal {label} value '{shown}'")


def lists_child(parent, child) -> bool:
    return f"]({child.path.name})" in parent.text


def check_epics_features(base, files) -> None:
    epic_files = {}
    for epic in base["epics"]:
        item = single_file(files, epic["id"], epic["title"])
        if item is None:
            continue
        epic_files[epic["id"]] = item
        future = all(r["scope"] == "future" for f in epic["features"] for r in f["reqs"])
        if future != (item.get("status") == "deferred"):
            error(item.path, "status must be deferred exactly when every child is future scope")
    for feature in base["features"]:
        item = single_file(files, feature["id"], feature["title"])
        if item is None:
            continue
        expect(item, "parent", feature["epic"])
        future = all(r["scope"] == "future" for r in feature["reqs"])
        if future != (item.get("status") == "deferred"):
            error(item.path, "status must be deferred exactly when every child is future scope")
        parent = epic_files.get(feature["epic"])
        if parent is not None and not lists_child(parent, item):
            error(parent.path, f"§ Features must link {item.path.name}")


def check_requirements(importer, base, files):
    """Checks b and c for the baseline requirements; returns the AC totals."""
    totals = Counter()
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
        expect(item, "dependencies", req["dependencies"])
        expect(item, "scenarios", req["scenarios"])
        expect(item, "baseline", importer.baseline_req_path(req["id"]))
        status = item.get("status")
        if req["scope"] == "future" and status not in ("deferred", "superseded"):
            error(item.path, f"future-scope requirement must stay deferred (status '{status}')")
        if req["scope"] == "v1" and status == "deferred":
            error(item.path, "version-one requirement cannot be deferred (baseline scope v1)")
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
            reason = item.recorded_change(ac_id)
            what = "is missing" if working is None else "differs from the baseline text"
            if reason:
                notes.append(f"Recorded change: {req['id']} {ac_id} {what} — {reason}")
            else:
                error(
                    item.path,
                    f"{ac_id} {what} and the Status log has no '{ac_id} changed: <reason>' line",
                )
        description = item.description()
        if description != req["statement"].strip():
            reason = item.recorded_change("Description")
            what = "is missing" if not description else "differs from the baseline statement"
            if reason:
                notes.append(f"Recorded change: {req['id']} Description {what} — {reason}")
            else:
                error(
                    item.path,
                    f"Description {what} and the Status log has no"
                    " 'Description changed: <reason>' line",
                )
        baseline_ids = {ac_id for ac_id, _ in req["criteria"]}
        for ac_id in criteria:
            if ac_id not in baseline_ids:
                notes.append(f"Additional criterion: {req['id']} {ac_id}")
        scope = item.get("scope")
        for ticked, _text in criteria.values():
            totals["all"] += 1
            totals["ticked"] += ticked
            if scope == "v1":
                totals["v1"] += 1
                totals["v1_ticked"] += ticked
    return totals


def check_derived(base, files) -> None:
    """Working files added after the import: numbering, source and required keys."""
    baseline_ids = (
        {e["id"] for e in base["epics"]}
        | {f["id"] for f in base["features"]}
        | {r["id"] for r in base["reqs"]}
    )
    for item_id, found in sorted(files.items()):
        if item_id in baseline_ids:
            continue
        for item in found:
            if item.number <= BASELINE_MAX[item.kind]:
                error(
                    item.path,
                    f"{item_id} lies inside the baseline ID range but has no baseline entry;"
                    f" new {item.kind} IDs continue after {BASELINE_MAX[item.kind]}",
                )
            if item.kind != "REQ":
                continue
            if item.get("source") != "derived":
                error(item.path, "a requirement added after the import has source derived")
            for key in ("scope", "primary_gate", "dependencies"):
                if key not in item.fm:
                    error(item.path, f"frontmatter {key} is missing")


def check_all_requirements(base, files):
    """Scope, gate and deferred dependencies of every working requirement (baseline and derived).

    check_requirements reports scope/status conflicts of the baseline requirements themselves.
    """
    imported = {r["id"] for r in base["reqs"]}
    reqs = {item_id: found[0] for item_id, found in files.items() if found[0].kind == "REQ"}
    for item_id, item in sorted(reqs.items()):
        scope, gate, status = item.get("scope"), item.get("primary_gate"), item.get("status")
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
        dependencies = item.flow("dependencies")
        if dependencies is None:
            if "dependencies" in item.fm:
                error(
                    item.path, "frontmatter dependencies must be a flow list such as [AVE-REQ-012]"
                )
            continue
        for dep in dependencies:
            target = reqs.get(dep)
            if target is None:
                error(item.path, f"dependency {dep} has no working requirement file")
            elif (
                scope == "v1"
                and status not in ("deferred", "superseded")
                and target.get("status") == "deferred"
            ):
                error(item.path, f"version-one requirement depends on deferred {dep}")
    return reqs


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
        print("Usage: python3 scripts/check_baseline.py (no arguments)", file=sys.stderr)
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
    run_package_validator(importer.PKG)
    try:
        base = importer.load_baseline()
    except (importer.BaselineError, KeyError, TypeError, ValueError, OSError) as exc:
        print("\n".join(errors))
        print(f"ERROR: {importer.PKG_NAME}: unreadable baseline: {exc}", file=sys.stderr)
        return 2
    files = load_working()
    check_epics_features(base, files)
    totals = check_requirements(importer, base, files)
    check_derived(base, files)
    reqs = check_all_requirements(base, files)
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
