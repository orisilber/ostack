#!/usr/bin/env bash
# Symlink every skill in this checkout into every supported host:
#   ~/.agents/skills  (canonical runtime location)
#   ~/.claude/skills  (Claude Code)
#   ~/.cursor/skills  (Cursor)
# Safe to re-run: existing symlinks are refreshed, real directories are left
# alone and reported instead of overwritten.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
TARGETS=("$AGENTS_HOME/skills" "$HOME/.claude/skills" "$HOME/.cursor/skills")
DRY_RUN=0

for arg in "$@"; do
	case "$arg" in
	--dry-run) DRY_RUN=1 ;;
	-h | --help)
		echo "Usage: $0 [--dry-run]"
		echo "  AGENTS_HOME env var overrides the default ~/.agents"
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

for target in "${TARGETS[@]}"; do
	mkdir -p "$target"
done

linked=0
skipped=0
for skill_dir in "$REPO_DIR"/skills/*/; do
	name="$(basename "$skill_dir")"
	[ -f "$skill_dir/SKILL.md" ] || continue
	source="${skill_dir%/}"

	for target in "${TARGETS[@]}"; do
		link="$target/$name"
		if [ -e "$link" ] && [ ! -L "$link" ]; then
			echo "skip $name in $target: exists and is not a symlink" >&2
			skipped=$((skipped + 1))
			continue
		fi
		if [ "$DRY_RUN" = 1 ]; then
			echo "would link $name -> $source ($target)"
		else
			ln -sfn "$source" "$link"
		fi
	done
	linked=$((linked + 1))
done

echo
if [ "$DRY_RUN" = 1 ]; then
	echo "Dry run: $linked skill(s) x ${#TARGETS[@]} hosts would be linked, $skipped skipped."
	exit 0
fi

echo "Linked $linked skill(s) into ${#TARGETS[@]} locations:"
printf '  %s\n' "${TARGETS[@]}"
[ "$skipped" -gt 0 ] && echo "Skipped $skipped (see warnings above); remove or rename them and re-run to pick those up."

echo
echo "Memory skills (memory-admin, memory-capture, memory-loop, memory-recall)"
echo "ship from github.com/orisilber/agent-memory, not this repo. Its own"
echo "installer links those the same way."
