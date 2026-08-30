#!/usr/bin/env bash
# Install every skill in this checkout into every supported host:
#   ~/.agents/skills  (canonical runtime location)
#   ~/.claude/skills  (Claude Code)
#   ~/.cursor/skills  (Cursor)
# Skills are COPIED, not symlinked, so the clone can be deleted after install.
# Re-running replaces current skills and removes retired copies with an .ostack
# marker. Unmarked directories and symlinks are left alone and reported.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_HOME="${OSTACK_INSTALL_HOME:-$HOME}"
AGENTS_HOME="${AGENTS_HOME:-$INSTALL_HOME/.agents}"
TARGETS=("$AGENTS_HOME/skills" "$INSTALL_HOME/.claude/skills" "$INSTALL_HOME/.cursor/skills")
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

for target in "${TARGETS[@]}"; do
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

	for target in "${TARGETS[@]}"; do
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

for target in "${TARGETS[@]}"; do
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

echo
if [ "$DRY_RUN" = 1 ]; then
	echo "Dry run: $(( $(ls -d "$REPO_DIR"/skills/*/ 2>/dev/null | wc -l) )) skill(s) x ${#TARGETS[@]} hosts; $removed retired skill(s) would be removed."
	exit 0
fi

echo "Installed $installed skill(s) into ${#TARGETS[@]} locations:"
printf '  %s\n' "${TARGETS[@]}"
if [ "$removed" -gt 0 ]; then
	echo "Removed $removed retired skill(s)."
fi
if [ "$skipped" -gt 0 ]; then
	echo "Skipped $skipped foreign path(s) (see warnings above)."
fi
