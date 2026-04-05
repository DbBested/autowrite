# Phase 3: Eval System - Research

**Researched:** 2026-04-05
**Domain:** Claude Code subagent design, LLM-as-a-judge rubric design, eval snapshot JSON schema
**Confidence:** HIGH — all findings verified against prior phase research documents (STACK.md, ARCHITECTURE.md, PITFALLS.md) which were produced from official Claude Code documentation and peer-reviewed sources.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Eval Invocation**
- `/eval @output.md --preset blog-post` or auto-detect preset from latest run directory
- Eval output goes to the same run directory as the revision: `runs/<run>/eval.json`
- Eval can run standalone: `/eval @any-text.md --preset X` works on any text, not just revision outputs
- Score scale: 1-10 integer per criterion, no decimals — simple and comparable

**Critic Agent Design**
- `.claude/agents/eval-critic.md` subagent — runs in separate context window, sees only the text and rubric
- Critic is explicitly instructed to be hyper-critical, find flaws, never praise — adversarial framing in agent file
- Preset `rubric.criteria` loaded directly — each criterion scored independently, then weighted aggregate computed
- Consistency via temperature=0 in agent instructions + anchored criteria with specific observable behaviors per score level

**Eval Snapshot Schema**
- JSON structure: `{preset, timestamp, criteria: [{name, score, weight, pass, failure_points: [{location, description, severity}], explanation}], aggregate_score, aggregate_pass}`
- Failure points are specific and located with severity: critical/major/minor — e.g., "Paragraph 3: thesis buried after anecdote (major)"
- Pass/fail threshold: score >= 6 is pass, < 6 is fail per criterion; aggregate pass requires all criteria pass AND weighted average >= 6
- Preset can add optional criteria beyond the 7 core — scored and included in snapshot but not in aggregate unless weight > 0

### Claude's Discretion

- Exact adversarial prompting language in the agent file
- Anchored score level descriptions (what a 3 vs 7 vs 10 looks like per criterion)
- How to handle edge cases: very short texts, texts with no clear form, missing preset fields
- Whether to include a human-readable eval summary alongside the JSON snapshot

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVAL-01 | Specialized eval critic agent runs as an isolated subagent (separate context window from writing agent) | Claude Code `.claude/agents/` subagent pattern with `context: fork` in the invoking skill; confirmed in STACK.md and ARCHITECTURE.md |
| EVAL-02 | Eval agent produces criterion-level scores for: novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity | All 7 criteria exist in all 3 presets as `rubric.criteria` arrays with `name`, `description`, `weight` fields; eval agent reads these directly |
| EVAL-03 | Eval agent produces specific failure points with concrete explanations per criterion | Failure point schema defined in CONTEXT.md; adversarial framing drives specificity; anchored scoring drives locatability |
| EVAL-04 | Eval rubric criteria and weights driven by the active preset | Preset JSON is the single source of truth; eval agent reads `preset.rubric.criteria` at invocation time; no hardcoded criteria in agent file |
| EVAL-05 | Eval snapshot saved as stable, machine-readable JSON (criterion → score → explanation → failure_points) | Schema defined in locked decisions; written to `runs/<run>/eval.json` by the `/eval` SKILL.md |
| EVAL-06 | Eval agent uses adversarial framing (hyper-critical, not supportive) | Agent system prompt language; counteracts self-preference bias documented in PITFALLS.md Pitfall 3 |
</phase_requirements>

---

## Summary

Phase 3 builds the eval system: a dedicated critic subagent that scores any text against a preset's rubric and writes a stable machine-readable snapshot. The system is entirely defined by two artifacts — a SKILL.md at `.claude/skills/eval/SKILL.md` that handles invocation, preset loading, and file I/O, and an agent definition at `.claude/agents/eval-critic.md` that contains the critic's identity, rubric injection protocol, and adversarial system prompt.

The core architecture is already established by prior phases. The Claude Code subagent pattern (`context: fork` + `.claude/agents/`) is the right primitive: it gives the critic a clean context window with no knowledge of having generated the text being evaluated. The preset system (Phase 1) provides the rubric input. The run directory structure (Phase 2) provides the output location. This phase wires them together.

The primary design challenge is eval consistency. LLM judges produce high variance when criteria are vague or holistic. The solution is anchored scoring: for each of the 7 criteria, define what a 3, 6, and 9 look like in terms of specific observable behaviors. This is Claude's discretion per CONTEXT.md, and it is where most of the implementation work lives — not in the plumbing, but in the quality of the rubric anchors and the adversarial prompt framing.

**Primary recommendation:** Build the eval agent with one narrow focus — produce a valid, specific eval.json with anchored scores and located failure points. Do not let the agent attempt to suggest fixes or explain how to improve. Fix suggestions are the writing engine's job. The eval agent's only job is to find what is wrong and report it precisely.

---

## Standard Stack

### Core Primitives

| Primitive | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `.claude/agents/eval-critic.md` | Claude Code v2.x | Subagent definition: system prompt, model, tool restriction | Official Claude Code pattern for isolated critic roles. Context window is separate from main conversation — mandatory for eval objectivity. |
| `.claude/skills/eval/SKILL.md` | Claude Code v2.x | `/eval` invocation: argument parsing, preset loading, critic dispatch, file writes | Skills are the correct entry point for user-invokable operations. `context: fork` in frontmatter routes execution to the critic subagent. |
| `runs/<run>/eval.json` | — | Machine-readable eval snapshot output | Established run directory pattern from Phase 2. Eval output co-located with revision artifacts. |
| `presets/<id>.json` | 1.0.0 | Rubric input: criteria names, descriptions, weights | Phase 1 artifact. The eval agent reads `rubric.criteria` directly. No criteria are hardcoded in the agent. |
| `jq` | 1.6+ | JSON validation and field extraction in shell scripts | Zero-install, available on all platforms. Validates eval.json structure in PostToolUse hook if wired. |

### Skill Frontmatter Pattern (eval/SKILL.md)

```yaml
---
name: eval
description: Evaluate any text against a preset rubric. Runs a hyper-critical subagent to produce criterion-level scores, located failure points, and a machine-readable eval snapshot.
disable-model-invocation: true
context: fork
agent: eval-critic
allowed-tools: Read Write Bash(jq *)
effort: high
---
```

Key flags:
- `disable-model-invocation: true` — eval is user-triggered only, never auto-invoked mid-revision
- `context: fork` — routes to the critic subagent in a clean context window
- `agent: eval-critic` — names the agent file in `.claude/agents/`
- `effort: high` — ensures thorough evaluation on assessment steps

### Agent Frontmatter Pattern (agents/eval-critic.md)

```yaml
---
name: eval-critic
description: Specialized writing evaluation agent. Produces criterion-level scores, failure points, and explanations. Adversarial framing. Read-only tool access.
model: claude-sonnet-4-6
effort: high
allowed-tools: Read
---
```

Key constraints:
- `allowed-tools: Read` only — the critic reads the text and preset; it writes nothing (the SKILL.md writes eval.json after receiving scores)
- No `Bash`, no `Write` — critic cannot modify files

### Supporting Libraries

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `python3 -c "import json..."` | Validate eval.json structure post-write | If jq not available; stdlib only, no pip |
| `bash scripts/validate-preset.sh` | Verify preset loads cleanly before eval run | Already exists from Phase 1; reuse |

**Installation:** No new dependencies. Everything is Claude Code primitives + existing project scripts.

---

## Architecture Patterns

### Recommended File Structure

```
.claude/
├── agents/
│   └── eval-critic.md          # Critic subagent: system prompt, adversarial framing, scoring protocol
└── skills/
    └── eval/
        └── SKILL.md            # /eval entry point: invocation, preset loading, critic dispatch, file writes

runs/
└── YYYY-MM-DD_HH-MM-SS_<preset-id>/
    ├── input.md                # (from Phase 2)
    ├── output.md               # (from Phase 2)
    ├── diagnosis.md            # (from Phase 2)
    ├── plan.md                 # (from Phase 2)
    ├── metadata.json           # (from Phase 2)
    └── eval.json               # (NEW — this phase)
```

The `eval.json` file is the sole new artifact produced by this phase. Everything else reuses the Phase 2 run directory structure.

### Pattern 1: Critic Isolation via context:fork

**What:** The `/eval` SKILL.md is invoked by the user. Its frontmatter specifies `context: fork` and `agent: eval-critic`. Claude Code forks a new context window containing: the SKILL.md content (with injected preset and text), the critic agent's system prompt from `eval-critic.md`, and CLAUDE.md. The main conversation history is not included.

**Why this matters:** The critic has no memory of generating the text. It applies the rubric as an external judge, not as the author reviewing their own work. This is the architectural control for self-preference bias (PITFALLS.md Pitfall 3).

**Invocation flow:**
```
User: /eval @runs/2026-04-05_12-00-00_blog-post/output.md --preset blog-post

  eval/SKILL.md loads
    |
    ├─ Read presets/blog-post.json   → extract rubric.criteria, passing_threshold, critical_criteria
    ├─ Read runs/.../output.md       → text to evaluate
    |
    ├─ [context: fork → agent: eval-critic]
    |     Critic receives: text content + rubric criteria (injected via !`cat` in SKILL.md)
    |     Critic produces: JSON score block (stdout / return value)
    |
    └─ SKILL.md writes: runs/.../eval.json
```

**Critical:** The critic agent returns scores as structured JSON. The SKILL.md receives this output and writes `eval.json`. The critic never writes files directly — its `allowed-tools` is `Read` only.

### Pattern 2: Preset-Driven Criteria (No Hardcoding)

**What:** The eval agent does not have a hardcoded list of criteria. The SKILL.md injects the preset's `rubric.criteria` array directly into the critic's context using shell dynamic injection:

```
## Rubric Criteria
!`cat presets/$PRESET_ID.json | jq '.rubric.criteria'`
```

This means any preset — including future custom presets from Phase 4 — will automatically be evaluated against their own rubric with no changes to the eval agent.

**Constraint for agent file:** The eval-critic.md must describe the scoring protocol generically: "Score each criterion provided in the rubric against the text provided." It must not enumerate specific criterion names.

### Pattern 3: Anchored Scoring (Claude's Discretion)

**What:** For each of the 7 core criteria, the eval-critic.md defines what specific observable behaviors correspond to score levels 1, 3, 6, and 9. These anchors reduce variance across runs and make failure points locatable.

**Example anchor structure (to be authored in eval-critic.md):**

```
## clarity — Score Anchors

9-10: Every sentence is unambiguous on first read. No sentence requires re-reading.
      No pronouns with unclear antecedents. No jargon introduced without definition or context.

6-8:  Nearly all sentences are clear. One or two sentences require re-reading or slight
      effort to parse. Antecedent ambiguity appears once or twice without disrupting flow.

3-5:  Several sentences are genuinely ambiguous. A careful reader would need to re-read
      a paragraph to establish meaning. One or more undefined technical terms in audience context.

1-2:  Multiple sentences are incomprehensible without substantial context.
      The reader cannot determine the meaning of key sentences from surrounding text.
```

**Why anchors matter:** PITFALLS.md Pitfall 8 documents that holistic "quality 1-10" rubrics produce > 1 point variance across runs of the same input. Anchored, observable criteria converge to consistent scores. The self-improvement loop (Phase 4) depends on consistent eval scores to detect real signal vs. noise.

### Pattern 4: Adversarial Framing in Agent System Prompt

**What:** The eval-critic.md system prompt opens with explicit adversarial framing. This counteracts Claude's self-preference bias and social desirability bias (tendency to be encouraging rather than critical).

**Required elements in agent system prompt:**
1. Role statement: you are a critic, not a coach; your job is to find flaws
2. Prohibition on positive framing: do not praise, do not soften failure points
3. Location requirement: every failure point must name a specific paragraph and sentence
4. Fabrication prohibition (inherited): never invent problems that do not exist — only report observable weaknesses
5. Output format: return only valid JSON matching the eval snapshot schema

**What adversarial framing is NOT:** inventing problems. The critic must be hyper-critical about real weaknesses but scrupulously accurate. Fabricating failure points to appear thorough is the same class of error as fabricating citations. The adversarial framing combats under-reporting, not accuracy.

### Pattern 5: Eval Snapshot Schema

The locked decision from CONTEXT.md defines the schema. This is the exact structure:

```json
{
  "preset": "blog-post",
  "preset_version": "1.0.0",
  "timestamp": "2026-04-05T14:32:12Z",
  "text_path": "runs/2026-04-05_12-00-00_blog-post/output.md",
  "criteria": [
    {
      "name": "novelty",
      "score": 7,
      "weight": 0.20,
      "pass": true,
      "failure_points": [],
      "explanation": "The piece advances a non-obvious claim about X with a specific framing the reader has not encountered in standard treatment of this topic."
    },
    {
      "name": "clarity",
      "score": 5,
      "weight": 0.20,
      "pass": false,
      "failure_points": [
        {
          "location": "Paragraph 3, sentence 2",
          "description": "Pronoun 'it' has three possible antecedents in the previous sentence; the reader cannot determine which noun is being referenced.",
          "severity": "major"
        }
      ],
      "explanation": "Most sentences are clear but paragraph 3 contains an antecedent ambiguity that requires re-reading to resolve."
    }
  ],
  "aggregate_score": 6.2,
  "aggregate_pass": false
}
```

**Aggregate score formula:** weighted sum of individual criterion scores, where weight = `criterion.weight` from the preset.

**Pass/fail logic:**
- Per-criterion pass: `score >= 6`
- Aggregate pass: ALL criteria pass AND `aggregate_score >= 6`
- Critical criteria (`factual_integrity`, `voice_preservation`) force `aggregate_pass: false` if their score < 6, regardless of aggregate score

**Note on score scale:** The locked decision uses 1-10 integer, not the 1-5 float scale used in earlier research artifacts (STACK.md, ARCHITECTURE.md). The CONTEXT.md 1-10 integer scale is authoritative for this phase. The pass threshold of 6 (out of 10) corresponds to the earlier research's 3.5 (out of 5) scaled proportionally.

### Anti-Patterns to Avoid

- **Hardcoding criteria in eval-critic.md:** The agent must read criteria from the injected preset, not from a static list in its own file. Static lists break when a new preset with different criterion weights is used.
- **Letting the critic write files:** `allowed-tools: Read` only. The SKILL.md writes eval.json from the critic's output. If the critic writes files, it bypasses the SKILL.md's validation and path management.
- **Scoring in the main conversation:** Never ask the writing agent to score its own output in the same context window. Even with a rubric, the model has seen the generation history and will exhibit self-preference bias.
- **Vague failure points:** "The voice is not preserved" is not a failure point. "Paragraph 4, sentence 1: the original draft used first-person throughout; this sentence shifts to third-person ('one should consider') breaking the voice pattern." is a failure point.
- **Floating-point scores:** The locked decision requires 1-10 integers. Do not score 6.5 or 7.3. Integer-only makes scores comparable across runs without floating-point drift.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Critic isolation | A separate API call wrapper or context management utility | `.claude/agents/` + `context: fork` in SKILL.md frontmatter | Claude Code native pattern; isolation is guaranteed by the runtime, not by prompt tricks |
| Rubric loading | A custom parser for rubric criteria | `jq '.rubric.criteria'` against existing preset JSON | Preset JSON is already valid and schema-validated; jq reads it in one line |
| Eval consistency enforcement | Temperature control code or retry logic | `temperature=0` declared in agent instructions + anchored scoring rubric | Agent instructions can request deterministic behavior; anchored criteria are the primary consistency mechanism |
| Aggregate score computation | A separate script to compute weighted average | Computed in SKILL.md instructions or inline in the agent response | Simple arithmetic; no script needed; agent can compute weighted sum given criteria scores and weights |

**Key insight:** The eval system's complexity is almost entirely in the quality of the rubric anchors and the adversarial prompt language — not in the plumbing. The Claude Code primitives handle isolation, routing, and file I/O without custom code.

---

## Common Pitfalls

### Pitfall 1: Self-Preference Bias Leaking Through Context

**What goes wrong:** The eval skill is invoked at the end of a revision run. The main conversation window contains the full generation history — diagnosis, plan, all pass outputs. Even with `context: fork`, if the SKILL.md passes the revision history as context material, the critic sees it and its scores are contaminated.

**Why it happens:** SKILL.md uses `!`command`` dynamic injection. A developer might inject `runs/<run>/explanation.md` or `runs/<run>/diagnosis.md` thinking it provides useful context. It does — but it also tells the critic what the writing agent thought it fixed, priming it to validate those judgments.

**How to avoid:** Inject ONLY two things into the critic's context: (1) the text to evaluate, (2) the rubric criteria. No revision history, no diagnosis, no explanation, no plan. The critic must evaluate the text as if it has never seen any other artifact from this run.

**Warning signs:** Eval scores correlate highly with the number of passes run (more passes → higher eval scores even when quality is flat). Eval agent's explanations echo language from explanation.md.

### Pitfall 2: Failure Points Without Locations

**What goes wrong:** The critic produces failure points like "The voice drift is noticeable in several places" or "The structure is weak throughout." These are observations, not failure points. The user cannot act on them, and the autoloop cannot use them for targeted mutation.

**Why it happens:** Without an explicit location requirement in the agent instructions, the model defaults to holistic summary language. This is its natural output mode — locating specific instances requires extra effort that the prompt must demand.

**How to avoid:** The agent system prompt must include an explicit requirement: "Every failure point must name a specific paragraph number and sentence number (e.g., 'Paragraph 4, sentence 2'). Failure points without locations are not acceptable." Add this as a hard output constraint, not a preference.

**Warning signs:** Eval output contains failure_points where `location` fields are empty, "throughout", or name sections rather than specific paragraph/sentence references.

### Pitfall 3: Score Scale Mismatch with Preset passing_threshold

**What goes wrong:** The existing presets have `passing_threshold: 3.5` (a 1-5 scale artifact). The locked decision uses a 1-10 integer scale with pass threshold at 6. If the SKILL.md reads `preset.rubric.passing_threshold` directly for the pass/fail determination, it will use 3.5 instead of 6, producing incorrect pass/fail results.

**Why it happens:** The preset schema was defined in Phase 1 before the 1-10 scale decision was made in Phase 3. The two scales are incompatible.

**How to avoid:** The `/eval` SKILL.md must apply the Phase 3 pass threshold (score >= 6 per criterion, weighted average >= 6 for aggregate) regardless of what `preset.rubric.passing_threshold` says. The `passing_threshold` field in the preset is a legacy artifact for this phase — do not read it for pass/fail determination. Document this explicitly in the SKILL.md instructions.

**Warning signs:** Eval output shows `"pass": true` for criteria with scores of 4 or 5, or `"aggregate_pass": true` when aggregate score is below 6.

### Pitfall 4: Eval Agent Producing Fix Suggestions

**What goes wrong:** The adversarial framing prompts the critic to be thorough. Thoroughness without scope constraint leads the critic to suggest how to fix problems it identifies. Fix suggestions contaminate the eval snapshot with editorial opinions that belong to the writing engine, not the evaluator.

**Why it happens:** "Find every flaw" and "be thorough" read as an invitation to provide complete analysis including remediation. The model's helpful defaults push toward suggestions.

**How to avoid:** The agent system prompt must explicitly prohibit fix suggestions: "Your output is scores, failure points, and explanations of what is wrong. Do NOT suggest how to fix problems. Do NOT rewrite any sentences. Do NOT propose alternative phrasings. Identifying the problem is your complete job."

**Warning signs:** `explanation` fields in eval.json contain phrases like "could be improved by...", "consider changing...", "would be stronger if...".

### Pitfall 5: Edge Case Handling — Very Short or Structureless Texts

**What goes wrong:** `/eval` is invoked on a standalone note, a draft fragment, or a very short text. The critic scores it against full rubric criteria designed for complete pieces. Scores are artificially low because the text is incomplete by design, not because it is poorly written. The user gets an unhelpful eval.

**Why it happens:** The eval system is designed for complete outputs. Edge cases arise when users invoke `/eval` on any text file (which CONTEXT.md says is valid for standalone use).

**How to avoid (Claude's discretion area):** The SKILL.md should detect text length before dispatch. If word count < 150 (approximate minimum for meaningful evaluation), output a warning: "Text is too short for reliable criterion-level evaluation (N words). Eval scores for very short texts are not comparable to scores for complete pieces." Then proceed with the eval but flag it in the output. Do not block eval entirely — let the user decide.

**Edge cases to handle in SKILL.md before dispatch:**
- Text file not found → STOP with error message
- Preset not found → STOP with error message, list available presets
- Preset found but `rubric.criteria` is empty → STOP with error
- Text < 150 words → Warn, continue
- Text > 5000 words → Warn that eval quality may degrade (context window pressure on critic), continue

---

## Code Examples

Verified patterns from established project research:

### eval/SKILL.md — Invocation and Preset Injection

```markdown
---
name: eval
description: Evaluate any text against a preset rubric. Runs a hyper-critical subagent to produce criterion-level scores, located failure points, and a machine-readable eval snapshot. Usage: /eval @<file> --preset <id>
disable-model-invocation: true
context: fork
agent: eval-critic
allowed-tools: Read Write Bash(jq *) Bash(wc *) Bash(date *)
effort: high
---

## Active Rubric
!`cat presets/$PRESET_ID.json | jq '.rubric.criteria'`

## Text to Evaluate
!`cat $TEXT_PATH`

Evaluate the text above against the rubric criteria above.
Score each criterion on a 1-10 integer scale.
Return ONLY a valid JSON object matching the eval snapshot schema below.
```

Note: Dynamic injection (`!`command``) preprocesses before Claude sees the skill content. `$PRESET_ID` and `$TEXT_PATH` are positional arguments from the invocation. The SKILL.md instructions describe how to handle the argument parsing before the fork.

### eval-critic.md — System Prompt Structure

```markdown
---
name: eval-critic
description: Hyper-critical writing evaluation agent. Scores text against injected rubric criteria. Adversarial framing. Read-only.
model: claude-sonnet-4-6
effort: high
allowed-tools: Read
---

You are a hyper-critical writing evaluator. Your sole job is to find weaknesses.
You do not encourage. You do not soften failure points. You do not suggest fixes.
You find every observable flaw and report it precisely.

## Your Output Contract

Return only valid JSON. No preamble. No explanation outside the JSON.
The JSON must match this schema exactly:

{
  "criteria": [
    {
      "name": "<criterion name>",
      "score": <integer 1-10>,
      "weight": <from rubric>,
      "pass": <true if score >= 6, false otherwise>,
      "failure_points": [
        {
          "location": "<Paragraph N, sentence N>",
          "description": "<specific observable problem>",
          "severity": "<critical|major|minor>"
        }
      ],
      "explanation": "<1-2 sentences explaining the score>"
    }
  ],
  "aggregate_score": <weighted sum>,
  "aggregate_pass": <true if all criteria pass AND aggregate >= 6>
}

## Location Requirement

Every failure_point.location MUST name a specific paragraph number and sentence number.
"Paragraph 3, sentence 2" is acceptable.
"Throughout", "in several places", "the middle section" are NOT acceptable.
A failure point without a specific location is a failed output — regenerate it.

## Fabrication Prohibition

Only report observable failures. Do not invent problems.
If a criterion has no failure points, return an empty array.
A clean score is a valid score.
```

### eval/SKILL.md — Writing eval.json

After the critic returns scores, the SKILL.md writes the final eval.json:

```bash
# Capture the run directory (from argument or auto-detect from runs/latest)
RUN_DIR="runs/$(cat runs/latest.txt 2>/dev/null || ls -t runs/ | head -1)"

# Write the eval snapshot
# (SKILL.md instructions direct Claude to write this using the Write tool)
# Path: ${RUN_DIR}/eval.json
```

The SKILL.md instructs Claude to:
1. Parse the critic's JSON output
2. Add `preset`, `preset_version`, `timestamp`, and `text_path` fields
3. Write the complete eval.json to `${RUN_DIR}/eval.json` using the Write tool
4. Confirm to the user with a summary (aggregate score, pass/fail, number of failure points per criterion)

### User Summary Format

After writing eval.json, display:

```
Eval complete.

Preset:          blog-post v1.0.0
Text:            runs/2026-04-05_12-00-00_blog-post/output.md
Aggregate score: 6.2 / 10  [PASS]

Criterion scores:
  novelty         7  PASS
  clarity         5  FAIL  (2 failure points)
  structure       8  PASS
  voice_preservation  6  PASS
  audience_fit    7  PASS
  concision       6  PASS
  factual_integrity  9  PASS

Snapshot: runs/2026-04-05_12-00-00_blog-post/eval.json
```

---

## Rubric Anchors (Claude's Discretion — Recommended Implementation)

These are recommended anchors for the 7 core criteria. These belong in `eval-critic.md` as the scoring calibration section. Claude has discretion to refine the exact language.

### novelty
- **9-10:** The text advances at least one claim, framing, or insight the reader has not encountered in standard treatment of this topic. The idea is specific enough to be falsifiable or arguable.
- **6-8:** The main point is not generic but does not introduce a genuinely new framing. A knowledgeable reader would find it competent and well-executed but not surprising.
- **3-5:** The primary claims are familiar restatements of common positions. A reader who has read one or two pieces on this topic would find nothing new.
- **1-2:** The text states only what is obvious or universally known. No reader would learn anything from it.

### clarity
- **9-10:** Every sentence is unambiguous on first read. No pronoun ambiguity. No jargon without context. No sentence requires re-reading to parse meaning.
- **6-8:** Nearly all sentences are clear. One or two sentences require a second read or brief effort to parse. Antecedent ambiguity appears at most once or twice.
- **3-5:** Several sentences are genuinely ambiguous. A careful reader must re-read paragraphs to establish meaning. One or more terms are undefined for the target audience.
- **1-2:** Multiple sentences are incomprehensible. The reader cannot determine the meaning of key sentences without external context.

### structure
- **9-10:** The arc holds completely. Opening earns its ending. Each section transitions naturally. No section floats disconnected from the argument. The piece has a single discernible shape.
- **6-8:** The overall shape is clear. One or two transitions are weak or abrupt but the piece still reads in logical order. A missing section would be noticed but the piece survives without it.
- **3-5:** The piece has a recognizable topic but the sections do not build on each other. Re-ordering several paragraphs would not change the piece's impact because the arc is not load-bearing.
- **1-2:** Sections appear in arbitrary order. The reader cannot determine why a paragraph follows the previous one. The opening and ending are not connected.

### voice_preservation
- **9-10:** The revised text is indistinguishable in register, vocabulary, and rhetorical habit from the author's established voice. Characteristic patterns (fragments, contractions, sentence length rhythm) are intact.
- **6-8:** The core voice is intact. One or two sentences have drifted toward generic phrasing that the author would not have chosen, but these are isolated. The overall voice fingerprint is recognizable.
- **3-5:** Voice drift is noticeable across multiple passages. The revised text reads like a competent version of the piece, not like the author's version. Characteristic vocabulary or patterns have been replaced with defaults.
- **1-2:** The voice is gone. The revised text reads as if a different person wrote it. Registers have shifted, characteristic patterns are absent, and the author's fingerprint is undetectable.

### audience_fit
- **9-10:** The text assumes exactly the right level of knowledge for the target audience. No over-explanation of concepts the audience knows. No under-explanation of concepts they need. Vocabulary matches the audience's register.
- **6-8:** Mostly well-pitched. One or two passages either over-explain basics or skip steps the audience would need. Overall the reader is neither patronized nor lost.
- **3-5:** Significant calibration mismatch. Either assumes knowledge the audience does not have (causing confusion) or explains at length what the audience already knows (causing disengagement).
- **1-2:** The piece is pitched entirely at the wrong audience. An expert piece delivered to beginners, or a beginner explanation delivered to experts. The mismatch pervades the entire piece.

### concision
- **9-10:** No filler sentences. Nothing repeats without adding new information. Every paragraph advances the piece. Each sentence earns its place.
- **6-8:** One or two sentences or passages are redundant or could be cut without loss. The piece does not feel padded but a careful editor would trim a sentence or two.
- **3-5:** Multiple redundant passages. The thesis is restated unnecessarily. Paragraphs exist that summarize what the previous paragraph already said. Cutting 20% would not lose any meaning.
- **1-2:** The piece is significantly padded. More than 30% of the text is redundant or filler. Removing it would improve every other criterion score.

### factual_integrity
- **9-10:** No invented citations, no fabricated claims, no strengthened claims beyond what the source supports. All qualifications from the original are preserved. No new factual assertions appear that were not in the input.
- **6-8:** One minor inconsistency or a qualification that was dropped without materially changing the claim. No fabrication.
- **3-5:** A claim has been strengthened beyond what the source supports, or a qualification has been removed in a way that changes the claim's scope. No outright fabrication.
- **1-2:** Citations were invented, statistics were fabricated, or the author's stated position was reversed. Hard failure.

**Note:** `factual_integrity` is a critical criterion. Any score below 6 forces `aggregate_pass: false` regardless of other scores, even if the weighted aggregate would otherwise pass.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Self-eval (same context) | Separate subagent (`context: fork`) | Phase architecture decision | Eliminates self-preference bias at the architectural level |
| Holistic quality scores | Criterion-level anchored scores | Phase 3 design | Reduces eval variance; makes failure points actionable |
| 1-5 float scale (STACK.md research) | 1-10 integer scale (CONTEXT.md locked decision) | Phase 3 design discussion | Simpler, comparable, no floating-point variance; pass threshold at 6 |
| `evals/` directory for snapshots | `runs/<run>/eval.json` co-located with revision | Phase 3 design | Eval and revision artifacts travel together; evals/ is available for cross-run comparison if needed |

**Deprecated:**
- The `passing_threshold: 3.5` field in presets is a Phase 1 artifact from the 1-5 scale. It is superseded by the Phase 3 decision to use score >= 6 as the pass threshold. Do not read this field for pass/fail determination in the eval system.

---

## Open Questions

1. **Human-readable summary file**
   - What we know: CONTEXT.md designates this as Claude's discretion
   - What's unclear: Whether `eval.json` alone is sufficient for users, or whether a companion `eval-summary.md` is worthwhile
   - Recommendation: Write the human-readable summary to stdout (displayed in the terminal) rather than to a file. Keep `eval.json` as the only output artifact. If the user wants the summary persisted, they can redirect stdout. This avoids proliferating files in the run directory for what is essentially a pretty-print of eval.json.

2. **Auto-detect preset from latest run**
   - What we know: CONTEXT.md says eval can auto-detect preset from latest run directory when `--preset` is omitted
   - What's unclear: The detection mechanism — does it read `runs/latest.txt` then parse `metadata.json` for `preset_id`?
   - Recommendation: SKILL.md reads `runs/latest.txt` (or `runs/latest` symlink on POSIX) to get the run directory path, then reads `runs/<dir>/metadata.json` and extracts `preset_id`. This reuses the Phase 2 metadata.json without adding new infrastructure.

3. **Eval on standalone text (not a revision output)**
   - What we know: `/eval @any-text.md --preset X` is explicitly supported per CONTEXT.md
   - What's unclear: Whether `text_path` in eval.json should be the absolute path or relative to repo root, and whether the eval.json should be written to the standalone text's directory or to `evals/`
   - Recommendation: For standalone eval (text not in `runs/`), write eval.json to `evals/<timestamp>_<preset-id>_<text-slug>.json`. The `text_path` field uses the path as provided by the user. Document this behavior in SKILL.md.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — this phase builds Claude Code primitives and local JSON files only).

The only tools used (`jq`, `diff`, `date`, `wc`) were verified as available in Phase 2. No new dependencies are introduced.

---

## Project Constraints (from CLAUDE.md)

These directives from CLAUDE.md are binding on this phase.

| Directive | Impact on Eval Phase |
|-----------|---------------------|
| Never invent citations or references | Eval agent must prohibit fabricating failure points — same constraint applies to the critic |
| Never fabricate statistics, examples, or claims | Eval agent failure_points must only report observable problems; the agent must not invent weaknesses to appear thorough |
| Preserve the author's voice by default | voice_preservation is a critical criterion in all presets; any score < 6 forces aggregate_pass: false |
| Pass Scope — every revision pass operates within its defined scope | The eval agent is read-only and score-only; it must not suggest fixes or perform any writing |
| Read the active preset before any revision begins | Eval agent receives preset rubric.criteria as injected context; it does not score without a preset |
| JSON for all structured data | eval.json must be valid JSON; no YAML, no Markdown tables as the machine-readable output |
| One SKILL.md per writing task | /eval is a separate skill in `.claude/skills/eval/SKILL.md`; it does not merge with /improve |
| Context: fork for eval agent invocations | Enforced via SKILL.md frontmatter; the critic never shares context with the writing agent |

---

## Sources

### Primary (HIGH confidence)

- `.planning/research/STACK.md` — Claude Code subagent pattern, `context: fork`, `allowed-tools: Read`, agent frontmatter schema, `disable-model-invocation` flag, shell dynamic injection
- `.planning/research/ARCHITECTURE.md` — Eval system component boundaries, data flow, file store pattern, anti-pattern: eval agent in same context as writing engine
- `.planning/research/PITFALLS.md` — Eval self-preference bias (Pitfall 3), eval score inconsistency (Pitfall 8), Goodhart's Law (Pitfall 4), anchored scoring requirement, temperature=0 for consistency
- `presets/blog-post.json`, `presets/argumentative-essay.json`, `presets/technical-explainer.json` — Verified rubric.criteria structure, weights, passing_threshold, critical_criteria fields
- `presets/preset-schema.json` — JSON Schema draft-07 definition confirming rubric.criteria array structure
- `.claude/skills/improve/SKILL.md` — Phase 2 run directory pattern, metadata.json schema, diff artifact conventions
- `.planning/phases/03-eval-system/03-CONTEXT.md` — Locked decisions: score scale (1-10 integer), pass threshold (>= 6), eval snapshot schema, agent design constraints

### Secondary (MEDIUM confidence)

- PITFALLS.md sources: arxiv.org/html/2410.21819v1 — Self-preference bias evidence for Claude; evidentlyai.com LLM-as-a-Judge guide — rubric design and calibration

### Tertiary (LOW confidence)

None — all critical claims verified against primary project documents.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Claude Code primitives verified in STACK.md from official docs
- Architecture: HIGH — patterns established in Phase 2, subagent pattern verified in ARCHITECTURE.md
- Eval schema: HIGH — schema is locked in CONTEXT.md; cross-verified against preset structure
- Rubric anchors: MEDIUM — observable behavior anchors are Claude's discretion; recommended language is based on established LLM-as-judge practices from PITFALLS.md sources, but exact wording should be tested for consistency
- Pitfalls: HIGH — directly derived from PITFALLS.md which cited peer-reviewed sources

**Research date:** 2026-04-05
**Valid until:** Stable — Claude Code primitive APIs change slowly; SKILL.md frontmatter schema is unlikely to change in the v1 development window. Re-verify if Claude Code releases a major version update.
