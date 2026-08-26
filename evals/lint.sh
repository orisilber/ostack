#!/usr/bin/env bash
# Layer 0 — static lint for ostack skills. No LLM calls, runs in seconds.
# Checks: frontmatter, local file refs, cross-skill refs, CLI flag accuracy
# (against real --help output), style rules, and hand-written contract rules.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS="$ROOT/skills"
PATH="/opt/homebrew/bin:$PATH"   # glab, gh live here on macOS
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
warn=0
declare -a FAILURES=()

err() { fail=$((fail + 1)); FAILURES+=("FAIL $1"); }
wrn() { warn=$((warn + 1)); echo "WARN $1" >&2; }

# ---------------------------------------------------------------- frontmatter
for dir in "$SKILLS"/*/; do
	name="$(basename "$dir")"
	f="$dir/SKILL.md"
	[ -f "$f" ] || { err "$name: SKILL.md missing"; continue; }

	grep -q '^name:' "$f" || err "$name: no name in frontmatter"
	fm_name="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '[:space:]')"
	[ "$fm_name" = "$name" ] || err "$name: frontmatter name '$fm_name' != folder"

	# description length measured ONLY within the frontmatter block
	desc_len="$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} /^[a-z-]+:/ && !/^description:/ && seen{exit} /^description:/{seen=1} seen{print}' "$f" | wc -c | tr -d ' ')"
	grep -q '^description:' "$f" || err "$name: no description in frontmatter"
	if [ "${desc_len:-0}" -gt 600 ]; then
		err "$name: description ${desc_len}b > 600b (index bloat)"
	fi

	# local file references must exist
	while IFS= read -r ref; do
		[ -e "$dir$ref" ] || err "$name: references missing file $ref"
	done < <(grep -oE '(references/[A-Za-z0-9._/-]+\.(md|tsv|json|yaml|yml))' "$f" | sort -u)
done

# ------------------------------------------------- cross-skill references valid
all_names="$(ls "$SKILLS")"
for dir in "$SKILLS"/*/; do
	name="$(basename "$dir")"
	for other in $all_names; do
		[ "$other" = "$name" ] && continue
		if grep -qE "\`$other\`" "$dir/SKILL.md" && [ ! -d "$SKILLS/$other" ]; then
			err "$name: mentions skill '$other' which does not exist"
		fi
	done
done

# ----------------------------------------------------- CLI flag accuracy check
# Extract glab/gh invocations from fenced bash blocks; join continuation lines;
# verify subcommands exist and long flags appear in `--help` output.
check_cli() {
	local cli="$1"
	command -v "$cli" >/dev/null 2>&1 || {
		wrn "lint: $cli not installed; flag checks skipped"
		return 0
	}

	# collect fenced bash content across all skills, plus inline `glab ...` code
	local joined
	joined="$(mktemp "$TMP/cli.XXXX")"
	for f in "$SKILLS"/*/"SKILL.md"; do
		sed -n '/^```bash/,/^```/p' "$f" \
			| grep "^$cli " >> "$joined" 2>/dev/null || true
		grep -oE "\`$cli [^\`]+\`" "$f" | sed 's/^`//; s/`$//' >> "$joined" 2>/dev/null || true
	done
	# join continuation lines, then split compound lines at every cli invocation
	awk '{ while (sub(/\\$/,"")) { buf=buf $0; getline; buf=buf $0 }; if (buf!="") { print buf; buf="" } else print }' \
		"$joined" > "$joined.j" || cp "$joined" "$joined.j"
	awk -v c="$cli" '{
		n = split($0, parts, c " ")
		for (i = 2; i <= n; i++) print c " " parts[i]
	}' "$joined.j" > "$joined.s"
	mv "$joined.s" "$joined.j"

	while IFS= read -r line; do
		case "$line" in *lint-ignore*) continue ;; esac
		# subcommand path: leading non-flag words after the cli token
		local rest subcmd=""
		rest="${line#$cli }"
		for word in $rest; do
			case "$word" in
				-*|\"*|\`*|\$*|[A-Z_]+=*|*[/?]*) break ;;
				*) subcmd="$subcmd $word" ;;
			esac
		done
		subcmd="${subcmd# }"

		local help_cache="$TMP/${cli}_${subcmd// /_}.help"
		if [ ! -f "$help_cache" ]; then
			# shellcheck disable=SC2086
			if "$cli" $subcmd --help > "$help_cache" 2>&1; then :;
			else echo "__NO_SUCH__" > "$help_cache"; fi
		fi
		if grep -q "__NO_SUCH__\|Unknown command\|unknown command" "$help_cache"; then
			err "cli: '$cli $subcmd' is not a real command (line: ${line:0:80})"
			continue
		fi
		# every long flag must appear in help text
		for word in $rest; do
			case "$word" in
				--[a-zA-Z][a-zA-Z-]*)
					flag="${word%%=*}"
					grep -q -- "$flag" "$help_cache" || \
						err "cli: flag '$flag' not in '$cli $subcmd --help' (line: ${line:0:70})"
					;;
			esac
		done
	done < "$joined.j"
}
check_cli glab
check_cli gh

# ---------------------------------------------------------------------- style
EMDASH="$(printf '\xe2\x80\x94')"
while IFS= read -r -d '' f; do
	rel="${f#$ROOT/}"
	LC_ALL=C grep -q "$EMDASH" "$f" && err "style: em dash in $rel"
	grep -nE "[[:blank:]]+$" "$f" >/dev/null && err "style: trailing whitespace in $rel"
	[ -n "$(tail -c 1 "$f")" ] && err "style: no trailing newline in $rel"
done < <(find "$SKILLS" "$ROOT/README.md" -name "*.md" -print0 2>/dev/null)

# ---------------------------------------------------- hand-written contracts
# Add project-specific invariants here as skills evolve.
grep -q 'last_seen_note' "$SKILLS/babysit-gitlab-mr/SKILL.md" || \
	err "contract: babysit cursor field renamed but doc still says otherwise"
grep -qE 'declared budget|budget.*declared' "$SKILLS/escalate/SKILL.md" || \
	err "contract: escalate must allow calling skills to declare their own budget"

# ------------------------------------------------------------------- summary
echo
if [ "$fail" -gt 0 ]; then
	printf '%s\n' "${FAILURES[@]}"
	echo
	echo "LINT: FAIL ($fail errors, $warn warnings)"
	exit 1
fi
echo "LINT: PASS ($warn warnings)"
