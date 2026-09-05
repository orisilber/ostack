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

# ------------------------------------------------ skill metadata and references
source "$ROOT/evals/lib/py_with_yaml.sh"
PYTHON="$(resolve_python)"
"$PYTHON" "$ROOT/evals/lib/check-skill-contracts.py" "$ROOT" || err "skill contract validation failed"
"$PYTHON" "$ROOT/tests/audit-regressions.py" || err "audit regression tests failed"

# ----------------------------------------------------- CLI flag accuracy check
# Extract glab/gh/acli invocations from fenced bash blocks; join continuation
# lines; verify subcommands exist and long flags appear in `--help` output.
#
# glab/gh/acli are all cobra-style: an unknown subcommand does NOT error, it
# silently prints the nearest valid parent's help and exits 0 (verified by
# hand: `glab issue note list --help` -> help for `glab issue note`, rc=0).
# So checking the final `--help` output for an error marker never fires.
# Instead walk the command tree one word at a time and confirm each word is
# actually listed in its parent's help before descending.

# print each subcommand name listed in a --help text (works across glab's
# padded "COMMANDS" box, gh's "GENERAL/TARGETED COMMANDS", acli's
# "Available/Additional Commands:"). glab pads a blank spacer line right
# after its section header, so "blank line ends the section" is wrong; end
# only on a known non-command header (also padded, so dedent can't be used
# as an end signal either) or on the next commands-section header.
commands_in_help() {
	local insec=0 line low trimmed
	local stopwords="usage|flags|flags:|examples|arguments|learn more|aliases|global flags|inherited flags|see also|additional help topics"
	while IFS= read -r line; do
		low="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
		trimmed="$(printf '%s' "$low" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
		if [[ "$trimmed" =~ ^.*commands:?$ ]]; then
			insec=1
			continue
		fi
		if [ "$insec" -eq 1 ]; then
			if [[ "$trimmed" =~ ^($stopwords)$ ]]; then
				insec=0
				continue
			fi
			if [[ "$line" =~ ^[[:space:]]+([A-Za-z][A-Za-z0-9_-]*) ]]; then
				echo "${BASH_REMATCH[1]}"
			elif [ -n "$trimmed" ] && [[ ! "$line" =~ ^[[:space:]] ]]; then
				insec=0
			fi
		fi
	done <<< "$1"
}

# cached `$cli $level --help` output; $level is a space-joined word prefix
# ("" for root, "jira workitem" etc).
help_at() {
	local cli="$1" level="$2"
	local key="${cli}_${level// /_}"
	[ -z "$level" ] && key="${cli}_ROOT"
	local cache="$TMP/help_${key}.cache"
	if [ ! -f "$cache" ]; then
		# Bound help probes: some CLIs try network access even for --help.
		"$PYTHON" - "$cli" "$level" > "$cache" 2>&1 <<'PY' || printf '\nOSTACK_HELP_UNAVAILABLE\n' >> "$cache"
import subprocess
import sys
result = subprocess.run([sys.argv[1], *sys.argv[2].split(), "--help"],
                        capture_output=True, text=True, timeout=10)
print(result.stdout + result.stderr)
sys.exit(result.returncode)
PY
	fi
	cat "$cache"
}

check_cli() {
	local cli="$1"
	command -v "$cli" >/dev/null 2>&1 || {
		wrn "lint: $cli not installed; flag checks skipped"
		return 0
	}
	if [[ "$(help_at "$cli" '')" = *OSTACK_HELP_UNAVAILABLE* ]]; then
		wrn "lint: $cli --help unavailable; flag checks skipped"
		return 0
	fi

	# collect fenced bash content across all skills, plus inline `glab ...` code
	local joined
	joined="$(mktemp "$TMP/cli.XXXX")"
	while IFS= read -r f; do
		sed -n '/^```bash/,/^```/p' "$f" \
			| awk '{ while (sub(/\\$/, "")) { next_line=""; if (getline next_line <= 0) break; $0=$0 next_line }; print }' \
			| grep "^$cli " >> "$joined" 2>/dev/null || true
		grep -oE "\`$cli [^\`]+\`" "$f" | sed 's/^`//; s/`$//' >> "$joined" 2>/dev/null || true
	done < <(find "$SKILLS" -type f -name "*.md" -print)
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
				-*|\"*|\`*|\$*|\#*|\<*|[A-Z_]+=*|*[/?]*) break ;;
				*) subcmd="$subcmd $word" ;;
			esac
		done
		subcmd="${subcmd# }"

		# walk the tree: each word must be listed in its parent level's help.
		# capture to a variable first, don't pipe live into `grep -q`: -q
		# exits on first match and SIGPIPEs the producer, which pipefail
		# then reports as a pipeline failure regardless of grep's verdict.
		# stop after "api": it takes a raw REST endpoint/path, not a subcommand.
		local level="" bad_word="" ok=1 avail
		for word in $subcmd; do
			avail="$(commands_in_help "$(help_at "$cli" "$level")")"
			if ! grep -qxF "$word" <<< "$avail"; then
				ok=0; bad_word="$word"; break
			fi
			level="${level:+$level }$word"
			[ "$word" = "api" ] && break
		done
		if [ "$ok" -eq 0 ]; then
			err "cli: '$cli $subcmd' -- '$bad_word' is not a real subcommand (line: ${line:0:80})"
			continue
		fi

		# every long flag must appear in the leaf level's help text
		local help_cache
		help_cache="$(help_at "$cli" "$subcmd")"
		for word in $rest; do
			case "$word" in
				--[a-zA-Z][a-zA-Z-]*)
					flag="${word%%=*}"
					grep -q -- "$flag" <<< "$help_cache" || \
						err "cli: flag '$flag' not in '$cli $subcmd --help' (line: ${line:0:70})"
					;;
			esac
		done
	done < "$joined.j"
}
if [ "${OSTACK_LINT_SKIP_CLI_CHECKS:-0}" != 1 ]; then
	check_cli glab
	check_cli gh
	check_cli acli
fi

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

# verify-changes' retry loop must match escalate's soft-stop default, numerically
escalate_n="$(grep -oE 'default N=[0-9]+' "$SKILLS/escalate/SKILL.md" | grep -oE '[0-9]+' | head -1)"
verify_n="$(grep -oE 'Loop max [0-9]+ attempts' "$SKILLS/verify-changes/SKILL.md" | grep -oE '[0-9]+' | head -1)"
if [ -z "${escalate_n:-}" ] || [ -z "${verify_n:-}" ]; then
	err "contract: could not find escalate's default N or verify-changes' loop max to compare"
elif [ "$escalate_n" != "$verify_n" ]; then
	err "contract: verify-changes loop max ($verify_n) != escalate default N ($escalate_n)"
fi

# Project-local verification is one layered contract. The generator writes the
# repository knowledge, verify-changes selects it, and e2e-verify supplies the
# browser mechanics. Keep all supported local skill roots discoverable.
for skill in create-verification-skill maintain-verification-skill verify-changes e2e-verify; do
	for root in .agents/skills .cursor/skills .claude/skills; do
		grep -qF "$root" "$SKILLS/$skill/SKILL.md" || \
			err "contract: $skill does not discover project-local root $root"
	done
done
grep -qF 'maintain-verification-skill' "$SKILLS/verify-changes/SKILL.md" || \
	err "contract: verify-changes must report project-local verifier drift"
grep -qF 'unmapped affected' "$SKILLS/verify-changes/SKILL.md" || \
	err "contract: verify-changes must reject unmapped affected behavior"
grep -qF 'project-local verifier' "$SKILLS/e2e-verify/SKILL.md" || \
	err "contract: e2e-verify must prefer repository-specific instructions"
grep -qF 'disable-model-invocation: true' "$SKILLS/create-verification-skill/SKILL.md" || \
	err "contract: create-verification-skill must remain explicitly invoked"
grep -qF 'disable-model-invocation: true' "$SKILLS/maintain-verification-skill/SKILL.md" || \
	err "contract: maintain-verification-skill must remain explicitly invoked"
bash "$ROOT/tests/install-upgrade.sh" || err "installer upgrade fixtures failed"

# ---------------------------------------------------- ostack-mode contracts
bash "$SKILLS/ostack-mode/scripts/validate.sh" --root "$ROOT" || err "ostack-mode validator failed"
bash "$ROOT/evals/fixtures/ostack-mode-validator/run.sh" || err "ostack-mode validator fixtures failed"

# A route scenario must prove an observable effect or preserved invariant. An
# output-only assertion can pass when an agent merely repeats the playbook.
while IFS= read -r scenario; do
	if ! awk '
		/^  custom:[[:space:]]*\|[[:space:]]*$/ {
			getline
			if ($0 == "    set -eu") found = 1
		}
		END { exit found ? 0 : 1 }
	' "$scenario"; then
		err "ostack-mode scenario has no fail-fast executable evidence: ${scenario#$ROOT/}"
	fi
done < <(find "$ROOT/evals/scenarios/ostack-mode" -type f -name '*.yaml' -print | sort)

# ------------------------------------------------------------------- summary
echo
if [ "$fail" -gt 0 ]; then
	printf '%s\n' "${FAILURES[@]}"
	echo
	echo "LINT: FAIL ($fail errors, $warn warnings)"
	exit 1
fi
echo "LINT: PASS ($warn warnings)"
