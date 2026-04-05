# Phase 2: Writing Engine - Research

**Researched:** 2026-04-05
**Domain:** Claude Code-native multi-pass writing revision engine — SKILL.md skill design, pass scope isolation, notes-to-draft detection, preset-driven pass sequencing, run directory management, diff generation, metadata logging
**Confidence:** HIGH — this is an internal/Claude Code-native system with no external library dependencies. All findings are derived from the project's own established patterns (Phase 1), the locked decisions in CONTEXT.md, and the official Claude Code primitives specification embedded in the project STACK.md research from Phase 1.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Skill Invocation:** User invokes via `/improve @draft.md` — preset auto-detected from content with `--preset` override flag
- **Preset auto-inference:** Analyzes content and selects the closest matching preset; user can override with `--preset blog-post` etc.
- **Notes-to-draft:** Uses the same `/improve` skill — detects whether input is rough notes or a polished draft and adjusts passes accordingly
- **Form adaptation:** Uses `/adapt @draft.md --to essay` — reuses the improve engine with the target preset applied
- **Pass execution:** Single `/improve` SKILL.md runs all passes sequentially in one session — each pass writes its output to the run directory
- **Preset `stages` field is authoritative:** All stages listed in the active preset run by default; no hardcoded pass list in the skill
- **Per-pass DO NOT touch constraints:** Each pass prompt includes explicit DO NOT touch constraints (e.g., clarity pass must not restructure paragraphs; structure pass must not edit sentence-level wording)
- **`--depth` flag:** `light` = 3 core passes (diagnose, plan, structure), `standard` = all preset stages, `deep` = all stages plus a second pass on weakest criteria
- **Run directory naming:** `runs/YYYY-MM-DD_HH-MM-SS_preset-name/`
- **Run directory is immutable:** Each run is a timestamped snapshot; never overwritten
- **Run contents:** `input.md`, `diagnosis.md`, `plan.md`, `passes/01-structure.md` through `NN-final.md`, `output.md`, `diff.patch`, `metadata.json`
- **Metadata JSON:** Preset used, pass sequence, timestamps per pass, input word count, output word count, revision depth
- **Symlink `runs/latest`:** Points to most recent run directory for quick access
- **Diff format:** Unified diff (`diff -u`) saved as `diff.patch` — human-readable, standard format
- **Explanation file:** `explanation.md` — each major change with rationale, grouped by pass; one explanation per substantive change, not per word change
- **Output file:** `output.md` is a clean revised draft with no annotations or markup

### Claude's Discretion

- Exact prompt engineering for each pass (specific DO NOT touch constraints per pass type)
- How to detect notes vs draft in the input
- How to auto-infer preset from content
- Pass ordering within "light" depth mode (which 3 core passes)
- Internal error handling and recovery during multi-pass execution

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WRIT-01 | User can submit a draft or notes file and select a preset to begin a revision workflow | SKILL.md invocation pattern — `/improve @draft.md` reads preset from file or flag; preset JSON already exists in `presets/` |
| WRIT-02 | System diagnoses specific weaknesses in the draft before any rewriting | `diagnose` is always first stage in all three preset `stages` arrays; diagnosis pass must produce named, located weaknesses (not generic advice) |
| WRIT-03 | System generates a structured revision plan referencing specific diagnosis findings before applying changes | `revision-plan` is always second stage; plan.md references specific diagnosis findings before pass execution begins |
| WRIT-04 | System applies staged passes in preset-defined sequence with per-pass scope constraints | Pass sequence read from preset `stages` array; each pass gets a scoped prompt with DO NOT touch rules for out-of-scope changes |
| WRIT-05 | Each pass preserves author voice by default using preset voice rules | Voice rules (`voice`, `voiceBehaviors` arrays) injected into every pass prompt; `transformations.preserveVoice` checked before each pass |
| WRIT-06 | System enforces factual integrity per pass — no new claims, no altered citations, no fabricated facts | CLAUDE.md Factual Integrity rules active every session; per-pass prompts explicitly reinforce no-fabrication constraint |
| WRIT-07 | System produces a unified diff between input and output | `diff -u input.md output.md > diff.patch` — standard Unix diff utility; no library needed |
| WRIT-08 | System produces per-change explanations (not just a summary) | `explanation.md` in run directory — final-review pass produces this; structured by pass, one entry per substantive change |
| WRIT-09 | System outputs a final clean revised draft as a single deliverable file | `output.md` in run directory — no markup, no annotations; copy of last non-final-review pass output |
| WRIT-10 | User can build from notes or outline into a polished piece (notes-to-draft flow) | `/improve` skill detects rough notes vs draft at diagnosis step; notes get an expanded `structure` pass and looser voice constraints |
| WRIT-11 | User can adapt a piece into another writing form by switching presets | `/adapt @draft.md --to essay` — reuses improve engine with target preset; adaptation-specific passes handle form conversion |
| RUNL-01 | Each revision run saves to an immutable timestamped directory in `runs/` | Directory created at run start with `runs/YYYY-MM-DD_HH-MM-SS_preset-name/` naming; symlink `runs/latest` updated |
| RUNL-02 | Run directory contains input draft, diagnosis, revision plan, per-pass outputs, final draft, diffs, and eval snapshot | Full artifact list: `input.md`, `diagnosis.md`, `plan.md`, `passes/NN-name.md`, `output.md`, `diff.patch`, `explanation.md` |
| RUNL-03 | Run metadata (preset used, pass sequence, timestamps) saved as JSON | `metadata.json` in run directory — machine-readable, stable format for Phase 3 eval agent and Phase 4 autoloop to consume |

</phase_requirements>

---

## Summary

Phase 2 delivers the core writing engine: a set of Claude Code skill files that orchestrate multi-pass revision from draft submission to revised output. The entire system is Claude Code-native — no Python execution, no external services, no CLI tooling beyond standard Unix utilities (`diff`). The deliverables are SKILL.md files for `/improve`, `/build`, and `/adapt`, a run directory management convention, per-pass scope rules in `.claude/rules/`, and the shell scaffolding to create timestamped run directories and generate diffs.

The dominant design challenge is pass scope isolation. Each pass in the preset's `stages` array must receive a precisely scoped prompt that defines what it may change AND what it must not touch. The voice preservation constraint (from CLAUDE.md and the preset's `voice`/`voiceBehaviors` fields) must be injected into every pass prompt, not just the final review. Getting this wrong produces the classic LLM rewriting failure: the clarity pass subtly flattens the author's voice while improving sentence readability.

The second challenge is the notes-to-draft detection branch. The `/improve` skill must distinguish rough notes (bulleted fragments, incomplete sentences, loose ideas) from a polished draft (full sentences, clear structure, developed argument) at the diagnosis step — then select an appropriate pass depth. Notes get a fuller structure pass with more latitude; drafts get targeted improvement passes with tighter voice constraints.

**Primary recommendation:** Implement `/improve` first as the core skill — it handles the standard draft improvement workflow. `/build` (notes-to-draft) is a variant of `/improve` with adjusted pass framing. `/adapt` is `/improve` with a different preset injected. All three share the same run directory structure and metadata format.

---

## Standard Stack

### Core Primitives

| Primitive | Format | Purpose | Why Standard |
|-----------|--------|---------|--------------|
| `.claude/skills/improve/SKILL.md` | Markdown | Entry point for `/improve` skill invocation | One SKILL.md per writing task — established in Phase 1 D-04 |
| `.claude/skills/build/SKILL.md` | Markdown | Notes-to-draft workflow | Same SKILL.md pattern; notes detection logic in prompt, not separate system |
| `.claude/skills/adapt/SKILL.md` | Markdown | Form adaptation workflow | Same SKILL.md pattern; loads target preset from `--to` flag |
| `.claude/rules/passes/*.md` | Markdown + YAML `paths:` | Per-pass scope constraints | Path-scoped rules pattern from Phase 1 D-07; loads only when executing relevant pass |
| `presets/*.json` | JSON | Preset as single source of truth for stages, voice, rubric | Established in Phase 1; writing engine reads `stages` array to determine pass sequence |
| `runs/YYYY-MM-DD_HH-MM-SS_preset-name/` | Directory | Immutable run snapshot | Locked in CONTEXT.md; timestamped directory prevents overwrites |
| `diff -u` | Unix utility | Unified diff between input and output | No library needed; available on Mac, Linux, and Windows (Git Bash/WSL) |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `date +"%Y-%m-%d_%H-%M-%S"` | Timestamp for run directory naming | Shell command in run setup; produces `YYYY-MM-DD_HH-MM-SS` format |
| `ln -sfn` | Symlink `runs/latest` to current run | Updates latest pointer after run directory creation |
| `wc -w` | Word count for metadata.json | Input and output word counts recorded at run start and end |
| `jq` 1.6+ | Reading preset JSON in shell scaffolding | Extracting `stages`, `id`, `name` from preset file for metadata and run naming |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single `/improve` SKILL.md running all passes | Separate SKILL.md per pass | Separate-per-pass creates N invocations and N context windows; single-skill is one session with continuity between passes — voice drift is caught pass-to-pass |
| Per-pass scope rules in `.claude/rules/passes/*.md` | Inline scope constraints in SKILL.md | Inline puts all constraints in one 500-line SKILL.md. Path-scoped rules load only when relevant, keeping each context lean. |
| `diff -u` via shell | Python `difflib` | `difflib` would require Python invocation from within Claude's skill execution — unnecessary complexity. `diff` is universally available and produces the standard patch format. |
| Timestamped directory names | UUID-based directory names | Timestamps are human-readable and sort naturally. UUIDs require a lookup to understand ordering. |

---

## Architecture Patterns

### Recommended Project Structure (Phase 2 additions)

```
autowrite/
├── .claude/
│   ├── skills/
│   │   ├── improve/
│   │   │   └── SKILL.md         # /improve skill — core revision engine
│   │   ├── build/
│   │   │   └── SKILL.md         # /build skill — notes-to-draft flow
│   │   └── adapt/
│   │       └── SKILL.md         # /adapt skill — form adaptation
│   └── rules/
│       ├── preset-editing.md    # Phase 1 — already exists
│       └── passes/
│           ├── diagnose.md      # Diagnosis pass scope rules
│           ├── revision-plan.md # Plan pass scope rules
│           ├── structure.md     # Structure pass: may move sections; must not edit wording
│           ├── clarity.md       # Clarity pass: sentence-level only; must not restructure
│           ├── argument.md      # Argument pass: claim/evidence only; must not reword
│           ├── tone.md          # Tone pass: register/voice only; must not restructure
│           ├── concision.md     # Concision pass: cuts only; must not reorder
│           └── final-review.md  # Final review: read-only checks + explanation.md writing
└── runs/
    ├── .gitkeep
    └── (created at runtime)
        └── YYYY-MM-DD_HH-MM-SS_preset-name/
            ├── input.md
            ├── diagnosis.md
            ├── plan.md
            ├── passes/
            │   ├── 01-structure.md
            │   ├── 02-clarity.md
            │   └── NN-final-review.md
            ├── output.md
            ├── diff.patch
            ├── explanation.md
            └── metadata.json
```

### Pattern 1: SKILL.md Structure for the Improve Skill

**What:** A SKILL.md defines the full orchestration for a writing task: load preset, create run directory, execute each stage in sequence, write artifacts, produce final output.

**When to use:** Every writing task in Autowrite. The `/improve` SKILL.md is the canonical implementation all other skills extend.

**Key sections a SKILL.md must contain:**

```markdown
# /improve

## What This Skill Does
[One paragraph explaining the workflow]

## Invocation
`/improve @<draft-file> [--preset <preset-id>] [--depth light|standard|deep]`

## Step 1: Load Preset
[Instructions for locating and reading preset JSON]
[Preset auto-detection logic when --preset not specified]

## Step 2: Detect Input Type
[Notes vs draft detection criteria]
[How detection changes the pass selection]

## Step 3: Create Run Directory
[Shell command: `runs/$(date +"%Y-%m-%d_%H-%M-%S")_<preset-id>/`]
[Write input.md as first artifact]
[Update runs/latest symlink]

## Step 4: Execute Passes
[For each stage in preset.stages:]
[  Load per-pass scope rules]
[  Execute pass with voice constraints injected]
[  Write output to passes/NN-<stage-name>.md]

## Step 5: Generate Output and Diff
[Write passes/NN-final-review.md]
[Copy clean output to output.md]
[Run: diff -u input.md output.md > diff.patch]

## Step 6: Write Explanation
[Write explanation.md grouped by pass]

## Step 7: Write Metadata
[Write metadata.json with preset, stages run, timestamps, word counts]

## Voice Preservation Contract
[Verbatim restatement of voice rules from active preset]
[Explicit: these rules apply on every pass without exception]

## Factual Integrity Contract
[Verbatim restatement from CLAUDE.md]
[Explicit: no new claims, no altered citations, no fabricated facts]
```

### Pattern 2: Per-Pass Scope Constraint File

**What:** A `.claude/rules/passes/<pass-name>.md` file defines what a single pass may and may not touch. The `paths:` frontmatter can scope activation, but for pass rules the better pattern is explicit loading in the SKILL.md prompt for each pass.

**When to use:** Every revision pass. Scope isolation prevents cross-contamination between passes.

**Example — structure pass:**

```markdown
# Structure Pass Rules

## Scope: What This Pass Does
- Reorganize sections and paragraphs for improved flow
- Strengthen transitions between sections
- Reorder arguments if the logical sequence is weak

## DO NOT Touch (Out of Scope)
- Individual sentence wording — leave exact sentences as-is
- Vocabulary choices — do not substitute words
- Punctuation and grammar — not this pass's job
- The thesis or central argument — preserve the author's position
- Any cited evidence — do not move, alter, or drop citations

## Voice Preservation
- Read preset voice rules before restructuring
- Short-punchy paragraph style (blog-post) means restructuring should not merge short paragraphs into long ones
- Preserve the author's opening and closing lines unless diagnosis explicitly flagged them as weak
```

**Example — clarity pass:**

```markdown
# Clarity Pass Rules

## Scope: What This Pass Does
- Rewrite sentences that are ambiguous on first read
- Break up sentences that contain more than one idea
- Replace jargon with accessible language where the preset allows it

## DO NOT Touch (Out of Scope)
- Section order or paragraph position — structural decisions are locked after structure pass
- Arguments and claims — do not strengthen or weaken positions
- Evidence and citations — leave exactly as-is
- The author's vocabulary choices when unambiguous — ambiguity must be flagged, not assumed
```

### Pattern 3: Notes vs Draft Detection

**What:** At the diagnosis step, the skill must classify the input as rough notes or a draft before deciding which passes to apply and with what depth.

**Detection criteria (for SKILL.md prompting):**

| Signal | Notes | Draft |
|--------|-------|-------|
| Sentence completeness | Fragments, bullets, incomplete thoughts common | Full sentences throughout |
| Structural completeness | Missing sections, loose ideas without grouping | Recognizable structure (intro/body/conclusion or equivalent) |
| Argument development | Claims without evidence, ideas without elaboration | Claims supported with evidence or reasoning |
| Voice consistency | Inconsistent register, switching between modes | Consistent register throughout |
| Word count relative to expected form | Under 40% of typical length for the form | Over 60% of typical length |

**Behavioral difference when input is notes:**
- Structure pass gets broader latitude (may create sections, not just reorder)
- Argument pass may expand undeveloped points (with factual integrity rules applying — no invented facts)
- Voice pass is lighter — establish register rather than preserve an existing one
- Diagnosis explicitly labels as "notes-to-draft" mode in `diagnosis.md`

### Pattern 4: Preset Auto-Inference

**What:** When `--preset` is not specified, the skill infers the closest matching preset from content analysis.

**Inference logic (for SKILL.md prompting):**

| Form Signal | Inferred Preset |
|-------------|-----------------|
| First-person, contractions, short paragraphs, opinion-driven | `blog-post` |
| Formal register, thesis statement, counterargument section, citations | `argumentative-essay` |
| Technical terms, code examples, "how to" structure, numbered steps | `technical-explainer` |
| Ambiguous or multi-form signals | Ask user to confirm with `--preset` flag before proceeding |

**Important:** When inference confidence is low (multiple competing signals), SKILL.md must stop and ask the user to specify `--preset` explicitly. Running the wrong preset produces incorrectly scoped passes and meaningless rubric scores. Do not guess silently.

### Pattern 5: Metadata JSON Format

**What:** `metadata.json` is the machine-readable record of a run. Phase 3 (eval agent) and Phase 4 (autoloop) consume this file.

**Canonical format:**

```json
{
  "run_id": "2026-04-05_14-32-01_blog-post",
  "preset_id": "blog-post",
  "preset_version": "1.0.0",
  "input_file": "drafts/my-article.md",
  "input_type": "draft",
  "depth": "standard",
  "stages_run": ["diagnose", "revision-plan", "structure", "clarity", "argument", "tone", "concision", "hook", "ending", "final-review"],
  "timestamps": {
    "run_start": "2026-04-05T14:32:01Z",
    "diagnose_complete": "2026-04-05T14:32:45Z",
    "revision_plan_complete": "2026-04-05T14:33:10Z",
    "final_review_complete": "2026-04-05T14:38:22Z",
    "run_end": "2026-04-05T14:38:22Z"
  },
  "word_counts": {
    "input": 847,
    "output": 793
  }
}
```

**Required fields:** `run_id`, `preset_id`, `preset_version`, `input_file`, `input_type`, `depth`, `stages_run`, `timestamps.run_start`, `timestamps.run_end`, `word_counts.input`, `word_counts.output`

**Per-stage timestamps are optional** but recommended — they enable the autoloop (Phase 4) to detect which passes consume the most revision time.

### Anti-Patterns to Avoid

- **Global voice rules in SKILL.md only:** Putting voice constraints solely in the SKILL.md header means per-pass execution may drift. Voice rules must be re-injected into every individual pass prompt. "Preserve author voice" as a global instruction is insufficient — it must be stated with the specific preset voice rules at the point of each pass execution.

- **Passing diagnosis output directly as next-pass input:** The diagnosis produces a weaknesses list. The revision-plan pass takes that diagnosis and produces a plan. Subsequent passes take the previous pass's *draft output*, not the diagnosis. Data flow: `input.md → diagnosis.md → plan.md` (planning) then `input.md → pass-1.md → pass-2.md → ... → output.md` (revision). Mixing these two flows produces passes that rewrite based on plan text rather than draft content.

- **Running diff before final-review:** Generate `diff.patch` after all revision passes complete, comparing original `input.md` against final `output.md`. Running diff pass-by-pass generates noise diffs, not the clean before/after the user needs.

- **Writing explanation.md as a summary:** The CONTEXT.md is explicit: one explanation per substantive change, grouped by pass. "Restructured the opening section" is not useful. "Moved the thesis statement from paragraph 4 to paragraph 1 because diagnosis found a buried lede" is the correct format.

- **Treating `/build` and `/adapt` as completely separate systems:** Both reuse the improve engine's pass execution machinery with adjusted parameters. `/build` = `/improve` with notes-input detection triggered unconditionally. `/adapt` = `/improve` with the target preset loaded from `--to` flag rather than inferred from content. Do not build three separate pass execution pipelines.

- **Hardcoding the pass list in SKILL.md:** The preset's `stages` array is the authoritative pass sequence. SKILL.md must iterate over `preset.stages`, not maintain its own list. This is the key design principle from CONTEXT.md: "The pass sequence is fully defined by the preset's `stages` field — no hardcoded pass list in the skill."

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unified diff between input and output | Custom diff logic in skill prompts | `diff -u input.md output.md > diff.patch` | Standard unified diff format; `diff` utility is universally available; produces git-compatible patch format |
| Timestamp for run directory | Custom date formatting in skill | `date +"%Y-%m-%d_%H-%M-%S"` | Shell built-in; consistent format; sorts lexicographically = chronologically |
| Word count for metadata | Counting words in Claude response | `wc -w < filename` | Shell built-in; faster and exact; no LLM processing cost |
| Pass sequence | Hardcoded list in SKILL.md | Read `preset.stages` array with `jq '.stages' presets/<id>.json` | Preset is the single source of truth; hardcoding the list means SKILL.md and preset drift independently |

**Key insight:** This phase builds no new infrastructure beyond markdown files and shell one-liners. The complexity is entirely in prompt engineering and SKILL.md structure — not in code.

---

## Runtime State Inventory

> This is a greenfield skill implementation phase. No renaming, refactoring, or migration is involved.

None — verified: this phase creates new files only. No existing runtime state, stored data, or OS registrations are affected.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `diff` (GNU/BSD) | WRIT-07 — unified diff generation | Expected on all platforms (Mac, Linux, Git Bash/WSL on Windows) | system | On Windows without Git Bash: `git diff --no-index` produces compatible unified diff |
| `date` | RUNL-01 — run directory timestamp naming | Available on Mac, Linux, Git Bash | system | Hardcode timestamp format instruction in SKILL.md; Claude can produce the timestamp string |
| `ln -sfn` | RUNL-01 — `runs/latest` symlink | Available on Mac, Linux; limited on Windows | system | On Windows: skip symlink, use `runs/latest.txt` containing path to current run directory |
| `wc -w` | RUNL-03 — word count metadata | Available on Mac, Linux, Git Bash | system | Claude counts words at start/end of run session — less precise but functional |
| `jq` 1.6+ | Preset parsing in shell scaffolding | Required (Phase 1 prerequisite) | system | Already documented in Phase 1 research |

**Missing dependencies with no fallback:** None

**Missing dependencies with fallback:**
- `ln -sfn` on Windows: use `runs/latest.txt` file containing the path string as fallback — planner must include Windows-compatible variant

**Note:** Since SKILL.md execution happens inside Claude Code, the shell commands above are executed via Claude's Bash tool. The availability check above applies to the developer's machine environment where Claude Code is running.

---

## Common Pitfalls

### Pitfall 1: Voice Drift Across Passes
**What goes wrong:** The first revision pass (structure) makes appropriate structural changes. By the third pass (clarity), the prose has been incrementally polished into generic LLM prose that no longer sounds like the author.
**Why it happens:** Voice constraints stated once at the SKILL.md level are forgotten or diluted as subsequent passes are executed. Each pass receives a fresh context about what it should do, without the voice anchor being re-stated.
**How to avoid:** Inject the preset's `voice` block and `voiceBehaviors` array into the system prompt of every individual pass. Voice preservation is not a global setting — it is a per-pass constraint that must be explicitly present in each pass's execution context.
**Warning signs:** After structure pass, check if the author's characteristic sentence patterns (fragments, contractions, first-person) are still present. If they've been smoothed away, voice drift has begun.

### Pitfall 2: Diagnosis Without Location
**What goes wrong:** Diagnosis pass produces: "The thesis is weak. The structure needs improvement. The examples could be stronger." This diagnosis cannot drive a useful revision plan.
**Why it happens:** Generic diagnosis is easy to produce and superficially looks useful. Location-specific diagnosis requires reading the draft and citing specific paragraph/sentence evidence.
**How to avoid:** Require diagnosis to name specific locations: "Buried thesis: the central claim first appears in paragraph 4, sentence 2 — it should be in paragraph 1." The CONTEXT.md specifics section is explicit: "Diagnosis should name specific weaknesses (e.g., 'buried thesis in paragraph 3', 'no evidence for claim in section 2') not generic advice."
**Warning signs:** Diagnosis uses vague quantifiers ("the", "some", "several") without referencing specific sections or sentences.

### Pitfall 3: Pass Scope Creep
**What goes wrong:** The clarity pass, while fixing ambiguous sentences, also notices weak arguments and starts strengthening them. The argument pass, while tightening claims, also restructures paragraphs for better flow.
**Why it happens:** LLMs generalize well — when asked to improve clarity, they also improve everything else nearby. Without explicit negative constraints, scope creeps.
**How to avoid:** Every pass prompt must include explicit DO NOT touch constraints. The structure pass rules file is as important as what the pass is allowed to do. Each pass should have a named list of out-of-scope changes.
**Warning signs:** Comparing pass N output to pass N-1 output shows changes that are not attributable to the pass's defined scope.

### Pitfall 4: `runs/latest` Symlink on Windows
**What goes wrong:** `ln -sfn` does not create a valid symlink on Windows file systems unless developer mode is enabled. The skill fails or silently produces a broken symlink.
**Why it happens:** Windows symlinks require elevated permissions or Developer Mode, unlike POSIX systems.
**How to avoid:** Use `runs/latest.txt` on Windows as a fallback — a plain text file containing the path to the most recent run directory. SKILL.md should detect Windows by checking `$OS` or `$OSTYPE` and use the appropriate approach.
**Warning signs:** `ls -la runs/latest` shows a regular file or error rather than a symlink on Windows.

### Pitfall 5: Diff Generated From Wrong Pair
**What goes wrong:** diff.patch shows changes between the last pass output and the previous pass output, rather than between the original input and final output. Or diff is generated against a wrong version of input.
**Why it happens:** Run directory contains multiple intermediate files. The diff command must be explicitly pointed at `input.md` vs `output.md`, not at `passes/NN-*.md` files.
**How to avoid:** SKILL.md must explicitly state: `diff -u runs/CURRENT_RUN/input.md runs/CURRENT_RUN/output.md > runs/CURRENT_RUN/diff.patch`. The input.md copy in the run directory is written at run start before any passes execute — it is the pristine original.
**Warning signs:** `diff.patch` is small (< 20 lines) for a draft that had substantial revision, suggesting diff was run against wrong pair.

### Pitfall 6: Metadata Timestamps Are Approximate
**What goes wrong:** Timestamps in metadata.json are noted as strings rather than ISO 8601 format, or the run_start timestamp is recorded after the first pass completes rather than at run initialization.
**Why it happens:** SKILL.md execution is Claude generating text — timestamps must be explicitly requested and formatted. Without explicit instructions, Claude produces human-readable but machine-inconsistent timestamps.
**How to avoid:** Specify ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`) in SKILL.md. Run_start is recorded first thing, before any pass execution. Use shell `date -u +"%Y-%m-%dT%H:%M:%SZ"` for the timestamp value.
**Warning signs:** metadata.json timestamps are in mixed formats, or run_start is after the first pass completion timestamp.

### Pitfall 7: Notes Input Treated as Draft
**What goes wrong:** User submits rough notes for expansion into a blog post. The `/improve` skill treats them as a polished draft with weak structure and tries to "clarify" fragments rather than expand them. Output is marginally improved notes, not a draft.
**Why it happens:** Detection logic is either absent or too lenient — full-sentence threshold is set too high, missing clear notes.
**How to avoid:** Detection happens at the diagnosis step. Notes signals (bullets, fragments, ideas without development, word count under 40% of expected form length) must trigger notes-to-draft mode explicitly. The diagnosis must label this mode: "Input classified as: rough notes." The structure pass in notes mode has explicit permission to create new sections from loose ideas.
**Warning signs:** diagnosis.md does not contain an "Input classified as" declaration.

---

## Code Examples

### Run Directory Creation Shell Block

```bash
# Source: CONTEXT.md locked decision — run directory format
RUN_DIR="runs/$(date +"%Y-%m-%d_%H-%M-%S")_${PRESET_ID}"
mkdir -p "${RUN_DIR}/passes"
cp "${INPUT_FILE}" "${RUN_DIR}/input.md"

# Update latest pointer (POSIX)
ln -sfn "$(basename ${RUN_DIR})" runs/latest

# Update latest pointer (Windows fallback)
# echo "${RUN_DIR}" > runs/latest.txt
```

### Unified Diff Generation

```bash
# Source: CONTEXT.md locked decision — diff -u format
diff -u "${RUN_DIR}/input.md" "${RUN_DIR}/output.md" > "${RUN_DIR}/diff.patch" || true
# Note: diff exits 1 if files differ, which is expected. The '|| true' prevents script failure.
```

### Metadata JSON Template

```json
{
  "run_id": "YYYY-MM-DD_HH-MM-SS_PRESET-ID",
  "preset_id": "blog-post",
  "preset_version": "1.0.0",
  "input_file": "drafts/FILENAME.md",
  "input_type": "draft",
  "depth": "standard",
  "stages_run": ["diagnose", "revision-plan", "structure", "clarity", "argument", "tone", "concision", "hook", "ending", "final-review"],
  "timestamps": {
    "run_start": "2026-04-05T14:32:01Z",
    "run_end": "2026-04-05T14:38:22Z"
  },
  "word_counts": {
    "input": 847,
    "output": 793
  }
}
```

### SKILL.md Pass Execution Block (Pseudocode Pattern)

```markdown
## Pass Execution Loop

For each stage listed in `preset.stages` (after diagnose and revision-plan):

1. Read the current draft state from the previous pass output (or input.md for first pass)
2. Load the pass-specific scope rules from `.claude/rules/passes/<stage-name>.md`
3. Inject into the pass context:
   - The preset's `voice` block and `voiceBehaviors` array (verbatim)
   - The pass scope rules (what may and may not be changed)
   - The revision plan (specific changes to address)
   - CLAUDE.md factual integrity rules (no fabrication, no citation invention)
4. Execute the pass
5. Write output to `runs/CURRENT_RUN/passes/NN-<stage-name>.md`
   where NN is the zero-padded pass number (01, 02, ...)
```

### Notes vs Draft Detection in Diagnosis Prompt

```markdown
## Step 1 of Diagnosis: Classify Input Type

Before diagnosing weaknesses, classify the input:

**Rough Notes** if three or more of these are true:
- Contains bullet points or numbered lists as primary structure
- Contains sentence fragments (not stylistic — genuinely incomplete thoughts)
- Contains "TODO:", "expand this:", or similar placeholder notes
- Fewer than 40% of the expected word count for this writing form
- Claims without supporting evidence or elaboration

**Polished Draft** if:
- Full sentences throughout
- Recognizable introduction, body, and closing structure
- Arguments have at least partial evidence
- Word count is 60%+ of expected form length

**Record the classification in diagnosis.md as the first line:**
`Input classified as: [rough notes | polished draft]`

This classification determines pass depth and structure pass latitude.
```

### Explanation.md Format

```markdown
# Revision Explanation

## Structure Pass
- **Moved thesis to opening paragraph**: The central claim ("X is the right approach because Y") was buried in paragraph 4. Moved to paragraph 1, sentence 2. Diagnosis: buried lede.
- **Reordered sections 3 and 4**: Section 4 (counterargument) was introduced before the main case was established. Moved after section 3 (evidence) to follow standard argument arc.

## Clarity Pass
- **Broke up paragraph 2, sentence 3**: "The system, which was built over three years and which was eventually deprecated, caused significant problems" → two sentences. One idea per sentence per blog-post preset voice rule.

## Concision Pass
- **Cut paragraph 6**: Full paragraph restated the opening claim without adding new information. Removed.
```

---

## Open Questions

1. **Pass-specific rules directory naming**
   - What we know: `.claude/rules/` is established; `passes/` subdirectory is one option
   - What's unclear: Whether `.claude/rules/passes/structure.md` activates cleanly when skill explicitly loads it vs using `paths:` frontmatter
   - Recommendation: Load pass rules explicitly in SKILL.md by referencing the file path directly in the pass prompt context, rather than relying on `paths:` frontmatter auto-activation. Explicit loading is more reliable for per-pass execution.

2. **`/adapt` preset loading when the input preset differs from target**
   - What we know: `/adapt @draft.md --to essay` reuses the improve engine with the target preset
   - What's unclear: Whether passes should be driven by the *source* preset (current form) or *target* preset (destination form) for the early passes
   - Recommendation: Use the target preset for all passes in adapt mode. The structure pass in particular must know the target form's structure expectations. Voice passes should blend — preserve the author's voice while adopting the target form's register conventions.

3. **`--depth light` pass selection (Claude's discretion)**
   - What we know: `light` = 3 core passes; CONTEXT.md specifies "diagnose, plan, structure"
   - What's unclear: Whether "structure" is always the right third pass for all presets, or whether SKILL.md should select the highest-weight stage from the preset's rubric
   - Recommendation: Lock the light-depth passes as `["diagnose", "revision-plan", "structure"]` for predictability. The goal of light depth is a quick structural fix, not a full rubric-weighted improvement.

---

## Sources

### Primary (HIGH confidence)
- `CONTEXT.md` — all locked decisions in this phase; treated as authoritative specification
- `presets/blog-post.json`, `presets/argumentative-essay.json`, `presets/technical-explainer.json` — actual preset files produced in Phase 1; verified directly
- `presets/preset-schema.json` — actual schema file; verified directly
- `CLAUDE.md` (project) — universal safety rules; verified directly
- `.claude/rules/preset-editing.md` — established rules file pattern; verified directly
- `.planning/phases/01-foundation-and-presets/01-RESEARCH.md` — Phase 1 research, verified Claude Code primitives and patterns

### Secondary (MEDIUM confidence)
- `PROJECT.md` and `STATE.md` — project context and accumulated decisions; verified directly

### Tertiary (LOW confidence)
- None — all research findings are derived from project-internal verified sources

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — primitives verified against Phase 1 research and actual project files
- Architecture: HIGH — patterns derived from locked CONTEXT.md decisions and established Phase 1 conventions
- Pitfalls: HIGH — derived from first-principles analysis of multi-pass LLM revision failure modes and CONTEXT.md specifics

**Research date:** 2026-04-05
**Valid until:** Stable indefinitely — Claude Code-native system with no external dependencies or library versions to expire
