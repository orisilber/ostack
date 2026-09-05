---
name: verify-changes
description: Pre-push quality gate. Run a repository's declared checks and use its project-local verifier for affected user behavior. Triggers "verify", "run checks", or "gate before push". Not for fixing code or reviewing changes.
---

# Verify changes

Gate every push. Run the repository checks and relevant user-path proof before a
changed artifact leaves the machine.

This is **prove-it-works** (see `principles`) with commands attached: the verdict
below is a claim about the real artifact, so never emit PASS from a run you
didn't watch finish.

## Verdicts

End with exactly one line: `VERIFY: PASS`, `VERIFY: FAIL <one-line reason>`, or
`VERIFY: SKIP <what's missing>`.

## 1. Find a project-local verifier

From the repository root, search these paths in order:

1. `.agents/skills/verify-*`
2. `.cursor/skills/verify-*`
3. `.claude/skills/verify-*`

A valid candidate has `SKILL.md`, launch and doctor instructions, and
`features/README.md`. Read the candidate that matches the changed application.
If several candidates could match, use changed paths and source anchors to
select one. Ask only when that evidence remains ambiguous.

The project-local verifier supplements this gate. It does not replace declared
repository checks. Confirm its commands against its source anchors before use.
If a command or path has drifted, report the documentation defect and use a
current repository declaration that checks the same behavior. Point to
`maintain-verification-skill` for repair. Stale instructions alone do not fail
the product gate when equivalent current evidence passes; an unverified affected
behavior still does.

## 2. Discover the commands once per session

Priority order, first source that names a command wins:

1. `AGENTS.md` at the repository root or nearest parent. Look for a **Checks**
   or **Verification** section that lists lint, typecheck, and test commands.
2. A valid project-local verifier's **Repository checks** section. Confirm each
   command against the source anchor that it names.
3. Manifests. Use the repository's files to find the declared checks; a
   manifest tells you where to inspect, but it never authorizes a guessed
   command. In addition to the common manifests, inspect:

   - Common repositories: `package.json` scripts (`lint`, `typecheck`/`tsc
     --noEmit`, `test`), `Makefile` targets, `justfile`, `pyproject.toml`
     (`ruff`, `mypy`, `pytest`), and `Cargo.toml`.
   - JVM/Scala: `pom.xml`, `build.gradle`, `build.gradle.kts`, and `build.sbt`.
     Check the Maven/Gradle/SBT wrapper and project or CI documentation for
     the exact check before running it.
   - Go: `go.mod` and `go.work`. Look for the check in a `Makefile`,
     `justfile`, `Taskfile.yml`, repository documentation, or CI configuration.
   - .NET: `*.sln`, `*.slnx`, `*.csproj`, `global.json`, and
     `Directory.Build.*`. Confirm the exact `dotnet` invocation in project
     documentation or CI.
   - Ruby: `Gemfile`, `*.gemspec`, and `Rakefile`. Confirm the exact Bundler or
     Rake task in project documentation or CI.
   - PHP: `composer.json`, `phpunit.xml*`, `phpstan.neon*`, and `psalm.xml*`.
     Confirm the exact Composer or analysis task in project documentation or
     CI.

   `Makefile` targets, `justfile` recipes, package scripts, and equivalent
   task definitions are declarations when they name the check directly. Do
   not turn the mere presence of a language manifest into an invented command
   such as `npm test`, `go test ./...`, `dotnet test`, `bundle exec`, or
   `composer test`.
4. CI config as ground truth of what must pass: `.gitlab-ci.yml` or GitHub
   workflows job names → map to local equivalents.

If no static command exists, report `Static checks: SKIP no commands declared`
and continue to the behavior pass. Emit `VERIFY: SKIP no executable checks`
only when neither a repository check nor a user-path proof can run. Flag that
gap to `escalate` for a non-trivial change.

## 3. Scope when possible

- Tests affected by changed files first (`pytest path/to/test.py`,
  `bun test test/foo.test.ts`). Full suite only if scoping is unclear.
- Run all repository-required checks at their declared scope. Where the
  repository supports affected-package lint, typecheck, or tests, use that scope
  when it covers the change. Do not assume full-repository checks are cheap.
- Reuse completed checks for unchanged code, dependencies, commands, and
  environment. Record the result and its scope. Rerun when an edit or environment
  change invalidates that evidence; do not repeat a check merely because a
  calling workflow already ran it.

## 4. Run repository checks

- Run independent checks concurrently when the repository permits it.
- Preserve the check's exit status when you cap its output. A trailing `tail`
  reports the pager's status, not the check's status. Use this shape:

```bash
bash <verify-changes-skill>/scripts/run-check.sh /tmp/task-check.log <command> <args...>
```

The helper runs in Bash regardless of the caller's shell and returns the original
check status. It keeps the full log for diagnosis, so inspect that log instead
of rerunning a failed check just to see its first error. Use a unique log path
per concurrent check. For a shell pipeline, pass `bash -o pipefail -c '<pipeline>'`.
A repository helper that preserves the same evidence is also valid.

## 5. Prove affected user behavior

After the repository checks pass, decide whether the diff can change mapped
user behavior.

- With a matching project-local verifier, use its source anchors and feature
  index to identify the affected features. Drive every matching feature. Run
  its launch, doctor, evidence, and cleanup steps.
- If a changed path cannot be classified from those anchors, treat it as
  affected user behavior instead of assuming that it is internal.
- If changed user-facing code has no mapped feature, use the repository's
  existing integration or end-to-end tool. Invoke `e2e-verify` for a browser.
  If no executable fallback exists, report `Behavior: FAIL unmapped affected
  user behavior` and emit `VERIFY: FAIL project-local verifier has no recipe
  for affected user behavior`. Point to `maintain-verification-skill`.
- For browser behavior, invoke `e2e-verify`. The project-local verifier owns
  launch, authentication, exact feature recipes, and evidence locations.
  `e2e-verify` owns browser assertions, console errors, traces, and retries.
- For another user interface, run the focused project-local recipe directly.
- Without a project-local verifier, use the repository's existing integration
  or end-to-end tool. Invoke `e2e-verify` for a browser. Report
  `Behavior: SKIP no project-local verifier` when no real user-path check
  exists. Do not invent a passing result.
- For a change that cannot affect user behavior, report why you skipped this
  pass.

When an intentional product change alters a mapped route, command, or result,
update the affected feature file in the same change and run that recipe. Do not
audit unrelated features. `maintain-verification-skill` owns the full audit.

## 6. On failure

Fix code (that's your job, not the gate's), re-run the failed check only.
Loop max 3 attempts (matches `escalate` soft-stop default) → call `escalate`
with the shortest reproduction of the failure.

## 7. Before PASS

- `git status --porcelain`: no unintended files staged (build artifacts,
  .DS_Store, secrets).
- Scan new content before publishing. A removed line is not a new exposure,
  but a secret added in an outgoing commit remains in that published history.

Use the repository's declared scanner first. The fallback scans additions from
an explicit base through the current worktree, including outgoing commits,
staged/unstaged edits, and untracked files. It scans each outgoing commit and
the index separately, so a later removal does not hide a committed secret:

```bash
python3 <verify-changes-skill>/scripts/scan-added-secrets.py <base-commit-or-ref>
```

For a PR, resolve the merge base with its target branch. For an incremental push,
use the verified remote tip; for a new branch, use its target merge base. `HEAD`
is valid only when checking uncommitted edits. A clean worktree does not mean
outgoing commits have been scanned. An invalid base or read failure is a scan
failure, never a clean result.

The fallback reports filenames without printing candidate secrets. Triage
matches before publishing: a documented placeholder is not an exposed credential.
Keep real secret additions out of the change and use `escalate` only when
remediation needs additional authority. Retain the scope and reason for any
false-positive dismissal.

PASS does not mean done. The calling skill decides whether to push, open MR,
or continue.
