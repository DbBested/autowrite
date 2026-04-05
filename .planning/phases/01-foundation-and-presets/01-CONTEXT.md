# Phase 1: Foundation and Presets - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Repo structure, universal safety rules (CLAUDE.md + rules files), preset JSON schema definition, three hand-tuned presets (blog post, argumentative essay, technical explainer), and a preset validation script. No writing engine, no eval system, no autoloop — those are later phases.

</domain>

<decisions>
## Implementation Decisions

### Preset file format
- **D-01:** Presets are JSON files stored in `presets/` directory, one file per preset (e.g., `presets/blog-post.json`, `presets/argumentative-essay.json`, `presets/technical-explainer.json`)
- **D-02:** JSON chosen because it is processable by jq in hook shell scripts, by Python stdlib, and natively by Claude — no additional dependencies needed
- **D-03:** Preset schema follows the TypeScript type definition from the design document: name, description, form, goals, stages, voice (tone, formality, sentenceLength, paragraphStyle, rhetoricalStyle), structure (expectedSections, sectionOrder, paragraphPatterns, introStyle, endingStyle), rubric (criteria with name/description/weight), constraints, transformations (preserveVoice, allowMajorRestructure, prioritizeClarity, prioritizePersuasion, prioritizeConcision), examples

### Skill structure
- **D-04:** One SKILL.md per writing task — each skill is a separate `.claude/skills/<name>/SKILL.md` file
- **D-05:** Phase 1 creates the directory scaffold for skills but does not implement writing skills (those are Phase 2). Phase 1 focuses on preset schema and validation only.

### Rules architecture
- **D-06:** CLAUDE.md holds universal safety rules only: no fabricated citations, voice preservation by default, no silent stance shifts, factual integrity enforcement. Must stay under 300 lines.
- **D-07:** `.claude/rules/*.md` files with `paths:` frontmatter for context-lean, conditionally-activated rules (e.g., rules that activate when working with preset files, rules that activate during revision passes)
- **D-08:** Rules files are created as needed — Phase 1 creates foundational rules for preset editing; Phase 2 adds pass-specific rules

### Preset validation
- **D-09:** Shell script (`scripts/validate-preset.sh`) using jq to check all required fields exist and have correct types
- **D-10:** Validation script exits non-zero on any missing/malformed field with a clear error message naming the field and expected type

### Claude's Discretion
- Exact directory naming within the repo scaffold (drafts/, presets/, skills/, evals/, autoloop/, scripts/, runs/ are specified, but internal structure is flexible)
- Voice rule granularity within each preset (how specific to make tone descriptors, formality scale, etc.)
- Rubric weight distribution across criteria for each preset
- Whether to include a JSON Schema file alongside the validation script

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements are fully captured in decisions above and in:

### Project context
- `.planning/PROJECT.md` — Core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — FOUND-01 through FOUND-03, PRES-01 through PRES-05

### Research findings
- `.planning/research/STACK.md` — SKILL.md format, JSON preset patterns, hook conventions, rules file architecture
- `.planning/research/ARCHITECTURE.md` — Component boundaries, preset-as-single-source-of-truth pattern, build order
- `.planning/research/PITFALLS.md` — CLAUDE.md bloat risk (>300 lines), voice rule design pitfalls, preset schema depth requirements

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- None yet — this phase establishes the foundational patterns

### Integration Points
- Preset JSON files will be read by writing engine skills (Phase 2), eval critic subagent (Phase 3), and autoloop (Phase 4)
- CLAUDE.md universal rules will be active for all subsequent phases
- Rules files with paths: frontmatter will activate conditionally for future skills

</code_context>

<specifics>
## Specific Ideas

- Preset schema should match the TypeScript type from the design document as closely as possible — this is the canonical schema definition
- Voice rules should capture actual voice characteristics (sentence rhythm, hedging patterns, vocabulary register) not shallow proxies like formality sliders
- Each of the three presets should be deeply tuned — better to have three excellent presets than ten shallow ones

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-and-presets*
*Context gathered: 2026-04-05*
