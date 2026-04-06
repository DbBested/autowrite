---
name: create-preset
description: Create a new preset from example texts or refine an existing preset with additional examples. Analyzes writing samples, synthesizes preset fields, displays annotated JSON for user review before saving. Usage: /create-preset @example.md --name my-preset
---

# /create-preset

Create a new preset JSON from one or more example texts, or refine an existing preset with additional examples. This skill analyzes example texts, synthesizes all preset schema fields, displays the full annotated result for review, and only writes the file after explicit user approval.

---

## Invocation

```
/create-preset @example1.md [@example2.md ...] --name <preset-id>
/create-preset @new-example.md --refine presets/<existing-id>.json
```

- `@<file>` — required: one or more example text files that represent the writing form (e.g., `@drafts/my-blog-post.md`)
- `--name` — required for create mode: the preset identifier slug (lowercase, hyphens only, no spaces, e.g., `--name technical-memo`)
- `--refine` — for refine mode: path to an existing preset JSON to update with new example analysis (e.g., `--refine presets/blog-post.json`)

---

## Step 1: Argument Parsing and Validation

### Parse flags

Extract from the invocation:
- All `@file` paths (the example texts)
- The `--name <id>` flag (create mode)
- The `--refine <path>` flag (refine mode)

### Validate: example files

For each `@file` provided, confirm the file exists using the Read tool. If any file is not found, STOP:
> "Example file not found: \<path\>"

If NO `@file` argument is provided at all, STOP:
> "At least one example text file is required. Usage: /create-preset @example.md --name my-preset"

If only one example file is provided, display this warning and continue — do not stop:
> "Note: 2–3 examples produce more reliable inferences. Single-example presets may need manual refinement."

### Validate: create mode

If `--name` is provided (create mode):
- Validate the name is a valid filename slug: lowercase letters, digits, and hyphens only, no spaces, no special characters
- If the name contains uppercase letters or spaces, STOP and suggest a corrected slug:
  > "Invalid preset name '\<name\>'. Use lowercase letters and hyphens only (e.g., '\<corrected-slug\>')"
- Check whether `presets/<name>.json` already exists. If it does, STOP:
  > "Preset presets/<name>.json already exists. Use --refine to update it, or choose a different name."

### Validate: refine mode

If `--refine` is provided (refine mode):
- Validate the path points to a file that exists (Read the file)
- If not found, STOP:
  > "Preset not found: \<path\>"
- If `--name` is also provided, ignore `--name` — refine mode uses the existing preset's `id`

### Mode determination

- If `--name` flag present → create mode
- If `--refine` flag present → refine mode (see Step 7)
- If neither → STOP: "Preset name required: /create-preset @file.md --name my-preset"

---

## Step 2: Analysis Pass

Read each example text file in full. For each example, extract the following signals:

### Writing form signals
- Is this thesis-driven (claim stated early, argued throughout)?
- Is this procedural / how-to (steps, numbered lists, "do this" framing)?
- Is this opinion-first (bold claim, then evidence)?
- Is this expository / explanatory (teaches a concept or system)?
- Is this narrative (story structure, scene-setting)?
- Are there citations or references? Academic or informal sourcing?
- What is the approximate word count and structure (sections, headers, paragraphs)?

### Tone register
- First-person ("I", "my", "we") — present or absent?
- Second-person ("you", "your") — present or absent? Peer address or instructional?
- Third-person neutral — predominant?
- Contractions present? ("don't", "isn't", "it's")
- Hedging language? ("it's worth noting", "one might argue", "in most cases")
- Confident assertions or measured qualifications?

### Sentence length distribution
- Short punchy sentences (under 12 words) — what percentage?
- Medium sentences (12–25 words) — what percentage?
- Long complex sentences (25+ words with subordinate clauses) — what percentage?
- Sentence fragments for emphasis — intentional and frequent?
- Overall: short-punchy, medium-varied, long-complex, or highly varied?

### Paragraph construction patterns
- Topic-sentence-led paragraphs (claim first, evidence follows)?
- Single-idea paragraphs (one point, 1–3 sentences)?
- Long multi-idea paragraphs (4+ sentences, thesis + evidence + explanation)?
- List-heavy structure (bullet points as main content)?
- Paragraph length: mostly short (1–3 sentences), medium (3–6), or long (6+)?

### Rhetorical moves
- Analogy and comparison (explains X by relating to Y)?
- Example-then-claim (concrete first, generalization second)?
- Question-and-answer (asks question, then answers)?
- Direct assertion (states claim without rhetorical setup)?
- Objection handling (raises counterarguments to address them)?
- Logos-primary (logic and evidence), ethos-primary (authority and trust), or pathos-primary (emotion and connection)?

### Vocabulary register
- Anglo-Saxon vocabulary dominant (short, common English words)?
- Latinate vocabulary dominant (longer, formal, technical words)?
- Technical density: low (accessible), medium (practitioner), or high (expert)?
- Jargon: domain-specific terms used without definition? Defined with explanation?
- Figurative language: metaphors, analogies, idiomatic expressions?

### Expected section structure
- Recognizable intro style: hook-first, thesis-forward, problem-first, scene-setting?
- Body structure: argument sections, step-by-step, claim-evidence-claim, conceptual blocks?
- Closing style: call-to-action, restate-and-broaden, strong-resonant-close, actionable-takeaway?
- Evidence style: inline citations, example blocks, numbered references, no citations?

### When multiple examples are provided

For each signal, note whether it is:
- **Convergent** — present consistently across all or most examples (higher inference confidence)
- **Divergent** — present in some examples but not others (lower confidence, flag for user review)

Convergent signals drive the inferred field values. Divergent signals are noted in annotations.

---

## Step 3: Synthesis Pass

Map extracted signals to preset schema fields. Every field must be explicitly inferred — do not leave any required field at a placeholder value.

### Identity fields

- `id` — use the `--name` slug exactly
- `name` — convert slug to title case (e.g., `technical-memo` → `"Technical Memo"`)
- `description` — 1-sentence description of the writing form derived from form signals. Be specific: "Opinion-first technical blog post for developer audiences" not "Writing form preset."
- `form` — same as `id`
- `version` — `"1.0.0"` for all new presets

### Goals

Derive 2–4 goal strings from form signals:
- Blog-like, opinion-driven → `["persuade", "engage"]`
- Explainer, how-to → `["inform", "educate"]`
- Argumentative, thesis-driven → `["persuade", "argue", "inform"]`
- Narrative, story-driven → `["engage", "resonate"]`
- Add "entertain" only if humor or lightness is a consistent signal

### Stages

Determine the appropriate pass sequence for this form. Rules:
- Must start with `"diagnose"` and `"revision-plan"` (always — required by preset-editing.md)
- Must end with `"final-review"` (always)
- Middle passes selected by form priority:
  - Blog/opinion → `["structure", "clarity", "argument", "tone", "concision", "hook", "ending"]`
  - Argumentative essay → `["structure", "argument", "evidence", "objection", "clarity", "tone", "concision"]`
  - Technical explainer → `["structure", "clarity", "precision", "examples", "concision"]`
  - Narrative/story → `["structure", "clarity", "tone", "hook", "ending"]`
  - Hybrid or ambiguous → use blog-post stages as default, annotate this inference

### Voice block (all 5 subfields required)

- `voice.tone` — behavioral description of tone (e.g., `"conversational"`, `"formal-analytical"`, `"precise-accessible"`, `"warm-instructional"`)
- `voice.formality` — behavioral description of formality level (`"informal"`, `"medium"`, `"high"`, `"semi-formal"`)
- `voice.sentenceLength` — behavioral description: `"short-punchy"`, `"medium-to-long"`, `"varied — mix short punchy sentences with occasional longer ones for rhythm"`, `"long-complex with subordinate clauses"`. Use a descriptive phrase, not a number.
- `voice.paragraphStyle` — behavioral description: `"short-punchy — most paragraphs 1–3 sentences"`, `"topic-sentence-led with full evidence development"`, `"long-form with multi-point paragraphs"`
- `voice.rhetoricalStyle` — primary approach: `"direct-assertion"`, `"logos-primary"`, `"expository"`, `"question-driven"`, `"narrative-illustration"`

### voiceBehaviors array (6–8 behavioral descriptions)

Generate 6–8 behavioral descriptions — observable instructions, NOT scalar proxies. Follow preset-editing.md rules strictly:
- BAD: `"formality: 7/10"` — this is a scalar proxy, never acceptable
- BAD: `"uses medium formality"` — not observable
- GOOD: `"Uses first person ('I', 'my') naturally throughout"` — observable behavior
- GOOD: `"Avoids corporate hedging phrases ('it is worth noting', 'one might argue')"` — specific and checkable

Each behavior must be an observable instruction a revision pass can check. Cover: person usage, contraction usage, sentence fragment stance, hedging language stance, reader address mode, vocabulary register preference, paragraph length tendency, and any distinctive rhetorical habits from the examples.

### Structure block (all 5 subfields required)

- `structure.expectedSections` — array of section names derived from the form. E.g., `["hook", "setup", "argument", "evidence", "close"]` for blog; `["introduction", "thesis", "body-argument-1", "body-argument-2", "counterargument", "conclusion"]` for essay; `["introduction", "concept-explanation", "steps", "examples", "summary"]` for explainer
- `structure.sectionOrder` — `"strict"` (essay, explainer), `"flexible"` (blog), or `"progressive"` (narrative)
- `structure.paragraphPatterns` — array of patterns, e.g., `["assertion-evidence", "single-idea"]` or `["claim-evidence-warrant", "long-form"]`
- `structure.introStyle` — e.g., `"hook-first"`, `"thesis-forward"`, `"problem-first"`, `"scene-setting"`, `"question-then-answer"`
- `structure.endingStyle` — e.g., `"strong-close"`, `"restate-and-broaden"`, `"actionable-takeaway"`, `"call-to-action"`, `"synthesis"`

### Rubric criteria (7 standard criteria with form-inferred weights)

Use these 7 standard criteria. Weights must sum to 1.0.

Weight distribution by inferred form:
- **Blog-like / engagement-heavy**: novelty 0.20, clarity 0.20, structure 0.15, voice_preservation 0.20, audience_fit 0.10, concision 0.10, factual_integrity 0.05
- **Argumentative-essay / structure-heavy**: novelty 0.15, clarity 0.15, structure 0.25, voice_preservation 0.15, audience_fit 0.10, concision 0.10, factual_integrity 0.10
- **Technical-explainer / clarity-heavy**: novelty 0.10, clarity 0.30, structure 0.20, voice_preservation 0.15, audience_fit 0.10, concision 0.10, factual_integrity 0.05
- **Hybrid or ambiguous**: use blog-post weights as default

For each criterion, write a description behavioral enough for an evaluator to apply:
- `novelty`: what "saying something worth saying" looks like for this form
- `clarity`: what "unambiguous on first read" means at this form's complexity level
- `structure`: what a coherent arc looks like for this form's expected sections
- `voice_preservation`: what "sounds like the author" means given the voice behaviors you documented
- `audience_fit`: the assumed reader and their expected knowledge level for this form
- `concision`: the standard for "nothing wasted" appropriate to this form's typical length
- `factual_integrity`: no invented citations, no fabricated claims, no silently altered positions

Safety defaults that are non-negotiable:
- `rubric.passing_threshold` — always `3.5` (legacy value required by schema; eval system uses score >= 6 on its own scale)
- `rubric.critical_criteria` — always `["factual_integrity", "voice_preservation"]`

### Constraints block (all 3 fields required)

Always set these values — they are safety defaults, not inferences:
- `constraints.no_citation_invention: true` — required, non-negotiable
- `constraints.no_stance_shift: true` — required, non-negotiable
- `constraints.aggressive_rewrite_requires_explicit_request: true` — always true unless user explicitly requests otherwise

### Transformations block (all 5 fields required)

- `transformations.preserveVoice: true` — always true; this is a safety default
- `transformations.allowMajorRestructure: false` — default false; set to true only if the form analysis strongly indicates structural reorganization is the primary value (e.g., very loose outline forms)
- `transformations.prioritizeClarity: true` for explainers and technical forms; `false` for blog/opinion forms
- `transformations.prioritizePersuasion: true` for argumentative forms only; `false` for all others
- `transformations.prioritizeConcision: false` by default; set to true only if the form examples showed heavily redundant writing as the primary weakness

### Examples array

Always `[]` — empty array. The user populates this manually if desired.

---

## Step 4: Display Annotated Draft JSON

Before displaying, say:

> "Here is the inferred preset based on your example(s). Every non-obvious inference is annotated with `# INFERRED:` explaining what signals drove it. Safety defaults are marked `# DEFAULT:`. Review each field and reply 'yes' to save, or describe what to change."

Display the full analysis summary block first:

```
# =============================================================================
# ANALYSIS SUMMARY
# Examples analyzed: N files (filename1.md, filename2.md, ...)
# Primary form signals: [list key convergent signals with evidence counts]
#   e.g., "first-person throughout all N examples"
#        "contractions in N/N examples"
#        "paragraph length <= 3 sentences in ~X% of paragraphs"
#        "opinion-before-evidence structure in N/N examples"
# Divergent signals (present in some examples only):
#   [list signals that varied across examples, if any]
# =============================================================================
```

Then display the complete preset JSON with `# INFERRED:` or `# DEFAULT:` comment annotations above each field group. Use this format:

```
{
  # INFERRED: id from --name flag
  "id": "<name>",
  "name": "<Title Case Name>",
  # INFERRED: <description source> — what signals identified this form
  "description": "<derived description>",
  "form": "<name>",
  # DEFAULT: version 1.0.0 for all new presets
  "version": "1.0.0",
  # INFERRED: goals from form signals — <brief explanation>
  "goals": [...],
  # INFERRED: stages — <form type> stage sequence; middle passes ordered by form priority
  "stages": [...],
  "voice": {
    # INFERRED: tone — <specific signals, e.g., "contractions in 100% of sentences, direct address throughout">
    "tone": "...",
    # INFERRED: formality — <signals, e.g., "no academic hedging, Anglo-Saxon vocabulary dominant">
    "formality": "...",
    # INFERRED: sentenceLength — <evidence, e.g., "~60% sentences under 15 words, frequent fragments">
    "sentenceLength": "...",
    # INFERRED: paragraphStyle — <evidence, e.g., "85% of paragraphs are 1-3 sentences">
    "paragraphStyle": "...",
    # INFERRED: rhetoricalStyle — <evidence, e.g., "3/3 examples open with direct claim before evidence">
    "rhetoricalStyle": "..."
  },
  # INFERRED: voiceBehaviors — derived from person usage, contraction, fragment, hedging patterns
  "voiceBehaviors": [
    "...",
    ...
  ],
  "structure": {
    # INFERRED: expectedSections — <form type> typical structure
    "expectedSections": [...],
    # INFERRED: sectionOrder — <evidence for strict/flexible/progressive>
    "sectionOrder": "...",
    # INFERRED: paragraphPatterns — from paragraph construction analysis
    "paragraphPatterns": [...],
    # INFERRED: introStyle — <evidence from how examples open>
    "introStyle": "...",
    # INFERRED: endingStyle — <evidence from how examples close>
    "endingStyle": "..."
  },
  "rubric": {
    # INFERRED: weights — <form type> weight distribution; highest weight to <criterion> (priority signal)
    "criteria": [
      {
        "name": "novelty",
        "description": "...",
        "weight": 0.XX
      },
      {
        "name": "clarity",
        "description": "...",
        "weight": 0.XX
      },
      {
        "name": "structure",
        "description": "...",
        "weight": 0.XX
      },
      {
        "name": "voice_preservation",
        "description": "...",
        "weight": 0.XX
      },
      {
        "name": "audience_fit",
        "description": "...",
        "weight": 0.XX
      },
      {
        "name": "concision",
        "description": "...",
        "weight": 0.XX
      },
      {
        "name": "factual_integrity",
        "description": "...",
        "weight": 0.XX
      }
    ],
    # DEFAULT: passing_threshold is 3.5 (legacy schema value — eval system uses >= 6 on its own scale)
    "passing_threshold": 3.5,
    # DEFAULT: critical_criteria always includes factual_integrity and voice_preservation
    "critical_criteria": ["factual_integrity", "voice_preservation"]
  },
  "constraints": {
    # DEFAULT: no_citation_invention must always be true — safety constraint, never inferred
    "no_citation_invention": true,
    # DEFAULT: no_stance_shift must always be true — safety constraint, never inferred
    "no_stance_shift": true,
    # DEFAULT: aggressive rewrites require explicit request — safety default
    "aggressive_rewrite_requires_explicit_request": true
  },
  "transformations": {
    # DEFAULT: preserveVoice always true — safety default
    "preserveVoice": true,
    # INFERRED: allowMajorRestructure — <rationale>
    "allowMajorRestructure": false,
    # INFERRED: prioritizeClarity — true for <form type>/false for <form type>
    "prioritizeClarity": true|false,
    # INFERRED: prioritizePersuasion — true only for argumentative forms
    "prioritizePersuasion": false,
    # INFERRED: prioritizeConcision — <rationale>
    "prioritizeConcision": false
  },
  # DEFAULT: empty array — user populates manually if desired
  "examples": []
}
```

---

## Step 5: User Approval Gate

**CRITICAL: NEVER write the file without explicit user approval. This is non-negotiable.**

After displaying the annotated JSON, ask:
> "Does this preset match your intent? Reply 'yes' to save to presets/\<id\>.json, or describe what to change."

### If user replies "yes" (or equivalent affirmative)

Proceed to Step 6: Write and Validate.

### If user requests changes

Apply the requested changes to the in-memory preset. For each changed field:
- Display only the changed fields with updated annotations
- Ask for approval again: "Updated. Does this look right? Reply 'yes' to save, or describe more changes."

Continue this review loop until the user provides explicit approval. Do not write the file at any point during the review loop — only after "yes."

### If user says "no" without specifying changes

Ask: "What would you like to change? You can describe changes in plain language (e.g., 'make the tone more formal', 'add a precision pass to the stages', 'increase the structure weight')."

---

## Step 6: Write and Validate

After receiving explicit user approval:

### Write the preset file

Write the preset JSON to `presets/<id>.json`. The written file must be clean JSON only — no annotation comments, no inline notes. The annotations shown to the user are for review only; the saved file must be valid JSON that passes schema validation.

### Validate immediately

Run:
```bash
bash scripts/validate-preset.sh presets/<id>.json
```

### If validation passes (exit 0)

Display:
> "Preset saved: presets/\<id\>.json (validated)"

### If validation fails (non-zero exit)

Do not consider the task complete. Display the specific validation error from the script output. Offer to fix the flagged field:
> "Validation failed: \<error from validate-preset.sh\>. Would you like me to fix the '\<field\>' field?"

Apply the fix, re-display the corrected field with annotation, ask for approval, and re-run validation. Repeat until validation passes.

---

## Step 7: Refine Mode (`--refine`)

When `--refine presets/<existing-id>.json` is provided:

### Step 7a: Load existing preset

Read the existing preset JSON file completely. Extract all current values.

### Step 7b: Run analysis pass

Run the full analysis pass (Step 2) on the provided example text(s).

### Step 7c: Synthesize inferred updates

Run the synthesis pass (Step 3) to produce inferred field values from the new examples.

### Step 7d: Compute differences

For each synthesized field: compare the inferred value with the existing preset value. Identify fields where the inferred value differs from the current value.

If no fields differ, say:
> "The new example(s) are consistent with the existing preset. No updates are suggested."

### Step 7e: Display side-by-side diff for changed fields only

Display only the fields that differ. For each changed field:

```
## Proposed Updates

### voice.tone
  Current:  "conversational"
  Inferred: "formal-accessible"
  Reason:   New example uses third-person throughout and avoids contractions — diverges from existing examples

### voiceBehaviors[2]
  Current:  "Avoids corporate hedging phrases ('it is worth noting')"
  Inferred: "Uses measured hedging to signal uncertainty ('typically', 'in most cases')"
  Reason:   New example uses hedging 8 times; existing preset treats hedging as a flag to remove

### rubric.criteria[voice_preservation].weight
  Current:  0.20
  Inferred: 0.25
  Note:     Would require rebalancing other weights to maintain 1.0 sum
```

Do NOT display fields that are unchanged.

### Step 7f: Ask which fields to update

> "Which of these proposed updates would you like to apply? Reply 'all', list specific fields (e.g., 'voice.tone and voiceBehaviors'), or 'none' to cancel."

### Step 7g: Apply approved changes

Apply only the approved changes. For rubric weight changes: if any weight is modified, recalculate other weights proportionally to maintain a 1.0 sum, display the rebalanced weights, and ask for confirmation.

### Step 7h: Bump patch version

Increment the patch version of the preset (e.g., `"1.0.0"` → `"1.0.1"`, `"1.2.3"` → `"1.2.4"`).

### Step 7i: Write and validate

Write the updated preset JSON (clean JSON, no annotations). Run `validate-preset.sh`. Display the result as in Step 6.

**Refinement never silently overwrites existing values — every proposed change requires explicit user approval per field or as a group.**

---

## Voice Preservation in Synthesized Presets

The `voiceBehaviors` array is the most important output of this skill. It anchors every subsequent revision pass against voice drift. Synthesize voiceBehaviors as observable, checkable instructions:

- **Person usage**: "Uses first person ('I', 'my') naturally throughout" or "Maintains third-person throughout; avoids first-person intrusions"
- **Contractions**: "Uses contractions consistently ('don't', 'isn't', 'can't')" or "Avoids contractions — formal register throughout"
- **Fragment stance**: "Allows sentence fragments for emphasis when rhythm calls for it" or "No sentence fragments — complete sentences only"
- **Hedging stance**: "Avoids corporate hedging phrases ('it is worth noting', 'one might argue')" or "Uses measured hedging to signal appropriate uncertainty ('typically', 'in most cases')"
- **Reader address**: "Addresses the reader directly with 'you' — assumes a peer relationship" or "Uses 'the reader' or third-person — maintains formal distance"
- **Vocabulary register**: "Favors Anglo-Saxon words over Latinate when both work" or "Technical vocabulary used precisely with context-appropriate density for expert audiences"
- **Paragraph length**: "Most paragraphs 1–3 sentences; single-idea per paragraph" or "Develops ideas fully — paragraphs typically 4–6 sentences with claim, evidence, and explanation"
- **Rhetorical habits**: any distinctive patterns from the examples (e.g., "Opens sections with a direct claim before evidence", "Uses rhetorical questions sparingly to set up points")

Each behavior must be specific enough that a revision pass can check it against the draft text. Generic instructions like "has a clear voice" are not acceptable.

---

## Factual Integrity Rules for Synthesized Presets

The create-preset skill must not fabricate analysis findings. When synthesizing preset fields:

- Do not invent form signals not present in the provided examples
- Do not assert convergence when signals are actually divergent across examples
- If the examples are too short (under 150 words each) or too heterogeneous to support a confident inference, flag it: "This field could not be confidently inferred from the provided examples — recommend providing longer or more consistent examples, or setting this field manually"
- Never infer that an example represents "the best" version of a form and optimize toward it — infer the characteristic patterns, not the ideal

---

## Edge Case Reference

| Situation | Action |
|-----------|--------|
| No `@file` provided | STOP — "At least one example text file is required. Usage: /create-preset @example.md --name my-preset" |
| File not found | STOP — "Example file not found: \<path\>" |
| `--name` missing in create mode | STOP — "Preset name required: /create-preset @file.md --name my-preset" |
| `--name` contains uppercase or spaces | STOP — "Invalid preset name '\<name\>'. Use lowercase letters and hyphens only (e.g., '\<corrected-slug\>')" |
| Preset `presets/<id>.json` already exists | STOP — "Preset presets/\<id\>.json already exists. Use --refine to update it, or choose a different name." |
| `--refine` target not found | STOP — "Preset not found: \<path\>" |
| Only one example provided | Warn: "Note: 2–3 examples produce more reliable inferences." Continue. |
| Examples are very short (<150 words each) | Flag affected inferences as low-confidence in annotations; continue |
| Examples are highly heterogeneous (signals diverge) | Annotate divergent fields clearly; default to blog-post weights for rubric |
| Rubric weights don't sum to 1.0 | Rebalance proportionally and annotate the adjustment before displaying |
| `validate-preset.sh` fails after write | Show specific error, offer to fix the flagged field, do not consider task complete |
| User replies "no" at approval gate | Ask what to change; re-synthesize changed fields; re-display; ask again |
| User requests a change that would require `no_citation_invention: false` | Refuse — "This constraint cannot be disabled. It is a safety default required by the preset schema." |
| `--refine` with no fields differing | Display — "The new example(s) are consistent with the existing preset. No updates are suggested." |
| Rubric weight change in refine mode | Rebalance other weights proportionally; display rebalanced set; ask for confirmation before writing |
