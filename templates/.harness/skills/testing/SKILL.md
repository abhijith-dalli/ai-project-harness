---
name: testing
description: >
  Use when creating, improving, or reviewing test suites. Covers unit
  tests, integration tests, end-to-end tests, test organization,
  coverage analysis, and testing strategy.
---

# Testing

Comprehensive testing strategy covering unit, integration, and end-to-end tests. Focus on testing behavior, not implementation.

## When to Use

- Creating a new test suite
- Improving test coverage
- Reviewing test quality
- Setting up test infrastructure
- Investigating flaky tests

## Testing Pyramid

```
        /\
       /  \        E2E Tests (few, slow, high confidence)
      /    \
     /------\      Integration Tests (moderate, medium speed)
    /        \
   /----------\    Unit Tests (many, fast, focused)
```

### Unit Tests
- Test individual functions/methods in isolation
- Fast execution (milliseconds)
- Mock external dependencies
- High coverage target (80%+)

### Integration Tests
- Test component interactions
- Moderate execution (seconds)
- Use real databases/services where practical
- Test data flow between components

### End-to-End Tests
- Test complete user workflows
- Slow execution (minutes)
- Use real environments
- Critical paths only

## Test Organization

### File Structure
```
tests/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── integration/
│   ├── api/
│   └── database/
└── e2e/
    └── workflows/
```

### Naming Conventions
- Test files: `*_test.py`, `*.test.js`, `*.spec.ts`
- Test functions: `test_describe_scenario`, `it('should do X when Y')`
- Test classes: `TestFeatureName`, `describe('FeatureName')`

## Coverage Strategy

### What to Cover
- All public APIs
- Business logic
- Edge cases and error paths
- Boundary conditions

### What NOT to Cover
- Framework boilerplate
- Simple getters/setters
- Third-party library internals
- Configuration files

## Flaky Test Management

### Detection
- Run tests multiple times in CI
- Track pass/fail rates per test
- Flag tests with <100% pass rate

### Resolution
- Identify root cause (timing, ordering, external dependency)
- Fix the test, not the symptom
- Quarantine unfixable flaky tests
- Delete tests that can't be made reliable

## Rules

1. **Test behavior, not implementation** — tests should survive refactors
2. **One assertion per test** — keep tests focused
3. **Tests are documentation** — they show how the code should be used
4. **Fast feedback** — unit tests in milliseconds, not minutes
5. **Deterministic** — same test, same result, every time
