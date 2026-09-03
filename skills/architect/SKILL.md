---
name: architect
description: Settle types, signatures, and module boundaries before writing code, optionally returning the design to a caller or implementing against it. Triggers "architect this", "design this first", or non-trivial work where jumping to code would lock in the wrong shape. Use only when real code follows; a plan nobody implements is not this skill.
disable-model-invocation: true
---

# Architect

Design before implementing. Sketch types, function signatures, class shapes, and module boundaries with `not implemented` bodies and pseudocode. Synthesize across multiple model perspectives. In full mode, fill in code against the chosen sketch and scrap it when implementation proves it wrong. In design-only mode, return the synthesized design to the caller that owns implementation.

## Modes

Architect has two modes:

- **Full** is the default for direct `/architect` usage. Run Ground, Sketch,
  Agree, Implement, and Scrap when implementation invalidates the design.
- **Design-only** is for a caller that owns implementation. Run Ground, Sketch,
  and Agree, return the synthesized design package, and stop. Do not enter
  Implement or Scrap and do not modify production implementation code.

A caller selects design-only explicitly, for example `architect design-only` or
"route through `architect` in design-only mode." If no mode is supplied, use
full mode.

A checkpoint is separate from mode. `full with checkpoint` pauses after Agree
for user approval and then continues implementation after approval. Design-only
always returns after Agree because implementation belongs to the caller.

## Model resolution

Architect's design-candidate role is `architect runners`, generic role
`judgment`, from `~/.cursor/rules/ostack-models.mdc`. Architect does not spawn
those candidates directly. In Phase B it routes through Arena and passes
`architect runners` as Arena's supported runner-role override. Arena then owns
resolution, host-rejection handling, candidate spawning, and fallback semantics
for that panel. Arena continues to resolve its cross-judge from
`arena cross-judge`.

For this nested call, Arena resolves `architect runners` from the skill-role
line, then generic `judgment`, then `inherit`, and passes each resolved candidate
value as the subagent `model` argument.

Hosts that do not load the Cursor rule therefore resolve both roles to
`inherit`. Do not replace a rejected model with a nearby ID, and do not treat a
successful delegation as proof of which model actually ran because the host may
substitute one silently.

## Start

Open a todolist with one entry per active phase before starting. Autonomous mode without checkpoints needs the list to show phase position and keep phases from silently disappearing.

Full mode:

1. Ground
2. Sketch
3. Agree
4. Implement
5. Scrap

Design-only mode:

1. Ground
2. Sketch
3. Agree

## Phase A: Ground the problem

Build a real mental model of every system the new code touches. Run the **how** skill over the relevant subsystems. Critique mode if existing structure is the constraint or the design must push back on it.

Naming a file isn't grounding. Produce the traced model `how` prescribes. If the design redefines ownership or layering, also run the **why** skill on the existing shape so the rationale becomes a constraint, not a guess.

Skip Phase A only when the work is genuinely greenfield with no surrounding system to integrate.

## Phase B: Sketch

Run the **arena** skill with the design-sketch task and the Phase A grounding artifacts. Pass `references/runner-prompt.md` as each runner's prompt. Each candidate produces a design package shaped per `references/rationale-template.md`: the caller's usage written first, then the type sketch, function signatures, module map, and prose rationale derived from it.

Set Arena's runner-role override to `architect runners`. Do not also use
`arena runners` for the design candidates. Arena still owns its
`arena cross-judge` role and the rest of its comparison, grafting, and
verification workflow.

Design it twice. Require at least two structurally distinct candidates before synthesis, even when the first looks sufficient. This is the **exhaust-the-design-space** principle made concrete. Whole-shape alternatives, not point fixes inside one shape.

Screen every candidate against [`references/design-red-flags.md`](references/design-red-flags.md) before synthesis. Reject or revise shallow modules, information leakage, temporal decomposition, and pass-through methods.

Compare viable candidates on interface depth. Prefer the design that hides more complexity behind a smaller, simpler public surface. A rich interface can keep call chains short by concentrating capability instead of scattering it across layers.

Arena returns one synthesized design package. The synthesis decision populates the rationale's "Synthesis decision" section.

## Phase C: Agree

In design-only mode, return the synthesized design package to the caller and stop. Do not enter Phase D or modify production implementation code.

In full mode, proceed directly to implementation with the synthesized design unless the invoker explicitly requested a checkpoint.

For `full with checkpoint`, surface the synthesized design and pause for sign-off. After approval, continue to Phase D. Examples include `/architect with checkpoint`, "stop and show me before implementing", or similar.

The synthesis can ship as its own commit in full mode. That's the "scaffold first" mode of the **foundational-thinking** principle; subsequent commits read as filling in bodies against a stable contract. Planned and scoped breakage during fill-in is fine, per the **outcome-oriented-execution** principle. For adversarial pressure on the design before implementing, run the **interrogate** skill on the synthesized sketch.

If the human or calling workflow pushes back on the shape, treat that as Phase A evidence. Re-ground and re-run Phase B before writing more code.

## Phase D: Implement against the sketch

Full mode only.

Replace `not implemented` bodies with code, pseudocode with logic. The synthesized sketch is the contract.

Deviations from the sketch are signal worth surfacing, not friction to absorb silently. If a function needs a parameter the sketch didn't anticipate, ask whether the sketch was wrong, the requirement was missed, or the implementation is overreaching. Surface it; don't bolt it on.

## Phase E: Scrap when the architecture is wrong

Full mode only.

If implementation keeps producing friction the sketch can't absorb, throw the sketch out. Don't bolt fixes onto a wrong design, per the **redesign-from-first-principles** and **fix-root-causes** principles.

The signal is a *pattern*, not single instances. Tells:

- The same shape of workaround appearing repeatedly across unrelated code.
- Multiple unrelated edge cases that all need special-case branches.
- Types that need escape hatches (`any`, casts, optional fields always set in practice) to compile.
- The "we need a lock" reflex when the sketch said the state wasn't shared.
- Callers having to know the abstraction's internal rules to use it.
- Two or more independent Phase D deviations of the same shape across the implementation. Surfacing deviations is Phase D's job; a repeated pattern of them is Phase E's trigger.

Use judgment. A few edge cases don't condemn an architecture. Some problems are legitimately complex; complexity in the data is not complexity in the design. The rewrite signal is repeated friction of the same shape, not single hard cases.

When you scrap:

1. Re-run the **how** skill over what's been built. The implementation lessons enter the new design as inputs, not vibes.
2. Redesign as if the new constraints had been day-one assumptions, per redesign-from-first-principles.
3. Subtract before adding, per the **subtract-before-you-add** principle. The new sketch should be smaller than the old one before it grows.
4. Return to Phase B and re-run arena.

## Outputs

The caller's usage is written first and the type sketch derived from it. One file with new types and signatures for small changes; module map plus type definitions for larger work. The rationale ships alongside, shaped per `references/rationale-template.md`, including the usage sketch and the synthesis decision.

Design-only returns that design package to the caller as its final artifact. Full mode continues through implementation and returns the implemented result plus the design rationale.
