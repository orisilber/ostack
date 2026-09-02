#!/usr/bin/env bash
# Install every skill and subagent in this checkout into every supported host:
#   ~/.agents/skills  (canonical runtime location)
#   ~/.claude/skills  (Claude Code)
#   ~/.cursor/skills  (Cursor)
#   ~/.codex/agents, ~/.claude/agents, ~/.cursor/agents
# Files are COPIED, not symlinked, so the clone can be deleted after install.
# Re-running replaces current items and removes retired copies with an .ostack
# marker. Unmarked paths and symlinks are left alone and reported.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_HOME="${OSTACK_INSTALL_HOME:-$HOME}"
AGENTS_HOME="${AGENTS_HOME:-$INSTALL_HOME/.agents}"
SKILL_TARGETS=("$AGENTS_HOME/skills" "$INSTALL_HOME/.claude/skills" "$INSTALL_HOME/.cursor/skills")
AGENT_TARGETS=("$INSTALL_HOME/.codex/agents" "$INSTALL_HOME/.claude/agents" "$INSTALL_HOME/.cursor/agents")
DRY_RUN=0

for arg in "$@"; do
	case "$arg" in
	--dry-run) DRY_RUN=1 ;;
	-h | --help)
		echo "Usage: $0 [--dry-run]"
		echo "  AGENTS_HOME env var overrides the default ~/.agents"
		echo "  OSTACK_INSTALL_HOME env var overrides the user home for all targets"
		exit 0
		;;
	*)
		echo "Unknown argument: $arg" >&2
		exit 1
		;;
	esac
done

if [ ! -d "$REPO_DIR/skills" ]; then
	echo "No skills/ directory found at $REPO_DIR" >&2
	exit 1
fi

for target in "${SKILL_TARGETS[@]}" "${AGENT_TARGETS[@]}"; do
	mkdir -p "$target"
done

# Ownership markers: an installed skill carries .ostack so upgrades can tell
# "ours, replace it" from "foreign, don't touch".
installed=0
replaced=0
removed=0
skipped=0
for skill_dir in "$REPO_DIR"/skills/*/; do
	name="$(basename "$skill_dir")"
	[ -f "$skill_dir/SKILL.md" ] || continue
	source="${skill_dir%/}"

	for target in "${SKILL_TARGETS[@]}"; do
		dest="$target/$name"
		if [ -L "$dest" ]; then
			echo "skip $name in $target: symlink is not owned by ostack" >&2
			skipped=$((skipped + 1))
			continue
		fi
		if [ -e "$dest" ] && [ ! -f "$dest/.ostack" ]; then
			echo "skip $name in $target: exists but was not installed by ostack" >&2
			skipped=$((skipped + 1))
			continue
		fi
		if [ "$DRY_RUN" = 1 ]; then
			echo "would install $name -> $target"
			continue
		fi
		rm -rf "$dest"
		cp -R "$source" "$dest"
		touch "$dest/.ostack"
	done
	[ "$DRY_RUN" = 1 ] || installed=$((installed + 1))
done

for target in "${SKILL_TARGETS[@]}"; do
	for dest in "$target"/*; do
		[ -e "$dest" ] || [ -L "$dest" ] || continue
		[ -L "$dest" ] && continue
		[ -d "$dest" ] || continue
		[ -f "$dest/.ostack" ] || continue
		name="$(basename "$dest")"
		[ -f "$REPO_DIR/skills/$name/SKILL.md" ] && continue
		if [ "$DRY_RUN" = 1 ]; then
			echo "would remove $name from $target"
		else
			rm -rf "$dest"
			echo "removed $name from $target"
		fi
		removed=$((removed + 1))
	done
done

installed_agents=0
if [ -d "$REPO_DIR/agents" ]; then
	for source in "$REPO_DIR"/agents/*.md; do
		[ -f "$source" ] || continue
		name="$(basename "$source")"
		for target in "${AGENT_TARGETS[@]}"; do
			dest="$target/$name"
			marker="$dest.ostack"
			if [ -L "$dest" ]; then
				echo "skip agent $name in $target: symlink is not owned by ostack" >&2
				skipped=$((skipped + 1))
				continue
			fi
			if [ -e "$dest" ] && [ ! -f "$marker" ]; then
				echo "skip agent $name in $target: exists but was not installed by ostack" >&2
				skipped=$((skipped + 1))
				continue
			fi
			if [ "$DRY_RUN" = 1 ]; then
				echo "would install agent $name -> $target"
				continue
			fi
			cp "$source" "$dest"
			touch "$marker"
		done
		[ "$DRY_RUN" = 1 ] || installed_agents=$((installed_agents + 1))
	done
fi

for target in "${AGENT_TARGETS[@]}"; do
	for marker in "$target"/*.md.ostack; do
		[ -f "$marker" ] || continue
		dest="${marker%.ostack}"
		name="$(basename "$dest")"
		[ -f "$REPO_DIR/agents/$name" ] && continue
		if [ -L "$dest" ]; then
			rm -f "$marker"
			continue
		fi
		if [ "$DRY_RUN" = 1 ]; then
			echo "would remove agent $name from $target"
		else
			rm -f "$dest" "$marker"
			echo "removed agent $name from $target"
		fi
		removed=$((removed + 1))
	done
done

echo
if [ "$DRY_RUN" = 1 ]; then
	agent_count="$(find "$REPO_DIR/agents" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
	echo "Dry run: $(( $(ls -d "$REPO_DIR"/skills/*/ 2>/dev/null | wc -l) )) skill(s) x ${#SKILL_TARGETS[@]} hosts; $agent_count agent(s) x ${#AGENT_TARGETS[@]} hosts; $removed retired item(s) would be removed."
	exit 0
fi

echo "Installed $installed skill(s) into ${#SKILL_TARGETS[@]} locations:"
printf '  %s\n' "${SKILL_TARGETS[@]}"
echo "Installed $installed_agents agent(s) into ${#AGENT_TARGETS[@]} locations:"
printf '  %s\n' "${AGENT_TARGETS[@]}"
if [ "$removed" -gt 0 ]; then
	echo "Removed $removed retired item(s)."
fi
if [ "$skipped" -gt 0 ]; then
	echo "Skipped $skipped foreign path(s) (see warnings above)."
fi
