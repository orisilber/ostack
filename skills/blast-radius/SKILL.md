---
name: blast-radius
description: "Find what a specific change breaks outside its own diff before it ships, and substantiate the key safety fact with the strongest available evidence. Triggers \"blast radius\", \"what could this break\", or \"is this safe to ship\". Use only for impact analysis; diff review is code review and the final gate is verify-changes."
disable-model-invocation: true
---

# Blast radius

Find what a change breaks somewhere else, before it ships. Use for "blast radius of X", "what could this break", or reviewing a small diff you don't trust yet.

Companion to `how` and `why`. `how` tells you what the code does. `why` tells you why it's shaped that way. Blast radius tells you what it breaks somewhere else.

Listing the callers is not the job. The agent can grep those in a second. The job is the breakage grep won't show you.

## Don't trust your own writeup

A blast-radius writeup needs evidence, not confidence. Find the one or two facts
the conclusion depends on, then use the strongest cheap check available: run the
real code for a consequential behavior, or cite the source and failure path for
a low-risk static change. Words explain the result; they do not replace proof.

### How sure are you

For each fact the change's safety depends on, get it as far down this list as is cheap, and say where it stopped.

1. You said so. Worthless on its own.
2. You pointed at the line. A real `file:line`, or the library's own source.
3. You showed the bad case can't happen. You walked the failure step by step and it doesn't reach.
4. You ran it. A script or test that calls the real code and fails loud if you're wrong.
5. You reproduced it in the running app.

For the highest-consequence fact, aim for step 4 when a small executable check
can reach the real code. Lower-risk facts may stop at a cited source or a clear
failure trace; state that evidence level instead of presenting it as stronger
proof. Step 4 is usually one small script that imports the same library the app
ships and calls the exact function you're worried about.

## Steps

1. Read the change. The diff, the symbols it adds, changes, and deletes, and what it now does differently, including the part the diff doesn't spell out. Use `why` step 2 to pull the PR and commits.
2. Find the one fact it's safe because of. Most changes that look scary are safe because of a single fact, like "this call only drops already-dead cache entries and does nothing else". Find that fact. If it holds, most of the scary cases die at once. Spend your time here, not on a long list of maybes.
3. Look where grep stops. Read the source of the library you call, and check its pinned version and any local patch. Work out when things run: microtasks, unmount and teardown, Solid versus React. Follow what a symbol search misses: the JSON an API returns, a DB column, a wire format, another language reading the same bytes, a feature flag, code three hops downstream.
4. Be honest about each risk. Give it a real chance of happening and a real cost if it does. Keep the risks you confirmed; list the ones you checked and cleared separately. Same rules as `why`. Cite a real `file:line`, a search that finds nothing is still an answer, and never make up a caller or an API.
5. Prove the highest-consequence fact. Write a script or test that runs the
   real code when that is a cheap, meaningful check, and paste what happened.
   For a low-risk or purely static change, cite the strongest available evidence
   instead. If a material safety fact remains unproven, say so plainly.
6. Use `arena` only when comparison earns its cost. A wide change with
   genuinely different risk surfaces may benefit from several independent
   reviewers. A small or well-understood change does not need a panel by default.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, say which step you got it to, and show the proof. If you couldn't prove it, write unproven.
- **Risks.** Only the real ones. Each names how it breaks, the `file:line`, how likely and how bad, and how to check. Paste the proof for the ones that matter.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest test or repro that catches the real bug,
  including the script when an executable proof was warranted and used.

Write it through `unslop`, cite real code, and strip anything private before it goes anywhere public.

**Reply:** the writeup above, with the one safety fact either proven or marked unproven.
