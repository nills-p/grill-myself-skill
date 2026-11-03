# Changelog

All notable changes to the `grill` plugin and the `grill-myself` skill.
Versions follow [SemVer](https://semver.org/). Always bump `version` in
`plugins/grill/.claude-plugin/plugin.json`, otherwise users won't receive the update.

## [1.1.0] - 2026-11-03

### Added
- MIT license (`LICENSE`), also declared in `SKILL.md` and `plugin.json`.
- Cross-tool support: install guide for Codex, GitHub Copilot, Cursor, Gemini CLI and other
  Agent Skills clients via the shared `.agents/skills/` folder.
- `scripts/install.sh` (macOS/Linux) and `scripts/Install-Skill.ps1` with `-Target Agents|Claude`.
- `scripts/New-SkillPackage.ps1` (was referenced in the README but missing).
- `adapters/AGENTS.md` for tools without skill support, and `adapters/chat-prompt.md` for chat apps.
- "Manual critic" option: an independent critic in any chat tool by pasting into a second chat.

### Changed
- Claude Code marketplace is now `nills-p-skills`, owner "Nills Parmentier".
- `SKILL.md` wording is tool-neutral ("the agent" instead of "Claude"); critic step lists
  subagent, separate CLI run, manual critic and self-critique in order of preference.
- `SKILL.md` frontmatter gains `license`, `compatibility` and `metadata` (Agent Skills spec fields).
- Docs and sequence diagram say "Agent (author)" instead of "Claude (author)".

## [1.0.0] - 2026-11-03

### Added
- `grill-myself` skill: critic-scored improvement loop (Frame, Benchmark, Draft, Grill loop, Deliver).
- Plugin marketplace `nills-p-skills` with plugin `grill`.
- Install scripts: `Install-Skill.ps1` (manual install) and `New-SkillPackage.ps1` (ZIP for claude.ai).
- Documentation with Mermaid diagrams and SVG fallback.
