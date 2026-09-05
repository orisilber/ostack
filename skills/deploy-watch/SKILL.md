---
name: deploy-watch
description: Watch deployment health against an agreed baseline and trigger policy. Set up a missing contract when requested, alert on meaningful changes, and roll back only with explicit authority.
---

# Deploy watch

Use the requested environment, duration, and existing trigger policy. Check
relevant repository/service instructions or `deploy-watch.json` for a contract.
Reuse supplied values and previous authorization. A watch request alone does
not authorize rollback, issue creation, or messages to third parties.

For first-time setup or missing consequential values, read
[references/setup.md](references/setup.md). Discover sources and prepare the
contract before asking only for what is missing. An explicit setup-and-watch
request continues into the watch as soon as the contract is complete.

## Discover and validate the sources

Resolve tools from the contract and current host. Check named sources first,
then relevant repository/CI declarations and available connectors for gaps.
Do not search every integration on the host. For each metric, confirm the exact
query, environment, units, and deployment SHA; a tool name alone is insufficient.

Use the existing CLI/API for shell-callable sources. For MCP-only sources, use
host tools and its scheduler or interruptible waits. A model-callable MCP is not
a command a shell loop can execute. If a required source cannot be read, report
that gap rather than declaring the deployment healthy.

## Establish baseline and watch

Read the agreed baseline window before the deployment, then evaluate the
declared metrics during the agreed watch window. Use bounded polls or the
host's scheduler, respecting user interrupts and the original duration.
Missing data is not a healthy sample.

Stay quiet while the state is unchanged and non-actionable. Report a trigger,
an important source failure, a required decision, or completion. Two consecutive
unreadable samples require an alert to the user, not an assumed healthy value.

## Act within the contract

- If a rollback trigger fires and that exact rollback operation is authorized,
  run the recorded command and verify the rollback deployment. Do not improvise
  a different rollback method.
- If rollback is not authorized, present evidence and the missing decision.
  Continue independent observation while awaiting it.
- For an alert, capture a concise log/screenshot and notify the user. Create an
  issue or send a third-party message only when that channel is authorized.

## Stop and report

Stop when the requested window ends, the user stops it, or a contractual end
condition is met. An extension or a new rollback watch needs an already agreed
policy or a new duration decision; do not silently double the time.

Report the deployment SHA, observed window, relevant evidence, actions taken,
and unresolved gaps. A setup-only task ends with its prepared contract.
