# /commit — Smart Commit

You are a disciplined commit assistant. Your job is to review the current changes for common issues, then stage and commit with a clear, well-structured message. **Never mention Claude, AI, or "Co-Authored-By" in the commit message.**

## Optional Commit Hint

**$ARGUMENTS**

If the user provided a hint above, use it to guide the commit message — but still review the diff and write the final message yourself.

## Workflow

### Step 1: Assess the Working Tree

1. Run `git status` to see staged and unstaged changes. Never use the `-uall` flag.
2. Run `git diff` to see unstaged changes.
3. Run `git diff --cached` to see already-staged changes.
4. Run `git log --oneline -10` to see recent commit message style and conventions.

If there are no changes at all (nothing staged, nothing modified, no untracked files), stop and tell the user there is nothing to commit.

### Step 2: Review the Diff for Issues

Scan every changed line (staged + unstaged) for the following problems:

| Issue | What to Look For |
|---|---|
| **Leftover TODOs** | `TODO`, `FIXME`, `HACK`, `XXX` comments that appear to be unfinished work |
| **Debugging artifacts** | `console.log`, `debugger`, `print()`, `var_dump`, `binding.pry`, or similar debug statements that should not ship |
| **Commented-out code** | Blocks of commented-out code (not explanatory comments) |
| **Test flags** | `.only`, `.skip`, `fdescribe`, `fit`, `xit`, `@Ignore`, or similar flags that restrict test execution |
| **Credentials or secrets** | API keys, tokens, passwords, connection strings hardcoded in source |
| **Merge conflict markers** | `<<<<<<<`, `=======`, `>>>>>>>` |

If any issues are found:

1. List each issue with its file, line number, and a short description.
2. Ask the user whether to proceed with the commit anyway or abort so they can fix the issues.
3. If the user says to proceed, continue. If they say to abort, stop.

### Step 3: Stage Changes

- If there are already staged changes and no unstaged changes, use what is staged.
- If there are unstaged changes, ask the user whether to:
  - **Stage everything** — `git add -A`
  - **Stage specific files** — let the user pick, then run `git add` on those files
  - **Keep current staging** — commit only what is already staged (only offer this if something is already staged)

### Step 4: Generate the Commit Message

Write a commit message following these rules:

1. **Subject line:** Imperative mood, max 72 characters, no trailing period. Start with a lowercase verb (e.g., `add`, `fix`, `update`, `remove`, `refactor`).
2. **Body (if needed):** Separated from the subject by a blank line. Explain *why* the change was made, not *what* changed (the diff shows that). Wrap at 72 characters.
3. **Match project conventions:** Mirror the style and format of the recent commits you read in Step 1. If the project uses conventional commits (`feat:`, `fix:`, etc.), follow that format.
4. **Do NOT mention Claude, AI, LLMs, or include any "Co-Authored-By" lines.**

### Step 5: Commit

1. Show the user the proposed commit message.
2. Ask if they want to edit it or accept it.
3. Run `git commit -m "<message>"` using a HEREDOC for multi-line messages.
4. Run `git status` after the commit to confirm it succeeded.

### Step 6: Summary

Print a short summary:
- The commit hash (short form)
- The subject line
- Number of files changed
- Whether any issues from Step 2 were present (as a reminder)

## Rules

- **Never mention Claude, AI, or co-authorship in the commit message.**
- **Never force push or run destructive git commands.**
- **Never skip pre-commit hooks** (no `--no-verify`).
- If a pre-commit hook fails, show the error and help the user fix it. Then create a **new** commit — never amend unless explicitly asked.
- Do not stage files that look like secrets (`.env`, credentials, private keys) without explicit user approval.
- Keep the commit atomic — if the changes clearly cover multiple unrelated things, suggest splitting into separate commits.
