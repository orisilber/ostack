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
4. Copy only the resulting next actions into the task list; do not repeat the
   reconstruction procedure or invent completed work.
5. Continue from the first unfinished atomic boundary and verify before
   claiming progress.

Pickup is read-only until the user requests a change. It does not open an MR or
resume a paused external operation implicitly.
