# Requirements first

Applies to every task that changes code, config, routes, providers, UI or docs (no path scope, always loads).

## Before implementing

1. Analyze the request with the `superpowers:brainstorming` skill (and `superpowers:writing-plans` for multi-step work) before touching files. Skip only for a one-line typo or an explicit, fully specified edit.
2. Check the analysis against this repo's rules (`.claude/rules/*.md`, `AGENTS.md`). Note which rules and which existing code the change touches. For searches across many files, use the `Explore` agent and keep only its conclusions.
3. If anything is unclear, ask the user with `AskUserQuestion` before implementing. Ask about things that change the result: scope, screen or route names, data source or API shape, states (loading, error, empty), platform targets, and which of several valid approaches to take. Batch the questions into one call (max 4 per call).
4. Ask only what cannot be decided from the request, the code or a sensible default. For a conventional choice, pick it, say so in the final message, and go on.
5. Don't start implementing while a question is open. Stop, wait for the answer, then continue.

## Output of the analysis

Before coding, state in one short block: the goal, the files to change, the open questions (if any), and the chosen approach. Keep it short.
