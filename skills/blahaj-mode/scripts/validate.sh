#!/usr/bin/env bash
# Validate the blahaj-mode registry, model schema, and playbook boundaries.
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

ROUTES="${ROUTES:-$ROOT/skills/blahaj-mode/references/routes.json}"
MODELS="${MODELS:-$ROOT/skills/blahaj-mode/references/models.example.md}"
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
require_file "$MODELS" 'model example missing' || true

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
		# Split frontmatter from body. Cursor only honours alwaysApply as a
		# frontmatter field, so a copy of it below the closing --- is body
		# text and does not make the rule load.
		if [ "$(head -1 <<< "$rule")" != '---' ]; then
			usage_error 'model example rule does not open with frontmatter'
			front='' body=''
		elif ! awk 'NR == 1 { next } /^---$/ { found = 1; exit } END { exit found ? 0 : 1 }' <<< "$rule"; then
			usage_error 'model example rule frontmatter is not closed'
			front='' body=''
		else
			front="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' <<< "$rule")"
			body="$(awk 'NR == 1 { next } !seen && /^---$/ { seen = 1; next } seen' <<< "$rule")"
		fi

		# Exactly one, so a stray alwaysApply: false cannot sit alongside a
		# true and leave which one wins to chance.
		always="$(grep -c '^alwaysApply:' <<< "$front" || true)"
		if [ "$always" -ne 1 ]; then
			usage_error "model example rule needs exactly one alwaysApply field, found $always"
		elif ! grep -qx 'alwaysApply: true' <<< "$front"; then
			usage_error 'model example rule must set alwaysApply: true'
		fi

		# The body carries role lines only. An alwaysApply or description that
		# drifted out of the frontmatter trips the unknown-role check below.
		seen_roles=$'\n'
		while IFS= read -r line; do
			case "$line" in ''|'#'*) continue ;; esac
			case "$line" in *:*) ;; *) usage_error "model rule line is not 'role: value': $line"; continue ;; esac
			role="${line%%:*}"
			values="${line#*:}"

			known=0
			for candidate in "${MODEL_ROLES[@]}"; do
				[ "$role" = "$candidate" ] && known=1 && break
			done
			[ "$known" -eq 1 ] || { usage_error "model rule has an unknown role: $role"; continue; }
			if grep -Fqx -- "$role" <<< "$seen_roles"; then
				usage_error "model rule role is duplicated: $role"
			fi
			seen_roles+="$role"$'\n'

			count=0 inherit=0
			seen_values=$'\n'
			values="$(printf '%s' "$values" | sed 's/[[:space:]]*$//')"
			case "$values" in *,) usage_error "model rule role '$role' has a trailing empty entry" ;; esac
			IFS=',' read -ra entries <<< "$values"
			for entry in "${entries[@]}"; do
				entry="$(printf '%s' "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
				[ -n "$entry" ] || { usage_error "model rule role '$role' has an empty entry"; continue; }
				if grep -Fqx -- "$entry" <<< "$seen_values"; then
					usage_error "model rule role '$role' repeats entry: $entry"
				fi
				seen_values+="$entry"$'\n'
				[ "$entry" = inherit ] && inherit=1
				count=$((count + 1))
			done
			unset seen_values
			[ "$count" -gt 0 ] || usage_error "model rule role '$role' has no value"
			[ "$inherit" -eq 0 ] || [ "$count" -eq 1 ] || \
				usage_error "model rule role '$role' combines inherit with a model ID"
		done <<< "$body"

		# Generic defaults are required; exact overrides are intentionally optional.
		for role in exploration implementation judgment prose; do
			grep -Fqx -- "$role" <<< "$seen_roles" || usage_error "model example omits role: $role"
		done
	fi
fi

# Every delegating skill must name the rule and pass a model, or the
# configuration silently stops reaching subagents (the bug this file guards).
for caller in architect arena how interrogate swarm why; do
	caller_file="$ROOT/skills/$caller/SKILL.md"
	[ -f "$caller_file" ] || continue
	model_doc="$caller_file"
	case "$caller" in
		how) model_doc="$ROOT/skills/how/references/exploration.md" ;;
		why) model_doc="$ROOT/skills/why/references/investigation.md" ;;
	esac
	grep -qF '~/.cursor/rules/ostack-models.mdc' "$model_doc" || \
		usage_error "$caller does not resolve models from the ostack rule"
	grep -qF 'then `inherit`' "$model_doc" || \
		usage_error "$caller does not fall back to inherit"
	grep -qF 'subagent `model` argument' "$model_doc" || \
		usage_error "$caller never passes the resolved model to a subagent"
done

# These are the ostack-managed coordinator and callers that previously
# consumed pstack's model roster. Keep this check scoped to those paths rather
# than the setup skill, whose contract explicitly says not to edit pstack's
# file.
ostack_model_files=()
if [ -d "$MODE_SKILLS" ]; then
	while IFS= read -r file; do ostack_model_files+=("$file"); done < <(find "$MODE_SKILLS" -type f -name '*.md' -print)
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
