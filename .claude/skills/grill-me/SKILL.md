---
name: grill-me
description: A relentless interview to sharpen a plan or design before building it, one question at a time, each with a recommendation. Use only when the user explicitly asks to be grilled, invokes /grill-me, or asks to stress-test a plan, approach, or design decision.
---

# Grill me

Interview the user relentlessly about every aspect of this until you reach a shared
understanding. Walk down each branch of the decision tree, resolving dependencies
between decisions one by one. For each question, give your recommended answer.

Ask **one question at a time**, waiting for the answer before continuing. Several
questions at once is bewildering. Use `AskUserQuestion` so each arrives with its
options.

If a *fact* can be found by looking, look it up. The *decisions* are the user's —
put each one to them and wait.

Do not act on any of it until the user confirms you have reached a shared
understanding.

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

Only what remains after that is a real question.

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

## Question shape

Each question carries three things:

1. **The options** — the real, distinct choices, not a blank prompt.
2. **The tradeoff** — what each option costs, in terms of *this* codebase.
3. **Your recommendation** — which you would pick and why, so the user is reacting
   to a proposal rather than starting from nothing.

Where an option matches an existing pattern, name the file that demonstrates it.
Where an option would introduce a new pattern, say so plainly — that is a cost the
user should price in, and this repo prefers following an existing shape.

## Settling

Settled decisions are not reopened. If new information contradicts a settled call,
say what changed and ask whether to revisit; do not quietly re-decide.

Grilling is **stateless**: it writes nothing, changes no code, and leaves no
artifact but the sharpened understanding in the conversation. Recording the outcome
— in a GitHub issue or a doc — is a separate, explicitly approved step.
