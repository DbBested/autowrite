# Autowrite

A Claude Code-native writing improvement system that diagnoses, plans, and revises drafts through form-aware staged passes — with an eval-driven self-improvement loop inspired by [Karpathy's auto-research](https://github.com/karpathy).

**No dependencies. No install. Just Claude Code.**

## What it does

You give it a draft. It tells you what's weak, makes a plan, and runs staged revision passes that each stay in their lane — structure doesn't touch wording, clarity doesn't restructure paragraphs. Every change is explained. Every diff is visible.

```
/improve @drafts/my-essay.md --preset argumentative-essay
```

**Output:** revised draft + diagnosis + revision plan + per-change explanations + unified diff — all in an immutable timestamped run directory.

## The self-improvement loop

The real differentiator. Autowrite improves *itself* through measured mutation:

```
/autoloop --target presets/argumentative-essay.json --iterations 20 --reference-draft @drafts/ref.md
```

Each iteration:
1. Proposes one atomic change to the preset (rubric wording, voice rule, stage order)
2. Runs the full writing engine + eval on a fixed reference draft
3. Keeps the change **only if** scores improve with no critical regressions
4. Checks a holdout set every 3 iterations to prevent Goodhart overfitting

In our first run: **7.55 → 9.00** across 20 iterations (10 accepted, 10 rejected).

## Skills

| Skill | What it does |
|-------|-------------|
| `/improve` | Staged revision: diagnose → plan → passes → diff → explain |
| `/build` | Notes/bullets → polished draft (same engine, notes mode) |
| `/adapt` | Convert between forms: essay → blog post, explainer → memo |
| `/eval` | Isolated adversarial critic scores on 7 criteria with located failure points |
| `/create-preset` | Analyze example texts → synthesize preset → review → save |
| `/autoloop` | Mutation-eval self-improvement cycle with holdout protection |

## How it works

### Presets define "good"

Each writing form has a JSON preset: voice rules, structure expectations, rubric criteria with weights, pass sequences, and behavioral constraints. Three included:

- **blog-post** — conversational, engagement-weighted, 10 stages
- **argumentative-essay** — formal-analytical, thesis-driven, 9 stages
- **technical-explainer** — precise but accessible, clarity at 0.30 weight, 8 stages

Create your own from examples: `/create-preset @example1.md @example2.md --name my-style`

### Staged passes with scope constraints

14 pass types, each with explicit "DO NOT touch" rules:

- **diagnose** — read-only analysis, names specific weaknesses by paragraph/sentence
- **revision-plan** — assigns each weakness to a pass, flags voice risks
- **structure** — reorders sections, adds transitions, never edits sentences
- **clarity** — rewrites ambiguous sentences, never restructures
- **argument** — tightens claims and evidence connections, never invents evidence
- **tone** — normalizes register, never changes meaning
- ...and 8 more (evidence, objection, concision, hook, ending, precision, examples, final-review)

### Eval critic

An isolated subagent (`context: fork`) that sees only the text and rubric — never the revision history. Scores on 7 anchored criteria (1-10 scale):

- Novelty, Clarity, Structure, Voice Preservation, Audience Fit, Concision, Factual Integrity

Hyper-critical by design. Finds flaws, never praises, never suggests fixes.

### Safety rules

- Never invents citations or references
- Never fabricates statistics or claims
- Never silently shifts the author's argumentative position
- Preserves author voice by default on every pass

## Setup

1. Clone this repo
2. Open in Claude Code
3. Run any skill: `/improve @drafts/your-draft.md`

That's it. No pip install, no npm, no Docker. Autowrite runs entirely on Claude Code primitives: CLAUDE.md, SKILL.md, local files, and shell scripts.

### Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- `jq` for preset validation (optional — Python fallback included)

## Project structure

```
autowrite/
├── CLAUDE.md                    # Universal safety rules + onboarding
├── presets/                     # JSON preset files (source of truth)
│   ├── blog-post.json
│   ├── argumentative-essay.json
│   ├── technical-explainer.json
│   └── preset-schema.json       # JSON Schema for validation
├── .claude/
│   ├── skills/                  # SKILL.md files (one per task)
│   │   ├── improve/
│   │   ├── build/
│   │   ├── adapt/
│   │   ├── eval/
│   │   ├── create-preset/
│   │   └── autoloop/
│   ├── agents/
│   │   └── eval-critic.md       # Adversarial evaluation subagent
│   └── rules/
│       └── passes/              # 14 per-pass scope constraint files
├── drafts/                      # Your input drafts
├── runs/                        # Immutable timestamped run outputs
├── evals/                       # Standalone eval results
├── autoloop/
│   ├── holdout/                 # Holdout texts for Goodhart protection
│   ├── reference-drafts/        # Fixed drafts for autoloop scoring
│   └── runs/                    # Autoloop mutation logs (JSONL)
└── scripts/
    └── validate-preset.sh       # jq-based preset validator
```

## The autoloop in detail

Inspired by the Auto Research paradigm: instead of hand-tuning prompts, let the system measure its own output and keep only the changes that measurably improve quality.

### Acceptance rule (all 4 must pass)

1. Aggregate score strictly improves
2. `factual_integrity` stays ≥ 6
3. `voice_preservation` stays ≥ 6
4. No single criterion drops > 2 points

### Goodhart protection

A holdout set (texts the loop never trains on) is checked every 3 iterations. If holdout scores diverge from loop scores by > 1.0 point, the loop halts and restores the original preset. This prevents the preset from overfitting to one reference draft's characteristics.

### What gets mutated

- Rubric criterion descriptions (anchor to observable behaviors)
- Voice behaviors (add/refine behavioral rules)
- Stage order (move passes earlier/later)
- Sentence length constraints
- Structure expectations

### What doesn't get mutated (v1)

- Core skills (improve, eval, build, adapt)
- Safety rules (CLAUDE.md)
- Pass scope constraints (rules/passes/*.md)

## Philosophy

Most writing tools focus on first-draft generation. Autowrite focuses on **iterative improvement**:

- **Diagnose before rewriting** — know what's weak before touching anything
- **Staged passes** — each pass has a defined scope and explicit boundaries
- **Voice preservation by default** — your writing should still sound like you
- **Presets as source of truth** — what "good" means is inspectable and editable
- **Eval-driven iteration** — not prompt guessing, engineering with measurement
- **Everything is a local file** — inspectable, hackable, version-controlled

## License

MIT

## Built with

- [Claude Code](https://claude.ai/claude-code) — the entire runtime
- [GSD](https://github.com/get-shit-done/gsd) — project planning and execution framework
