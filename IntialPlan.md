Let me search for the latest information on Claude Code's command system and agent capabilities.Here's a comprehensive breakdown of useful Claude Code commands and agent specializations for your development cycle:

---

## Recommended Slash Commands (Skills)

### 🔄 Git & Code Management
| Command | Purpose |
|---|---|
| `/commit` | Smart commit — reviews diffs for TODOs, test flags, commented-out code, then stages and commits with a generated message. The message will not mention Claude |
| `/pr` | Creates a PR: branches, commits, formats, writes description from diff context |
| `/catchup` | Reads all uncommitted git changes into the current conversation (great after `/clear`) |
| `/review` | Runs a multi-perspective code review on staged or recent changes |
| `/merge-check` | Validates a branch is safe to merge (conflicts, CI status, review approvals) |

### 🏗️ Feature Development
| Command | Purpose |
|---|---|
| `/plan <feature>` | Research & Plan New Feature Implementation. Instruct claude to save this to a plans folder in the root, increasing the plan number with each new plan. The file name format is plan.<plan number>.md, example plan.2.md. Instruct claude to include unit tests where applicable in the Success Criteria portion of the planning. The plan should include a final code review and an attempt to implement the improvements found in the code review. Then finally have claude generate a prompt I can give to a new context to load and execute the plan. Claude will do all of this before writing any code. |
| `/scaffold <type>` | Generates boilerplate for API routes, components, services, etc., auto-detecting your stack |
| `/refactor <file>` | Analyzes and refactors for readability, DRY, clean code principles |
| `/fix <issue-number>` | Reads a GitHub issue and implements the fix with tests |
| `/tdd <feature>` | Writes failing tests first, then implements until they pass |

### 🔍 Analysis & Quality
| Command | Purpose |
|---|---|
| `/security-scan` | SAST analysis — injection risks, exposed credentials, insecure configs |
| `/perf-audit <file>` | Profiles for performance bottlenecks, N+1 queries, memory leaks |
| `/type-check` | Runs the type checker and fixes all errors |
| `/lint-fix` | Runs linter + formatter, then auto-fixes violations |
| `/dep-check` | Audits dependencies for vulnerabilities, outdated versions, license issues |
| `/test-review-plan` | Runs all of the unit tests and run multi-perspective review on test results, then create a plan to fix and improve all of the issues found. Instruct claude to save this to a plans folder in the root, increasing the plan number with each new plan. The file name format is plan.<plan number>.md, example plan.2.md. Instruct claude to include unit tests where applicable in the Success Criteria portion of the planning. The plan should include a final code review and an attempt to implement the improvements found in the code review. The plan is only complete when all tests pass. Then finally have claude generate a prompt I can give to a new context to load and execute the plan. Claude will do all of this before writing any code. |
| `/code-review-plan` | Runs a multi-perspective code review on specific components or the project as a whole, then create a plan to fix and improve the issues found. Instruct claude to save this to a plans folder in the root, increasing the plan number with each new plan. The file name format is plan.<plan number>.md, example plan.2.md. Instruct claude to include unit tests where applicable in the Success Criteria portion of the planning. The plan should include a final code review and an attempt to implement the improvements found in the code review. Then finally have claude generate a prompt I can give to a new context to load and execute the plan. Claude will do all of this before writing any code. |

### 📖 Documentation & Communication
| Command | Purpose |
|---|---|
| `/doc <file>` | Generates/updates JSDoc, docstrings, or inline comments for a file |
| `/changelog` | Generates a changelog entry from recent commits |
| `/explain <file>` | Produces an explanation with analogies, ASCII diagrams, and gotchas |
| `/adr <decision>` | Creates an Architecture Decision Record with context, options, and rationale |

### 🧹 Housekeeping
| Command | Purpose |
|---|---|
| `/clean` | Finds dead code, unused imports, orphaned files across the project |
| `/migrate <from> <to>` | Generates a migration plan (e.g., database schema, framework version) |
| `/env-check` | Validates `.env` files, missing vars, and config consistency across environments |

---

## Recommended Agent Specializations

These go in `.claude/agents/` (project-level) or `~/.claude/agents/` (global). Each is a markdown file with YAML frontmatter controlling tools, model, and system prompt.

### Core Development Agents

| Agent | Tools | Purpose |
|---|---|---|
| **code-reviewer** | `Read, Grep, Glob` (read-only) | Reviews diffs for bugs, security issues, style violations. Opinionated and critical — never modifies code |
| **debugger** | `Read, Edit, Bash, Grep, Glob` | Root-cause analysis specialist. Reads stack traces, forms hypotheses, adds strategic logging, implements minimal fixes |
| **architect** | `Read, Grep, Glob, WebSearch` | Evaluates design decisions, suggests patterns, reviews system structure. Thinks in tradeoffs, not absolutes |
| **test-writer** | `Read, Write, Edit, Bash, Glob, Grep` | Writes unit/integration/e2e tests. Focuses on edge cases, mocks, and coverage gaps |

### Infrastructure & Operations Agents

| Agent | Tools | Purpose |
|---|---|---|
| **devops-engineer** | `Read, Write, Edit, Bash, Glob, Grep` | Docker, CI/CD pipelines, Kubernetes configs, deployment scripts. Knows your pipeline and can debug config drift |
| **database-architect** | `Read, Write, Edit, Bash, Grep` | Schema design, migration writing, query optimization, indexing strategy |
| **security-auditor** | `Read, Grep, Glob` (read-only) | Dependency scanning, secret detection, OWASP checks. Reports findings without changing code |

### Specialized Domain Agents

| Agent | Tools | Purpose |
|---|---|---|
| **frontend-specialist** | `Read, Write, Edit, Bash, Glob, Grep` | Component architecture, accessibility, responsive design, performance (Core Web Vitals) |
| **api-designer** | `Read, Write, Edit, Grep, Glob` | REST/GraphQL schema design, versioning strategy, request/response contracts, OpenAPI specs |
| **performance-optimizer** | `Read, Edit, Bash, Grep, Glob` | Profiling, query tuning, caching strategies, bundle analysis, lazy loading |
| **documentation-writer** | `Read, Write, Edit, Glob, Grep, WebSearch` | READMEs, API docs, architecture guides, onboarding docs. Researches context before writing |

### Quality & Process Agents

| Agent | Tools | Purpose |
|---|---|---|
| **tech-lead** | `Read, Grep, Glob, WebSearch` | High-level review: "Should we even build this? Is this the right abstraction?" Challenges assumptions |
| **release-manager** | `Read, Bash, Grep, Glob` | Validates release readiness: changelog, version bumps, migration safety, rollback plan |

---

## Key Design Principles

**For commands:** Keep them as codified workflows — the prompt should capture your team's actual process (commit standards, review checklist, etc.) rather than being a generic instruction. Use `$ARGUMENTS` (or `$1`, `$2`) for parameterization.

**For agents:** The critical differentiators are tool restrictions (a reviewer should never have `Write` or `Edit`), focused system prompts (be specific and opinionated), and model routing (use `model: sonnet` for cheaper exploratory agents, `model: inherit` or `model: opus` for high-stakes ones like architecture review).

**A good starting set** would be 3–4 agents max (code-reviewer, debugger, test-writer, and one domain specialist matching your stack) plus 4–5 commands for your most repetitive workflows (commit, review, plan, scaffold). Expand from there as patterns emerge.

Want me to generate the actual markdown files for any of these so you can drop them straight into your `.claude/` directory?