# How to Use Claude Code — A Practical Guide

This guide covers the basics of working with Claude Code and collects tips for getting better results. It pairs with the slash commands and agent definitions in this repository.

## Getting Started

### What Is Claude Code?

Claude Code is Anthropic's official CLI tool for working with Claude directly in your terminal. It can read your codebase, edit files, run commands, and interact with git — all through natural language conversation.

### Installation

```bash
npm install -g @anthropic-ai/claude-code
```

You need an Anthropic API key or a Claude subscription. See the [official docs](https://docs.anthropic.com/en/docs/claude-code) for full setup instructions.

### Basic Usage

Run `claude` in your project directory to start a conversation. From there you can:

- Ask questions about your codebase ("How does authentication work in this project?")
- Request changes ("Add input validation to the signup form")
- Run workflows via slash commands (`/commit`, `/plan`, etc.)
- Delegate tasks to specialized agents

## Using Slash Commands

Slash commands are reusable prompts that encode specific workflows. They live in `.claude/commands/` inside your project (project-level) or `~/.claude/commands/` (global).

### How to Invoke

Type `/command-name` in a Claude Code session. For example:

- `/commit` — review your diff and create a clean commit
- `/plan` — research and plan a feature before writing code
- `/code-review-plan` — conduct a multi-perspective code review

### Installing Commands from This Repo

Copy the files from `commands/` into your project's `.claude/commands/` directory:

```bash
# Project-level (available only in this project)
cp commands/*.md your-project/.claude/commands/

# Global (available in all projects)
cp commands/*.md ~/.claude/commands/
```

### Parameterization

Commands can accept arguments using `$ARGUMENTS` (or `$1`, `$2` for positional args). When you invoke a command, anything you type after the command name is passed as arguments.

## Using Agents

Agents are specialized sub-processes with restricted tools, focused system prompts, and targeted model selection. They live in `.claude/agents/` inside your project or `~/.claude/agents/` globally.

### How Agents Differ from Commands

| | Commands | Agents |
|---|---|---|
| **Purpose** | Encode a workflow you invoke directly | Specialized roles Claude delegates to |
| **Interaction** | You run them with `/command-name` | Claude spawns them as needed |
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
- **In commands:** When writing reusable slash commands, build failure checks into the workflow. For example, the `/commit` command in this repo explicitly scans for debugging artifacts, commented-out code, and credentials before committing — those are failure criteria baked into the process.

**The pattern:** Tell Claude what success looks like, then tell it what failure looks like. The gap between those two descriptions is where the best work happens.
