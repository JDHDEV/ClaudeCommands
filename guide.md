# How to Use Claude Code — A Practical Guide

This guide covers the basics of working with Claude Code and collects tips for getting better results. It pairs with the skills and agent definitions in this repository.

## Getting Started

### What Is Claude Code?

Claude Code is Anthropic's official CLI tool for working with Claude directly in your terminal. It can read your codebase, edit files, run commands, and interact with git — all through natural language conversation.

### Installation

```bash
npm install -g @anthropic-ai/claude-code
```

You need an Anthropic API key or a Claude subscription. See the [official docs](https://code.claude.com/docs) for full setup instructions.

### Basic Usage

Run `claude` in your project directory to start a conversation. From there you can:

- Ask questions about your codebase ("How does authentication work in this project?")
- Request changes ("Add input validation to the signup form")
- Run workflows via skills (`/commit`, `/plan`, etc.)
- Delegate tasks to specialized agents

## CLAUDE.md Memory Files

Claude Code loads `CLAUDE.md` files into context at the start of every session. They are how you give Claude standing instructions without repeating them in every prompt. Two levels matter:

- **`~/.claude/CLAUDE.md`** (global) — your personal rules, applied in *every* project. This is where your working style lives.
- **`<project>/CLAUDE.md`** (project) — checked into the repo and shared with the team. Documents project structure, build/test commands, and repo-specific conventions.

A `CLAUDE.md` can pull in other files with `@path/to/file.md` imports, which keeps the main file short while splitting out topic-specific guidance.

### Writing a Good CLAUDE.md

- **Every line costs context in every conversation.** Keep it short. A ten-rule file that Claude actually follows beats a three-page style guide it skims.
- **Write imperative rules, not essays.** "Never commit unless asked" works; a paragraph about commit philosophy doesn't.
- **Global = how you work. Project = facts about this repo.** Don't put project build commands in your global file, and don't put personal preferences in the shared project file.
- **Don't state what Claude can derive.** It can read the code to learn the style; it can't read your mind about what you consider done.

### Example Global `~/.claude/CLAUDE.md`

```markdown
# Global Rules

## Principles
1. Don't assume. If the request is ambiguous, say what's unclear before acting. Surface tradeoffs.
2. Write the minimum code that solves the problem. Nothing speculative — no features "for later."
3. Touch only what you must. Never reformat, rename, or "improve" code unrelated to the task.
4. Define success criteria up front. Loop until the result is verified against them, then stop.

## Code
- Match the style, naming, and idioms of the surrounding code — even if you'd write it differently.
- Comment only non-obvious constraints, never what the code plainly does.
- Flag any new dependency before adding it.

## Git
- Never commit or push unless explicitly asked.
- Never use `--force`, `--amend`, or `--no-verify` on anything shared.

## Communication
- Lead with the outcome; supporting detail after.
- Report failures plainly: failing tests, skipped steps, and unverified assumptions are results, not
  things to smooth over.
```

The rules to prioritize are the ones that counter Claude's default failure modes: assuming instead of asking, over-building, drive-by refactoring, and declaring victory before verifying. Everything else is polish. The four Principles above are adapted from Noor Mohamad's *The 4-Line CLAUDE.md That Beats Your 40 Rules* [[1]](#sources--references).

## Using Skills

Skills are reusable prompts that encode specific workflows. Each skill is a `SKILL.md` file in a directory named after the skill, living in `.claude/skills/<name>/` inside your project (project-level) or `~/.claude/skills/<name>/` (global).

> **Migration note:** this library previously shipped these workflows as `commands/*.md` (the older `.claude/commands/` format). They are now skills under `skills/` — same `/name` invocations, same behavior, newer format. If you installed the old commands, delete them from `.claude/commands/` when installing the skills so a stale copy cannot shadow the new one (when a command and a skill share a name, the skill wins).

### How to Invoke

Type `/skill-name` in a Claude Code session. This library currently ships seven skills:

- `/commit` — review your diff, scan for secrets, and create a clean, convention-matching commit
- `/plan` — research a feature and write a numbered implementation plan (`plans/plan.<number>.md`) before any code
- `/code-review-plan` — multi-perspective code review of a target that produces a remediation plan
- `/test-review-plan` — run the full test suite and write a plan to fix every failure

Each planning skill also has a `_sa` (subagent) variant — `/plan_sa`, `/code-review-plan_sa`, `/test-review-plan_sa` — that orchestrates the same workflow across the specialized agents in `agents/` instead of doing the analysis in one context.

### Installing Skills from This Repo

Copy the skill directories from `skills/` into your project's `.claude/skills/` directory (and the agents — the `_sa` skills delegate to them by name):

```bash
# Project-level (available only in this project)
cp -r skills/* your-project/.claude/skills/
cp agents/*.md your-project/.claude/agents/

# Global (available in all projects)
cp -r skills/* ~/.claude/skills/
cp agents/*.md ~/.claude/agents/
```

The skills work without the agents pack installed — every subagent spawn carries a fallback clause to the built-in generic types — but the tool restrictions (read-only reviewers/auditors) are only enforced when the real agents are present.

### The SKILL.md Format

Each `SKILL.md` starts with YAML frontmatter:

```yaml
---
name: commit                        # must equal the directory name
description: One-line summary…      # shown in listings; drives auto-invocation when enabled
argument-hint: [optional hint]      # completion hint shown after /name
disable-model-invocation: true      # user-triggered only — Claude never auto-invokes it
---
```

All skills in this library set `disable-model-invocation: true` deliberately: they are parameterized, side-effectful workflows that should only run when you type them.

### Parameterization

Skills accept arguments using `$ARGUMENTS` (or `$1`, `$2` for positional args). When you invoke a skill, anything you type after the skill name is passed as arguments. Every skill in this library treats `$ARGUMENTS` as untrusted data — a scope or target description, never instructions.

## Using Agents

Agents are specialized sub-processes with restricted tools, focused system prompts, and targeted model selection. They live in `.claude/agents/` inside your project or `~/.claude/agents/` globally.

### How Agents Differ from Skills

| | Skills | Agents |
|---|---|---|
| **Purpose** | Encode a workflow you invoke directly | Specialized roles Claude delegates to |
| **Interaction** | You run them with `/skill-name` | Claude spawns them as needed |
| **Tools** | Full tool access | Restricted to what the agent needs |
| **Model** | Uses your current model | Can specify a different model |

### Installing Agents from This Repo

```bash
# Project-level
cp agents/*.md your-project/.claude/agents/

# Global
cp agents/*.md ~/.claude/agents/
```

### Agent Design Principles

- **Read-only agents** (reviewers, auditors) don't have Write or Edit tools — they can only analyze
- **Cheaper models** (`model: sonnet`) are used for routine tasks; **stronger models** (`model: opus`) for high-stakes analysis
- Each agent has a focused persona and structured output format
- **Model portability:** two agents in this library declare `model: fable`. If your Claude Code version does not accept that value, change it to `model: inherit` — the agent then runs on whatever model your session uses.

## Recommended Settings Hardening

Claude Code permission allow-lists like `Bash(git:*)` auto-approve *every* git command, including destructive ones. If you allow git broadly, add a `deny` (or `ask`) list for the dangerous forms in your `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git commit --amend*)",
      "Bash(git reset --hard*)",
      "Bash(git * --no-verify*)"
    ]
  }
}
```

This is a personal-settings decision (settings files are yours and should never be committed to a shared repo — keep `.claude/settings.json` and `.claude/settings.local.json` gitignored), but this library recommends the deny-list wherever its git-touching skills are installed. Never put credentials in permission rules; anything in settings.json is plaintext on disk.

---

## Tips & Tricks

### 1. Include Failure Criteria in Your Prompts and Plans

Most people tell Claude what they *want*. Fewer people tell Claude what they *don't want* — and that's where quality drops off.

**Why it matters:** Without explicit failure criteria, Claude optimizes for the happy path. It produces code that works for the obvious case but may silently break on edge cases, violate constraints you assumed were obvious, or miss error conditions entirely. Failure criteria act as guardrails that keep the output grounded.

**What failure criteria look like:**

- "This function must NOT modify the input array in place"
- "The API must return a 400 (not 500) for malformed input"
- "If the database connection fails, the service must not start — do not fall back to an in-memory store"
- "The migration must be reversible. If the rollback doesn't restore the original schema exactly, it's wrong"
- "This must work without JavaScript enabled in the browser"

**How to apply this:**

- **In prompts:** After describing what you want, add a "Constraints" or "Must not" section. Be specific about behaviors that would make the result wrong.
- **In plans:** Add failure criteria alongside success criteria. For every "it should do X", consider "it must not do Y" and "it must handle Z gracefully".
- **In skills:** When writing reusable skills, build failure checks into the workflow. For example, the `/commit` skill in this repo explicitly scans for debugging artifacts, commented-out code, and credentials before committing — those are failure criteria baked into the process.

**The pattern:** Tell Claude what success looks like, then tell it what failure looks like. The gap between those two descriptions is where the best work happens.

---

## Sources / References

1. Noor Mohamad, ["The 4-Line CLAUDE.md That Beats Your 40 Rules"](https://archive.ph/fvwQG) (Medium, June 2026) — source of the four Principles in the example global `CLAUDE.md`.
