---
name: verify-changes
description: Pre-push quality gate. Discover and run a repo's lint, typecheck, and tests, and block pushing until they pass. Triggers "verify", "run checks", "gate before push". Not for fixing code or reviewing PRs.
---

# Verify Changes

Gate every push. A diff that hasn't passed this never leaves the machine.

This is **prove-it-works** (see `principles`) with commands attached: the verdict
below is a claim about the real artifact, so never emit PASS from a run you
didn't watch finish.

## Verdicts

End with exactly one line: `VERIFY: PASS`, `VERIFY: FAIL <one-line reason>`, or
`VERIFY: SKIP <what's missing>`.

## 1. Discover the commands (once per session, cache in memory)

Priority order, first source that names a command wins:

1. `AGENTS.md` (repo root or nearest parent): look for a **Checks** /
   **Verification** section listing lint/typecheck/test commands.
2. Manifests. Use the repository's files to find the declared checks; a
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
3. CI config as ground truth of what must pass: `.gitlab-ci.yml` / GitHub
   workflows job names → map to local equivalents.

Nothing found → `VERIFY: SKIP no commands declared` and note that the repo has
no gate (flag to `escalate` if the change is non-trivial).

## 2. Scope when possible

- Tests affected by changed files first (`pytest path/to/test.py`,
  `bun test test/foo.test.ts`). Full suite only if scoping is unclear.
- Typecheck/lint are cheap, always full-repo.

## 3. Run: token rules are mandatory

- One bash call per check, chained where independent.
- Never let full logs hit context. Always cap:

```bash
<cmd> 2>&1 | tail -30
```

- On failure, re-run only the failed tool with more targeted output (e.g.
  `| head -60`) to capture the first error, not the last.

## 4. On failure

Fix code (that's your job, not the gate's), re-run the failed check only.
Loop max 3 attempts (matches `escalate` soft-stop default) → call `escalate`
with the shortest reproduction of the failure.

## 5. Before PASS

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
