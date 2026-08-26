# Confluence (long-form documents)

## What this source contains

- PRDs, specs, RFCs, design docs, ADRs
- Postmortems and incident reviews with action items
- Team and onboarding pages, runbooks
- Meeting notes, quarterly planning pages
- Page version history and inline comments, which show where a decision changed

Best at **long-form design rationale**: the problem statement, the alternatives
considered, and the approaches explicitly rejected.

## Access, in order of preference

1. **Atlassian MCP**, if connected. The only path with real search.
2. **Confluence REST with CQL**, when you have an API token:

```bash
curl -sS -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
  --get "https://$SITE.atlassian.net/wiki/rest/api/search" \
  --data-urlencode 'cql=text ~ "rate limit" AND type = page AND lastModified > "2026-01-01"' \
  --data-urlencode 'limit=20' | jq -r '.results[] | "\(.content.id)\t\(.title)"'
```

3. **`acli confluence page view --id <id>`** once you have an ID or URL. It reads
   a page but cannot search:

```bash
acli confluence page view --id 123456789 --body-format view --include-labels --include-direct-children
```

Jira tickets routinely link the spec, so the cheapest route is often Jira first,
then read the linked page by ID. If you have no MCP and no token, say the category
was searchable only through links found elsewhere. That's a gap, not a skip.

## How to search it

- Search the feature name, the symbol, and the error string. Docs use product
  language, so also search the user-facing name, not just the identifier.
- Bracket the ship date: `lastModified` and `created` windows around the MR merge.
- Follow the page tree: `--include-direct-children` finds the sibling ADR the
  search missed.
- Read version history when a doc contradicts the code. The doc may describe a
  plan that changed; the diff of two versions is where the "why not" lives.

## What to bring back

- The problem statement in the author's words, with the page title and URL
- "Alternatives considered" and "rejected because" sections, verbatim
- Postmortem action items that map onto the target code
- The decision's date relative to the code's ship date, so you can say whether the
  doc led the code or documented it after the fact

## Failure modes

- **Confusing a proposal with a decision.** A page in draft, or one nobody
  approved, is a proposal. Say which it is.
- **Stale docs read as current truth.** The code is the current truth; the doc is
  history. When they disagree, report the disagreement rather than picking.
- **Deriving intent from a template.** Empty template sections are not evidence.
