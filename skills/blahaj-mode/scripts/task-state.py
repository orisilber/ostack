#!/usr/bin/env python3
"""Save and load a single coordinator's task checkpoint in worktree metadata."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

OUTCOMES = ["answer", "local-change", "mr-open", "merge-ready"]


def git(*args):
    return subprocess.check_output(["git", *args], stderr=subprocess.PIPE)


def identity():
    return {
        "worktree": str(Path(git("rev-parse", "--show-toplevel").decode().strip()).resolve()),
        "branch": git("rev-parse", "--abbrev-ref", "HEAD").decode().strip(),
        "remote_fingerprint": hashlib.sha256(git("remote", "-v")).hexdigest(),
    }


def fingerprint():
    digest = hashlib.sha256()
    digest.update(git("rev-parse", "HEAD"))
    digest.update(git("diff", "--binary", "HEAD", "--"))
    digest.update(git("diff", "--cached", "--binary", "--"))
    for name in sorted(git("ls-files", "--others", "--exclude-standard", "-z").split(b"\0")):
        if name:
            path = Path(os.fsdecode(name))
            digest.update(name + b"\0")
            digest.update(str(path.lstat().st_mode).encode())
            digest.update(os.fsencode(os.readlink(path)) if path.is_symlink() else path.read_bytes())
    return digest.hexdigest()


def validate(data):
    contract = data["contract"]
    for key in ("task", "route", "authority_source"):
        if not isinstance(contract[key], str) or not contract[key].strip():
            raise ValueError("contract requires " + key)
    if contract["outcome"] not in OUTCOMES:
        raise ValueError("unknown outcome")
    if not isinstance(contract["constraints"], list) or not all(
        isinstance(item, str) and item.strip() for item in contract["constraints"]
    ):
        raise ValueError("constraints must be a list of strings")
    if data["status"] not in ("active", "waiting", "blocked", "paused", "complete"):
        raise ValueError("unknown status")
    if not isinstance(data["next_action"], str) or not data["next_action"].strip():
        raise ValueError("next_action required (use 'none' when complete)")
    if not isinstance(data["evidence"], dict):
        raise ValueError("evidence must be an object")


def read_state(path, task, current_identity):
    data = json.loads(path.read_text())
    validate(data)
    if data["version"] != 1 or data["task_id"] != task or data["identity"] != current_identity:
        raise ValueError("checkpoint version, task, or repository/worktree/branch identity mismatch")
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("save", "load"))
    parser.add_argument("--task", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", args.task):
        raise ValueError("task ID must be a simple stable identifier")
    current_identity = identity()
    os.chdir(current_identity["worktree"])
    path = Path(git("rev-parse", "--git-path", "ostack-tasks/" + args.task + ".json").decode().strip())
    current_fingerprint = fingerprint()
    if args.operation == "load":
        data = read_state(path, args.task, current_identity)
        data["needs_verification"] = data["fingerprint"] != current_fingerprint
        if data["needs_verification"]:
            data["evidence"] = {}
        print(json.dumps(data, indent=2))
        return
    data = json.load(sys.stdin)
    validate(data)
    if path.exists():
        previous_data = read_state(path, args.task, current_identity)
        previous = previous_data["contract"]
        contract = data["contract"]
        if any(previous[key] != contract[key] for key in ("task", "route", "authority_source")):
            raise ValueError("task contract changed; use a new task ID")
        if OUTCOMES.index(contract["outcome"]) > OUTCOMES.index(previous["outcome"]):
            raise ValueError("checkpoint cannot raise authority")
        if not set(previous["constraints"]).issubset(contract["constraints"]):
            raise ValueError("checkpoint cannot drop constraints")
        if previous_data["fingerprint"] != current_fingerprint:
            data["evidence"] = {}
    data.pop("needs_verification", None)
    data.update(version=1, task_id=args.task, identity=current_identity, fingerprint=current_fingerprint)
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=".checkpoint-")
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump(data, stream, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(path.resolve())


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print("task-state: " + str(error), file=sys.stderr)
        sys.exit(2)
