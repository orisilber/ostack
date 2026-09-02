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
	mkdir -p "$release/scripts" "$release/skills" "$release/agents"
	cp "$INSTALLER" "$release/scripts/install.sh"
	chmod +x "$release/scripts/install.sh"
	local kind=skill
	for name in "$@"; do
		if [ "$name" = -- ]; then
			kind=agent
			continue
		fi
		if [ "$kind" = skill ]; then
			mkdir -p "$release/skills/$name"
			printf -- '---\nname: %s\ndescription: Fixture skill.\n---\n' "$name" > "$release/skills/$name/SKILL.md"
		else
			printf -- '---\nname: %s\ndescription: Fixture agent.\nreadonly: true\n---\n' "$name" > "$release/agents/$name.md"
		fi
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

assert_agent_installed() {
	local install_home="$1" name="$2"
	local target
	for target in \
		"$install_home/.codex/agents" \
		"$install_home/.claude/agents" \
		"$install_home/.cursor/agents"; do
		[ -f "$target/$name.md" ] || {
			echo "expected agent $name in $target" >&2
			exit 1
		}
		[ -f "$target/$name.md.ostack" ] || {
			echo "expected agent ownership marker for $name in $target" >&2
			exit 1
		}
	done
}

make_release v1 keep retired occupied -- keep-agent retired-agent occupied-agent
make_release v2 keep occupied -- keep-agent occupied-agent

INSTALL_ROOT="$TEST_ROOT/installed"
mkdir -p "$INSTALL_ROOT/.agents/skills/occupied"
mkdir -p "$INSTALL_ROOT/.codex/agents"
touch "$INSTALL_ROOT/.codex/agents/occupied-agent.md"
AGENTS_HOME="$INSTALL_ROOT/.agents" OSTACK_INSTALL_HOME="$INSTALL_ROOT" \
	bash "$TEST_ROOT/v1/scripts/install.sh" >/dev/null
assert_installed "$INSTALL_ROOT" keep
assert_installed "$INSTALL_ROOT" retired
assert_agent_installed "$INSTALL_ROOT" keep-agent
assert_agent_installed "$INSTALL_ROOT" retired-agent
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
for target in \
	"$INSTALL_ROOT/.codex/agents" \
	"$INSTALL_ROOT/.claude/agents" \
	"$INSTALL_ROOT/.cursor/agents"; do
	touch "$target/foreign-agent.md"
	ln -s "$TEST_ROOT/foreign-source" "$target/foreign-agent-link.md"
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
for target in \
	"$INSTALL_ROOT/.codex/agents" \
	"$INSTALL_ROOT/.claude/agents" \
	"$INSTALL_ROOT/.cursor/agents"; do
	[ ! -e "$target/retired-agent.md" ] || {
		echo "retired agent remained in $target" >&2
		exit 1
	}
	[ -f "$target/foreign-agent.md" ] || {
		echo "foreign agent was removed from $target" >&2
		exit 1
	}
	[ -L "$target/foreign-agent-link.md" ] || {
		echo "foreign agent symlink was removed from $target" >&2
		exit 1
	}
done
assert_installed "$INSTALL_ROOT" keep
assert_agent_installed "$INSTALL_ROOT" keep-agent

DRY_ROOT="$TEST_ROOT/dry-installed"
mkdir -p "$DRY_ROOT/.agents/skills/occupied"
mkdir -p "$DRY_ROOT/.codex/agents"
touch "$DRY_ROOT/.codex/agents/occupied-agent.md"
AGENTS_HOME="$DRY_ROOT/.agents" OSTACK_INSTALL_HOME="$DRY_ROOT" \
	bash "$TEST_ROOT/v1/scripts/install.sh" >/dev/null
dry_output="$(AGENTS_HOME="$DRY_ROOT/.agents" OSTACK_INSTALL_HOME="$DRY_ROOT" \
	bash "$TEST_ROOT/v2/scripts/install.sh" --dry-run)"
assert_installed "$DRY_ROOT" retired
assert_agent_installed "$DRY_ROOT" retired-agent
[ "$(grep -c 'would remove retired' <<< "$dry_output")" -eq 3 ] || {
	echo 'dry run did not report all retired skills' >&2
	exit 1
}
[ "$(grep -c 'would remove agent retired-agent.md' <<< "$dry_output")" -eq 3 ] || {
	echo 'dry run did not report all retired agents' >&2
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
for target in \
	"$SYMLINK_ROOT/.codex/agents" \
	"$SYMLINK_ROOT/.claude/agents" \
	"$SYMLINK_ROOT/.cursor/agents"; do
	mkdir -p "$target"
	ln -s "$SYMLINK_SOURCE" "$target/keep-agent.md"
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
for target in \
	"$SYMLINK_ROOT/.codex/agents" \
	"$SYMLINK_ROOT/.claude/agents" \
	"$SYMLINK_ROOT/.cursor/agents"; do
	[ -L "$target/keep-agent.md" ] || {
		echo "current-agent symlink was replaced in $target" >&2
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
