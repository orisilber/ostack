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
MODELS="${MODELS:-$ROOT/skills/ostack-mode/references/models.example.md}"
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

# The model configuration is an always-applied Cursor rule, not a data file a
# skill has to go read. Validate the example rule's shape and the role labels
# the delegating skills resolve against.
MODEL_ROLES=(
	"exploration" "implementation" "judgment" "prose"
	"architect runners" "arena runners" "arena cross-judge"
	"how explorer" "how explainer" "how critics"
	"interrogate reviewers" "swarm workers"
	"why investigators" "why synthesizer"
)

if [ -f "$MODELS" ]; then
	rule="$(awk '/^```$/{ inblock = !inblock; next } inblock' "$MODELS")"
	if [ -z "$rule" ]; then
		usage_error 'model example has no fenced rule block'
	else
		grep -qx 'alwaysApply: true' <<< "$rule" || \
			usage_error 'model example rule must set alwaysApply: true'

		declare -A seen_roles=()
		while IFS= read -r line; do
			case "$line" in ''|'#'*|'---'|'description:'*|'alwaysApply:'*) continue ;; esac
			case "$line" in *:*) ;; *) usage_error "model rule line is not 'role: value': $line"; continue ;; esac
			role="${line%%:*}"
			values="${line#*:}"

			known=0
			for candidate in "${MODEL_ROLES[@]}"; do
				[ "$role" = "$candidate" ] && known=1 && break
			done
			[ "$known" -eq 1 ] || { usage_error "model rule has an unknown role: $role"; continue; }
			[ -z "${seen_roles[$role]+x}" ] || usage_error "model rule role is duplicated: $role"
			seen_roles[$role]=1

			count=0 inherit=0
			declare -A seen_values=()
			IFS=',' read -ra entries <<< "$values"
			for entry in "${entries[@]}"; do
				entry="$(printf '%s' "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
				[ -n "$entry" ] || { usage_error "model rule role '$role' has an empty entry"; continue; }
				[ -z "${seen_values[$entry]+x}" ] || usage_error "model rule role '$role' repeats entry: $entry"
				seen_values[$entry]=1
				[ "$entry" = inherit ] && inherit=1
				count=$((count + 1))
			done
			unset seen_values
			[ "$count" -gt 0 ] || usage_error "model rule role '$role' has no value"
			[ "$inherit" -eq 0 ] || [ "$count" -eq 1 ] || \
				usage_error "model rule role '$role' combines inherit with a model ID"
		done <<< "$rule"

		# Every role a delegating skill resolves must be documented, or setup
		# writes a line nothing reads.
		for role in "${MODEL_ROLES[@]}"; do
			[ -n "${seen_roles[$role]+x}" ] || usage_error "model example omits role: $role"
		done
	fi
fi

# Every delegating skill must name the rule and pass a model, or the
# configuration silently stops reaching subagents (the bug this file guards).
for caller in architect arena how interrogate swarm why; do
	caller_file="$ROOT/skills/$caller/SKILL.md"
	[ -f "$caller_file" ] || continue
	grep -qF '~/.cursor/rules/ostack-models.mdc' "$caller_file" || \
		usage_error "$caller does not resolve models from the ostack rule"
	grep -qF 'then `inherit`' "$caller_file" || \
		usage_error "$caller does not fall back to inherit"
	grep -qF 'subagent `model` argument' "$caller_file" || \
		usage_error "$caller never passes the resolved model to a subagent"
done

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
