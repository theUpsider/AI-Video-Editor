#!/usr/bin/env python3
"""Validate this requirements package, not an implemented media application.

Usage: python3 tools/validate_package.py [--root PACKAGE] [--skip-manifest]
The final archive requires no third-party Python dependencies. --skip-manifest is
for package authors while assembling an inventory; do not use it for intake.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path
from urllib.parse import unquote, urlsplit


def validate(root: Path, skip_manifest: bool = False) -> tuple[list[str], dict[str, int]]:
    errors: list[str] = []
    counts: dict[str, int] = {}

    def check(ok: bool, message: str) -> None:
        if not ok:
            errors.append(message)

    def load(relative: str):
        path = root / relative
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            errors.append(f"Cannot read {relative}: {exc}")
            return None

    required = (
        "README.md", "IMPLEMENTATION_PROMPT.md", "RESUME_PROMPT.md",
        "LAUNCHER_PROMPT.txt", "intake/USER_BRIEF.md", "spec/PRODUCT.md",
        "spec/SCOPE_AND_ASSUMPTIONS.md", "spec/REQUIREMENTS_INDEX.md",
        "spec/EPICS_AND_FEATURES.md", "spec/TRACEABILITY.md",
        "spec/DATA_AND_TIMING_MODEL.md", "spec/EDITING_API.md",
        "spec/ACCEPTANCE_TESTS.md", "spec/TECHNICAL_DEFAULTS.md",
        "spec/ROADMAP.md", "spec/AGENT_WORKFLOW.md", "spec/THREAT_MODEL.md",
        "spec/DELIVERY_CHECKLIST.md", "spec/SOURCES.md", "workflow/INSTALLATION.md",
        "workflow/ai-video-editor-delivery/SKILL.md", "workflow/skill.zip",
        "tools/validate_package.py",
    )
    for name in required:
        check((root / name).is_file(), f"Required file missing: {name}")

    rd = load("spec/requirements.json")
    fd = load("spec/features.json")
    clauses = load("spec/source_clauses.json")
    ad = load("spec/acceptance_scenarios.json")
    sources = load("spec/sources.json")
    if any(item is None for item in (rd, fd, clauses, ad, sources)):
        return errors, counts
    if not (isinstance(rd, dict) and isinstance(fd, dict) and isinstance(clauses, dict)
            and isinstance(ad, dict) and isinstance(sources, list)):
        errors.append("Unexpected top-level JSON types.")
        return errors, counts

    reqs = rd.get("requirements", [])
    features = fd.get("features", [])
    scenarios = ad.get("scenarios", [])
    check(all(isinstance(x, dict) for x in reqs + features + scenarios + sources),
          "An entity list contains a non-object.")
    if errors and not all(isinstance(x, dict) for x in reqs + features + scenarios + sources):
        return errors, counts

    def index(items: list[dict], label: str) -> dict[str, dict]:
        ids = [x.get("id") for x in items]
        check(all(isinstance(x, str) and x for x in ids), f"Invalid {label} IDs")
        check(len(ids) == len(set(ids)), f"Duplicate {label} IDs")
        return {x["id"]: x for x in items if isinstance(x.get("id"), str)}

    ri, fi, ai, si = (index(reqs, "requirement"), index(features, "feature"),
                       index(scenarios, "scenario"), index(sources, "source"))
    expected_r = {f"AVE-REQ-{n:03d}" for n in range(1, 102)}
    expected_a = {f"AT-{n:02d}" for n in range(1, 32)}
    check(set(ri) == expected_r, "Requirement IDs must be AVE-REQ-001 through AVE-REQ-101")
    check(set(fi) == {f"AVE-FEAT-{n:03d}" for n in range(1, 21)}, "Feature ID set mismatch")
    check(set(ai) == expected_a, "Acceptance scenario ID set mismatch")
    check(set(si) == {f"SRC-{n:02d}" for n in range(1, 24)}, "Primary reference ID set mismatch")
    expected_clauses = {f"U{n:02d}" for n in range(1, 28)} | {f"D{n:02d}" for n in range(1, 6)}
    check(set(clauses) == expected_clauses, "User/derived clause ID set mismatch")
    check(ad.get("status") == "specification_only_not_executed", "Scenario execution disclaimer missing")
    epics = {f"AVE-EPIC-{n}" for n in fd.get("epics", {})}
    check(len(epics) == 10, "Expected ten epics")
    for feature in features:
        check(feature.get("epic") in epics, f"Unknown parent epic: {feature.get('id')}")

    coverage: set[str] = set()
    criteria_total = 0
    graph: dict[str, list[str]] = {}
    for rid, req in ri.items():
        feature = req.get("feature")
        check(feature in fi, f"{rid}: unknown feature {feature}")
        check(req.get("epic") == fi.get(feature, {}).get("epic"), f"{rid}: parent epic mismatch")
        origins = req.get("origins", [])
        deps = req.get("dependencies", [])
        tests = req.get("scenarios", [])
        criteria = req.get("acceptance_criteria", [])
        check(bool(origins), f"{rid}: missing source traceability")
        check(set(origins) <= set(clauses), f"{rid}: unknown source clause")
        coverage.update(origins)
        check(len(deps) == len(set(deps)), f"{rid}: duplicate dependencies")
        check(set(deps) <= set(ri), f"{rid}: unknown dependency")
        check(rid not in deps, f"{rid}: depends on itself")
        graph[rid] = deps
        check(bool(tests) and set(tests) <= set(ai), f"{rid}: missing/unknown scenario")
        check(bool(criteria), f"{rid}: missing acceptance criteria")
        check([x.get("id") for x in criteria] == [f"AC-{i}" for i in range(1, len(criteria) + 1)],
              f"{rid}: criterion IDs out of sequence")
        check(all(isinstance(x.get("text"), str) and x["text"].strip() for x in criteria),
              f"{rid}: empty criterion")
        criteria_total += len(criteria)
        future = rid in {"AVE-REQ-067", "AVE-REQ-101"}
        check(req.get("scope") == ("future" if future else "v1"), f"{rid}: incorrect scope")
        check(req.get("status") == ("deferred" if future else "ready"), f"{rid}: incorrect initial status")
        check(req.get("priority") == ("future" if future else "must"), f"{rid}: incorrect initial priority")
        check(req.get("milestone") in ({"FUTURE"} if future else {f"M{x}" for x in range(8)}),
              f"{rid}: invalid primary gate")
        if not future:
            check(not any(ri.get(d, {}).get("scope") == "future" for d in deps),
                  f"{rid}: version-one work depends on a deferred feature")
        for test in tests:
            check(rid in ai.get(test, {}).get("requirements", []), f"{rid}: missing reciprocal {test} mapping")
        path = root / "spec" / "requirements" / (rid + ".md")
        if not path.is_file():
            errors.append(f"{rid}: Markdown file missing")
            continue
        text = path.read_text(encoding="utf-8")
        check(f"# {rid} - {req.get('title')}" in text, f"{rid}: Markdown title mismatch")
        check(req.get("statement", "__MISSING__") in text, f"{rid}: Markdown statement mismatch")
        for criterion in criteria:
            target = f"**{criterion['id']}:** {criterion['text']}"
            check(target in text, f"{rid}/{criterion['id']}: Markdown/JSON mismatch")
        check("Not implemented or verified by this package." in text,
              f"{rid}: verification disclaimer missing")
        frontmatter_fields = {
            "id": rid, "scope": req.get("scope"), "priority": req.get("priority"),
            "status": req.get("status"), "parent": feature, "epic": req.get("epic"),
            "primary_gate": req.get("milestone"),
        }
        frontmatter = text.split("---", 2)[1] if text.startswith("---\n") else ""
        for key, value in frontmatter_fields.items():
            check(f"{key}: {value}" in frontmatter.splitlines(), f"{rid}: frontmatter {key} mismatch")
        for key, values in (("dependencies", deps), ("origins", origins), ("scenarios", tests)):
            match = re.search(rf"^{key}: (.*)$", frontmatter, re.MULTILINE)
            try:
                actual = json.loads(match.group(1)) if match else None
            except json.JSONDecodeError:
                actual = None
            check(actual == values, f"{rid}: frontmatter {key} mismatch")
    check(coverage == expected_clauses, f"Source clauses not fully covered: {sorted(expected_clauses - coverage)}")
    check(criteria_total == 404, f"Expected 404 acceptance criteria; found {criteria_total}")
    paths = {x.stem for x in (root / "spec" / "requirements").glob("*.md")}
    check(paths == expected_r, "Markdown requirement file set differs from JSON")

    state: dict[str, int] = {}
    def visit(node: str, trail: list[str]) -> None:
        if state.get(node) == 1:
            errors.append("Dependency cycle: " + " -> ".join(trail + [node]))
            return
        if state.get(node) == 2:
            return
        state[node] = 1
        for dependency in graph.get(node, []):
            if dependency in graph:
                visit(dependency, trail + [node])
        state[node] = 2
    for rid in ri:
        visit(rid, [])

    for sid, scenario in ai.items():
        for field in ("title", "fixtures", "actions", "expected", "evidence"):
            check(bool(scenario.get(field)), f"{sid}: missing {field}")
        ids = scenario.get("requirements", [])
        check(bool(ids) and set(ids) <= set(ri), f"{sid}: unknown/missing requirements")
        check(len(ids) == len(set(ids)), f"{sid}: duplicate requirements")
        for rid in ids:
            check(sid in ri.get(rid, {}).get("scenarios", []), f"{sid}: missing reciprocal {rid} mapping")

    for sid, source in si.items():
        check(urlsplit(source.get("url", "")).scheme == "https", f"{sid}: HTTPS source URL required")
        check(source.get("checked") == "2026-10-02", f"{sid}: missing check date")

    def no_fences(text: str) -> str:
        return re.sub(r"^```[^\n]*\n.*?^```[^\n]*(?:\n|$)", "", text,
                      flags=re.MULTILINE | re.DOTALL)

    def anchors(path: Path) -> set[str]:
        text = no_fences(path.read_text(encoding="utf-8"))
        result = set(re.findall(r'<a\s+id=[\"\']([^\"\']+)[\"\']', text))
        seen: Counter[str] = Counter()
        for heading in re.findall(r"^#{1,6}\s+(.+?)\s*#*\s*$", text, re.MULTILINE):
            cleaned = re.sub(r"<[^>]+>", "", heading).lower()
            cleaned = re.sub(r"[^\w\-\s]", "", cleaned)
            slug = re.sub(r"\s", "-", cleaned)
            duplicate = seen[slug]
            seen[slug] += 1
            result.add(slug if not duplicate else f"{slug}-{duplicate}")
        return result

    links = 0
    mds = list(root.rglob("*.md"))
    for path in mds:
        text = no_fences(path.read_text(encoding="utf-8"))
        for link in re.findall(r"\[[^\]\n]*\]\(([^)\n]+)\)", text):
            url = link.strip().strip("<>").split(' "', 1)[0]
            parsed = urlsplit(url)
            if parsed.scheme or parsed.netloc:
                continue
            target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path.resolve()
            try:
                target.relative_to(root)
            except ValueError:
                errors.append(f"Unsafe internal path in {path.relative_to(root)}: {url}")
                continue
            links += 1
            if not target.exists():
                errors.append(f"Broken internal link in {path.relative_to(root)}: {url}")
            elif parsed.fragment and target.suffix.lower() == ".md":
                check(unquote(parsed.fragment) in anchors(target),
                      f"Broken anchor in {path.relative_to(root)}: {url}")
        for sid in set(re.findall(r"\bSRC-\d{2}\b", text)):
            check(sid in si, f"Unknown source reference {sid} in {path.relative_to(root)}")

    skill = root / "workflow" / "skill.zip"
    if skill.is_file():
        try:
            with zipfile.ZipFile(skill) as archive:
                members = archive.namelist()
                check(len(members) == 4, "Portable skill must contain exactly four files")
                check(sum(x.endswith("/SKILL.md") for x in members) == 1, "Portable skill entrypoint mismatch")
                check(archive.testzip() is None, "Portable skill CRC check failed")
                for name in members:
                    item = Path(name)
                    check(not item.is_absolute() and ".." not in item.parts, f"Unsafe skill archive path: {name}")
                    check(item.parts[0] == "ai-video-editor-delivery", f"Unexpected skill archive root: {name}")
                    source_path = root / "workflow" / item
                    check(source_path.is_file(), f"Skill source file missing: {name}")
                    if source_path.is_file():
                        check(archive.read(name) == source_path.read_bytes(), f"Skill archive/source mismatch: {name}")
        except (OSError, zipfile.BadZipFile) as exc:
            errors.append(f"Cannot verify portable skill archive: {exc}")

    if not skip_manifest:
        check((root / "PACKAGE_VALIDATION.md").is_file(), "Validation report missing")
        manifest = load("MANIFEST.json")
        if isinstance(manifest, dict):
            inventory = manifest.get("files", [])
            declared = {item.get("path") for item in inventory}
            actual = {p.relative_to(root).as_posix() for p in root.rglob("*")
                      if p.is_file() and p.name != "MANIFEST.json"}
            check(len(declared) == len(inventory), "Duplicate manifest paths")
            check(declared == actual,
                  f"Manifest inventory mismatch: missing={sorted(actual-declared)}, extra={sorted(declared-actual)}")
            for item in inventory:
                name = item.get("path", "")
                path = (root / name).resolve()
                try:
                    path.relative_to(root)
                except ValueError:
                    errors.append(f"Unsafe manifest path: {name}")
                    continue
                if path.is_file():
                    data = path.read_bytes()
                    check(item.get("bytes") == len(data), f"Size mismatch: {name}")
                    check(item.get("sha256") == hashlib.sha256(data).hexdigest(), f"Hash mismatch: {name}")

    counts.update(requirements=len(reqs), version_one=sum(r.get("scope") == "v1" for r in reqs),
                  future=sum(r.get("scope") == "future" for r in reqs), acceptance_criteria=criteria_total,
                  scenarios=len(scenarios), source_clauses=len(clauses), primary_references=len(sources),
                  markdown_files=len(mds), checked_internal_links=links)
    return errors, counts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--skip-manifest", action="store_true", help="Authoring only: do not verify final hashes")
    args = parser.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"FAIL: package directory not found: {root}", file=sys.stderr)
        return 2
    try:
        errors, counts = validate(root, args.skip_manifest)
    except (OSError, UnicodeError, ValueError, TypeError, KeyError) as exc:
        print(f"FAIL: malformed package: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(counts, indent=2))
    if errors:
        print(f"FAIL: {len(errors)} package validation issue(s):", file=sys.stderr)
        for error in errors:
            print("- " + error, file=sys.stderr)
        return 1
    suffix = " (authoring mode: manifest not checked)" if args.skip_manifest else ""
    print("PASS: requirements package consistency" + suffix)
    print("This does not establish application implementation, media quality, live AI integration, or GPU support.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
