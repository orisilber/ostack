---
name: clarify-requirements
description: One batched round of upfront questions per ticket, defaults included, to eliminate mid-flight stalls. Triggers "clarify requirements", "ask about ticket", "resolve ambiguity". Only at task start; mid-flight blockers go through escalate.
---

# Clarify Requirements

Ask once, completely, then shut up and build. Mid-flight questions are the
single biggest autonomy killer.

## When to run

Immediately after claiming a ticket (pick-next-task step 1 of handoff). Skip
entirely if the ticket has acceptance criteria that are objectively checkable
and no open design choice.

## 1. Hunt for ambiguity (in memory, no tools needed)

Read the ticket against the actual codebase. You are looking for:

- **Undefined behavior**: what happens on error/empty/overflow/concurrent access?
- **Unstated constraints**: perf targets, browser/runtime versions, backward compat
- **Data contracts**: new fields, nullable? defaults? migration for existing rows?
- **UX specifics**: exact copy, empty states, loading/error states
- **Done criteria**: which acceptance items are testable as written?

## 2. Ask once, max 5 questions, each with a default

```
#<iid>, 3 clarifications before I start:
1. <question>?
   Default if unanswered: <assumption I will proceed with>
2. ...
Answer all at once, or reply "defaults" to accept everything.
```

Every question must change what you'd build. If you can't state how the answer
changes the implementation, don't ask it. That's what defaults are for.

## 3. Persist the answers

Append to the originating ticket's description or decision field through the
same provider that supplied the ticket. A Jira item uses the configured Jira
client; a GitLab issue uses `glab`; another tracker uses its own write path.
Preserve the existing description and add a `## Decisions` section containing
question → decision → date. This is the record a resumed session reads instead
of re-asking. Do not send Jira decisions to GitLab merely because the eventual
code lands in GitLab.

## 4. Then never ask again

After this round, all uncertainty routes to `escalate` (which is also one
batched ask); there is no third mechanism. If nothing was ambiguous, output
exactly `No questions. Proceeding.` so the caller knows the step ran.
Once decisions are persisted, start implementing immediately, no further
confirmation round.
