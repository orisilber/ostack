#!/usr/bin/env python3
"""Offline gh fixture. Every unsupported command fails without network access."""

import json
import os
from pathlib import Path
import subprocess
import sys

args = sys.argv[1:]
path = Path(os.environ["GITHUB_FIXTURE"])
data = json.loads(path.read_text())
with open(os.environ["CALLS_LOG"], "a") as log:
    log.write("--- gh " + " ".join(args) + "\n")
if data.get("error"):
    print("fixture authentication failure", file=sys.stderr)
    sys.exit(1)
if data.get("dynamic_head"):
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    data["pr"]["headRefOid"] = head
    for review in data["reviews"]:
        review["commit"]["oid"] = head
if args[:2] == ["pr", "view"]:
    result = dict(data["pr"])
    if data.get("race"):
        data["pr"]["headRefOid"] = "c" * 40
        path.write_text(json.dumps(data))
elif args[:2] == ["pr", "list"]:
    result = [data["pr"]]
elif args[:2] == ["pr", "checks"]:
    result = data["required_checks" if "--required" in args else "checks"]
    if data.get("empty_checks_message") and not result:
        qualifier = "required " if "--required" in args else ""
        print("no " + qualifier + "checks reported on the 'fixture' branch", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(result))
    sys.exit(8 if any(c["bucket"] == "pending" for c in result) else
             1 if any(c["bucket"] == "fail" for c in result) else 0)
elif args[:2] == ["api", "graphql"]:
    query = next(arg for arg in args if arg.startswith("query="))
    field = "reviewThreads" if "reviewThreads(" in query else "reviews"
    source = data["threads" if field == "reviewThreads" else "reviews"]
    cursor = next((arg.split("=", 1)[1] for arg in args if arg.startswith("cursor=")), "0")
    index = int(cursor)
    more = index + 1 < len(source)
    result = {"data": {"repository": {"pullRequest": {field: {
        "nodes": source[index:index + 1],
        "pageInfo": {"hasNextPage": more, "endCursor": str(index + 1) if more else None}
    }}}}}
    if data.get("bad_page"):
        result = {"errors": [{"message": "fixture pagination failure"}]}
elif args[:1] == ["api"] and any("/issues/7/comments" in arg for arg in args):
    result = data.get("comments", [])
    if "--slurp" in args:
        result = [result]
else:
    print("Unsupported offline gh operation", file=sys.stderr)
    sys.exit(2)
print(json.dumps(result))
