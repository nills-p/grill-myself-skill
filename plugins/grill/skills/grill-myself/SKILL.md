---
name: grill-myself
description: "Make the agent relentlessly question and improve its OWN output through an independent critic, scored against a task-specific benchmark, for at most 5 rounds. Use ONLY when the user explicitly asks for it: 'grill yourself', '/grill-myself', 'self-critique this until it passes', 'stress-test your answer', 'iterate until it meets the bar', or asks for a critic-scored improvement loop on a deliverable (UI design, flow, script, formula, plan, doc). Do NOT use for ordinary 'fix/improve/optimize this' requests, quick answers, or when the user wants to be questioned themselves (that is grill-me)."
license: MIT
compatibility: Works in any Agent Skills client (Claude, Codex, GitHub Copilot, Cursor, Gemini CLI and others). An independent critic needs a subagent tool or a second chat session; without one it falls back to a labelled self-critique.
metadata:
  author: Nills Parmentier
  version: "1.1.0"
---

# Grill Myself

You produce something, then have it attacked until it passes a benchmark you defined
before judging it. Not until it *feels* good.

Three rules. Break one and the loop becomes theatre:

1. **The bar is set before judging.** Write the benchmark before you draft, or before you
   study an existing artifact, so you can't fit the bar to the work.
2. **The critic is not you.** A fresh critic context (subagent or new chat) sees only the template inputs. Never your reasoning.
3. **The loop has an exit, computed from numbers.** PASS, PLATEAU or CAP. Never "feels done".

## When not to use / scale down

- **Under ~30 lines or a one-shot factual answer:** say in one line that the loop likely costs
  more than it finds, and offer light mode. Run light mode if the user confirms or already said 'grill yourself'.
- **Light mode** (small deliverable, or user says "quick"): 5 criteria, max 2 rounds.
- **Full mode** (default): 5–8 criteria, max 5 rounds.
- Cost per round ≈ draft + benchmark + template, sent to a fresh critic context. Tell the user
  the mode, max rounds and max critic runs (rounds + 1 final scoring run at CAP) in one line before starting.

---

## Phase 0: Frame (no tools)

Write exactly 3 lines. This text is the **TASK FRAME**, passed to every critic verbatim:
- **Deliverable:** what gets produced
- **Audience / context:** who uses it, where
- **Hard constraints:** stack, licensing, limits, brand, anything the user stated

Facts only. No justifications, no "this is intentional because…".
If an unknown constraint would change the outcome, ask ONE question. Otherwise state the assumption.

## Phase 1: Benchmark

Start from the matching entry under **Benchmark starting points** (bottom of this file).
If none matches, derive criteria from the Phase 0 constraints. Tailor every criterion.

| # | Criterion | Pass condition (observable) | Gate? |
|---|-----------|-----------------------------|-------|

Rules:
- **Observable or it doesn't count.** A pass condition names a number, a check, or a test a
  stranger could run ("contrast ≥ 4.5:1", "no delegation warnings"). Words like *clear,
  meaningful, appropriate, earns its place* are banned in pass conditions.
- **5–8 criteria** (light mode: 5). **2–3 Gates.**
- **At least one fit-for-purpose criterion** tied to the user's real context.
- **Scoring:** 0 fail / 1 partial / 2 pass. Max = 2 × criteria.
- **PASS = every Gate = 2 AND total ≥ ceil(0.8 × max).** Write the number down (e.g. 7 criteria → 12/14).

Show the benchmark as one compact table, then continue.

## Phase 2: Draft v1

- **New deliverable:** produce your best honest attempt. Don't hold back for a comeback.
- **Existing artifact** (user's file, your previous answer): that artifact *is* v1. Skip
  drafting. Phase 1 must be written from the task frame before you study the artifact in detail.

## Phase 3: The grill loop

Each round runs **in this order**. The order matters: the draft you ship must be the draft
that was scored.

### 3a. Critic scores the current draft

Run the critic in a **fresh, isolated context** with the template below. Use the first
option your host supports:
1. **Subagent tool** (subagent, sub-agent, task or agent tool; in Claude Code a
   `general-purpose` agent). This is the default.
2. **Separate CLI run:** if you can run shell commands, a new non-interactive run of your own
   CLI in its read-only/sandbox mode, with the template as the prompt. Ask the user once before the first one.
3. **No isolation available:** tell the user the critic can't be independent and offer:
   - **Manual critic:** you print the filled-in template, the user pastes it into a NEW chat
     (any AI tool) and pastes the reply back. Independent, but one copy-paste per round.
   - **Self-critique:** you run the template as a separate step using only its inputs and
     mark the verdict `SELF-CRITIQUE (not independent)`.

For every option:
- **Paste the draft inline.** Use a file path only if the draft is very large AND the
  critic shares your filesystem (never for the manual critic).
- **Never add** your reasoning, earlier drafts, or your opinion.
- **Testing:** if the deliverable can be tested (render + screenshot, run code, run tests),
  tell the critic to test, not just read. **Side-effect rule:** the critic may only execute in a
  sandbox, read-only, or dry-run mode. Never against a production tenant, never with real
  credentials, never anything that sends mail, writes data, or deletes. If it can't be tested
  safely, the critic reviews statically and says so.

```
You are a senior reviewer. Your reputation suffers if you approve something a domain
expert would reject, AND if you report issues that aren't real.

TASK FRAME:
<Phase 0 text, verbatim>

BENCHMARK (fixed after round 1):
<table, with PASS threshold>

DRAFT (round N):
<draft inline>

PREVIOUSLY RAISED (issue | round | status: fixed / rejected; if rejected for a hard
constraint, quote that TASK FRAME line, nothing else):
<list, or "none">
Re-raise any item whose problem is still visible in the draft, with new evidence.

TESTING: <what you may run, and the side-effect rule; or "static review only">
Do not create, modify or delete any file. You score and report; you do not fix.

Do this:
1. Score EVERY criterion 0/1/2 with EVIDENCE quoted exactly from the draft or from a
   test you ran. No evidence = 0. Skipping a criterion is not allowed.
2. List UP TO 3 issues that cost points on a criterion, ranked by impact. Each: location,
   which criterion it costs, why it matters to this audience, a concrete fix. If none,
   write "No blocking issues". Do not invent issues.
3. Round 1 only: up to 2 criteria the benchmark is MISSING, or "none".
4. One line: "Would a domain expert ship this as-is? yes/no, because ..."
No praise. No summary. No softening.
```

**Validate the reply:** treat a criterion as 0 and log `critic evidence invalid: #N` if it has
no score, OR its evidence is a quote that doesn't appear in the draft, OR it cites a test without
the exact command/action and the relevant output. Test evidence with command + output counts.

### 3b. Check exits (on the score just received)

1. **PASS:** all Gates = 2 AND total ≥ threshold → stop, ship this exact draft unchanged.
2. **PLATEAU:** round ≥ 3 AND total ≤ previous round's total AND Gates-at-2 did not increase → stop,
   ship the highest-scoring snapshot scored under the frozen benchmark (round 1 counts if no
   criteria were added in round 1; ties: the latest), unchanged, with its score.
3. **CAP:** this is the last round (5, or 2 in light mode) → go to 3c and 3d, then run
   **one final scoring-only critic** (items 1 and 4 of the template only) on the revised draft. Ship it with that score.

Minimum: one critic round always runs.

### 3c. Triage every issue

- **Accept:** will fix.
- **Reject:** with a concrete reason (conflicts with a hard constraint, critic misread the
  context, fix breaks a Gate). Allowed and healthy. The reason goes in the grill log only,
  never into the critic prompt.
- **Defer:** valid but out of scope → residual risks.
- **Disputed:** an issue you already rejected, raised again with new evidence. You may not
  reject it a second time. Either Accept it, or list it as **disputed** in residual risks for the user to decide.

Round 1 only: add the critic's missing criteria if they pass the "observable" rule AND the total
stays ≤ 8 (light mode: ≤ 5; to add one, drop a non-Gate criterion). Recompute threshold =
ceil(0.8 × new max), then **freeze the benchmark, its max and its threshold.** If criteria were
added, round 1's score is not comparable: compare from round 2 onward.

### 3d. Revise

**Snapshot first:** before applying fixes, keep the current draft as v<N>: verbatim in context,
or for files copy it to `<name>.v<N>.<ext>`. For an existing user file, revise a working copy named `<name>.work.<ext>` and
write the shipped snapshot back to the original path only in Phase 4.

Apply accepted fixes. **Oscillation check:** if a fix would undo an earlier accepted fix, don't
apply it. Keep the earlier version, log `oscillation: <issue>`, carry on with the round.

Next round → back to 3a with the revised draft.

## Phase 4: Deliver

Output in this order. The verdict comes first so it can't get lost under a long deliverable.

1. **Verdict line:** `PASS in N rounds (X/Y)` / `PLATEAU at round N, shipped v<K> (X/Y, scored in round K)` / `CAP (X/Y, final scoring run)`.
   Add `SELF-CRITIQUE (not independent)` if it applies.
2. **Grill log:**

| Round | Score | Gates (name: score) | Accepted | Rejected (why) | Deferred / Disputed |
|---|---|---|---|---|---|

   **Score provenance:** every score in the log and verdict comes from a critic run on exactly
   that version of the draft. Never estimate a score yourself.
3. **Residual risks:** failing criteria, deferred and disputed issues, Phase 0 assumptions,
   and whether the critic tested or only read.
4. **The final deliverable.** If it's a file: copy the shipped snapshot (`<name>.v<K>.<ext>`, or the
   working copy if that is the shipped version) to the deliverable's path (for an existing user file:
   the original path), then give that path. The file there must be identical to the version the
   reported score came from.

---

## Anti-patterns (if you notice yourself doing these, stop)

- Writing the benchmark after studying the draft
- Adding reasoning or justifications to the TASK FRAME or the critic prompt
- Rejecting the same issue twice, or accepting everything to please the critic
- Reporting a score you estimated instead of one the critic produced
- Reporting PASS with a Gate at 1
- Letting the critic run anything with side effects on a real system
- Showing the user critic transcripts: they want the verdict, log and result

---

## Benchmark starting points

Tailor every entry. ✅ = suggested Gate. Each line is "criterion: pass if …".

**UI design / HTML mockup / dashboard**
- ✅ Hierarchy: pass if exactly one primary CTA per view, and the primary action/key number is the largest or highest-contrast element
- ✅ Accessibility: pass if text contrast ≥ 4.5:1 (large ≥ 3:1), targets ≥ 44×44px, visible focus state on every interactive element
- Spacing: pass if every margin/padding/gap is a value from one declared scale
- Typography: pass if ≤ 2 font families and ≤ 5 font sizes
- States: pass if empty, loading, error and overflow (very long text, 0 items, 1,000 items) each render without breaking layout
- Responsive: pass if no horizontal scroll at 360px width
- *How to test (not a criterion): render and screenshot at desktop and 360px width.*

**Canvas App / Power Fx**
- ✅ Delegation: pass if zero delegation warnings on sources that can exceed the row limit, or each warning has a documented row ceiling
- ✅ Correctness: pass if output is correct for a normal record, an empty/blank record, and one edge record (listed)
- Performance: pass if no LookUp/Filter inside a ForAll or gallery item that could be hoisted into With() or a collection
- Error handling: pass if every Patch/SubmitForm is wrapped in IfError or followed by an Errors() check that notifies the user
- Layout: pass if main layout uses containers, no absolute X/Y on top-level controls

**Power Automate flow**
- ✅ Scale: pass if pagination/concurrency settings are explicit and expected volume × actions per item stays under the license's daily action limit
- ✅ Failure handling: pass if there's a Try/Catch scope pair with run-after on failed/timed out, and the catch notifies a named recipient
- Idempotency: pass if a re-run on the same trigger input creates no duplicate records (check described)
- Licensing: pass if every connector is standard, or premium licensing is confirmed in the hard constraints
- Maintainability: pass if zero hard-coded URLs/IDs (environment variables used) and the flow sits in a solution with connection references

**PnP PowerShell**
- ✅ Safety: pass if a read-only/-WhatIf verification block runs before any destructive loop, and a `-Confirm`/switch is needed to execute
- ✅ Scale & correctness: pass if internal column names are used, list reads use paging (`-PageSize`), and 429 throttling is retried
- Auth: pass if it uses certificate/app registration or managed identity, with zero stored passwords
- Idempotency: pass if running twice gives the same end state (check described)
- Logging: pass if changed / skipped / failed items are written to a file with timestamps

**JS / TS / React / PCF**
- ✅ Types: pass if it compiles under `strict` with zero `any` (or each one justified inline)
- ✅ State: pass if no derived value is stored in useState, and every useEffect has complete deps and a cleanup where it subscribes
- Accessibility: pass if every input has a label and all actions work with keyboard only
- PCF: pass if notifyOutputChanged is only called on real value changes and updateView does no DOM rebuild when inputs are unchanged

**Architecture / plan / roadmap**
- ✅ Sequencing: pass if every step lists its dependencies and each dependency appears earlier
- ✅ Decisions: pass if each key decision lists ≥ 1 rejected alternative with the reason
- Risks: pass if ≥ 3 risks, each with a mitigation and an owner
- Exit criteria: pass if each phase has a measurable "done" (number, artifact, or sign-off)

**Writing (blog, doc, Confluence)**
- ✅ Accuracy: pass if every technical claim has a source or a reproducible step, and versions/dates are stated where behaviour depends on them
- ✅ Actionability: pass if every task the reader must do has numbered steps or a command
- Structure: pass if the first 2 sentences state the conclusion or recommendation the title promises, and every H2 is a full statement (subject + verb), not a one-word label
- Length: pass if within the target word count (state it in Phase 0)

**Skill / prompt / agent instructions**
- ✅ Executability: pass if every referenced file/tool exists at runtime and every step can be done with the host's tools
- ✅ Termination: pass if every loop has an exit computable from logged values
- Trigger precision: pass if 3 should-trigger and 3 should-not-trigger phrasings classify correctly from the description alone
