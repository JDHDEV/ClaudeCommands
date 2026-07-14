# Plan 1: Fable-Era Upgrade of All Subagent Definitions

**Created:** 2026-07-13
**Status:** Draft

## 1. Overview

Upgrade the 13 existing subagent definitions in `agents/` to the Fable-era design described in [IntialPlan.md](../IntialPlan.md) (§1 and §3), and add the two new Fable-enabled agents (**adversarial-verifier**, **workflow-author**). The upgrade delivers: discoverable frontmatter (`name` + `description` for auto-delegation), corrected model routing per the §1.1 tier table, an explicit subagent contract in every prompt (structured return values, fire-and-forget vs persistent designation), per-agent Fable enhancements (SendMessage-persistent debugger, judge-panel participation, adversarial-verification handoffs), and a validation script so the whole library stays structurally correct as it grows.

## 2. Research Findings

**Current agent inventory (13 files in `agents/`):** code-reviewer, debugger, architect, test-writer, devops-engineer, database-architect, security-auditor, frontend-specialist, api-designer, performance-optimizer, documentation-writer, tech-lead, release-manager.

**Frontmatter state:** Every agent file has only `tools:` (YAML list) and `model:`. **None has `name:` or `description:`** — but Claude Code uses `description` to decide when to auto-delegate to a subagent, so today these agents are only usable when explicitly named. This is the single biggest functional gap.

**Current model routing:** `architect` and `tech-lead` are `opus`; all other 11 are `sonnet`. IntialPlan §1.1/§3 calls for four reroutes: security-auditor → `opus`, database-architect → `opus`, documentation-writer → `haiku`, debugger → `inherit`.

**Tool restrictions:** Already correct and match the IntialPlan §3 tables. Read-only agents (code-reviewer, security-auditor, tech-lead, architect) have no `Write`/`Edit`; release-manager has `Bash` but no `Write`/`Edit`. `database-architect` intentionally lacks `Glob` (uses `Grep`).

**Prompt structure convention:** Every agent follows: role paragraph → `## Rules` → one domain section (`## Review Checklist` / `## Areas of Focus` / `## Approach` / etc.) → `## Output Format`. Upgrades must preserve this shape and append rather than restructure.

**Duplicate install:** `.claude/agents/` contains copies of all 13 agents (this is the live project-level install — the repo's own commands load from `.claude/commands/`). Any change to `agents/` must be synced to `.claude/agents/` or the live install silently diverges. (`.claude/commands/` is also missing `test-review-plan.md` and `test-review-plan_sa.md` — out of scope here, logged in §7.)

**No test infrastructure exists** — no `plans/` folder, no scripts, no CI. Validation must be introduced by this plan.

## 3. Design

### Approach

Three layers of change, applied uniformly then per-agent:

1. **Frontmatter layer (all 15 agents):** add `name:` (matching filename) and `description:` (delegation-trigger phrasing: what it does + when to use it + "read-only" where true). Apply the four model reroutes. Keep existing `tools:` lists untouched.
2. **Contract layer (all 15 agents):** append a short `## Subagent Contract` section stating: (a) the final message is a return value consumed by an orchestrating agent, not a human — return complete structured findings, never questions or offers; (b) the agent's mode — **fire-and-forget** (stateless, one-shot) or **persistent** (expects SendMessage continuation; must carry investigation state forward in each reply).
3. **Fable-enhancement layer (per-agent):** targeted additions from IntialPlan §3 (table below).

New agents get full files following the existing structural convention.

A PowerShell validation script enforces the structure so future agents can't regress (this is the "unit test" for a markdown-config repo).

### Architecture

`agents/` remains the canonical, portable library. `.claude/agents/` is the local install, updated by copy as the final implementation step. The validation script lives in `scripts/` and checks both directories, including that they are in sync for agent files.

### Key Decisions

- **`description` phrasing is delegation-critical.** Descriptions are written as "Use when/after …" trigger sentences, not marketing copy — Claude Code matches tasks against them. Read-only agents say "read-only" in the description so orchestrators don't route write-work to them.
- **`model: fable` for the two new agents, verified at implementation time.** The Fable tier is specified in IntialPlan §1.1, but if the installed CLI rejects `fable` as a frontmatter value, fall back to `model: inherit` (the session model is Fable-class anyway) and note it in §9.
- **Effort guidance goes in prose, not frontmatter.** There is no standard `effort:` frontmatter key; per-agent effort expectations ("this is a low-effort mechanical agent" / "maximize rigor") are written into the system prompt instead.
- **Only `debugger` is persistent.** Everything else is fire-and-forget. Persistence is expensive to design for (state summarization each turn); IntialPlan §3 designates only the debugger.
- **Append, don't rewrite.** Existing Rules/Checklist/Output Format sections are proven; upgrades add sections and frontmatter keys. Diffs stay reviewable.

### Per-Agent Change Matrix

| Agent | Model | Fable enhancement (beyond frontmatter + contract) |
|---|---|---|
| code-reviewer | sonnet (keep) | Findings must carry evidence for downstream adversarial verification: each item gets `file:line`, severity, and a concrete failure scenario (inputs → wrong behavior), not just an opinion |
| debugger | sonnet → **inherit** | **Persistent mode.** Add `## Investigation State` protocol: maintain a hypothesis ledger (hypothesis / evidence for / evidence against / status) restated at the end of every reply so SendMessage continuations resume cold-free |
| architect | opus (keep) | Add judge-panel participation: when invoked as one of N panelists with an assigned angle (e.g. "argue MVP-first"), argue that angle genuinely and score rivals honestly |
| test-writer | sonnet (keep) | Add vacuous-pass guard: after writing tests, verify each fails when the behavior it constrains is broken (or predates the fix); a test that can't fail is a defect |
| devops-engineer | sonnet (keep) | Contract + frontmatter only |
| database-architect | sonnet → **opus** | Contract + frontmatter only |
| security-auditor | sonnet → **opus** | Findings formatted for adversarial-verifier handoff: each includes evidence path, preconditions, and a repro sketch so an independent agent can confirm or refute |
| frontend-specialist | sonnet (keep) | Contract + frontmatter only |
| api-designer | sonnet (keep) | Contract + frontmatter only |
| performance-optimizer | sonnet (keep) | Add measure-first discipline: no optimization without a before-measurement; report before/after numbers or mark the change speculative |
| documentation-writer | sonnet → **haiku** | Note in prompt: mechanical/low-effort agent; escalate to the orchestrator rather than guessing when domain understanding is missing |
| tech-lead | opus (keep) | Judge-panel participation (same clause as architect) |
| release-manager | sonnet (keep) | Add parallel-check awareness: often spawned as one of several concurrent `/merge-check` validators — do only the assigned dimension, return a structured verdict |
| **adversarial-verifier** (new) | **fable** | Read-only refuter (`Read, Grep, Glob, Bash`; no Write/Edit). Given a claimed finding, actively tries to refute it: reproduce, trace call paths, hunt counterevidence. **Defaults to "refuted" when uncertain.** Returns verdict `CONFIRMED`/`REFUTED`/`UNVERIFIABLE` + evidence |
| **workflow-author** (new) | **fable** | Read-only scoper (`Read, Grep, Glob`). Scopes a large task and authors a Workflow orchestration script for it: fan-out shape, phases, JSON schemas for structured outputs, verification stages. Returns the script, does not run it |

## 4. Implementation Steps

1. **Create `scripts/validate-agents.ps1`** (write the test first). It must check, for every `agents/*.md` and `.claude/agents/*.md`: (a) frontmatter parses as YAML between `---` fences; (b) required keys `name`, `description`, `tools`, `model` present; (c) `name` equals the filename stem; (d) `model` ∈ {haiku, sonnet, opus, fable, inherit}; (e) agents named in a read-only list (code-reviewer, security-auditor, tech-lead, architect, adversarial-verifier, workflow-author) contain no `Write`/`Edit` in tools; (f) every file in `agents/` has an identical counterpart in `.claude/agents/`; (g) body contains a `## Subagent Contract` heading. Exit non-zero with a per-file failure list. Run it now — it must fail (13 missing-frontmatter + missing-contract findings), proving it detects the current gaps.
2. **Frontmatter pass over all 13 existing agents** in `agents/`: add `name:` and `description:` as first two keys; apply the four model reroutes (debugger → inherit, database-architect → opus, security-auditor → opus, documentation-writer → haiku). Descriptions follow the trigger-phrase rule from §3 Key Decisions.
3. **Contract pass over all 13:** append `## Subagent Contract` (return-value semantics + mode designation; debugger marked persistent, all others fire-and-forget).
4. **Per-agent enhancement pass** for the 8 agents with entries in the change matrix (code-reviewer, debugger, architect, test-writer, security-auditor, performance-optimizer, documentation-writer, tech-lead, release-manager) — add the specified section/clauses, preserving each file's existing section order.
5. **Create `agents/adversarial-verifier.md`:** frontmatter (`name`, description with "use to verify any claimed bug/root-cause/security finding before it enters a plan", tools `Read, Grep, Glob, Bash`, `model: fable`); prompt with refutation methodology, the uncertain→refuted default, verdict output format, and Subagent Contract (fire-and-forget).
6. **Create `agents/workflow-author.md`:** frontmatter (tools `Read, Grep, Glob`, `model: fable`); prompt covering scoping questions, fan-out shape selection (pipeline vs parallel vs loop-until-dry), schema design for structured outputs, and verification-stage insertion; Subagent Contract (fire-and-forget).
7. **Verify the `fable` model value:** spawn each new agent once with a trivial prompt. If the CLI rejects the model value, switch both to `model: inherit` and record the substitution in §9.
8. **Sync to the live install:** copy all 15 files from `agents/` to `.claude/agents/`.
9. **Run `scripts/validate-agents.ps1`** — must pass with zero findings.
10. **Update [IntialPlan.md](../IntialPlan.md):** mark the two new agents ✅ built, mark the Phase 2 agent-routing item and the Phase 3 new-agents item done.

## 5. Files to Create or Modify

| File | Action | Purpose |
|------|--------|---------|
| `scripts/validate-agents.ps1` | Create | Structural validation of all agent files (the test suite for this change) |
| `agents/code-reviewer.md` | Modify | Frontmatter, contract, evidence-bearing findings format |
| `agents/debugger.md` | Modify | Frontmatter (model: inherit), persistent contract, hypothesis-ledger protocol |
| `agents/architect.md` | Modify | Frontmatter, contract, judge-panel clause |
| `agents/test-writer.md` | Modify | Frontmatter, contract, vacuous-pass guard |
| `agents/devops-engineer.md` | Modify | Frontmatter, contract |
| `agents/database-architect.md` | Modify | Frontmatter (model: opus), contract |
| `agents/security-auditor.md` | Modify | Frontmatter (model: opus), contract, verifier-handoff findings format |
| `agents/frontend-specialist.md` | Modify | Frontmatter, contract |
| `agents/api-designer.md` | Modify | Frontmatter, contract |
| `agents/performance-optimizer.md` | Modify | Frontmatter, contract, measure-first discipline |
| `agents/documentation-writer.md` | Modify | Frontmatter (model: haiku), contract, escalation note |
| `agents/tech-lead.md` | Modify | Frontmatter, contract, judge-panel clause |
| `agents/release-manager.md` | Modify | Frontmatter, contract, parallel-check awareness |
| `agents/adversarial-verifier.md` | Create | New Fable-tier read-only refutation agent |
| `agents/workflow-author.md` | Create | New Fable-tier orchestration-script author |
| `.claude/agents/*` (15 files) | Modify/Create | Sync live install with canonical library |
| `IntialPlan.md` | Modify | Status updates (new agents built, Phase 2/3 items done) |

## 6. Success Criteria

- [ ] **Functional:** All 15 agents have `name`, `description`, `tools`, `model` frontmatter; descriptions use delegation-trigger phrasing; the four model reroutes and two new agents match the change matrix exactly.
- [ ] **Tests:** `scripts/validate-agents.ps1` exists, failed before the changes (proving detection), and passes after — covering frontmatter presence, name/filename match, model whitelist, read-only tool enforcement, contract-section presence, and `agents/` ↔ `.claude/agents/` sync.
- [ ] **Behavioral spot-checks:** (a) spawning adversarial-verifier with a deliberately false finding returns `REFUTED`; (b) spawning debugger, then continuing it via SendMessage, shows the hypothesis ledger carried into the second reply; (c) both `model: fable` agents spawn without a model-resolution error (or the documented fallback is applied).
- [ ] **Quality:** Existing section order preserved in every modified file (diff shows additions, not restructuring); no `Write`/`Edit` granted to any read-only agent.

## 7. Risks & Open Questions

- **`fable` may be invalid in agent frontmatter** on the installed CLI version. Mitigation: Step 7 verifies empirically; fallback `inherit` documented in §9.
- **Auto-delegation side effects:** adding descriptions makes Claude Code start delegating to these agents automatically. Overly broad descriptions could cause surprise spawns. Mitigation: trigger phrasing is narrow ("use when X"), and read-only agents state their limits.
- **Dual-directory drift** remains a standing hazard; the validator's sync check turns silent drift into a loud failure, but a longer-term answer (symlink or install script) is deferred.
- **Open (out of scope, log for follow-up):** `.claude/commands/` is missing `test-review-plan.md` and `test-review-plan_sa.md`; `.claude/settings.json` contents were not audited.
- **Open:** should `haiku` documentation-writer keep `WebSearch`? Research-heavy doc tasks may exceed haiku; the escalation note mitigates, but watch quality after rollout.

## 8. Code Review Checklist

After implementation, verify:
- [ ] No dead code or unused imports introduced (n/a for markdown; no leftover placeholder text or template fragments)
- [ ] Error handling covers failure modes (validator reports per-file, per-rule failures and exits non-zero)
- [ ] No security vulnerabilities (no agent gained tools beyond its matrix row; read-only agents remain read-only)
- [ ] Code follows existing project conventions (frontmatter key order, section order, tone of existing prompts)
- [ ] Tests cover happy path, edge cases, and error scenarios (validator tested against a known-bad file, not just the final good state)
- [ ] No performance regressions (descriptions don't over-trigger delegation; model reroutes match the matrix — no accidental opus/fable on mechanical agents)
- [ ] Changes are minimal — no unrelated refactoring bundled in (command files untouched except IntialPlan status)

## 9. Post-Review Improvements

Ran the Section 8 Code Review Checklist against the diff. Six of seven items passed as
written; the one gap and the improvements made are documented below (each was implemented).

### Checklist results

- **No dead code / leftover template fragments** — PASS. The `...` cells in the debugger
  Hypothesis Ledger and architect Options tables are intentional illustrative templates,
  consistent with the pre-existing architect Options table; not stray fragments.
- **Error handling covers failure modes** — PASS. The validator reports per-file, per-rule
  findings and exits non-zero; it also handles missing directories, unparseable
  frontmatter, missing counterparts, and orphaned install files.
- **No security vulnerabilities / tool creep** — PASS. No `tools:` list was modified; every
  read-only agent (code-reviewer, security-auditor, tech-lead, architect,
  adversarial-verifier, workflow-author) has no `Write`/`Edit`, enforced by the validator.
- **Follows project conventions** — PASS. `name`/`description` added as the first two
  frontmatter keys; existing section order preserved (all changes appended after
  `## Output Format`); prompt tone matches the existing files.
- **Tests cover happy path, edge cases, and error scenarios** — **GAP FOUND → FIXED**
  (see Improvement 1). The initial known-bad run only exercised 2 of the validator's
  7 rules.
- **No performance regressions** — PASS. Model reroutes match the matrix exactly (verified
  by dumping every agent's `name`/`model`/`tools`); descriptions use narrow trigger
  phrasing to avoid over-broad auto-delegation.
- **Changes are minimal** — PASS. Only `agents/*.md`, the new `scripts/`, `.claude/agents/`
  sync, and `IntialPlan.md`/`plan.1.md` status/docs were touched. No command files changed.

### Improvement 1 — prove every validator rule fires (test coverage)

The Step 1 known-bad run only tripped rules (b) missing-keys and (g) missing-contract.
Rules (c) name/filename mismatch, (d) invalid model, (e) read-only tool violation, and
(f) sync drift / orphaned files were never exercised, so the "tests cover error scenarios"
criterion was not truly met. Implemented:

- **Parameterized `validate-agents.ps1`** with optional `-CanonicalDir` / `-InstallDir`
  (defaulting to the real directories) so the ruleset can run against fixtures without
  disturbing the library. Also simplified the required-key check for readability.
- **Added `scripts/test-validate-agents.ps1`** — a meta-test that builds known-good and
  known-bad fixture pairs in a temp dir and asserts the validator's exit code and message
  for 9 cases: happy path, missing key, name/filename mismatch, invalid model, read-only
  tool violation, missing Subagent Contract, sync drift, missing counterpart, and
  unparseable frontmatter. All 9 pass.

While building the meta-test, a fixture-generation bug surfaced and was fixed: an unbound
`[string]` parameter is `""` (not `$null`) in PowerShell, so the happy-path install fixture
was being written empty; switched the guard to `$PSBoundParameters.ContainsKey('InstallContent')`.
(A BOM red herring from `Set-Content -Encoding UTF8` was also eliminated by writing fixtures
as BOM-less UTF-8 via `UTF8Encoding($false)`, matching how real agent files are stored.)

### Deviation — behavioral spot-checks run via proxy; `model: fable` kept

This SDK/headless session's Agent tool exposes only a fixed built-in set of agent types
(claude, claude-code-guide, Explore, general-purpose, Plan, statusline-setup) and does
**not** register project `.claude/agents/*.md` definitions as spawnable `subagent_type`s.
Consequently:

- **Native spawn-by-name could not be tested here**, and therefore the empirical
  `model: fable` resolution check from Step 7 could not be performed by spawning. Project
  subagents are spawnable this way in an interactive Claude Code CLI, where the fable value
  would resolve or error visibly.
- **The Section 6 behavioral spot-checks were run via a proxy** — a `general-purpose` agent
  instructed to operate strictly under each agent's own definition. Results:
  - *adversarial-verifier*: given the deliberately false claim that
    `agents/adversarial-verifier.md` grants `Edit`, it returned **REFUTED** with `file:line`
    evidence (tools block is Read/Grep/Glob/Bash; the only "Edit" is the description prose).
  - *debugger*: after a `SendMessage`-style continuation carrying new evidence, it restated
    the **full hypothesis ledger**, kept all prior hypotheses, flipped #1 to `confirmed` and
    #2/#3 to `ruled out` with the killing evidence, and added a new row — i.e., the
    persistent Investigation State protocol works.
- **Decision:** kept `model: fable` on both new agents (did **not** fall back to `inherit`).
  There was no evidence of CLI rejection: `fable` is the documented tier in IntialPlan §1.1,
  is this session's own model class, and is on the validator's model whitelist. The
  Step 7 / §3 fallback to `inherit` was therefore **not** triggered.

## 10. Execution Prompt

```
Read the file plans/plan.1.md in this repository and execute it completely.

Context: this repo is a library of Claude Code agent definitions (agents/) and slash
commands (commands/), with a live install copy under .claude/. The plan upgrades all
13 existing agents and adds 2 new ones (adversarial-verifier, workflow-author) per
the design in IntialPlan.md.

Instructions:
1. Read plans/plan.1.md in full, then IntialPlan.md §1 and §3 for design rationale.
2. Implement the steps in Section 4 in order. Step 1 (the validation script) comes
   first and MUST fail against the current files before you change anything — if it
   passes, the script is wrong; fix it before proceeding.
3. Follow the Per-Agent Change Matrix in Section 3 exactly: model values, tool lists,
   and per-agent enhancements. Preserve each file's existing section order — append,
   don't restructure.
4. After Step 9 (validator passes), run the behavioral spot-checks from Section 6:
   spawn adversarial-verifier with a deliberately false finding (expect REFUTED),
   spawn and continue the debugger via SendMessage (expect the hypothesis ledger to
   persist), and confirm both model: fable agents spawn cleanly (fall back to
   model: inherit if the CLI rejects fable, and record this in Section 9).
5. Then run the Code Review Checklist in Section 8 against your own diff. For every
   item that fails, fix it. Document each improvement made during this review in
   Section 9 of the plan file, then implement it.
6. Before finishing: re-run scripts/validate-agents.ps1 (must pass), confirm
   agents/ and .claude/agents/ are identical, and update IntialPlan.md statuses
   (Step 10). Report what changed, what the validator covers, and any deviations
   from the plan.
```
