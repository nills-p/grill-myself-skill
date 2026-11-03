<!--
  Adapter for AI tools that read AGENTS.md (or a similar project instructions file)
  but do NOT load Agent Skills on their own.

  How to use:
  1. Copy the skill folder into your project: .agents/skills/grill-myself/SKILL.md
     (scripts/install.sh --scope project, or scripts/Install-Skill.ps1 -Scope Project).
  2. Paste the section below into your project's AGENTS.md (create it if missing).
     Same idea for CLAUDE.md, GEMINI.md, .github/copilot-instructions.md, etc.

  Tools that support Agent Skills natively do not need this file.
-->

## Skill: grill-myself

When the user explicitly asks you to **grill yourself**, "stress-test your answer",
"self-critique this until it passes" or "iterate until it meets the bar":

1. Read `.agents/skills/grill-myself/SKILL.md` in full before you do anything else.
2. Follow it exactly: frame, benchmark (written before the draft), draft, critic loop, deliver.

Do not use it for ordinary "fix/improve this" requests, or when the user asks to be
grilled themselves.
