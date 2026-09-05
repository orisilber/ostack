#!/usr/bin/env python3
"""Validate skill metadata and explicit dependencies, including references."""
import json
from pathlib import Path
import re
import sys

import yaml


DEPENDENCY = re.compile(r"(?:\*\*([a-z][a-z0-9-]*)\*\*|`([a-z][a-z0-9-]*)`)\s+skill\b")
LOCAL_REFERENCE = re.compile(r"(?<![\w/-])(references/[A-Za-z0-9._/-]+\.(?:md|tsv|json|ya?ml))\b")
SCRIPT_REFERENCE = re.compile(r"(?:\]\(|<[^>\n]+>/)(scripts/[A-Za-z0-9._/-]+\.(?:sh|py|jq))\b")


def check(root):
    skills = root / "skills"
    failures = []
    manifest = root / "evals/external-skills.json"
    external = json.loads(manifest.read_text()) if manifest.exists() else {}
    if not isinstance(external, dict) or any(
        not isinstance(owner, str) or not owner.strip() for owner in external.values()
    ):
        return ["external-skills.json must map skill names to their providers"]
    for directory in sorted(skills.iterdir()):
        if not directory.is_dir():
            continue
        entry = directory / "SKILL.md"
        if not entry.is_file():
            failures.append(f"{directory.name}: SKILL.md missing")
            continue
        text = entry.read_text()
        match = re.match(r"\A---\s*\n(.*?)\n---\s*(?:\n|$)", text, re.S)
        try:
            metadata = yaml.safe_load(match[1]) if match else None
            if not isinstance(metadata, dict):
                raise ValueError("expected YAML frontmatter mapping")
            if metadata.get("name") != directory.name:
                failures.append(f"{directory.name}: frontmatter name must match folder")
            description = metadata.get("description")
            if not isinstance(description, str) or not description.strip():
                failures.append(f"{directory.name}: description must be nonempty text")
            elif len(description.encode()) > 600:
                failures.append(f"{directory.name}: description exceeds 600 bytes")
            if metadata.get("disable-model-invocation") is True:
                policy_file = directory / "agents/openai.yaml"
                config = yaml.safe_load(policy_file.read_text())
                policy = config.get("policy") if isinstance(config, dict) else None
                if not isinstance(policy, dict) or policy.get("allow_implicit_invocation") is not False:
                    failures.append(f"{directory.name}: Codex policy must disable implicit invocation")
        except (OSError, ValueError, yaml.YAMLError) as error:
            failures.append(f"{directory.name}: invalid metadata ({error})")
        if len(text.encode()) > 12000:
            failures.append(f"{directory.name}: SKILL.md exceeds 12000 bytes; move conditional detail to references")
        for document in sorted(directory.rglob("*.md")):
            prose = document.read_text()
            relative = document.relative_to(root)
            for dependency in DEPENDENCY.finditer(prose):
                name = dependency[1] or dependency[2]
                if not (skills / name / "SKILL.md").is_file() and name not in external:
                    failures.append(f"{relative}: unknown skill '{name}'")
            for reference in set(LOCAL_REFERENCE.findall(prose) + SCRIPT_REFERENCE.findall(prose)):
                # Skill paths are relative to the skill root. Markdown may also
                # use paths relative to the reference document itself.
                if not (directory / reference).exists() and not (document.parent / reference).exists():
                    failures.append(f"{relative}: missing file '{reference}'")
    return failures


if __name__ == "__main__":
    try:
        failures = check(Path(sys.argv[1]).resolve())
    except (OSError, ValueError) as error:
        sys.exit(f"Skill contract validation failed: {error}")
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    print(f"SKILL CONTRACTS: {'FAIL' if failures else 'PASS'}")
    sys.exit(bool(failures))
