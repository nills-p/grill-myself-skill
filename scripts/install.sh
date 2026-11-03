#!/usr/bin/env bash
# Install the grill-myself skill for one or more AI tools (macOS / Linux).
#
# Pipeline: resolve source folder -> resolve target skill roots -> DRY-RUN report -> copy.
# Each target is just "<root>/grill-myself/SKILL.md", so you can always do this by hand
# with: mkdir -p <root> && cp -R plugins/grill/skills/grill-myself <root>/
#
# Usage:
#   ./scripts/install.sh [--target agents|claude|all] [--scope personal|project]
#                        [--project PATH] [--dry-run]
#
#   --target agents  ~/.agents/skills   (Codex, GitHub Copilot, Cursor, Gemini CLI, ...)
#   --target claude  ~/.claude/skills   (Claude Code)
#   --target all     both (default)
#   --scope project  installs into PATH/.agents/skills and/or PATH/.claude/skills instead
set -euo pipefail

TARGET="all"
SCOPE="personal"
PROJECT=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --scope)   SCOPE="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$REPO_ROOT/plugins/grill/skills/grill-myself"
[[ -f "$SOURCE/SKILL.md" ]] || { echo "SKILL.md not found at $SOURCE" >&2; exit 1; }

case "$SCOPE" in
  personal) BASE="$HOME" ;;
  project)
    [[ -n "$PROJECT" ]] || { echo "--scope project needs --project PATH" >&2; exit 1; }
    [[ -d "$PROJECT" ]] || { echo "Project path not found: $PROJECT" >&2; exit 1; }
    BASE="$(cd "$PROJECT" && pwd)" ;;
  *) echo "--scope must be personal or project" >&2; exit 1 ;;
esac

case "$TARGET" in
  agents) ROOTS=("$BASE/.agents/skills") ;;
  claude) ROOTS=("$BASE/.claude/skills") ;;
  all)    ROOTS=("$BASE/.agents/skills" "$BASE/.claude/skills") ;;
  *) echo "--target must be agents, claude or all" >&2; exit 1 ;;
esac

# --- DRY-RUN / VERIFICATION: show exactly what will be created or replaced ---
echo "Source: $SOURCE"
for root in "${ROOTS[@]}"; do
  dest="$root/grill-myself"
  if [[ -e "$dest" ]]; then echo "  REPLACE $dest"; else echo "  CREATE  $dest"; fi
done
if [[ $DRY_RUN -eq 1 ]]; then echo "Dry run: nothing changed."; exit 0; fi

# --- Copy: replace the whole folder so removed files don't linger ---
for root in "${ROOTS[@]}"; do
  mkdir -p "$root"
  rm -rf "$root/grill-myself"
  cp -R "$SOURCE" "$root/"
  echo "Installed: $root/grill-myself"
done
echo "Done. Start a new session in your AI tool to load the skill."
