#!/usr/bin/env bash
# Print one combined JSON array only after every page has been fetched.
set -euo pipefail
if [ "$#" -ne 1 ]; then
	printf 'usage: bash list-pages.sh API_ENDPOINT_WITHOUT_QUERY\n' >&2
	exit 2
fi
case "$1" in *\?*) printf 'pass an endpoint without query parameters\n' >&2; exit 2 ;; esac
pages_file="$(mktemp)"
trap 'rm -f "$pages_file"' EXIT
page=1
while [ "$page" -le 100 ]; do
	response="$(glab api "$1?per_page=100&page=$page")"
	count="$(jq -er 'if type == "array" then length else error("expected array") end' <<< "$response")"
	printf '%s\n' "$response" >> "$pages_file"
	if [ "$count" -lt 100 ]; then
		jq -s 'add' "$pages_file"
		exit 0
	fi
	page=$((page + 1))
done
printf 'pagination limit reached; inventory is incomplete\n' >&2
exit 1
