#!/usr/bin/env bash
# Replay stub shared by glab/acli shims. Sources common logic, then dispatches.
# Usage: this file is sourced; caller sets CMD=glab|acli and its own logging.
set -uo pipefail
LOG="${CALLS_LOG:?CALLS_LOG not set}"
FIX="${FIXTURES_DIR:?FIXTURES_DIR not set}"

args="*"
if [ $# -gt 0 ]; then
	args="$*"
fi
echo "--- $CMD $args" >> "$LOG"

# Pattern-matched responses: files named "<NN>__<ERE>.out". The ERE is matched
# against the full argument string. Lowest NN that matches wins; no match -> {}
shopt -s nullglob
best=""
for f in "$FIX"/[0-9]*__*.out; do
	base="$(basename "$f")"
	re="${base#*__}"      # <ERE>.out
	re="${re%.out}"
	if [[ "$args" =~ ^.*${re}.*$ ]]; then
		best="$f"
		break
	fi
done

if [ -n "$best" ]; then
	cat "$best"
	err_f="${best%.out}.err"
	[ -f "$err_f" ] && cat "$err_f" >&2
	code_f="${best%.out}.code"
	exit "$( [ -f "$code_f" ] && cat "$code_f" || echo 0 )"
fi
echo '{}'
exit 0
