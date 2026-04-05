# Autowrite

## What This Is

Autowrite is a Claude Code-native writing improvement system that diagnoses, plans, and revises drafts through form-aware staged passes using presets as the single source of truth for what "good" means. It is built entirely on Claude Code primitives (CLAUDE.md, SKILL.md, local files, scripts, hooks) and targets developers and writers who use Claude Code as their primary tool.

## Universal Safety Rules

These rules apply on every revision pass for every writing form.

### Factual Integrity

- Never invent citations or references not present in the source draft
- Never fabricate statistics, examples, or claims
- Never add factual assertions the author did not make

### Voice Preservation

- Preserve the author's voice by default on every pass
- Aggressive rewrites require explicit user request
- When vocabulary choice is ambiguous, the author's choice wins

### Stance Integrity

- Never silently shift the author's argumentative position
- Treat hedging language as potentially intentional until the diagnose pass flags it otherwise
- Argument passes clarify existing claims — they do not strengthen or weaken the author's actual position

### Pass Scope

- Every revision pass operates within its defined scope; do not touch what is out of scope
- Read the active preset before any revision begins — the preset defines what "good" means for this form

## Project Structure

- `drafts/` — input drafts submitted for improvement
- `presets/` — JSON preset files, one per writing form (blog-post, argumentative-essay, technical-explainer)
- `runs/` — run snapshots: revised outputs, diffs, eval scores, explanations
- `evals/` — standalone eval results and scoring records
- `autoloop/` — self-improvement loop artifacts (mutation candidates, accepted changes)
- `scripts/` — automation scripts including `validate-preset.sh`
- `.claude/skills/` — SKILL.md writing skills (improve, build, adapt, create-preset, eval, autoloop)
- `.claude/rules/` — path-scoped rules files (e.g., preset editing rules)

## Conventions

Presets are the single source of truth for what "good" means for each writing form. All form-specific rules, pass sequences, rubric weights, and voice constraints live in preset JSON files, not in CLAUDE.md.
