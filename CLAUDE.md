# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository is a library of reusable Claude Code slash commands (skills) and subagent configuration files. The goal is to create, test, and maintain portable `.claude/` configurations that can be dropped into any project.

## Repository Structure

- **Slash commands** go in `commands/` — each is a markdown file defining a skill (workflow) that users invoke via `/command-name`
- **Agent definitions** go in `agents/` — each is a markdown file with YAML frontmatter specifying tools, model, and system prompt for a specialized subagent
- [IntialPlan.md](IntialPlan.md) contains the initial roadmap of planned commands and agents
- [guide.md](guide.md) is a practical guide to using Claude Code, with tips and tricks

## Claude Code File Conventions

### Slash Commands
- Commands are markdown files placed in `.claude/commands/` (project-level) or `~/.claude/commands/` (global)
- Use `$ARGUMENTS` (or `$1`, `$2`) for parameterization
- Commands should encode specific team workflows and standards, not generic instructions

### Agent Definitions
- Agents are markdown files with YAML frontmatter placed in `.claude/agents/` or `~/.claude/agents/`
- Frontmatter controls: `tools` (restrict to minimum needed), `model` (sonnet/opus/inherit), and system prompt
- Read-only agents (reviewers, auditors) must NOT have `Write` or `Edit` tools
- Use `model: sonnet` for cheaper exploratory agents, `model: opus` for high-stakes analysis

## Design Principles

- Each command/agent file should be self-contained and independently usable
- Commands capture codified workflows — the prompt reflects actual process (commit standards, review checklists), not generic advice
- Agents are differentiated by tool restrictions, focused system prompts, and model routing
- Start minimal (3-4 agents, 4-5 commands) and expand as patterns emerge
