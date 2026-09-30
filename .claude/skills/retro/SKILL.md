---
name: retro
description: Look back at a finished session and propose changes to the agent's environment (skills, docs/agents rules, AGENTS.md, SwiftLint or CI checks, memory) so the next run goes better, each one backed by a quoted moment from the session log. Runs as the last phase of solve; also use when the owner says "retro", "retrospective", or asks what went wrong in a session.
---

# Retro

A retro changes the environment, not the code. Its output is a short list of proposed
edits to the files that steer the next agent: a skill, a `docs/agents/` reference,
`AGENTS.md`, a check in SwiftLint or CI, or a memory worth promoting. Like
[grill-me](../grill-me/SKILL.md), it is stateless until the owner approves a finding's
wording; nothing is edited before that, and nothing is committed without the owner's
word.

The measure of a retro is not how much it finds. It is whether a complaint it fixed
stays fixed.

## Start with the last retro's fixes

Before reading this session for new findings, read [ledger.md](ledger.md). The ledger
is each engineer's own and is gitignored: the fixes land in the repo for everyone, but
whether they held is tracked per engineer. If the file does not exist yet, create it
from the header below and skip this step.

Every fix a retro has landed is a row there: the complaint quoted, the fix, the file,
and the rung it used (see "When a fix did not hold"). For each row still marked
`holding`, search this session's log for the same complaint or the same slip.

- Not seen: leave it `holding`.
- Seen: mark the row `came back`, with this session's quote and date. That is the first
  finding of this retro and it outranks every new one, because a fix that did not hold
  means the owner is repeating a correction to a system that claimed to have listened.

```markdown
# Retro ledger

One row per fix a retro landed. The next retro checks every `holding` row against its
session log first. Rungs: 1 sentence, 2 the moment, 3 a check, 4 tooling or model.

| Complaint (quoted) | Fix | File | Rung | Landed | Status | Last seen |
| --- | --- | --- | --- | --- | --- | --- |
```

## Evidence comes from the log, not from memory

The session log is the primary source. Your recollection of the session is not: by the
end of a piece of work the conversation has usually been summarised, and the summary
keeps what went well and drops the moment the owner had to repeat a correction.

1. Logs live at `~/.claude/projects/<project>/<session-id>.jsonl`, where `<project>` is
   the working directory with every `/` turned into `-`
   (`-Users-<you>-Projects-swift-ios-template` for this repo). Default to the current
   session; the owner may name others. The file is complete even when the conversation
   was compacted.
2. The raw log is mostly tool output. Condense it first with
   `python3 .claude/skills/retro/condense.py <session.jsonl> <scratchpad>/condensed.txt`:
   it keeps every owner message in full, including those typed while the agent was
   mid-turn, and redacts anything shaped like a password or token. Then send the
   condensed log to an `Explore` subagent and ask for candidate moments, each with its
   timestamp and the quoted lines. The judging stays in this thread.
3. The strongest signal is the owner correcting, repeating, or interrupting. Next: the
   same tool call repeated, a long search for something a pointer would have found, a
   build-or-test loop that failed twice, a fact asked of the owner that a file already
   held, a rule in a skill or in `AGENTS.md` that the session broke anyway.
4. Before proposing, grep the other session logs for the same failure. A finding that
   recurs across sessions outranks one that happened once, and the recurrence count goes
   in the finding.

No quote, no finding. A finding the log cannot show is an opinion, and the owner has no
way to check it.

## Where each fix belongs

Pick the cheapest home that will actually change the next run, in this order:

| The failure | The home | Why there |
| --- | --- | --- |
| A mechanical slip a pattern can see (a banned call, an import shape, a file in the wrong module) | a SwiftLint rule in `.swiftlint.yml`, or a step in `.github/workflows/ci.yml` | A check runs every time; a sentence is read sometimes. Look first for a check that exists but is unwired or too loose. |
| A judgement call reviewable from a diff | the `docs/agents/` file for that area (`architecture.md`, `testing.md`, `conventions.md`) | The reference is read before the work it governs. |
| A step in how a piece of work runs | the skill that owns that phase (solve, grill-me) | The rule loads exactly when it applies. |
| The agent could not find something | a pointer in `AGENTS.md` | `AGENTS.md` loads into every session via `CLAUDE.md`, so it holds pointers and the few hard rules, never a long explanation. |
| A working preference that lives only in memory | promote it into the skill or reference that governs that moment | Memory is on one machine; the repo reaches every agent. |
| Information the agent had no way to reach | a tooling proposal | No sentence fixes missing access. |

Prefer tightening or deleting an existing sentence over adding a new one. A rule the
session broke while it was already written is not fixed by writing it again, louder: ask
why it did not bite (too far from the moment it applies, buried among others, phrased as
a preference) and fix that. Check also for **no-ops**: instructions that changed nothing
in the session, or say what another file already says. Removing them is a finding too.

### When a fix did not hold

A complaint that came back is never fixed with the same kind of fix. Move it one rung up:

1. **A sentence** in the skill or reference that owns the moment.
2. **The moment itself**: the rule moved to the exact step where it applies, or into a
   test the agent runs before acting.
3. **A check** that fails without a human: a SwiftLint rule, CI, or a Claude Code hook.
   A hook lives in `.claude/settings.json`, which this repo's `.gitignore` excludes, so
   proposing one includes the `.gitignore` exception that lets it reach other engineers.
4. **A tooling or model change**, when no check can see the failure.

Say in the finding which rung failed and which one you propose. If the top rung has
failed, say so plainly and let the owner decide; do not start the ladder again from the
bottom.

## Delivering the findings

Order by severity: a correction that recurs across sessions, then a single correction,
then friction the owner never saw. Deliver them one at a time: what happened (the quote
and its timestamp), the change you propose, and the file it lands in. Plain sentences,
no headings. Stop, and let the owner accept, reject, or reword it before the next.

For an accepted finding, show the exact wording, get approval, then edit, and add its
row to [ledger.md](ledger.md) as `holding` in the same change. A fix without a ledger
row cannot be checked by the next retro, so it does not count as landed. If it changes
a rule, update every doc that states that rule in the same change, since `AGENTS.md`
says the code wins and a stale doc is what gets corrected. The retro ends when every
finding has a ruling.
