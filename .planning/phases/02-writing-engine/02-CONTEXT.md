# Phase 2: Writing Engine - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Staged revision workflow from user-submitted draft to revised output. User invokes `/improve` skill with a draft file, system diagnoses weaknesses, generates a revision plan, applies preset-driven staged passes, and outputs a revised draft with diffs, explanations, and a complete run log. Also supports notes-to-draft (`/improve` detects notes vs draft) and form adaptation (`/adapt` with target preset). No eval system, no autoloop — those are later phases.

</domain>

<decisions>
## Implementation Decisions

### Skill Invocation
- User invokes via `/improve @draft.md` — preset auto-detected from content with `--preset` override flag
- Preset auto-inference analyzes content and selects the closest matching preset; user can override with `--preset blog-post` etc.
- Notes-to-draft uses the same `/improve` skill — it detects whether input is rough notes or a polished draft and adjusts passes accordingly
- Form adaptation uses `/adapt @draft.md --to essay` — reuses the improve engine with the target preset applied

### Pass Execution
- Single `/improve` SKILL.md runs all passes sequentially in one session — each pass writes its output to the run directory
- Preset `stages` field defines the pass sequence — all stages listed in the active preset run by default
- Each pass prompt includes explicit DO NOT touch constraints (e.g., clarity pass must not restructure paragraphs; structure pass must not edit sentence-level wording)
- `--depth light/standard/deep` flag controls how many passes run: light = 3 core passes (diagnose, plan, structure), standard = all preset stages, deep = all stages plus a second pass on weakest criteria

### Run Directory Structure
- Run directories named `runs/YYYY-MM-DD_HH-MM-SS_preset-name/` — timestamped, immutable
- Each run contains: input.md, diagnosis.md, plan.md, passes/01-structure.md through NN-final.md, output.md, diff.patch, metadata.json
- Metadata JSON includes: preset used, pass sequence, timestamps per pass, input word count, output word count, revision depth
- Symlink `runs/latest` points to most recent run directory for quick access

### Diff and Explanation Format
- Unified diff (`diff -u`) saved as `diff.patch` — human-readable, standard format
- `explanation.md` lists each major change with rationale, grouped by pass
- One explanation per substantive change (structural moves, argument reframes, voice adjustments) — not per word change
- `output.md` is a clean revised draft with no annotations or markup

### Claude's Discretion
- Exact prompt engineering for each pass (specific DO NOT touch constraints per pass type)
- How to detect notes vs draft in the input
- How to auto-infer preset from content
- Pass ordering within "light" depth mode (which 3 core passes)
- Internal error handling and recovery during multi-pass execution

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `presets/blog-post.json`, `presets/argumentative-essay.json`, `presets/technical-explainer.json` — three hand-tuned presets with stages, voice rules, rubric criteria
- `presets/preset-schema.json` — JSON Schema draft-07 for preset validation
- `scripts/validate-preset.sh` — jq-based preset validator
- `.claude/skills/improve/`, `.claude/skills/build/`, `.claude/skills/adapt/` — empty skill directories ready for SKILL.md files
- `CLAUDE.md` — universal safety rules (factual integrity, voice preservation, stance integrity, pass scope)

### Established Patterns
- One SKILL.md per writing task (from Phase 1 D-04)
- JSON for all structured data (from Phase 1 D-02)
- Path-scoped rules via `.claude/rules/*.md` with `paths:` frontmatter (from Phase 1 D-07)

### Integration Points
- Skills read preset JSON files from `presets/` directory
- Run artifacts written to `runs/` directory
- CLAUDE.md safety rules active during all skill execution
- `.claude/rules/preset-editing.md` activates when working with preset files

</code_context>

<specifics>
## Specific Ideas

- The pass sequence is fully defined by the preset's `stages` field — no hardcoded pass list in the skill
- Voice preservation must be enforced per-pass via explicit constraints, not just a global rule
- Diagnosis should name specific weaknesses (e.g., "buried thesis in paragraph 3", "no evidence for claim in section 2") not generic advice

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-writing-engine*
*Context gathered: 2026-04-05*
