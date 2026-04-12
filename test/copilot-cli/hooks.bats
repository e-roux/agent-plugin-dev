#!/usr/bin/env bats

SCRIPTS_DIR="$BATS_TEST_DIRNAME/../../hooks/scripts"

# ── session-start.sh ──────────────────────────────────────────────────────────

@test "session-start: exits successfully" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [ "$status" -eq 0 ]
}

@test "session-start: outputs additionalContext JSON" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.additionalContext' >/dev/null
}

@test "session-start: banner mentions secrets-guard" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"secrets-guard"* ]]
}

@test "session-start: banner mentions branch-guard" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"branch-guard"* ]]
}

@test "session-start: banner mentions migration-guard" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"migration-guard"* ]]
}

@test "session-start: banner mentions no-comments-guard" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"no-comments-guard"* ]]
}

# ── pre-tool.sh: secrets-guard ────────────────────────────────────────────────

@test "secrets: allows edit of non-code file (markdown)" {
  local toolargs
  toolargs=$(jq -n '{"path":"/tmp/README.md","old_str":"old","new_str":"JWT_SECRET := \"my-secret-key-here\""}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "secrets: denies hardcoded JWT_SECRET in Go source" {
  local content
  content='JWT_SECRET := "super-secret-key-value"'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/handler.go' --arg new_str "$content" '{"path":$path,"old_str":"","new_str":$new_str}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "secrets: denies hardcoded API_KEY in TypeScript" {
  local content
  content='const API_KEY = "abcdef1234567890"'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/client.ts' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "secrets: allows test files to contain credential patterns" {
  local content
  content='JWT_SECRET := "test-secret-value-here"'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/handler_test.go' --arg new_str "$content" '{"path":$path,"old_str":"","new_str":$new_str}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── pre-tool.sh: branch-guard ─────────────────────────────────────────────────

@test "branch: allows git push to feature branch" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git push origin feat/my-feature\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "branch: denies git push to main" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git push origin main\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "branch: denies git merge main" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git merge main\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "branch: does not false-positive on git checkout -B main origin/main" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git checkout -B main origin/main\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "branch: does not false-positive on cd && git commands with main in path" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git merge --abort && git reset --hard origin/main\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "branch: denies git commit --no-verify" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git commit -m msg --no-verify\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

# ── pre-tool.sh: migration-guard ──────────────────────────────────────────────

@test "migration: allows normal SQL commands outside migrations" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"psql -c \\\"SELECT * FROM users\\\"\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "migration: denies DROP TABLE in migration command" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"psql migrations/0001.sql <<< DROP TABLE users\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "migration: denies TRUNCATE TABLE in migration path" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"cat migrations/0002.sql | grep TRUNCATE TABLE\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "migration: allows CREATE TABLE in migration" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"psql migrations/0003.sql # CREATE TABLE events\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── pre-tool.sh: no-comments-guard ───────────────────────────────────────────

@test "comments: denies // comment line in Go source" {
  local content
  content='// handleAuth processes the request'$'\n''func handleAuth() {}'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/handler.go' --arg new_str "$content" '{"path":$path,"old_str":"","new_str":$new_str}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "comments: denies /* block comment in TypeScript" {
  local content
  content='/* utility helpers */'$'\n''export function doThing() {}'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/utils.ts' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "comments: denies # comment line in Python source" {
  local content
  content='# parse the config'$'\n''def parse(f): pass'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/config.py' --arg new_str "$content" '{"path":$path,"old_str":"","new_str":$new_str}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "comments: allows shebang line in Python source" {
  local content
  content='#!/usr/bin/env python3'$'\n''def main(): pass'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/script.py' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "comments: allows test files with comment lines" {
  local content
  content='// test helper'$'\n''func TestFoo(t *testing.T) {}'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/auth_test.go' --arg new_str "$content" '{"path":$path,"old_str":"","new_str":$new_str}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "comments: allows Makefile (not a code file)" {
  local content
  content='# Makefile comment'$'\n''test:'$'\n'$'\tpytest'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "comments: allows markdown file with # headings" {
  local content
  content='# Title'$'\n''## Section'$'\n''Some text.'
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/README.md' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp); echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── pipeline-chainguard.sh ────────────────────────────────────────────────────

@test "chainguard: ignores non-bash tools" {
  local input='{"toolName":"edit","toolArgs":{"path":"/tmp/f.go","new_str":"x"},"toolResult":{"textResultForLlm":"ok","resultType":"success"}}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pipeline-chainguard.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "chainguard: ignores bash commands without git push" {
  local input='{"toolName":"bash","toolArgs":{"command":"make test"},"toolResult":{"textResultForLlm":"ok","resultType":"success"}}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pipeline-chainguard.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "chainguard: detects git push and returns additionalContext" {
  local input='{"toolName":"bash","toolArgs":{"command":"git push origin feat/ci-check"},"toolResult":{"textResultForLlm":"To github.com:user/repo.git\n abc1234..def5678 feat/ci-check -> feat/ci-check","resultType":"success"}}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pipeline-chainguard.sh'"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.additionalContext' >/dev/null
  [[ "$output" == *"Pipeline Chainguard"* ]]
}

@test "chainguard: detects failed push and warns instead of CI check" {
  local input='{"toolName":"bash","toolArgs":{"command":"git push origin feat/broken"},"toolResult":{"textResultForLlm":"error: failed to push some refs to remote","resultType":"success"}}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pipeline-chainguard.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"push FAILED"* ]]
}

@test "chainguard: detects git push without explicit remote/branch" {
  local input='{"toolName":"bash","toolArgs":{"command":"git push"},"toolResult":{"textResultForLlm":"Everything up-to-date","resultType":"success"}}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pipeline-chainguard.sh'"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.additionalContext' >/dev/null
  [[ "$output" == *"Pipeline Chainguard"* ]]
}

@test "chainguard: mentions gh run commands when gh is available" {
  if ! command -v gh &>/dev/null; then
    skip "gh CLI not installed"
  fi
  local input='{"toolName":"bash","toolArgs":{"command":"git push origin feat/test"},"toolResult":{"textResultForLlm":"pushed","resultType":"success"}}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pipeline-chainguard.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh run"* ]]
}
