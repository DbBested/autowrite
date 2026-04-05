# Architecture Research

**Domain:** Claude Code-native writing workflow system
**Researched:** 2026-04-05
**Confidence:** HIGH (official Claude Code docs + verified patterns)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Entry Points                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  /improve    │  │  /build      │  │  /adapt              │   │
│  │  (skill)     │  │  (skill)     │  │  (skill)             │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
├─────────┴─────────────────┴──────────────────────┴───────────────┤
│                     Writing Engine                                │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  Orchestrator (CLAUDE.md + skill instructions)               │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐               │ │
│  │  │  diagnose  │ │  plan      │ │  pass seq  │               │ │
│  │  │  pass      │ │  pass      │ │  (n passes)│               │ │
│  │  └────────────┘ └────────────┘ └────────────┘               │ │
│  └──────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                     Support Systems                              │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  Preset System  │  │   Eval System    │  │  Autoloop      │  │
│  │  (JSON/YAML     │  │   (subagent:     │  │  (mutation +   │  │
│  │   definitions)  │  │    critic)       │  │   eval cycle)  │  │
│  └────────┬────────┘  └───────┬──────────┘  └───────┬────────┘  │
│           │                   │                      │           │
├───────────┴───────────────────┴──────────────────────┴───────────┤
│                     File Store                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │ drafts/  │ │presets/  │ │  evals/  │ │autoloop/ │ │ runs/  │ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| Entry point skills | Accept user input, load preset, invoke engine | SKILL.md files in `.claude/skills/` |
| Writing engine | Orchestrate staged revision passes against a preset | CLAUDE.md instructions + skill content |
| Preset system | Define "good" per writing form (schema, rubric, voice rules) | JSON or YAML files in `presets/` |
| Eval system | Score outputs on criterion-level rubric, no self-eval | Dedicated subagent in `.claude/agents/` |
| Autoloop | Mutate one asset (skill or preset), eval before/after, keep improvements | Scripts + JSON run logs in `autoloop/` |
| File store | Drafts, outputs, diffs, eval snapshots, run logs | Local filesystem under repo root |

---

## Recommended Project Structure

```
autowrite/
├── CLAUDE.md                    # Repo-wide behavior: voice rules, safety constraints, pass vocabulary
├── .claude/
│   ├── skills/
│   │   ├── improve/
│   │   │   ├── SKILL.md         # /improve entry point: improve existing draft through staged passes
│   │   │   └── passes.md        # Reference: ordered pass list, what each pass does
│   │   ├── build/
│   │   │   └── SKILL.md         # /build entry point: build from notes/outline to polished piece
│   │   ├── adapt/
│   │   │   └── SKILL.md         # /adapt entry point: rewrite into a different writing form
│   │   ├── create-preset/
│   │   │   ├── SKILL.md         # /create-preset: analyze examples, synthesize preset schema
│   │   │   └── schema.md        # Reference: full preset schema definition
│   │   ├── eval/
│   │   │   └── SKILL.md         # /eval: run eval agent against a draft, write snapshot
│   │   └── autoloop/
│   │       └── SKILL.md         # /autoloop: trigger mutation + eval cycle
│   └── agents/
│       └── writing-critic.md    # Specialized eval subagent — independent context, critic persona
├── presets/
│   ├── blog-post.json           # Hand-tuned preset: form, goals, stages, voice rules, rubric
│   ├── argumentative-essay.json
│   └── technical-explainer.json
├── drafts/                      # Input drafts (user-owned, not modified in place)
│   └── .gitkeep
├── runs/                        # Output per run: revised draft, diff, explanation, eval snapshot
│   └── YYYYMMDD-HHMMSS-<slug>/
│       ├── output.md            # Revised draft
│       ├── diff.md              # Structured diff with change explanations
│       ├── explanation.md       # High-level summary of changes made
│       └── eval.json            # Criterion-level scores for this run
├── evals/                       # Persistent eval snapshots for comparison across runs
│   └── <draft-slug>-<timestamp>.json
├── autoloop/
│   ├── runs/                    # Mutation run logs: before/after scores, asset snapshot
│   │   └── <timestamp>-<asset>-mutation.json
│   └── accepted/                # Assets promoted by autoloop (diff from baseline)
│       └── <asset>-<timestamp>.patch
└── scripts/
    ├── diff.sh                  # Generate structured diff between two files
    ├── run-eval.sh              # Invoke eval subagent on a specific run output
    └── autoloop-step.sh         # One mutation cycle: mutate → eval → compare → keep/revert
```

### Structure Rationale

- **.claude/skills/**: Each workflow is an independently invokable skill. Skills can reference each other's outputs via the file store but don't call each other directly — this keeps invocation explicit and inspectable.
- **.claude/agents/**: The eval subagent lives here as a separate agent file, not a skill. This enforces the separation: the writing agent and the eval agent never share a context window during a single run.
- **presets/**: JSON/YAML files, not embedded in skills. Presets are data, not code — they can be created, versioned, compared, and mutated without touching skill logic.
- **runs/**: Each run gets a timestamped directory containing all artifacts. This makes diffs, evals, and explanations linkable and replayable without re-running the engine.
- **evals/**: Persistent snapshot store separate from run output. The autoloop reads evals/ to compare before/after mutation scores without depending on a specific run directory.
- **autoloop/**: Mutation run logs are append-only. Accepted mutations are stored as patches for audit. Nothing in autoloop/ overwrites the canonical presets/ or skills/ files — it proposes, the human approves.

---

## Architectural Patterns

### Pattern 1: File Store as Inter-Component Bus

**What:** All components communicate by reading and writing local files, not by calling each other directly. The writing engine writes `runs/<slug>/output.md`. The eval agent reads that file and writes `runs/<slug>/eval.json`. The autoloop reads `evals/` and `autoloop/runs/` to compare.

**When to use:** Always, in this architecture. This is the Claude Code-native approach — no in-process APIs, no function calls across component boundaries, no shared mutable state.

**Trade-offs:**
- Pro: Fully inspectable at every step. Any component failure leaves partial artifacts that can be debugged.
- Pro: Components can be developed, tested, and invoked independently.
- Con: No transactional guarantees — if a run is interrupted mid-pass, the run directory is in a partial state. Mitigate with a `status.json` file per run.

**Example:**
```
# Writing engine completes a run:
runs/20260405-143022-my-draft/
  output.md       <- writing engine writes this
  explanation.md  <- writing engine writes this
  diff.md         <- scripts/diff.sh writes this

# Eval agent runs after:
# reads output.md, writes:
  eval.json       <- eval subagent writes this
```

### Pattern 2: Preset as Single Source of Truth for "Good"

**What:** A preset JSON file defines everything the writing engine needs to evaluate and improve a piece: the form (blog post, argumentative essay, etc.), the goal, the ordered pass sequence, per-pass instructions, voice rules, structure expectations, rubric criteria and weights, hard constraints, and transformation defaults.

**When to use:** Before any pass executes, the engine loads the preset for the target form. Every pass reads from the same preset — no hardcoded pass logic in skills.

**Trade-offs:**
- Pro: Changing what "good" means for a form is a single file edit, not a skill refactor.
- Pro: Presets are independently versionable and diffable.
- Con: Schema discipline required. A malformed preset will cause silent misbehavior, not a loud error. Use JSON Schema validation in scripts.

**Example preset schema (abbreviated):**
```json
{
  "form": "blog-post",
  "goal": "Engaging, clear post that delivers one insight and respects the author's voice",
  "passes": ["diagnose", "revision-plan", "structure", "clarity", "hook", "ending", "final-review"],
  "voice_rules": {
    "preserve_author_register": true,
    "flag_voice_changes": true,
    "aggressive_rewrite_requires_explicit_request": true
  },
  "rubric": {
    "novelty": {"weight": 0.20, "description": "Does it say something worth saying?"},
    "clarity": {"weight": 0.20, "description": "Is each sentence unambiguous?"},
    "structure": {"weight": 0.15, "description": "Does the arc hold?"},
    "voice_preservation": {"weight": 0.20, "description": "Does it still sound like the author?"},
    "audience_fit": {"weight": 0.10, "description": "Right register for the target reader?"},
    "concision": {"weight": 0.10, "description": "No filler sentences?"},
    "factual_integrity": {"weight": 0.05, "description": "No invented citations or fabricated claims?"}
  },
  "constraints": [
    "Never invent citations",
    "Never fabricate facts",
    "Never silently shift author stance"
  ]
}
```

### Pattern 3: Specialized Eval Subagent (Critic Separation)

**What:** The eval system is a dedicated Claude Code subagent defined in `.claude/agents/writing-critic.md`. It has its own system prompt, its own context window, and read-only tool access. The main writing engine never evaluates its own output — it delegates to the critic.

**When to use:** Whenever a score is needed: after a run completes, during the autoloop, or when the user explicitly invokes `/eval`.

**Trade-offs:**
- Pro: Objective criticism. The critic has no memory of generating the text and applies the rubric cleanly.
- Pro: Subagent isolation means eval context does not contaminate the main conversation.
- Con: Additional API call per evaluation. At ~300 output tokens per eval, cost is small but nonzero.

**Example subagent frontmatter:**
```yaml
---
name: writing-critic
description: Specialized writing evaluation agent. Use when scoring a draft against a preset rubric.
model: claude-sonnet-4-6
tools: Read
memory: none
---
```

### Pattern 4: Autoloop as Mutation-Eval Cycle

**What:** The autoloop treats skills and presets as mutable assets. Each cycle: (1) propose a targeted mutation to one asset, (2) run a before snapshot if one does not exist, (3) apply the mutation, (4) run the writing engine on a reference draft, (5) run the eval agent on the new output, (6) compare scores, (7) keep if aggregate improves with no critical regressions, revert if not.

**When to use:** When a skill or preset is underperforming on a specific criterion and you want systematic improvement rather than manual guessing.

**Trade-offs:**
- Pro: Evidence-based improvement. Every accepted change has a before/after score pair.
- Con: Requires stable reference drafts (inputs that don't change between mutation cycles) and a consistent eval agent. Drift in either breaks the comparison.

**Example cycle log:**
```json
{
  "cycle": 3,
  "asset": "presets/blog-post.json",
  "mutation": "Tightened hook pass instructions to require a question or provocative claim in first sentence",
  "scores_before": {"novelty": 0.72, "clarity": 0.81, "voice_preservation": 0.88, "aggregate": 0.78},
  "scores_after":  {"novelty": 0.79, "clarity": 0.80, "voice_preservation": 0.87, "aggregate": 0.81},
  "decision": "accepted",
  "reason": "Aggregate improved 0.03, no criterion regressed below threshold"
}
```

---

## Data Flow

### Primary Flow: Draft Improvement

```
User invokes /improve <draft.md> [--preset blog-post]
    |
    v
improve/SKILL.md loads
    |
    v
Read presets/blog-post.json  -->  pass sequence, rubric, voice rules, constraints
    |
    v
Read drafts/<draft.md>       -->  source text
    |
    v
[Diagnose pass]
  Write runs/<slug>/diagnosis.md
    |
    v
[Revision plan pass]
  Read diagnosis.md
  Write runs/<slug>/revision-plan.md
    |
    v
[Ordered content passes: structure -> clarity -> argument -> ...]
  Each pass reads: source, preset, previous pass output
  Each pass writes: intermediate output to runs/<slug>/pass-N.md
    |
    v
[Final review pass]
  Write runs/<slug>/output.md
    |
    v
scripts/diff.sh drafts/<draft.md> runs/<slug>/output.md
  Write runs/<slug>/diff.md
    |
    v
Write runs/<slug>/explanation.md (summary of changes)
    |
    v
[Optional] Eval agent reads output.md + preset rubric
  Write runs/<slug>/eval.json
    |
    v
Return path to runs/<slug>/
```

### Preset Creation Flow

```
User invokes /create-preset <example1.md> [<example2.md> ...]
    |
    v
create-preset/SKILL.md loads
    |
    v
Read all example files
    |
    v
[Analyze pass] Infer: form, register, structure patterns, recurring devices
    |
    v
[Synthesize pass] Map inferences to preset schema fields
    |
    v
[Inferred preset displayed] User reviews, approves, requests changes
    |
    v
Write presets/<form-name>.json
```

### Autoloop Flow

```
User invokes /autoloop <asset> [--reference-draft <draft.md>]
    |
    v
Check if evals/<draft-slug>-baseline.json exists
  If not: run eval agent on current output -> write baseline
    |
    v
[Mutation proposal] Analyze asset + baseline eval weaknesses
  Propose targeted change to one field or instruction
    |
    v
Apply mutation to asset (in working copy)
    |
    v
Run writing engine on reference draft -> new output
    |
    v
Run eval agent on new output -> new eval snapshot
    |
    v
Compare scores (aggregate + per-criterion)
    |
    v
Decision:
  Improvement + no critical regressions? -> Accept, write autoloop/runs/<log>.json
  Regression or no improvement?          -> Revert asset, write log with reason
    |
    v
Write autoloop/runs/<timestamp>-<asset>-mutation.json
```

### Key Data Flows Summary

1. **Preset in, passes out:** The preset governs which passes run, in what order, and with what constraints. No pass sequence is hardcoded in a skill.
2. **Each pass is additive:** Passes write to separate intermediate files. The final pass combines. No pass overwrites the source draft.
3. **Eval never touches the source:** The eval subagent has read-only tools. It reads output files and writes score files. It cannot modify drafts or presets.
4. **Autoloop is non-destructive by default:** Mutations are applied to working copies. Canonical files in `presets/` and `.claude/skills/` are only updated on explicit acceptance.

---

## Anti-Patterns

### Anti-Pattern 1: Monolithic Single-Pass Rewrite

**What people do:** Write one skill that reads the draft and outputs a complete rewrite in a single pass.

**Why it's wrong:** Single-pass rewrites accumulate all transformation decisions simultaneously, making it nearly impossible to preserve voice. When voice is lost, there is no intermediate state to diagnose which pass caused the drift. The user sees a final output that no longer sounds like them with no actionable feedback.

**Do this instead:** Run a diagnose pass first. Run a revision plan pass before any content changes. Run content passes in order of structural concern (structure before clarity, clarity before tone). Each pass is narrow in scope.

### Anti-Pattern 2: Embedding Rubric Criteria in Skill Instructions

**What people do:** Hardcode evaluation criteria inside the `/improve` skill: "make the writing clear, concise, and engaging."

**Why it's wrong:** The rubric becomes invisible and un-tunable. You cannot run the autoloop against it because there is nothing to mutate. Different forms (blog post vs. technical explainer) have different criteria weights that cannot be expressed in a single embedded string.

**Do this instead:** The rubric lives exclusively in the preset JSON. The skill reads the preset. The eval subagent scores against the preset rubric. The rubric is the single source of truth for what "good" means.

### Anti-Pattern 3: Eval Agent in the Same Context as the Writing Engine

**What people do:** Ask Claude to write the revision, then in the same conversation ask it to score the revision.

**Why it's wrong:** The model is aware it generated the text. Self-evaluation in the same context window produces inflated scores and avoids flagging the model's own choices as weaknesses. This breaks the autoloop because scores become unreliable comparators.

**Do this instead:** Always run evaluation through the dedicated writing-critic subagent. The subagent has its own context window and no memory of generating the text.

### Anti-Pattern 4: Autoloop Without Stable Reference Drafts

**What people do:** Run the autoloop against different drafts in each cycle, comparing scores across inputs.

**Why it's wrong:** Score changes reflect both the asset mutation and the input variance. You cannot determine whether an improvement came from the mutation or the different draft.

**Do this instead:** Keep a small set of reference drafts locked in `autoloop/reference-drafts/`. Run every cycle against the same reference drafts. Score delta is attributable to the mutation.

### Anti-Pattern 5: Storing Voice Rules in CLAUDE.md Only

**What people do:** Put all voice preservation rules in CLAUDE.md ("never change the author's register") and assume they apply universally.

**Why it's wrong:** CLAUDE.md applies globally but has no per-form specificity. A technical explainer has different voice norms than a personal blog post. Global rules get too loose to be actionable.

**Do this instead:** Put universal safety rules in CLAUDE.md (no fabricated citations, no silent stance shifts). Put form-specific voice rules in the preset. The skill reads both.

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Entry skill → Writing engine | Skill invokes engine logic via CLAUDE.md + its own instructions | No separate process; same Claude context |
| Writing engine → Preset system | File read: `presets/<form>.json` | Engine never writes to presets/ |
| Writing engine → Eval system | File handoff: engine writes `runs/<slug>/output.md`, eval reads it | Eval runs in separate subagent context |
| Eval system → Autoloop | File read: `evals/<snapshot>.json` | Autoloop reads eval snapshots, never calls eval agent directly |
| Autoloop → Asset files | Controlled mutation + optional write | Only writes on explicit acceptance decision |
| Any skill → File store | Read/write via Claude's Read/Write/Edit tools | All intermediate state is local files |

### Hooks Integration (Optional but Valuable)

Hooks can automate artifact generation without burdening the main skill logic:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "if": "Write(**/runs/**/output.md)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/diff.sh"
          }
        ]
      }
    ]
  }
}
```

This generates the diff automatically when output.md is written, without requiring the skill to explicitly invoke the diff script. Keeps skills focused on content logic, not artifact management.

---

## Build Order Implications

The component dependencies create a natural build sequence:

**Phase 1 — File Store + CLAUDE.md**
Everything else reads from or writes to the file store. CLAUDE.md establishes universal safety rules. Neither has external dependencies.

**Phase 2 — Preset System**
Three hand-tuned presets (blog-post, argumentative-essay, technical-explainer). Preset schema must be stable before the writing engine or eval system can be built against it. The `/create-preset` skill can come later — hand-tuned presets come first.

**Phase 3 — Writing Engine (Core Passes)**
The diagnose and revision-plan passes can be developed and tested against a reference draft + a preset before any content passes exist. Add passes incrementally: structure before clarity, clarity before tone.

**Phase 4 — Eval System**
The eval subagent requires a stable rubric (from Phase 2) and stable outputs (from Phase 3) to produce meaningful scores. Building eval before the engine produces nothing to score.

**Phase 5 — Autoloop**
The autoloop depends on the eval system (for scoring) and the preset/skill assets (as mutation targets). It is the last system to build because it requires all others to function correctly. An autoloop built on an unstable eval system will accept mutations based on noise.

**Phase 6 — Preset Creation Skill**
The `/create-preset` skill is a convenience feature, not a dependency. It can be built any time after Phase 2. The three hand-tuned presets are the foundation; preset creation is an accelerator for users who want custom forms.

---

## Scaling Considerations

This system operates at single-user, local scale. "Scaling" means handling larger or more complex inputs, not concurrent users.

| Concern | Current approach | When it becomes a problem |
|---------|-----------------|--------------------------|
| Long drafts (>5k words) | Multi-pass in sequence | Context window pressure in later passes. Mitigation: chunk long drafts, process sections, merge. |
| Many passes per run | Sequential file I/O | Context accumulates. Mitigation: use `context: fork` in skills to isolate each pass in a subagent. |
| Autoloop convergence | Manual invocation per cycle | Not a problem for v1. Future: script multi-cycle runs with acceptance thresholds. |
| Preset proliferation | Flat `presets/` directory | Not a problem under ~20 presets. |

---

## Sources

- [Claude Code: How skills work (official docs)](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter, supporting files, subagent execution (HIGH confidence)
- [Claude Code: How it works (official docs)](https://code.claude.com/docs/en/how-claude-code-works) — Agentic loop, context window, CLAUDE.md (HIGH confidence)
- [Claude Code: Subagents (official docs)](https://code.claude.com/docs/en/sub-agents) — Subagent architecture, isolation, tool restriction (HIGH confidence)
- [Claude Code: Hooks (official docs)](https://code.claude.com/docs/en/hooks) — Hook lifecycle, PostToolUse pattern (HIGH confidence)
- [Inside Claude Code architecture (Penligent)](https://www.penligent.ai/hackinglabs/inside-claude-code-the-architecture-behind-tools-memory-hooks-and-mcp/) — Memory/context layers, policy enforcement, data flow (MEDIUM confidence)
- [Claude Code eval loop (mager.co)](https://www.mager.co/blog/2026-03-08-claude-code-eval-loop/) — Skill eval loop pattern (MEDIUM confidence — paywalled, partial access)
- [Recursive self-improvement with Claude Code (Medium)](https://medium.com/@davidroliver/recursive-self-improvement-building-a-self-improving-agent-with-claude-code-d2d2ae941282) — Mutation-eval cycle pattern (MEDIUM confidence — behind paywall, summary only)

---

*Architecture research for: Claude Code-native writing workflow system (Autowrite)*
*Researched: 2026-04-05*
