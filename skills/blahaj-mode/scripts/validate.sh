#!/usr/bin/env bash
# Validate the blahaj-mode registry and playbook boundaries.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ROUTES=""

usage() {
	cat >&2 <<'EOF'
usage: validate.sh [--root DIR] [--routes FILE]
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--root) [ "$#" -ge 2 ] || { usage; exit 2; }; ROOT="$2"; shift 2 ;;
		--routes) [ "$#" -ge 2 ] || { usage; exit 2; }; ROUTES="$2"; shift 2 ;;
		-h|--help) usage; exit 0 ;;
		*) usage; exit 2 ;;
	esac
done

ROUTES="${ROUTES:-$ROOT/skills/blahaj-mode/references/routes.json}"
MODE_SKILLS="$ROOT/skills/blahaj-mode"
fail=0

usage_error() {
	fail=$((fail + 1))
	printf 'FAIL: %s\n' "$1" >&2
}

require_file() {
	[ -f "$1" ] || { usage_error "$2 ($1)"; return 1; }
}

if ! command -v jq >/dev/null 2>&1; then
	usage_error 'jq is required'
	printf 'VALIDATE: FAIL (%d errors)\n' "$fail" >&2
	exit 1
fi

require_file "$ROUTES" 'route registry missing' || true

if [ -f "$ROUTES" ] && ! jq empty "$ROUTES" >/dev/null 2>&1; then
	usage_error 'route registry is not valid JSON'
fi

if [ -f "$ROUTES" ] && jq empty "$ROUTES" >/dev/null 2>&1; then
	[ "$(jq -r '.version // empty' "$ROUTES")" = 1 ] || usage_error 'route registry version must be 1'
	[ "$(jq -r '.routes | type' "$ROUTES" 2>/dev/null || true)" = array ] || usage_error 'routes must be an array'
	[ "$(jq -r '.outcomeTails | type' "$ROUTES" 2>/dev/null || true)" = object ] || usage_error 'outcomeTails must be an object'
	if ! jq -e '.routes | type == "array" and length > 0 and all(.[];
		type == "object" and
		(.id | type == "string" and length > 0 and (test("[\\r\\n]") | not)) and
		(.match | type == "string" and length > 0) and
		(.playbook | type == "string" and length > 0 and (test("[\\r\\n]") | not)))' "$ROUTES" >/dev/null 2>&1; then
		usage_error 'routes require nonempty string IDs, matches, and single-line playbook paths; IDs must be single-line'
		exit 1
	fi

	# Keep this validator runnable with the Bash shipped by macOS. IDs and
	# playbook paths are newline-free, so newline-delimited sets are sufficient
	# and avoid Bash 4-only associative arrays.
	seen_ids=$'\n'
	reachable=$'\n'
	while IFS= read -r route; do
		id="$(jq -r '.id // empty' <<< "$route")"
		match="$(jq -r '.match // empty' <<< "$route")"
		playbook="$(jq -r '.playbook // empty' <<< "$route")"
		[ -n "$id" ] || usage_error 'route ID is empty'
		if [ -n "$id" ]; then
			if grep -Fqx -- "$id" <<< "$seen_ids"; then
				usage_error "route ID is duplicated: $id"
			fi
			seen_ids+="$id"$'\n'
		fi
		[ -n "$match" ] || usage_error "route '$id' has an empty match statement"
		[ -n "$playbook" ] || usage_error "route '$id' has no playbook"
		if [ -n "$playbook" ]; then
			case "$playbook" in
				playbooks/*.md)
					[ -f "$MODE_SKILLS/$playbook" ] || usage_error "route '$id' references missing playbook: $playbook"
				reachable+="$playbook"$'\n' ;;
				*) usage_error "route '$id' playbook must be playbooks/*.md: $playbook" ;;
			esac
		fi
		allowed_type="$(jq -r '.allowedOutcomes | type' <<< "$route")"
		[ "$allowed_type" = array ] || usage_error "route '$id' allowedOutcomes must be an array"
		allowed_count="$(jq -r '(.allowedOutcomes // []) | length' <<< "$route")"
		[ "$allowed_count" -gt 0 ] || usage_error "route '$id' has no allowed outcome"
		if [ "$allowed_type" = array ]; then
			while IFS= read -r allowed; do
				case "$allowed" in
					answer|local-change|mr-open|merge-ready) ;;
					*) usage_error "route '$id' has an unsupported outcome: $allowed" ;;
				esac
			done < <(jq -r '.allowedOutcomes[]' <<< "$route")
		fi
		default="$(jq -r '.defaultOutcome // empty' <<< "$route")"
		[ -n "$default" ] || usage_error "route '$id' has no default outcome"
		if [ -n "$default" ] && ! jq -e --arg d "$default" '(.allowedOutcomes // []) | index($d)' <<< "$route" >/dev/null; then
			usage_error "route '$id' default outcome is not allowed: $default"
		fi
	done < <(jq -c '.routes[]?' "$ROUTES")

	feature_index="$(jq -r '[.routes[].id] | index("feature") // -1' "$ROUTES")"
	large_feature_index="$(jq -r '[.routes[].id] | index("large-feature") // -1' "$ROUTES")"
	if [ "$feature_index" -ge 0 ]; then
		[ "$large_feature_index" -ge 0 ] || usage_error "feature route requires a large-feature route"
		if [ "$large_feature_index" -ge 0 ] && [ "$large_feature_index" -ge "$feature_index" ]; then
			usage_error "large-feature route must appear before feature"
		fi
	fi
	if [ "$large_feature_index" -ge 0 ]; then
		large_feature_playbook="$(jq -r '.routes[] | select(.id == "large-feature") | .playbook' "$ROUTES")"
		for required_skill in decompose-epic swarm verify-changes; do
			if ! grep -q "\`$required_skill\`" "$MODE_SKILLS/$large_feature_playbook"; then
				usage_error "large-feature playbook must reference $required_skill"
			fi
		done
	fi

	for outcome in answer local-change mr-open merge-ready; do
		tail_type="$(jq -r --arg o "$outcome" '.outcomeTails[$o] | type' "$ROUTES")"
		[ "$tail_type" = array ] || { usage_error "outcome tail '$outcome' must be an array"; continue; }
		while IFS= read -r item; do
			[ -n "$item" ] || { usage_error "outcome tail '$outcome' contains an empty step"; continue; }
			case "$item" in
				playbooks/*.md)
					[ -f "$MODE_SKILLS/$item" ] || usage_error "outcome tail '$outcome' references missing playbook: $item"
					reachable+="$item"$'\n' ;;
				skill:*)
					skill_name="${item#skill:}"
					[ -n "$skill_name" ] && [ -d "$ROOT/skills/$skill_name" ] || usage_error "outcome tail '$outcome' references unknown skill: $item" ;;
				*) usage_error "outcome tail '$outcome' has invalid step: $item" ;;
			esac
		done < <(jq -r --arg o "$outcome" '.outcomeTails[$o][]?' "$ROUTES")
	done

	playbooks_dir="$MODE_SKILLS/playbooks"
	if [ -d "$playbooks_dir" ]; then
		while IFS= read -r file; do
			rel="playbooks/${file#"$playbooks_dir/"}"
			grep -Fqx -- "$rel" <<< "$reachable" || usage_error "playbook is not reachable from a route or tail: $rel"
		done < <(find "$playbooks_dir" -type f -name '*.md' -print)

		# Playbooks must stay generic and defer repository-specific commands to
		# verify-changes' discovery step.
		while IFS= read -r file; do
			if grep -nE '(^|[`[:space:]])(npm( run)? (test|check|lint)|yarn (test|lint)|pnpm (test|lint)|pytest|go test|cargo test|mvn (test|verify)|gradle (test|check)|dotnet test|bundle exec|phpunit|mix test|make (test|check|lint))([[:space:]`]|$)' "$file" >/dev/null; then
				usage_error "playbook contains a project-specific verification command: ${file#"$ROOT/"}"
			fi
		done < <(find "$playbooks_dir" -type f -name '*.md' -print)
	fi
fi

if [ "$fail" -gt 0 ]; then
	printf 'VALIDATE: FAIL (%d errors)\n' "$fail" >&2
	exit 1
fi
echo 'VALIDATE: PASS'
