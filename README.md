# Autowrite

An auto-research inspired self-improvement loop for writing. Give it a draft, it diagnoses what's weak, runs staged revision passes, and scores the result. Then it mutates its own preset and keeps only the changes that measurably improve output quality.

Works for any writing form — essays, blog posts, technical docs, grant proposals, reports. Create a preset from examples of writing you admire and the system tunes itself to that standard.

**No dependencies. No install. Just [Claude Code](https://claude.ai/claude-code).**

## How it works

```
/improve @drafts/my-essay.md --preset argumentative-essay
```

1. **Diagnose** — identifies specific weaknesses by paragraph and sentence
2. **Plan** — assigns each fix to a revision pass
3. **Revise** — runs staged passes (structure, argument, clarity, etc.) each with strict scope constraints
4. **Output** — revised draft + diff + per-change explanations in a timestamped run directory

## The self-improvement loop

```
/autoloop --target presets/argumentative-essay.json --iterations 20 --reference-draft @drafts/ref.md
```

Each iteration: mutate one preset field → run the full pipeline → eval the output → keep only if scores improve with no regressions. A holdout set prevents overfitting.

First run: **7.55 → 9.00** across 20 iterations.

## Skills

| Skill | What it does |
|-------|-------------|
| `/improve` | Diagnose → plan → staged revision passes → diff + explanations |
| `/build` | Rough notes or bullets → polished draft |
| `/adapt` | Convert between forms (essay → blog post, etc.) |
| `/eval` | Adversarial critic scores on 7 criteria with located failure points |
| `/create-preset` | Analyze example texts → synthesize a reusable preset |
| `/autoloop` | Mutation-eval self-improvement cycle |

## Presets

Three included — or create your own from examples:

- **blog-post** — conversational, engagement-weighted
- **argumentative-essay** — formal-analytical, thesis-driven
- **technical-explainer** — precise but accessible, clarity-first

```
/create-preset @example1.md @example2.md --name grant-proposal
```

## Setup

1. Clone this repo
2. Open in [Claude Code](https://claude.ai/claude-code)
3. Run `/improve @drafts/your-file.md`

## License

MIT
