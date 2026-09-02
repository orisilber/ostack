#!/usr/bin/env bash
# Layer 1 -- behavioral eval runner.
#   evals/run.sh                 run every scenario
#   evals/run.sh <name> [...]    run specific scenarios (yaml file paths,
#                                 relative to evals/scenarios/)
# Each scenario is one YAML file under evals/scenarios/<skill>/<name>.yaml:
#   skill:        which skill the prompt should trigger
#   setup:        shell run in $WORK before the agent (git init, fixture files)
#   prompt:       what's sent to the headless agent
#   fixtures:     list of {match, response} pairs the glab/acli stubs replay,
#                 lowest-index match against the full argument string wins
#   assert:       tools_called / tools_not_called (against $CALLS_LOG),
#                 output_contains / output_not_contains (against $OUT), all
#                 extended regex; plus an optional custom: shell escape hatch
#                 for checks that don't fit the declarative shape (repo state,
#                 ordering, counting)
# Agent CLIs see stub shims first on PATH; HOME is a sandbox so skills load
# from this checkout, never from the developer's real config.
set -uo pipefail

EVALS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$EVALS")"
STUBS="$EVALS/stubs/bin"
RESULTS="$EVALS/results.jsonl"
AGENT="${AGENT:-auto}"

source "$EVALS/lib/py_with_yaml.sh"
PY="$(resolve_python)"

resolve_agent() {
	[ "$AGENT" != "auto" ] && { echo "$AGENT"; return; }
	if command -v cursor >/dev/null 2>&1; then echo cursor
	elif command -v opencode >/dev/null 2>&1; then echo opencode
	elif command -v claude >/dev/null 2>&1; then echo claude
	else echo none; fi
}

run_agent() {
	local pf="$1" which_agent="$2"
	local prompt
	prompt="$(cat "$pf")"
	case "$which_agent" in
		cursor)   cursor agent -p --yolo "$prompt" ;;
		opencode) opencode run "$prompt" ;;
		claude)   claude -p "$prompt" ;;
		*) return 66 ;;
	esac
}

link_runtime() {
	local home="$1" src name dst target
	mkdir -p \
		"$home/.agents/skills" "$home/.claude/skills" \
		"$home/.codex/agents" "$home/.claude/agents" "$home/.cursor/agents"
	for src in "$ROOT"/skills/*/; do
		name="$(basename "$src")"
		dst="${src%/}"
		ln -sfn "$dst" "$home/.claude/skills/$name"
		ln -sfn "$dst" "$home/.agents/skills/$name"
	done
	for src in "$ROOT"/agents/*.md; do
		[ -f "$src" ] || continue
		name="$(basename "$src")"
		for target in \
			"$home/.codex/agents" \
			"$home/.claude/agents" \
			"$home/.cursor/agents"; do
			ln -sfn "$src" "$target/$name"
		done
	done
}

if [ $# -gt 0 ]; then
	SCENARIOS=()
	for n in "$@"; do SCENARIOS+=("$EVALS/scenarios/$n"); done
else
	mapfile -t SCENARIOS < <(find "$EVALS/scenarios" -name '*.yaml' | sort)
fi

WHICH_AGENT="$(resolve_agent)"
if [ "$WHICH_AGENT" = none ]; then
	echo "No headless agent CLI found (cursor/opencode/claude)." >&2
	exit 3
fi
echo "Agent adapter: $WHICH_AGENT"

pass=0
fail=0
: > "$RESULTS.tmp"
for S in "${SCENARIOS[@]}"; do
	name="$(basename "$S" .yaml)"
	echo "== $name"

	json="$("$PY" "$EVALS/lib/yaml2json.py" "$S")"
	skill="$(jq -r '.skill' <<< "$json")"
	setup="$(jq -r '.setup // ""' <<< "$json")"
	prompt="$(jq -r '.prompt // ""' <<< "$json")"
	custom="$(jq -r '.assert.custom // ""' <<< "$json")"
	mapfile -t tools_called < <(jq -r '.assert.tools_called[]? // empty' <<< "$json")
	mapfile -t tools_not_called < <(jq -r '.assert.tools_not_called[]? // empty' <<< "$json")
	mapfile -t output_contains < <(jq -r '.assert.output_contains[]? // empty' <<< "$json")
	mapfile -t output_not_contains < <(jq -r '.assert.output_not_contains[]? // empty' <<< "$json")

	SANDBOX="$(mktemp -d /tmp/ostack-eval.XXXXXX)"
	HOME="$SANDBOX/home" WORK="$SANDBOX/work" FIXTURES_DIR="$SANDBOX/fixtures"
	CALLS_LOG="$SANDBOX/calls.log" PROMPT_FILE="$SANDBOX/prompt.txt" OUT="$SANDBOX/out.txt"
	export HOME WORK FIXTURES_DIR CALLS_LOG PROMPT_FILE OUT SANDBOX
	mkdir -p "$HOME" "$WORK" "$FIXTURES_DIR"
	touch "$CALLS_LOG"
	link_runtime "$HOME"

	n_fixtures="$(jq -r '.fixtures // [] | length' <<< "$json")"
	for ((i = 0; i < n_fixtures; i++)); do
		idx="$(printf '%02d' $((i + 1)))"
		jq -r --argjson i "$i" '.fixtures[$i].match' <<< "$json" > "$FIXTURES_DIR/$idx.match"
		jq -r --argjson i "$i" '.fixtures[$i].response' <<< "$json" > "$FIXTURES_DIR/$idx.out"
	done

	printf '%s' "$prompt" > "$PROMPT_FILE"

	set +e
	# real tools, no stub PATH: setup only ever does local git/file scaffolding,
	# and the stub git wrapper logs every call, which would pollute $CALLS_LOG
	# with the fixture repo's own commits before the agent has even started.
	( cd "$WORK" && bash -c "$setup" ) > "$SANDBOX/setup.log" 2>&1
	setup_rc=$?
	started=$(date +%s)
	if [ $setup_rc -eq 0 ]; then
		( cd "$WORK" && PATH="$STUBS:$PATH" run_agent "$PROMPT_FILE" "$WHICH_AGENT" ) \
			> "$OUT" 2> "$SANDBOX/agent.err"
		agent_rc=$?
	else
		agent_rc=77
	fi

	assert_ok=1
	assert_log="$SANDBOX/assert.log"
	: > "$assert_log"
	if [ $setup_rc -ne 0 ]; then
		{ echo "SETUP FAILED:"; cat "$SANDBOX/setup.log"; } >> "$assert_log"
		assert_ok=0
	elif [ $agent_rc -ne 0 ]; then
		{ echo "AGENT EXITED $agent_rc:"; tail -20 "$SANDBOX/agent.err"; } >> "$assert_log"
		assert_ok=0
	else
		for p in "${tools_called[@]}"; do
			grep -qE -- "$p" "$CALLS_LOG" || {
				echo "expected tool call not found: $p" >> "$assert_log"; assert_ok=0
			}
		done
		for p in "${tools_not_called[@]}"; do
			grep -qE -- "$p" "$CALLS_LOG" && {
				echo "unexpected tool call found: $p" >> "$assert_log"; assert_ok=0
			}
		done
		for p in "${output_contains[@]}"; do
			grep -qE -- "$p" "$OUT" || {
				echo "expected output not found: $p" >> "$assert_log"; assert_ok=0
			}
		done
		for p in "${output_not_contains[@]}"; do
			grep -qE -- "$p" "$OUT" && {
				echo "unexpected output found: $p" >> "$assert_log"; assert_ok=0
			}
		done
		if [ -n "$custom" ]; then
			custom_out="$(cd "$WORK" && bash -c "$custom" 2>&1)"
			if [ $? -ne 0 ]; then
				{ echo "custom assertion failed:"; echo "$custom_out"; } >> "$assert_log"
				assert_ok=0
			fi
		fi
	fi
	set -e

	secs=$(( $(date +%s) - started ))
	if [ "$assert_ok" -eq 1 ]; then
		status=pass; pass=$((pass + 1)); echo "   PASS (${secs}s)"
	else
		status=fail; fail=$((fail + 1)); echo "   FAIL (${secs}s)"
		sed 's/^/     | /' "$assert_log" | head -15
		echo "     sandbox kept: $SANDBOX"
		jq -nc --arg n "$name" --arg s "$status" --arg a "$WHICH_AGENT" --argjson t "$secs" \
			'{scenario:$n,status:$s,agent:$a,seconds:$t,ts:(now|todate)}' >> "$RESULTS.tmp"
		continue
	fi
	rm -rf "$SANDBOX"
	jq -nc --arg n "$name" --arg s "$status" --arg a "$WHICH_AGENT" --argjson t "$secs" \
		'{scenario:$n,status:$s,agent:$a,seconds:$t,ts:(now|todate)}' >> "$RESULTS.tmp"
done
mv "$RESULTS.tmp" "$RESULTS"
echo
echo "Layer 1: $pass pass, $fail fail (results in evals/results.jsonl)"
[ "$fail" -eq 0 ]
