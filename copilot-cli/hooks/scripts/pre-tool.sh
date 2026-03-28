#!/usr/bin/env bash
# pre-tool.sh — General-purpose development guards.
#
# Guards:
#   secrets-guard     — block hardcoded credentials in source files
#   branch-guard      — block direct push/merge to main + --no-verify
#   migration-guard   — block destructive SQL in migration files
#
# These guards are project-agnostic: they work with any repository.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"

INPUT="$(cat)"
TOOL=$(printf '%s' "$INPUT" | jq -r '.toolName' 2>/dev/null) || exit 0
ARGS=$(printf '%s' "$INPUT" | jq -r '.toolArgs' 2>/dev/null) || ARGS="{}"
CMD=""
FILE=""

case "$TOOL" in
  bash)
    CMD=$(printf '%s' "$ARGS" | jq -r '.command // ""' 2>/dev/null) || CMD=""
    ;;
  edit|create)
    FILE=$(printf '%s' "$ARGS" | jq -r '.path // ""' 2>/dev/null) || FILE=""
    ;;
esac

deny() {
  local reason="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null \
    && echo "denied at $(date -u +%Y-%m-%dT%H:%M:%SZ): $reason" >> "$LOG_DIR/pre-tool-denied.log" 2>/dev/null \
    || true
  jq -cn --arg reason "$reason" '{"permissionDecision":"deny","permissionDecisionReason":$reason}'
  exit 0
}

# ── secrets-guard: block hardcoded credentials in source files ────────────────
# Fires on edit/create for code files (skips tests, templates, markdown).
if [ "$TOOL" = "edit" ] || [ "$TOOL" = "create" ]; then
  if [ -n "$FILE" ]; then
    if ! printf '%s' "$FILE" | grep -qE '(_test\.(go|ts|js|rs|py)|\.test\.(ts|js)|spec\.(ts|js)|\.example|\.md|\.template|testdata)'; then
      if [ "$TOOL" = "edit" ]; then
        CONTENT=$(printf '%s' "$ARGS" | jq -r '.new_str // ""' 2>/dev/null) || CONTENT=""
      else
        CONTENT=$(printf '%s' "$ARGS" | jq -r '.file_text // ""' 2>/dev/null) || CONTENT=""
      fi
      SECRET_KEYS='(JWT_SECRET|API_KEY|CLIENT_SECRET|OIDC_CLIENT_SECRET|DB_PASS(WORD)?|MONGODB_URI|RABBITMQ_URL|PRIVATE_KEY|ACCESS_TOKEN_SECRET|SECRET_KEY|PASSWORD|PASSWD)'
      if printf '%s' "$CONTENT" | grep -qE "${SECRET_KEYS}[[:space:]]*:?=[[:space:]]*[\"'][^\"']{8,}[\"']"; then
        deny "Secrets guard: potential hardcoded credential detected in $(basename "$FILE"). Use os.Getenv() / process.env / env vars instead."
      fi
    fi
  fi
fi

# Remaining guards apply only to bash commands
[ "$TOOL" = "bash" ] || exit 0
[ -z "$CMD" ] && exit 0

# ── migration-guard: block destructive SQL in migration files ─────────────────
# Applies when the bash command touches SQL migration files.
if printf '%s' "$CMD" | grep -qiE '(migrations?/|\.sql)'; then
  if printf '%s' "$CMD" | grep -qiE '(DROP[[:space:]]+(TABLE|COLUMN|SCHEMA)|TRUNCATE[[:space:]]+TABLE|DELETE[[:space:]]+FROM)'; then
    deny "Migration guard: destructive SQL (DROP/TRUNCATE/DELETE) is forbidden in migrations. Use additive changes only (ADD COLUMN, CREATE TABLE)."
  fi
fi

# ── branch-guard: block direct main push/merge and --no-verify ───────────────
# Use [^&|;]* to avoid matching 'main' in a later command after && or ;.
if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+(push|merge)[[:space:]][^&|;]*\bmain\b'; then
  deny "Branch guard: never push/merge to main directly. Use a PR: gh pr create --base <default-branch>."
fi
if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit[[:space:]]+.*--no-verify'; then
  deny "Branch guard: --no-verify bypasses commit hooks. Remove the flag."
fi

exit 0
