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

## User Onboarding

When a user opens this project for the first time or seems unsure how to use Autowrite, guide them through setup. Ask what they need before suggesting a workflow.

### First question to ask

"What are you working on? Do you have a draft to improve, notes to expand, or do you want to create a preset from example writing?"

### Workflow routing

Based on the user's answer, route them:

| User has... | Suggest | What to tell them |
|-------------|---------|-------------------|
| A finished draft to improve | `/improve @drafts/file.md` | "Put your draft in `drafts/`, then run `/improve @drafts/yourfile.md`. I'll auto-detect the best preset, or you can pick one with `--preset blog-post`." |
| Rough notes, bullet points, or an outline | `/build @drafts/notes.md` | "Put your notes in `drafts/` — bullet points, fragments, whatever you have. Run `/build @drafts/notes.md --preset argumentative-essay`. I'll expand it into a full piece." |
| A draft to convert to a different form | `/adapt @drafts/file.md --to <preset>` | "Run `/adapt @drafts/yourfile.md --to technical-explainer`. I'll restructure it for the target form while keeping your content." |
| Example writing they want to match | `/create-preset @example1.md --name my-style` | "Give me 1-3 examples of writing you admire. Run `/create-preset @example1.md @example2.md --name my-style`. I'll analyze the style and create a reusable preset — you review every field before it saves." |
| A revised draft to evaluate | `/eval @drafts/file.md --preset blog-post` | "Run `/eval @yourfile.md --preset blog-post`. I'll score it on 7 criteria (clarity, structure, voice, etc.) with specific failure points and locations." |
| A preset to improve over time | `/autoloop --target presets/blog-post.json --iterations 5 --reference-draft @drafts/ref.md` | "Give me a reference draft that represents good writing for this form, put it in `drafts/`. I'll run mutation cycles on the preset — each change is tested and only kept if scores improve." |

### What the user needs to provide

Always tell the user exactly what files to create and where to put them:

- **Drafts and notes** go in `drafts/` — any `.md` file
- **Example texts** for preset creation can be anywhere, referenced with `@path`
- **Reference drafts** for autoloop go in `drafts/` or `autoloop/reference-drafts/`
- **Holdout texts** for autoloop go in `autoloop/holdout/` (1-3 texts the loop doesn't train on)

### Available presets

Three presets are included. Help the user pick:

| Preset | Best for | Voice |
|--------|----------|-------|
| `blog-post` | Blog posts, articles, opinion pieces | Conversational, first-person, contractions allowed |
| `argumentative-essay` | Academic essays, position papers, formal arguments | Formal-analytical, no contractions, thesis-driven |
| `technical-explainer` | Tutorials, documentation, how-to guides | Precise but accessible, define-first, examples after abstractions |

If none fits, suggest `/create-preset` to make a custom one from examples.

### Depth flag

All writing skills accept `--depth`:
- `light` — 3 core passes (diagnose, plan, structure). Quick cleanup.
- `standard` — all preset stages. Default.
- `deep` — all stages plus a second pass on weakest areas. Most thorough.

### After a run

Outputs appear in `runs/YYYY-MM-DD_HH-MM-SS_preset-name/`:
- `output.md` — the clean revised draft (this is what the user wants)
- `diagnosis.md` — what was weak and where
- `explanation.md` — what changed and why, grouped by pass
- `diff.patch` — unified diff (input vs output)
- `metadata.json` — preset used, timestamps, word counts

Point users to `output.md` first. If they want to understand the changes, point to `explanation.md`.

## Conventions

Presets are the single source of truth for what "good" means for each writing form. All form-specific rules, pass sequences, rubric weights, and voice constraints live in preset JSON files, not in CLAUDE.md.
