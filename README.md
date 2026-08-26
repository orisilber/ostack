# ostack

Personal agent skills. Two layers: the procedure that gets work from a ticket to
a merged MR, and the judgment that decides whether what shipped was any good.

Skills live in [`skills/`](skills/) as standard `SKILL.md` folders (Cursor /
Claude Code / opencode compatible). Written Cursor-first — multi-model panels and
`~/.cursor` paths are the default path — but every skill names its fallback for
single-vendor hosts, so nothing silently no-ops in Claude Code.

## Skills

### Autonomous dev loop

| Skill | Purpose |
|---|---|
| `pick-next-task` | Claim the next Jira work item with `acli`: JQL by agent-ready criteria, self-assign with read-back, transition, branch |
| `decompose-epic` | Jira epic → atomic, conflict-free child tickets with acceptance criteria, disjoint file scopes, and real `Blocks` links |
| `clarify-requirements` | One batched round of upfront questions per ticket, defaults included, then never interrupts |
| `reproduce-first` | Bug tickets: an executable failing check before any fix, and the honest path when a unit test is the wrong tool |
| `verify-changes` | Pre-push gate: discover and run lint/typecheck/tests, block on failure |
| `e2e-verify` | Playwright verification of UI changes: web-first assertions, console-error capture, screenshots, trace on failure |
| `babysit-gitlab-mr` | Drive a GitLab MR end-to-end: `!review` loop with the review bot, pipeline gate, optional comment watch mode |

### Understanding code

| Skill | Purpose |
|---|---|
| `how` | How a subsystem works: runtime flow, architecture, ownership and layering, with an optional critique panel |
| `why` | Why it's shaped that way: parallel investigators over git/GitLab, Jira, Confluence, chat, observability, error tracking, analytics |
| `blast-radius` | What a change breaks outside its own diff, with the one safety fact proven by running code |
| `recall` | Rebuild working context on a topic from your own transcripts plus the shared record |

### Shaping code

| Skill | Purpose |
|---|---|
| `principles` | The judgment layer: 21 rules for shape, verification, and delegation, indexed with full text in references |
| `architect` | Types, signatures, and module boundaries settled before code, and scrapped when implementation disproves them |
| `typescript-best-practices` | TypeScript type discipline grounded in syntax, with worked examples |
| `arena` | N parallel candidates at one artifact, judged, then grafted into a single base |
| `swarm` | N parallel workers over slices or races, drained into one report |
| `interrogate` | Adversarial review panel over a diff, sorted into act-on / consider / noted / dismissed |

### Safety & delivery

| Skill | Purpose |
|---|---|
| `escalate` | Stop-and-ask policy: hard stops, soft stops after N attempts, batched ask with a declared default |
| `show-me-your-work` | Reviewable decision trail for long or unattended runs, one TSV row per decision |
| `release` | Forge-agnostic release flow: bump → build → tag → publish → manifest SHA updates |
| `deploy-watch` | Post-deploy metric watch against contract-defined triggers, authorized auto-rollback |

### Writing

| Skill | Purpose |
|---|---|
| `unslop` | Cut AI tells from prose about to be published |
| `technical-writing` | Diátaxis structure, Google developer style, simplified technical English, global English |

### Memory (agent-memory suite)

| Skill | Purpose |
|---|---|
| `memory-admin` | Review, export, correct, archive, or delete agent-memory records |
| `memory-capture` | Save preferences, procedures, decisions, and facts to agent-memory |
| `memory-loop` | Persist and resume agent loop state via memory checkpoints |
| `memory-recall` | Search agent-memory before answering or repeating work |

## Where the loop runs

Work comes from **Jira** (`acli`), lands in **GitLab** (`glab`). `pick-next-task`
and `decompose-epic` speak Jira; `babysit-gitlab-mr` and `release` speak GitLab.
Both keep a GitLab-issues fallback at the bottom of the file for repos whose
queue lives there instead.

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

## Layout on this machine

The canonical runtime location is `~/.agents/`:

```
~/.agents/skills/<name>  ->  symlink into this repo checkout
~/.cursor/{skills,commands,agents}/  ->  symlinked from ~/.agents by ~/.zshrc sync_agent_assets
~/.claude/skills/<name>  ->  symlinked from ~/.agents by ~/.zshrc sync_agent_assets
```

## Install on a new machine

```sh
git clone git@github.com:orisilber/ostack.git ~/dev/ostack
mkdir -p ~/.agents/skills
for d in ~/dev/ostack/skills/*; do ln -sfn "$d" "$HOME/.agents/skills/$(basename "$d")"; done
```

Then start a shell — the `sync_agent_assets` function in `~/.zshrc` propagates
everything into Cursor and Claude Code automatically.

Skills that shell out need `glab` (GitLab), `acli` (Jira/Confluence), and `node`
with `npx playwright` for `e2e-verify`.
