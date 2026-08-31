# Implement ostack-mode

Use this backlog to implement
[`ostack-mode-plan.md`](ostack-mode-plan.md). Each ticket fits one agent session,
names its files, and ends in an objective check.

The route registry is the only shared write bottleneck. Tickets that edit
`skills/ostack-mode/references/routes.json` run in one ordered lane. The model,
verification, documentation, and Cursor-validation lanes run in parallel when
their dependencies allow it.

## Run the phases in this order

### Phase 1: build the independent foundations

Run both tickets at the same time. Their file scopes do not overlap.

- [ ] `OSM-001` adds the mode contract and its deterministic validator.
- [ ] `OSM-002` expands repository-check discovery.

### Phase 2: deliver the first route and the model migration

Start this phase after `OSM-001`. Run both tickets at the same time.

- [ ] `OSM-003` delivers the bug-fix route through merge-ready.
- [ ] `OSM-004` adds model setup and migrates every model-aware skill.

### Phase 3: add the common routes

Start `OSM-005` after both Phase 2 tickets. This ticket owns the route registry
until it finishes.

- [ ] `OSM-005` adds investigation, feature, and refactoring routes.

### Phase 4: expand, document, and test the core in parallel

Start all three tickets after `OSM-005`. Their file scopes do not overlap.

- [ ] `OSM-006` adds the operational playbooks.
- [ ] `OSM-007` updates installation and provenance documentation.
- [ ] `OSM-008` runs the core Cursor matrix and records the evidence.

### Phase 5: add prototype and visual-parity routes

Start this phase after `OSM-006`. This ticket resumes ownership of the route
registry.

- [ ] `OSM-009` adds prototype and visual-parity playbooks.

### Phase 6: add planning and cleanup routes

Start this phase after `OSM-009`.

- [ ] `OSM-010` adds multi-phase planning and worktree cleanup.

### Phase 7: run the final acceptance gate

Start this phase after `OSM-002`, `OSM-007`, `OSM-008`, and `OSM-010` finish.

- [ ] `OSM-011` runs every static, headless, and live check.

## Parallel lanes

```text
Foundation lane   OSM-001 -> OSM-003 -> OSM-005 -> OSM-006 -> OSM-009 -> OSM-010
Model lane                  OSM-004 ------------------------------┐
Verify lane        OSM-002 --------------------------------------|
Docs lane                                        OSM-007 --------|
Cursor lane                                      OSM-008 --------|
                                                                v
                                                             OSM-011
```

`OSM-003`, `OSM-005`, `OSM-006`, `OSM-009`, and `OSM-010` are the route-registry
lane. Do not run two of them at once. Every other ticket can run as soon as its
declared dependencies finish.

## Ticket summary

| ID | Summary | Type | Scope | Depends on |
|---|---|---|---|---|
| `OSM-001` | Add the mode contract and validator | Story | New `ostack-mode` core, `evals/lint.sh`, validator fixtures | None |
| `OSM-002` | Expand repository-check discovery | Story | `verify-changes`, its discovery scenarios | None |
| `OSM-003` | Deliver the bug-fix route | Story | Mode router, route registry, bug and MR playbooks, bug scenarios | `OSM-001` |
| `OSM-004` | Add model setup and migrate callers | Story | Setup skill, model contract, six model-aware skills, setup scenarios | `OSM-001` |
| `OSM-005` | Add the common routes | Story | Route registry, three playbooks, route scenarios | `OSM-003`, `OSM-004` |
| `OSM-006` | Add operational playbooks | Story | Route registry, four playbooks, route scenarios | `OSM-005` |
| `OSM-007` | Document ostack-mode | Story | `README.md`, `NOTICE`, installer only if needed | `OSM-004`, `OSM-005` |
| `OSM-008` | Validate the core in Cursor | Story | Cursor evidence report only | `OSM-002`, `OSM-003`, `OSM-004`, `OSM-005` |
| `OSM-009` | Add prototype and visual parity | Story | Route registry, two playbooks, route scenarios | `OSM-006` |
| `OSM-010` | Add planning and cleanup routes | Story | Route registry, two playbooks, route scenarios | `OSM-009` |
| `OSM-011` | Run the final acceptance gate | Story | Final evidence report only | `OSM-002`, `OSM-007`, `OSM-008`, `OSM-010` |

## OSM-001: add the mode contract and validator

Create the smallest valid `ostack-mode` skill. It has no task routes yet. It
reads an empty registry, reports `Route: none`, and falls back to the applicable
leaf skills.

**Files.**

- Create `skills/ostack-mode/SKILL.md`.
- Create `skills/ostack-mode/references/routes.json`.
- Create `skills/ostack-mode/references/models.example.json`.
- Create `skills/ostack-mode/scripts/validate.sh`.
- Create `evals/fixtures/ostack-mode-validator/**`.
- Edit `evals/lint.sh`.

**Acceptance criteria.**

- [ ] `SKILL.md` has valid frontmatter and
      `disable-model-invocation: true`.
- [ ] `routes.json` has version 1, an empty route array, and four empty outcome
      tails.
- [ ] `models.example.json` has version 1 and resolves every generic role to
      `inherit`.
- [ ] Invoking the mode with the empty registry emits `Route: none` and does not
      invent a playbook.
- [ ] `validate.sh` rejects every failure class named in the implementation
      plan.
- [ ] Positive and negative validator fixtures pass.
- [ ] `evals/lint.sh` invokes the validator and reports `LINT: PASS`.

**Out of scope.** Do not add a bug, feature, investigation, or refactoring
route. Do not change any existing model-aware skill.

## OSM-002: expand repository-check discovery

Teach `verify-changes` where to find declared checks in more repositories. Keep
the existing priority: `AGENTS.md`, manifests, then CI. A manifest identifies
where to inspect. It does not authorize a guessed command.

**Files.**

- Edit `skills/verify-changes/SKILL.md`.
- Create `evals/scenarios/verify-changes/jvm-discovery.yaml`.
- Create `evals/scenarios/verify-changes/go-discovery.yaml`.

**Acceptance criteria.**

- [ ] Discovery recognizes `build.sbt`, `pom.xml`, `build.gradle`, and
      `build.gradle.kts`.
- [ ] Discovery covers Go, .NET, Ruby, and PHP manifests.
- [ ] `AGENTS.md` still wins when it declares a check.
- [ ] An unknown repository returns `VERIFY: SKIP no commands declared`.
- [ ] The JVM and Go scenarios prove command discovery without a frontend
      command.
- [ ] `evals/lint.sh` and the new scenarios pass.

**Out of scope.** Do not add project commands to an ostack-mode playbook. Do not
change the mode router or the route registry.

## OSM-003: deliver the bug-fix route

Deliver one complete route before adding breadth. The route reproduces the
defect, implements the fix, verifies the repository, and stops at the requested
outcome.

**Files.**

- Edit `skills/ostack-mode/SKILL.md`.
- Edit `skills/ostack-mode/references/routes.json`.
- Create `skills/ostack-mode/references/playbooks/bug-fix.md`.
- Create `skills/ostack-mode/references/playbooks/opening-an-mr.md`.
- Create `evals/scenarios/ostack-mode/bug-fix-local.yaml`.
- Create `evals/scenarios/ostack-mode/bug-fix-mr-open.yaml`.
- Create `evals/scenarios/ostack-mode/bug-fix-merge-ready.yaml`.

**Acceptance criteria.**

- [ ] The route matcher resolves the outcome before it selects the task kind.
- [ ] "Fix this bug" selects `bug-fix -> local-change`.
- [ ] The local route invokes `reproduce-first` before implementation and
      invokes `verify-changes` afterward.
- [ ] The local route performs no `glab` write.
- [ ] The MR-open route creates or resolves one MR only after `VERIFY: PASS`.
- [ ] Re-running the MR tail returns the existing MR and does not create a
      duplicate.
- [ ] The merge-ready route invokes `babysit-gitlab-mr` only after the MR exists.
- [ ] `escalate` still stops an irreversible action.
- [ ] `evals/lint.sh` and all three scenarios pass.

**Out of scope.** Do not add feature, investigation, or refactoring routes. Do
not merge, deploy, or release.

## OSM-004: add model setup and migrate callers

Add one ostack model configuration and move every model-aware skill to it in
the same change. Missing or invalid configuration resolves to `inherit`.

**Files.**

- Create `skills/setup-ostack-mode/SKILL.md`.
- Edit `skills/ostack-mode/references/models.example.json`.
- Edit `skills/ostack-mode/scripts/validate.sh`.
- Edit `skills/architect/SKILL.md`.
- Edit `skills/arena/SKILL.md`.
- Edit `skills/how/SKILL.md`.
- Edit `skills/interrogate/SKILL.md`.
- Edit `skills/swarm/SKILL.md`.
- Edit `skills/why/SKILL.md`.
- Create `evals/scenarios/setup-ostack-mode/**`.

**Acceptance criteria.**

- [ ] Setup reads and validates `~/.config/ostack/models.json`.
- [ ] `OSTACK_CONFIG_HOME` replaces the default directory in tests.
- [ ] Setup asks for the four generic roles in one batch.
- [ ] Setup offers overrides only for an existing advanced configuration or an
      explicit advanced request.
- [ ] Setup validates a complete candidate before an atomic replacement.
- [ ] A failed write preserves the previous valid file.
- [ ] All six migrated skills resolve an exact override, then a generic role,
      then `inherit`.
- [ ] No ostack skill reads `pstack-models.mdc`.
- [ ] An explicit rejection uses the remaining panel entries or `inherit`.
- [ ] No skill claims that a successful subagent call proves which model ran.
- [ ] `evals/lint.sh` and every setup scenario pass.

**Out of scope.** Do not edit pstack's configuration. Do not choose a nearby
model when the host rejects a configured ID.

## OSM-005: add the common routes

Add the remaining routes needed for the first useful release. Keep route policy
in `routes.json` and workflow steps in the playbooks.

**Files.**

- Edit `skills/ostack-mode/references/routes.json`.
- Create `skills/ostack-mode/references/playbooks/investigation.md`.
- Create `skills/ostack-mode/references/playbooks/feature.md`.
- Create `skills/ostack-mode/references/playbooks/refactoring.md`.
- Create `evals/scenarios/ostack-mode/investigation.yaml`.
- Create `evals/scenarios/ostack-mode/feature.yaml`.
- Create `evals/scenarios/ostack-mode/feature-boundary.yaml`.
- Create `evals/scenarios/ostack-mode/refactoring.yaml`.
- Create `evals/scenarios/ostack-mode/no-route.yaml`.

**Acceptance criteria.**

- [ ] Investigation allows only `answer` and performs no edit or `glab` write.
- [ ] Investigation uses `how` for behavior and `why` only for motivation or
      history.
- [ ] A one-file feature that follows an existing pattern skips `architect` and
      `arena`.
- [ ] A feature that adds or moves a public function, class, or type across
      modules invokes `architect`.
- [ ] Refactoring preserves behavior and applies the Laziness Protocol and
      Subtract Before You Add.
- [ ] Feature and refactoring allow `local-change`, `mr-open`, and
      `merge-ready`.
- [ ] A negative constraint such as "do not edit" wins over the word "bug".
- [ ] A prompt with no matching route emits `Route: none` and uses leaf skills.
- [ ] `arena` runs only when the prompt requests competing implementations or
      the task identifies two incompatible boundaries or interactions.
- [ ] `evals/lint.sh` and all five scenarios pass.

**Out of scope.** Do not add prototype, visual-parity, planning, or cleanup
routes.

## OSM-006: add the operational playbooks

Add the playbooks that help an agent test, author, resume, and pause work. Reuse
the existing leaf skills instead of copying their instructions.

**Files.**

- Edit `skills/ostack-mode/references/routes.json`.
- Create `skills/ostack-mode/references/playbooks/eval.md`.
- Create `skills/ostack-mode/references/playbooks/authoring-a-skill.md`.
- Create `skills/ostack-mode/references/playbooks/session-pickup.md`.
- Create `skills/ostack-mode/references/playbooks/pause-safely.md`.
- Create `evals/scenarios/ostack-mode/eval.yaml`.
- Create `evals/scenarios/ostack-mode/authoring-a-skill.yaml`.
- Create `evals/scenarios/ostack-mode/session-pickup.yaml`.
- Create `evals/scenarios/ostack-mode/pause-safely.yaml`.

**Acceptance criteria.**

- [ ] Eval invokes `evals/lint.sh` and the YAML scenario runner.
- [ ] Skill authoring uses `principles`, `technical-writing`, `unslop`, and the
      repository evals.
- [ ] Session pickup delegates to `recall` and does not repeat its procedure.
- [ ] Pause safely stops at an atomic boundary and leaves a durable resume note.
- [ ] Pause safely uses `show-me-your-work` only when a decision trail exists or
      the run needs one.
- [ ] Every route has an objective headless scenario.
- [ ] `evals/lint.sh` and all four scenarios pass.

**Out of scope.** Do not add visual prototypes, Jira decomposition, or worktree
deletion.

## OSM-007: document ostack-mode

Document the installed skills and the pstack provenance after the common routes
and model migration are real. Do not document planned behavior as shipped.

**Files.**

- Edit `README.md`.
- Edit `NOTICE`.
- Edit `scripts/install.sh` only if its dry run proves that nested files are not
  copied.

**Acceptance criteria.**

- [ ] `README.md` has an Orchestration section for `ostack-mode` and
      `setup-ostack-mode`.
- [ ] The README says that Custom Mode activation provides session persistence.
- [ ] The README does not claim that slash invocation alone is sticky.
- [ ] `NOTICE` records `ostack-mode` as adapted from pstack's mechanism.
- [ ] The deliberate exclusions include `make-bot-ui` and its Cursor-team
      integration reason.
- [ ] `scripts/install.sh --dry-run` includes the new skills.
- [ ] The installer remains unchanged when the dry run already copies nested
      playbooks and scripts.
- [ ] `evals/lint.sh` passes.

**Out of scope.** Do not alter routing, model selection, or playbook behavior.

## OSM-008: validate the core in Cursor

Run the first-release matrix on the real target host. Record what Cursor did,
not what the skill intended to do.

**Files.**

- Create `evals/cursor/ostack-mode-core.md`.

**Acceptance criteria.**

- [ ] Record the Cursor version and the parent model.
- [ ] Prove that Custom Mode remains active across a follow-up turn.
- [ ] Prove that a missing model file resolves every role to `inherit`.
- [ ] Record an observable model substitution when Cursor exposes it.
- [ ] Do not claim which model ran when Cursor exposes no model metadata.
- [ ] Run the investigation, bug local-change, bug MR-open, bug merge-ready,
      feature, refactoring, Spark, and no-route cases from the implementation
      plan.
- [ ] Record each route, outcome, relevant tool effects, and result.
- [ ] Record any failure as a blocker for `OSM-011`.

**Out of scope.** Do not change production files to make the evidence report
pass. Return a failure to the owning ticket.

## OSM-009: add prototype and visual parity

Add the two playbooks that compare observable alternatives. Keep prototypes out
of production source and keep visual verification conditional on UI work.

**Files.**

- Edit `skills/ostack-mode/references/routes.json`.
- Create `skills/ostack-mode/references/playbooks/prototype.md`.
- Create `skills/ostack-mode/references/playbooks/visual-parity.md`.
- Create `evals/scenarios/ostack-mode/prototype.yaml`.
- Create `evals/scenarios/ostack-mode/visual-parity.yaml`.

**Acceptance criteria.**

- [ ] Prototype uses `arena` only when the decision needs competing artifacts.
- [ ] Prototype writes every candidate outside production source.
- [ ] Prototype returns a decision and labels its artifacts as disposable.
- [ ] Visual parity invokes `e2e-verify` only for a repository with a UI.
- [ ] Visual parity starts with labeled side-by-side screenshots.
- [ ] Pixel diffing remains out of scope until a task supplies a numeric
      threshold.
- [ ] `evals/lint.sh` and both scenarios pass.

**Out of scope.** Do not add a general image-diff framework or a project-specific
frontend command.

## OSM-010: add planning and cleanup routes

Add the remaining approved playbooks. Keep Jira writes conditional on a real
Jira epic, and guard every destructive cleanup with exact path resolution.

**Files.**

- Edit `skills/ostack-mode/references/routes.json`.
- Create `skills/ostack-mode/references/playbooks/multi-phase-plan.md`.
- Create `skills/ostack-mode/references/playbooks/worktree-cleanup.md`.
- Create `evals/scenarios/ostack-mode/multi-phase-plan.yaml`.
- Create `evals/scenarios/ostack-mode/worktree-cleanup.yaml`.

**Acceptance criteria.**

- [ ] Multi-phase planning produces independently verifiable phase boundaries.
- [ ] It invokes `decompose-epic` only when the source is a real Jira epic.
- [ ] A generic plan performs no Jira read or write.
- [ ] Cleanup resolves every worktree to an exact absolute path.
- [ ] Cleanup distinguishes merged, abandoned, dirty, and active worktrees.
- [ ] Cleanup asks before a destructive action that the prompt did not
      authorize.
- [ ] Cleanup never targets the repository root, the home directory, or an
      unresolved variable.
- [ ] `evals/lint.sh` and both scenarios pass.

**Out of scope.** Do not add `git-spice`, merge MRs, delete active work, or
create Jira tickets from a generic plan.

## OSM-011: run the final acceptance gate

Prove the complete implementation against the checked-in plan. This ticket is
a gate, not a place to hide implementation fixes.

**Files.**

- Create `evals/cursor/ostack-mode-final.md`.

**Acceptance criteria.**

- [ ] `evals/lint.sh` reports `LINT: PASS`.
- [ ] Every YAML scenario passes through `evals/run.sh`.
- [ ] `git status --porcelain` contains no generated or unintended file.
- [ ] Every implemented route appears once in `routes.json` and points to an
      installed playbook.
- [ ] No ostack-mode playbook contains a project-specific verification command.
- [ ] No ostack skill reads `pstack-models.mdc`.
- [ ] The final Cursor matrix passes on the exact head commit.
- [ ] The evidence report records commands, Cursor version, head SHA, and each
      verdict.
- [ ] Any failure returns to the ticket that owns the affected files. Do not
      mark this gate complete with an exception note.

**Out of scope.** Do not merge, deploy, release, or weaken a failed assertion.

## Dependency graph

```text
OSM-001 -> OSM-003
OSM-001 -> OSM-004
OSM-003 + OSM-004 -> OSM-005
OSM-005 -> OSM-006 -> OSM-009 -> OSM-010
OSM-004 + OSM-005 -> OSM-007
OSM-002 + OSM-003 + OSM-004 + OSM-005 -> OSM-008
OSM-002 + OSM-007 + OSM-008 + OSM-010 -> OSM-011
```

## Shared-file audit

Every overlap has an explicit dependency. No tickets in the same phase edit the
same file.

- `skills/ostack-mode/SKILL.md`: `OSM-001 -> OSM-003`.
- `skills/ostack-mode/references/models.example.json`:
  `OSM-001 -> OSM-004`.
- `skills/ostack-mode/scripts/validate.sh`: `OSM-001 -> OSM-004`.
- `skills/ostack-mode/references/routes.json`:
  `OSM-001 -> OSM-003 -> OSM-005 -> OSM-006 -> OSM-009 -> OSM-010`.

The practical parallel lanes are:

- Phase 1: `OSM-001` and `OSM-002`.
- Phase 2: `OSM-003` and `OSM-004`.
- Phase 4: `OSM-006`, `OSM-007`, and `OSM-008`.
- The route-registry lane remains sequential because one JSON file owns route
  precedence.
