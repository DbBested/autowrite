---
paths:
  - "presets/*.json"
---

# Preset Editing Rules

When editing or creating a preset JSON file:

## Schema Compliance
- Every preset must include all required top-level fields: id, name, description, form, version, goals, stages, voice, structure, rubric, constraints, transformations, examples
- Run `bash scripts/validate-preset.sh <file>` after every edit and confirm it passes

## Voice Rules
- Voice rules must be behavioral descriptions, not scalar proxies
- Bad: "formality: 7/10"
- Good: "Uses first person throughout. Favors short sentences for emphasis."

## Rubric Integrity
- Rubric weights must sum to 1.0 (within 0.01 tolerance)
- `critical_criteria` must include at minimum `factual_integrity` and `voice_preservation`
- Every criterion must have name, description, and weight fields

## Stages
- `stages` array must list passes in the intended execution order for this form
- First stage should always be `diagnose`, second should be `revision-plan`

## Safety Defaults
- `constraints.no_citation_invention` must be true
- `constraints.no_stance_shift` must be true
- `transformations.preserveVoice` must be true unless aggressive rewrite is explicitly requested
