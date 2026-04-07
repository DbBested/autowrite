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

**Input:** Bullet-point notes → `/build @drafts/blog-post-notes.md --preset blog-post`

```markdown
# Why most productivity advice is backwards

- people optimize for output (more tasks, more hours, more hustle)
- but the bottleneck is almost never output — it's input
- what you choose to work on matters 10x more than how fast you work on it
- nobody talks about the hard part: deciding what NOT to do
- example: I spent a year optimizing my task management system.
  Color coded labels, priority matrices, weekly reviews.
  I was incredibly organized and incredibly unproductive.
- the fix wasn't a better system. it was asking "if I could only do
  one thing today, what would it be?"
- controversial take: most "productivity" content is procrastination
  disguised as work
```

**Output:** Structured blog post with hook, argument, and close

```markdown
I spent a year building the perfect productivity system. Color-coded
labels, priority matrices, weekly reviews, the whole thing. I was
incredibly organized. I was also incredibly unproductive.

The system was flawless. The inputs were wrong.

Here's what I mean. Most productivity advice optimizes for output —
more tasks completed, more hours logged, more hustle. But the bottleneck
is almost never output. It's input. What you choose to work on matters
ten times more than how fast you work on it...

Here's the part that will bother you if you're deep in the productivity
world: most productivity content is procrastination disguised as work.
Reading about how to be productive feels like being productive. Setting
up a new system feels like progress. But none of it is the work itself.

You don't need a better system. You need a shorter list.
```

Full examples: [`drafts/`](drafts/) → [`runs/`](runs/)

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
