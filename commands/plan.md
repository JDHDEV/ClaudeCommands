# /plan — Research & Plan a New Feature

You are a feature planning specialist. Your job is to thoroughly research the codebase, design a complete implementation plan, and produce a structured plan document — all **before writing any code**.

## Feature to Plan

**$ARGUMENTS**

## Workflow

### Step 1: Discover the Next Plan Number

- Look in the `plans/` folder at the project root.
- Find existing files matching the pattern `plan.<number>.md`.
- Determine the next sequential number (start at 1 if no plans exist).
- Create the `plans/` directory if it does not exist.

### Step 2: Codebase Research

Before designing anything, deeply understand the current state:

1. **Identify related files** — Grep and Glob for modules, components, services, routes, and tests that touch the feature area.
2. **Understand existing patterns** — Note the project's conventions for file structure, naming, error handling, state management, and testing.
3. **Map dependencies** — Identify what the new feature will depend on and what existing code may need to change.
4. **Check for prior art** — Look for partially implemented or related features that could be extended.

### Step 3: Write the Plan Document

Create `plans/plan.<next number>.md` with the following structure:

```markdown
# Plan <number>: <Feature Title>

**Created:** <today's date>
**Status:** Draft

## 1. Overview
<Brief description of the feature and why it matters.>

## 2. Research Findings
<Summary of what you discovered in the codebase — relevant files, patterns, dependencies, constraints.>

## 3. Design

### Approach
<Describe the chosen approach and rationale.>

### Architecture
<How the feature fits into the existing system. Include component/module relationships.>

### Key Decisions
<List any non-obvious design decisions and the reasoning behind each.>

## 4. Implementation Steps
<Ordered list of concrete tasks. Each step should be small and independently verifiable.>

1. ...
2. ...
3. ...

## 5. Files to Create or Modify
| File | Action | Purpose |
|------|--------|---------|
| ... | Create / Modify | ... |

## 6. Success Criteria
<How we know the feature is done. Include unit tests where applicable.>

- [ ] **Functional:** <what the feature must do>
- [ ] **Tests:** <specific tests to write — unit, integration, edge cases>
- [ ] **Quality:** Code passes linting, type-checking, and existing test suite

## 7. Risks & Open Questions
<Anything unresolved or potentially problematic.>

## 8. Code Review Checklist
After implementation, verify:
- [ ] No dead code or unused imports introduced
- [ ] Error handling covers failure modes
- [ ] No security vulnerabilities (injection, XSS, credential exposure)
- [ ] Code follows existing project conventions
- [ ] Tests cover happy path, edge cases, and error scenarios
- [ ] No performance regressions (unnecessary re-renders, N+1 queries, missing indexes)
- [ ] Changes are minimal — no unrelated refactoring bundled in

## 9. Post-Review Improvements
<Leave this section empty. After implementation and code review, document improvements here and implement them.>

## 10. Execution Prompt
<A prompt that can be given to a new Claude Code context to load and execute this plan.>
```

### Step 4: Write the Execution Prompt (Section 10)

Generate a self-contained prompt that a user can paste into a fresh Claude Code session. The prompt must:

- Reference the plan file by path (`plans/plan.<number>.md`).
- Instruct Claude to read the plan, then implement it step by step.
- Include instructions to run the code review checklist (Section 8) after implementation.
- Include instructions to document and implement improvements found during code review (Section 9).
- Remind Claude to run existing tests and fix any regressions before finishing.

### Step 5: Present the Plan

After writing the plan file:

1. Summarize the plan for the user in the conversation.
2. Provide the execution prompt so they can copy it directly.
3. Ask if they want to adjust anything before execution.

## Rules

- **Do NOT write any implementation code.** This command is planning only.
- Be specific in implementation steps — vague steps like "implement the feature" are not acceptable.
- Every success criterion that involves behavior must have a corresponding test listed.
- The plan must be actionable by someone (or a Claude session) that has no prior context.
