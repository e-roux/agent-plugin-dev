---
name: dev
description: "General-purpose development guards. Use in any project to enforce: no hardcoded secrets, no direct main pushes, no destructive SQL migrations, no --no-verify bypasses, and self-documenting code (no comments)."
---

# Dev Guards Skill

General-purpose hooks that protect any project, regardless of language or toolchain.

## Active Guards

### 1. Secrets Guard

**Never hardcode credentials in source files.**

```go
// ✗ Forbidden
JWT_SECRET := "my-super-secret-key-here"

// ✓ Correct
JWT_SECRET := os.Getenv("JWT_SECRET")
```

Applies to: all code files except tests, templates, and markdown.

### 2. Branch Guard

**Never push or merge directly to `main`.**

```bash
# ✗ Forbidden
git push origin main
git merge main

# ✓ Correct
gh pr create --base main
```

Also blocks `git commit --no-verify` which bypasses hooks.

### 3. Migration Guard

**SQL migrations are additive only — no destructive statements.**

```sql
-- ✗ Forbidden in migration files
DROP TABLE users;
TRUNCATE TABLE events;
DELETE FROM calibrations;

-- ✓ Correct
ALTER TABLE users ADD COLUMN display_name TEXT;
CREATE TABLE new_feature (...);
```

Fires when a bash command touches files matching `migrations?/` or `*.sql`.

### 4. No-Comments Guard

**Code must be self-documenting — no comment lines in source files.**

Rationale: comments can conflict with code, and that makes the LLM confused about which to follow.
Code executes; a comment can say something different. Removing conflicting information improves reliability.
Source: [AMPECO Infinite Engineer](https://p.ampeco.com/infinite-engineer/infinite-engineer)

```go
// ✗ Forbidden
// handleAuth processes the authentication request
func handleAuth(r *http.Request) error {

// ✓ Correct — the name is the documentation
func processAuthenticationRequest(r *http.Request) error {
```

```python
# ✗ Forbidden
# parse the config file
def p(f):

# ✓ Correct
def parse_config_file(path: str) -> Config:
```

Applies to: `.go`, `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.rs`, `.java`, `.c`, `.cpp`, `.h`, `.cs`, `.rb`, `.swift`, `.kt` files.
Does NOT apply to: test files, Makefiles, shell scripts, config files (`.json`, `.yaml`, `.toml`), markdown.
Shebang lines (`#!/`) are always allowed.

## When Guards Fire

| Guard | Tool | Condition |
|-------|------|-----------|
| secrets-guard | `edit`, `create` | Detects credential pattern in new content |
| no-comments-guard | `edit`, `create` | Detects comment lines (`//`, `/*`, `#`) in code files |
| branch-guard | `bash` | `git push/merge ... main` or `git commit --no-verify` |
| migration-guard | `bash` | SQL command on migration path with DROP/TRUNCATE/DELETE |

## Scope

These guards are **project-agnostic** — they apply to every repository in the session.
They complement project-specific hooks (qa-guard, scope-guard, etc.) that live in individual project repos.
