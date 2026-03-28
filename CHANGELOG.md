# Changelog

## [0.1.0] - 2026-03-28

### Added

- Initial release of `agent-plugin-dev`.
- **copilot-cli plugin**
  - `session-start` hook: injects "Dev Guards Active" policy banner with all three guard names.
  - `preToolUse` hook (`pre-tool.sh`):
    - **secrets-guard**: detects hardcoded credentials (`JWT_SECRET`, `API_KEY`, `CLIENT_SECRET`, `DB_PASSWORD`, etc.) in `edit`/`create` tool calls on code files. Skips test files, templates, and markdown.
    - **branch-guard**: blocks `git push/merge ... main` (with boundary-aware `[^&|;]*\bmain\b` regex to avoid false positives across `&&` chains), and `git commit --no-verify`.
    - **migration-guard**: blocks `DROP TABLE`, `TRUNCATE TABLE`, `DELETE FROM` in bash commands that reference migration file paths.
  - Skill definition (`SKILL.md`) documenting all three guards with examples.
- **Test suite**: 19 bats unit tests (19/19 passing).
