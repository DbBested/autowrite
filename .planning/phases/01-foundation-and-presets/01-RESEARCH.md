# Phase 1: Foundation and Presets - Research

**Researched:** 2026-04-05
**Domain:** Claude Code-native writing workflow scaffolding — repo structure, CLAUDE.md safety rules, .claude/rules/ files, JSON preset schema, three hand-tuned presets, shell validation script
**Confidence:** HIGH — primary sources are project-internal canonical research docs (STACK.md, ARCHITECTURE.md, PITFALLS.md) supplemented by CONTEXT.md locked decisions. All key claims verified against existing research docs fetched from official sources on 2026-04-05.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Presets are JSON files stored in `presets/` directory, one file per preset (e.g., `presets/blog-post.json`, `presets/argumentative-essay.json`, `presets/technical-explainer.json`)
- **D-02:** JSON chosen because it is processable by jq in hook shell scripts, by Python stdlib, and natively by Claude — no additional dependencies needed
- **D-03:** Preset schema follows the TypeScript type definition from the design document: name, description, form, goals, stages, voice (tone, formality, sentenceLength, paragraphStyle, rhetoricalStyle), structure (expectedSections, sectionOrder, paragraphPatterns, introStyle, endingStyle), rubric (criteria with name/description/weight), constraints, transformations (preserveVoice, allowMajorRestructure, prioritizeClarity, prioritizePersuasion, prioritizeConcision), examples
- **D-04:** One SKILL.md per writing task — each skill is a separate `.claude/skills/<name>/SKILL.md` file
- **D-05:** Phase 1 creates the directory scaffold for skills but does not implement writing skills (those are Phase 2). Phase 1 focuses on preset schema and validation only.
- **D-06:** CLAUDE.md holds universal safety rules only: no fabricated citations, voice preservation by default, no silent stance shifts, factual integrity enforcement. Must stay under 300 lines.
- **D-07:** `.claude/rules/*.md` files with `paths:` frontmatter for context-lean, conditionally-activated rules (e.g., rules that activate when working with preset files, rules that activate during revision passes)
- **D-08:** Rules files are created as needed — Phase 1 creates foundational rules for preset editing; Phase 2 adds pass-specific rules
- **D-09:** Shell script (`scripts/validate-preset.sh`) using jq to check all required fields exist and have correct types
- **D-10:** Validation script exits non-zero on any missing/malformed field with a clear error message naming the field and expected type

### Claude's Discretion

- Exact directory naming within the repo scaffold (drafts/, presets/, skills/, evals/, autoloop/, scripts/, runs/ are specified, but internal structure is flexible)
- Voice rule granularity within each preset (how specific to make tone descriptors, formality scale, etc.)
- Rubric weight distribution across criteria for each preset
- Whether to include a JSON Schema file alongside the validation script

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | Repository structure created with drafts/, presets/, skills/, evals/, autoloop/, scripts/, runs/ directories | ARCHITECTURE.md §Recommended Project Structure confirms exact directory names and purpose |
| FOUND-02 | CLAUDE.md defines universal safety rules (no fabricated citations, voice preservation defaults, factual integrity constraints) | PITFALLS.md §Pitfall 6 specifies 300-line hard ceiling; ARCHITECTURE.md §Anti-Pattern 5 defines split between CLAUDE.md (universal) vs preset (form-specific) voice rules |
| FOUND-03 | .claude/rules/*.md files provide context-lean, path-scoped behavioral rules for skills and passes | STACK.md §Core Primitives confirms `.claude/rules/*.md` with `paths:` frontmatter as official Claude Code pattern |
| PRES-01 | Preset schema defined in JSON covering form, goals, stages, voice rules, structure expectations, rubric criteria, constraints, and transformation defaults | STACK.md §Preset Schema gives reference schema; CONTEXT.md D-03 specifies the exact TypeScript-matching field set |
| PRES-02 | Blog post preset hand-tuned with form-specific voice, structure, rubric, and pass sequence | ARCHITECTURE.md §Pattern 2 shows abbreviated schema; PITFALLS.md §Pitfall 5 explains form-specific diagnosis requirements that flow from preset quality |
| PRES-03 | Argumentative essay preset hand-tuned with form-specific voice, structure, rubric, and pass sequence | Same pattern as PRES-02 — different form priorities (thesis, evidence structure, objection handling) |
| PRES-04 | Technical explainer preset hand-tuned with form-specific voice, structure, rubric, and pass sequence | Same pattern as PRES-02 — different form priorities (clarity, precision, progressive disclosure) |
| PRES-05 | Preset validation script catches malformed preset JSON before use | STACK.md §Shell Scripting Conventions confirms jq 1.6+ as the tool; D-09/D-10 specify exit behavior |
</phase_requirements>

---

## Summary

Phase 1 is pure scaffolding and content creation — no code execution paths, no external services. The deliverables are: a directory tree, a CLAUDE.md under 300 lines, one or two foundational rules files in `.claude/rules/`, three deeply-tuned JSON preset files, and a jq-based validation shell script. Nothing in this phase has runtime dependencies beyond bash and jq.

The most consequential design decisions happen here, not later. Voice preservation rules encoded in the preset schema in Phase 1 are what every subsequent phase (writing engine, eval, autoloop) reads from. Getting preset schema depth wrong in Phase 1 means retrofitting all later phases. The research consistently identifies three failure modes that are fixed or broken here: CLAUDE.md bloat (>300 lines causes instruction dropout), voice rules that are too shallow (formality sliders rather than behavioral fingerprints), and preset schemas that omit form-specific pass sequences (causing the writing engine to apply generic passes to form-specific work).

The three presets must be hand-tuned to the point where they can drive both revision (Phase 2) and evaluation (Phase 3) without modification. This means each preset needs weighted rubric criteria specific to its form, a stage sequence with the correct pass order for that form, and voice rules that are behavioral descriptions rather than scalar proxies.

**Primary recommendation:** Treat preset depth as the success criterion for this phase. The directory scaffold and validation script are mechanical. The presets are the hard design work — each should be capable of standing alone as a complete specification of what "good" means for its form.

---

## Standard Stack

### Core

| Primitive | Format | Purpose | Why Standard |
|-----------|--------|---------|--------------|
| CLAUDE.md | Markdown | Persistent repo-wide universal safety rules | Loaded every session unconditionally; keep under 300 lines. Universal rules only (no fabrication, voice default, factual integrity). Form-specific rules go in presets. |
| `.claude/rules/*.md` | Markdown + YAML frontmatter | Context-lean, conditionally-activated behavioral rules scoped by file path | Official Claude Code rules layer. `paths:` frontmatter means the rule only loads when Claude is working with matching files — zero context cost otherwise. |
| `presets/*.json` | JSON | Preset schema files — one per writing form | JSON chosen for jq processability in shell hooks, Python stdlib parsability, and native Claude readability. One file per preset, named by form (e.g., `blog-post.json`). |
| `scripts/validate-preset.sh` | Bash + jq | Validate a preset JSON against required schema fields before use | Zero-dependency validation. jq 1.6+ is available on all platforms. Exits non-zero with named field error. |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| jq 1.6+ | JSON field checking in validation script | All JSON field existence and type checks in validate-preset.sh |
| python3 stdlib | Complex validation when jq is insufficient | Only if jq cannot express the check (e.g., regex on field values). No pip packages — zero install dependency. |
| `.gitkeep` | Mark empty directories in git | One per empty directory (drafts/, runs/, evals/, etc.) so git tracks the scaffold without contents |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSON presets | YAML presets | YAML cannot be processed by jq in shell hooks without an extra parser. JSON is the correct choice. |
| jq for validation | Python-based JSON Schema validator | Adds a pip dependency and an install step. jq is available everywhere; no install needed. Only choose python3 stdlib validation if jq coverage is insufficient. |
| `.claude/rules/*.md` for path-scoped rules | More content in CLAUDE.md | CLAUDE.md degrades above 300 lines. Rules files load on demand — correct approach for any rules that are not universal. |

**Installation:**

No installation step for this phase. jq must be available on the developer's system:
```bash
# macOS
brew install jq
# Windows
winget install jqlang.jq
# Linux
apt install jq
```

---

## Architecture Patterns

### Recommended Project Structure

```
autowrite/
├── CLAUDE.md                        # Universal safety rules ONLY — under 300 lines
├── .claude/
│   ├── rules/
│   │   ├── preset-editing.md        # Rules that activate when working with presets/
│   │   └── (pass-specific rules added in Phase 2)
│   ├── skills/                      # Directory scaffold only — skills implemented in Phase 2
│   │   ├── improve/
│   │   ├── build/
│   │   ├── adapt/
│   │   ├── create-preset/
│   │   ├── eval/
│   │   └── autoloop/
│   └── agents/                      # Directory scaffold only — agents implemented in Phase 3
├── presets/
│   ├── blog-post.json               # Hand-tuned preset
│   ├── argumentative-essay.json     # Hand-tuned preset
│   ├── technical-explainer.json     # Hand-tuned preset
│   └── preset-schema.json           # JSON Schema draft-07 definition (Claude's discretion)
├── drafts/
│   └── .gitkeep
├── runs/
│   └── .gitkeep
├── evals/
│   └── .gitkeep
├── autoloop/
│   ├── runs/
│   │   └── .gitkeep
│   └── accepted/
│       └── .gitkeep
└── scripts/
    └── validate-preset.sh           # jq-based preset validation
```

### Pattern 1: Preset as Single Source of Truth

**What:** A preset JSON file defines everything the writing engine, eval agent, and autoloop need to understand "good" for a writing form. No evaluation criteria are hardcoded in skill files. All form-specific voice rules, pass sequences, rubric weights, and constraints live in the preset.

**When to use:** Phase 1 creates the presets that all later phases read. The schema depth decided here cannot be shallowly patched in later phases without touching all downstream consumers.

**Key fields required by downstream phases (from CONTEXT.md D-03 and STACK.md §Preset Schema):**
```json
{
  "id": "blog-post",
  "name": "Blog Post",
  "description": "Conversational, opinion-driven blog post for developer/writer audiences",
  "form": "blog-post",
  "version": "1.0.0",
  "goals": ["persuade", "engage", "inform"],
  "stages": ["diagnose", "revision-plan", "structure", "clarity", "argument", "tone", "concision", "hook", "ending", "final-review"],
  "voice": {
    "tone": "conversational",
    "formality": "informal",
    "sentenceLength": "varied",
    "paragraphStyle": "short-punchy",
    "rhetoricalStyle": "direct-assertion"
  },
  "structure": {
    "expectedSections": ["hook", "setup", "argument", "evidence", "objection", "resolution", "close"],
    "sectionOrder": "flexible",
    "paragraphPatterns": ["assertion-evidence", "single-idea"],
    "introStyle": "hook-first",
    "endingStyle": "strong-close"
  },
  "rubric": {
    "criteria": [
      {"name": "novelty", "description": "Does it say something worth saying? Not obvious, not generic.", "weight": 0.20},
      {"name": "clarity", "description": "Every sentence is unambiguous on first read.", "weight": 0.20},
      {"name": "structure", "description": "The arc holds. Opening earns its ending.", "weight": 0.15},
      {"name": "voice_preservation", "description": "Still sounds like the author, not like a language model.", "weight": 0.20},
      {"name": "audience_fit", "description": "Right register and assumed knowledge for the target reader.", "weight": 0.10},
      {"name": "concision", "description": "No filler sentences. Nothing repeats.", "weight": 0.10},
      {"name": "factual_integrity", "description": "No invented citations, no fabricated claims, no silently altered positions.", "weight": 0.05}
    ],
    "passing_threshold": 3.5,
    "critical_criteria": ["factual_integrity", "voice_preservation"]
  },
  "constraints": {
    "no_citation_invention": true,
    "no_stance_shift": true,
    "aggressive_rewrite_requires_explicit_request": true
  },
  "transformations": {
    "preserveVoice": true,
    "allowMajorRestructure": false,
    "prioritizeClarity": true,
    "prioritizePersuasion": false,
    "prioritizeConcision": false
  },
  "examples": []
}
```

### Pattern 2: CLAUDE.md — Universal Rules Only, Under 300 Lines

**What:** CLAUDE.md holds the three or four inviolable cross-form rules: no fabricated citations, voice preservation as default, no silent stance shifts, factual integrity enforcement. Nothing form-specific goes here.

**When to use:** CLAUDE.md loads unconditionally on every session. It is the always-on safety layer. The moment form-specific guidance enters CLAUDE.md, it competes with universal rules and creates context noise.

**Structure for CLAUDE.md:**
```markdown
# Autowrite

## What This Is
[One paragraph describing the system]

## Universal Safety Rules

### Factual Integrity
- Never invent citations or references not present in the source draft
- Never fabricate facts, statistics, or examples
- Never add assertions the author did not make

### Voice Preservation
- Preserve the author's voice by default on every pass
- Aggressive rewrites only when the user explicitly requests them
- When in doubt, the author's choice wins over the model's preference

### Stance Integrity
- Never silently shift the author's position on a contested claim
- Flag intentional hedging — do not "strengthen" qualified claims without explicit instruction
- Argument passes strengthen clarity of existing claims, not the claims themselves

### Pass Scope
- Every revision pass has a defined scope; do not touch what is out of scope
- Read the active preset before any revision begins — the preset defines what "good" means for this form
```

**Line budget:** Target 100-150 lines. Under 300 is the hard ceiling. Every line added to CLAUDE.md is always-on context cost.

### Pattern 3: `.claude/rules/` Path-Scoped Rules

**What:** Rules files with `paths:` frontmatter activate only when Claude is working with matching files. A `preset-editing.md` rule file activates only when editing files in `presets/`, adding zero context cost in all other sessions.

**When to use:** Any behavioral rule that applies to a specific file type or directory but not universally.

**Example for Phase 1:**
```markdown
---
paths:
  - "presets/*.json"
---

# Preset Editing Rules

When editing a preset JSON file:
- Preserve the full schema structure — do not remove fields that downstream skills depend on
- Voice rules must be behavioral descriptions, not scalar proxies
- Rubric weights must sum to 1.0
- `critical_criteria` array must always include at minimum `factual_integrity` and `voice_preservation`
- Run `bash scripts/validate-preset.sh <preset-file>` after any preset edit and confirm it passes
```

### Pattern 4: jq-Based Validation Script

**What:** `scripts/validate-preset.sh` takes a preset file path as argument, uses jq to check all required fields exist with correct types, and exits non-zero with a named error on any failure.

**When to use:** Invoked manually before a revision run or from a hook. Catches malformed presets before they cause silent misbehavior downstream.

**Example structure:**
```bash
#!/usr/bin/env bash
set -euo pipefail

PRESET_FILE="${1:-}"
if [[ -z "$PRESET_FILE" ]]; then
  echo "Usage: validate-preset.sh <path-to-preset.json>" >&2
  exit 1
fi

check_field() {
  local field="$1"
  local jq_expr="$2"
  local expected_type="$3"
  if ! jq -e "$jq_expr" "$PRESET_FILE" > /dev/null 2>&1; then
    echo "ERROR: Missing or invalid field '$field' (expected: $expected_type)" >&2
    exit 1
  fi
}

check_field "id"          '.id | type == "string"'        "string"
check_field "form"        '.form | type == "string"'       "string"
check_field "stages"      '.stages | type == "array" and length > 0'  "non-empty array"
check_field "voice"       '.voice | type == "object"'      "object"
check_field "structure"   '.structure | type == "object"'  "object"
check_field "rubric"      '.rubric | type == "object"'     "object"
check_field "rubric.criteria" '.rubric.criteria | type == "array" and length > 0' "non-empty array"
check_field "constraints" '.constraints | type == "object"' "object"
check_field "transformations" '.transformations | type == "object"' "object"

# Verify rubric weights sum to 1.0 (within float tolerance)
WEIGHT_SUM=$(jq '[.rubric.criteria[].weight] | add' "$PRESET_FILE")
if ! echo "$WEIGHT_SUM" | awk '{ if ($1 < 0.99 || $1 > 1.01) exit 1 }'; then
  echo "ERROR: rubric.criteria weights sum to $WEIGHT_SUM — must sum to 1.0 (+/- 0.01)" >&2
  exit 1
fi

echo "OK: $PRESET_FILE is valid"
```

### Anti-Patterns to Avoid

- **Form-specific rules in CLAUDE.md:** Every token in CLAUDE.md loads unconditionally. Blog post voice rules are irrelevant during a technical explainer session — they add noise and compete with the rules that matter. Keep CLAUDE.md universal.
- **Voice rules as scalar proxies ("formality: 7/10"):** The model cannot operationalize "formality 7". Voice rules must be behavioral: "uses sentence fragments for emphasis", "avoids passive constructions", "favors Anglo-Saxon vocabulary over Latinate". These are instructions the model can follow.
- **Omitting `stages` from the preset:** If the writing engine has to invent its own pass sequence, it defaults to generic passes that may be wrong for the form. The stages array is what the Phase 2 engine reads to determine what passes to run and in what order.
- **Omitting `critical_criteria` from rubric:** The eval agent uses `critical_criteria` as hard-fail gates. If omitted, every revision passes eval regardless of voice or factual integrity degradation.
- **Missing `transformations.preserveVoice: true`:** This flag signals the writing engine and eval agent that voice preservation is a first-class constraint for this preset. An aggressive-rewrite preset (if one were ever created) would set this to false. The three Phase 1 presets must all have it set to true.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON validation | Custom parser or Python schema validator with pip dependency | jq 1.6+ field checks in shell script | jq is available everywhere with no install. pip dependency adds friction and a required install step that conflicts with zero-dependency design. |
| Path-scoped rule activation | Complex CLAUDE.md conditionals or per-session context injection | `.claude/rules/*.md` with `paths:` frontmatter | Official Claude Code primitive. Zero implementation required — Claude Code handles loading automatically based on file paths in the active session. |
| Skill invocation registry | A meta-file listing all available skills | `.claude/skills/<name>/SKILL.md` standard structure | Claude Code discovers skills by directory convention. No registry needed. |

**Key insight:** Phase 1 has no complex logic to hand-roll. The work is content design (preset quality, rule precision) not code design. The only code artifact is the validation script, and jq handles all the heavy lifting.

---

## Common Pitfalls

### Pitfall 1: Voice Rules That Are Too Shallow

**What goes wrong:** Presets define voice as scalar proxies ("formality: 7", "sentenceLength: medium") rather than behavioral descriptions. The writing engine cannot operationalize scalars — it does not know what "formality 7" means in practice. Voice drift proceeds unchecked because there are no observable constraints for the model to follow.

**Why it happens:** Shallow voice descriptors are easy to write quickly. Behavioral descriptions require actually analyzing the target form's voice patterns.

**How to avoid:** For each form, define voice rules as observable behaviors: what the model must preserve, what it must avoid, and what signals characterize the form's register. Examples:
- Blog post: "Uses first person throughout. Favors short sentences and fragments for emphasis. Avoids corporate hedging ('it is worth noting'). Keeps vocabulary in everyday register — Anglo-Saxon over Latinate."
- Technical explainer: "Precision over personality. Defines terms before using them. Uses imperative voice in procedural sections. Avoids hedging on technical facts — if uncertain, says so explicitly."
- Argumentative essay: "Clear declarative thesis in opening. Each paragraph advances one claim. Uses logical connectives explicitly ('therefore', 'however', 'because'). Formal register, no contractions."

**Warning signs:** Voice rules in the preset are one-liners with no operational specificity.

### Pitfall 2: CLAUDE.md Exceeds 300 Lines

**What goes wrong:** Instructions buried past line 200 in CLAUDE.md experience measurable dropout — the model follows rules near the top more consistently than rules in the middle or bottom.

**Why it happens:** It feels natural to add project context, design rationale, and convention notes to CLAUDE.md. These are not universal rules — they are noise.

**How to avoid:** Every line in CLAUDE.md must answer: "Does this apply on every single session for every writing form?" If no, it belongs in a rules file or skill file. Target 100-150 lines. Audit before Phase 2 begins.

**Warning signs:** CLAUDE.md contains form-specific guidance, pass instructions, or schema documentation.

### Pitfall 3: Preset Schema Missing Fields Required by Later Phases

**What goes wrong:** Phase 1 creates a preset schema that looks complete but omits fields that the writing engine (Phase 2) or eval agent (Phase 3) will need. Retrofitting schema fields in Phase 3 requires updating all three preset files and re-validating.

**Why it happens:** It is not obvious in Phase 1 what Phase 2 and Phase 3 will need. The design document spec and the ARCHITECTURE.md data flow diagrams resolve this.

**How to avoid:** The schema in CONTEXT.md D-03 is the canonical field list from the design document. Use it exactly. Do not abbreviate `stages`, `rubric`, `constraints`, or `transformations` — all four are consumed by downstream phases.

**Warning signs:** Preset schema omits `stages` (engine cannot determine pass sequence), omits `rubric.critical_criteria` (eval cannot apply hard-fail gates), or omits `transformations` (engine cannot determine default rewrite behavior).

### Pitfall 4: Validation Script That Only Checks Field Existence

**What goes wrong:** The validation script confirms required keys exist but does not check types, array length, or weight sum. A preset passes validation with `"stages": null` or `"rubric": {"criteria": []}`. The engine silently misbehaves.

**Why it happens:** jq type checking requires slightly more complex expressions. The temptation is to keep the script simple.

**How to avoid:** For every required field, validate both existence and type. For arrays, validate `length > 0`. For rubric weights, validate they sum to 1.0 within tolerance. See Pattern 4 code example above.

**Warning signs:** Validation script uses `jq 'has("field")'` only, without type checking.

---

## Code Examples

Verified patterns from project-internal canonical research (STACK.md, researched 2026-04-05 from official Claude Code docs).

### CLAUDE.md Universal Safety Rules Block

```markdown
## Universal Safety Rules

These rules apply on every revision pass for every writing form.

### Factual Integrity
- Never invent citations or references not present in the source draft
- Never fabricate statistics, examples, or claims
- Never add factual assertions the author did not make

### Voice Preservation
- Preserve the author's voice by default
- Aggressive rewrites require explicit user request
- When vocabulary choice is ambiguous, the author's choice wins

### Stance Integrity
- Never silently shift the author's argumentative position
- Treat hedging language as potentially intentional until the diagnose pass flags it otherwise
- Argument passes clarify existing claims — they do not strengthen or weaken the author's actual position

### Pass Scope
- Every revision pass operates within its defined scope
- Read the active preset before any revision begins
```

### `.claude/rules/preset-editing.md` Frontmatter Pattern

```markdown
---
paths:
  - "presets/*.json"
---

# Preset Editing Rules

When editing or creating a preset JSON file:
- Run `bash scripts/validate-preset.sh <file>` after every edit
- Rubric weights must sum to 1.0
- `critical_criteria` must include at minimum `factual_integrity` and `voice_preservation`
- Voice rules must be behavioral descriptions, not scalar values
- `stages` array must list passes in the intended execution order for this form
```

### Preset Schema — Argumentative Essay (Abbreviated)

```json
{
  "id": "argumentative-essay",
  "name": "Argumentative Essay",
  "description": "Formal argument-driven essay with clear thesis, structured evidence, and addressed objections",
  "form": "argumentative-essay",
  "version": "1.0.0",
  "goals": ["persuade", "demonstrate-reasoning", "address-counterargument"],
  "stages": ["diagnose", "revision-plan", "structure", "argument", "evidence", "objection", "clarity", "concision", "final-review"],
  "voice": {
    "tone": "formal-analytical",
    "formality": "high",
    "sentenceLength": "medium-to-long",
    "paragraphStyle": "topic-sentence-led",
    "rhetoricalStyle": "logos-primary"
  },
  "structure": {
    "expectedSections": ["introduction-with-thesis", "body-arguments", "counterargument", "rebuttal", "conclusion"],
    "sectionOrder": "strict",
    "paragraphPatterns": ["claim-evidence-warrant", "topic-sentence-support-synthesis"],
    "introStyle": "thesis-forward",
    "endingStyle": "restate-and-broaden"
  },
  "rubric": {
    "criteria": [
      {"name": "novelty", "description": "Thesis makes a claim worth defending — not obvious, not merely descriptive.", "weight": 0.20},
      {"name": "clarity", "description": "Each sentence is unambiguous. Argument chain follows without logical gaps.", "weight": 0.20},
      {"name": "structure", "description": "Thesis governs every paragraph. Conclusion follows from the body, not from general sentiment.", "weight": 0.20},
      {"name": "voice_preservation", "description": "Analytical register maintained. Author's specific argumentative choices preserved.", "weight": 0.15},
      {"name": "audience_fit", "description": "Assumes appropriate reader knowledge. No unexplained jargon, no over-explaining basics.", "weight": 0.10},
      {"name": "concision", "description": "No paragraph exists solely to pad length. Evidence is sufficient, not exhaustive.", "weight": 0.10},
      {"name": "factual_integrity", "description": "No invented citations, no fabricated evidence, no strengthened claims beyond what source material supports.", "weight": 0.05}
    ],
    "passing_threshold": 3.5,
    "critical_criteria": ["factual_integrity", "voice_preservation"]
  },
  "constraints": {
    "no_citation_invention": true,
    "no_stance_shift": true,
    "aggressive_rewrite_requires_explicit_request": true
  },
  "transformations": {
    "preserveVoice": true,
    "allowMajorRestructure": false,
    "prioritizeClarity": true,
    "prioritizePersuasion": true,
    "prioritizeConcision": false
  },
  "examples": []
}
```

### Preset Schema — Technical Explainer (Key Differences)

The technical explainer preset differs from the others in: tone (precision over personality), rhetorical style (exposition, not persuasion), structure (progressive disclosure — simple to complex), and goal priorities (clarity and audience fit outweigh novelty).

```json
{
  "id": "technical-explainer",
  "form": "technical-explainer",
  "goals": ["explain", "clarify", "enable-action"],
  "voice": {
    "tone": "precise-accessible",
    "formality": "medium",
    "sentenceLength": "short-to-medium",
    "paragraphStyle": "definition-example-implication",
    "rhetoricalStyle": "expository"
  },
  "structure": {
    "expectedSections": ["problem-or-concept", "explanation", "examples", "caveats", "summary"],
    "sectionOrder": "progressive",
    "paragraphPatterns": ["define-then-illustrate", "compare-then-contrast"],
    "introStyle": "problem-first",
    "endingStyle": "actionable-takeaway"
  },
  "rubric": {
    "criteria": [
      {"name": "novelty",           "weight": 0.10},
      {"name": "clarity",           "weight": 0.30},
      {"name": "structure",         "weight": 0.20},
      {"name": "voice_preservation","weight": 0.15},
      {"name": "audience_fit",      "weight": 0.15},
      {"name": "concision",         "weight": 0.05},
      {"name": "factual_integrity", "weight": 0.05}
    ]
  }
}
```

Note: clarity (0.30) and audience fit (0.15) are elevated vs. blog post. Novelty (0.10) is reduced — explaining well-known concepts clearly is the goal, not saying something unprecedented.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Monolithic CLAUDE.md for all rules | CLAUDE.md (universal) + `.claude/rules/*.md` (path-scoped) | Claude Code v2.x | Rules files are official Claude Code primitive. Path scoping eliminates always-on context cost for form-specific rules. |
| `.claude/commands/*.md` for skills | `.claude/skills/<name>/SKILL.md` | Claude Code v2.x | Skills have supporting file directories, invocation control, `context: fork`, and model auto-invocation. Commands still work but are the legacy path. |

**Deprecated/outdated:**
- `.claude/commands/*.md` pattern: Still functional but not forward path. Phase 1 creates the `skills/` directory structure following the current standard even though skills are not implemented until Phase 2.

---

## Open Questions

1. **JSON Schema file alongside validation script**
   - What we know: CONTEXT.md marks this as Claude's discretion. STACK.md mentions JSON Schema Draft 7 for preset validation.
   - What's unclear: Whether a `preset-schema.json` JSON Schema file adds value beyond the shell validation script.
   - Recommendation: Include `presets/preset-schema.json` as a reference document. It makes the schema explicit and machine-readable for future tooling without adding any implementation complexity. Cost is near-zero (one JSON file); benefit is clear schema documentation.

2. **Voice rule specificity per preset**
   - What we know: PITFALLS.md §Pitfall 1 strongly warns against shallow voice proxies. CONTEXT.md marks granularity as Claude's discretion.
   - What's unclear: How deep to go in Phase 1 vs. refining in the autoloop.
   - Recommendation: Write behavioral descriptions for the most important 3-4 voice characteristics per form. These should be specific enough that a revision pass could fail if it violated them. The autoloop will refine them in Phase 4 — Phase 1 needs to be good enough to serve as a meaningful starting point.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified — Phase 1 is directory scaffold, JSON files, CLAUDE.md, rules files, and a shell script. The only tool dependency is jq, which is a developer install documented in the Standard Stack section rather than a runtime check.)

---

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — Preset schema pattern, SKILL.md structure, rules file frontmatter, jq scripting conventions, shell script patterns, hook events — verified 2026-04-05 against official Claude Code docs
- `.planning/research/ARCHITECTURE.md` — Directory structure, component responsibilities, preset-as-single-source-of-truth pattern, anti-patterns — HIGH confidence
- `.planning/research/PITFALLS.md` — CLAUDE.md bloat pitfall (300-line ceiling), voice rule depth requirements, preset schema completeness — HIGH confidence

### Secondary (MEDIUM confidence)
- `.planning/phases/01-foundation-and-presets/01-CONTEXT.md` — D-01 through D-10 locked decisions, schema field list from design document — MEDIUM confidence (decisions from human discussion, no external source verification needed)
- `.planning/REQUIREMENTS.md` — FOUND-01 through PRES-05 requirement definitions
- `.planning/PROJECT.md` — Core value, constraints, key decisions

---

## Metadata

**Confidence breakdown:**
- Directory scaffold (FOUND-01): HIGH — exact names specified in ARCHITECTURE.md and CONTEXT.md
- CLAUDE.md structure (FOUND-02): HIGH — PITFALLS.md and ARCHITECTURE.md give clear specification; 300-line ceiling documented
- Rules files (FOUND-03): HIGH — official Claude Code primitive documented in STACK.md
- Preset schema (PRES-01): HIGH — canonical schema in STACK.md and CONTEXT.md D-03
- Blog post preset (PRES-02): HIGH for structure/rubric patterns; MEDIUM for voice rule specificity (behavioral descriptions require design judgment)
- Argumentative essay preset (PRES-03): Same as PRES-02
- Technical explainer preset (PRES-04): Same as PRES-02
- Validation script (PRES-05): HIGH — jq field-check pattern is straightforward and well-documented

**Research date:** 2026-04-05
**Valid until:** Stable — this phase is entirely based on project-internal decisions and Claude Code patterns that are not subject to external API changes.
