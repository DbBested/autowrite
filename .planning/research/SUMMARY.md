# Project Research Summary

**Project:** Autowrite
**Domain:** Claude Code-native AI writing improvement and revision system
**Researched:** 2026-04-05
**Confidence:** HIGH

## Executive Summary

Autowrite is a Claude Code-native writing revision system, not a web app or GUI tool. Experts in this space build iterative, multi-pass revision systems that preserve author voice by default and evaluate outputs using separate critic agents — not the same model that generated the revision. The core architecture is a local file store as an inter-component bus: entry-point skills invoke a writing engine that reads preset JSON files to determine pass sequence, voice rules, and rubric criteria; a dedicated subagent handles evaluation in a separate context window; and every artifact (draft, diff, explanation, eval snapshot, run log) is a timestamped local file. This architecture is fully inspectable, version-controllable, and directly scriptable — the primary differentiator versus GUI-based competitors like Grammarly, ProWritingAid, and Sudowrite.

The recommended stack is entirely Claude Code primitives: SKILL.md files (the new first-class invocation system, not legacy commands), a dedicated eval critic subagent in `.claude/agents/`, JSON preset files (not YAML — jq-processable), and PostToolUse/Stop hooks for artifact management. There are no external services, no HTTP APIs, no Python packages, and no install dependencies. The only shell tooling required is bash, jq, and git — all available everywhere. Three hand-tuned presets (blog post, argumentative essay, technical explainer) are sufficient for launch; a preset creation flow from example texts is a validated v1.x addition.

The dominant risks are voice homogenization (the model's statistical defaults overwrite author style), Goodhart's Law in the self-improvement loop (the system optimizes for metrics rather than real quality), and eval self-preference bias (Claude scores Claude's own output too generously). All three risks must be addressed architecturally before they are addressed in prompts: voice preservation must be a preset schema field and an eval criterion; the eval agent must run in a separate context with adversarial framing; and the autoloop must maintain a frozen holdout set outside the mutation cycle. Getting any of these wrong in Phase 1 or 2 propagates through every subsequent phase.

## Key Findings

### Recommended Stack

Autowrite is built entirely on Claude Code's native primitives. SKILL.md files in `.claude/skills/` are the primary invocation layer — this is the forward path per official Claude Code v2.x documentation, replacing the legacy `.claude/commands/` approach. CLAUDE.md should be kept under 300 lines and scoped to repo-wide universal behavior only; form-specific rules belong in skill files loaded on demand. Rules files in `.claude/rules/` support path-scoped loading for additional modular rules.

All structured data (presets, eval results, run snapshots) is JSON — not YAML. This is a load-bearing decision: jq processes JSON natively in hook scripts; YAML cannot be processed without an external parser not available everywhere. Python stdlib only (no pip packages) is used for string processing beyond jq's capability. Hooks in `.claude/settings.json` automate artifact generation post-write without burdening skill logic.

**Core technologies:**
- `CLAUDE.md` + `.claude/rules/` — universal safety rules and path-scoped behavior, kept under 300 lines total
- `.claude/skills/<name>/SKILL.md` — executable invocation points for each workflow (/improve, /build, /eval, /autoloop, /create-preset)
- `.claude/agents/writing-critic.md` — dedicated eval subagent, separate context window, adversarial persona, read-only tools
- `presets/*.json` — JSON files defining form, goals, pass sequence, voice rules, rubric, and constraints (single source of truth for "good")
- `runs/<timestamp>/` — immutable per-run artifact directory (output, diff, explanation, eval snapshot)
- `bash` + `jq` + `git diff --no-index` — hook scripts and pipeline glue, zero install friction
- PostToolUse hook on Write matching `**/runs/**/output.md` — auto-generates diff when engine completes a run

### Expected Features

**Must have (table stakes):**
- Draft diagnosis before any rewriting — users burned by blind AI rewrites expect this; must be form-specific via preset
- Revision plan generation before passes begin — structured, user-visible, pass-constraining document
- Staged revision passes (diagnose → plan → structure → clarity → argument → tone → concision → final review) — each pass narrow in scope with explicit DO NOT touch instructions
- Voice preservation by default — top complaint against all competitors; requires voice fingerprint extraction in diagnose pass and voice criterion in eval rubric
- Factual integrity constraint on all passes — hard constraint, not prompt guideline; post-pass validation for new assertions
- Diff output (input vs. revised draft) — programmatic, not LLM-described; generated by diff.sh script
- Change explanation per pass — rationale for every change, not a single summary
- Three hand-tuned presets (blog post, argumentative essay, technical explainer) — deeply tuned, not shallow
- Eval agent with criterion-level scoring — separate subagent, observable anchored criteria, temperature=0
- Eval snapshot as persistent JSON artifact — required for before/after comparison and autoloop input

**Should have (competitive differentiators):**
- Preset schema with full voice + structure + rubric spec in a single reusable JSON — no competitor does this
- Eval-driven self-improvement loop for preset/skill mutation — borrowing from PromptBreeder/PromptWizard; requires holdout set and hard acceptance rules
- Preset creation from example texts — infers form, voice, and structure; shows all inferred fields before saving

**Defer (v2+):**
- Additional first-party presets (newsletter, business memo, personal essay, README) — validate three first
- Adapt-a-piece flow (blog → essay form transformation) — complex bridging pass, defer until core is stable
- External integrations (Google Docs, Notion, Obsidian) — distribution problem, not quality problem; defer indefinitely

### Architecture Approach

The architecture treats the local file system as the inter-component bus. Components communicate exclusively through reading and writing files — no in-process APIs, no function calls across component boundaries, no shared mutable state. The writing engine reads the preset to determine what passes to run and in what order; each pass writes to a separate intermediate file; the eval subagent reads output files and writes score files in a fully separate context window; the autoloop reads eval snapshots to compare before/after mutation scores. Nothing in the autoloop overwrites canonical preset or skill files without explicit acceptance.

**Major components:**
1. **Entry point skills** (`.claude/skills/`) — accept user input, load preset, invoke engine; one skill per workflow
2. **Preset system** (`presets/*.json`) — single source of truth for what "good" means per form; governs pass sequence, voice rules, rubric, and constraints
3. **Writing engine** (CLAUDE.md + skill pass logic) — orchestrates staged passes; each pass reads preset and prior pass output; writes to `runs/<slug>/`
4. **Eval system** (`.claude/agents/writing-critic.md`) — dedicated subagent, adversarial persona, criterion-level scoring against preset rubric, temperature=0
5. **Autoloop** (`autoloop/` + scripts) — mutation-eval cycle for system self-improvement; non-destructive by default; holdout set for drift detection
6. **File store** (`drafts/`, `runs/`, `evals/`, `autoloop/`) — immutable timestamped directories; all artifacts local and version-controllable

### Critical Pitfalls

1. **Voice homogenization** — LLM defaults erase author style. Prevention: extract voice fingerprints in the diagnose pass; encode voice rules in preset schema; treat voice preservation as a hard eval criterion with a regression floor. Must be designed into Phase 1 (Preset System) and Phase 2 (Writing Engine). Retrofit cost is high.

2. **Single-shot rewriting disguised as staged passes** — without explicit scope constraints, every pass becomes a full rewrite. Prevention: each pass prompt must contain explicit DO NOT touch boundaries; revision plan generates per-pass constraints; diff-aware token-change check after each pass. Build this into pass architecture from the start.

3. **Eval self-preference bias** — Claude inflates scores for its own outputs. Prevention: eval agent must have a separate context window, adversarial system prompt framing, and observable anchored criteria (not holistic quality scores). Architectural separation is required, not just prompt framing. Must be addressed before the autoloop is wired.

4. **Goodhart's Law in the autoloop** — the system optimizes for metrics rather than real quality within 10-20 iterations. Prevention: frozen holdout set outside the mutation cycle; acceptance rule requires aggregate improvement with no critical regressions; metrics must include structural observables (word count ratio, sentence start diversity) that are harder to game. Never deploy the autoloop to users without the holdout set in place.

5. **CLAUDE.md / SKILL.md bloat causing instruction dropout** — above ~300 lines, Claude begins ignoring instructions buried in the middle. Prevention: CLAUDE.md contains only universal safety rules; form-specific behavior lives in skill files loaded on demand; each pass has its own skill file. Design for on-demand loading from Phase 1 — retrofitting a bloated CLAUDE.md is painful.

## Implications for Roadmap

Based on research, the architecture mandates a strict build order driven by component dependencies. The preset schema is the foundational artifact that every other component depends on. The eval system must be stable before the autoloop is built. Voice preservation must be in the foundation, not added later.

### Phase 1: Foundation — File Store, CLAUDE.md, and Preset Schema

**Rationale:** The preset schema is the single source of truth for "good" — every other component reads from it. The file store directory structure must be defined before any component writes to it. CLAUDE.md universal rules must be established first to avoid bloat accumulation. Nothing else can be built correctly without these.
**Delivers:** Stable preset schema for all three forms (blog-post, argumentative-essay, technical-explainer); repo directory structure; CLAUDE.md with universal safety rules (no fabricated citations, no silent stance shifts, no aggressive rewrite by default); JSON schema validation script for presets.
**Addresses:** Preset schema (P1 table stakes foundation), voice preservation design, factual integrity constraint design.
**Avoids:** Pitfalls 1 (voice homogenization), 5 (CLAUDE.md bloat), 6 (diagnosis without form awareness). All three are impossible to fix cheaply after Phase 2 begins.

### Phase 2: Writing Engine — Diagnose, Plan, and Core Revision Passes

**Rationale:** The writing engine can only be built against a stable preset schema (Phase 1). Passes are developed incrementally: diagnose first (extracts voice fingerprints and identifies weaknesses), revision plan second (scopes subsequent passes), then structural passes before stylistic passes. Each pass must have scope constraints baked in from the start.
**Delivers:** /improve skill entry point; diagnose pass (voice fingerprint extraction, form-aware weakness identification); revision plan pass; core passes: structure, clarity, argument, tone, concision, final review; diff.sh script (programmatic diff, not LLM-described); change explanation per pass; run artifact structure in `runs/<slug>/`.
**Uses:** SKILL.md with `disable-model-invocation: true` for all revision passes; PostToolUse hook to auto-generate diff on output.md write; `git diff --no-index --color-words` for human-readable diffs.
**Implements:** Writing engine and file store components.
**Avoids:** Pitfall 2 (single-shot rewriting disguised as stages) — per-pass DO NOT touch constraints designed here; Pitfall 7 (factual stance mutation) — post-pass validation gate built into argument/evidence passes.

### Phase 3: Eval System — Critic Subagent and Eval Snapshots

**Rationale:** The eval system requires stable outputs from Phase 2 to score. Building eval before the engine produces nothing meaningful to evaluate. The eval subagent must be fully operational and calibrated (variance < 1 point across 3 runs on the same input) before the autoloop can use it as a reliable signal.
**Delivers:** writing-critic subagent (`.claude/agents/writing-critic.md`); /eval skill; criterion-level rubric scoring against preset; eval snapshot JSON schema and writer; eval calibration test (same draft, 3 runs, zero variance at temperature=0); before/after comparison tooling.
**Avoids:** Pitfall 3 (eval self-preference bias) — architecturally separate context, adversarial framing, observable anchored criteria (not holistic scores), temperature=0; Pitfall 8 (eval score inconsistency) — calibration test is a required deliverable, not optional.

### Phase 4: Autoloop — Mutation-Eval Cycle for Self-Improvement

**Rationale:** The autoloop depends on the eval system (Phase 3) producing reliable signals and the writing engine (Phase 2) producing stable outputs. It is the last system to build because it requires all others to function correctly. An autoloop built on an unstable eval will accept mutations based on noise.
**Delivers:** /autoloop skill; autoloop-step.sh script (mutate → eval → compare → keep/revert); mutation log schema (append-only JSON per cycle); holdout set in `autoloop/reference-drafts/`; acceptance rule enforcement (aggregate improves, no critical criterion regressions); iteration cap and convergence detection.
**Avoids:** Pitfall 4 (Goodhart's Law) — holdout set required before first cycle; structural observables in rubric; permanent mutation log; human review trigger after N iterations without holdout improvement.

### Phase 5: Preset Creation Skill and v1.x Additions

**Rationale:** Preset creation from examples is a convenience feature, not a dependency. The three hand-tuned presets from Phase 1 are the foundation. This phase adds the user-facing preset creation flow once the preset schema is well-understood and stable. Notes-to-draft flow is added here as well.
**Delivers:** /create-preset skill (analyze examples → synthesize preset fields → show all inferred fields to user → save on approval; never silent writes); notes-to-draft flow (/build skill entry point); preset schema reference doc for users.
**Avoids:** UX pitfall: preset creation that infers too aggressively — all inferred fields shown before saving, no silent writes.

### Phase Ordering Rationale

- **Preset schema first** because every component (writing engine, eval system, autoloop) reads from the preset. A schema change after Phase 2 requires retroactively updating all pass logic.
- **Writing engine before eval** because the eval system needs stable, representative outputs to score during calibration. Eval calibration on unstable pass outputs produces unreliable baselines.
- **Eval before autoloop** because the autoloop's acceptance rule depends on eval scores being consistent across runs. An inconsistent eval signal makes every mutation decision meaningless.
- **Autoloop last** because it is the only component that can mutate canonical system assets (presets, prompts). Building it before the rest of the system is stable risks corrupting the foundation.
- **Voice preservation in Phase 1, not Phase 3** — voice rules live in the preset schema and must be enforced in every pass from Phase 2 onward. Adding voice preservation after the engine is built means retrofitting constraints into every pass individually, which is high-cost and error-prone.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Eval System):** LLM-as-a-judge rubric design is nontrivial. Anchoring eval criteria to observable signals with calibration examples (1/3/5 score definitions per criterion) requires careful iteration. The calibration test protocol needs detailed specification before implementation.
- **Phase 4 (Autoloop):** Self-improvement loop design is the highest-complexity feature with the least directly applicable Claude Code documentation. Mutation strategy (what to mutate, how to constrain mutation scope to one field), convergence detection logic, and holdout set construction need deeper planning research.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** CLAUDE.md structure and JSON preset schema are well-documented patterns. Directory layout follows architecture research directly.
- **Phase 2 (Writing Engine):** SKILL.md pass architecture and PostToolUse hooks are official, well-documented Claude Code patterns. Standard implementation.
- **Phase 5 (Preset Creation):** Follows the same skill pattern as Phase 2. No new primitives.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Primary sources are official Claude Code documentation (code.claude.com, platform.claude.com) fetched directly. All key primitives (SKILL.md, agents, hooks, settings.json) are confirmed in official docs. |
| Features | HIGH | Table stakes verified across multiple competitor sources; core differentiators (preset schema, eval-driven loop, separate critic agent) confirmed against peer-reviewed research on iterative revision and eval-driven development. Anti-features confirmed against known failure modes. |
| Architecture | HIGH | Official Claude Code docs for subagents, hooks, skills, and memory architecture. File store as inter-component bus is the documented Claude Code-native pattern. Build order derived directly from component dependency graph. |
| Pitfalls | HIGH (voice/eval), MEDIUM (autoloop specifics) | Voice homogenization and eval self-preference bias backed by peer-reviewed research (arXiv papers). Goodhart's Law in LLM loops backed by published research. CLAUDE.md bloat backed by community sources. Autoloop convergence behavior is directionally correct but specifics are inferred — no direct Claude Code autoloop documentation exists. |

**Overall confidence:** HIGH

### Gaps to Address

- **Eval rubric anchor definitions:** The research establishes that anchored criteria are required (score 1/3/5 per criterion with example sentences) but does not provide the actual anchor text for each of the seven rubric criteria (novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity). These must be written and calibrated during Phase 3 planning.
- **Mutation scope constraints for the autoloop:** The research confirms that mutations must be limited to one field or instruction per cycle, but the specific mutation strategy (how to propose targeted changes, what constitutes "one mutation") needs deeper design during Phase 4 planning.
- **Token change threshold for pass scope enforcement:** PITFALLS.md recommends a token-change threshold to detect over-reaching passes but does not specify a reasonable percentage. This must be determined empirically during Phase 2 implementation.
- **agentskills.io standard reliability:** STACK.md notes this is MEDIUM confidence — referenced in official docs but site not directly verified. If the frontmatter fields deviate from Claude Code's actual behavior, discovered during implementation.

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills documentation](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter schema, invocation control, `context: fork`
- [Claude Code Hooks guide](https://code.claude.com/docs/en/hooks-guide) — hook events, JSON stdin/stdout protocol, matchers
- [Claude Code Memory documentation](https://code.claude.com/docs/en/memory) — CLAUDE.md format, `.claude/rules/` path scoping, auto memory
- [Claude Code Subagents documentation](https://code.claude.com/docs/en/sub-agents) — agent YAML frontmatter, storage paths, system prompt structure
- [Agent Skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — SKILL.md authoring, eval-driven development, JSON eval schema
- [Self-Preference Bias in LLM-as-a-Judge](https://arxiv.org/html/2410.21819v1) — self-preference bias in Claude and GPT-4o
- [PromptBreeder paper](https://openreview.net/forum?id=HKkiX32Zw1) — eval-driven self-improvement methodology
- [AAAI 2026 — Democratizing Writing Support with AI](https://ojs.aaai.org/index.php/AAAI/article/view/41167) — iterative revision improving writing quality

### Secondary (MEDIUM confidence)
- [LLM-as-a-Judge: A Complete Guide](https://www.evidentlyai.com/llm-guide/llm-as-a-judge) — rubric design, calibration, bias mitigation
- [Goodhart's LLM Principle](https://medium.com/@swagata_acharya/goodharts-llm-principle-how-ai-and-people-learn-to-pass-the-test-instead-of-solving-the-problem-1f582198e252) — Goodhart's Law in LLM metric optimization
- [When "Better" Prompts Hurt](https://arxiv.org/abs/2601.22025) — prompt mutation loops that degrade real quality
- [Stop Bloating Your CLAUDE.md](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/) — CLAUDE.md size limits and skill file strategy
- [Voice Drift Was Killing Us](https://refractedaspect.com/voice-drift-was-killing-us-so-we-built-a-voice-execution-system/) — practical voice drift prevention
- [Grammarly vs ProWritingAid vs Hemingway 2026](https://saascompared.io/blog/grammarly-vs-prowritingaid-vs-hemingway/) — competitor feature analysis

### Tertiary (LOW confidence)
- [Multi-agent writing system architecture](https://www.trysight.ai/blog/multi-ai-agent-writing-system) — architecture pattern directionally correct; marketing content
- [Claude Code eval loop](https://www.mager.co/blog/2026-03-08-claude-code-eval-loop/) — skill eval loop pattern; paywalled, partial access only

---
*Research completed: 2026-04-05*
*Ready for roadmap: yes*
