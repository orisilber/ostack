#!/usr/bin/env bash
# Layer 1 — behavioral eval runner.
#   evals/run.sh                 run every scenario
#   evals/run.sh <name> [...]    run specific scenarios (dir names)
# Each scenario dir under evals/scenarios/<name>/ contains:
#   setup.sh    builds the sandbox: fixture repo in $WORK, canned responses in
#               $FIX (consumed in order by stubs), writes prompt to $PROMPT_FILE
#   assert.sh   checks results; env has OUT, CALLS_LOG, WORK, SANDBOX
# Agent CLIs see stub shims first on PATH; HOME is a sandbox so skills load
# from this checkout, never from the developer's real config.
set -uo pipefail

EVALS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$EVALS")"
STUBS="$EVALS/stubs/bin"
RESULTS="$EVALS/results.jsonl"
AGENT="${AGENT:-auto}"

resolve_agent() {
	[ "$AGENT" != "auto" ] && { echo "$AGENT"; return; }
	if command -v cursor >/dev/null 2>&1; then echo cursor
	elif command -v opencode >/dev/null 2>&1; then echo opencode
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

link_skills() {
	local home="$1" src name dst
	mkdir -p "$home/.claude/skills" "$home/.agents/skills"
	for src in "$ROOT"/skills/*/; do
		name="$(basename "$src")"
		dst="${src%/}"
		ln -sfn "$dst" "$home/.claude/skills/$name"
		ln -sfn "$dst" "$home/.agents/skills/$name"
	done
}

if [ $# -gt 0 ]; then
	SCENARIOS=()
	for n in "$@"; do SCENARIOS+=("$EVALS/scenarios/$n"); done
else
	mapfile -t SCENARIOS < <(find "$EVALS/scenarios" -mindepth 2 -maxdepth 2 -type d | sort)
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
	name="$(basename "$S")"
	echo "== $name"
	SANDBOX="$(mktemp -d /tmp/ostack-eval.XXXXXX)"
	HOME="$SANDBOX/home" WORK="$SANDBOX/work" FIX="$S/fixtures"
	CALLS_LOG="$SANDBOX/calls.log" PROMPT_FILE="$SANDBOX/prompt.txt" OUT="$SANDBOX/out.txt"
	export HOME WORK FIX CALLS_LOG PROMPT_FILE OUT SANDBOX
	mkdir -p "$HOME" "$WORK"
	touch "$CALLS_LOG"
	link_skills "$HOME"

	set +e
	( cd "$WORK" && PATH="$STUBS:$PATH" bash "$S/setup.sh" ) > "$SANDBOX/setup.log" 2>&1
	setup_rc=$?
	[ -f "$S/prompt.txt" ] && cp "$S/prompt.txt" "$PROMPT_FILE"
	started=$(date +%s)
	if [ $setup_rc -eq 0 ]; then
		( cd "$WORK" && PATH="$STUBS:$PATH" run_agent "$PROMPT_FILE" "$WHICH_AGENT" ) \
			> "$OUT" 2> "$SANDBOX/agent.err"
		agent_rc=$?
	else
		agent_rc=77
	fi
	assert_rc=1
	if [ $setup_rc -eq 0 ] && [ $agent_rc -eq 0 ]; then
		bash "$S/assert.sh" > "$SANDBOX/assert.log" 2>&1
		assert_rc=$?
	elif [ $setup_rc -ne 0 ]; then
		{ echo "SETUP FAILED:"; cat "$SANDBOX/setup.log"; } > "$SANDBOX/assert.log"
	else
		{ echo "AGENT EXITED $agent_rc:"; tail -20 "$SANDBOX/agent.err"; } > "$SANDBOX/assert.log"
	fi
	set -e

	secs=$(( $(date +%s) - started ))
	if [ $assert_rc -eq 0 ]; then
		status=pass; pass=$((pass + 1)); echo "   PASS (${secs}s)"
	else
		status=fail; fail=$((fail + 1)); echo "   FAIL (${secs}s)"
		sed 's/^/     | /' "$SANDBOX/assert.log" | head -15
		echo "     sandbox kept: $SANDBOX"
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
