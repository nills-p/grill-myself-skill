# Using grill-myself in a chat app without skill support

For chat assistants that can't load Agent Skills (for example Microsoft 365 Copilot Chat,
or a Gemini or ChatGPT workspace where skills are switched off).

The skill text is **not** copied here, so it can't drift from the real one. You attach
`SKILL.md` and paste the short preamble below.

## One-off use

1. Start a new chat.
2. Attach `plugins/grill/skills/grill-myself/SKILL.md` (or paste its contents).
3. Paste this preamble, then your task:

```text
The attached SKILL.md is a procedure called "grill-myself". Follow it exactly for the
task below, from Phase 0 to Phase 4. You have no subagent tool, so for every critic
round use the "Manual critic" option: print the filled-in critic template in one code
block and wait for me to paste the critic's reply back. Do not score your own draft.

TASK:
<your task here>
```

4. For each round, copy the critic template into a **second, new chat** (any AI tool),
   then paste its reply back into the first chat.

The second chat never sees the author's reasoning, so the critic stays independent.
Prefer not to copy-paste? Replace the "Manual critic" sentence with
"use the Self-critique option". The verdict is then labelled `SELF-CRITIQUE (not independent)`.

## Reusable assistant (custom GPT, Gemini Gem, Copilot agent, Claude Project)

1. Upload `SKILL.md` as a **knowledge file**. It is ~15k characters, which exceeds the
   instruction limit of some builders.
2. Put this in the instructions field:

```text
You have a knowledge file SKILL.md describing a procedure called "grill-myself".
When the user says "grill yourself", "stress-test your answer" or "iterate until it
meets the bar", read SKILL.md in full and follow it exactly. You have no subagent tool:
offer the "Manual critic" option, or fall back to "Self-critique" and label it.
Do not use it for ordinary "improve this" requests.
```
