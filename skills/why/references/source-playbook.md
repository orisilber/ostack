# Source playbooks

The why skill may spawn one investigator per relevant evidence category, each
reading a single source-specific playbook below. Start with directly linked
history and add categories when the question needs them; a narrow question can
use one investigator across several directly relevant sources. The playbooks
are concrete examples for common MCPs; adapt them for a different MCP in the
same category.

| Category | Playbook | Example MCP it documents |
|---|---|---|
| Source control history | [`code-archaeology.md`](./sources/code-archaeology.md) | git, `glab`, `gh` |
| Issue / ticket tracker | [`jira.md`](./sources/jira.md) | Jira via `acli` (adapt for Linear, GitHub Issues, Plane, Shortcut) |
| Long-form documents | [`confluence.md`](./sources/confluence.md) | Confluence via MCP / CQL / `acli` (adapt for Notion, Google Docs, Coda) |
| Real-time team chat | [`slack.md`](./sources/slack.md) | Slack (adapt for Discord, Microsoft Teams, Mattermost) |
| Infrastructure observability | [`datadog.md`](./sources/datadog.md) | Datadog (adapt for New Relic, Honeycomb, Grafana, Splunk) |
| Error / exception tracking | [`sentry.md`](./sources/sentry.md) | Sentry (adapt for Rollbar, Bugsnag, Airbrake) |
| Product analytics warehouse | [`databricks.md`](./sources/databricks.md) | Databricks SQL (adapt for Snowflake, BigQuery, Firebolt, ClickHouse, Mixpanel, dbt) |

Cross-cutting:

- [`incident-postmortem.md`](./sources/incident-postmortem.md). Add this if the target code looks defensive (null checks, retry, timeout, rate limit, feature flag, egress guard, OOM handler).
