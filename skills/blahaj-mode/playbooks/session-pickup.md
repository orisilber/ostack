# Session-pickup playbook

Use this route when the user asks to resume work or reconstruct where a prior
run stopped.

1. State the selected outcome and inspect the current branch and worktree.
2. If the user identifies one specific prior chat or session, open that
   transcript directly and reconstruct where it stopped; do not route through
   `recall`. Otherwise route through `recall` for broader cross-chat context
   reconstruction.
3. Reconcile the reconstructed context, whether from the direct transcript or
   the Recall brief, with current files, git status, and any durable decision
   log.
4. When the user says to continue a specific authorized task, restore its
   original implemented route and outcome from trusted history, applying any
   newer constraints. Follow [the continuation contract](../references/continuation.md)
   to reconcile saved evidence. The pickup route's outcomes govern context
   reconstruction; they do not lower the resumed task's existing authority.
5. Copy only the resulting next actions into the task list; do not repeat the
   reconstruction procedure or invent completed work.
6. Continue from the first unfinished atomic boundary and verify before
   claiming progress.

Asking only for a recap stays read-only. A checkpoint alone cannot authorize
resuming external operations, and an explicit user stop requires a new resume
request before further work.
