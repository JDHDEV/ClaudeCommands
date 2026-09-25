# Skill & Agent Library — Roadmap

**Updated:** 2026-07-13 — revised for the Claude 5 family (Fable 5). The original catalog is preserved below with build status; new sections cover capabilities that did not exist when this plan was first written and how to exploit them.

> **Format note (2026-07-13, plan.2):** everything in this library that users invoke via `/name` is a **skill** — `skills/<version>/<name>/SKILL.md` (current version: `skills/Fable-5.1/`; `skills/Fable-5/` is the frozen snapshot), mirrored to `.claude/skills/<name>/SKILL.md`. The original `commands/*.md` format is retired. Every planned item below (`/scaffold`, `/migrate`, `/pr`, `/doc`, `/parallel-fix`, …) is to be built as `skills/Fable-5.1/<name>/SKILL.md`, validated by `scripts/validate-skills.ps1`. Agents follow the same versioning: agents/<version>/<name>.md (current version: agents/Fable-5.1/), mirrored to .claude/agents/<name>.md.

## Status Snapshot

**Built** (in this repo today):

- **Skills (7):** `/plan`, `/plan_sa`, `/commit`, `/code-review-plan`, `/code-review-plan_sa`, `/test-review-plan`, `/test-review-plan_sa`
- **Agents (16, canonical: agents/Fable-5.1/):** code-reviewer, debugger, architect, test-writer, devops-engineer, database-architect, security-auditor, frontend-specialist, api-designer, performance-optimizer, documentation-writer, tech-lead, release-manager, adversarial-verifier, workflow-author, taskmaster

**The `_sa` convention:** each `_sa` skill is the subagent-enhanced variant of its base skill — it orchestrates parallel specialist agents instead of doing everything in one context. As of plan.2 the `_sa` skills spawn the real named agents (with graceful fallback to generic types); Phase 3 below upgrades the choreography further with the Workflow tool.

---

## 1. Fable-Era Capabilities to Build On

These are the harness capabilities that change how this library should be designed. Every planned skill/agent below references them.

### 1.1 Model tiers & routing

The Claude 5 family adds `fable` as a model value above `opus`. Updated routing guidance for agent frontmatter and orchestration calls:

| Tier | Use for |
|---|---|
| `haiku` | Mechanical work: scaffolding, formatting, changelog generation, bulk transforms |
| `sonnet` | Exploratory research, codebase mapping, first-pass reviews |
| `opus` | High-stakes single-perspective analysis: architecture review, security audit |
| `fable` | Orchestration leads, adversarial verification, synthesis across many agent outputs, the hardest debugging |
| `inherit` | Default when the agent should match the session's model |

Reasoning **effort** is now tunable per agent invocation (`low` → `max`). Cheap mechanical stages get `low`; final verify/judge stages get `high`+. Encode this in skill prompts, not just agent frontmatter.

The **taskmaster** agent (§3) applies this table to a concrete spawn set at runtime and returns a model tier (and the effort that goes with it) per spawn, starting from each agent's frontmatter default; the frontmatter model remains the default whenever no routing call is made.

### 1.2 Subagent upgrades

- **Background by default** — spawned agents run concurrently without blocking; fan out independent research in a single message.
- **SendMessage continuation** — a spawned agent keeps its context and can be continued across turns. Skills can now define *persistent specialists* (e.g., a debugger that holds the investigation state across a whole session) instead of fire-and-forget lookups.
- **Worktree isolation** (`isolation: worktree`) — an agent gets its own git worktree, auto-cleaned if unchanged. This unlocks skills where multiple agents *edit files in parallel* without conflicts (migrations, parallel fixes).
- **Remote/cloud agents** (`isolation: remote`) and **scheduled routines** (cron-driven cloud agents) — recurring audits no longer need a human to invoke them.

### 1.3 Workflow orchestration

The Workflow tool runs deterministic multi-agent scripts: `pipeline()` / `parallel()` fan-out, JSON-schema-validated structured outputs from each agent, and proven quality patterns (adversarial verify, judge panels, loop-until-dry). This replaces the hand-rolled "spawn three agents and hope" choreography in the `_sa` skills with:

- **Structured outputs** — agents return validated JSON, not prose to re-parse.
- **Adversarial verification** — every finding gets N independent skeptics prompted to refute it before it reaches the plan document. Kills plausible-but-wrong findings.
- **Judge panels** — generate N independent designs from different angles, score them, synthesize from the winner.
- **Loop-until-dry** — for unknown-size discovery (dead code, flaky tests), keep spawning finders until consecutive rounds return nothing new.

Workflows are opt-in (user says "use a workflow" or the invoking skill instructs it) — skill files that want orchestration should say so explicitly in their prompt.

### 1.4 Built-in skills — don't duplicate them

Claude Code now ships skills that overlap with parts of the original catalog. Custom skills should **wrap or defer to** these, adding only team-specific process:

| Built-in | Supersedes / absorbs |
|---|---|
| `/code-review` (effort levels low→max, plus `ultra` multi-agent cloud review) | planned `/review` |
| `/security-review` | planned `/security-scan` core |
| `/review <PR#>` | PR review half of `/merge-check` |
| `/simplify` | part of `/refactor` |
| `/verify` | end-to-end verification step in `/commit`, `/fix`, `/tdd` |
| `/run` | app-launching steps in any skill |

### 1.5 Automation surfaces beyond skills

- **Hooks** — deterministic automation the model can't forget: auto-lint/format on edit, permission gating, command rewriting. Better fit than skills for `/lint-fix`, `/type-check`, `/env-check`-style checks.
- **Scheduled routines** — nightly/weekly cloud runs for `/dep-check`, security scans, test-health reports.
- **`/loop`** — recurring local tasks (poll CI, babysit a deploy).
- **Persistent memory** — cross-session facts directory; `/catchup`-style skills should write durable project state there, not just re-read diffs.
- **AskUserQuestion** — structured clarifying questions with option previews; planning skills should use it to resolve scope ambiguity *before* research instead of guessing.
- **Artifacts** — private shareable web pages; audit/review/explain skills can publish a report or diagram instead of dumping walls of terminal text.

---

## 2. Skill Catalog

Status legend: ✅ built · 🔲 planned · 🔁 superseded by a built-in (build only a thin team wrapper, if anything)

All items below, built and planned, live as `skills/Fable-5.1/<name>/SKILL.md` (see the format note at the top).

### 🔄 Git & Code Management

| Skill | Status | Purpose & Fable-era notes |
|---|---|---|
| `/commit` | ✅ | Smart commit — reviews diffs for TODOs, test flags, commented-out code, then stages and commits with a generated message (no Claude attribution). **Upgrade:** invoke `/verify` before committing nontrivial changes. *(plan.4: verify step — recommends `/verify`, else a confirmed manifest test command; commit message passed as data)* |
| `/pr` | 🔲 | Creates a PR: branches, commits, formats, writes description from diff context via `gh`. |
| `/catchup` | 🔲 | Rebuilds context after `/clear`: uncommitted changes + recent commits + **persistent memory** of in-flight work. Should also *write* a session-state memory so the next catchup is richer. |
| `/review` | 🔁 | Use built-in `/code-review` (choose effort level; `ultra` for branch-wide multi-agent review). Custom wrapper only if team checklist items emerge that the built-in misses. |
| `/merge-check` | 🔲 | Validates a branch is safe to merge. **Upgrade:** fan out background agents in parallel — one on conflicts, one on CI status (`gh`), one on review approvals — and merge the verdicts. |

### 🏗️ Feature Development

| Skill | Status | Purpose & Fable-era notes |
|---|---|---|
| `/plan <feature>` | ✅ | Research & plan before writing code; saves `plans/plan.<n>.md` with success criteria (incl. unit tests), a post-implementation code-review pass, and a self-contained execution prompt for a fresh context. *(plan.4: AskUserQuestion for scope; Summary block; `plans/plan.<n>.diagram.html` above a complexity threshold)* |
| `/plan_sa <feature>` | ✅ | Subagent-enhanced `/plan` (tech-lead gut-check, parallel architect/security/test research, reviewer pass). **Phase 3 upgrade:** AskUserQuestion for scope ambiguity up front; judge panel (2–3 independent designs, scored, synthesized) for wide solution spaces; structured outputs instead of prose hand-offs; `fable` for the synthesis step. *(plan.4: AskUserQuestion, structured returns, taskmaster routing, Summary + diagram done; judge panel and fable synthesis deferred to the Workflow pass)* |
| `/scaffold <type>` | 🔲 | Boilerplate for routes, components, services — auto-detects stack. Route to `haiku`, effort `low`. |
| `/refactor <file>` | 🔲 | Defer quality cleanups to built-in `/simplify`; custom skill adds structural refactors (extract module, invert dependency) that `/simplify` won't attempt. Verify with `/verify` after. |
| `/fix <issue-number>` | 🔲 | Reads a GitHub issue (`gh issue view`), implements the fix with tests, runs `/verify`, links the issue in the commit. |
| `/tdd <feature>` | 🔲 | Failing tests first, then implement until green. **Upgrade:** test-writer agent authors tests; implementation loops until the suite passes; a read-only reviewer confirms the tests actually constrain the behavior (no vacuous passes). |
| `/parallel-fix <issue list>` | 🔲 **new** | Takes N independent issues/failures and fixes them concurrently — one worktree-isolated agent per fix, then merges and runs the full suite. Only possible with `isolation: worktree`. |

### 🔍 Analysis & Quality

| Skill | Status | Purpose & Fable-era notes |
|---|---|---|
| `/security-scan` | 🔁 | Use built-in `/security-review` interactively. Custom value-add: a **scheduled routine** running it nightly on main and filing findings as issues. |
| `/perf-audit <file>` | 🔲 | Bottlenecks, N+1 queries, memory leaks. Pair with performance-optimizer agent; publish results as an **Artifact** when the audit is repo-wide. |
| `/type-check` | 🔁→hook | Better as a PostToolUse/pre-commit **hook** than a skill — deterministic, can't be forgotten. |
| `/lint-fix` | 🔁→hook | Same: auto-format on edit via hook. |
| `/dep-check` | 🔲 | Vulnerabilities, outdated versions, licenses. Primary form: **weekly scheduled routine** with a summary report; skill form for on-demand runs. |
| `/test-review-plan` | ✅ | Run all unit tests, multi-perspective review of results, produce numbered fix plan (`plans/plan.<n>.md`) with execution prompt; plan complete only when all tests pass. |
| `/test-review-plan_sa` | ✅ | Subagent variant. **Phase 3 upgrade:** Workflow pipeline — run suite once, fan out one analysis agent *per failure cluster* with structured output (root cause, fix, affected files), adversarially verify root causes before they enter the plan. *(plan.4: per-cluster debugger fan-out with structured output, gate widened to security/performance findings, taskmaster routing; Workflow pipeline deferred)* |
| `/code-review-plan` | ✅ | Multi-perspective review of components or whole project → numbered fix plan with execution prompt. |
| `/code-review-plan_sa` | ✅ | Subagent variant. **Phase 3 upgrade:** the canonical Workflow review shape — dimension finders (bugs/security/perf/tests) → dedup → adversarial verify (majority-refute kills a finding) → synthesize plan. Fewer false findings in plans means less wasted execution time. *(plan.4: structured finder output, dedup, widened gate, taskmaster routing; majority-refute and Workflow deferred)* |

### 📖 Documentation & Communication

| Skill | Status | Purpose & Fable-era notes |
|---|---|---|
| `/doc <file>` | 🔲 | JSDoc/docstrings/inline comments. `haiku` or `sonnet`, effort `low`. |
| `/changelog` | 🔲 | Changelog entry from recent commits. `haiku`. |
| `/explain <file>` | 🔲 | Explanation with analogies and diagrams. **Upgrade:** publish as an **Artifact** with real rendered diagrams instead of ASCII when the topic warrants it. |
| `/adr <decision>` | 🔲 | Architecture Decision Record. **Upgrade:** optional judge panel — N agents argue for different options, ADR records the genuine trade-offs rather than post-hoc rationale. |

### 🧹 Housekeeping

| Skill | Status | Purpose & Fable-era notes |
|---|---|---|
| `/clean` | 🔲 | Dead code, unused imports, orphaned files. **Upgrade:** loop-until-dry finder pattern — keep spawning finders until two consecutive rounds surface nothing new; simple single-pass scans miss the tail. |
| `/migrate <from> <to>` | 🔲 | Migration plan + execution. **Upgrade:** the canonical Workflow migration — discover all sites → transform each in worktree-isolated agents → verify — turns week-long migrations into one supervised run. |
| `/env-check` | 🔁→hook | Validate `.env` consistency as a SessionStart hook or scheduled check rather than a manual skill. |

---

## 3. Agent Catalog

All 15 agents are ✅ built; the current canonical set is agents/Fable-5.1/ (16 with taskmaster), while agents/Fable-5/ is the frozen Fable-5-authored snapshot and is no longer mirrored or validated. Updated model routing (was: "sonnet for cheap, opus for high-stakes"):

### Core Development

| Agent | Tools | Model | Purpose |
|---|---|---|---|
| **code-reviewer** | `Read, Grep, Glob` (read-only) | sonnet | First-pass diff review: bugs, security, style. Opinionated, never modifies code |
| **debugger** | `Read, Edit, Bash, Grep, Glob` | inherit | Root-cause analysis. **Upgrade:** designed for SendMessage continuation — one debugger holds the investigation across a session instead of restarting cold each spawn |
| **architect** | `Read, Grep, Glob, WebSearch` | opus | Design decisions, patterns, system structure. Thinks in trade-offs |
| **test-writer** | `Read, Write, Edit, Bash, Glob, Grep` | sonnet | Unit/integration/e2e tests, edge cases, coverage gaps |

### Infrastructure & Operations

| Agent | Tools | Model | Purpose |
|---|---|---|---|
| **devops-engineer** | `Read, Write, Edit, Bash, Glob, Grep` | sonnet | Docker, CI/CD, K8s, deployment scripts |
| **database-architect** | `Read, Write, Edit, Bash, Grep` | opus | Schema design, migrations, query optimization, indexing |
| **security-auditor** | `Read, Grep, Glob` (read-only) | opus | Dependency scanning, secret detection, OWASP. Reports without changing code |

### Specialized Domain

| Agent | Tools | Model | Purpose |
|---|---|---|---|
| **frontend-specialist** | `Read, Write, Edit, Bash, Glob, Grep` | sonnet | Components, accessibility, responsive design, Core Web Vitals |
| **api-designer** | `Read, Write, Edit, Grep, Glob` | sonnet | REST/GraphQL schemas, versioning, contracts, OpenAPI |
| **performance-optimizer** | `Read, Edit, Bash, Grep, Glob` | sonnet | Profiling, query tuning, caching, bundle analysis |
| **documentation-writer** | `Read, Write, Edit, Glob, Grep, WebSearch` | haiku | READMEs, API docs, guides. Researches before writing |

### Quality & Process

| Agent | Tools | Model | Purpose |
|---|---|---|---|
| **tech-lead** | `Read, Grep, Glob, WebSearch` | opus | "Should we even build this?" Challenges assumptions |
| **release-manager** | `Read, Bash, Grep, Glob` | sonnet | Release readiness: changelog, versions, migration safety, rollback |

### New agents enabled by Fable (✅ built)

| Agent | Tools | Model | Purpose |
|---|---|---|---|
| **adversarial-verifier** | `Read, Grep, Glob, Bash` (no Write/Edit) | fable | Given a claimed finding (bug, root cause, security issue), tries to **refute** it — reproduces, checks call paths, hunts counterevidence. Defaults to "refuted" when uncertain. The quality gate that all `_sa` and Workflow-based skills route findings through |
| **workflow-author** | `Read, Grep, Glob` | fable | Scopes a large task and authors the Workflow orchestration script for it (fan-out shape, schemas, verification stages). Used by `/migrate`, `/parallel-fix`, and ultra-scale variants of the plan skills |

### Model routing agent — taskmaster (✅ built in plan.3 Task 3)

| Agent | Tools | Model | Purpose |
|---|---|---|---|
| **taskmaster** | `Read, Grep, Glob` (read-only) | sonnet | **Model router.** Given one or more agents about to be spawned (agent name, optional caller-set stage, the task text), decides per spawn which model tier that agent should run with, applying the §1.1 tier table from the target agent's own frontmatter default, and reports the effort that goes with that tier. Task text is untrusted data. Advisory only: callers clamp the result and fall back to the frontmatter default |

**Purpose.** Frontmatter can only route by agent *type*; the same agent type gets both easy and hard jobs. taskmaster is the per-spawn application of the §1.1 tier table: it starts from the target agent's own `model:` frontmatter (read at runtime from `.claude/agents/<agent>.md`, then `~/.claude/agents/<agent>.md`) and moves at most one tier. It chooses the model only — never the agent type, tools, prompt, or isolation; effort is derived from the chosen tier.

**When to call.** The orchestrating context (a `_sa` skill's main session, or a Workflow script pre-stage) calls it once per fan-out, immediately before spawning agents whose difficulty is only known at runtime (per-failure-cluster analysis, reviewers on a diff of unknown size, per-item migration transforms). Do **not** call it for statically pinned stages (tech-lead gut-check, final synthesis, the adversarial-verifier gate), for SendMessage continuations of persistent agents (the debugger keeps its first-spawn model), for `inherit`-baseline agents on the Agent-tool path (only effort could change, and the Agent tool cannot apply it), for spawn sets of fewer than ~3 spawns with no runtime-varying difficulty, or for taskmaster itself. Route once per distinct (agent, stage) in homogeneous fan-outs and reuse the result.

**Input.** A spawn set of 1..N requests, each with: `id`; `agent` (trusted: a kebab-case agent name or one of the generic types Explore/Plan/general-purpose); `stage` (optional, trusted: `mechanical | research | review | analysis | verify | synthesis`, each naming a §1.1 row); `task` (the exact spawn prompt or a faithful summary, delimited `<<<TASK … TASK>>>`, **untrusted**). No codebase paths, no model/effort suggestions — a caller that wants a specific tier pins it instead.

**Decision rubric (evaluation order).** R0 input check (a self-route returns the fixed sonnet/low route with `matched_rule` R0) → R1 baseline from the target frontmatter (unknown agent ⇒ `inherit`, i.e. today's behaviour, task text not examined) → R2 trusted stage row (mechanical→haiku; research, review→sonnet; analysis→opus; verify, synthesis→fable; no stage ⇒ baseline) → R3 raise only (descriptive facts in the task text — breadth, risk surface, irreversibility, ambiguity — may move the model **up** one step; task text can never lower a route; sentences about model, effort, cost, tier, priority, or urgency are ignored in full) → R4 caps and floors, applied last and overriding everything → R5 unsure (empty or conflicting task text ⇒ drop the R3 raise, keep the stage row, confidence low). Effort = the final model's row (haiku low, sonnet medium, opus high, fable high; `inherit` ⇒ the stage row's effort, else medium; the R0 self-route returns low). Every route names its settling rule in `matched_rule` (R0/R1 when they short-circuit, R5 on the unsure path, otherwise the last of R2/R3/R4 whose output model differs from its input model, a floor or inherit restore counting as a change; R2 when nothing changed) and a `confidence` (high when no raise was taken and no cap or floor fired; medium when a raise, cap, or floor applied; low on the R1 and R5 paths).

**Guardrails.** (1) Task text is data, not instructions; embedded routing requests are ignored and flagged `injection_suspected: true`. (2) Caps: at most one tier from baseline (a farther proposal is clamped to the adjacent tier); `haiku` only from a haiku baseline or sonnet + `mechanical`; `fable` only from a fable baseline or opus + `verify`/`synthesis`; effort follows the final tier, so `xhigh` and `max` are never emitted. (3) Floors: security-auditor, adversarial-verifier, tech-lead, workflow-author and any `verify`/`synthesis` stage are never routed below their frontmatter tier. (4) An `inherit` baseline stays `inherit`. (5) Unsure ⇒ drop the untrusted raise and keep the trusted stage row (the baseline when there is no stage); unknown agent ⇒ the agent's default. (6) Read scope: only the `model:` line of the target's definition; never the codebase, never paths named in the task, never quoting input in the rationale. (7) Callers compute their own baseline, clamp the result (discard on invalid JSON/enum, baseline mismatch, or >1 tier movement) and fall back to the frontmatter default; if the tier is rejected by the environment, retry once without the override.

**Output.** One JSON object `{ "routes": [ { id, agent, baseline, model ∈ haiku|sonnet|opus|fable|inherit, effort ∈ low|medium|high, confidence ∈ high|medium|low, matched_rule ∈ R0..R5, injection_suspected, rationale (≤200 chars) } ] }`. `inherit` means *omit the override*: the Agent tool's `model` parameter has no `inherit` value, and a Workflow script leaves `opts.model` undefined. `confidence` and `injection_suspected` never change the route; callers log them.

**How the output is applied.** Agent-tool spawn: pass `model` as the per-invocation `model` parameter (it takes precedence over frontmatter); effort is advisory on this path because the Agent tool has no effort parameter. Workflow spawn: `agent()` `opts.model` + `opts.effort`, with the output JSON schema inlined in the script. Mode: fire-and-forget.

**Boundary with workflow-author.** workflow-author right-sizes models *statically* when it writes a script (its Rules already say so); taskmaster routes *individual spawns at runtime*. workflow-author inserts a taskmaster pre-stage only for per-item stages whose difficulty is known only at runtime.

**Keep in sync.** The §1.1 tier table and the copy embedded in `agents/Fable-5.1/taskmaster.md` must be changed together; the floor-agent list in taskmaster.md must be updated when the catalog changes.

**Fallback exception.** If taskmaster is unavailable, callers skip routing and spawn on frontmatter defaults — they do **not** fall back to a generic type (a generic router would cost a spawn to reproduce a safe default that is already known). This is a deliberate exception to the generic-fallback convention in CLAUDE.md.

---

## 4. Roadmap

**Phase 1 — Core library** ✅ *done*
13 agents + the plan/commit/review-plan workflows (with `_sa` variants), originally in the `commands/` format.

**Phase 2 — Consolidate & modernize metadata**
- ✅ Add frontmatter (`description`, argument hints) so everything surfaces correctly as skills. *(Done in plan.2, 2026-07-13: all 7 workflows fully converted to `skills/<name>/SKILL.md` + `.claude/skills/` install copies with `name`/`description`/`argument-hint`/`disable-model-invocation: true` frontmatter and an `### Argument Safety` guardrail; the old `commands/` and `.claude/commands/` trees are deleted. `scripts/validate-skills.ps1` + its meta-test guard the format, mirror parity, and named-agent delegation.)*
- Drop planned skills superseded by built-ins (`/review`, core `/security-scan`); document the built-in mapping in [guide.md](guide.md).
- Convert `/lint-fix`, `/type-check`, `/env-check` concepts into example **hook** configurations (new `hooks/` directory with drop-in `settings.json` snippets).
- ✅ Update the 13 agent files with the model routing table above. *(Done in plan.1: added `name`/`description` frontmatter to all 13, applied the four reroutes — security-auditor→opus, database-architect→opus, documentation-writer→haiku, debugger→inherit — and appended a Subagent Contract to each. A `scripts/validate-agents.ps1` structural validator now guards the whole library.)*

**Phase 3 — Fable orchestration upgrades**
- ✅ Add **adversarial-verifier** and **workflow-author** agents. *(Done in plan.1, both `model: fable`, read-only.)*
- ✅ Upgrade the three `_sa` skills to delegate to the real specialized agents. *(Done in plan.2, 2026-07-13: every spawn in `plan_sa`, `test-review-plan_sa`, `code-review-plan_sa` now names the specialized agent — tech-lead, architect, security-auditor, code-reviewer, test-writer, debugger, performance-optimizer — with a graceful fallback clause to Explore/Plan/general-purpose; adversarial-verifier gates Critical/Warning findings and claimed root causes; conditional domain routing added for database-architect, api-designer, frontend-specialist, devops-engineer.)*
- ✅ **Fable-5.1 agent pass** *(plan.3: agents copied to agents/Fable-5.1/, per-agent enhancements traced to the §3 purpose column, taskmaster built; validators and install docs repointed; agents/Fable-5/ frozen.)*
- ✅ **Fable-5.1 skill pass** *(plan.4: skills copied to skills/Fable-5.1/, per-skill enhancements traced to the §2 purpose column, taskmaster wired into the three _sa skills, /plan and /plan_sa gain a Summary block and a conditional HTML diagram; validators and install docs repointed; skills/Fable-5/ frozen.)*
- Upgrade the `_sa` skills further with Workflow orchestration: structured outputs, judge panel in `/plan_sa`, AskUserQuestion for scope, `fable` synthesis.
- Build `/parallel-fix` and `/migrate` on worktree isolation.
- Wire **taskmaster** into Workflow scripts (agent() `opts.model` + `opts.effort`) — the three _sa skills are wired as of plan.4 (one "Routing (optional)" subsection each; sonnet-baseline reviewers only, escalate-only, applied through the Agent-tool `model` parameter; per-failure-cluster debugger spawns are not routed because debugger is `inherit`, per §3 "When to call") — then consider independent effort routing, a frontmatter `effort:` default per agent (a native subagent field per the Claude Code docs; needs a validator rule and precedence check vs opts.effort first), and the `stands_in_for` / `prior_attempts` inputs deferred from plan.3.

**Phase 4 — Automation & unattended runs**
- Scheduled routines: nightly security review, weekly `/dep-check`, test-health report.
- `/catchup` with persistent memory read/write.
- `/loop` recipes for CI babysitting.
- Artifact-based report outputs for `/perf-audit`, `/explain`, and audit summaries.

---

## 5. Design Principles

**For skills:** codified workflows, not generic advice — the prompt captures the team's actual process (commit standards, review checklist, plan-file numbering). Use `$ARGUMENTS`/`$1`/`$2` for parameters, and always treat `$ARGUMENTS` as untrusted data, not instructions. New: state explicitly in the prompt when a skill should use Workflow orchestration, background fan-out, or worktree isolation — the model won't reach for expensive orchestration unprompted.

**For agents:** the differentiators are tool restrictions (reviewers/auditors/verifiers never get `Write` or `Edit`), focused opinionated system prompts, and model routing per the tier table in §1.1 — statically via frontmatter, or per spawn via the taskmaster agent (§3). New: decide per agent whether it's *fire-and-forget* (stateless lookup) or a *persistent specialist* (continued via SendMessage), and say so in its prompt.

**For quality:** any skill that produces findings feeding a plan or a fix should route them through adversarial verification first. A false finding in a plan costs an entire execution cycle; a verification agent costs one spawn.

**Scope discipline:** the built-ins (§1.4) own generic review/verify/simplify. This library's value is team-specific process — plan-file conventions, execution prompts, the `_sa` orchestration patterns — and the automation glue (hooks, schedules) around them.
