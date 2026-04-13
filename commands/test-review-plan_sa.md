# /test-review-plan_sa — Test Execution, Multi-Perspective Review & Improvement Plan (Subagent-Enhanced)

You are a testing lead who orchestrates specialized subagents to produce a thorough, multi-perspective review of test results and an improvement plan — all **before writing any implementation code**.

This is the subagent-enhanced version of `/test-review-plan`. Instead of conducting all review perspectives yourself, you delegate to purpose-built agents for deeper, parallel analysis.

## Target

**$ARGUMENTS**

If no target is specified, run all tests in the project.

## Workflow

### Step 1: Discover the Next Plan Number

- Look in the `plans/` folder at the project root.
- Find existing files matching the pattern `plan.<number>.md`.
- Determine the next sequential number (start at 1 if no plans exist).
- Create the `plans/` directory if it does not exist.

### Step 2: Identify the Testing Framework and Run Tests

1. Detect the project's language, package manager, and testing framework (e.g., Jest, Vitest, pytest, Go test, xUnit, etc.).
2. Locate test configuration files and understand how tests are run.
3. Execute the full test suite. Capture the complete output — passes, failures, errors, skipped tests, timing, and coverage if available.
4. If tests require a build step first, run it.

Document the results clearly — the subagents need the test output and file context to perform their analysis.

### Step 3: Failure Analysis — Debugger Agent

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `general-purpose`
- **Role:** Debugger
- **Prompt:** Analyze the following test failures from the project's test suite. For each failing test: (1) Read the test code and the code under test. (2) Determine the root cause — is it a bug in the source code, a bug in the test, a configuration issue, or a missing dependency? (3) Group related failures by root cause — identify systemic issues causing cascading failures. (4) For each root cause, explain the dependency chain and which fix would resolve the most failures. (5) Categorize each finding as **critical** (production bugs, data loss), **warning** (significant quality/reliability issues), or **improvement** (test quality). Reference specific file paths and line numbers for every finding. The failing tests are: <include test output here>. Do NOT modify any code — analysis only.

### Step 4: Code Review — Code Reviewer Agent

**Spawn a Task subagent** (run in parallel with Steps 5, 6, and 7) with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Code Reviewer
- **Thoroughness:** very thorough
- **Prompt:** Review the code involved in the following test failures: <include list of failing test files and source files>. Focus on: (1) Correctness — off-by-one errors, null dereferences, race conditions, unhandled edge cases, logic errors, dead code paths, missing or swallowed error handling. (2) Readability — confusing naming, overly clever logic, inconsistent patterns. (3) Are the tests themselves well-written — clear names, proper assertions, appropriate mocking? Are any tests brittle or tied to implementation details? Categorize every finding as **critical**, **warning**, **improvement**, or **nit**. Reference specific file paths and line numbers. Do NOT modify any code — analysis only.

### Step 5: Security Audit — Security Auditor Agent

**Spawn a Task subagent** (run in parallel with Steps 4, 6, and 7) with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Security Auditor
- **Prompt:** Perform a security audit of the code paths exercised by the test suite, with special attention to code involved in test failures. Target: "$ARGUMENTS" (if unspecified, audit the entire project). Check for: (1) Injection risks — SQL, command, XSS, template, path traversal. Look for unsanitized user input flowing into dangerous sinks. (2) Exposed secrets — hardcoded API keys, tokens, passwords, connection strings in source or config. (3) Authentication & authorization gaps — missing auth checks, privilege escalation, insecure session handling. (4) Dependency vulnerabilities — known CVEs, outdated packages. (5) Data exposure — sensitive data in logs, verbose error messages, PII handling. (6) Security-sensitive code paths that lack test coverage. Categorize findings by severity: **critical**, **high**, **medium**, **low**. Reference specific file paths and line numbers. Do NOT modify any code — analysis only.

### Step 6: Performance Analysis — Performance Optimizer Agent

**Spawn a Task subagent** (run in parallel with Steps 4, 5, and 7) with the following configuration:
- **subagent_type:** `Explore`
- **Role:** Performance Optimizer
- **Prompt:** Analyze the performance characteristics of the code exercised by the test suite. Target: "$ARGUMENTS" (if unspecified, analyze the entire project). Pay special attention to: (1) Tests that are slow or timing out — what code paths are they exercising and why are they slow? (2) Unnecessary allocations, redundant computations, inefficient algorithms in the tested code. (3) N+1 queries, missing database indexes, unoptimized queries. (4) Blocking calls in async paths. (5) Missing caching opportunities. (6) Memory leaks or resource cleanup issues revealed by tests. Categorize findings by impact: **high**, **medium**, **low**. Reference specific file paths and line numbers. Do NOT modify any code — analysis only.

### Step 7: Test Coverage Assessment — Test Writer Agent

**Spawn a Task subagent** (run in parallel with Steps 4, 5, and 6) with the following configuration:
- **subagent_type:** `Plan`
- **Role:** Test Writer
- **Prompt:** Assess the test coverage for: "$ARGUMENTS" (if unspecified, assess the entire project). The test suite was just executed — here is a summary of the results: <include test summary>. (1) Review existing tests — identify the testing framework, conventions, file locations, and assertion style. (2) Identify untested critical paths, complex logic, and edge cases. (3) Identify brittle tests tied to implementation details or inappropriate mocks. (4) Propose specific new tests needed: unit tests (happy path, edge cases, error cases), integration tests if the code crosses module boundaries. (5) For each discovered bug or fixed failure, propose a regression test. (6) Note any mock/stub requirements. Format as a prioritized checklist. Do NOT write test code — assessment only.

### Step 8: Strategic Assessment — Tech Lead Agent

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `Plan`
- **Role:** Tech Lead
- **Prompt:** Review the findings from a multi-perspective test review of: "$ARGUMENTS". The test suite had X failures out of Y total tests. Analysis was performed by debugger, code reviewer, security auditor, performance optimizer, and test writer agents. Provide a strategic assessment: (1) Which failures and findings have the highest impact and should be addressed first? (2) Are there systemic issues (broken shared utilities, config drift, outdated mocks) causing cascading failures? (3) What's the optimal fix order to minimize risk and maximize progress — which single fix resolves the most failures? (4) Are there findings that should be deferred or accepted as technical debt? (5) Is the test infrastructure itself part of the problem (flaky CI, missing fixtures, slow setup)? Provide a prioritized action plan. Do NOT write code — strategic analysis only.

### Step 9: Synthesize the Plan Document

Combine the outputs from all agents with your own analysis. Create `plans/plan.<next number>.md` with the following structure:

```markdown
# Plan <number>: Test Review & Improvements — <Target Description>

**Created:** <today's date>
**Status:** Draft
**Type:** Test Review & Improvement Plan
**Planning Mode:** Subagent-Enhanced

## 1. Overview
<Summary of test execution results and overall assessment of test health and code quality.>

## 2. Test Execution Results
### Summary
- **Total:** X tests
- **Passed:** X
- **Failed:** X
- **Skipped:** X
- **Errored:** X
- **Coverage:** X% (if available)

### Failing Tests
| Test | File | Root Cause | Category | Agent Source |
|------|------|------------|----------|-------------|
| ... | ... | ... | Critical / Warning | Debugger |

## 3. Review Findings

### Root Cause Analysis (Debugger)
<Grouped failures by root cause. Systemic issues. Cascading failure chains.>

### Correctness & Code Quality (Code Reviewer)
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

### Performance (Performance Optimizer)
#### High Impact
- `file:line` — Issue and optimization.
#### Medium / Low Impact
- `file:line` — Issue and optimization.

### Testing Gaps (Test Writer)
<Untested paths, missing coverage, brittle tests, proposed new tests, regression tests for discovered bugs.>

## 4. Strategic Assessment (Tech Lead)
<Systemic issues, optimal fix order, cascading failure strategy, prioritization, acceptable technical debt.>

## 5. Summary Assessment
<Overall assessment across all perspectives. Top 3-5 most impactful changes.>

## 6. Improvement Plan

### Approach
<High-level strategy. Fix order: (1) systemic issues causing cascading failures, (2) critical bugs, (3) security issues, (4) individual test fixes, (5) coverage improvements, (6) test quality improvements.>

### Implementation Steps
<Ordered list of concrete tasks informed by the tech lead's prioritization.>

1. ...
2. ...
3. ...

## 7. Files to Create or Modify
| File | Action | Purpose |
|------|--------|---------|
| ... | Create / Modify | ... |

## 8. Test Strategy
<Test writer's assessment — new tests and regression tests to write, organized by type.>

- [ ] **Regression Tests (for discovered bugs):**
  - ...
- [ ] **Unit Tests:**
  - ...
- [ ] **Integration Tests:**
  - ...
- [ ] **Edge Cases & Error Scenarios:**
  - ...

## 9. Success Criteria
<How we know the improvements are done.>

- [ ] **All Tests Pass:** Every test in the suite passes (0 failures, 0 errors)
- [ ] **Critical Fixes:** All critical findings from all agents resolved
- [ ] **Security:** All security findings addressed (Section 3 — Security)
- [ ] **New Tests:** All tests from Section 8 written and passing
- [ ] **Coverage:** Test coverage improved for identified gaps
- [ ] **Performance:** No test timeout regressions
- [ ] **Quality:** Code passes linting, type-checking, and full test suite
- [ ] **No Regressions:** No previously passing tests broken

## 10. Risks & Open Questions
<Anything unresolved, informed by all agent perspectives.>

## 11. Code Review Checklist
After implementing improvements, verify:
- [ ] No dead code or unused imports introduced
- [ ] Error handling covers failure modes
- [ ] No new security vulnerabilities introduced
- [ ] Security findings from audit fully addressed
- [ ] Code follows existing project conventions
- [ ] Tests cover happy path, edge cases, and error scenarios
- [ ] No performance regressions
- [ ] All previously passing tests still pass
- [ ] New tests are not brittle or implementation-coupled
- [ ] Changes are focused — no scope creep beyond the review findings

## 12. Post-Review Improvements
<Leave this section empty. After implementation and final code review, document additional improvements here and implement them.>

## 13. Execution Prompt
<A prompt that can be given to a new Claude Code context to load and execute this plan.>
```

### Step 10: Plan Review — Code Reviewer Agent

Before finalizing, have the plan itself reviewed for completeness and consistency.

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `general-purpose`
- **Role:** Code Reviewer
- **Prompt:** Review the improvement plan at `plans/plan.<number>.md`. Check for: (1) Are the implementation steps specific enough to execute without ambiguity? (2) Are there missing steps or gaps in the sequence? (3) Does the test strategy adequately cover the findings — does every discovered bug have a regression test? (4) Are there findings from the review that don't have corresponding implementation steps? (5) Is the plan internally consistent (do files in implementation steps match the files table)? (6) Is the prioritization logical — are systemic/cascading failures addressed before individual fixes? (7) Is the success criterion "all tests pass" achievable with the proposed steps? Return specific, actionable feedback. Read-only — do NOT modify the plan file.

Incorporate the reviewer's feedback by updating the plan file.

### Step 11: Write the Execution Prompt (Section 13)

Generate a self-contained prompt that a user can paste into a fresh Claude Code session. The prompt must:

- Reference the plan file by path (`plans/plan.<number>.md`).
- Instruct Claude to read the plan, then implement the fixes and improvements step by step.
- Instruct Claude to start with systemic/cascading failures, then critical bugs, then security issues, then individual fixes, then coverage improvements.
- Instruct Claude to use subagents where beneficial during implementation:
  - Spawn a **debugger** agent to verify root cause fixes resolve cascading failures.
  - Spawn a **code-reviewer** agent (read-only: `Read, Grep, Glob`) after implementation to verify all findings are addressed.
  - Spawn a **test-writer** agent to write tests according to the test strategy in Section 8.
  - Spawn a **security-auditor** agent (read-only: `Read, Grep, Glob`) to verify all security findings from Section 3 are resolved.
- Include instructions to run the full test suite after each group of related fixes to verify progress.
- Include instructions to run the code review checklist (Section 11) after implementation.
- Include instructions to document and implement additional improvements found during the final review (Section 12).
- Remind Claude that **the plan is only complete when all tests pass**.
- Remind Claude to run existing tests and fix any regressions before finishing.

### Step 12: Present the Plan

After writing the plan file:

1. Summarize the test results and review findings for the user, highlighting insights from each agent.
2. Call out the top 3-5 most impactful improvements.
3. Provide the execution prompt so they can copy it directly.
4. Ask if they want to adjust priorities, scope, or defer any findings before execution.

## Rules

- **Do NOT write any implementation code.** This command produces a review and a plan only.
- **Maximize parallel subagent execution.** Steps 4, 5, 6, and 7 should run concurrently.
- Be specific — every finding must reference a file path and line number. Vague findings like "tests could be better" are not acceptable.
- Every success criterion that involves behavior must have a corresponding test listed.
- The plan must be actionable by someone (or a Claude session) that has no prior context.
- Do not pad the review with low-value nits. Focus on findings that materially improve test health and code quality.
- Attribute insights to their source agent so the user understands where each recommendation came from.
- **The plan is only complete when all tests pass.** This must be reflected in the success criteria and execution prompt.
