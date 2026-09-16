# Troubleshooting

Common issues and solutions for the AI Project Harness.

## Installation Issues

### "Target project does not exist"

**Cause:** The path provided to install.sh doesn't exist.

**Fix:**
```bash
# Verify the path exists
ls -la /path/to/project

# Use absolute path
./scripts/install.sh /absolute/path/to/project
```

### "Not a Git repository"

**Warning, not error.** The harness works without Git, but memory isolation uses directory name instead of repo name.

**Fix:**
```bash
cd /path/to/project
git init
```

### "Permission denied" on scripts

**Cause:** Scripts are not executable.

**Fix:**
```bash
chmod +x scripts/*.sh
```

## Provider Adapter Issues

### Claude Code not finding configuration

**Cause:** .claude/ not properly installed.

**Fix:**
```bash
# Verify .claude/settings.json exists
cat .claude/settings.json

# Reinstall if needed
./scripts/install.sh /path/to/project
```

### OpenCode not loading skills

**Cause:** opencode.json not in project root or AGENTS.md missing.

**Fix:**
```bash
# Verify files exist
cat opencode.json
cat .opencode/AGENTS.md
```

### Cursor hooks not firing

**Cause:** .cursor/hooks.json not installed.

**Fix:**
```bash
# Enable Cursor during install
./scripts/install.sh /path/to/project --enable-cursor

# Or manually copy
cp templates/.cursor/* .cursor/
```

## Memory Issues

### Memory files not found

**Cause:** Memory directories not created.

**Fix:**
```bash
# Create memory structure
mkdir -p .harness/memory/shared/{project,decisions,lessons,observations}
mkdir -p .harness/memory/local/sessions
```

### Memory leaking between projects

**Cause:** Each project should have its own `.harness/memory/` directory.

**Fix:** Verify each project has its own `.harness/memory/`:
```bash
ls -la /path/to/ProjectA/.harness/memory/
ls -la /path/to/ProjectB/.harness/memory/
```

### Shared memory not committed

**Cause:** .gitignore includes .harness/memory/shared/

**Fix:**
```bash
# Check .gitignore
grep -n "harness/memory" .gitignore

# Should only ignore local/, not shared/
# Remove .harness/memory/shared/ from .gitignore if present
```

## Script Issues

### doctor.sh shows failures

**Run the full diagnostic:**
```bash
./scripts/doctor.sh /path/to/project
```

Common failures:
- Missing .harness/ → run install.sh
- Missing agents/skills → run install.sh
- Missing provider adapters → run install.sh with flags
- Git not initialized → run git init

### update.sh not updating

**Cause:** Files were customized (different from template).

**Behavior:** update.sh preserves customized files and only updates unchanged files. This is by design.

**Fix:** Review the warnings and manually update if needed, or delete the customized file and re-run update.

## Performance Issues

### Slow memory recall

**Cause:** Too many memory files.

**Fix:**
```bash
# Archive old/superseded memories
# Mark old decisions as superseded in their frontmatter
```

### Context window overflow

**Cause:** Too much memory loaded into context.

**Fix:**
- Use more specific search queries
- Archive old memories
- Use the context-management skill to prioritize

## Getting More Help

1. Run `./scripts/doctor.sh /path/to/project` for diagnostics
2. Run `./scripts/status.sh /path/to/project` for current state
3. Check `docs/` for architecture and usage details
4. Open an issue on the GitHub repository
