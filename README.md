# ostack

Personal agent skills and subagents. Two layers: the procedure that gets work from a ticket to
a merged MR, and the judgment that decides whether what shipped was any good.

Skills live in [`skills/`](skills/) as standard `SKILL.md` folders (Cursor /
Claude Code / opencode compatible). Written Cursor-first: `~/.cursor` paths and Cursor
subagent types are the default path, but every skill names its fallback for
single-vendor hosts, so nothing silently no-ops in Claude Code.

Named subagents live in [`agents/`](agents/) and are installed for Cursor,
Claude Code, and Codex.

## Install

```sh
tmp=$(mktemp -d) && git clone -q git@github.com:orisilber/ostack.git "$tmp/ostack" && bash "$tmp/ostack/scripts/install.sh"; rm -rf "$tmp"
```

Nushell:

```nu
let tmp = (mktemp -d); git clone -q git@github.com:orisilber/ostack.git $"($tmp)/ostack"; bash $"($tmp)/ostack/scripts/install.sh"; rm -rf $tmp
```

One line, nothing left behind but the skills and agents: copies skills into
`~/.agents/skills`, `~/.claude/skills`, and `~/.cursor/skills`; copies
agents into `~/.codex/agents`, `~/.claude/agents`, and `~/.cursor/agents`;
then deletes the clone. Re-run anytime to upgrade or drop retired items.
`--dry-run` previews; `AGENTS_HOME` or `OSTACK_INSTALL_HOME` redirect the
target.

## Orchestration

`blahaj-mode` is the Cursor-first entry point: activate it as a Custom Mode to
keep it active across turns, or invoke `/blahaj-mode` per turn. It is a working
agreement, not a router. It resolves one outcome (`answer`, `local-change`,
`mr-open`, `merge-ready`) from what you asked for, reports it as
`Outcome: <outcome>`, and applies the gates for the kind of work: a failing
check before a bug fix, real-interface proof for a feature, unchanged behavior
for a refactor, a browser check for UI. It never opens an MR, merges, or
releases unless you ask for that outcome.

`/blahaj-mode deliver <task>` is the autonomous form. It researches, chooses the
approach, implements, verifies, opens the change request, and drives it
merge-ready without routine checkpoints. Saying "work autonomously" alone keeps
the outcome you requested. Negative constraints always win, and no outcome
authorizes merge, release, or deploy.

Delivery supports GitHub PRs and GitLab MRs. Readiness requires review and CI
for the current head. Longer tasks can save progress outside tracked files and
resume with the same outcome and scope. Later execution requires an explicitly
requested and confirmed host schedule; installing the skill does not keep the
agent running after its host stops.

Everything runs on the model you are already using. Delegating skills (`arena`,
`how`, `interrogate`, `swarm`, `why`) delegate only for isolation, real
parallelism, or a fresh reviewer, and their subagents run on the parent model.
Name a model in the request to get a second opinion from it, for example a
second `interrogate` reviewer.

## How skills participate

Skills with automatic invocation start whenever the request matches their
description, inside or outside `blahaj-mode`. Inside the mode, the gates also
reach for `reproduce-first`, `feature-retention-tests`, `verify-changes`,
`e2e-verify`, `escalate`, `how`, `why`, `recall`, and `babysit-gitlab-mr`, and
a large feature can use `decompose-epic` and `swarm`.

When a repository contains a project-local `verify-*` skill, `verify-changes`
uses it automatically for affected user behavior. Creating or auditing that
skill stays explicit through `/verification-skill create` or
`/verification-skill audit`.

### Explicit invocation

Skills with `disable-model-invocation: true` start only when you name them:

`blahaj-mode`, `arena`, `blast-radius`, `interrogate`, `no-comments`, `swarm`,
and `verification-skill`.

For example, `/blahaj-mode Fix the pagination bug` works the bug to a local
change, `/blahaj-mode deliver Fix the pagination bug` carries it through
merge-ready, and `/interrogate Review this diff` runs the review directly.

## Skills

The **source** column says where a skill's content originates: `ostack` is
original to this repo, `pstack` is adapted from [pstack](#provenance) (see
below for what changed).

### Autonomous dev loop

| Skill | Source | Purpose |
|---|---|---|
| `blahaj-mode` | ostack | Working agreement: resolve the outcome, apply per-kind gates, and `deliver` to merge-ready on request |
| `pick-next-task` | ostack | Claim the next Jira work item with `acli`: JQL by agent-ready criteria, self-assign with read-back, transition, branch |
| `decompose-epic` | ostack | Jira epic → atomic, conflict-free child tickets with acceptance criteria, disjoint file scopes, and real `Blocks` links |
| `clarify-requirements` | ostack | One batched round of upfront questions per ticket, defaults included, then never interrupts |
| `reproduce-first` | ostack | Bug tickets: an executable failing check before any fix, and the honest path when a unit test is the wrong tool |
| `feature-retention-tests` | ostack | Features: permanent behavioral coverage only after implementation and real-interface acceptance |
| `verification-skill` | pstack | Create or audit a project-local verifier with exact checks, control instructions, a feature map, and a structural linter |
| `verify-changes` | ostack | Pre-push gate: run declared checks and affected project-local verification, block on failure |
| `e2e-verify` | ostack | Browser verification through a project-local verifier or Playwright fallback |
| `babysit-gitlab-mr` | ostack | Drive a GitLab MR end-to-end: `!review` loop with the review bot, pipeline gate, optional comment watch mode |

### Understanding code

| Skill | Source | Purpose |
|---|---|---|
| `how` | pstack | How a subsystem works: runtime flow, architecture, ownership and layering, with an optional critique |
| `why` | pstack | Why it's shaped that way: evidence from git/GitLab, Jira, Confluence, chat, observability, error tracking, analytics |
| `blast-radius` | pstack | What a change breaks outside its own diff, with the one safety fact proven by running code |
| `recall` | pstack | Rebuild working context on a topic from your chat history plus MRs, tickets, and errors |

### Shaping code

| Skill | Source | Purpose |
|---|---|---|
| `principles` | pstack | The judgment layer: 18 rules for shape, verification, and delegation, plus design red flags, indexed with full text in references |
| `typescript-best-practices` | pstack | TypeScript type discipline grounded in syntax, with worked examples |
| `arena` | pstack | N parallel candidates at one artifact, judged, then grafted into a single base |
| `swarm` | pstack | N parallel workers over slices or races, drained into one report |
| `interrogate` | pstack | Fresh-context adversarial review over a diff, sorted into act-on / consider / noted / dismissed |
| `no-comments` | pstack | Remove unjustified comments and turn accepted findings into root-cause fixes |

### Safety & delivery

| Skill | Source | Purpose |
|---|---|---|
| `escalate` | ostack | Stop-and-ask policy: hard stops, soft stops after N attempts, batched ask with a declared default |
| `deploy-watch` | ostack | Post-deploy metric watch against contract-defined triggers, authorized auto-rollback |

### Writing

| Skill | Source | Purpose |
|---|---|---|
| `unslop` | pstack | Write and edit published prose: cut AI tells, pick the document mode, apply sentence style |

### Memory

Not vendored here. `memory-admin`, `memory-capture`, `memory-loop`, and
`memory-recall` ship from
[agent-memory](https://github.com/orisilber/agent-memory), a separate local-first
memory service with its own installer. Install that repo and its skills land in
`~/.agents/skills` next to these. `recall` rebuilds working context for a task;
`memory-recall` holds durable preferences and facts across tasks.

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

`blahaj-mode`, `principles`, `how`, `why`, `blast-radius`, `arena`, `swarm`,
`interrogate`, `no-comments`, `recall`, `unslop`, `typescript-best-practices`,
and `verification-skill` are adapted from
[pstack](https://github.com/poteto/pstack) by Lauren Tan (MIT). See
[`NOTICE`](NOTICE). Changes from upstream:

- `blahaj-mode` adapts the mode mechanism from pstack's `poteto-mode` into a
  single working agreement with outcome tails and per-kind gates, without a
  route registry or per-role model routing.
- 21 standalone principle skills consolidated into one `principles` skill with
  grouped references. Rules that restated harness behavior were dropped, and
  pstack's `architect` design red flags live there instead.
- `unslop` absorbs `technical-writing`'s document modes and sentence style.
- `verification-skill` merges `create-verification-skill` and
  `maintain-verification-skill`, adds a template linter, and scopes audits from
  the last verified commit.
- Cursor-specific hooks kept as the default path, with a fallback named for
  single-vendor hosts: subagent types and transcript locations.
- GitHub/graphite replaced by GitLab (`glab`) and Linear/Notion by Jira and
  Confluence (`acli`) in `why`'s evidence playbooks.
- `never-block-on-the-human` becomes "decide, then present", with `escalate`
  owning the exceptions.
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
`automate-me`, `reflect`, `teach`, `bro`,
`tdd`, `architect`, `show-me-your-work`, `technical-writing`.

`make-bot-ui` is also excluded. It depends on Cursor-team internals, including
a Grok Bot webhook, `update_state`, and sender-key handling. Ostack does not
ship that integration.

If you run pstack as a Cursor plugin *and* symlink ostack into `~/.cursor/skills`,
the shared names collide. Pick one: keep pstack for the upstream set, or keep
these forks. Running both means a coin flip over which `/how` you get.

Skills that shell out need `glab` (GitLab), `acli` (Jira/Confluence), and `node`
with `npx playwright` for `e2e-verify`.
