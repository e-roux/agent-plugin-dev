---
name: dev
description: "General-purpose development guards. Use in any project to enforce: no hardcoded secrets, no direct main pushes, no destructive SQL migrations, no --no-verify bypasses."
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

## When Guards Fire

| Guard | Tool | Condition |
|-------|------|-----------|
| secrets-guard | `edit`, `create` | Detects credential pattern in new content |
| branch-guard | `bash` | `git push/merge ... main` or `git commit --no-verify` |
| migration-guard | `bash` | SQL command on migration path with DROP/TRUNCATE/DELETE |

## Scope

These guards are **project-agnostic** — they apply to every repository in the session. They complement project-specific hooks (qa-guard, scope-guard, etc.) that live in individual project repos.
