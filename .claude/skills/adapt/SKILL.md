# /adapt

Adapt a piece of writing from one form to another.

## What This Skill Does

Takes an existing draft written in one form (e.g., blog post) and adapts it to a different writing form (e.g., argumentative essay) by running the /improve engine with the TARGET form's preset. The adaptation is driven by the target preset's pass sequence, structure expectations, voice rules, and rubric criteria — not the source form's.

## Invocation

```
/adapt @<draft-file> --to <target-preset-id> [--depth light|standard|deep]
```

- `@<draft-file>` — required: the draft to adapt (e.g., `@drafts/my-blog-post.md`)
- `--to` — **REQUIRED**: target writing form preset ID (`blog-post`, `argumentative-essay`, `technical-explainer`)
- `--depth` — optional: `light`, `standard`, or `deep`. Default: `deep` (form adaptation is a substantial transformation)

If `--to` is omitted, STOP and say:
> "`/adapt` requires a target form. Re-run with `--to blog-post`, `--to argumentative-essay`, or `--to technical-explainer`."

## How It Works

This skill runs the same workflow as /improve with these overrides:

1. **Preset is always the TARGET form** — `--to argumentative-essay` loads `presets/argumentative-essay.json`. The source form's preset is NOT loaded. All passes are driven by the target preset's stages, voice rules, structure expectations, and rubric criteria. Per Phase 2 research: use target preset for all passes — the structure pass must know the target form's expectations.

2. **Diagnosis focuses on form gaps** — in addition to diagnosing weaknesses in the draft, the diagnosis pass (Step 4 in /improve) identifies what the draft is MISSING relative to the target form. Examples:
   - Blog post → essay: "Missing formal thesis statement. No counterargument section. Contractions throughout need formal register."
   - Essay → blog post: "Too formal — no conversational hooks. Paragraph 3 is 200 words (target: 80–120). No direct reader address."
   - Any → technical explainer: "No step-by-step structure. Missing concrete examples. Jargon undefined."
   The `diagnosis.md` file should include a **Form Gaps** section for this analysis (in addition to the standard Weaknesses sections).

3. **Voice behavior is ADAPTATION** — not preservation of the source form's voice, not establishment from scratch. The author's core voice (personality, perspective, characteristic patterns) is preserved, but the REGISTER shifts to match the target form. Example: adapting a casual blog post to a formal essay removes contractions but keeps the author's argumentative style and characteristic sentence rhythms.

4. **Depth defaults to "deep"** — form adaptation is a substantial transformation that benefits from all passes plus the second targeted pass on the weakest criterion.

5. **metadata.json records the adaptation:**
   - `input_type` is set to `"adaptation"` (not `"draft"` or `"rough notes"`)
   - Additional field: `"adapted_from": "<source_form_if_detectable>"` — attempt to detect the source form from content signals; use `"unknown"` if ambiguous

6. **Everything else is identical to /improve:**
   - Run directory creation (uses target preset ID in directory name, same artifact set) — Step 2
   - Pass execution with per-pass voice injection (target preset voice block and voiceBehaviors) — Step 6
   - Factual integrity rules apply on every pass — no invented facts, no fabricated citations
   - Final review and artifact generation (output.md, diff.patch, explanation.md, metadata.json) — Step 7

## When to Use /adapt vs /improve

- Use **/adapt** when changing the FORM: blog post → essay, essay → explainer, explainer → blog post
- Use **/improve** when improving within the SAME form: a better blog post, a stronger essay
- /adapt always requires `--to` — it must know the target form to load the correct preset

## Factual Integrity

Form adaptation does not relax factual integrity rules. The passes may restructure arguments and shift register, but they must not:
- Invent citations or references not present in the source draft
- Fabricate statistics, examples, or claims
- Add factual assertions the author did not make
- Silently shift the author's argumentative position
If the target form requires evidence that the source draft lacks (e.g., essay form expects citations for claims), flag the gap for the author — do not invent the evidence.

## Execution

Follow the /improve SKILL.md workflow exactly (all 7 steps), with these overrides:

1. Load preset from `--to` flag — no auto-inference. `--to` is required.
2. In Step 4 (diagnosis): include a **Form Gaps** section identifying what the draft is missing for the target form.
3. Voice mode is ADAPTATION: preserve the author's core voice patterns, shift register to match the target preset's voice rules.
4. Depth defaults to `deep`.
5. In Step 7 (metadata.json): set `input_type` to `"adaptation"` and include `"adapted_from"` field.
