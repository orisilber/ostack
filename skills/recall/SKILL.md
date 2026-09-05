---
name: recall
description: Rebuild your working context on a topic from your own transcripts plus the shared record (MRs, tickets, incidents, errors) and hand back a tight current-state brief. Triggers "catch me up", "what was I working on", "where did I leave off", before resuming work. Use only to reconstruct context; durable preferences and facts are memory-recall (agent-memory).
disable-model-invocation: true
---

# Recall

When the user asks to reconstruct prior work, rebuild the relevant working
context and hand back a tight capsule of where things stand now and what to do
next. Use for "recall my work on X", "catch me up", "what have I been working
on", or "where did I leave off". Do not run this workflow before every task.

Keep it tight and on-topic. Read only what the in-scope threads need, then stop.
For a large transcript corpus, bounded parallel search can save time; for a
small corpus, search directly. The main thread keeps only the findings and final
brief.

Your context lives in two records. Your own chat history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the **why** skill searches, across source control, the issue tracker, chat and issue channels, long-form docs, and error tracking. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your transcripts alone.

Transcripts are per-workspace JSONL, one chat message per line. Where they live depends on the host:

- **Cursor**: `~/.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>.jsonl`, where `<slug>` is the workspace path with the leading slash dropped and each "/" turned into "-" (so `/Users/you/proj` becomes `Users-you-proj`).
- **Claude Code**: `~/.claude/projects/<slug>/<uuid>.jsonl`, where `<slug>` is the full path with every "/" and "." turned into "-", leading dash kept (so `/Users/you/dev/proj` becomes `-Users-you-dev-proj`). A git worktree is its own slug, so a task worked in a worktree is not in the main checkout's directory. Check both.
- **Codex**: use the host's native task/thread history or read-thread facility
  for the active workspace first. If it exposes no history, continue with live
  state and say so; do not pretend the Cursor or Claude paths apply.

Neither directory exists → say so and work from live state alone. Don't invent a history.

1. Classify, then route. Resuming one specific prior chat is a session pickup, not this: open that transcript and continue from it. A durable preference or procedure is `memory-capture` (from agent-memory, not this repo). A human-readable summary of your work is a different task. Recall loads working context across recent chats before you act. If the user already gave you a full state capsule (paths, branch, the change), use it and skip the mining.
2. Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, and the workspace (default the active one; never read another project's transcripts without being asked). State the scope back. Never quietly turn "all" into "recent N".
3. Search your chat history. For a large corpus, spawn bounded parallel
   workers on a fast model, each taking a slice. For one or two chats, search
   directly. In either case, order candidates by real modification time (`ls
   -t`) rather than UUID name, search the topic before reading a matching chat,
   read only relevant regions, and skip the current chat plus obvious noise
   (subagent, eval, and test chats). Return the same schema, one block per chat:
   topic, the user's goal, decisions, open threads, struggles and corrections,
   and artifacts (PRs, tickets, branches), each citing the chat UUID. Keep raw
   transcripts out of the main thread.
4. Sweep the shared record when the named target or the first-pass evidence
   leaves an important gap. Hand it to the **why** skill's source investigators,
   steering the question from "why was this built this way" to "what's the
   current state, what's been tried and didn't hold, and what are users still
   reporting". Reuse its per-source playbooks, run independent searches in
   parallel when useful, and record scoped null results without treating them as
   proof of absence. Skip this step for pure activity recall with no named target
   ("what did I do this week"), where live state and your own history are enough.
5. Verify against live state. A transcript or a stale ticket is history, not current truth, so take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), read the full transcript, not just a trimmed local copy.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep reporting and any fix that shipped and was reverted, so the next attempt starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Write the brief through the **unslop** skill, cite chat findings by UUID and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above.
