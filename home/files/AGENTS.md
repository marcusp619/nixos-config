# Agent Rules

## Writing style
- Never use em-dashes (--). Use a comma, semicolon, or rewrite the sentence.
- When writing or substantially editing long Markdown files, put each full sentence on its own line. Preserve normal Markdown structure, but avoid wrapping multiple sentences onto one physical line.

## Git commits
- Do not add AI co-author lines ("Co-Authored-By: Claude", "Generated with Claude Code", etc.) to any commit message.
- Never create a git commit unless the user explicitly asks for one. Uncommitted changes are the user's review state, they read the diff before deciding what to commit, so keep changes uncommitted until asked.
- Prefer `git merge` over `git squash` whenever possible, unless the user explicitly asks for squash.

## Engineering standards
- Prioritize correctness and code quality over development speed. A slower, right solution beats a fast, wrong one.
- When weighing technical decisions, do not give much weight to development cost or time; favor quality, simplicity, robustness, scalability, and long-term maintainability.
- Before fixing a bug, reproduce it first, ideally in an end-to-end setting that mirrors how an end user actually encounters it, so the fix addresses the real problem. If you cannot reproduce it, say so rather than guessing at a fix.
- Do not add speculative error handling, fallbacks, or abstractions for scenarios that do not currently exist.

## UI review
- When reviewing or implementing UI changes, be pixel-perfect. Check alignment, spacing, color, and typography against the design. Do not approve changes that differ visually from the spec.
- If something clearly looks off during review, even if unrelated to the current change, flag it and get it fixed along the way. Apply the same standard to lint errors, test failures, and test flakiness you notice, even if not caused by the current work.

## Code style
- Comments in English only.
- Prefer functional programming over OOP; use OOP classes only for connectors and interfaces to external systems.
- Write pure functions, only modify return values, never input parameters or global state.
- Follow DRY, KISS, and YAGNI principles.
- Prefer simple, native, vendor-recommended solutions and avoid premature abstractions.
- Use strict typing for returns, variables, collections, and complex data. Validate external/API data at runtime, require needed fields, ignore unrelated extra fields, prefer structured models over loose dictionaries, and avoid weak generic types like `Any`, `unknown`, or `List[Dict[str, Any]]`.
- Check if logic already exists before writing new code.
- Never use default parameter values, make all parameters explicit.
- Write simple single-purpose functions, no multi-mode behavior, no flag parameters that switch logic. If multiple modes are needed, wait to be asked explicitly.

## Error handling
- Always raise errors explicitly, never silently ignore them.
- Use specific error types that clearly indicate what went wrong; avoid catch-all exception handlers that hide the root cause.
- No fallbacks, symptom-masking guards, or silent recovery unless explicitly requested; fix root causes and make code either succeed or fail with a clear error.
- For external API or service calls, use retries with warnings, then raise the last error.
- Error messages must be clear, actionable, and specific: explain what failed and why, include request params, response body, and status codes; avoid generic "something went wrong".
- Logging should use structured fields instead of interpolating dynamic values into message strings.

## Libraries and dependencies
- Use modern, stable, project-compatible package management, libraries, and language standards; prefer vendor-recommended patterns such as ESM when supported.
- Install dependencies in project environments, not globally.
- Add or update dependencies in project config files, not as one-off manual installs.
- If a dependency is installed locally, read its source code when needed instead of guessing, even if it is gitignored.

## Testing
- Respect the repository test strategy and add only the minimum useful tests for the requested change.
- Prefer smoke, integration, and end-to-end tests over narrow unit or regression tests; do not test static text, prompts, or config unless behavior depends on them.
- Do not create fake/mock-based tests by default; use real integrations when practical, even if they cost a little money.
- UI tests and automations must use stable IDs, test IDs, or accessibility IDs instead of visible text, and fail fast without fallback clicks.

## Terminal usage
- Prefer non-interactive commands with flags over interactive ones.
- Always use non-interactive git diff: `git --no-pager diff` or `git diff | cat`.

## Workflow
- Read the existing code and relevant project instructions before editing.
- Keep changes minimal and tightly scoped to the current request: make the smallest useful diff, change only the lines needed to solve the problem, and avoid unrelated improvements unless asked.
- Match the existing style of the repository even if it differs from personal preference; new code must look like it was written by the same author.
- Keep files small and cohesive; split by feature or responsibility when the project has no established structure.
- Do not revert unrelated changes.
- Never manually modify CHANGELOG.md files or any files marked as auto-generated.
- If unsure, inspect the codebase instead of inventing patterns.
- When project instructions include test or lint commands, run them before finishing if the task changed code.

## Documentation
- Code is the primary documentation, use clear naming, types, and docstrings.
- Keep documentation in the docstrings of the functions, classes, or modules they describe, not in separate files.
- Separate docs files only when a concept cannot be expressed clearly in code, and only one file per topic.
- Never duplicate documentation across files; reference other sources instead.
- Store knowledge as current state, not as a changelog of modifications.

## Extended ruleset

Anbeeld's global rules (vendored from github.com/Anbeeld/AGENTS.md, see AGENTS-anbeeld.md):

@~/nix-config/home/files/AGENTS-anbeeld.md
