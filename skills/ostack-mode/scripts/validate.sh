#!/usr/bin/env bash
# Validate the ostack-mode registry, model schema, and playbook boundaries.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ROUTES=""
MODELS=""

usage() {
	cat >&2 <<'EOF'
usage: validate.sh [--root DIR] [--routes FILE] [--models FILE]
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--root) [ "$#" -ge 2 ] || { usage; exit 2; }; ROOT="$2"; shift 2 ;;
		--routes) [ "$#" -ge 2 ] || { usage; exit 2; }; ROUTES="$2"; shift 2 ;;
		--models) [ "$#" -ge 2 ] || { usage; exit 2; }; MODELS="$2"; shift 2 ;;
		-h|--help) usage; exit 0 ;;
		*) usage; exit 2 ;;
	esac
done

ROUTES="${ROUTES:-$ROOT/skills/ostack-mode/references/routes.json}"
MODELS="${MODELS:-$ROOT/skills/ostack-mode/references/models.example.json}"
OSTACK_SKILLS="$ROOT/skills/ostack-mode"
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
require_file "$MODELS" 'model example missing' || true

if [ -f "$ROUTES" ] && ! jq empty "$ROUTES" >/dev/null 2>&1; then
	usage_error 'route registry is not valid JSON'
fi
if [ -f "$MODELS" ] && ! jq empty "$MODELS" >/dev/null 2>&1; then
	usage_error 'model example is not valid JSON'
fi

if [ -f "$ROUTES" ] && jq empty "$ROUTES" >/dev/null 2>&1; then
	[ "$(jq -r '.version // empty' "$ROUTES")" = 1 ] || usage_error 'route registry version must be 1'
	[ "$(jq -r '.routes | type' "$ROUTES" 2>/dev/null || true)" = array ] || usage_error 'routes must be an array'
	[ "$(jq -r '.outcomeTails | type' "$ROUTES" 2>/dev/null || true)" = object ] || usage_error 'outcomeTails must be an object'

	declare -A seen_ids=()
	declare -A reachable=()
	while IFS= read -r route; do
		id="$(jq -r '.id // empty' <<< "$route")"
		match="$(jq -r '.match // empty' <<< "$route")"
		playbook="$(jq -r '.playbook // empty' <<< "$route")"
		[ -n "$id" ] || usage_error 'route ID is empty'
		if [ -n "$id" ]; then
			[ -z "${seen_ids[$id]+x}" ] || usage_error "route ID is duplicated: $id"
			seen_ids[$id]=1
		fi
		[ -n "$match" ] || usage_error "route '$id' has an empty match statement"
		[ -n "$playbook" ] || usage_error "route '$id' has no playbook"
		if [ -n "$playbook" ]; then
			case "$playbook" in
				playbooks/*.md)
					[ -f "$OSTACK_SKILLS/$playbook" ] || usage_error "route '$id' references missing playbook: $playbook"
					reachable[$playbook]=1 ;;
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
			if ! grep -q "\`$required_skill\`" "$OSTACK_SKILLS/$large_feature_playbook"; then
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
					[ -f "$OSTACK_SKILLS/$item" ] || usage_error "outcome tail '$outcome' references missing playbook: $item"
					reachable[$item]=1 ;;
				skill:*)
					skill_name="${item#skill:}"
					[ -n "$skill_name" ] && [ -d "$ROOT/skills/$skill_name" ] || usage_error "outcome tail '$outcome' references unknown skill: $item" ;;
				*) usage_error "outcome tail '$outcome' has invalid step: $item" ;;
			esac
		done < <(jq -r --arg o "$outcome" '.outcomeTails[$o][]?' "$ROUTES")
	done

	playbooks_dir="$OSTACK_SKILLS/playbooks"
	if [ -d "$playbooks_dir" ]; then
		while IFS= read -r file; do
			rel="playbooks/${file#"$playbooks_dir/"}"
			[ -n "${reachable[$rel]+x}" ] || usage_error "playbook is not reachable from a route or tail: $rel"
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

if [ -f "$MODELS" ] && jq empty "$MODELS" >/dev/null 2>&1; then
	[ "$(jq -r '.version // empty' "$MODELS")" = 1 ] || usage_error 'model example version must be 1'
	[ "$(jq -r '.roles | type' "$MODELS")" = object ] || usage_error 'model roles must be an object'
	for role in exploration implementation judgment prose; do
		[ "$(jq -r --arg r "$role" '.roles[$r] | type' "$MODELS")" = array ] || usage_error "model roles.$role must be an array"
	done
	model_sections=(roles)
	if jq -e 'has("overrides")' "$MODELS" >/dev/null; then
		model_sections+=(overrides)
	fi
	for section in "${model_sections[@]}"; do
		[ "$(jq -r --arg s "$section" '.[$s] | type' "$MODELS")" = object ] || { usage_error "model '$section' must be an object"; continue; }
		while IFS= read -r key; do
			values="$(jq -c --arg s "$section" --arg k "$key" '.[$s][$k]' "$MODELS")"
			[ "$(jq -r 'type' <<< "$values")" = array ] || { usage_error "model $section.$key must be an array"; continue; }
			count="$(jq -r 'length' <<< "$values")"
			[ "$count" -gt 0 ] || usage_error "model $section.$key has an empty array"
			unique="$(jq -r 'unique | length' <<< "$values")"
			[ "$count" = "$unique" ] || usage_error "model $section.$key contains duplicate entries"
			if jq -e 'any(.[]; . == "inherit")' <<< "$values" >/dev/null && [ "$count" -ne 1 ]; then
				usage_error "model $section.$key combines inherit with another model ID"
			fi
			if jq -e 'any(.[]; (type != "string" or length == 0))' <<< "$values" >/dev/null; then
				usage_error "model $section.$key contains an empty or non-string model ID"
			fi
		done < <(jq -r --arg s "$section" '.[$s] | keys[]?' "$MODELS")
	done
fi

# These are the ostack-managed coordinator and callers that previously
# consumed pstack's model roster. Keep this check scoped to those paths rather
# than the setup skill, whose contract explicitly says not to edit pstack's
# file.
ostack_model_files=()
if [ -d "$OSTACK_SKILLS" ]; then
	while IFS= read -r file; do ostack_model_files+=("$file"); done < <(find "$OSTACK_SKILLS" -type f -name '*.md' -print)
fi
for caller in architect arena how interrogate swarm why; do
	caller_file="$ROOT/skills/$caller/SKILL.md"
	[ -f "$caller_file" ] && ostack_model_files+=("$caller_file")
done
for file in "${ostack_model_files[@]}"; do
	if grep -n 'pstack-models\.mdc' "$file" >/dev/null 2>&1; then
		usage_error "ostack skill still references pstack-models.mdc: ${file#"$ROOT/"}"
	fi
done

if [ "$fail" -gt 0 ]; then
	printf 'VALIDATE: FAIL (%d errors)\n' "$fail" >&2
	exit 1
fi
echo 'VALIDATE: PASS'
