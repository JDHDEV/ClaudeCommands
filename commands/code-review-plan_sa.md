# /code-review-plan_sa — Multi-Perspective Code Review & Improvement Plan (Subagent-Enhanced)

You are a code review lead who orchestrates specialized subagents to produce a thorough, multi-perspective code review and improvement plan — all **before writing any implementation code**.

This is the subagent-enhanced version of `/code-review-plan`. Instead of conducting all review perspectives yourself, you delegate to purpose-built agents for deeper, parallel analysis.

## Target

**$ARGUMENTS**

If no target is specified, review the project as a whole.

## Workflow

### Step 1: Discover the Next Plan Number

- Look in the `plans/` folder at the project root.
- Find existing files matching the pattern `plan.<number>.md`.
- Determine the next sequential number (start at 1 if no plans exist).
- Create the `plans/` directory if it does not exist.

### Step 2: Scope the Review

Determine what to review based on the target:

1. **If a specific file, folder, or component is specified** — Focus the review on that area and its immediate dependencies.
2. **If the target is broad or unspecified** — Survey the entire project structure. Identify the most critical areas (core business logic, public API surface, security-sensitive code, complex modules) and prioritize them.

Document the scope clearly — the subagents need to know what to review.

### Step 3: Code Review — Code Reviewer Agent

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Code Reviewer
- **Thoroughness:** very thorough
- **Prompt:** Conduct a thorough code review of: "$ARGUMENTS" (if unspecified, review the entire project). Focus on: (1) Correctness — off-by-one errors, null dereferences, race conditions, unhandled edge cases, logic errors, dead code paths, missing or swallowed error handling. (2) Readability — confusing naming, overly clever logic, inconsistent patterns, code duplication. (3) Style & Consistency — adherence to project conventions and patterns. Categorize every finding as **critical**, **warning**, **improvement**, or **nit**. Reference specific file paths and line numbers for every finding. Do NOT modify any code — analysis only.

### Step 4: Security Audit — Security Auditor Agent

**Spawn a Task subagent** (run in parallel with Steps 3, 5, and 6) with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Security Auditor
- **Prompt:** Perform a security audit of: "$ARGUMENTS" (if unspecified, audit the entire project). Check for: (1) Injection risks — SQL, command, XSS, template, path traversal. Look for unsanitized user input flowing into dangerous sinks. (2) Exposed secrets — hardcoded API keys, tokens, passwords, connection strings in source or config. (3) Authentication & authorization gaps — missing auth checks, privilege escalation, insecure session handling. (4) Dependency vulnerabilities — known CVEs, outdated packages, typosquatting risks. (5) Configuration security — debug mode in production, permissive CORS, missing security headers. (6) Data exposure — sensitive data in logs, verbose error messages, PII handling. Categorize findings by severity: **critical**, **high**, **medium**, **low**. Reference specific file paths and line numbers. Do NOT modify any code — analysis only.

### Step 5: Architecture Review — Architect Agent

**Spawn a Task subagent** (run in parallel with Steps 3, 4, and 6) with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Architect
- **Thoroughness:** very thorough
- **Prompt:** Review the architecture of: "$ARGUMENTS" (if unspecified, review the entire project). Evaluate: (1) Component boundaries and separation of concerns. (2) Abstractions — are they at the right level? Too generic? Too specific? (3) Coupling and dependency direction. Identify circular dependencies. (4) Patterns — are the right patterns in use? Are there anti-patterns? (5) Scalability — will the current design hold under growth? Where are the bottlenecks? (6) Maintainability — can a new developer understand this quickly? Where is accidental complexity? Provide specific recommendations for structural improvements. Reference file paths. Do NOT modify any code — analysis only.

### Step 6: Performance Analysis — Performance Optimizer Agent

**Spawn a Task subagent** (run in parallel with Steps 3, 4, and 5) with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Performance Optimizer
- **Prompt:** Analyze the performance characteristics of: "$ARGUMENTS" (if unspecified, analyze the entire project). Look for: (1) Unnecessary allocations, redundant computations, inefficient algorithms. (2) N+1 queries, missing database indexes, unoptimized queries. (3) Blocking calls in async paths. (4) Missing caching opportunities. (5) Unnecessary re-renders, large bundle concerns, lazy loading opportunities (if frontend). (6) Memory leaks or resource cleanup issues. Categorize findings by impact: **high**, **medium**, **low**. Reference specific file paths and line numbers. Do NOT modify any code — analysis only.

### Step 7: Test Coverage Assessment — Test Writer Agent

**Spawn a Task subagent** (can run after Steps 3-6, or in parallel if scope is clear) with the following configuration:
- **subagent_type:** `Plan`
- **Role:** Test Writer
- **Prompt:** Assess the test coverage for: "$ARGUMENTS" (if unspecified, assess the entire project). (1) Review existing tests — identify the testing framework, conventions, file locations, and assertion style. (2) Identify untested critical paths, complex logic, and edge cases. (3) Identify brittle tests tied to implementation details or inappropriate mocks. (4) Propose specific new tests needed: unit tests (happy path, edge cases, error cases), integration tests if the code crosses module boundaries, and E2E tests for user-facing behavior. (5) Note any mock/stub requirements. Format as a prioritized checklist. Do NOT write test code — assessment only.

### Step 8: Strategic Assessment — Tech Lead Agent

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `Plan`
- **Role:** Tech Lead
- **Prompt:** Review the findings from a multi-perspective code review of: "$ARGUMENTS". The review covered correctness, security, architecture, performance, and testing. Provide a strategic assessment: (1) Which findings have the highest impact and should be addressed first? (2) Are there systemic issues that indicate a deeper architectural problem? (3) Is there over-engineering or under-engineering? (4) What's the recommended order of remediation to minimize risk and maximize value? (5) Are there any findings that should be deferred or intentionally accepted as technical debt? Provide a prioritized action plan. Do NOT write code — strategic analysis only.

### Step 9: Synthesize the Plan Document

Combine the outputs from all agents with your own analysis. Create `plans/plan.<next number>.md` with the following structure:

```markdown
# Plan <number>: Code Review & Improvements — <Target Description>

**Created:** <today's date>
**Status:** Draft
**Type:** Code Review & Improvement Plan
**Planning Mode:** Subagent-Enhanced

## 1. Overview
<What was reviewed, scope, and overall assessment of code health.>

## 2. Review Findings

### Correctness & Logic (Code Reviewer)
#### Critical
- `file:line` — Description of the issue.
#### Warnings
- `file:line` — Description.
#### Improvements
- `file:line` — Description.

### Security (Security Auditor)
#### Critical
- `file:line` — Vulnerability, impact, and remediation.
#### High
- `file:line` — Description and remediation.
#### Medium / Low
- `file:line` — Description and remediation.

### Architecture (Architect)
<Structural findings, anti-patterns, coupling issues, and recommendations.>

### Performance (Performance Optimizer)
#### High Impact
- `file:line` — Issue and optimization.
#### Medium / Low Impact
- `file:line` — Issue and optimization.

### Testing Gaps (Test Writer)
<Untested paths, missing coverage, brittle tests, proposed new tests.>

## 3. Strategic Assessment (Tech Lead)
<Systemic issues, prioritization, recommended remediation order, acceptable technical debt.>

## 4. Summary Assessment
<Overall code quality assessment across all perspectives. Highlight the top 3-5 most impactful changes.>

## 5. Improvement Plan

### Approach
<High-level strategy for addressing findings. Group related fixes. Order by priority: critical bugs and security first, then architectural improvements, then performance, then quality.>

### Implementation Steps
<Ordered list of concrete tasks informed by the tech lead's prioritization.>

1. ...
2. ...
3. ...

## 6. Files to Create or Modify
| File | Action | Purpose |
|------|--------|---------|
| ... | Create / Modify | ... |

## 7. Test Strategy
<Test writer's assessment — new tests to write, organized by type.>

- [ ] **Unit Tests:**
  - ...
- [ ] **Integration Tests:**
  - ...
- [ ] **Edge Cases & Error Scenarios:**
  - ...

## 8. Success Criteria
<How we know the improvements are done.>

- [ ] **Critical Fixes:** All critical findings from all agents resolved
- [ ] **Security:** All security findings addressed (Section 2 — Security)
- [ ] **Tests:** All tests from Section 7 written and passing
- [ ] **Performance:** Performance improvements verified where applicable
- [ ] **Quality:** Code passes linting, type-checking, and existing test suite
- [ ] **No Regressions:** All existing tests still pass

## 9. Risks & Open Questions
<Anything unresolved, informed by all agent perspectives.>

## 10. Code Review Checklist
After implementing improvements, verify:
- [ ] No dead code or unused imports introduced
- [ ] Error handling covers failure modes
- [ ] No new security vulnerabilities introduced
- [ ] Security findings from audit fully addressed
- [ ] Code follows existing project conventions
- [ ] Tests cover happy path, edge cases, and error scenarios
- [ ] No performance regressions
- [ ] Architectural improvements maintain backward compatibility
- [ ] Changes are focused — no scope creep beyond the review findings

## 11. Post-Review Improvements
<Leave this section empty. After implementation and final code review, document additional improvements here and implement them.>

## 12. Execution Prompt
<A prompt that can be given to a new Claude Code context to load and execute this plan.>
```

### Step 10: Plan Review — Code Reviewer Agent

Before finalizing, have the plan itself reviewed for completeness and consistency.

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `general-purpose`
- **Role:** Code Reviewer
- **Prompt:** Review the improvement plan at `plans/plan.<number>.md`. Check for: (1) Are the implementation steps specific enough to execute without ambiguity? (2) Are there missing steps or gaps in the sequence? (3) Does the test strategy adequately cover the findings? (4) Are there findings from the review that don't have corresponding implementation steps? (5) Is the plan internally consistent (do files in implementation steps match the files table)? (6) Is the prioritization logical — are critical fixes truly first? Return specific, actionable feedback. Read-only — do NOT modify the plan file.

Incorporate the reviewer's feedback by updating the plan file.

### Step 11: Write the Execution Prompt (Section 12)

Generate a self-contained prompt that a user can paste into a fresh Claude Code session. The prompt must:

- Reference the plan file by path (`plans/plan.<number>.md`).
- Instruct Claude to read the plan, then implement the fixes and improvements step by step.
- Instruct Claude to start with critical findings, then work down by priority.
- Instruct Claude to use subagents where beneficial during implementation:
  - Spawn a **code-reviewer** agent (read-only: `Read, Grep, Glob`) after implementation to verify all findings are addressed.
  - Spawn a **test-writer** agent to write tests according to the test strategy in Section 7.
  - Spawn a **security-auditor** agent (read-only: `Read, Grep, Glob`) to verify all security findings from Section 2 are resolved.
- Include instructions to run the code review checklist (Section 10) after implementation.
- Include instructions to document and implement additional improvements found during the final review (Section 11).
- Remind Claude to run existing tests and fix any regressions before finishing.

### Step 12: Present the Plan

After writing the plan file:

1. Summarize the review findings for the user, highlighting insights from each agent.
2. Call out the top 3-5 most impactful improvements.
3. Provide the execution prompt so they can copy it directly.
4. Ask if they want to adjust priorities, scope, or defer any findings before execution.

## Rules

- **Do NOT write any implementation code.** This command produces a review and a plan only.
- **Maximize parallel subagent execution.** Steps 3, 4, 5, and 6 should run concurrently.
- Be specific — every finding must reference a file path and line number. Vague findings like "code could be better" are not acceptable.
- Every success criterion that involves behavior must have a corresponding test listed.
- The plan must be actionable by someone (or a Claude session) that has no prior context.
- Do not pad the review with low-value nits. Focus on findings that materially improve code quality.
- Attribute insights to their source agent so the user understands where each recommendation came from.
