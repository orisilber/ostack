# Large feature playbook

Use this route when new behavior spans multiple independently verifiable
implementation scopes or cannot reasonably finish in one agent session.

1. State the complete done predicate and run `how` over every affected
   subsystem.
2. Run `architect` in `design-only` mode when a public type, function, class, or
   ownership boundary crosses modules. Its design comparison satisfies `arena`
   for that decision and returns control before implementation ownership is
   assigned.
   Otherwise, run `arena` when at least two viable approaches exist and choosing
   the wrong one would cause substantial rework. Record why an arena was not
   needed when the target follows an established pattern.
3. Decompose the work into atomic tasks with acceptance checks, explicit file
   ownership, and a dependency DAG. Put shared foundations first. Keep the
   decomposition local by default. If the source is a real Jira epic and the
   user explicitly authorizes Jira work, invoke `decompose-epic` instead.
4. After each shared foundation passes its check, identify the ready tasks. If
   at least two ready tasks have disjoint write scopes and independent done
   predicates, invoke `swarm`. Give each worker an isolated worktree or output
   path and its own verification contract. Otherwise, implement the tasks in
   dependency order and record why parallel work was unsafe or too small.
5. Integrate worker results one at a time. Resolve shared wiring in the parent
   task, then run the acceptance checks for every task.
6. Run `verify-changes` over the integrated change and report the exact checks
   and result.

Do not let workers share a writable file, branch, or external object. Do not
read or write Jira unless the user supplied a real epic and authorized Jira
work. MR creation and reviewer interaction remain outcome tails.
