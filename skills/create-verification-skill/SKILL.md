---
name: create-verification-skill
description: "Generate a project-local verification skill that records exact repository checks and drives the real app through its user-facing behavior. Use for /create-verification-skill or when a repository has no repeatable UI, CLI, API, service, or library verification path."
disable-model-invocation: true
---

# Create a verification skill

Create one project-local skill that tells a cold agent how to run the
repository checks, launch the real app, exercise user-facing behavior, and
capture proof. The generated skill complements `verify-changes` and
`e2e-verify`; it does not copy their general rules.

## 1. Interview the repository

Answer these questions from the repository. Ask the user only for facts that
the repository cannot provide.

- **User interface.** Identify what a user touches: a web UI, a CLI or TUI, a
  desktop app, an API, a mobile app, or a library. Pick the primary interface
  and note the others.
- **Repository checks.** Find the exact lint, typecheck, test, build, and
  integration commands in `AGENTS.md`, manifests, task files, and CI. Record
  only declared commands.
- **Run.** Find the documented local start command. Record ports, environment
  variables, seed data, and authentication.
- **Drive.** Prefer an existing Playwright, Cypress, PTY, HTTP, or debug
  harness. For browser behavior, apply `e2e-verify` instead of restating its
  browser rules.
- **Observe.** Identify useful proof, such as screenshots, terminal
  transcripts, response bodies, logs, exit codes, and stored state.
- **Isolate.** Determine whether two instances can run at once. If they cannot,
  make the generated skill refuse to drive a shared instance.

If the checkout cannot build or start, report the exact blocker. Fix product
code only when the current request includes that work. Do not generate
instructions against a broken base. The generated skill may create disposable
verification data when an irrelevant missing asset blocks startup. Mark that
data and remove it during cleanup.

## 2. Pick one project-local skill root

Use an existing repository convention when one exists:

1. `.agents/skills`
2. `.cursor/skills`
3. `.claude/skills`

If the repository has no local skill root, use
`.agents/skills/verify-<app>/`. Keep one authoritative copy. Do not duplicate
the skill across host-specific directories because the copies will drift.

## 3. Generate the skill

Under the selected root, write `verify-<app>/SKILL.md` with YAML frontmatter.
Set `name` to `verify-<app>`. In the description, name the application, the
user interface, and the situations that require the skill. Keep automatic
model invocation enabled for the generated verifier so `verify-changes` and
ordinary task workflows can select it.

Ground these sections in repository evidence. Leave no placeholders.

- **Source anchors.** List the files that define check commands, startup,
  routes or commands, authentication, and the existing control harness. Map
  each user-facing source path to one or more feature IDs. Mark known
  user-facing paths that are not mapped. These paths let
  `verify-changes` find affected recipes and let `maintain-verification-skill`
  detect drift.
- **Repository checks.** List the exact static and integration commands, their
  working directories, and safe focused forms. State which repository file
  declares each command.
- **Launch.** Give the exact start command, the readiness signal, and teardown.
  For a short-lived CLI or TUI, build once and start each drive in an isolated
  PTY or tmux session.
- **Doctor.** Provide one read-only check for the process, build, port, data
  directory, and authentication that matter. Run it before a drive whenever
  the instance behaves unexpectedly.
- **Drive.** Give real selectors or commands from this repository. Prefer ARIA
  labels, data attributes, prompt strings, and route paths over coordinates or
  tab order.
- **Evidence.** Name the artifact location and proof standard. Exercise the
  real user path. Capture the action and result. Verify stored side effects
  through a second read-only view. Use mocks only at an existing production
  boundary.
- **Cleanup.** Stop only the processes that the run started. Remove disposable
  state, but keep evidence at the named path.
- **Helpers.** Make owned scripts executable and document each invocation in
  the skill body.

If the safe path is a dry run or test mode, observe what it skips. Do not trust
the mode's name. Check files, network calls, git refs, or other affected state.

## 4. Seed the feature map

Create `features/README.md` and one file for each of the three to five most
important user-facing features. Derive the list from routes, commands, menus,
or product docs. Use
[`references/feature-map-example/`](references/feature-map-example/) as the
shape.

Each feature file describes the behavior from the user's point of view. Use
these four H2 sections in order:

1. `Sub-features`
2. `How to get to it (user POV)`
3. `Driving it with <harness>`
4. `Gotchas`

List every known user entry point and the observable result that proves it.
Testing one convenient entry point does not verify the others.

## 5. Prove the generated skill

Run the generated instructions end to end once:

1. Run the repository checks.
2. Launch the app and run the doctor check.
3. Drive one mapped feature.
4. Capture evidence.
5. Clean up.
6. Confirm that the evidence still exists.

Fix failures and repeat the affected step. Clean up after every failed drive so
the run does not strand processes, ports, or data. A generated skill that has
not completed this proof is a draft.

## 6. Hand off maintenance

Report the generated skill path, the feature that you drove, the exact checks,
and the evidence path. Point the user at `maintain-verification-skill` for a
full drift audit. Suggest a maintenance schedule only when the user asks.
