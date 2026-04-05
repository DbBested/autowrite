# /improve

Revise a draft or notes file using form-aware staged passes. This skill orchestrates the full revision workflow: load preset, detect input type, create run directory, execute staged passes sequentially, generate diff, write explanation, and record metadata.

## Invocation

```
/improve @<draft-file> [--preset <preset-id>] [--depth light|standard|deep]
```

- `@<draft-file>` — required: the file to improve (e.g., `@drafts/my-post.md`)
- `--preset` — optional: preset ID to use (e.g., `--preset blog-post`). If omitted, auto-infer from content.
- `--depth` — optional: `light`, `standard`, or `deep`. Default: `standard`

---

## Step 1: Load Preset

### If `--preset` is specified

Load `presets/<preset-id>.json`. If the file does not exist, STOP and say:
> "Preset not found: presets/<preset-id>.json. Available presets: blog-post, argumentative-essay, technical-explainer"

### If `--preset` is NOT specified — auto-infer

Read the draft content and check for form signals:

| Signal | Inferred Preset |
|--------|-----------------|
| First-person throughout, contractions, short paragraphs, opinion-driven, no citations | `blog-post` |
| Formal register, thesis statement, counterargument section, citations present | `argumentative-essay` |
| Technical terms, code examples, "how to" structure, numbered steps, procedure-oriented | `technical-explainer` |
| Multiple signals match or signals are ambiguous | Ask user |

If inference confidence is low (multiple forms compete equally), STOP and say:
> "I can't confidently determine the writing form from the content. Please re-run with `--preset blog-post`, `--preset argumentative-essay`, or `--preset technical-explainer`."

Do not guess silently when confidence is low — the wrong preset produces incorrectly scoped passes.

### After loading preset

Read the full preset JSON. Extract and store:
- `id`, `version`, `stages`, `voice`, `voiceBehaviors`, `goals`, `structure`, `rubric`, `constraints`, `transformations`

Validate safety constraints — if any of the following are `false`, STOP and warn the user:
- `constraints.no_citation_invention`
- `constraints.no_stance_shift`
- `transformations.preserveVoice`

---

## Step 2: Create Run Directory

Use the Bash tool to execute these commands:

```bash
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
PRESET_ID="<preset.id>"
RUN_DIR="runs/${TIMESTAMP}_${PRESET_ID}"
mkdir -p "${RUN_DIR}/passes"
cp "<draft-file>" "${RUN_DIR}/input.md"

# Update latest pointer
# On POSIX (Mac/Linux):
ln -sfn "$(basename ${RUN_DIR})" runs/latest

# On Windows (if ln fails):
echo "${RUN_DIR}" > runs/latest.txt
```

Record `RUN_START` timestamp immediately after directory creation:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Record input word count:
```bash
wc -w < "${RUN_DIR}/input.md"
```

Store both values — they become `timestamps.run_start` and `word_counts.input` in `metadata.json`.

**Important:** `${RUN_DIR}/input.md` is the pristine original. It must never be modified after this copy. All diffs are computed against it.

---

## Step 3: Determine Depth and Pass Sequence

Read the `--depth` flag (default: `standard`).

**`light`:** Run only `["diagnose", "revision-plan", "structure"]` regardless of preset stages. Goal: quick structural fix.

**`standard`:** Run all stages from `preset.stages` exactly as ordered.

**`deep`:** Run all stages from `preset.stages`, then:
1. Re-read `${RUN_DIR}/diagnosis.md`
2. Identify the rubric criterion with the lowest confidence or most severe finding
3. Run one additional targeted pass on that weakest area

Store the final selected list as `STAGES_TO_RUN`.

---

## Step 4: Execute Diagnosis Pass

The diagnosis pass is always first. It is read-only — it produces `diagnosis.md` but must not modify the draft.

**Load scope rules:** Read `.claude/rules/passes/diagnose.md` completely before proceeding.

**Read the draft:** Read `${RUN_DIR}/input.md` completely.

**Inject into diagnosis context:**
- Preset `goals` array — what "good" looks like for this form
- Preset `structure.sectionOrder` or `structure.expectedSections` — what structure is expected
- Preset `rubric.criteria` — what will be evaluated
- CLAUDE.md safety rules (factual integrity, voice preservation, stance integrity)

**Produce `${RUN_DIR}/diagnosis.md`** with these required sections:

```markdown
Input classified as: [rough notes | polished draft]

## Author Voice Patterns
[Document the author's characteristic patterns: contractions, fragments, first-person, sentence length habits, register. These are anchors for every subsequent pass — not weaknesses.]

## Weaknesses by Category

### Structure
- [Specific, located finding: paragraph and sentence reference. Example: "Buried thesis: central claim first appears in paragraph 4, sentence 2"]

### Clarity
- [Specific, located findings]

### Argument
- [Specific, located findings — flag unsubstantiated claims by location]

### Voice
- [Voice pattern inconsistencies, if any]

### Concision
- [Redundant sections, filler paragraphs — named by location]

### Form-Specific Issues
- [Issues specific to the preset form, from rubric criteria]
```

**Classification criteria** (from `.claude/rules/passes/diagnose.md`):

*Rough Notes* if three or more of these are true:
- Contains bullet points or numbered lists as primary structure
- Contains sentence fragments (not stylistic — genuinely incomplete thoughts)
- Contains "TODO:", "expand this:", or similar placeholder notes
- Fewer than 40% of expected word count for this writing form
- Claims without supporting evidence or elaboration

*Polished Draft* if:
- Full sentences throughout
- Recognizable introduction, body, and closing structure
- Arguments have at least partial evidence
- Word count is 60%+ of expected form length

**If input is classified as rough notes:** Add a note in `diagnosis.md` that expanded structure pass latitude is needed, and that voice establishment (not preservation) is the goal for subsequent passes.

**Diagnosis rule:** Every weakness must name a specific location. "Thesis is weak" is not acceptable. "Buried thesis: central claim first appears in paragraph 4, sentence 2" is the required format.

---

## Step 5: Execute Revision Plan Pass

The revision-plan pass is always second. It is read-only — it produces `plan.md` but must not modify the draft.

**Load scope rules:** Read `.claude/rules/passes/revision-plan.md` completely before proceeding.

**Read:** `${RUN_DIR}/diagnosis.md`

**Produce `${RUN_DIR}/plan.md`** with:

```markdown
# Revision Plan

## Pass Assignments

| Pass | Change | Diagnosis Finding | Location |
|------|--------|-------------------|----------|
| structure | Move thesis to opening | Buried thesis, paragraph 4 sentence 2 | Paragraph 1 |
| clarity | Break up run-on in paragraph 6 | Ambiguous on first read | Paragraph 6, sentence 3 |
| ... | ... | ... | ... |

## Voice Preservation Risks

[Flag specific passes where voice is at risk. Example: "Clarity pass on paragraph 3 — author uses intentional fragments for emphasis; preserve them."]

## Factual Integrity Notes

[Flag any diagnosis findings that require caution during revision. Example: "Claim in paragraph 5 has no supporting evidence — passes must not invent evidence; flag for author instead."]
```

Each planned change must state:
1. Which pass will address it
2. What will change
3. Which diagnosis finding it addresses (by location reference from `diagnosis.md`)

**This pass produces `plan.md` only. No draft changes.**

---

## Step 6: Execute Revision Passes

For each remaining stage in `STAGES_TO_RUN` (after `diagnose` and `revision-plan`, excluding `final-review`):

### Data Flow (Critical — read this carefully)

**The revision chain reads the previous pass's draft output, NOT the diagnosis or plan.**

```
input.md ──► diagnosis.md ──► plan.md     (planning chain — reference only)
input.md ──► pass-01.md ──► pass-02.md ──► ... ──► output.md   (revision chain)
```

Diagnosis and plan are REFERENCE documents. They are not inputs to the revision chain.

- For the FIRST revision pass: read `${RUN_DIR}/input.md`
- For subsequent passes: read `${RUN_DIR}/passes/NN-<prev-stage>.md` (the previous pass output)

### Per-Pass Execution Protocol

For each stage:

1. **Determine current draft state:** Previous pass output (or `input.md` for first pass)
2. **Load pass scope rules:** Read `.claude/rules/passes/<stage-name>.md` completely
3. **Inject into pass context — EVERY PASS WITHOUT EXCEPTION:**
   - The preset's `voice` block (all 5 fields: `tone`, `formality`, `sentenceLength`, `paragraphStyle`, `rhetoricalStyle`)
   - The preset's `voiceBehaviors` array (all 8 behavioral descriptions — verbatim, not summarized)
   - The pass scope rules (what may and must not be changed)
   - The specific changes assigned to this pass from `plan.md`
   - CLAUDE.md factual integrity rules (no fabrication, no citation invention)
   - If input was classified as "rough notes": note expanded latitude for structure/argument passes
4. **Execute the pass:** Revise the draft within the pass's defined scope only
5. **Write output:** `${RUN_DIR}/passes/NN-<stage-name>.md` where NN is zero-padded (01, 02, 03...)

**Why voice must be injected per-pass:** Voice constraints stated once at the SKILL.md level are forgotten as subsequent passes execute in fresh context. "Preserve author voice" as a global instruction is insufficient. The specific `voice` block and `voiceBehaviors` array must be present in each individual pass's execution context to prevent incremental voice drift.

### Pass Number Assignment

Pass numbers start at 01 for the first revision pass (after diagnose and revision-plan). Do not number the planning passes.

Example for blog-post standard depth:
- `passes/01-structure.md`
- `passes/02-clarity.md`
- `passes/03-argument.md`
- `passes/04-tone.md`
- `passes/05-concision.md`
- `passes/06-hook.md`
- `passes/07-ending.md`

---

## Step 7: Final Review and Artifacts

**Load scope rules:** Read `.claude/rules/passes/final-review.md` completely before proceeding.

This pass is READ-ONLY. Do not modify the draft text. Read the last revision pass output.

Produce all four artifacts:

### Artifact 1: `${RUN_DIR}/output.md`

Clean copy of the last revision pass output. No annotations, no markup, no tracked changes, no explanatory comments. This is the deliverable the user reads.

### Artifact 2: `${RUN_DIR}/diff.patch`

```bash
diff -u "${RUN_DIR}/input.md" "${RUN_DIR}/output.md" > "${RUN_DIR}/diff.patch" || true
```

Note: `diff` exits with code 1 when files differ, which is expected. The `|| true` prevents failure.

Diff is always computed between the pristine `input.md` and the final `output.md` — never between intermediate pass files.

### Artifact 3: `${RUN_DIR}/explanation.md`

Per-change explanations grouped by pass. One explanation per substantive change — not per word change.

Required format:

```markdown
# Revision Explanation

## Structure Pass
- **Change description**: What changed, where (paragraph N, sentence N), and why (referencing the specific diagnosis finding or plan item).

## Clarity Pass
- **Change description**: ...
```

Each entry must include: which pass, what changed, where (paragraph/sentence reference), why (diagnosis finding or plan item). Summaries like "improved the structure" are not acceptable.

If a pass chose NOT to change something in order to preserve voice, document that decision here too.

If factual integrity prevented a change (e.g., "could not strengthen evidence — no source material available"), document it here so the author knows what requires their input.

### Artifact 4: `${RUN_DIR}/metadata.json`

Record the run end timestamp first:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Record output word count:
```bash
wc -w < "${RUN_DIR}/output.md"
```

Write `${RUN_DIR}/metadata.json`:

```json
{
  "run_id": "<TIMESTAMP>_<PRESET_ID>",
  "preset_id": "<preset.id>",
  "preset_version": "<preset.version>",
  "input_file": "<original draft file path>",
  "input_type": "draft | rough notes",
  "depth": "light | standard | deep",
  "stages_run": ["diagnose", "revision-plan", "..."],
  "timestamps": {
    "run_start": "<ISO 8601 — recorded at Step 2>",
    "run_end": "<ISO 8601 — recorded now>"
  },
  "word_counts": {
    "input": 0,
    "output": 0
  }
}
```

- `run_id` format: `YYYY-MM-DD_HH-MM-SS_preset-id` (matches the run directory name)
- `stages_run` must reflect the actual stages executed, in order
- All timestamps must be ISO 8601 format: `YYYY-MM-DDTHH:MM:SSZ`
- `timestamps.run_start` is the value captured at Step 2 (before any passes ran)

---

## Voice Preservation Contract

These rules apply on EVERY pass without exception. They are not a global setting to be stated once — they are injected into each individual pass execution context.

1. **The preset's `voice` block and `voiceBehaviors` array are injected into every pass context** — not just the first or last pass. Voice drift happens incrementally across passes; the only defense is per-pass anchoring.

2. **When vocabulary choice is ambiguous, the author's choice wins.** Do not substitute vocabulary unless the word genuinely obscures meaning for the target audience.

3. **Aggressive rewrites require explicit user request.** Check `transformations.aggressiveness` in the preset. Default behavior is conservative.

4. **If input is rough notes:** The goal is voice ESTABLISHMENT (matching the preset's target voice for the form), not voice PRESERVATION. The author's notes may not have a consistent voice yet — do not anchor to an incoherent register.

5. **Fragment sentences that are stylistic (matching preset `voiceBehaviors`) are not errors to fix.** Only fix fragments that are genuinely unclear.

---

## Factual Integrity Contract

These rules are verbatim from CLAUDE.md and apply on EVERY pass without exception.

- Never invent citations or references not present in the source draft
- Never fabricate statistics, examples, or claims
- Never add factual assertions the author did not make
- Never silently shift the author's argumentative position
- Argument passes clarify existing claims — they do not strengthen or weaken the author's actual position

**Highest-risk passes:** evidence and argument passes. Apply extra vigilance on these passes. If evidence is missing for a claim, flag it for the author — do not invent it.

---

## Completion

After all artifacts are written, display to the user:

```
Run complete.

Run directory: runs/<TIMESTAMP>_<PRESET_ID>/
Input type:    [draft | rough notes]
Preset used:   <preset.id> v<preset.version>
Depth:         <light | standard | deep>
Passes run:    <N> passes (<list of stage names>)
Word count:    <input> words → <output> words (<+/- delta>)

Output:  runs/<TIMESTAMP>_<PRESET_ID>/output.md
Diff:    runs/<TIMESTAMP>_<PRESET_ID>/diff.patch
Changes: runs/<TIMESTAMP>_<PRESET_ID>/explanation.md
```
