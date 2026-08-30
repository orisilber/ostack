#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Simulate a caller with a custom canonical skills directory. Fixture installs
# must override this value rather than escaping their temporary install root.
CALLER_AGENTS_HOME="$TEST_ROOT/caller-agents"
export AGENTS_HOME="$CALLER_AGENTS_HOME"

make_release() {
	local version="$1"
	shift
	local release="$TEST_ROOT/$version"
	mkdir -p "$release/scripts" "$release/skills"
	cp "$INSTALLER" "$release/scripts/install.sh"
	chmod +x "$release/scripts/install.sh"
	for name in "$@"; do
		mkdir -p "$release/skills/$name"
		printf -- '---\nname: %s\ndescription: Fixture skill.\n---\n' "$name" > "$release/skills/$name/SKILL.md"
	done
}

assert_installed() {
	local install_home="$1" name="$2"
	local target
	for target in \
		"$install_home/.agents/skills" \
		"$install_home/.claude/skills" \
		"$install_home/.cursor/skills"; do
		[ -f "$target/$name/SKILL.md" ] || {
			echo "expected $name in $target" >&2
			exit 1
		}
		[ -f "$target/$name/.ostack" ] || {
			echo "expected ownership marker for $name in $target" >&2
			exit 1
		}
	done
}

make_release v1 keep retired occupied
make_release v2 keep occupied

INSTALL_ROOT="$TEST_ROOT/installed"
mkdir -p "$INSTALL_ROOT/.agents/skills/occupied"
AGENTS_HOME="$INSTALL_ROOT/.agents" OSTACK_INSTALL_HOME="$INSTALL_ROOT" \
	bash "$TEST_ROOT/v1/scripts/install.sh" >/dev/null
assert_installed "$INSTALL_ROOT" keep
assert_installed "$INSTALL_ROOT" retired
[ ! -e "$CALLER_AGENTS_HOME/skills/keep" ] || {
	echo 'fixture installer escaped into the caller AGENTS_HOME' >&2
	exit 1
}

mkdir -p "$TEST_ROOT/foreign-source"
for target in \
	"$INSTALL_ROOT/.agents/skills" \
	"$INSTALL_ROOT/.claude/skills" \
	"$INSTALL_ROOT/.cursor/skills"; do
	mkdir -p "$target/foreign"
	touch "$target/foreign/SKILL.md"
	ln -s "$TEST_ROOT/foreign-source" "$target/foreign-link"
done

AGENTS_HOME="$INSTALL_ROOT/.agents" OSTACK_INSTALL_HOME="$INSTALL_ROOT" \
	bash "$TEST_ROOT/v2/scripts/install.sh" >/dev/null
for target in \
	"$INSTALL_ROOT/.agents/skills" \
	"$INSTALL_ROOT/.claude/skills" \
	"$INSTALL_ROOT/.cursor/skills"; do
	[ ! -e "$target/retired" ] || {
		echo "retired skill remained in $target" >&2
		exit 1
	}
	[ -d "$target/foreign" ] || {
		echo "foreign directory was removed from $target" >&2
		exit 1
	}
	[ -L "$target/foreign-link" ] || {
		echo "foreign symlink was removed from $target" >&2
		exit 1
	}
done
assert_installed "$INSTALL_ROOT" keep

DRY_ROOT="$TEST_ROOT/dry-installed"
mkdir -p "$DRY_ROOT/.agents/skills/occupied"
AGENTS_HOME="$DRY_ROOT/.agents" OSTACK_INSTALL_HOME="$DRY_ROOT" \
	bash "$TEST_ROOT/v1/scripts/install.sh" >/dev/null
dry_output="$(AGENTS_HOME="$DRY_ROOT/.agents" OSTACK_INSTALL_HOME="$DRY_ROOT" \
	bash "$TEST_ROOT/v2/scripts/install.sh" --dry-run)"
assert_installed "$DRY_ROOT" retired
[ "$(grep -c 'would remove retired' <<< "$dry_output")" -eq 3 ] || {
	echo 'dry run did not report all retired skills' >&2
	exit 1
}

SYMLINK_ROOT="$TEST_ROOT/symlink-installed"
SYMLINK_SOURCE="$TEST_ROOT/current-skill-source"
mkdir -p "$SYMLINK_SOURCE"
for target in \
	"$SYMLINK_ROOT/.agents/skills" \
	"$SYMLINK_ROOT/.claude/skills" \
	"$SYMLINK_ROOT/.cursor/skills"; do
	mkdir -p "$target"
	ln -s "$SYMLINK_SOURCE" "$target/keep"
done
AGENTS_HOME="$SYMLINK_ROOT/.agents" OSTACK_INSTALL_HOME="$SYMLINK_ROOT" \
	bash "$TEST_ROOT/v2/scripts/install.sh" >/dev/null
for target in \
	"$SYMLINK_ROOT/.agents/skills" \
	"$SYMLINK_ROOT/.claude/skills" \
	"$SYMLINK_ROOT/.cursor/skills"; do
	[ -L "$target/keep" ] || {
		echo "current-skill symlink was replaced in $target" >&2
		exit 1
	}
done

CLEAN_ROOT="$TEST_ROOT/clean-installed"
if ! AGENTS_HOME="$CLEAN_ROOT/.agents" OSTACK_INSTALL_HOME="$CLEAN_ROOT" \
	bash "$TEST_ROOT/v2/scripts/install.sh" >/dev/null; then
	echo 'clean install returned a failure status' >&2
	exit 1
fi

echo 'INSTALL UPGRADE: PASS'
