# Large feature playbook

Use this route when new behavior spans multiple independently verifiable
implementation scopes or cannot reasonably finish in one agent session.

1. State the complete done predicate and reuse current grounding. Route through
   `how` for material gaps in affected behavior or ownership.
2. When a consequential type, interface, or ownership decision remains unresolved,
   route through `architect` in `design-only` mode. A comparison it actually ran
   satisfies `arena` for that decision. Otherwise, route through `arena` when at
   least two viable approaches exist and choosing the wrong one would cause
   substantial rework. For this pre-decomposition arena, the candidate artifact
   is the implementation design only: pass the complete done predicate, require
   structurally distinct approaches, and forbid production-code changes or
   feature implementation. Arena returns the synthesized design decision that
   step 3 decomposes. Record why an arena was not needed when the target follows
   an established pattern.
3. Decompose the work into atomic tasks with acceptance checks, explicit file
   ownership, and a dependency DAG. Put shared foundations first. Acceptance
   checks use existing repository checks or temporary commands against real
   behavior, not new permanent feature tests. Keep the decomposition local by
   default. If the source is a real Jira epic and the user explicitly
   authorizes Jira work, route through `decompose-epic` instead.
4. After each shared foundation passes its check, identify the ready tasks. If
   at least two ready tasks have disjoint write scopes and independent done
   predicates, route through `swarm`. Give each worker an isolated worktree or
   output path and its own verification contract. Workers must not add or edit
   feature-specific tests. Otherwise, implement the tasks in dependency order
   and record why parallel work was unsafe or too small.
5. Integrate worker results one at a time. Resolve shared wiring in the parent
   task, then run the acceptance checks for every task.
6. Exercise the integrated feature through its real interface and prove the
   complete done predicate without new feature-specific test code. Return to
   implementation when any behavior fails.
7. Route through `feature-retention-tests` once from the parent after the
   integrated feature is accepted. Add the minimum durable coverage, if any.
8. Run the focused retention tests and then route through `verify-changes` over
   the integrated change. Report the real behavior proof, retained contracts,
   exact checks, and result.

Do not let workers share a writable file, branch, or external object. Do not
read or write Jira unless the user supplied a real epic and authorized Jira
work. MR creation and reviewer interaction remain outcome tails.
