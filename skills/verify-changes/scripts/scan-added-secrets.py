#!/usr/bin/env python3
"""Scan proposed additions relative to an explicit base, without printing secrets."""
import os
from pathlib import Path
import re
import subprocess
import sys

PATTERN = re.compile(rb"sk-[a-z0-9]{8,}|AKIA[A-Z0-9]{8,}|BEGIN[^\r\n]*PRIVATE KEY", re.I)


def git(*args):
    return subprocess.check_output(["git", *args], stderr=subprocess.PIPE)


def scan(base):
    root = Path(os.fsdecode(git("rev-parse", "--show-toplevel").strip()))
    os.chdir(root)
    base_sha = git("rev-parse", "--verify", "--end-of-options", base + "^{commit}").decode().strip()
    options = ("--no-ext-diff", "--no-textconv", "--no-renames", "--unified=0")
    # Scan every outgoing commit, even when a later commit deletes a secret.
    # Inspect the index separately: unstaged removal does not remove staged data.
    diff = b"\n".join((
        git("log", "--format=", "-p", "--diff-merges=first-parent", *options, base_sha + "..HEAD", "--"),
        git("diff", "--cached", *options, "HEAD", "--"),
        git("diff", *options, "--"),
    ))
    findings = []
    file_header = b"unknown file"
    in_hunk = False
    for line in diff.splitlines():
        if line.startswith(b"diff --git "):
            in_hunk = False
        elif line.startswith(b"@@ "):
            in_hunk = True
        elif not in_hunk and line.startswith(b"+++ "):
            file_header = line[4:]
        elif in_hunk and line.startswith(b"+") and PATTERN.search(line[1:]):
            findings.append(os.fsdecode(file_header))
    for name in git("ls-files", "--others", "--exclude-standard", "-z").split(b"\0"):
        if not name:
            continue
        path = root / os.fsdecode(name)
        data = os.fsencode(os.readlink(path)) if path.is_symlink() else path.read_bytes()
        if PATTERN.search(data):
            findings.append(os.fsdecode(name))
    for name in sorted(set(findings)):
        print(f"Secret-shaped addition in {name!r}; value redacted", file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python3 scan-added-secrets.py BASE_COMMIT_OR_REF")
    try:
        sys.exit(scan(sys.argv[1]))
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Secret scan failed: {type(error).__name__}", file=sys.stderr)
        sys.exit(2)
