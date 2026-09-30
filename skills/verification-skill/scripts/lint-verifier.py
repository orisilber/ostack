#!/usr/bin/env python3
"""Check a project-local verifier against the verification-skill template.

Usage: lint-verifier.py <verifier-dir> [repo-root]

repo-root defaults to the git top level of verifier-dir.
"""

import re
import subprocess
import sys
from pathlib import Path

SECTIONS = (
    "Source anchors",
    "Repository checks",
    "Launch",
    "Doctor",
    "Drive",
    "Evidence",
    "Cleanup",
)
FEATURE_SECTIONS = (
    re.compile(r"Sub-features$"),
    re.compile(r"How to get to it \(user POV\)$"),
    re.compile(r"Driving it with \S.*$"),
    re.compile(r"Gotchas$"),
)
MARKER = re.compile(r"\{\{[^}]*\}\}")
LAST_VERIFIED = re.compile(r"^Last verified: `?([0-9a-f]{7,40}|never)`?\s*$", re.M)
LINK = re.compile(r"\]\(\./?([^)#\s]+\.md)\)")
STATUS = re.compile(r"Status: `(verified|draft|verified-unreachable)`\.?\s*$")


def headings(text):
    return [m.group(1).strip() for m in re.finditer(r"^## (.+)$", text, re.M)]


def section(text, name):
    match = re.search(rf"^## {re.escape(name)}\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return match.group(1) if match else ""


def anchor_rows(text):
    for line in section(text, "Source anchors").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 3 or not cells[0].startswith("`"):
            continue
        ids = [i.strip(" `") for i in cells[2].split(",") if i.strip(" `")]
        yield cells[0].strip("`"), ids


def lint(verifier, root):
    errors = []
    skill = verifier / "SKILL.md"
    if not skill.is_file():
        return [f"{skill}: missing"]
    text = skill.read_text()
    features_dir = verifier / "features"
    files = sorted(features_dir.glob("*.md")) if features_dir.is_dir() else []

    for path in [skill, *files]:
        for marker in sorted(set(MARKER.findall(path.read_text()))):
            errors.append(f"{path.relative_to(verifier)}: template marker {marker}")

    if not re.search(r"^name: verify-\S+$", text, re.M):
        errors.append("SKILL.md: frontmatter name must be verify-<app>")
    if not LAST_VERIFIED.search(text):
        errors.append("SKILL.md: missing 'Last verified: <sha>' or 'Last verified: never'")
    present = headings(text)
    for name in SECTIONS:
        if name not in present:
            errors.append(f"SKILL.md: missing section '## {name}'")

    feature_ids = {f.stem for f in files if f.name != "README.md"}
    anchored = set()
    rows = list(anchor_rows(text))
    if "Source anchors" in present and not rows:
        errors.append("SKILL.md: Source anchors table has no rows")
    for path, ids in rows:
        if not (root / path).exists():
            errors.append(f"SKILL.md: anchor path does not exist: {path}")
        for fid in ids:
            if fid == "unmapped":
                continue
            if fid not in feature_ids:
                errors.append(f"SKILL.md: anchor {path} names unknown feature '{fid}'")
            anchored.add(fid)
    for fid in sorted(feature_ids - anchored):
        errors.append(f"features/{fid}.md: not named by any source anchor")

    index = features_dir / "README.md"
    if not index.is_file():
        errors.append("features/README.md: missing")
    else:
        index_text = index.read_text()
        linked = set(LINK.findall(index_text))
        for line in index_text.splitlines():
            for target in LINK.findall(line):
                if not STATUS.search(line):
                    errors.append(f"features/README.md: entry for {target} has no status")
        for target in sorted(linked):
            if not (features_dir / target).is_file():
                errors.append(f"features/README.md: broken link {target}")
        for fid in sorted(feature_ids):
            if f"{fid}.md" not in linked:
                errors.append(f"features/README.md: does not link {fid}.md")

    for fid in sorted(feature_ids):
        found = headings((features_dir / f"{fid}.md").read_text())
        ok = len(found) == len(FEATURE_SECTIONS) and all(
            p.match(h) for p, h in zip(FEATURE_SECTIONS, found)
        )
        if not ok:
            errors.append(
                f"features/{fid}.md: H2 sections must be Sub-features, "
                "How to get to it (user POV), Driving it with <harness>, Gotchas"
            )
    return errors


def main():
    if len(sys.argv) not in (2, 3):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    verifier = Path(sys.argv[1]).resolve()
    if len(sys.argv) == 3:
        root = Path(sys.argv[2]).resolve()
    else:
        top = subprocess.run(
            ["git", "-C", str(verifier), "rev-parse", "--show-toplevel"],
            capture_output=True, text=True,
        )
        root = Path(top.stdout.strip()) if top.returncode == 0 else verifier
    errors = lint(verifier, root)
    for error in errors:
        print(f"FAIL: {error}")
    print("VERIFIER LINT: " + ("FAIL" if errors else "PASS"))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
