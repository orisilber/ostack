# Build ostack-mode as a composable orchestrator

Build `/ostack-mode` as the Cursor-first entry point for ostack. It classifies
the task, selects an implemented playbook, delegates each role on a resolved
model, and stops at the outcome the user requested.

The first useful release handles investigations, bug fixes, features, and
refactors. It can leave a verified local change, open a GitLab MR, or drive the
MR to merge-ready. It does not merge, deploy, release, or invent a larger
outcome than the prompt authorizes.

## Done condition

The work is done when all of these statements are true:

- [ ] Cursor can activate `ostack-mode` as a Custom Mode and keep its
      instructions in context for the session.
- [ ] The mode classifies both the task kind and the requested outcome before
      it chooses a playbook.
- [ ] Every route points to an installed playbook. The route registry contains
      no placeholders for future playbooks.
- [ ] Every subagent model resolves from one ostack configuration or to
      `inherit`. No skill guesses an unavailable model ID.
- [ ] `escalate` owns hard stops. The mode cannot weaken them.
- [ ] Every code-changing route runs `verify-changes` before an MR push or a
      success report.
- [ ] The static validator, `evals/lint.sh`, the headless scenarios, and the
      Cursor test matrix all pass.
- [ ] A non-frontend repository completes the same flow without a hardcoded
      JavaScript, Python, or frontend command in a playbook.

## Keep these constraints

### Build for Cursor first

Use Cursor's documented skill and subagent contracts as the baseline. Activate
the skill as a Custom Mode for session persistence. Keep
`disable-model-invocation: true` so the model does not enter the mode without
an explicit user action. Recheck the current
[skill contract](https://cursor.com/docs/skills) and
[subagent contract](https://cursor.com/docs/subagents) before Change 8 because
these host APIs can change.

Do not make `mode: true` a required mechanism. Cursor's current public skill
frontmatter does not document that field. Add it only if the live Cursor test
shows that it changes behavior and does not break skill validation.

Pass either `inherit` or a configured model ID to a Cursor subagent. Cursor can
fall back when an account or a team policy does not allow a requested model, so
a successful `Task` call does not prove model entitlement. Use a model list
exposed by the current host when one exists. Otherwise offer only `inherit` and
model IDs the user supplies.

Claude Code is best-effort. It can invoke the skill, but it does not have to
match Cursor's Custom Mode behavior or model roster. On a host that cannot use
a configured model ID, resolve the role to `inherit` and state the fallback.

### Keep verification independent of the project type

Every playbook delegates repository checks to `verify-changes`. A playbook may
invoke a domain-specific verifier only when the changed files require it. For
example, a UI change can also invoke `e2e-verify`, and a TypeScript change can
apply `typescript-best-practices`.

Do not put `npm`, `pytest`, `go test`, `sbt`, or another project command in an
ostack-mode playbook. `verify-changes` discovers the command from repository
instructions, manifests, or CI.

### Stop at the requested outcome

Classify a request on two separate axes.

The task kind selects the base playbook:

- `investigation`
- `bug-fix`
- `feature`
- `refactoring`
- later task kinds that have an implemented playbook

The outcome selects the optional tail:

- `answer`
- `local-change`
- `mr-open`
- `merge-ready`

Use these defaults:

- A read-only question defaults to `answer`.
- A request to change code defaults to `local-change`.
- Only an explicit request to open or create an MR selects `mr-open`.
- Only an explicit request to babysit, get green, or reach merge-ready selects
  `merge-ready`.

Never infer `mr-open` or `merge-ready` from the existence of a ticket, a branch,
or a GitLab remote. Opening an MR, posting `!review`, and replying to reviewers
are external writes. The selected outcome is the most the run may do.

## Define the contracts before the workflows

### Route registry

Create `skills/ostack-mode/references/routes.json`. This file is the only list
of implemented routes and outcome tails.

After Change 2, the registry has this shape:

```json
{
  "version": 1,
  "routes": [
    {
      "id": "bug-fix",
      "match": "The user reports a defect and asks to change code.",
      "playbook": "playbooks/bug-fix.md",
      "defaultOutcome": "local-change",
      "allowedOutcomes": ["local-change", "mr-open", "merge-ready"]
    }
  ],
  "outcomeTails": {
    "answer": [],
    "local-change": [],
    "mr-open": ["playbooks/opening-an-mr.md"],
    "merge-ready": [
      "playbooks/opening-an-mr.md",
      "skill:babysit-gitlab-mr"
    ]
  }
}
```

Add a route only in the same change that adds its playbook and its scenarios.
The mode reads the registry, chooses one route, and copies the base playbook
steps followed by the selected tail steps into its task list. A skipped step
stays visible with a reason.

Resolve the route in this order:

1. Resolve the outcome. Honor negative constraints such as "do not edit" and
   "do not open an MR" before positive task words such as "bug" or "feature".
2. If the user explicitly names a route ID, select it only when it allows the
   resolved outcome.
3. Otherwise, read the route array in order and select the first entry whose
   `match` statement fits and whose allowed outcomes include the resolved
   outcome. Array order is route precedence.
4. If no implemented route fits, work normally with the applicable leaf skills.
   Do not invent a route or load the nearest playbook.

State the selected pair once in the first progress update as
`Route: <task-kind> -> <outcome>`. State `Route: none` when the fallback runs.
The headless scenarios use this line as one observable routing result.

### Model configuration

Create `skills/ostack-mode/references/models.example.json` with the schema
below. Store the user's canonical model configuration at
`~/.config/ostack/models.json`. Allow `OSTACK_CONFIG_HOME` to replace
`~/.config/ostack` for tests and nonstandard installations.

Use one shape for single-model and panel roles. Every value is a non-empty
array, even when a role uses one model:

```json
{
  "version": 1,
  "roles": {
    "exploration": ["inherit"],
    "implementation": ["inherit"],
    "judgment": ["inherit"],
    "prose": ["inherit"]
  },
  "overrides": {
    "how.explorer": ["inherit"],
    "how.explainer": ["inherit"],
    "how.critics": ["inherit"]
  }
}
```

Resolve a subagent model in this order:

1. Use the exact skill-role override when it exists.
2. Use the generic role when the skill declares one.
3. Use `inherit`.

A role that launches one subagent uses the first configured entry. A panel role
uses every configured entry once. `inherit` must be the only entry in its
array. Reject empty strings and duplicate entries.

Treat a missing file, an invalid file, or an empty model array as a recoverable
configuration error. Report the fallback once and use `inherit`. If the host
explicitly rejects a single-model role, use `inherit`. If it rejects one panel
entry, continue with the remaining entries and use `inherit` only when none
remain. Do not pick a nearby model ID.

Cursor may substitute a model without returning an error. When the host exposes
the model that ran, record a substitution once. When it does not, report the
requested model as requested, not confirmed. Do not claim that a successful
subagent call proves which model executed it.

Migrate `architect`, `arena`, `how`, `interrogate`, `swarm`, and `why` from
`pstack-models.mdc` in the same change that adds the ostack configuration.
After that change, no ostack skill reads pstack's model file. Do not delete or
edit pstack's file because pstack still owns it.

### Static validator

Create `skills/ostack-mode/scripts/validate.sh` and call it from
`evals/lint.sh`. Use `jq` for the JSON checks.

The validator fails when:

- the registry or the model-config example has an unsupported version;
- a route ID is empty or duplicated;
- a route has an empty `match` statement;
- a route references a missing playbook;
- a route has no allowed outcome;
- a default outcome is not allowed;
- an outcome tail references a missing playbook or an unknown skill;
- a listed playbook is not reachable from a route or a tail;
- a playbook contains a literal project-specific verification command;
- a model array is empty, contains duplicates, or combines `inherit` with a
  model ID;
- an ostack skill still references `pstack-models.mdc` after the migration.

Add validator fixtures for one valid registry and each failure class. The
negative fixtures prove that every failure path works.

Change 1 implements the registry and playbook checks. Change 3 adds the model
checks and the ban on ostack references to `pstack-models.mdc` when it performs
the model migration. The validator must pass at the end of every change.

## Implement in verifiable changes

### Change 1: add the route contract and validator

- [ ] Create a valid `skills/ostack-mode/SKILL.md` with the frontmatter, route
      lookup, `Route: none` progress line, and no-route fallback. It exposes no
      incomplete workflow.
- [ ] Create `skills/ostack-mode/references/routes.json` with an empty `routes`
      array. Include all four outcome-tail keys, but keep every tail array empty
      until its referenced playbook exists.
- [ ] Create `skills/ostack-mode/references/models.example.json` with the model
      schema and `inherit` for every generic role.
- [ ] Create `skills/ostack-mode/scripts/validate.sh`.
- [ ] Add positive and negative validator fixtures.
- [ ] Call the validator from `evals/lint.sh`.
- [ ] Run `evals/lint.sh` and the validator tests.

This change establishes the data shape before the mode contains a task route.
The repository lint passes because the new skill directory already contains a
valid `SKILL.md`.

### Change 2: deliver the bug-fix path end to end

- [ ] Extend `skills/ostack-mode/SKILL.md` with route selection, the maximum
      allowed outcome, model-resolution fallback, task-list copying, ownership
      of delegated work, and `escalate` precedence.
- [ ] Create `skills/ostack-mode/references/playbooks/bug-fix.md`.
- [ ] Make the base flow invoke `reproduce-first`, implement the fix, and invoke
      `verify-changes`.
- [ ] Create `skills/ostack-mode/references/playbooks/opening-an-mr.md`.
- [ ] Make the MR tail run only after `VERIFY: PASS`. Use `technical-writing`
      and `unslop` for the title and description.
- [ ] Make the MR tail idempotent. Resolve and return an existing MR before it
      creates one. Re-running the tail must not create a second MR.
- [ ] Add `bug-fix` to `routes.json` with `local-change`, `mr-open`, and
      `merge-ready` as allowed outcomes.
- [ ] Compose `merge-ready` from the MR tail and `babysit-gitlab-mr`. Do not
      duplicate the babysit procedure in the playbook.
- [ ] Add headless scenarios for every bug-fix outcome.
- [ ] Run the static and headless checks.

The local-change scenario must prove that no `glab` write occurs. The MR-open
scenario must prove that verification completes before `glab mr create`. The
merge-ready scenario must prove that the babysit flow starts only after the MR
exists.

### Change 3: add model setup and migrate every caller

- [ ] Create `skills/setup-ostack-mode/SKILL.md`.
- [ ] Use `skills/ostack-mode/references/models.example.json` as the schema
      example and validator fixture. Do not use the inline plan example as
      runtime input.
- [ ] Read the current configuration when it exists.
- [ ] Read host-exposed model IDs when the host provides them. If it does not,
      offer `inherit` and accept IDs supplied by the user.
- [ ] Ask for the four generic role choices in one batch. Offer skill-role
      overrides only when the user asks for advanced configuration or the
      current file already contains them.
- [ ] Validate the complete candidate configuration before replacing the
      existing file.
- [ ] Write through a temporary file and rename it so interruption cannot leave
      partial JSON.
- [ ] Preserve the previous valid configuration when validation or the write
      fails.
- [ ] Migrate `architect`, `arena`, `how`, `interrogate`, `swarm`, and `why` to
      the new resolution order.
- [ ] Delete the ostack fallback tables that contain guessed model IDs. Keep
      `inherit` as the pre-configuration default.
- [ ] Add scenarios for first setup, update, invalid input, missing host model
      discovery, and an explicit model rejection.
- [ ] Run the static and headless checks.

This is one migration. Do not leave some ostack skills on pstack's roster and
others on the new configuration between changes.

### Change 4: add the common routes

- [ ] Add `investigation.md`. Use `how` for behavior and structure. Add `why`
      only for motivation or history. Do not edit files, open an MR, or invoke
      `architect` unless a later user request starts a code change.
- [ ] Allow only the `answer` outcome for `investigation`.
- [ ] Add `feature.md`. Name the data shape, invoke `architect` only when the
      change crosses a meaningful boundary, implement, and verify.
- [ ] Add `refactoring.md`. Apply the Laziness Protocol and Subtract Before You
      Add. Invoke `architect` only when the refactor changes module boundaries.
- [ ] Allow `local-change`, `mr-open`, and `merge-ready` for `feature` and
      `refactoring`.
- [ ] Add each route to `routes.json` only when its playbook and scenarios exist.
- [ ] Add a fallback scenario whose prompt matches no route. Confirm that the
      mode does not force a playbook.
- [ ] Run the static and headless checks.

Do not invoke `arena` for every feature. Use it only when two or more viable
shapes would commit the work to different boundaries or interactions.

### Change 5: make verify discovery cover more repositories

- [ ] Extend `verify-changes` manifest discovery for JVM and Scala repositories,
      including `build.sbt`, `pom.xml`, `build.gradle`, and
      `build.gradle.kts`.
- [ ] Add discovery cases for common repositories that the current list misses,
      including Go, .NET, Ruby, and PHP.
- [ ] Prefer explicit commands from `AGENTS.md`. Then inspect manifests. Use CI
      as the last source of repository-specific commands.
- [ ] Return `VERIFY: SKIP no commands declared` when no source names a command.
      Do not guess one from the language alone.
- [ ] Add at least one JVM or Scala scenario and one non-JVM scenario.
- [ ] Run the static and headless checks.

The manifest list is an index of places to inspect, not a table of commands to
run blindly. A Gradle wrapper, a monorepo task, or an `AGENTS.md` instruction can
change the correct command.

### Change 6: add playbooks that reuse existing ostack skills

Add these playbooks in separate, reviewable changes. Each change updates the
registry, adds scenarios, and passes all checks.

- [ ] `eval.md` wraps `evals/lint.sh` and the YAML scenario runner.
- [ ] `authoring-a-skill.md` uses `principles`, `technical-writing`, `unslop`,
      and the eval checks.
- [ ] `session-pickup.md` delegates to `recall`.
- [ ] `pause-safely.md` leaves a durable resume note and uses
      `show-me-your-work` when a decision trail already exists or the run needs
      one.
- [ ] `prototype.md` uses `arena` only when the decision needs competing
      artifacts. Keep all prototypes outside production source.
- [ ] `visual-parity.md` uses `e2e-verify` screenshots. Start with labeled
      side-by-side review. Add pixel diffing only when a real task needs a
      numeric threshold.
- [ ] `multi-phase-plan.md` creates verifiable phase boundaries. Invoke
      `decompose-epic` only when the source is a Jira epic. A generic plan must
      not create or edit Jira tickets.
- [ ] `worktree-cleanup.md` resolves exact worktree paths before any deletion
      and asks before destructive cleanup that the prompt did not authorize.

### Change 7: update the repository docs

- [ ] Add an Orchestration section to `README.md` for `ostack-mode` and
      `setup-ostack-mode`.
- [ ] State that Custom Mode activation provides session persistence. Do not
      claim that slash invocation alone is sticky.
- [ ] Update the Provenance section with the scope of the pstack adaptation.
- [ ] Add `ostack-mode` to `NOTICE` because its routing and playbook mechanism
      derive from pstack's `poteto-mode`, even though the routes and playbook
      text are ostack-specific.
- [ ] Add `make-bot-ui` to the deliberate exclusions with its Cursor-team
      integration reason.
- [ ] Confirm that `scripts/install.sh` copies the nested playbooks and scripts
      in a dry run. Change the installer only if the check fails.
- [ ] Run all static and headless checks.

### Change 8: validate the real Cursor behavior

Run this matrix inside Cursor. Record the Cursor version, the selected parent
model, the route, the resolved role models, the commands or tool effects, and
the final outcome for each case.

| Prompt | Route | Outcome | Required evidence |
|---|---|---|---|
| "Explain why this bug occurs" | `investigation` | `answer` | No edits and no `glab` writes |
| "Fix this bug" | `bug-fix` | `local-change` | A failing reproduction, a passing reproduction, and `VERIFY: PASS` |
| "Fix this bug and open an MR" | `bug-fix` | `mr-open` | Verification precedes `glab mr create`; no `!review` note |
| "Fix this bug and get the MR merge-ready" | `bug-fix` | `merge-ready` | The MR exists before the babysit flow starts |
| "Add this behavior" | `feature` | `local-change` | The data shape is named and the verified change stays local |
| "Move this code without changing behavior" | `refactoring` | `local-change` | Behavior checks pass and no feature route runs |
| "Change this Spark job" | `feature` | `local-change` | Repository-specific verification without a frontend command |
| A prompt with no matching route | none | prompt-derived | The applicable leaf skills run without a fabricated playbook |

Also verify these host behaviors:

- [ ] Custom Mode keeps the skill active across follow-up turns.
- [ ] Slash invocation without Custom Mode does not get documented as sticky.
- [ ] A missing model configuration resolves every role to `inherit`.
- [ ] An explicitly rejected model reports one fallback and continues on
      `inherit`. A silent host substitution does not produce a false claim that
      the requested model ran.
- [ ] `escalate` stops an irreversible action even when the selected playbook
      says to continue.
- [ ] `skills/ostack-mode/SKILL.md` stays a router. Workflow detail remains in
      playbooks and model detail remains in the configuration reference.

Do not call the work done until this matrix passes. Cursor-specific behavior is
the product, so headless prose checks alone cannot prove it.

## Keep these items out of scope

Do not add these playbooks until ostack has a leaf skill that can perform and
verify the work:

- `perf-issue`
- `hillclimb`
- `runtime-forensics`
- `trace-forensics`

Do not port these pstack workflows now:

- `shipping`
- `autopilot-full`
- `autopilot-stack`
- `orchestrate`

They assume Graphite stacks, release authority, or a project-scale coordinator.
`babysit-gitlab-mr` already owns the flat GitLab MR path through merge-ready.

## Record the decisions already made

### Pstack parity audit

The 2026-08-28 audit checked all 44 pstack catalog entries against `NOTICE` and
`README.md`.

`make-bot-ui` is a deliberate exclusion. It depends on Cursor-team internals,
including a Grok Bot webhook, `update_state`, and sender-key handling.

`automations/benny/` is not a skill. It is a Slack-triggered Cursor automation
for bug triage, reproduction, and a draft fix. Ostack uses Jira and GitLab and
has no Slack intake path. Reconsider it only if Slack becomes a real source of
work. Use `reproduce-first` for the reproduction stage if that happens.

### Stacked GitLab MRs

GitLab can target an MR at another branch, but it does not provide Graphite's
restacking workflow. `git-spice` already supplies stack creation, submission,
restacking, and synchronization for GitLab.

Do not adopt it now. Reconsider `git-spice` only when dependent Jira tickets
regularly block review before the parent MR can merge. Until then, keep one MR
with ordered, independently verifiable commits or use sequential MRs.
