---
name: grill-me
description: A relentless interview to sharpen a plan or design before building it, one question at a time, each briefed with the current state and the consequence of every option, and carrying a recommendation. Use only when the user explicitly asks to be grilled, invokes /grill-me, or asks to stress-test a plan, approach, or design decision.
---

# Grill me

Interview the user relentlessly about every aspect of this until you reach a shared
understanding. Walk down each branch of the decision tree, resolving dependencies
between decisions one by one. For each question, give your recommended answer.

Ask **one question at a time**, waiting for the answer before continuing. Several
questions at once is bewildering.

If a *fact* can be found by looking, look it up. The *decisions* are the user's —
put each one to them and wait.

Do not act on any of it until the user confirms you have reached a shared
understanding.

## The context gap

By the time you ask anything, you have read files the user has not looked at in
weeks, and you know which earlier answer led to this question. The user sees only
the question. A question that makes sense from inside your context is a question
dropped on them cold: they either guess, or accept your recommendation without
understanding it, and both mean you made the decision alone.

So the user never meets a question without the briefing that makes it answerable.
Everything below exists to close that gap.

## Look it up, don't ask

Before asking anything, exhaust the sources that already hold the answer:

- **`AGENTS.md`** and the `docs/agents/` reference for the layer being touched —
  `architecture.md`, `testing.md`, `conventions.md`. If a reference already rules
  on the question, it is a fact, not a decision. Say which file settled it and
  move on.
- **The code.** `App/` for wiring, routing and the container; `Modules/Features/*`
  and `Modules/Platform/*` for everything else. An existing screen, repository,
  endpoint or route nearly always settles "how do we do X here". `Products` is the
  fuller reference implementation; `Users` is the deliberately simpler one.
- **The tests.** `AppTests/`, `Modules/*/*/Tests/` — they encode expected
  behaviour, especially around routing and caching.
- **The issue,** if there is one: `gh issue view <n>`.

Only what remains after that is a real question. Finish all of this before the
first question, so no question changes under the user while they answer it.

What you found is not private. It is the context the user needs, and it goes into
the orientation and the briefings below.

## Open with an orientation

Before the first question, write one message in chat:

1. **The goal as you understood it** — one or two sentences, so a misread is caught
   before anything is built on it.
2. **What you found** — how the relevant part of the app works today, with file
   links. Only what bears on the decisions ahead.
3. **The decisions ahead** — a numbered list of the questions you expect to ask,
   each a few words, in the order you will ask them and why that order (which ones
   depend on which). Say it may grow.

Keep it short when the work is small, but never skip it.

## Question shape

Every question is two parts: a **briefing in chat**, then the **`AskUserQuestion`
card**. The briefing carries the substance; the card only collects the answer. Never
put the context only inside the card.

The briefing, in this order:

1. **Where we are** — which decision this is (`3 of ~6: cache policy`) and which
   earlier answer led here, by name, not by number alone.
2. **Today** — how the code behaves now, with a file link. If nothing exists yet,
   say what the nearest existing pattern does.
3. **Why it needs deciding** — what goes wrong, or stays ambiguous, if nobody
   decides.
4. **The options** — the real, distinct choices. For each one, *if we pick this*:
   - what the app's user would see or experience differently;
   - what changes in the code, naming the file that already demonstrates it, or
     saying plainly that it introduces a new pattern (a cost — this repo prefers an
     existing shape);
   - what it costs later or rules out.
5. **Recommendation** — which you would pick and why, with a confidence percentage
   on every option, so the user is reacting to a proposal rather than starting from
   nothing.

Describe options in **plain behaviour first**, then the code terms: "Back returns
to the cart and the other tab keeps its place (`push`)", not "`push` or `crossTo`?".
Explain any concept the choice turns on in a sentence, unless the user has already
shown they know it.

Phrase the question so that **yes means your recommendation**. Do not recommend P
while asking whether to do not-P.

Aim for roughly six to twelve lines of briefing. If it runs longer, the question is
probably two questions.

The card then repeats the question in one line, and each option label is short and
matches a name used in the briefing.

## When the user asks what something means

A request for context is not an answer. Stop, explain in chat, and wait. Do not
re-ask the question in the same turn, and do not tuck the explanation inside the
next card. Once the user has read it, bring the question back.

## What counts as a question worth asking

Judgement calls where this codebase genuinely permits more than one answer, and
the choice has consequences. The recurring ones here:

- **Feature-local or Platform?** The admission rule is a *second* consumer, never
  anticipation — so this is usually "does anything else need it yet".
- **New `AnyRoute` case, or a sheet local to the screen?** A route is app-level
  vocabulary and deep-linkable; a sheet is not.
- **`push` or `crossTo`?** Pushing keeps Back returning where the user came from
  and leaves the other tab untouched; crossing replaces the target stack and
  discards any flow in progress there.
- **New endpoint and request type, or extend an existing one?**
- **Cache policy**, and what happens when the network fails — fall back to cache,
  or surface the error.
- **Error, empty, loading and offline behaviour** where the issue and design are
  silent.
- **Test depth** — state tests only, or a storage test against an in-memory store,
  or a UI test — and what is deliberately *not* covered.
- **Does this need a `Project.swift` change**, and therefore a new target, scheme
  entry and `tuist generate`?
- **Scope**: what is explicitly out for this piece of work, and deferred.

## Settling

Settled decisions are not reopened. If new information contradicts a settled call,
say what changed and ask whether to revisit; do not quietly re-decide.

When the decision list is exhausted, close with:

1. **A numbered recap** of every settled decision and the answer chosen, so the
   user can catch one recorded backwards.
2. **How it works** — one plain paragraph describing the whole thing as decided,
   as a newcomer would need it. If you cannot write it, something was never asked;
   ask it.

Then ask the user to confirm the recap and the paragraph as a whole. A "yes" to the
last question is not that confirmation.

Grilling is **stateless**: it writes nothing, changes no code, and leaves no
artifact but the sharpened understanding in the conversation. Recording the outcome
— in a GitHub issue or a doc — is a separate, explicitly approved step.
