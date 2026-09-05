#!/usr/bin/env python3
"""Collect current GitHub PR readiness evidence without mutating the PR."""

import argparse
import json
import re
import subprocess
import sys

FIELDS = "number,url,headRefOid,baseRefOid,baseRefName,state,isDraft,mergeable,mergeStateStatus,reviewDecision,updatedAt"


def command(args, allowed=(0,), empty_checks=False):
    result = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=60)
    if result.returncode not in allowed:
        raise ValueError("GitHub command failed (exit " + str(result.returncode) + ")")
    if empty_checks and result.returncode == 1 and not result.stdout.strip() and re.fullmatch(
        r"no (?:required )?checks reported on the '.+' branch\n?", result.stderr
    ):
        return []
    data = json.loads(result.stdout)
    if isinstance(data, dict) and data.get("errors"):
        raise ValueError("GraphQL returned errors")
    return data


def pages(host, owner, repo, number, field, selection):
    query = ("query($owner:String!,$repo:String!,$number:Int!,$cursor:String){"
             "repository(owner:$owner,name:$repo){pullRequest(number:$number){"
             + field + "(first:100,after:$cursor){nodes{" + selection + "}"
             "pageInfo{hasNextPage endCursor}}}}}")
    nodes, cursor, seen = [], None, set()
    for _ in range(100):
        args = ["api", "graphql", "--hostname", host, "-f", "query=" + query,
                "-f", "owner=" + owner, "-f", "repo=" + repo, "-F", "number=" + str(number)]
        if cursor is not None:
            args += ["-f", "cursor=" + cursor]
        page = command(args)["data"]["repository"]["pullRequest"][field]
        if not isinstance(page["nodes"], list):
            raise ValueError("invalid " + field + " page")
        nodes.extend(page["nodes"])
        info = page["pageInfo"]
        if info["hasNextPage"] is False:
            return nodes
        cursor = info["endCursor"]
        if info["hasNextPage"] is not True or not isinstance(cursor, str) or not cursor or cursor in seen:
            raise ValueError("invalid pagination cursor")
        seen.add(cursor)
    raise ValueError("pagination limit reached; evidence incomplete")


def metadata(repo, number):
    data = command(["pr", "view", str(number), "--repo", repo, "--json", FIELDS])
    for field in FIELDS.split(","):
        if field not in data:
            raise ValueError("missing PR field: " + field)
    if data["number"] != number or type(data["isDraft"]) is not bool:
        raise ValueError("invalid PR identity or draft status")
    for field in ("headRefOid", "baseRefOid"):
        if not isinstance(data[field], str) or not re.fullmatch(r"[a-f0-9]{40,64}", data[field]):
            raise ValueError("invalid commit identity")
    return data


def checks(repo, number, required=False):
    args = ["pr", "checks", str(number), "--repo", repo,
            "--json", "name,bucket,state,link,workflow"]
    if required:
        args += ["--required"]
    data = command(args, allowed=(0, 1, 8), empty_checks=True)
    if not isinstance(data, list):
        raise ValueError("invalid checks response")
    for check in data:
        if not isinstance(check["name"], str) or not check["name"] or check["bucket"] not in (
            "pass", "fail", "pending", "skipping", "cancel"
        ):
            raise ValueError("invalid check result")
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True, help="explicit host/owner/repo")
    parser.add_argument("--pr", required=True, type=int)
    parser.add_argument("--expected-head", required=True)
    parser.add_argument("--reviewer", action="append", default=[])
    parser.add_argument("--no-review-required", action="store_true")
    parser.add_argument("--no-checks-required", action="store_true")
    args = parser.parse_args()
    parts = args.repo.split("/")
    if len(parts) != 3 or any(not re.fullmatch(r"[A-Za-z0-9_.-]+", part) for part in parts):
        raise ValueError("repo must be host/owner/repo")
    if args.pr < 1 or not re.fullmatch(r"[a-f0-9]{40,64}", args.expected_head):
        raise ValueError("invalid PR number or expected head")
    if args.reviewer and args.no_review_required:
        raise ValueError("reviewer and no-review-required are mutually exclusive")
    before = metadata(args.repo, args.pr)
    reviews = pages(*parts, args.pr, "reviews", "id author{login} state commit{oid} submittedAt")
    threads = pages(*parts, args.pr, "reviewThreads", "id isResolved")
    all_checks = checks(args.repo, args.pr)
    required_checks = checks(args.repo, args.pr, required=True)
    after = metadata(args.repo, args.pr)
    reasons = []
    if before != after or after["headRefOid"] != args.expected_head:
        reasons.append("PR changed during collection or differs from verified head")
    if after["state"] != "OPEN" or after["isDraft"]:
        reasons.append("PR is closed or draft")
    if after["mergeable"] != "MERGEABLE" or after["mergeStateStatus"] not in ("CLEAN", "UNSTABLE"):
        reasons.append("mergeability is blocked or unknown")
    if after["reviewDecision"] not in ("", None, "APPROVED", "REVIEW_REQUIRED", "CHANGES_REQUESTED"):
        raise ValueError("unknown review decision")
    if after["reviewDecision"] in ("REVIEW_REQUIRED", "CHANGES_REQUESTED"):
        reasons.append("repository review requirements are unsatisfied")
    latest = {}
    for review in reviews:
        state = review["state"]
        if state not in ("PENDING", "COMMENTED", "APPROVED", "CHANGES_REQUESTED", "DISMISSED"):
            raise ValueError("unknown review state")
        if state in ("PENDING", "COMMENTED"):
            continue
        login, submitted = review["author"]["login"], review["submittedAt"]
        if not isinstance(login, str) or not isinstance(submitted, str) or not submitted:
            raise ValueError("missing review author or submission time")
        if login not in latest or submitted > latest[login]["submittedAt"]:
            latest[login] = review
    approved = set()
    for login, review in latest.items():
        if review["state"] == "CHANGES_REQUESTED":
            reasons.append("changes requested by " + login)
        elif review["state"] == "APPROVED":
            if review["commit"]["oid"] == args.expected_head:
                approved.add(login.lower())
            elif not args.no_review_required:
                reasons.append("stale approval from " + login)
    if not args.no_review_required and not approved:
        reasons.append("no approval for the current head")
    for reviewer in args.reviewer:
        if reviewer.lower() not in approved:
            reasons.append("missing current-head approval from " + reviewer)
    for thread in threads:
        if type(thread["isResolved"]) is not bool:
            raise ValueError("invalid thread resolution")
        if not thread["isResolved"]:
            reasons.append("unresolved review thread " + thread["id"])
    gated_checks = required_checks or all_checks
    if not gated_checks and not args.no_checks_required:
        reasons.append("no CI evidence; no-checks policy must be confirmed")
    for check in gated_checks:
        if check["bucket"] != "pass":
            reasons.append("check " + check["name"] + ": " + check["bucket"])
    print(json.dumps({"ready": not reasons, "head": after["headRefOid"], "url": after["url"],
                      "reasons": reasons, "reviews": reviews, "threads": threads,
                      "required_checks": required_checks, "all_checks": all_checks}, indent=2))
    return 1 if reasons else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"ready": False, "error": str(error)}))
        sys.exit(2)
