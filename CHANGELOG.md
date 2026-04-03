# Changelog

## [0.2.0] - 2026-04-02

### Added

- **no-comments-guard**: new `preToolUse` guard that blocks comment lines (`//`, `/*`, `*/`, `#`) in
  source code files (`.go`, `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.rs`, `.java`, `.c`, `.cpp`, `.h`,
  `.cs`, `.rb`, `.swift`, `.kt`). Shebang lines (`#!/`), test files, Makefiles, shell scripts, and
  config files are excluded. Rationale: comments can conflict with code, confusing the LLM about
  which to follow ([AMPECO Infinite Engineer](https://p.ampeco.com/infinite-engineer/infinite-engineer)).
- **skills directory restructured**: `copilot-cli/skill/SKILL.md` → `copilot-cli/skills/dev/SKILL.md`
  per the latest copilot-cli plugin spec (skills must live in named subdirectories).
- **plugin.json**: `"skills"` path updated to `"skills/"`, version bumped to `0.2.0`, added
  `"self-documenting"` keyword.
- **session-start.sh**: banner updated to list `no-comments-guard`.
- **hooks.bats**: 7 new tests for `no-comments-guard` (27 tests total, 0 failures).

### Changed

- **pre-tool.sh**: refactored to extract `CONTENT` once at the top (shared between `secrets-guard`
  and `no-comments-guard`), eliminating duplicate `jq` calls. Added `_is_test_or_config()` helper
  to deduplicate the file-exclusion check.

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
