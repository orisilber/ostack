# Worktree-cleanup playbook

Use this route to inspect and, when authorized, reclaim worktrees.

1. Read `git worktree list --porcelain` and resolve every candidate to an
   existing absolute path. Never operate on an unresolved variable or a
   hand-typed broad directory.
2. Classify each worktree as merged, abandoned, dirty, or active using branch,
   status, and current-use evidence.
3. Hold active and dirty worktrees. Show the exact path and reason.
4. Ask before any destructive removal that the prompt did not authorize.
5. Remove only the exact confirmed worktree path, never the repository root,
   home directory, or a path that is empty or unresolved.
6. Re-list worktrees and report what changed and what remains.

Do not delete active work, merge MRs, remove a repository root, or add a
general cleanup framework.
