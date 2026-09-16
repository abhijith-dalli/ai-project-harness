---
name: codebase-exploration
description: >
  Use when you need to understand existing code before making changes.
  Structured approach to exploring codebases — trace behavior, identify
  patterns, map dependencies, and report findings with evidence.
---

# Codebase Exploration

Structured approach to understanding existing code before making changes. Trace behavior, identify patterns, map dependencies, and report findings with evidence.

## When to Use

- Before modifying existing code
- When investigating a bug
- When onboarding to a new codebase
- When planning a refactoring
- When reviewing unfamiliar code

## Exploration Process

### Phase 1: Orientation

1. **Read project structure** — understand the directory layout
2. **Read project context** — `.harness/project-context.md`
3. **Read memory** — decisions, lessons, observations
4. **Identify entry points** — where does execution start?
5. **Understand the stack** — languages, frameworks, databases

### Phase 2: Tracing

1. **Follow the data** — trace data flow through the system
2. **Follow the control** — trace execution flow
3. **Identify boundaries** — where does one module end and another begin?
4. **Find public APIs** — what is exposed to consumers?
5. **Find internal APIs** — what is the internal contract?

### Phase 3: Pattern Analysis

1. **Identify coding patterns** — how is code structured?
2. **Identify naming conventions** — what naming patterns are used?
3. **Identify error handling** — how are errors handled?
4. **Identify testing patterns** — how are tests structured?
5. **Identify configuration** — how is the app configured?

### Phase 4: Dependency Mapping

1. **Map imports** — what depends on what?
2. **Map module relationships** — which modules interact?
3. **Map external dependencies** — what libraries are used?
4. **Map configuration dependencies** — what env vars are needed?
5. **Map data dependencies** — what data flows where?

## Exploration Tools

### File Discovery

```
# Find files by pattern
glob: "**/*.py"
glob: "**/test_*.py"

# Find files containing patterns
grep: "def handle_request"
grep: "import.*database"
```

### Code Reading

- Read files in context (not just snippets)
- Follow imports to understand dependencies
- Check test files for usage examples
- Read documentation for design intent

### Evidence Collection

- Collect file paths and line numbers for every finding
- Note the direction of dependencies (A depends on B)
- Record timestamps for time-sensitive information
- Verify claims by reading actual code

## Output Format

```yaml
exploration:
  task: "what was explored"
  project_overview:
    language: "Python"
    framework: "Flask"
    database: "PostgreSQL"
    entry_point: "app.py:main"
  findings:
    - file: "app/routes.py"
      line: 42
      description: "handles POST /api/users"
    - file: "app/models.py"
      line: 15
      description: "User model with email validation"
  patterns:
    - "All routes follow REST conventions"
    - "Error handling uses custom exceptions"
    - "Database queries use SQLAlchemy ORM"
  dependencies:
    - "routes.py depends on models.py"
    - "models.py depends on database.py"
  affected_files:
    - "files that would be affected by the proposed change"
  risks:
    - "potential complication identified"
```

## Rules

1. **Be thorough** — check edge cases, error handling, related code
2. **Be evidence-based** — file paths and line numbers for every claim
3. **Be honest** — if you can't find something, say so
4. **Don't modify** — exploration is read-only
5. **Document findings** — save important discoveries to memory
6. **Respect conventions** — note patterns without judging them
