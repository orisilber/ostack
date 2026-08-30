#!/usr/bin/env bash
set -euo pipefail

FIXTURE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$FIXTURE_ROOT/../../.." && pwd)"
VALID="$FIXTURE_ROOT/valid-root"
VALIDATOR="$ROOT/skills/ostack-mode/scripts/validate.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp -R "$VALID" "$TMP/root"
"$VALIDATOR" --root "$TMP/root" >/dev/null

expect_fail() {
	local name="$1" expression="$2"
	cp -R "$VALID" "$TMP/$name"
	jq "$expression" "$TMP/$name/skills/ostack-mode/references/routes.json" > "$TMP/$name/routes.tmp"
	mv "$TMP/$name/routes.tmp" "$TMP/$name/skills/ostack-mode/references/routes.json"
	if "$VALIDATOR" --root "$TMP/$name" >/dev/null 2>&1; then
		echo "expected validator failure: $name" >&2
		exit 1
	fi
}

expect_model_fail() {
	local name="$1" expression="$2"
	cp -R "$VALID" "$TMP/$name"
	jq "$expression" "$TMP/$name/skills/ostack-mode/references/models.example.json" > "$TMP/$name/models.tmp"
	mv "$TMP/$name/models.tmp" "$TMP/$name/skills/ostack-mode/references/models.example.json"
	if "$VALIDATOR" --root "$TMP/$name" >/dev/null 2>&1; then
		echo "expected model validator failure: $name" >&2
		exit 1
	fi
}

expect_fail bad-version '.version = 2'
expect_fail empty-id '.routes[0].id = ""'
expect_fail duplicate-id '.routes += [.routes[0]]'
expect_fail empty-match '.routes[0].match = ""'
expect_fail missing-playbook '.routes[0].playbook = "playbooks/missing.md"'
expect_fail no-allowed '.routes[0].allowedOutcomes = []'
expect_fail bad-default '.routes[0].defaultOutcome = "answer"'
expect_fail bad-tail '.outcomeTails["local-change"] = ["playbooks/missing.md"]'
expect_fail unknown-skill '.outcomeTails["local-change"] = ["skill:not-a-skill"]'
expect_fail missing-large-feature '.routes[0].id = "feature"'
expect_fail large-feature-after-feature '.routes[0] as $route | .routes = [($route | .id = "feature"), ($route | .id = "large-feature")]'

cp -R "$VALID" "$TMP/unreachable"
printf '# Unreachable\n' > "$TMP/unreachable/skills/ostack-mode/playbooks/unreachable.md"
if "$VALIDATOR" --root "$TMP/unreachable" >/dev/null 2>&1; then
	echo 'expected unreachable playbook failure' >&2
	exit 1
fi

cp -R "$VALID" "$TMP/project-command"
printf '\nRun `npm test` here.\n' >> "$TMP/project-command/skills/ostack-mode/playbooks/sample.md"
if "$VALIDATOR" --root "$TMP/project-command" >/dev/null 2>&1; then
	echo 'expected project-command failure' >&2
	exit 1
fi

expect_model_fail model-version '.version = 2'
expect_model_fail model-empty '.roles.exploration = []'
expect_model_fail model-duplicates '.roles.exploration = ["foo", "foo"]'
expect_model_fail model-inherit-mixed '.roles.exploration = ["inherit", "foo"]'
expect_model_fail model-empty-string '.roles.exploration = [""]'

cp -R "$VALID" "$TMP/pstack"
printf '\nSee pstack-models.mdc\n' >> "$TMP/pstack/skills/ostack-mode/SKILL.md"
if "$VALIDATOR" --root "$TMP/pstack" >/dev/null 2>&1; then
	echo 'expected pstack reference failure' >&2
	exit 1
fi

echo 'OSTACK VALIDATOR FIXTURES: PASS'
