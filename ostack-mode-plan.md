# ostack-mode: plan to a composable orchestrator

Goal: a `/ostack-mode` skill that works like pstack's `poteto-mode`, routing a
prompt to the right ostack skills, the right model per step, and the right
sequence (e.g. understand the bug -> fix -> verify -> open MR -> babysit it),
built from playbooks so the routing is composable instead of hardcoded.

## Design constraints

These two govern every decision below; re-read them before adding anything.

**Cursor is the target. Claude Code is best-effort, not a requirement.**
Design for Cursor's real primitives first: `mode: true` (engine-enforced
stickiness), the `Task` tool with arbitrary detected model slugs, and
`~/.cursor/rules/*.mdc` for persisted config. Where Claude Code can't do the
same thing (no engine-enforced mode, a 4-value model enum instead of a real
roster), note the degradation in one line and move on. Do not spend design
effort making the two hosts equivalent. Nothing here can be live-tested from
a Claude Code session; Cursor-specific mechanics (`mode: true` stickiness,
`Task` model detection) only get validated by running this inside Cursor.

**No project-type assumptions, anywhere, especially in verify.** This runs
in frontend repos, backend services, Spark/data pipelines, whatever else.
Every playbook step that runs checks must go through `verify-changes`
(already discovery-based: `AGENTS.md`, then manifests across ecosystems,
then CI config, never a hardcoded command) or skills that are already
conditional on the work touching their domain (`e2e-verify` only when UI is
touched, `typescript-best-practices` only on `.ts`/`.tsx`). No playbook may
name a language- or framework-specific command directly.

## Phase 0: core mechanism (minimum to call `/ostack-mode` and have it work)

- [ ] `skills/ostack-mode/SKILL.md`: `mode: true` + `disable-model-invocation:
      true`, playbook-match-and-copy mechanism, model-routing lookup, `Task`
      delegation (Cursor-shaped; one line on Claude Code's `Agent` fallback
      and its lost stickiness, not a parallel design), "own the result"
      review discipline, non-negotiables (never spawn without resolving a
      model tier, `escalate`'s hard stops always win regardless of mode).
- [ ] `skills/setup-ostack-mode/SKILL.md`: detect real Cursor model slugs via
      a `Task` subagent this session, load the existing
      `~/.cursor/rules/ostack-models.mdc` if present, batched
      `AskUserQuestion` config flow, write the file (`alwaysApply: true`).
      Claude Code: same skill, degrades to the 4-value enum, one paragraph,
      not a separate design pass.
- [ ] `skills/ostack-mode/references/playbooks/feature.md`
- [ ] `skills/ostack-mode/references/playbooks/bug-fix.md`
- [ ] `skills/ostack-mode/references/playbooks/opening-an-mr.md`: shared
      tail factored out of feature/bug-fix (`glab mr create`,
      `technical-writing`/`unslop` the description, hand to
      `babysit-gitlab-mr`).
- [ ] Run `evals/lint.sh` against everything above, fix findings (frontmatter
      shape, description byte budget, file-size budget, no em dashes,
      cross-skill references resolve).

## Phase 1: fill out the playbook library

Map every pstack playbook to an ostack-native equivalent, or record an
explicit "not now" with a reason. No silent gaps.

- [ ] `refactoring.md`: architect (if boundary-crossing) -> implementation
      delegate -> verify-changes, `principles`' laziness-protocol /
      subtract-before-you-add as the lens.
- [ ] `investigation.md`: parallel `how` + `why`, synthesized reply, no fix,
      no MR.
- [ ] `prototype.md`: 2-3 disposable builds via `arena`, per `principles`'
      exhaust-the-design-space rule, to settle a fork empirically instead of
      asking.
- [ ] `visual-parity.md`: built on `e2e-verify`'s screenshots.
      **Sub-task**: `e2e-verify` has no before/after pixel-diff today; either
      extend it or scope this playbook to manual side-by-side screenshot
      comparison for now. Frontend-only playbook by nature; never invoked
      for a repo with no UI, which the task-to-playbook match already
      handles.
- [ ] `eval.md`: native to ostack, not a port. Wraps this repo's own
      `evals/scenarios/*.yaml` + `evals/lint.sh` harness to test a
      skill/prompt change before promoting it.
- [ ] `session-pickup.md`: built on `recall` (already does exactly this).
- [ ] `pause-safely.md`: the inverse. Suspend cleanly, leave `recall` /
      `show-me-your-work` a resumable trail, per `principles`'
      make-operations-idempotent rule.
- [ ] `multi-phase-plan.md`: `decompose-epic` for phase boundaries, one
      `babysit-gitlab-mr` pass per phase, sequential (no stacking, ostack
      has no Graphite equivalent).
- [ ] `authoring-a-skill.md`: `evals/lint.sh` as the mechanical check,
      `principles` as the judgment lens, no Cursor `create-skill`
      dependency.
- [ ] `worktree-cleanup.md`: host-agnostic git hygiene, safety-gated
      deletes, low priority.
- [ ] Explicit "not now" list, recorded so it's a decision, not a gap:
  - `perf-issue`, `hillclimb`, `runtime-forensics`, `trace-forensics`:
    skip, no profiling/instrumentation skill exists in ostack yet; each
    needs a new skill before a playbook can wrap it.
  - `shipping`, `autopilot-full`, `autopilot-stack`, `orchestrate`: skip,
    Graphite-stacking-shaped, no ostack equivalent workflow;
    `babysit-gitlab-mr` already owns the flat-MR case these would
    otherwise cover.

## Phase 1.5: pstack parity audit (completed 2026-08-28)

Checked the full pstack skill catalog (44 entries via the GitHub API, not
memory) against ostack's `NOTICE`/README. One gap found, one new category
found, both resolved:

- [ ] `make-bot-ui` is in pstack, listed in neither ostack's adapted nor
      declined lists. Not a functional gap: its content is Cursor-team
      internal (a Grok Bot webhook, `update_state` tool calls, sender-key
      handling), nothing in ostack has or needs an equivalent. Fix: add it
      to README's Provenance "not adapted, deliberately" list with that
      reason, so it's a recorded decision instead of a silent omission.
- [ ] `automations/benny/` is a different Cursor primitive than skills
      (`.cursor/automations/`, scheduled/webhook-triggered, not
      slash-invoked): Slack-triggered bug-report triage plus auto-repro and
      draft-fix. Ostack's loop is Jira+GitLab only, no Slack today.
      Logged as a future candidate, not built: if Slack becomes a real
      issue-intake channel, port the triage/repro automation using
      `reproduce-first` for the repro half; until then this is out of
      scope, not a gap.
- Everything else reconciles cleanly: 12 adapted skills match `NOTICE`
  exactly, 11 declined skills match README's list exactly, no other pstack
  skill or workflow needs a decision.

## Phase 1.6: stacked GitLab MRs (evaluated 2026-08-28, not building now)

Question: can ostack get pstack/Graphite's stacked-PR workflow on GitLab?

- GitLab already supports the mechanical half natively: an MR can target
  any branch, so a child branch can open an MR against its parent branch
  today, zero tooling. What's missing is Graphite's automation:
  auto-restack on parent change, auto-retarget on parent merge, a unified
  stack CLI/view.
- That automation already exists and doesn't need building: **`git-spice`**
  (verified against its own docs) supports GitLab as a first-class forge
  (also GitHub, Bitbucket, Gitea, Forgejo), with `gs branch create/submit`,
  `gs stack submit`, `gs stack restack`, `gs repo sync` covering the same
  ground Graphite covers for pstack. If real stacking is ever wanted, adopt
  this rather than building an ostack-specific layer.
- The lighter version, stack locally, flatten to one MR at push, needs no
  new tooling at all: it's just ordered, independently-verifiable commits
  on one branch, which `principles`' **sequence verifiable units** rule
  plus normal git discipline already provides, and GitLab's MR "Commits"
  tab already supports commit-by-commit review.
- [ ] Not building either version now. Real stacking (via `git-spice`) is
      only worth adopting if `decompose-epic`'s dependent-ticket chains are
      a recurring, felt bottleneck (ticket B blocked on ticket A's code
      before B can even be reviewed, not just before A merges). Revisit if
      that pain shows up in practice; building for it speculatively
      violates the Laziness Protocol.

## Phase 2: model routing infrastructure

- [ ] Finalize the routing file schema: skill-name keys plus free-form role
      keys (e.g. `implementation`), values are detected Cursor slugs plus
      `inherit`.
- [ ] Confirm `ostack-models.mdc` can't collide with pstack's own
      `pstack-models.mdc` if both are installed (distinct filename, distinct
      keys, already true by construction; `how`, `why`, etc. keep reading
      pstack's file for their own inherited roles).
- [ ] Confirm the pre-configuration default (everything runs on `inherit`
      until `/setup-ostack-mode` runs once) is acceptable: zero surprise
      cost-tiering on day one.

## Phase 3: project-agnostic verify audit

- [ ] Add JVM/Scala build manifests (`build.sbt`, `pom.xml`, `build.gradle`)
      to `verify-changes`' discovery priority list explicitly, so a
      Spark/Scala repo doesn't fall all the way through to the CI-config
      fallback for something as basic as "how do I run tests here."
  Everything else in `verify-changes` (`AGENTS.md` first, then manifests,
  then CI config, `VERIFY: SKIP` when nothing is found) is already
  ecosystem-agnostic; this is the one concrete gap.
- [ ] Grep every new playbook file for a literal `npm`, `yarn`, `pytest`,
      `go test`, or any other hardcoded tool invocation outside of
      `verify-changes`/`e2e-verify` calls. Any hit is a bug: the playbook
      should name the skill, never the command.

## Phase 4: cross-cutting repo updates

- [ ] `README.md`: add `ostack-mode`/`setup-ostack-mode` to the skill
      catalog (new "Orchestration" section), rewrite the Provenance
      "not adapted, deliberately" line to explain the scope-down (routing +
      native playbooks, no Graphite/`cursor-team-kit`/bugbot, no literal
      22-playbook port).
- [ ] `NOTICE`: decide whether the mode-matching/playbook-copy mechanism
      counts as "adapted from pstack" even though playbook content is
      original; add `ostack-mode` to the adapted-skills list if so.
- [ ] Add eval scenarios under `evals/scenarios/ostack-mode/` and
      `evals/scenarios/setup-ostack-mode/`, e.g. asserting a bug-report
      prompt routes to `bug-fix.md` and calls `reproduce-first` before any
      implementation step.
- [ ] Confirm `install.sh` needs no change (confirmed already: `cp -R` per
      skill folder copies nested `references/playbooks/` for free).

## Phase 5: validation (Cursor-only; can't be done from this session)

- [ ] Inside Cursor, hand-run a fake bug-fix prompt through `/ostack-mode`:
      confirm it matches `bug-fix.md`, copies the steps into a todolist,
      delegates `reproduce-first` first rather than jumping to a fix, and
      that `escalate` still wins on any irreversible step.
- [ ] Inside Cursor, hand-run a fake feature prompt the same way: confirm
      `arena` fires only when a step genuinely has multiple valid shapes,
      not every time.
- [ ] Inside Cursor, hand-run one non-frontend task (e.g. a Spark job
      change) through `/ostack-mode` end to end, to prove Phase 3's audit
      actually holds outside a JS/TS repo.
- [ ] Re-read `ostack-mode/SKILL.md` against `principles` before calling
      this done; it's the one skill most likely to violate its own
      minimize-reader-load rule.
