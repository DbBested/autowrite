# Milestones

## v1.0 MVP (Shipped: 2026-04-06)

**Phases completed:** 4 phases, 8 plans, 12 tasks

**Key accomplishments:**

- Three deeply-tuned preset JSON files covering blog post (conversational), argumentative essay (formal-analytical), and technical explainer (precise-accessible) writing forms — each with 8 behavioral voice descriptors, form-specific rubric weight distributions, ordered pass sequences, and universal safety constraints.
- 14 per-pass scope constraint rules files covering every pass type across all three presets, with explicit DO NOT touch boundaries, voice preservation instructions, and factual integrity constraints in every file
- 390-line /improve SKILL.md orchestrating preset-driven staged revision from diagnosis through multi-pass execution, diff generation, explanation, and metadata logging — with per-pass voice injection and factual integrity contracts
- Adversarial eval critic subagent with anchored 7-criterion rubric and preset-driven /eval skill producing isolated, located, machine-readable eval.json snapshots
- Text-to-preset synthesis skill with analyze-synthesize-display-approve-save pipeline, --refine mode, and explicit approval gate preventing silent writes
- Explicit `--reference-draft` flag required:

---
