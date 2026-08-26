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

One line, nothing left behind but the skills: the script copies every skill
into `~/.agents/skills`, `~/.claude/skills`, and `~/.cursor/skills`, then the
clone is deleted. Run it again anytime to replace the installed skills with the
latest versions. Foreign directories (not installed by ostack) are skipped and
reported, never clobbered. Override the canonical home with `AGENTS_HOME`, or
preview with `--dry-run`.

## Skills

The **source** column says where a skill's content originates: `ostack` is
original to this repo, `pstack` is adapted from [pstack](#provenance) (see
below for what changed).

### Autonomous dev loop

| Skill | Source | Purpose |
|---|---|---|
| `pick-next-task` | ostack | Claim the next Jira work item with `acli`: JQL by agent-ready criteria, self-assign with read-back, transition, branch |
| `decompose-epic` | ostack | Jira epic → atomic, conflict-free child tickets with acceptance criteria, disjoint file scopes, and real `Blocks` links |
| `clarify-requirements` | ostack | One batched round of upfront questions per ticket, defaults included, then never interrupts |
| `reproduce-first` | ostack | Bug tickets: an executable failing check before any fix, and the honest path when a unit test is the wrong tool |
| `verify-changes` | ostack | Pre-push gate: discover and run lint/typecheck/tests, block on failure |
| `e2e-verify` | ostack | Playwright verification of UI changes: web-first assertions, console-error capture, screenshots, trace on failure |
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

`principles`, `how`, `why`, `blast-radius`, `architect`, `arena`, `swarm`,
`interrogate`, `recall`, `show-me-your-work`, `unslop`, `technical-writing`, and
`typescript-best-practices` are adapted from
[pstack](https://github.com/poteto/pstack) by Lauren Tan (MIT). See
[`NOTICE`](NOTICE). Changes from upstream:

- 21 standalone principle skills consolidated into one `principles` skill with
  grouped references, so the skill index costs one entry instead of twenty-one.
- Cursor-specific hooks kept as the default path, with a fallback named for
  single-vendor hosts: subagent types, model panels, transcript locations.
- GitHub/graphite replaced by GitLab (`glab`) and Linear/Notion by Jira and
  Confluence (`acli`) in `why`'s evidence playbooks.
- `never-block-on-the-human` scoped by `escalate`, which owns the hard stops.
- `tdd`'s impractical-test guardrails folded into `reproduce-first` rather than
  shipped as a second, overlapping skill.

Not adapted, deliberately: `poteto-mode` and `figure-it-out` (a mode skill with
its own playbook set, tied to graphite and GitHub), `setup-pstack`,
`automate-me`, `reflect`, `teach`, `bro`, `no-comments`,
`create-verification-skill`, `maintain-verification-skill`, `tdd`.

If you run pstack as a Cursor plugin *and* symlink ostack into `~/.cursor/skills`,
the shared names collide. Pick one: keep pstack for the upstream set, or keep
these forks. Running both means a coin flip over which `/how` you get.

Skills that shell out need `glab` (GitLab), `acli` (Jira/Confluence), and `node`
with `npx playwright` for `e2e-verify`.
