---
name: brainstorming
description: >
  Use before writing any code to refine rough ideas through questions,
  explore alternatives, and present design in sections for validation.
  Three paths: spike (feasibility), bounded (well-scoped), architectural (new subsystem).
---

# Brainstorming

Refine rough ideas through questions, explore alternatives, and present design in sections for validation. This skill ensures you understand what to build before you build it.

**Adapted from obra/superpowers (MIT License).**

## When to Use

- Before writing any code
- When requirements are unclear
- When multiple approaches exist
- When the task is non-trivial

## Three Classification Paths

### Spike (Feasibility)
- Quick feasibility question
- 2-3 sentence probe plan
- Report findings, no implementation

### Bounded (Well-Scoped)
- Change to existing code
- Short design in chat
- Approval gate, then implement directly
- No formal spec needed

### Architectural (New Subsystem)
- New project or major subsystem
- Full process with 2-3 approaches
- Sectioned design presentation
- Written spec required

## Process

### 1. Understand the Request
- What is the user trying to achieve?
- What are the constraints?
- What is the scope?

### 2. Explore Alternatives
- What are 2-3 possible approaches?
- What are the trade-offs of each?
- What does the existing codebase suggest?

### 3. Present Design
- Present in sections for validation
- Include diagrams where helpful
- Be explicit about trade-offs
- Get approval before proceeding

### 4. Save Design Document
- Save to `.harness/memory/shared/decisions/`
- Include date, alternatives considered, and rationale

## Design Presentation Format

```markdown
# Design: [Feature Name]

## Problem Statement
What are we solving and why?

## Approach A: [Name]
### Description
How it works.

### Pros
- advantage 1
- advantage 2

### Cons
- disadvantage 1
- disadvantage 2

## Approach B: [Name]
### Description
How it works.

### Pros
- advantage 1
- advantage 2

### Cons
- disadvantage 1
- disadvantage 2

## Recommendation
Which approach and why.

## Open Questions
- question 1
- question 2
```

## Self-Review

After presenting design:
- [ ] Placeholder scan — no "TBD" or "TODO" in the design
- [ ] Internal consistency — approaches don't contradict each other
- [ ] Scope check — design matches the original request
- [ ] Ambiguity check — nothing could be interpreted multiple ways

## Rules

1. **Approval gate is NEVER skipped** — even trivial tasks need a short design presented
2. **Explore before you commit** — consider alternatives
3. **Be explicit about trade-offs** — don't hide downsides
4. **Present in sections** — let the user validate incrementally
5. **Save important designs** — to project memory for future reference
