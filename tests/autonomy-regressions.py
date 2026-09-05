#!/usr/bin/env python3
"""Exercise checkpoint recovery and GitHub gates with real helpers and offline CLI fixtures."""

import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills/blahaj-mode/scripts"
HEAD = "a" * 40


def github_fixture():
    return {
        "pr": {"number": 7, "url": "https://github.example/owner/repo/pull/7",
               "headRefOid": HEAD, "headRefName": "fix/djungelskog-mode",
               "baseRefOid": "b" * 40, "baseRefName": "main",
               "state": "OPEN", "isDraft": False, "mergeable": "MERGEABLE",
               "mergeStateStatus": "CLEAN", "reviewDecision": "APPROVED",
               "updatedAt": "2026-09-05T10:00:00Z"},
        "reviews": [{"id": "r1", "author": {"login": "reviewer"}, "state": "APPROVED",
                     "commit": {"oid": HEAD}, "submittedAt": "2026-09-05T10:00:00Z"}],
        "threads": [{"id": "t1", "isResolved": True}],
        "comments": [],
        "checks": [{"name": "test", "bucket": "pass", "state": "SUCCESS"}],
        "required_checks": [{"name": "test", "bucket": "pass", "state": "SUCCESS"}],
    }


class Sandbox(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="ostack-autonomy-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()

    def run_command(self, *args, cwd=None, env=None, data=None):
        return subprocess.run([str(arg) for arg in args], cwd=cwd or self.root,
                              env=env, input=data, capture_output=True, text=True, timeout=30)


class GitHubGates(Sandbox):
    def setUp(self):
        super().setUp()
        self.fixture = self.root / "github.json"
        self.log = self.root / "calls.log"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        shutil.copy(ROOT / "tests/fixtures/github-cli.py", self.bin / "gh")
        (self.bin / "gh").chmod(0o755)
        self.env = dict(os.environ, GITHUB_FIXTURE=str(self.fixture), CALLS_LOG=str(self.log),
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"])
        self.data = github_fixture()

    def gate(self, expected, *flags, head=HEAD):
        self.fixture.write_text(json.dumps(self.data))
        result = self.run_command(sys.executable, SCRIPTS / "github-ready.py", "--repo",
                                  "github.example/owner/repo", "--pr", "7", "--expected-head",
                                  head, *flags, env=self.env)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        body = json.loads(result.stdout)
        self.assertEqual(body["ready"], expected == 0)
        self.assertNotRegex(self.log.read_text(), r"--- gh (pr (create|merge|comment|review)|api .*mutation)")
        return body

    def test_pending_failed_fix_stale_review_and_fresh_approval(self):
        for bucket in ("pending", "fail"):
            self.data["required_checks"][0]["bucket"] = bucket
            self.assertIn(bucket, " ".join(self.gate(1)["reasons"]))
        new_head = "d" * 40
        self.data["pr"]["headRefOid"] = new_head
        self.data["required_checks"][0]["bucket"] = "pass"
        self.assertIn("stale", " ".join(self.gate(1, head=new_head)["reasons"]))
        self.data["reviews"][0]["commit"]["oid"] = new_head
        self.gate(0, head=new_head)
        self.gate(0, head=new_head)

    def test_second_page_thread_blocks_and_named_reviewer_is_required(self):
        self.data["threads"].append({"id": "later", "isResolved": False})
        self.assertIn("later", " ".join(self.gate(1)["reasons"]))
        self.data["threads"][1]["isResolved"] = True
        self.gate(1, "--reviewer", "missing")
        self.gate(0, "--reviewer", "REVIEWER")

    def test_changes_requested_and_dismissal_supersede_approval(self):
        for state in ("CHANGES_REQUESTED", "DISMISSED"):
            later = copy.deepcopy(self.data["reviews"][0])
            later.update(id="r2", state=state, submittedAt="2026-09-05T11:00:00Z")
            self.data["reviews"] = [self.data["reviews"][0], later]
            self.gate(1)

    def test_missing_ci_requires_confirmed_policy_and_never_waives_failures(self):
        self.data["checks"] = self.data["required_checks"] = []
        self.data["empty_checks_message"] = True
        self.gate(1)
        self.gate(0, "--no-checks-required")
        self.data["checks"] = [{"name": "test", "bucket": "fail"}]
        self.gate(1, "--no-checks-required")

    def test_optional_failed_check_does_not_block_passing_required_checks(self):
        self.data["checks"].append({"name": "optional", "bucket": "fail"})
        self.data["pr"]["mergeStateStatus"] = "UNSTABLE"
        self.gate(0)

    def test_no_review_policy_does_not_waive_repository_requirements(self):
        self.data["reviews"] = []
        self.data["pr"]["reviewDecision"] = ""
        self.gate(1)
        self.gate(0, "--no-review-required")
        self.data["pr"]["reviewDecision"] = "REVIEW_REQUIRED"
        self.gate(1, "--no-review-required")

    def test_race_draft_and_conflicts_never_pass(self):
        self.data["race"] = True
        self.gate(1)
        self.gate(1, head="c" * 40)
        self.data = github_fixture()
        self.data["pr"]["isDraft"] = True
        self.gate(1)
        self.data["pr"]["isDraft"] = False
        self.data["pr"]["mergeable"] = "CONFLICTING"
        self.gate(1)

    def test_api_missing_fields_and_pagination_errors_fail_closed(self):
        for key in ("error", "bad_page"):
            self.data = github_fixture()
            self.data[key] = True
            self.gate(2)
        self.data = github_fixture()
        del self.data["pr"]["reviewDecision"]
        self.gate(2)


class Checkpoints(Sandbox):
    def setUp(self):
        super().setUp()
        for args in (("init", "-q", "-b", "main"), ("config", "user.name", "Fixture"),
                     ("config", "user.email", "fixture@example.invalid")):
            self.git(*args)
        (self.root / "app").write_text("before\n")
        self.git("add", "app")
        self.git("-c", "commit.gpgsign=false", "commit", "-qm", "initial")
        self.data = {"contract": {"task": "Fix app", "route": "bug-fix", "outcome": "merge-ready",
                                  "constraints": ["do not merge"], "authority_source": "user turn 1"},
                     "status": "waiting", "next_action": "check existing PR", "request_url": "pr/7",
                     "evidence": {"verified": True}, "scheduler": None}

    def git(self, *args):
        result = self.run_command("git", *args)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def state(self, operation, expected=0, task="task-1", cwd=None):
        result = self.run_command(sys.executable, SCRIPTS / "task-state.py", operation,
                                  "--task", task, data=json.dumps(self.data), cwd=cwd)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return json.loads(result.stdout) if operation == "load" and not expected else result.stdout.strip()

    def test_roundtrip_resume_and_metadata_do_not_dirty_worktree(self):
        path = Path(self.state("save"))
        self.assertTrue(path.is_relative_to(self.root / ".git"))
        loaded = self.state("load")
        self.assertEqual(loaded["contract"], self.data["contract"])
        self.assertEqual(loaded["request_url"], "pr/7")
        self.assertFalse(loaded["needs_verification"])
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.state("save")
        self.assertEqual(len(list(path.parent.glob("*.json"))), 1)

    def test_head_tracked_and_untracked_changes_invalidate_evidence(self):
        self.state("save")
        for path in ("app", "untracked"):
            (self.root / path).write_text("changed\n")
            loaded = self.state("load")
            self.assertTrue(loaded["needs_verification"])
            self.assertEqual(loaded["evidence"], {})
            self.state("save")
            self.assertEqual(self.state("load")["evidence"], {})
        self.git("add", "-A")
        self.git("-c", "commit.gpgsign=false", "commit", "-qm", "fix")
        self.assertTrue(self.state("load")["needs_verification"])

    def test_lower_scope_allowed_but_escalation_or_dropped_constraints_rejected(self):
        path = Path(self.state("save"))
        self.data["contract"]["outcome"] = "local-change"
        self.data["contract"]["constraints"].append("no PR")
        self.state("save")
        before = path.read_text()
        self.data["contract"]["outcome"] = "merge-ready"
        self.state("save", 2)
        self.assertEqual(path.read_text(), before)
        self.data["contract"]["outcome"] = "local-change"
        self.data["contract"]["constraints"] = []
        self.state("save", 2)

    def test_identity_mismatch_and_invalid_state_do_not_overwrite(self):
        path = Path(self.state("save"))
        before = path.read_text()
        self.git("switch", "-qc", "other")
        self.state("load", 2)
        self.state("save", 2)
        self.assertEqual(path.read_text(), before)
        self.git("switch", "-q", "main")
        self.data["status"] = "invented"
        self.state("save", 2)
        self.assertEqual(path.read_text(), before)
        self.state("load", 2, task="../escape")

    def test_worktree_isolation_and_subdirectory(self):
        original = self.state("save")
        linked = self.root / "linked"
        self.git("worktree", "add", "-qb", "linked", str(linked))
        linked_state = self.state("save", cwd=linked)
        self.assertNotEqual(original, linked_state)
        (linked / "nested").mkdir()
        self.assertEqual(self.state("load", cwd=linked / "nested")["identity"]["branch"], "linked")

    def test_stopped_status_and_confirmed_schedule_survive_resume(self):
        self.data["scheduler"] = {"host": "fixture", "id": "schedule-1", "status": "PAUSED"}
        for status in ("blocked", "paused", "complete"):
            self.data["status"] = status
            self.data["next_action"] = "none"
            self.state("save")
            loaded = self.state("load")
            self.assertEqual(loaded["status"], status)
            self.assertEqual(loaded["scheduler"], self.data["scheduler"])

    def test_changed_remote_rejected_without_persisting_remote_credentials(self):
        remote = "https://fixture-user:fixture-password@example.invalid/owner/repo"
        self.git("remote", "add", "origin", remote)
        path = Path(self.state("save"))
        self.assertNotIn("fixture-password", path.read_text())
        self.git("remote", "set-url", "origin", "https://example.invalid/other/repo")
        self.state("load", 2)

    def test_detached_worktree_can_checkpoint_before_delivery_branch_exists(self):
        self.git("checkout", "--detach", "-q")
        self.state("save")
        self.assertEqual(self.state("load")["identity"]["branch"], "HEAD")


if __name__ == "__main__":
    unittest.main()
