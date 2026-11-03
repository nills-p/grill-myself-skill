# How Grill Myself works: scoring, exits and triage

This document explains the rules in `SKILL.md` for anyone who wants to understand *why* the skill is this strict, or who wants to change it. The source of truth remains [`plugins/grill/skills/grill-myself/SKILL.md`](../plugins/grill/skills/grill-myself/SKILL.md).

---

## Phase 0: the frame (3 lines, facts only)

| Line | Example |
|---|---|
| **Deliverable** | Patch formula for the request form |
| **Audience / context** | Employees in a Canvas App on Dataverse table `Requests` |
| **Hard constraints** | No premium connectors, table grows to 50k rows |

This frame goes to every critic **verbatim**. No justifications ("this is intentional because..."): they would steer the critic.

## Phase 1: the benchmark

- **5 to 8 criteria** (light mode: 5), of which **2 to 3 are Gates**.
- Every criterion has an **observable** pass condition: a number, a check or a test a stranger could run.
  - Good: *"zero delegation warnings on sources that can exceed the row limit"*
  - Bad: *"the formula is clear and efficient"* (words like *clear, meaningful, appropriate* are banned)
- At least one criterion is **fit-for-purpose**: tied to the user's real context.

### Worked example

| Criteria | Max | PASS threshold `ceil(0.8 × max)` |
|---|---|---|
| 5 | 10 | 8 |
| 6 | 12 | 10 |
| 7 | 14 | 12 |
| 8 | 16 | 13 |

PASS requires **both**: total ≥ threshold **and** every Gate = 2. A 13/14 with one Gate at 1 is **not** a PASS.

After round 1 the critic may propose at most 2 missing criteria. Then the benchmark is **frozen**: criteria, max and threshold no longer change.

## Phase 3: the grill loop

### 3a. The critic

A **new**, isolated critic each round (a subagent, a separate CLI run, or a second chat the user pastes into) receives only: the frame, the benchmark, the current draft, and the list of previously raised issues with their status. It must:

1. Score every criterion (0/1/2) with **verbatim evidence**.
2. Report at most 3 issues, ranked by impact, each with a concrete fix.
3. (Round 1 only) propose missing criteria.
4. One line: *"Would a domain expert ship this as-is? yes/no, because..."*

A score counts as **0** if the evidence is missing, a quote does not appear in the draft, or a test is cited without the exact command and output.

### 3b. The exits

| Exit | Condition | What ships |
|---|---|---|
| **PASS** | All Gates = 2 and total ≥ threshold | This exact draft, unchanged |
| **PLATEAU** | Round ≥ 3, score did not rise, no more Gates at 2 | The highest-scoring snapshot (ties: the latest) |
| **CAP** | Last round reached (5, or 2 in light mode) | The revised draft, after one extra scoring-only critic run |

At least one critic round always runs.

### 3c. Triage of every issue

| Decision | When |
|---|---|
| **Accept** | The issue is valid: it gets fixed |
| **Reject** | With a concrete reason: conflicts with a hard constraint, the critic misread the context, or the fix breaks a Gate |
| **Defer** | Valid but out of scope: goes into residual risks |
| **Disputed** | A previously rejected issue comes back with new evidence. The agent may **not** reject it again: accept it, or list it as *disputed* for the user to decide |

The reason for a reject goes into the grill log only, **never** into the next critic prompt.

### 3d. Revise

1. First keep a **snapshot** of the current version (`<name>.v<N>.<ext>` for files).
2. Apply the accepted fixes.
3. **Oscillation check:** if a fix would undo an earlier fix, it is not applied and gets logged.

For an existing user file, the agent works on a copy (`<name>.work.<ext>`) and only writes back in phase 4.

## Phase 4: delivery

1. Verdict line
2. Grill log (every score comes from a real critic run on exactly that version, never estimated)
3. Residual risks
4. The deliverable: identical to the version the score was based on

## Anti-patterns the skill guards against

- Writing the benchmark after studying the draft
- Adding reasoning or justification to the frame or the critic prompt
- Rejecting the same issue twice, or accepting everything to please the critic
- Reporting a self-estimated score
- Reporting PASS with a Gate at 1
- Letting the critic run anything with side effects on a real system
- Showing critic transcripts to the user (they want the verdict, the log and the result)
