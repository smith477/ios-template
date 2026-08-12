---
name: solve
description: Drive a piece of work from unread scope to an approved multi-phase plan, then build it one owner-reviewed phase at a time, the same way every time. Use when the owner says "solve 12", "let's start issue 12", or begins work on any task in this repo.
---

# Solve

One fixed opening sequence for every piece of work, so the approach never drifts.
This skill drives the work to an approved plan, then builds it one phase at a
time. The rules it builds against are in `AGENTS.md` and `docs/agents/`.

Run the phases in order. Do not skip ahead: no branch before the scope is read
back, no grilling before the branch exists, no plan before grilling settles, no
second build phase before the owner has reviewed the first.

Every phase ends by naming the next phase and stopping. Do not run two phases in
one turn.

## The argument

`solve` takes either a GitHub issue number or a plain description:

```
/solve 12
/solve add a Reviews list to the product detail screen
```

A bare number means an issue. Anything else is a description, and there is no
issue to fetch — that is normal here, not a reason to stop and ask for one.

## Before you start

Give a **brief** step-by-step of what solve will do for this work — a short
numbered list, not an essay. Cover the sequence: read scope → branch → grill →
plan → build one phase at a time. Then stop and wait for the owner to confirm
before doing anything else.

## Phase 1: Read the scope

1. **With an issue number**, fetch it:

   ```bash
   gh issue view <n> --json number,title,body,labels,comments
   ```

   Read the comments, but treat anything that only lives in a comment as
   unsettled — carry it into Phase 3 rather than acting on it.

   **With a description**, there is nothing to fetch. The description is the scope.

2. Read `AGENTS.md`, then the `docs/agents/` reference for the layer being touched
   — `architecture.md` for a module, feature or route, `testing.md` for tests,
   `conventions.md` for anything else. Then read the code that will change, and
   the tests around it.

3. Read the scope back to the owner in a few lines: what is being built, the
   acceptance criteria, and what is explicitly out. Name **where it lands** — which
   module under `Modules/Features/` or `Modules/Platform/`, or `App/` — and whether
   it needs a `Project.swift` change, which implies a new target, a scheme entry
   and `tuist generate`.

4. Surface anything ambiguous as a candidate grilling question, but **do not ask
   yet**. Facts come from the code and the docs, never from the owner.

5. Name Phase 2 and stop.

## Phase 2: Create the branch

1. Branch from an up-to-date `main`:

   ```bash
   git fetch origin && git switch -c <name> origin/main
   ```

2. Name it `<issue>-<kebab-slug>` when there is an issue (`12-add-reviews-list`),
   a bare kebab slug when there is not (`add-reviews-list`).

3. If the working tree is dirty, **stop and ask**. Do not stash or discard anything
   on your own initiative.

4. Confirm with `git branch --show-current` and `git status`.

5. Creating a branch is not a commit and needs no approval. Do **not** push it.
   Commits and pushes happen only on the owner's explicit instruction.

6. Name Phase 3 and stop.

## Phase 3: Grill

Invoke the [grill-me](../grill-me/SKILL.md) skill with the Skill tool
(`skill: "grill-me"`). It takes no arguments — carry the candidate questions from
Phase 1 into it yourself, since it runs in this same conversation and can see them.

One judgement-call question at a time, each with options, the tradeoff in terms of
this codebase, and a recommendation; the owner decides. Facts the code or
`docs/agents/` already settle are looked up, not asked. Settled decisions are not
reopened.

Grilling ends when the owner confirms the settled calls and says where they are
recorded: the issue body, or nowhere. Nothing is written to GitHub without approval
on the wording — draft it, stop, ask, then apply.

Name Phase 4 and stop.

## Phase 4: Plan

Enter plan mode and produce the implementation plan.

1. The plan **must** break into multiple buildable phases. Phases are not competing
   slices of the work — they are **increments on a working base**. Phase 1 is the
   thinnest thing that builds, is green, and can be shown to the owner. Every later
   phase keeps it building and green while adding one capability on top. Each phase
   lands as one small commit and reviews on its own.

   A typical increment chain in this repo:

   > static screen with its layout and copy, plus the view-model state test → the
   > interactions and the events they emit → the repository, its endpoint and its
   > cache policy → the `AnyRoute` case, `AppRouter+<Feature>.swift`, and the
   > deep-link host

   Stop the chain where the scope stops. An increment the acceptance criteria
   exclude is not a phase, it is the next piece of work.

   Two rules carry the most weight. **A phase that only stacks a layer with nothing
   to show is wrong** — "add all the endpoints" and "wire up all the navigation"
   are not increments. And **tests ship with the increment that needs them**;
   "write the tests at the end" is never a phase.

2. State each phase's **demo** — what the owner can see in the simulator, or which
   test proves it — and which earlier phase it builds on. Order them so the
   frontier moves one phase at a time.

3. Label every phase **mechanical** or **judgement**. The label decides what gets
   delegated in Phase 5.

   - **Mechanical** — the plan already pins it down: the files to touch are named,
     the existing file to copy the pattern from is named, and the test file is
     named. Adding an endpoint that mirrors three siblings; a storage type that
     follows `ProductCoreDataStorage`.
   - **Judgement** — the answer is not sitting in a neighbouring file. Async timing,
     `@Observable` state that behaves unexpectedly, a new pattern, or anything whose
     failure mode you cannot predict from the plan.
   - When a phase is genuinely borderline, **label it judgement**. The cost is
     asymmetric.

4. Call out anything that introduces a **new pattern** rather than following an
   existing one — this repo prefers the existing shape, and a new one is a decision
   the owner should make knowingly. Call out any `Project.swift` change, and any
   new dependency (which needs approval before it is added).

5. Exit plan mode for the owner's approval. Name the first build phase and stop.

## Phase 5: Build one phase, then stop

Approving the plan approves the plan, not the build. Each phase is built and
reviewed on its own.

1. Build **exactly one phase**, then stop and hand it to the owner for review. Do
   not begin the next phase, even when the current one looks done and the next is
   obvious. The owner says when to continue.

2. **Route the phase by its label.**

   - **Judgement** — build it in this thread.
   - **Mechanical** — may be delegated to a subagent. The subagent has none of this
     conversation, so its brief must carry, in full: the phase's scope copied
     verbatim from the approved plan, the exact files to add or change, the existing
     file whose pattern it should follow, the test file and its path, which
     `docs/agents/` reference to read first, and instructions to **make no commits**
     and to **stop rather than widen scope**. Review what comes back before
     reporting it — a delegated phase is still your phase.

3. **Verify before handing off.** A single bundle is quick, so run it:

   ```bash
   mise exec -- tuist generate                                     # if Project.swift changed
   mise exec -- tuist test <Bundle> --device "iPhone 17 Pro"
   mise exec -- swiftformat . --lint && mise exec -- swiftlint lint --strict
   mise exec -- tuist inspect dependencies --only implicit         # if the module graph changed
   ```

   Never claim a build or test passed unless it was actually run. If something
   fails, paste the last meaningful error rather than "tests failed". If a command
   cannot run, say so explicitly rather than implying it passed.

4. **Escalation tripwire.** Two failed build-or-test cycles on a delegated
   mechanical phase ends the delegation. Stop, report the last meaningful error, and
   finish the phase in this thread. Two failures also mean the phase was
   mislabelled — say so, and re-check the labels on the phases still ahead.

5. **Tests belong to the phase**, not to a later cleanup phase. Write them with the
   increment that needs them, following `docs/agents/testing.md`.

6. **Report at the stop**: what the phase changed, its demo, whether it was built
   here or delegated, what the plan predicted wrongly, and the next phase. A phase
   that revealed a surprise is a reason to re-plan the remaining phases with the
   owner, not to absorb it silently and carry on.

7. **Commits and pushes happen only on explicit instruction.** Reaching the end of
   a phase is not that instruction. When the owner does ask, the commit is a subject
   line only — imperative, no body, no trailers.
