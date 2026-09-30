# Agent configuration for ontrack

Agent skills for working on the ontrack repo live in two places:

- `.claude/skills/` — read by Claude Code (which reads only its own
  skills directory).
- `.agents/skills/` — the cross-tool path, read by OpenCode, Codex,
  Cursor, GitHub Copilot, Gemini CLI, and others.

OpenCode also reads `.claude/skills/` directly, so the old
`.opencode/skills/` duplicates were removed as redundant; this
`.opencode/` directory is kept for OpenCode-specific configuration.

Skills: `ontrack-publish` (Play + F-Droid publication: fastlane
metadata, fdroiddata recipe, Android build/test gates, operator-only
boundary).
