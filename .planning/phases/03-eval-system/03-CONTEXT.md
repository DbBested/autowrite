# Phase 3: Eval System - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Isolated critic subagent producing criterion-level scores and stable eval snapshot JSON. User invokes `/eval` skill to evaluate any text against a preset's rubric. The eval agent runs in a separate context window, sees only the text and rubric, and produces a machine-readable JSON snapshot with scores, failure points, and explanations. No autoloop, no preset creation — those are Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Eval Invocation
- `/eval @output.md --preset blog-post` or auto-detect preset from latest run directory
- Eval output goes to the same run directory as the revision: `runs/<run>/eval.json`
- Eval can run standalone: `/eval @any-text.md --preset X` works on any text, not just revision outputs
- Score scale: 1-10 integer per criterion, no decimals — simple and comparable

### Critic Agent Design
- `.claude/agents/eval-critic.md` subagent — runs in separate context window, sees only the text and rubric
- Critic is explicitly instructed to be hyper-critical, find flaws, never praise — adversarial framing in agent file
- Preset `rubric.criteria` loaded directly — each criterion scored independently, then weighted aggregate computed
- Consistency via temperature=0 in agent instructions + anchored criteria with specific observable behaviors per score level

### Eval Snapshot Schema
- JSON structure: `{preset, timestamp, criteria: [{name, score, weight, pass, failure_points: [{location, description, severity}], explanation}], aggregate_score, aggregate_pass}`
- Failure points are specific and located with severity: critical/major/minor — e.g., "Paragraph 3: thesis buried after anecdote (major)"
- Pass/fail threshold: score >= 6 is pass, < 6 is fail per criterion; aggregate pass requires all criteria pass AND weighted average >= 6
- Preset can add optional criteria beyond the 7 core — scored and included in snapshot but not in aggregate unless weight > 0

### Claude's Discretion
- Exact adversarial prompting language in the agent file
- Anchored score level descriptions (what a 3 vs 7 vs 10 looks like per criterion)
- How to handle edge cases: very short texts, texts with no clear form, missing preset fields
- Whether to include a human-readable eval summary alongside the JSON snapshot

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project context
- `.planning/PROJECT.md` — Core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — EVAL-01 through EVAL-06

### Prior phase artifacts
- `.claude/skills/improve/SKILL.md` — Core revision engine (eval integrates with its run directory output)
- `presets/blog-post.json` — Reference preset with rubric.criteria structure
- `.planning/research/PITFALLS.md` — Eval self-preference bias, Goodhart's Law warnings

### Research findings
- `.planning/research/STACK.md` — Eval critic subagent isolation pattern, context: fork
- `.planning/research/ARCHITECTURE.md` — Eval system component boundaries, data flow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/skills/eval/` — empty skill directory ready for SKILL.md
- `.claude/agents/` — empty agents directory ready for eval-critic.md
- `presets/*.json` — three presets with `rubric.criteria` arrays defining scoring dimensions
- `runs/` directory structure — eval.json will be written here alongside revision artifacts

### Established Patterns
- One SKILL.md per writing task (Phase 1 D-04)
- JSON for all structured data (Phase 1 D-02)
- Path-scoped rules via `.claude/rules/*.md` (Phase 1 D-07)
- Run directory artifacts at `runs/YYYY-MM-DD_HH-MM-SS_preset-name/` (Phase 2)

### Integration Points
- `/eval` skill reads preset JSON for rubric criteria and weights
- Eval snapshot (eval.json) written to run directory alongside revision artifacts
- `/improve` SKILL.md metadata.json can reference eval results in future phases

</code_context>

<specifics>
## Specific Ideas

- The eval critic must never see the conversation history or know it's evaluating its own model's output — isolation prevents self-preference bias
- Anchored criteria should define what specific observable behaviors correspond to each score level (not just "good" vs "bad")
- The 7 core criteria (novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity) must always be scored; preset-specific criteria are additive

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-eval-system*
*Context gathered: 2026-04-05*
