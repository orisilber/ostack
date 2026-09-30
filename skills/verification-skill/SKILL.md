---
name: verification-skill
description: "Create or audit a project-local verification skill that records exact repository checks and drives the real app through its user-facing behavior. Use for /verification-skill create, /verification-skill audit, or when a repository has no repeatable UI, CLI, API, service, or library verification path."
disable-model-invocation: true
---

# Verification skill

A project-local verifier tells a cold agent how to run the repository checks,
launch the real app, exercise user-facing behavior, and capture proof. It
complements `verify-changes` and `e2e-verify`; it does not copy their general
rules.

Two modes:

- **create**: generate `verify-<app>` for a repository that has none.
- **audit**: bring an existing verifier back in line with the source and live
  behavior. With no mode named, audit when a verifier exists and create
  otherwise.

The shape of a verifier is fixed by
[references/verifier-template.md](references/verifier-template.md). Check it
with `python3 <this skill>/scripts/lint-verifier.py <verifier-dir>` after every
edit; a verifier that fails the linter is not done.

## Locate the verifier

Search `.agents/skills/verify-*`, `.cursor/skills/verify-*`, and
`.claude/skills/verify-*` from the repository root. If several describe
different applications, ask which one. For create, a verifier that already
covers the application gets extended, not duplicated; a second one splits the
feature map. Otherwise use the existing local skill root in that order, or
`.agents/skills/verify-<app>/` when none exists. Keep one authoritative copy;
host-specific duplicates drift.

The verifier is a committed file. Record where each credential comes from,
never its value, and keep session state, tokens, and key files outside the
repository. Add the evidence path to the repository's ignore file.

## Create

1. **Interview the repository.** Answer from the repository; ask the user only
   for facts it cannot provide.
   - **Interface.** What a user touches: web UI, CLI or TUI, desktop app, API,
     mobile app, or library. Pick the primary one and note the others.
   - **Checks.** Exact lint, typecheck, test, build, and integration commands
     from `AGENTS.md`, task files, and CI. Record only declared commands.
   - **Run.** The documented start command, ports, environment variables, seed
     data, and authentication.
   - **Drive.** Prefer an existing Playwright, Cypress, PTY, HTTP, or debug
     harness. For browser behavior, apply `e2e-verify`.
   - **Observe.** Screenshots, terminal transcripts, response bodies, logs,
     exit codes, and stored state.
   - **Isolate.** Whether two instances can run at once. If they cannot, the
     verifier refuses to drive a shared instance.

   If the checkout cannot build or start, report the exact blocker; do not
   write instructions against a broken base. Fix product code only when the
   request includes that work.
2. **Write `SKILL.md`** from the template. Keep automatic invocation enabled so
   `verify-changes` and ordinary workflows can select it. Ground every section
   in repository evidence, and prefer ARIA labels, data attributes, prompt
   strings, and route paths over coordinates. If the safe path is a dry run or
   test mode, observe what it skips instead of trusting its name. Make owned
   helper scripts executable and document each invocation.
3. **Seed the feature map.** Write `features/README.md` and one file for each
   of the three to five most important user-facing features, derived from
   routes, commands, menus, or product docs. Follow
   [references/feature-map-example/](references/feature-map-example/). Each
   index entry ends with a status: `verified`, `draft`, or
   `verified-unreachable`, written as ``Status: `draft`.`` List
   every user entry point and the observable result that proves it; testing
   one convenient entry point does not verify the others. Map each feature's
   source paths in the anchors table, and mark known user-facing paths with no
   feature as `unmapped`.
4. **Prove it.** Run the checks, launch, run the doctor, drive each feature you
   claim as verified, capture evidence, clean up, and confirm the evidence
   survived cleanup. Run the written instructions, not your memory of them.
   Clean up after every failed drive. Mark features you did not drive `draft`.
   Set `Last verified:` to the commit you proved against, or `never` if nothing
   was driven.
5. **Report** one outcome with the verifier path, feature statuses, exact
   checks, and evidence path. **created**: no feature is `draft`. **draft**:
   name the undriven features. **existing**: a current verifier already covers
   the application and nothing was written. **blocked**: name the blocker.

## Audit

Edit only the verifier directory: its `SKILL.md`, `features/`, and owned
scripts. Never edit product code. A mapped behavior that no longer works is
either documentation drift, which you correct, or a product regression, which
you report without hiding it in the map.

1. **Scope from history.** Read `Last verified:`. When it names a commit, list
   `git diff --name-only <sha>..HEAD` and map each changed path to features
   through the anchors table by path prefix. Changed user-facing paths that no
   anchor covers are candidate new features or `unmapped` rows. A full audit,
   a `never` value, or an unreachable commit covers every feature. State the
   scope and the features left out.
2. **Lint.** Run the linter and fix structural failures first.
3. **Read each feature in scope from source.** Compare its entry points,
   handles, and results with the code the anchors name, and each repository
   check with the file that declares it. Delegate reading to read-only
   subagents only when the feature set is large and independent.
4. **Drive every feature in scope.** One long-lived instance for servers and
   UIs, or one isolated session per short-lived CLI drive, as the verifier
   specifies. Run the doctor before the first drive, on each fresh session, and
   after a surprising failure. Preserve evidence across cleanup. Promote a
   `draft` to `verified` only after a live drive, and mark a feature
   `verified-unreachable` only with the named prerequisite and attempted route.
   A `draft` recipe that cannot drive the behavior is drift, not a product
   failure.
5. **Triage each mismatch.** A wrong user description is documentation drift;
   correct it. A control script that cannot drive working behavior is a control
   gap; fix and re-drive it. Broken application behavior is a product gap;
   report it.
6. **Finish.** Advance `Last verified:` to `HEAD` when every feature in scope
   passed and the scope covered everything changed since the old value. An
   audit the user narrowed further leaves it alone. Run `verify-changes` after
   corrections and re-read every changed file.

Report one outcome. **clean**: everything in scope passed and nothing changed;
no commit or MR. **changed**: the local change holds proven corrections; commit,
push, or open an MR only when the user asked. **blocked**: name the exact
blocker.
