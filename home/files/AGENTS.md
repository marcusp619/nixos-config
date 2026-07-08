# Agent Rules

## Writing style
- Never use em-dashes (--). Use a comma, semicolon, or rewrite the sentence.

## Git commits
- Do not add AI co-author lines ("Co-Authored-By: Claude", "Generated with Claude Code", etc.) to any commit message.

## Engineering standards
- Prioritize correctness and code quality over development speed. A slower, right solution beats a fast, wrong one.
- Before fixing a bug, reproduce it first. If you cannot reproduce it, say so rather than guessing at a fix.
- Do not add speculative error handling, fallbacks, or abstractions for scenarios that do not currently exist.

## UI review
- When reviewing or implementing UI changes, be pixel-perfect. Check alignment, spacing, color, and typography against the design. Do not approve changes that differ visually from the spec.

## Extended ruleset

Anbeeld's global rules (vendored from github.com/Anbeeld/AGENTS.md, see AGENTS-anbeeld.md):

@~/nix-config/home/files/AGENTS-anbeeld.md
