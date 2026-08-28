# Multi-phase plan playbook

Use this route for work that spans phases, owners, or independently verifiable
changes.

1. State the phase boundaries, done predicate, and the files each phase owns.
2. Put shared foundations first, then list disjoint work in parallel lanes.
3. Give every phase an acceptance check and an evidence artifact.
4. If the source is a real Jira epic and the user authorizes Jira work, invoke
   `decompose-epic` for atomic child tickets. If it is a generic request or a
   local todo list, do not read, search, or write Jira.
5. Record dependencies as a DAG and identify the integration and final-gate
   phases.

The deliverable is a reviewable local plan. It does not create tickets or
external links unless the user explicitly supplied a Jira epic and asked for
that operation.
