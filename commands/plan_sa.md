# /plan_sa — Research & Plan a New Feature (Subagent-Enhanced)

You are a feature planning lead who orchestrates specialized subagents to produce a thorough, multi-perspective implementation plan — all **before writing any code**.

This is the subagent-enhanced version of `/plan`. Instead of doing all research and review yourself, you delegate to purpose-built agents for deeper analysis.

## Feature to Plan

**$ARGUMENTS**

---

## MANDATORY DELIVERABLES — READ THIS FIRST

This command has exactly **three required outputs**. You are NOT done until all three are complete:

1. **A plan file written to disk** at `plans/plan.<number>.md` using the template in Step 6. You MUST use the Write tool to create this file. If you finish the conversation without having called the Write tool to create the plan file, you have failed.
2. **The plan file must include a complete Section 13 (Execution Prompt)** — a self-contained prompt the user can paste into a fresh Claude Code session. See Step 8 for the exact requirements of this prompt.
3. **A message to the user** that summarizes the plan and presents the execution prompt in a copyable format.

**Checkpoint rule:** After all subagent research is complete, STOP and verify you have the information needed. Then proceed directly to writing the plan file. Do not end your turn until the file is written and the execution prompt is presented to the user.

---

## Workflow

### Step 1: Discover the Next Plan Number

- Look in the `plans/` folder at the project root.
- Find existing files matching the pattern `plan.<number>.md`.
- Determine the next sequential number (start at 1 if no plans exist).
- Create the `plans/` directory if it does not exist.

### Step 2: High-Level Feasibility — Tech Lead Agent

Before diving into details, get a strategic gut-check.

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `Plan`
- **Role:** Tech Lead
- **Prompt:** Analyze whether the feature "$ARGUMENTS" is well-scoped for this codebase. Review the project structure, existing patterns, and architectural direction. Answer: (1) Is this the right feature to build now? (2) Are there existing abstractions we should leverage or avoid? (3) What's the riskiest part of this feature? (4) Suggest the highest-level approach (1-2 sentences). Do NOT write code — analysis only.

Incorporate the tech lead's strategic assessment into the plan.

### Step 3: Parallel Research — Architect, Security, and Test Agents

Spawn the following three subagents **in parallel** (all in a single message with three Agent tool calls):

**Agent A — Architect (Explore):**
- **subagent_type:** `Explore`
- **Thoroughness:** very thorough
- **Prompt:** Research the codebase to design an implementation for: "$ARGUMENTS". Specifically: (1) Identify all files, modules, and components related to this feature area. (2) Document the project's conventions for file structure, naming, error handling, state management, and testing. (3) Map dependencies — what will the new feature depend on, and what existing code may need to change? (4) Look for prior art — any partially implemented or related features. (5) Propose an architecture: which files to create or modify, how the feature fits into the existing system, and any key design decisions with rationale. Return structured findings — do NOT write implementation code.

**Agent B — Security Auditor (Explore):**
- **subagent_type:** `Explore`
- **Prompt:** Analyze the security implications of adding the feature "$ARGUMENTS" to this codebase. Check for: (1) Input validation gaps the feature might introduce. (2) Authentication/authorization concerns. (3) Data exposure risks. (4) Dependency risks if new packages are needed. (5) OWASP Top 10 relevance. Return a list of security considerations and requirements that should be included in the implementation plan. Read-only analysis — do NOT modify any files.

**Agent C — Test Writer (Plan):**
- **subagent_type:** `Plan`
- **Prompt:** Design a comprehensive test strategy for the feature "$ARGUMENTS". Review the existing test patterns in the codebase (test framework, file locations, naming conventions, fixtures/mocks usage). Then produce: (1) A list of unit tests needed (happy path, edge cases, error cases). (2) Integration tests if the feature crosses module boundaries. (3) Any E2E tests if the feature has user-facing behavior. (4) Specific mock/stub requirements. Format as a checklist. Do NOT write test code — strategy only.

### Step 4: Write the Plan File to Disk

**This is the most important step.** Once you have the results from Steps 2-3, you MUST immediately write the plan file using the **Write** tool.

Create `plans/plan.<next number>.md` using the template below. Fill in every section with the research gathered from the subagents. Do not leave placeholder text — every section must contain real, substantive content from the agent results.

```markdown
# Plan <number>: <Feature Title>

**Created:** <today's date>
**Status:** Draft
**Planning Mode:** Subagent-Enhanced

## 1. Overview
<Brief description of the feature and why it matters.>

## 2. Strategic Assessment
<Tech lead's feasibility analysis — is this the right thing to build, risks, high-level approach.>

## 3. Research Findings
<Architect's detailed codebase analysis — relevant files, patterns, dependencies, constraints, prior art.>

## 4. Security Considerations
<Security auditor's findings — threats, requirements, mitigations to build in from the start.>

## 5. Design

### Approach
<Chosen approach informed by architect and tech lead input. Include rationale.>

### Architecture
<How the feature fits into the existing system. Component/module relationships.>

### Key Decisions
<Non-obvious design decisions and reasoning behind each.>

## 6. Implementation Steps
<Ordered list of concrete tasks. Each step should be small and independently verifiable.>

1. ...
2. ...
3. ...

## 7. Files to Create or Modify
| File | Action | Purpose |
|------|--------|---------|
| ... | Create / Modify | ... |

## 8. Test Strategy
<Test writer's comprehensive plan — unit, integration, E2E, mocks/stubs.>

- [ ] **Unit Tests:**
  - ...
- [ ] **Integration Tests:**
  - ...
- [ ] **Edge Cases & Error Scenarios:**
  - ...

## 9. Success Criteria
<How we know the feature is done.>

- [ ] **Functional:** <what the feature must do>
- [ ] **Tests:** All tests from Section 8 pass
- [ ] **Security:** All mitigations from Section 4 implemented
- [ ] **Quality:** Code passes linting, type-checking, and existing test suite

## 10. Risks & Open Questions
<Anything unresolved or potentially problematic, informed by all agent perspectives.>

## 11. Code Review Checklist
After implementation, verify:
- [ ] No dead code or unused imports introduced
- [ ] Error handling covers failure modes
- [ ] No security vulnerabilities (injection, XSS, credential exposure)
- [ ] Security considerations from Section 4 addressed
- [ ] Code follows existing project conventions
- [ ] Tests cover happy path, edge cases, and error scenarios
- [ ] No performance regressions (unnecessary re-renders, N+1 queries, missing indexes)
- [ ] Changes are minimal — no unrelated refactoring bundled in

## 12. Post-Review Improvements
<Leave this section empty. After implementation and code review, document improvements here and implement them.>

## 13. Execution Prompt
<See Step 5 below — this section must contain the full execution prompt.>
```

### Step 5: Write the Execution Prompt into Section 13

After writing the initial plan file, use the **Edit** tool to replace the placeholder in Section 13 with a complete, self-contained execution prompt. The prompt must include ALL of the following:

1. An instruction to read the plan file by its exact path (`plans/plan.<number>.md`)
2. An instruction to implement the plan step by step, following Section 6
3. Instructions to use subagents during implementation:
   - Spawn a **code-reviewer** agent (read-only: `Read, Grep, Glob`) after implementation to review changes
   - Spawn a **test-writer** agent to write tests per the strategy in Section 8
   - Spawn a **security-auditor** agent (read-only: `Read, Grep, Glob`) to verify Section 4 mitigations
4. An instruction to run the code review checklist (Section 11) after implementation
5. An instruction to document and implement improvements in Section 12
6. A reminder to run existing tests and fix regressions before finishing

### Step 6: Review the Plan — Code Reviewer Agent

**Spawn a Task subagent** with the following configuration:
- **subagent_type:** `general-purpose`
- **Role:** Code Reviewer
- **Prompt:** Review the implementation plan at `plans/plan.<number>.md`. Check for: (1) Are the implementation steps specific enough to execute without ambiguity? (2) Are there missing steps or gaps in the sequence? (3) Does the test strategy have coverage holes? (4) Are there architectural concerns not addressed? (5) Is the plan internally consistent (do files in the implementation steps match the files table)? Return specific, actionable feedback. Read-only — do NOT modify the plan file.

Incorporate the reviewer's feedback by updating the plan file using the **Edit** tool.

### Step 7: Present the Plan to the User

**You MUST complete this step.** After the plan file is written and reviewed:

1. Summarize the plan in your message, highlighting key insights from each agent (tech lead, architect, security auditor, test writer, code reviewer).
2. **Display the full execution prompt from Section 13** in a fenced code block so the user can copy it directly.
3. Ask the user if they want to adjust anything before execution.

---

## Rules

- **Do NOT write any implementation code.** This command is planning only.
- **Maximize parallel subagent execution.** The architect, security, and test agents in Step 3 MUST run concurrently.
- Be specific in implementation steps — vague steps like "implement the feature" are not acceptable.
- Every success criterion that involves behavior must have a corresponding test listed.
- The plan must be actionable by someone (or a Claude session) that has no prior context.
- Attribute insights to their source agent so the user understands where each recommendation came from.
- **You are not done until the plan file exists on disk AND the execution prompt has been shown to the user.** If you are about to end your response, check: did you write the file? Did you show the prompt? If not, do it now.
