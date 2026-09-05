#!/usr/bin/env bash
# Keep the complete log while returning the check's status, including failures.
set -uo pipefail
if [ "$#" -lt 2 ]; then
	printf 'usage: bash run-check.sh LOG COMMAND [ARG ...]\n' >&2
	exit 2
fi
check_log="$1"
shift
if ! touch "$check_log"; then exit 2; fi
"$@" >"$check_log" 2>&1
check_status=$?
tail -n 30 "$check_log"
printf 'Check exit: %s; full log: %s\n' "$check_status" "$check_log"
exit "$check_status"
