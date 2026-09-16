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

### Claude Code not finding MCP server

**Cause:** MCP configuration not properly installed.

**Fix:**
```bash
# Verify .claude/settings.json exists
cat .claude/settings.json

# Reinstall if needed
./scripts/install.sh /path/to/project
```

### OpenCode not loading skills

**Cause:** opencode.json not in project root.

**Fix:**
```bash
# Verify opencode.json exists
cat opencode.json

# Should contain mcp.agentmemory configuration
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

**Cause:** Using agentmemory without proper project scoping.

**Fix:**
```bash
# Set project name explicitly
export AGENTMEMORY_PROJECT_NAME="MyProject"

# Or verify git repo name is correct
git rev-parse --show-toplevel | xargs basename
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

## agentmemory Issues

### agentmemory service won't start

**Cause:** Node.js not installed or wrong version.

**Fix:**
```bash
# Check Node.js version (requires >= 20.0.0)
node --version

# Install/update Node.js
# macOS:
brew install node

# Linux:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### "npx: command not found"

**Cause:** npm/npx not installed.

**Fix:**
```bash
# Install npm (comes with Node.js)
# Or install separately:
sudo apt-get install npm
```

### agentmemory health check fails

**Cause:** Service not running or wrong port.

**Fix:**
```bash
# Check if service is running
curl -fsS http://localhost:3111/agentmemory/health

# Start the service
./scripts/start.sh /path/to/project

# Check logs
cat /tmp/agentmemory.log
```

### MCP tools not available

**Cause:** MCP server not configured or not running.

**Fix:**
```bash
# Verify MCP configuration
cat .claude/settings.json | grep -A5 mcpServers

# Should contain:
# "agentmemory": {
#   "command": "npx",
#   "args": ["-y", "@agentmemory/mcp"]
# }

# Start agentmemory if not running
./scripts/start.sh /path/to/project
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

**Cause:** Too many memory files or agentmemory not optimized.

**Fix:**
```bash
# Archive old/superseded memories
# Mark old decisions as superseded in their frontmatter

# If using agentmemory, consolidate
# (requires agentmemory MCP tool: memory_consolidate)
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
