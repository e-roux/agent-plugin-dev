#!/usr/bin/env bash
# session-start.sh — Inject dev guards policy banner into session context.
set -euo pipefail

PLUGIN_ROOT="${COPILOT_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
LOG_DIR="$PLUGIN_ROOT/hooks/logs"

INPUT="$(cat)"
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // "unknown"')"

jq -cn '{additionalContext: "## Dev Guards Active\n\nGeneral-purpose guards are enforced:\n- **secrets-guard**: no hardcoded credentials — use env vars\n- **no-comments-guard**: code must be self-documenting — no comment lines in source files\n- **branch-guard**: never push/merge to `main` directly — use PRs\n- **migration-guard**: no DROP/TRUNCATE/DELETE in SQL migrations\n- **no-verify-guard**: `--no-verify` is forbidden on commits\n- **pipeline-chainguard**: after every `git push`, check CI pipeline status before continuing\n\nAll guards apply to every project in this session."}'

mkdir -p "$LOG_DIR" && \
  echo "session-start fired at $(date -u +%Y-%m-%dT%H:%M:%SZ), cwd=${CWD}" >> "$LOG_DIR/session-start.log" \
  || true

exit 0
