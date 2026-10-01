---
name: recall
description: Rebuild working context on a topic from your own chat history plus the shared record (MRs, tickets, errors) and hand back a tight current-state brief. Triggers "catch me up", "what was I working on", "where did I leave off", "recall my work on X". Not for resuming one specific chat or for durable preferences.
---

# Recall

Rebuild the working context for prior work and hand back a short brief of where
things stand and what to do next. Do not run it before every task.

If the user names one specific prior chat, open that chat and continue from it
instead. If the user already gave a full state capsule (paths, branch, the
change), use it and skip the search.

## Steps

1. **Lock the scope.** Pin the window (default the last 7 days), the topic if
   named, and the workspace (default the active one). State the scope back in
   one line. Never read another project's history without being asked, and
   never quietly narrow "all" to "recent".
2. **Search your chat history.** Use the host's native conversation search
   when it has one (Cursor's `SearchConversations`, Codex thread history).
   Otherwise grep the transcript files:

   - **Cursor**: `~/.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>.jsonl`
     or `.../agent-transcripts/<uuid>.jsonl`. The slug is the workspace path
     with the leading `/` dropped and each `/` and `.` turned into `-`.
   - **Claude Code**: `~/.claude/projects/<slug>/<uuid>.jsonl`. The slug is
     the full path with each `/` and `.` turned into `-`, leading dash kept. A
     git worktree has its own slug; check it too.

   Order candidates by modification time, not by name. Grep for the topic
   before reading a chat, read only the matching regions, and skip the current
   chat and subagent or eval chats. For each relevant chat, note the goal,
   decisions, open threads, corrections, and artifacts (MRs, tickets,
   branches), cited by chat ID. If no history is available, say so and work
   from live state alone.
3. **Check the shared record.** When the topic is named, run bounded searches
   for it in the systems the repository uses: merge requests and their review
   threads (`glab mr list --search`, or `gh pr list --search` for GitHub), the
   issue tracker, and the error tracker when one is connected. Look for
   reverted fixes and symptoms users still report. Record a search that found
   nothing as a scoped null, not as proof of absence. Skip this step for pure
   activity recall ("what did I do this week").
4. **Verify against live state.** Transcripts and tickets are history. Check
   each surfaced branch, MR, and ticket with `git`, `glab`, or `gh` before
   giving it a status.
5. **Write the brief** to the contract below.

## Output contract

- **Capsule.** At most 5 bullets: what this work is and where it stands.
- **Threads.** One line each, prefixed with exactly one status tag:
  `[merged !N]`, `[open MR !N]`, `[in flight <branch>]`,
  `[verified, uncommitted]`, `[reverted !N]`, or `[planned, not started]`.
  Use `#N` instead of `!N` for GitHub. Every thread gets a tag.
- **Problems.** At most 5 recurring ones, including symptoms users keep
  reporting and fixes that shipped and were reverted.
- **Next move.** The single most useful next action.

Stay on the named topic; an adjacent ticket appears only if it blocks this one.
Cite chat findings by chat ID and shared-record findings by source (MR, ticket,
error issue). Cut detail before cutting threads.
