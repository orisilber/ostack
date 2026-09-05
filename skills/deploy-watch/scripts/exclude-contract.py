#!/usr/bin/env python3
"""Ignore one existing local contract; reject contracts already in the index."""
from pathlib import Path
import subprocess
import sys


def exclude(contract):
    path = Path(contract).resolve(strict=True)
    root = Path(subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True).strip()).resolve()
    entry = path.relative_to(root).as_posix()
    if not path.is_file() or "\n" in entry or "\r" in entry:
        raise ValueError("contract must be a regular file with a single-line path")
    tracked = subprocess.run(
        ["git", "ls-files", "--error-unmatch", "--", ":(literal)" + entry],
        cwd=root, capture_output=True)
    if tracked.returncode == 0:
        raise ValueError("contract is already tracked; an ignore entry cannot untrack it")
    if tracked.returncode != 1:
        raise ValueError("could not inspect the Git index")
    ignore_file = Path(subprocess.check_output(
        ["git", "rev-parse", "--git-path", "info/exclude"], text=True).strip()).resolve()
    # Anchor the exact path and escape Gitignore metacharacters.
    pattern = "/" + "".join("\\" + c if c in "\\*?[]#! " else c for c in entry)
    current = ignore_file.read_text() if ignore_file.exists() else ""
    if pattern not in current.splitlines():
        ignore_file.parent.mkdir(parents=True, exist_ok=True)
        with ignore_file.open("a") as stream:
            if current and not current.endswith("\n"):
                stream.write("\n")
            stream.write(pattern + "\n")
    subprocess.run(["git", "check-ignore", "-q", "--", entry], cwd=root, check=True)
    print(f"Contract is untracked and ignored: {entry}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python3 exclude-contract.py CONTRACT_PATH")
    try:
        exclude(sys.argv[1])
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Cannot exclude contract: {error}", file=sys.stderr)
        sys.exit(1)
