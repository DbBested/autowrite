# Autowrite

An auto-research inspired self-improvement loop for writing. Give it a draft, it diagnoses what's weak, runs staged revision passes, and scores the result. Then it mutates its own preset and keeps only the changes that measurably improve output quality.

Works for any writing form — essays, blog posts, technical docs, grant proposals, reports. Create a preset from examples of writing you admire and the system tunes itself to that standard.

**No dependencies. No install. Just [Claude Code](https://claude.ai/claude-code).**

<!-- TODO: Add demo GIF here -->
<!-- ![demo](assets/demo.gif) -->

## Start here in 60 seconds

```bash
git clone https://github.com/DbBested/autowrite.git
cd autowrite
```

Open the folder in Claude Code. Drop a draft into `drafts/`:

```
/improve @drafts/my-essay.md
```

That's it. Autowrite auto-detects the writing form, runs diagnosis + staged passes, and outputs a revised draft with diffs and explanations to `runs/`.

## Before and after

**Input:** 764 words of bullet-point notes

```markdown
## Thesis
The zombie within — the fact that most of our cognition is unconscious —
is evidence FOR materialism about consciousness, not against it.

## Core Argument
- Chalmers: we can conceive of a physical duplicate with no consciousness
- Neuroscience shows most cognitive processing is unconscious
- Blindsight patients process visual info without conscious experience
- If consciousness were non-physical, WHY would it attach to only SOME computations?
- P1: Most cognition is unconscious
- P2: Consciousness tracks specific computational features
- P3: Dualism has no principled explanation for this selectivity
- C: Materialism explains selectivity better than dualism

## Best Objection
- Correlation doesn't prove identity — like a radio receiving signals
...
```

**Output:** 1,917 words of structured argumentative essay

```markdown
One of the most influential arguments against materialism comes from the
philosopher David Chalmers. Materialism is the view that everything,
including consciousness, is physical. Chalmers challenges this view by
asking us to conceive of a "zombie": a being physically identical to a
human in every respect but with no conscious experience whatsoever. This
paper argues that the zombie concept, properly understood, actually
supports materialism rather than undermining it...

The third premise is the crucial one. If consciousness were a non-physical
property — something separate from physical processes — there would be no
principled explanation for why it accompanies only globally broadcast
processes and not local ones. A non-physical mind, by definition, is not
constrained by physical or functional features. There is nothing about
being non-physical that would make a substance responsive to one type of
neural computation rather than another...
```

Full before/after: [`drafts/philosophy-essay-notes.md`](drafts/philosophy-essay-notes.md) → [`runs/` output](runs/)

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

First run: **7.55 → 9.00** across 20 iterations (10 accepted, 10 rejected).

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

## License

MIT
