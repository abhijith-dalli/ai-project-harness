---
name: test-driven-development
description: >
  Use when implementing new functionality or fixing bugs where test-first
  approach is required. Enforces RED-GREEN-REFACTOR cycle: write failing
  test, verify it fails, write minimal code, verify it passes, refactor.
---

# Test-Driven Development

The iron law: no production code without a failing test first. RED-GREEN-REFACTOR is not optional.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Implementing new features
- Fixing bugs (write a test that reproduces the bug first)
- When the project uses TDD
- When task requires high confidence in correctness

## Iron Law

**No production code without a failing test first.**

No exceptions. Even for "simple" tasks. If you write code before a test, delete it and start over.

## RED-GREEN-REFACTOR Cycle

### RED: Write a Failing Test
1. Write a test that describes the desired behavior
2. Run the test — it MUST fail
3. If it passes, the test is wrong — fix the test

### GREEN: Write Minimal Code
1. Write the simplest code that makes the test pass
2. No extras, no optimization, no future-proofing
3. Run the test — it MUST pass

### REFACTOR: Improve the Code
1. Clean up the code while keeping tests green
2. Extract methods, rename for clarity, remove duplication
3. Run tests after each refactor step
4. Stop refactoring when the code is clean

## Test Quality Standards

### What Makes a Good Test
- Tests behavior, not implementation
- Single assertion per test (or closely related assertions)
- Descriptive test name that explains the scenario
- Independent — no test depends on another
- Fast — completes in milliseconds

### Testing Anti-Patterns to Avoid
- **Testing implementation details** — test what, not how
- **Shared mutable state** — each test sets up its own data
- **Excessive mocking** — mock boundaries, not internals
- **Slow tests** — if a test is slow, it won't be run often
- **Brittle tests** — tests that break with harmless refactors

## Test Structure

```python
# Example: Python
def test_feature_does_X_when_Y():
    # Arrange
    input_data = setup_test_data()
    
    # Act
    result = function_under_test(input_data)
    
    # Assert
    assert result == expected_output
```

```javascript
// Example: JavaScript
describe('functionUnderTest', () => {
  it('should do X when Y', () => {
    // Arrange
    const inputData = setupTestData();
    
    // Act
    const result = functionUnderTest(inputData);
    
    // Assert
    expect(result).toEqual(expectedOutput);
  });
});
```

## Decision: Test First or Test After?

| Scenario | Approach |
|----------|----------|
| New feature | TDD — test first, always |
| Bug fix | Write failing test that reproduces bug, then fix |
| Refactoring | Tests exist already, refactor with safety net |
| Exploration | Prototype first, then delete and rewrite with TDD |
| Simple change | Still test first — it's faster than debugging later |

## Rules

1. **RED-GREEN-REFACTOR** — no skipping steps
2. **Delete code written before tests** — start over with test first
3. **One failing test at a time** — don't write multiple tests before implementing
4. **Tests are documentation** — they describe what the code should do
5. **Run tests frequently** — after every change, not just at the end
