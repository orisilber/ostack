#!/usr/bin/env python3
"""Exercise the audit's failure modes in disposable repositories and API fixtures."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
TOKEN = "sk" + "-" + "a" * 18


def run(*args, cwd=None, env=None):
    return subprocess.run([str(arg) for arg in args], cwd=cwd, env=env,
                          capture_output=True, text=True, timeout=30)


class Sandbox(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ostack-audit-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def git(self, *args):
        result = run("git", *args, cwd=self.root)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def repo(self):
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Audit fixture")
        self.git("config", "user.email", "audit@example.invalid")
        (self.root / "baseline").write_text("baseline\n")
        self.commit()
        return self.git("rev-parse", "HEAD")

    def commit(self):
        self.git("add", "-A")
        self.git("-c", "commit.gpgsign=false", "commit", "-qm", "fixture")


class CheckStatus(Sandbox):
    def test_status_and_full_log_in_bash_and_zsh(self):
        helper = SKILLS / "verify-changes/scripts/run-check.sh"
        for shell in ("bash", "zsh"):
            if not shutil.which(shell):
                continue
            for expected in (0, 7, 23):
                with self.subTest(shell=shell, status=expected):
                    log = self.root / f"{shell}-{expected}.log"
                    result = run(shell, "-c", 'bash "$1" "$2" bash -c "$3"',
                                 "fixture", helper, log,
                                 f'for n in {{1..45}}; do echo "line-$n"; done; exit {expected}')
                    self.assertEqual(result.returncode, expected)
                    self.assertEqual(len(log.read_text().splitlines()), 45)
                    self.assertNotIn("line-1\n", result.stdout)
                    self.assertIn("line-45\n", result.stdout)

    def test_launch_and_log_errors_do_not_pass(self):
        helper = SKILLS / "verify-changes/scripts/run-check.sh"
        self.assertEqual(run("bash", helper, self.root / "log", "missing-audit-command").returncode, 127)
        result = run("bash", helper, self.root / "absent/log", "true")
        self.assertNotEqual(result.returncode, 0)


class SecretScan(Sandbox):
    def setUp(self):
        super().setUp()
        self.base = self.repo()
        self.helper = SKILLS / "verify-changes/scripts/scan-added-secrets.py"

    def scan(self, expected, base=None, cwd=None):
        result = run(sys.executable, self.helper, base or self.base, cwd=cwd or self.root)
        self.assertEqual(result.returncode, expected, result.stderr)
        self.assertNotIn(TOKEN, result.stdout + result.stderr)
        return result

    def test_clean_and_removal(self):
        self.scan(0)
        (self.root / "old").write_text(TOKEN + "\n")
        self.commit()
        self.base = self.git("rev-parse", "HEAD")
        (self.root / "old").unlink()
        self.scan(0)

    def test_outgoing_secret_still_detected_after_later_removal(self):
        (self.root / "outgoing").write_text(TOKEN + "\n")
        self.commit()
        self.scan(1)
        (self.root / "outgoing").unlink()
        self.commit()
        self.scan(1)

    def test_staged_secret_not_hidden_by_unstaged_removal(self):
        (self.root / "staged").write_text(TOKEN + "\n")
        self.git("add", "staged")
        (self.root / "staged").write_text("removed locally\n")
        self.scan(1)

    def test_unstaged_and_untracked_from_subdirectory(self):
        (self.root / "baseline").write_text(TOKEN + "\n")
        self.scan(1)
        self.git("restore", "baseline")
        (self.root / "untracked").write_text(TOKEN + "\n")
        (self.root / "service").mkdir()
        self.scan(1, cwd=self.root / "service")

    def test_invalid_base_is_scan_failure(self):
        self.scan(2, base="missing-base")

    def test_prose_and_pattern_source_are_not_credentials(self):
        (self.root / "prose").write_text("Use a task-specific path.\n")
        (self.root / "scanner-source.py").write_bytes(self.helper.read_bytes())
        self.scan(0)

    def test_aws_and_pem_markers_are_redacted(self):
        for token in ("AKIA" + "X" * 16, "-----BEGIN " + "RSA PRIVATE KEY-----"):
            (self.root / "candidate").write_text(token)
            result = self.scan(1)
            self.assertNotIn(token, result.stdout + result.stderr)

    def test_symlink_does_not_read_destination(self):
        with tempfile.TemporaryDirectory() as other:
            secret = Path(other) / "outside"
            secret.write_text(TOKEN)
            (self.root / "link").symlink_to(secret)
            self.scan(0)


class ContractIgnore(Sandbox):
    def setUp(self):
        super().setUp()
        self.repo()
        self.helper = SKILLS / "deploy-watch/scripts/exclude-contract.py"

    def exclude(self, path, cwd=None):
        return run(sys.executable, self.helper, path, cwd=cwd or self.root)

    def test_actual_path_from_nested_directory_and_idempotence(self):
        service = self.root / "services/one"
        service.mkdir(parents=True)
        for path in (self.root / "watch.json", service / "local [one]*?.json"):
            path.write_text("{}")
            result = self.exclude(path, cwd=service)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.git("check-ignore", "-q", "--", str(path))
            exclude_file = self.root / ".git/info/exclude"
            before = exclude_file.read_text()
            self.assertEqual(self.exclude(path, cwd=service).returncode, 0)
            self.assertEqual(exclude_file.read_text(), before)
        similar = service / "local oops.json"
        similar.write_text("{}")
        self.assertEqual(run("git", "check-ignore", "-q", similar, cwd=self.root).returncode, 1)

    def test_tracked_contract_rejected_without_mutation(self):
        path = self.root / "tracked.json"
        path.write_text("{}")
        self.commit()
        exclude_file = self.root / ".git/info/exclude"
        before = exclude_file.read_text()
        result = self.exclude(path)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already tracked", result.stderr)
        self.assertEqual(exclude_file.read_text(), before)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_linked_worktree(self):
        worktree = self.root / "linked"
        self.git("worktree", "add", "-qb", "fixture-branch", worktree)
        self.assertTrue((worktree / ".git").is_file())
        contract = worktree / "watch.json"
        contract.write_text("{}")
        result = self.exclude(contract, cwd=worktree)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(run("git", "check-ignore", "-q", contract, cwd=worktree).returncode, 0)

    def test_missing_and_outside_contract_rejected(self):
        self.assertNotEqual(self.exclude(self.root / "missing").returncode, 0)
        with tempfile.NamedTemporaryFile() as outside:
            self.assertNotEqual(self.exclude(outside.name).returncode, 0)


class ReviewNotes(Sandbox):
    def test_predicates_apply_to_same_note_and_keep_full_evidence(self):
        def note(nid, author, system=False, body="hello"):
            return {"id": nid, "system": system, "author": {"username": author}, "body": body}
        qualifier = "LGTM " + "x" * 450 + " but do not merge until corrected"
        data = [{"id": "thread", "notes": [note(1, "human"), note(12, "system", True),
                note(14, "review-bot", body=qualifier), note(15, "me"), note(13, "human")]}]
        path = self.root / "notes.json"
        path.write_text(json.dumps(data))
        helper = SKILLS / "babysit-gitlab-mr/scripts/new-notes.jq"
        for humans_only, expected in (("true", [13]), ("false", [13, 14])):
            result = run("jq", "--arg", "me", "me", "--argjson", "last", "10",
                         "--argjson", "bots", '["review-bot"]', "--argjson", "humans_only",
                         humans_only, "-f", helper, path)
            self.assertEqual(result.returncode, 0, result.stderr)
            notes = json.loads(result.stdout)
            self.assertEqual([n["nid"] for n in notes], expected)
            if humans_only == "false":
                self.assertEqual(notes[-1]["text"], qualifier)
                self.assertEqual(notes[-1]["by"], "review-bot")


class Pagination(Sandbox):
    def pages(self, mode):
        stub = self.root / "glab"
        stub.write_text('#!' + sys.executable + '\n' + '''import json, os, sys
page = int(sys.argv[-1].split("page=")[-1])
mode = os.environ["PAGE_FIXTURE"]
if mode == "failure" and page == 2:
    sys.exit(23)
if mode == "invalid":
    print("not json")
elif mode == "object":
    print('{}')
elif mode == "empty":
    print('[]')
else:
    count = 100 if page == 1 or mode == "limit" else 2
    print(json.dumps(list(range((page - 1) * 100, (page - 1) * 100 + count))))
''')
        stub.chmod(0o755)
        env = dict(os.environ, PATH=str(self.root) + os.pathsep + os.environ["PATH"], PAGE_FIXTURE=mode)
        return run("bash", SKILLS / "babysit-gitlab-mr/scripts/list-pages.sh", "projects/1/notes", env=env)

    def test_all_pages_and_empty_inventory(self):
        result = self.pages("success")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), list(range(102)))
        self.assertEqual(json.loads(self.pages("empty").stdout), [])

    def test_failures_never_publish_partial_inventory(self):
        for mode in ("failure", "invalid", "object", "limit"):
            with self.subTest(mode=mode):
                result = self.pages(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")


class SkillContracts(Sandbox):
    def setUp(self):
        super().setUp()
        spec = importlib.util.spec_from_file_location("contracts", ROOT / "evals/lib/check-skill-contracts.py")
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.skill = self.root / "skills/sample"
        (self.skill / "agents").mkdir(parents=True)
        (self.skill / "SKILL.md").write_text("---\nname: sample\ndescription: fixture\ndisable-model-invocation: true\n---\n")
        self.policy = self.skill / "agents/openai.yaml"
        self.policy.write_text("policy:\n  allow_implicit_invocation: false\n")

    def test_manual_policy_is_structured_yaml_not_matching_text(self):
        self.assertEqual(self.module.check(self.root), [])
        for policy in ("# allow_implicit_invocation: false\n", "allow_implicit_invocation: false\n",
                       'policy:\n  allow_implicit_invocation: "false"\n', "policy: []\n"):
            with self.subTest(policy=policy):
                self.policy.write_text(policy)
                self.assertTrue(self.module.check(self.root))

    def test_all_dependencies_on_one_line_and_nested_references(self):
        references = self.skill / "references"
        references.mkdir()
        (references / "guide.md").write_text("Use **first-missing** skill and `second-missing` skill.\n")
        errors = self.module.check(self.root)
        self.assertEqual(len(errors), 2, errors)

        self.assertTrue(any("first-missing" in e for e in errors))
        self.assertTrue(any("second-missing" in e for e in errors))
        (self.root / "evals").mkdir()
        (self.root / "evals/external-skills.json").write_text(json.dumps({"first-missing": "external provider"}))
        errors = self.module.check(self.root)
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("second-missing", errors[0])

    def test_missing_helper_reference_is_detected(self):
        with (self.skill / "SKILL.md").open("a") as stream:
            stream.write("Run [helper](scripts/missing.py).\n")
        self.assertTrue(any("missing.py" in e for e in self.module.check(self.root)))

    def test_plural_dependency_list(self):
        with (self.skill / "SKILL.md").open("a") as stream:
            stream.write("Use **first-missing** and `second-missing` skills.\n")
        errors = self.module.check(self.root)
        self.assertEqual(len(errors), 2, errors)


class CliExamples(unittest.TestCase):
    def test_pipeline_flags_are_not_cli_flags(self):
        spec = importlib.util.spec_from_file_location("cli_command", ROOT / "evals/lib/cli-command.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertEqual(module.arguments('acli jira workitem view PROJ-1 --json | jq --arg id 1'),
                         ['acli', 'jira', 'workitem', 'view', 'PROJ-1', '--json'])
        self.assertEqual(module.arguments('glab api "projects/a|b" --method GET > result.json'),
                         ['glab', 'api', 'projects/a|b', '--method', 'GET'])


if __name__ == "__main__":
    unittest.main(verbosity=2)
