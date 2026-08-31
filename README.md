# ostack

Personal agent skills. Two layers: the procedure that gets work from a ticket to
a merged MR, and the judgment that decides whether what shipped was any good.

Skills live in [`skills/`](skills/) as standard `SKILL.md` folders (Cursor /
Claude Code / opencode compatible). Written Cursor-first: multi-model panels and
`~/.cursor` paths are the default path, but every skill names its fallback for
single-vendor hosts, so nothing silently no-ops in Claude Code.

## Install

```sh
tmp=$(mktemp -d) && git clone -q git@github.com:orisilber/ostack.git "$tmp/ostack" && bash "$tmp/ostack/scripts/install.sh"; rm -rf "$tmp"
```

Nushell has no `&&`, so the nushell version drops the short-circuiting and just runs each step:

```nu
let tmp = (mktemp -d); git clone -q git@github.com:orisilber/ostack.git $"($tmp)/ostack"; bash $"($tmp)/ostack/scripts/install.sh"; rm -rf $tmp
```

One line, nothing left behind but the skills: the script copies every skill
into `~/.agents/skills`, `~/.claude/skills`, and `~/.cursor/skills`, then the
clone is deleted. Run it again anytime to replace the installed skills with
the latest versions. An upgrade also removes a retired skill when its installed
directory contains ostack's `.ostack` ownership marker. The installer preserves
unmarked directories and all symlinks. It reports current-name conflicts
without replacing them. Override the canonical home with `AGENTS_HOME`, or
preview installs and removals with `--dry-run`. Set `OSTACK_INSTALL_HOME` to
redirect all three targets to another user home.

## Orchestration

`ostack-mode` is the Cursor-first entry point when you want ostack to coordinate
the work. Activate it as a Cursor Custom Mode when you want its instructions to
remain active across follow-up turns. Slash invocation is explicit, but it does
not make the mode sticky by itself. The skill keeps
`disable-model-invocation: true`, so it never starts without your action.

The mode resolves two separate values before it chooses a playbook:

- Route: `investigation`, `bug-fix`, `large-feature`, `feature`, `refactoring`,
  `eval`, `authoring-a-skill`, `session-pickup`, `pause-safely`, `prototype`,
  `visual-parity`, `multi-phase-plan`, or `worktree-cleanup`.
- Outcome: `answer`, `local-change`, `mr-open`, or `merge-ready`.

It reports the selected pair as `Route: <task-kind> -> <outcome>`. A read-only
question defaults to `answer`, and a code-change request defaults to
`local-change`. The mode selects `mr-open` or `merge-ready` only when you ask
for that outcome. It never infers an external write from a ticket, branch, or
remote. If no implemented route matches, it uses the applicable leaf skills.
A code route runs its verification steps automatically. You do not need to ask
the mode to verify a change or keep it local. The mode does not merge, deploy,
or release.

The mode selects `large-feature` when implementation has at least two
independently verifiable scopes after shared foundations are separated, or when
the complete change cannot fit one agent session. It creates a local task DAG
by default. If at least two ready tasks have disjoint write scopes, it invokes
`swarm` and integrates the results. It uses `decompose-epic` only for a real
Jira epic when you authorize Jira work.

For uncertain implementation choices, the mode uses `arena` when at least two
viable approaches exist and a wrong choice would cause substantial rework. It
uses `how` without an arena when only the current system is unclear.

Use `setup-ostack-mode` to configure delegated model roles. It reads
`~/.config/ostack/models.json`, or the directory named by `OSTACK_CONFIG_HOME`,
and falls back to `inherit` when the file is missing or invalid. The setup skill
does not read or edit pstack's model configuration. See
[`skills/ostack-mode/references/models.example.json`](skills/ostack-mode/references/models.example.json)
for the configuration shape.

## How skills participate

Workflow membership and invocation policy are separate. A skill can be part of
an `ostack-mode` workflow and still require explicit invocation when you use it
outside the mode.

### Workflow components

When `ostack-mode` selects a route, its playbook selects these skills as needed.
You do not need to name them in the prompt.

| Skill | Workflow use |
|---|---|
| `architect` | Settle a boundary before a feature, bug fix, or refactor crosses it |
| `arena` | Compare viable implementations when one choice would lock in the wrong shape |
| `babysit-gitlab-mr` | Run only for the explicit `merge-ready` outcome |
| `decompose-epic` | Split work only when the source is a real Jira epic |
| `e2e-verify` | Verify UI behavior or visual parity on a real UI |
| `escalate` | Stop a route at a safety or authority boundary |
| `how` and `why` | Recover runtime structure and design history |
| `principles` | Review the shape of implementation and refactoring work |
| `recall` | Reconstruct context for `session-pickup` |
| `reproduce-first` | Establish failing evidence before a bug fix |
| `show-me-your-work` | Preserve decisions when a long run needs a trail |
| `swarm` | Implement disjoint ready tasks for a large feature in parallel |
| `technical-writing` and `unslop` | Edit prose that a workflow publishes |
| `verify-changes` | Run repository checks and affected project-local verification after a code change |

`ostack-mode` is the workflow entry point. `setup-ostack-mode` configures its
model roles but does not run inside a task route.

When a repository contains a project-local `verify-*` skill, `verify-changes`
uses it automatically for affected user behavior. Creating or auditing that
skill remains explicit through `create-verification-skill` or
`maintain-verification-skill`.

### Standalone skills

These skills are not selected by any current `ostack-mode` route. Use them for
their own task when the need arises.

| Skill | Use |
|---|---|
| `blast-radius` | Check what a specific change can break outside its diff |
| `clarify-requirements` | Resolve ticket ambiguity before implementation starts |
| `deploy-watch` | Watch a deployment after release |
| `interrogate` | Run an adversarial review over a diff |
| `create-verification-skill` | Generate a project-local verifier and feature map |
| `maintain-verification-skill` | Audit a project-local verifier against source and live behavior |
| `pick-next-task` | Claim the next ready Jira item |
| `typescript-best-practices` | Apply TypeScript type discipline when TypeScript files are in scope |

### Explicit invocation

Skills with `disable-model-invocation: true` do not start from a model-selected
trigger. Invoke them by name or slash command when no active workflow already
calls for them:

`ostack-mode`, `setup-ostack-mode`, `architect`, `arena`, `blast-radius`,
`create-verification-skill`, `interrogate`, `maintain-verification-skill`,
`recall`, `show-me-your-work`, `swarm`, and `technical-writing`.

For example, `/ostack-mode Fix the pagination bug` starts the workflow, while
`/interrogate Review this diff` runs the standalone review directly. Inside
`ostack-mode`, a selected playbook can include `architect`, `arena`, `recall`,
`show-me-your-work`, `swarm`, or `technical-writing`; you do not need to invoke
those skills again.

## Skills

The **source** column says where a skill's content originates: `ostack` is
original to this repo, `pstack` is adapted from [pstack](#provenance) (see
below for what changed).

### Autonomous dev loop

| Skill | Source | Purpose |
|---|---|---|
| `ostack-mode` | ostack | Cursor-first router for task kind, outcome, and implemented playbooks |
| `setup-ostack-mode` | ostack | Configure ostack's delegated model roles and fallback behavior |
| `pick-next-task` | ostack | Claim the next Jira work item with `acli`: JQL by agent-ready criteria, self-assign with read-back, transition, branch |
| `decompose-epic` | ostack | Jira epic → atomic, conflict-free child tickets with acceptance criteria, disjoint file scopes, and real `Blocks` links |
| `clarify-requirements` | ostack | One batched round of upfront questions per ticket, defaults included, then never interrupts |
| `reproduce-first` | ostack | Bug tickets: an executable failing check before any fix, and the honest path when a unit test is the wrong tool |
| `create-verification-skill` | pstack | Generate and prove a project-local verifier with exact checks, control instructions, and a user-facing feature map |
| `maintain-verification-skill` | pstack | Audit a project-local verifier against source and live behavior without changing product code |
| `verify-changes` | ostack | Pre-push gate: run declared checks and affected project-local verification, block on failure |
| `e2e-verify` | ostack | Browser verification through a project-local verifier or Playwright fallback |
| `babysit-gitlab-mr` | ostack | Drive a GitLab MR end-to-end: `!review` loop with the review bot, pipeline gate, optional comment watch mode |

### Understanding code

| Skill | Source | Purpose |
|---|---|---|
| `how` | pstack | How a subsystem works: runtime flow, architecture, ownership and layering, with an optional critique panel |
| `why` | pstack | Why it's shaped that way: parallel investigators over git/GitLab, Jira, Confluence, chat, observability, error tracking, analytics |
| `blast-radius` | pstack | What a change breaks outside its own diff, with the one safety fact proven by running code |
| `recall` | pstack | Rebuild working context on a topic from your own transcripts plus the shared record |

### Shaping code

| Skill | Source | Purpose |
|---|---|---|
| `principles` | pstack | The judgment layer: 21 rules for shape, verification, and delegation, indexed with full text in references |
| `architect` | pstack | Types, signatures, and module boundaries settled before code, and scrapped when implementation disproves them |
| `typescript-best-practices` | pstack | TypeScript type discipline grounded in syntax, with worked examples |
| `arena` | pstack | N parallel candidates at one artifact, judged, then grafted into a single base |
| `swarm` | pstack | N parallel workers over slices or races, drained into one report |
| `interrogate` | pstack | Adversarial review panel over a diff, sorted into act-on / consider / noted / dismissed |

### Safety & delivery

| Skill | Source | Purpose |
|---|---|---|
| `escalate` | ostack | Stop-and-ask policy: hard stops, soft stops after N attempts, batched ask with a declared default |
| `show-me-your-work` | pstack | Reviewable decision trail for long or unattended runs, one TSV row per decision |
| `deploy-watch` | ostack | Post-deploy metric watch against contract-defined triggers, authorized auto-rollback |

### Writing

| Skill | Source | Purpose |
|---|---|---|
| `unslop` | pstack | Cut AI tells from prose about to be published |
| `technical-writing` | pstack | Diátaxis structure, Google developer style, simplified technical English, global English |

### Memory

Not vendored here. `memory-admin`, `memory-capture`, `memory-loop`, and
`memory-recall` ship from
[agent-memory](https://github.com/orisilber/agent-memory), a separate local-first
memory service with its own installer. Install that repo and its skills land in
`~/.agents/skills` next to these, same runtime location, same symlink
mechanism, picked up by `recall` and every other skill that references
`memory-capture` or `memory-recall`.

## Where the loop runs

Work comes from **Jira** (`acli`), lands in **GitLab** (`glab`). `pick-next-task`
and `decompose-epic` speak Jira; `babysit-gitlab-mr` speaks GitLab. Both keep a
GitLab-issues fallback at the bottom of the file for repos whose queue lives
there instead.

No skill cuts a release. That's deliberate: releasing is a one-way door
(published artifact, tagged version, sometimes a customer-visible changelog),
and this stack doesn't grant that authority to an agent by default. Cut
releases yourself, or write a project-local skill scoped to your own approval
step if you want the agent doing the mechanics under supervision.

## Provenance

`ostack-mode`, `principles`, `how`, `why`, `blast-radius`, `architect`, `arena`,
`swarm`, `interrogate`, `recall`, `show-me-your-work`, `unslop`,
`technical-writing`, `typescript-best-practices`, `create-verification-skill`,
and `maintain-verification-skill` are adapted from
[pstack](https://github.com/poteto/pstack) by Lauren Tan (MIT). See
[`NOTICE`](NOTICE). Changes from upstream:

- `ostack-mode` adapts the mode and playbook mechanism from pstack's
  `poteto-mode`. Its route registry, outcome tails, and playbook text are
  specific to ostack.
- 21 standalone principle skills consolidated into one `principles` skill with
  grouped references, so the skill index costs one entry instead of twenty-one.
- Cursor-specific hooks kept as the default path, with a fallback named for
  single-vendor hosts: subagent types, model panels, transcript locations.
- GitHub/graphite replaced by GitLab (`glab`) and Linear/Notion by Jira and
  Confluence (`acli`) in `why`'s evidence playbooks.
- `never-block-on-the-human` scoped by `escalate`, which owns the hard stops.
- `tdd`'s impractical-test guardrails folded into `reproduce-first` rather than
  shipped as a second, overlapping skill.
- Project-local verification defaults to `.agents/skills`, detects existing
  Cursor and Claude roots, records declared repository checks, and keeps
  external writes behind the selected ostack outcome.
- `verify-changes` runs affected project-local recipes after static checks.
  `e2e-verify` supplies browser mechanics without duplicating the repository's
  launch, authentication, and feature knowledge.

Not vendored as pstack workflows, deliberately: the full `poteto-mode` and
`figure-it-out` playbook sets (tied to Graphite and GitHub), `setup-pstack`,
`automate-me`, `reflect`, `teach`, `bro`, `no-comments`,
`tdd`.

`make-bot-ui` is also excluded. It depends on Cursor-team internals, including
a Grok Bot webhook, `update_state`, and sender-key handling. Ostack does not
ship that integration.

If you run pstack as a Cursor plugin *and* symlink ostack into `~/.cursor/skills`,
the shared names collide. Pick one: keep pstack for the upstream set, or keep
these forks. Running both means a coin flip over which `/how` you get.

Skills that shell out need `glab` (GitLab), `acli` (Jira/Confluence), and `node`
with `npx playwright` for `e2e-verify`.
