---
name: git-workflow
description: >
  Use when managing git branches, worktrees, commits, and merges.
  Covers branch strategy, worktree isolation, commit conventions,
  and finishing development branches.
---

# Git Workflow

Branch management, worktree isolation, commit conventions, and finishing development branches safely.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Starting new feature work
- Managing multiple parallel features
- Preparing code for review/merge
- Finishing a development branch
- Resolving merge conflicts

## Branch Strategy

### Branch Types
- `main` — stable, always deployable
- `feature/*` — new features
- `fix/*` — bug fixes
- `refactor/*` — code restructuring
- `test/*` — test additions/improvements

### Branch Naming
```
feature/user-authentication
fix/login-redirect
refactor/extract-service-layer
test/add-integration-tests
```

## Git Worktrees

### Why Use Worktrees
- Work on multiple features simultaneously
- Keep main branch clean
- Isolate experimental work
- Avoid stashing changes

### Creating a Worktree
```bash
# Create worktree for a feature
git worktree add ../project-feature-name -b feature/feature-name

# List worktrees
git worktree list

# Remove worktree when done
git worktree remove ../project-feature-name
```

### Worktree Rules
1. **One worktree per feature** — don't mix concerns
2. **Clean up when done** — remove worktrees after merge
3. **Don't commit to main from worktrees** — merge properly
4. **Run setup in each worktree** — dependencies may differ

## Commit Conventions

### Commit Message Format
```
<type>: <description>

<body>

<footer>
```

### Types
- `feat` — new feature
- `fix` — bug fix
- `refactor` — code restructuring
- `test` — adding tests
- `docs` — documentation
- `chore` — maintenance

### Good Commit Messages
```
feat: add user authentication

Implement JWT-based authentication with login, logout, and
token refresh. Includes middleware for protected routes.

Closes #123
```

### Bad Commit Messages
```
fix stuff
wip
updates
```

## Finishing a Development Branch

### Step 1: Verify
```bash
# Run full test suite
npm test

# Check for lint errors
npm run lint

# Verify no TODO/FIXME left
grep -r "TODO\|FIXME" src/
```

### Step 2: Clean Up
```bash
# Remove debug code
git diff --name-only | xargs grep -l "console.log\|debugger" | xargs sed -i '/console.log\|debugger/d'

# Stage all changes
git add -A

# Commit with clear message
git commit -m "feat: complete feature description"
```

### Step 3: Merge or PR
```bash
# Option A: Merge locally
git checkout main
git merge feature/feature-name
git push

# Option B: Create PR
git push -u origin feature/feature-name
# Create PR via GitHub/GitLab

# Option C: Keep as-is (experimental)
# Leave branch for future reference
```

### Step 4: Cleanup
```bash
# Delete merged branch
git branch -d feature/feature-name
git push origin --delete feature/feature-name

# Remove worktree if used
git worktree remove ../project-feature-name
```

## Rules

1. **Never commit directly to main** — always use branches
2. **One feature per branch** — don't mix concerns
3. **Clean commits** — meaningful messages, logical grouping
4. **Verify before merge** — tests pass, no regressions
5. **Clean up after merge** — remove branches and worktrees
