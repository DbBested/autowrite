# /build

Build a polished draft from rough notes, outlines, or fragments.

## What This Skill Does

Takes rough notes, bullet points, outlines, or incomplete fragments and builds them into a polished piece using the /improve engine in notes-to-draft mode. The key difference from /improve: the input is ALWAYS treated as rough notes, even if it contains some complete sentences. This gives the structure and argument passes broader latitude to expand and organize material.

## Invocation

```
/build @<notes-file> [--preset <preset-id>] [--depth light|standard|deep]
```

- `@<notes-file>` — required: the notes or outline file to build from (e.g., `@drafts/rough-notes.md`)
- `--preset` — optional: preset ID to use (e.g., `--preset blog-post`). If omitted, auto-infer from content.
- `--depth` — optional: `light`, `standard`, or `deep`. Default: `standard` (notes benefit from all passes)

## How It Works

This skill runs the same workflow as /improve with these overrides:

1. **Input classification is forced to "rough notes"** — the diagnosis step (Step 4 in /improve) skips auto-detection and labels the input as notes regardless of its content. This means:
   - The structure pass has permission to create new sections, reorder, and expand material — not just reorganize existing structure
   - The argument pass may expand undeveloped points within factual integrity rules — no invented facts
   - Voice behavior is ESTABLISHMENT (matching the preset's target voice for the form), not PRESERVATION — the notes may not have a consistent voice yet, so do not anchor to an incoherent register
   - `diagnosis.md` is labeled `Input classified as: rough notes` and notes that expanded structure pass latitude is in effect

2. **Depth defaults to "standard"** — notes benefit from the full pass sequence, not just the light subset

3. **Everything else is identical to /improve:**
   - Preset loading (auto-infer or --preset flag) — Step 1
   - Run directory creation (same naming convention, same artifact set) — Step 2
   - Pass sequence from preset.stages — Step 3
   - Pass execution with per-pass voice injection — Step 6
   - Final review and artifact generation (output.md, diff.patch, explanation.md, metadata.json) — Step 7

## When to Use /build vs /improve

- Use **/build** when starting from scratch: bullet points, meeting notes, research notes, rough outlines, fragment collections
- Use **/improve** when you have a draft that needs revision: complete sentences, clear structure, developed arguments
- When in doubt, use /improve — its auto-detection will classify notes correctly and apply the same expanded latitude

## Factual Integrity

The expanded latitude granted to notes-to-draft mode does NOT relax factual integrity rules. The structure and argument passes may expand and organize material, but they must not:
- Invent citations or references not present in the notes
- Fabricate statistics, examples, or claims
- Add factual assertions the author did not include in the notes
If a point in the notes is underdeveloped and cannot be expanded without inventing facts, flag it for the author — do not fill the gap.

## Execution

Follow the /improve SKILL.md workflow exactly (all 7 steps), with this single override in Step 4:

> Force `input_type` to "rough notes". Do not run the classification criteria check. Write `Input classified as: rough notes` at the top of `diagnosis.md`. Note that expanded structure pass latitude is in effect for this run.

All other steps — preset loading, run directory creation, pass execution, voice injection, final review, artifact generation — are identical to /improve.
