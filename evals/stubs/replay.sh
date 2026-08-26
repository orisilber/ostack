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

# Pattern-matched responses: numbered pairs "<NN>.match" (one ERE per file,
# matched against the full argument string) and "<NN>.out" (the canned
# response). The pattern lives in its own file rather than the filename so
# it can contain anything (slashes, quotes) without filesystem escaping.
# Lowest NN that matches wins; no match -> {}
shopt -s nullglob
best=""
for m in "$FIX"/[0-9]*.match; do
	re="$(head -n1 "$m")"
	if [[ "$args" =~ ^.*${re}.*$ ]]; then
		best="${m%.match}"
		break
	fi
done

if [ -n "$best" ]; then
	cat "$best.out" 2>/dev/null
	[ -f "$best.err" ] && cat "$best.err" >&2
	exit "$( [ -f "$best.code" ] && cat "$best.code" || echo 0 )"
fi
echo '{}'
exit 0
