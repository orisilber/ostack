# ostack

Personal agent skills — the ones I own, not vendor-provided stacks.

Skills live in [`skills/`](skills/) as standard `SKILL.md` folders (opencode /
Claude Code / Cursor compatible).

## Skills

| Skill | Purpose |
|---|---|
| `babysit-gitlab-mr` | Drive a GitLab MR end-to-end: find/create MR, `!review` loop with the review bot, pipeline gate, optional comment watch mode |
| `memory-admin` | Review, export, correct, archive, or delete agent-memory records |
| `memory-capture` | Save preferences, procedures, decisions, and facts to agent-memory |
| `memory-loop` | Persist and resume agent loop state via memory checkpoints |
| `memory-recall` | Search agent-memory before answering or repeating work |

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
