#!/usr/bin/env bash
# Builds a valid project-local verifier from the shipped feature-map example,
# then breaks it one way at a time and requires lint-verifier.py to fail.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$ROOT/skills/verification-skill/scripts/lint-verifier.py"
EXAMPLE="$ROOT/skills/verification-skill/references/feature-map-example"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

build() {
	local repo="$TMP/$1"
	mkdir -p "$repo/src/routes" "$repo/src/admin" "$repo/.agents/skills/verify-notes/features"
	echo '{"scripts":{"test":"vitest","dev":"vite"}}' > "$repo/package.json"
	touch "$repo/src/routes/notes.ts" "$repo/src/routes/search.ts" "$repo/src/admin/index.ts"
	cp "$EXAMPLE"/*.md "$repo/.agents/skills/verify-notes/features/"
	cat > "$repo/.agents/skills/verify-notes/SKILL.md" <<'MD'
---
name: verify-notes
description: Verify Notes through its browser UI and CLI.
---

# Verify Notes

Last verified: never

## Source anchors

| Path | Defines | Features |
|---|---|---|
| `package.json` | checks, launch | |
| `src/routes/notes.ts` | routes | create-note |
| `src/routes/search.ts` | routes | search |
| `src/admin/` | routes | unmapped |

## Repository checks

- `npm test` in the repository root, declared in `package.json`.

## Launch

`npm run dev`; ready when `http://127.0.0.1:4173` answers.

## Doctor

`control-notes doctor`

## Drive

Follow the recipe in `features/`.

## Evidence

Artifacts go under `artifacts/<feature>/`.

## Cleanup

Stop the dev server this run started.
MD
	echo "$repo"
}

expect() {
	local want="$1" name="$2" dir="$3" out
	if out="$(python3 "$LINT" "$dir/.agents/skills/verify-notes" "$dir" 2>&1)"; then got=pass; else got=fail; fi
	if [ "$got" = "$want" ]; then
		echo "ok   $name"
	else
		echo "FAIL $name: expected $want, got $got"
		echo "$out" | sed 's/^/     /'
		failures=$((failures + 1))
	fi
}

skill() { echo "$1/.agents/skills/verify-notes/SKILL.md"; }
edit() { python3 - "$1" "$2" "$3" <<'PY'
import sys
path, old, new = sys.argv[1:]
text = open(path).read()
assert old in text, old
open(path, "w").write(text.replace(old, new))
PY
}

expect pass "valid verifier" "$(build valid)"

d="$(build bare-links)"; sed -i.bak 's|(\./|(|g' "$d/.agents/skills/verify-notes/features/README.md"
expect pass "index links without ./" "$d"

d="$(build no-frontmatter)"; edit "$(skill "$d")" "---
name: verify-notes" "name: verify-notes"
expect fail "name outside frontmatter" "$d"

d="$(build escape)"; edit "$(skill "$d")" "| \`package.json\` |" "| \`../outside.txt\` |"; touch "$TMP/outside.txt"
expect fail "anchor outside repository" "$d"

d="$(build marker)"; edit "$(skill "$d")" "Stop the dev server" "{{teardown}}"
expect fail "template marker" "$d"

d="$(build section)"; edit "$(skill "$d")" "## Doctor" "## Health"
expect fail "missing section" "$d"

d="$(build last-verified)"; edit "$(skill "$d")" "Last verified: never" "Last verified: soon"
expect fail "bad Last verified" "$d"

d="$(build path)"; rm "$d/src/routes/search.ts"
expect fail "anchor path missing" "$d"

d="$(build unknown)"; edit "$(skill "$d")" "| search |" "| searching |"
expect fail "anchor names unknown feature" "$d"

d="$(build unanchored)"; edit "$(skill "$d")" "| \`src/routes/search.ts\` | routes | search |" ""
expect fail "feature with no anchor" "$d"

d="$(build feature-h2)"; edit "$d/.agents/skills/verify-notes/features/search.md" "## Gotchas" "## Notes"
expect fail "feature file sections" "$d"

d="$(build status)"; edit "$d/.agents/skills/verify-notes/features/README.md" " Status: \`verified\`." ""
expect fail "index entry without status" "$d"

d="$(build index)"; edit "$d/.agents/skills/verify-notes/features/README.md" "(./search.md)" "(./find.md)"
expect fail "index link" "$d"

[ "$failures" -eq 0 ] && echo "VERIFIER LINT FIXTURES: PASS" || { echo "VERIFIER LINT FIXTURES: FAIL"; exit 1; }
