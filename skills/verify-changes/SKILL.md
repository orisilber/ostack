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
If a command or path has drifted, use the current repository declaration for
diagnosis and return `VERIFY: FAIL project-local verifier is stale`. Point to
`maintain-verification-skill`.

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
- Typecheck/lint are cheap, always full-repo.

## 4. Run repository checks

- One bash call per check, chained where independent.
- Never let full logs hit context. Always cap:

```bash
<cmd> 2>&1 | tail -30
```

- On failure, re-run only the failed tool with more targeted output (e.g.
  `| head -60`) to capture the first error, not the last.

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
- Secret scan over all to-be-committed content (staged + unstaged tracked):

```bash
git diff HEAD | grep -inE "sk-[a-z0-9]{8,}|AKIA[A-Z0-9]{8,}|BEGIN.*PRIVATE KEY"
```

Match means hard stop → `escalate`. Untracked files: eyeball `git status`
output for filenames that look like env/key files before staging.

PASS does not mean done. The calling skill decides whether to push, open MR,
or continue.
