---
name: autoloop
description: Run a mutation-eval self-improvement cycle on a preset. Proposes atomic mutations, measures impact via /eval, keeps only improvements. Usage: /autoloop --target presets/blog-post.json --iterations 5 --reference-draft @drafts/ref.md
---

# /autoloop

Run a mutation-eval self-improvement cycle on a preset file. Each iteration proposes one atomic change to a preset field, measures the change's effect by running the writing engine and evaluating the output, and keeps the change only when scores measurably improve without critical regressions. A holdout set guards against Goodhart's Law overfitting.

---

## Invocation

```
/autoloop --target presets/<id>.json --iterations <N> --reference-draft @<file.md>
```

All three flags are required.

- `--target` — the preset file to mutate (must be in `presets/` directory)
- `--iterations` — number of mutation attempts (positive integer, 1-20)
- `--reference-draft` — fixed reference draft for comparable before/after scoring

---

## Step 1: Argument Parsing and Validation

### Step 1a — Validate `--target`

Resolve the path provided to `--target`.

The target must be a file in the `presets/` directory — no other paths are permitted. Mutation scope is restricted to prevent accidental mutation of skills, CLAUDE.md, or other system files.

If the path does not begin with `presets/`:
> STOP: "Autoloop targets are restricted to presets/*.json files. Received: \<path\>"

If the file does not exist:
> STOP: "Target preset not found: \<path\>"

Extract the preset ID from the filename (strip `presets/` prefix and `.json` suffix). This will be `<preset-id>` in all subsequent steps.

### Step 1b — Validate `--iterations`

Check that `--iterations` is a positive integer between 1 and 20.

If not a positive integer or not provided:
> STOP: "Iterations must be a positive integer between 1 and 20."

If greater than 20:
> STOP: "Maximum 20 iterations to prevent context exhaustion. Received: \<N\>"

If not provided, default to 5.

### Step 1c — Validate `--reference-draft`

The `--reference-draft` flag is required. Fail loudly if not provided — running eval without a fixed reference draft destroys score comparability (scores would then reflect input variance, not preset mutation effects).

If `--reference-draft` is not provided:
> STOP: "Reference draft not found: \<path\>. The autoloop requires a fixed reference draft to produce comparable before/after scores. Use --reference-draft @\<file.md\>."

If the file does not exist:
> STOP: "Reference draft not found: \<path\>. The autoloop requires a fixed reference draft to produce comparable before/after scores."

Extract a slug from the reference draft filename (strip path and extension) — this is `<draft-slug>` in all subsequent steps.

### Step 1d — Holdout Check

Run:
```bash
ls autoloop/holdout/*.md 2>/dev/null | wc -l
```

If the count is zero, display the following warning and pause for user confirmation:

```
WARNING: autoloop/holdout/ is empty.

Running the autoloop without a holdout set removes Goodhart's Law protection. The
loop will optimize against its own eval criteria. Within 10-20 iterations, the preset
may be tuned to score well without producing better writing.

Recommended: place 1-3 holdout texts in autoloop/holdout/ and rerun.

To continue without holdout protection (not recommended), reply 'yes, continue without holdout'.
To abort and add holdout texts first, reply 'abort'.
```

Wait for user response. Do not proceed until the user explicitly confirms or aborts.

---

## Step 2: Create Run Directory

Generate a timestamp for the run directory:
```bash
TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S")
RUN_DIR="autoloop/runs/${TIMESTAMP}"
```

Create the run directory structure:
```bash
mkdir -p "${RUN_DIR}/backup" "${RUN_DIR}/reference-outputs" "${RUN_DIR}/evals"
```

Immediately copy the target preset file to backup:
```bash
cp "presets/<preset-id>.json" "${RUN_DIR}/backup/<preset-id>.json"
```

This backup is the restore point for all rejected mutations and for any halt condition.

The `mutations.jsonl` file will be appended to at `${RUN_DIR}/mutations.jsonl` — do not create it now; the first append will create it.

---

## Step 3: Run Baseline Eval

This step establishes the pre-mutation score baseline. All subsequent mutation decisions are relative to this baseline.

**Why this matters:** Running eval on arbitrary text measures that text's quality, not the preset's effect. The correct approach is to run the writing engine on a fixed reference draft and eval the engine's output. Only then do score changes reflect the preset mutation's effect.

1. Run the writing engine on the reference draft with the current (unmutated) preset:
   ```
   /improve @<reference-draft-path> --preset <preset-id>
   ```

2. Copy the writing engine output to the run directory:
   ```bash
   cp "runs/<latest-run>/output.md" "${RUN_DIR}/reference-outputs/<draft-slug>-before.md"
   ```
   Read `runs/latest.txt` (Windows) or follow `runs/latest` symlink (POSIX) to find the latest run directory.

3. Run eval on the baseline output:
   ```
   /eval @${RUN_DIR}/reference-outputs/<draft-slug>-before.md --preset <preset-id>
   ```

4. Copy the eval result to the run directory:
   ```bash
   cp "runs/<latest-eval-output>/eval.json" "${RUN_DIR}/evals/<draft-slug>-before.json"
   ```
   If `/eval` wrote to a standalone `evals/` path (because the file was not inside a `runs/` directory), find it there.

5. Read the baseline scores from `${RUN_DIR}/evals/<draft-slug>-before.json`:
   ```bash
   jq '.aggregate_score' "${RUN_DIR}/evals/<draft-slug>-before.json"
   jq '.criteria[] | {name: .name, score: .score}' "${RUN_DIR}/evals/<draft-slug>-before.json"
   ```

Store the baseline aggregate score and all per-criterion scores. These are the "current scores" for iteration 1.

---

## Step 4: Iteration Loop

Repeat the following sub-steps for each iteration from 1 to N.

At the start of each iteration, "current scores" are:
- Iteration 1: the baseline scores from Step 3
- Subsequent iterations: the scores from the last ACCEPTED mutation (or baseline if no mutations have been accepted yet)

---

### Step 4a: Select Mutation Target

Use the weakest-criterion-first selection strategy:

1. Read the current scores (baseline for iteration 1, post-mutation scores for subsequent iterations)
2. Find the criterion with the lowest score
3. Map that criterion to the most relevant preset field using this table:

| Lowest Criterion | Mutation Target Field |
|------------------|----------------------|
| `voice_preservation` | `voiceBehaviors` array (add/refine a behavioral rule) or `voice.rhetoricalStyle` |
| `clarity` | stage order in `stages` (move clarity pass earlier?) or `rubric.criteria[clarity].description` (tighten the criterion signal) |
| `structure` | `stages` ordering or `structure.expectedSections` (add/reorder structural expectations) |
| `novelty` | `rubric.criteria[novelty].description` (anchor observable signals for novelty, not holistic judgment) |
| `concision` | `stages` (add or reorder concision pass) |
| `audience_fit` | `voice.formality` or `voiceBehaviors` (add audience-specific register rule) |
| `factual_integrity` | `rubric.criteria[factual_integrity].description` (tighten anchoring to specific observable behaviors) |

4. If the weakest criterion was the target of the last 2 consecutive mutations, round-robin to the next-weakest criterion instead. This prevents fixating on one criterion indefinitely.

5. Propose exactly ONE change to the identified field. Write a rationale explaining why this specific mutation should improve the score for the weakest criterion.

---

### Step 4b: Apply Mutation

1. Read the current target preset file:
   ```
   Read presets/<preset-id>.json
   ```

2. Apply the proposed change — modify exactly one field or section. The change must be:
   - Atomic: one field only
   - Isolated: does not cascade to other fields without explicit intent
   - Reversible: can be restored from `${RUN_DIR}/backup/`

3. Write the mutated preset to `presets/<preset-id>.json`.

4. Bump the preset's `version` field by one patch increment:
   - `1.0.0` → `1.0.1`
   - `1.0.7` → `1.0.8`

5. Run preset validation:
   ```bash
   bash scripts/validate-preset.sh presets/<preset-id>.json
   ```

   If validation fails:
   - Restore the original from backup:
     ```bash
     cp "${RUN_DIR}/backup/<preset-id>.json" "presets/<preset-id>.json"
     ```
   - Append a rejection record to `mutations.jsonl` (see Step 4e format, use `"decision": "rejected"` and `"decision_reason": "validation_failed: <error message from validate-preset.sh>"`)
   - Continue to the next iteration — do NOT stop the loop

---

### Step 4c: Run Post-Mutation Eval

1. Run the writing engine on the same reference draft with the MUTATED preset:
   ```
   /improve @<reference-draft-path> --preset <preset-id>
   ```

2. Copy the writing engine output to the run directory:
   ```bash
   cp "runs/<latest-run>/output.md" "${RUN_DIR}/reference-outputs/<draft-slug>-after-iter-<N>.md"
   ```

3. Run eval on the post-mutation output:
   ```
   /eval @${RUN_DIR}/reference-outputs/<draft-slug>-after-iter-<N>.md --preset <preset-id>
   ```

4. Copy the eval result:
   ```bash
   cp "<eval-output-path>" "${RUN_DIR}/evals/<draft-slug>-after-iter-<N>.json"
   ```

5. Read the post-mutation scores:
   ```bash
   jq '.aggregate_score' "${RUN_DIR}/evals/<draft-slug>-after-iter-<N>.json"
   jq '.criteria[] | {name: .name, score: .score}' "${RUN_DIR}/evals/<draft-slug>-after-iter-<N>.json"
   ```

---

### Step 4d: Acceptance Decision

ALL four conditions must be true for acceptance:

```
Condition 1: scores_after.aggregate > scores_before.aggregate          (any improvement)
Condition 2: scores_after.factual_integrity >= 6                       (critical floor)
Condition 3: scores_after.voice_preservation >= 6                     (critical floor)
Condition 4: For EACH criterion C: scores_after[C] >= scores_before[C] - 2   (no criterion drops > 2 pts)
```

Extract scores for comparison:
```bash
BEFORE_AGG=$(jq '.aggregate_score' "${RUN_DIR}/evals/<draft-slug>-before.json")
AFTER_AGG=$(jq '.aggregate_score' "${RUN_DIR}/evals/<draft-slug>-after-iter-<N>.json")

# Condition 1: aggregate improved
IMPROVED=$(echo "$BEFORE_AGG $AFTER_AGG" | awk '{ print ($2 > $1) ? "yes" : "no" }')

# Condition 2: factual_integrity >= 6
FACTUAL_OK=$(jq '.criteria[] | select(.name == "factual_integrity") | .score >= 6' "${RUN_DIR}/evals/<draft-slug>-after-iter-<N>.json")

# Condition 3: voice_preservation >= 6
VOICE_OK=$(jq '.criteria[] | select(.name == "voice_preservation") | .score >= 6' "${RUN_DIR}/evals/<draft-slug>-after-iter-<N>.json")

# Condition 4: no criterion dropped > 2 points (check each criterion individually)
```

**If ALL conditions true — ACCEPT:**
- Keep the mutated preset file as-is
- Update "current scores" to post-mutation scores for the next iteration
- Save accepted mutation diff:
  ```bash
  diff -u "${RUN_DIR}/backup/<preset-id>.json" "presets/<preset-id>.json" > "autoloop/accepted/${TIMESTAMP}-iter-<N>.patch" || true
  ```
- Update the backup to reflect the newly accepted version:
  ```bash
  cp "presets/<preset-id>.json" "${RUN_DIR}/backup/<preset-id>.json"
  ```

**If ANY condition false — REJECT:**
- Identify which conditions failed (for the decision_reason field)
- Restore the preset from backup:
  ```bash
  cp "${RUN_DIR}/backup/<preset-id>.json" "presets/<preset-id>.json"
  ```
- Current scores remain unchanged (stay at the previous accepted state)

---

### Step 4e: Log Mutation

Append exactly ONE JSONL line to `${RUN_DIR}/mutations.jsonl`. Never read-parse-rewrite this file — only append.

```bash
cat >> "${RUN_DIR}/mutations.jsonl" << 'EOF'
{"iteration":N,"timestamp":"<ISO 8601>","target_asset":"presets/<id>.json","mutated_field":"<field.path>","mutation_rationale":"<why this mutation should improve scores>","diff":"<unified diff of the change>","scores_before":{"novelty":N,"clarity":N,"structure":N,"voice_preservation":N,"audience_fit":N,"concision":N,"factual_integrity":N,"aggregate":N.NN},"scores_after":{"novelty":N,"clarity":N,"structure":N,"voice_preservation":N,"audience_fit":N,"concision":N,"factual_integrity":N,"aggregate":N.NN},"decision":"accepted|rejected","decision_reason":"<specific reason citing which conditions passed or failed>"}
EOF
```

Required fields:
- `iteration` — integer, the current iteration number
- `timestamp` — ISO 8601 UTC (`date -u +"%Y-%m-%dT%H:%M:%SZ"`)
- `target_asset` — the preset file path (e.g., `"presets/blog-post.json"`)
- `mutated_field` — dot-notation path to the changed field (e.g., `"rubric.criteria[voice_preservation].description"`)
- `mutation_rationale` — one to two sentences explaining why this mutation should improve the target criterion
- `diff` — unified diff of the change (`diff -u before after` output)
- `scores_before` — all criterion scores plus aggregate from the current-baseline eval
- `scores_after` — all criterion scores plus aggregate from the post-mutation eval (or all zeros if validation failed before eval ran)
- `decision` — `"accepted"` or `"rejected"` or `"validation_failed"`
- `decision_reason` — specific language naming which condition(s) failed, e.g., `"Condition 1 failed: aggregate did not improve (7.15 -> 7.10)"` or `"All 4 conditions passed: aggregate 7.15 -> 7.35 (+0.20)"`

---

### Step 4f: Holdout Check

Run the holdout check at iterations 3, 6, 9, 12, 15, 18, and at the final iteration.

Check whether it is a holdout iteration:
```bash
if [[ $((ITERATION % 3)) -eq 0 ]] || [[ $ITERATION -eq $N_ITERATIONS ]]; then
  # Run holdout check
fi
```

**Holdout check protocol:**

1. Find all `.md` files in `autoloop/holdout/`:
   ```bash
   HOLDOUT_FILES=$(ls autoloop/holdout/*.md 2>/dev/null)
   ```

   If no files found (directory is now empty): skip the holdout check and log a warning. Do not halt.

2. For each holdout text file:
   a. Run the writing engine with the current preset:
      ```
      /improve @autoloop/holdout/<holdout-file>.md --preset <preset-id>
      ```
   b. Run eval on the output:
      ```
      /eval @runs/<latest-run>/output.md --preset <preset-id>
      ```
   c. Copy the eval to the run directory:
      ```bash
      cp "<eval-output>" "${RUN_DIR}/evals/holdout-<slug>-iter-<N>.json"
      ```
   d. Extract the holdout aggregate score:
      ```bash
      jq '.aggregate_score' "${RUN_DIR}/evals/holdout-<slug>-iter-<N>.json"
      ```

3. Compute the holdout aggregate: average of all holdout text aggregate scores.

4. Compute the loop aggregate: average of `scores_after.aggregate` from the last 3 entries in `mutations.jsonl`:
   ```bash
   LOOP_AVG=$(tail -3 "${RUN_DIR}/mutations.jsonl" | jq -s '[.[].scores_after.aggregate] | add / length')
   ```

5. Compute delta: `|holdout_aggregate - loop_aggregate|`

6. If delta > 1.0:
   - Append halt record to `mutations.jsonl`:
     ```json
     {"iteration": N, "decision": "HALTED", "decision_reason": "Holdout divergence: holdout_aggregate=X.XX, loop_aggregate=Y.YY, delta=Z.ZZ > 1.0 threshold"}
     ```
   - Restore the original preset from the initial backup (before any mutations):
     ```bash
     cp "${RUN_DIR}/backup/<preset-id>.json" "presets/<preset-id>.json"
     ```
   - Display:
     ```
     AUTOLOOP HALTED: Holdout divergence detected (delta: Z.ZZ points).
     This indicates the loop is overfitting to the reference draft.
     The original preset has been restored.
     Mutation log: autoloop/runs/<timestamp>/mutations.jsonl
     ```
   - **Stop the iteration loop immediately.**

7. If delta <= 1.0: continue to next iteration.

---

## Step 5: Completion Summary

After all iterations complete (or the loop halts), display the completion summary.

```
Autoloop complete.

Target:          presets/<id>.json
Iterations:      <N> attempted, <M> accepted, <K> rejected[, HALTED at iteration <H>]
Reference draft: <path>
Holdout texts:   <count> files checked (<0 if no holdout set was present>)

Score trajectory:
  Baseline:   <baseline-aggregate>
  Final:      <final-aggregate>  (<+/- delta>)

Accepted mutations:
  Iter 1: mutated <field> — aggregate <before> -> <after> (<+delta>)
  Iter 4: mutated <field> — aggregate <before> -> <after> (<+delta>)
  [None — all mutations rejected] (if no mutations were accepted)

Rejected mutations:
  Iter 2: mutated <field> — rejected: <condition that failed>
  [...]

Mutation log: autoloop/runs/<timestamp>/mutations.jsonl
```

If all iterations were rejected, append this advice:
```
All mutations were rejected. This may indicate the preset is already well-tuned for
this reference draft, or the mutation targets were too aggressive. Consider:
  - Using a different reference draft that exercises more of the preset's weaknesses
  - Starting with smaller mutations (e.g., adjusting rubric descriptions before touching stage order)
  - Running /eval @<reference-draft> --preset <id> directly to review baseline scores
```

---

## Edge Case Reference

| Situation | Action |
|-----------|--------|
| `--target` not in `presets/` directory | STOP — "Autoloop targets are restricted to presets/*.json files. Received: \<path\>" |
| `--target` file not found | STOP — "Target preset not found: \<path\>" |
| `--reference-draft` not provided | STOP — "Reference draft not found: \<path\>. The autoloop requires a fixed reference draft to produce comparable before/after scores." |
| `--reference-draft` file not found | STOP — "Reference draft not found: \<path\>" |
| `--iterations` not provided | Default to 5 |
| `--iterations` > 20 | STOP — "Maximum 20 iterations to prevent context exhaustion. Received: \<N\>" |
| `autoloop/holdout/` empty | WARN with Goodhart's Law explanation, ask user to confirm or abort |
| `validate-preset.sh` fails after mutation | Restore backup, log rejection with `"decision_reason": "validation_failed: \<error\>"`, continue to next iteration |
| Holdout divergence > 1.0 points | HALT loop, restore initial backup, display HALTED warning with delta value |
| All iterations rejected | Display completion summary, show tuning advice |
| `/improve` fails mid-loop | STOP loop, restore backup, display: "STOP: /improve failed during iteration \<N\>. Preset has been restored from backup." |
| `/eval` fails mid-loop | STOP loop, restore backup, display: "STOP: /eval failed during iteration \<N\>. Preset has been restored from backup." |
| Weakest criterion tied (two criteria equal low score) | Pick the first alphabetically for consistency |
| Same weakest criterion for 3+ consecutive iterations | Round-robin to next-weakest criterion |

---

## Safety Principles

**Mutation target restriction:** The `--target` flag is restricted to `presets/*.json` files only. This prevents mutation of core skills (`improve`, `eval`, `build`, `adapt`), CLAUDE.md, or any other system file. Skill instruction mutation is deferred to a future version.

**Backup-first, restore-on-reject:** The target file is copied to `backup/` before any mutation. On rejection or halt, the backup is restored. The preset file is never left in a mutated state without an accepted improvement.

**Holdout set is non-negotiable for production use:** The holdout check is the primary defense against Goodhart's Law. Without it, the loop will overfit to the reference draft's characteristics within 10-20 iterations. The empty-holdout warning is not optional UX polish — it is a critical safety gate.

**JSONL append-only:** The mutation log is never read-parse-rewritten. Only appended. This guarantees the audit trail survives partial writes, interrupted loops, and any JSON parsing edge case.

**Atomic mutations:** Each mutation changes exactly one field or section. This ensures that score changes are attributable to a single change, and that reversals restore exactly the changed state.

**Critical regression floors:** `factual_integrity` and `voice_preservation` must remain >= 6 after every accepted mutation. These are the two critical criteria in the preset schema. An improvement in novelty or structure that degrades factual integrity is always rejected.

---

## Integration Points

### How /autoloop Calls /improve

The `/improve` skill is invoked as a standard slash command within the skill workflow. The autoloop instructs Claude to run `/improve @<reference-draft-path> --preset <preset-id>` as a step in the SKILL.md instructions. The output is the latest run directory at `runs/<timestamp>_<preset-id>/output.md`.

### How /autoloop Calls /eval

The `/eval` skill is invoked as a standard slash command. After `/improve` writes `output.md`, the autoloop instructs Claude to run `/eval @<output-path> --preset <preset-id>`. The result is written to `eval.json` in the appropriate directory. The autoloop reads this file with `jq` to extract scores.

### How /autoloop Reads the Latest Run

After invoking `/improve`, read `runs/latest.txt` (Windows) or follow `runs/latest` symlink (POSIX) to find the run directory path. The `output.md` file is at `<run-dir>/output.md`.

### How Scores Are Compared

All score comparisons use `jq` arithmetic on eval.json files. The aggregate score is a float (e.g., `7.15`). Per-criterion scores are integers (1-10). The acceptance rule checks `>` (strictly greater than) for aggregate comparison — equal scores are rejected.

---

## Linked Skills and Assets

- `/improve` — writing engine that runs revision passes on the reference draft
- `/eval` — eval skill that dispatches the eval-critic subagent for scoring
- `scripts/validate-preset.sh` — validates mutated presets against preset-schema.json
- `autoloop/runs/` — run directories for backups, evals, and mutation log
- `autoloop/accepted/` — accepted mutation patch files
- `autoloop/holdout/` — holdout texts for Goodhart's Law protection
- `autoloop/reference-drafts/` — recommended location for reference drafts
- `presets/preset-schema.json` — schema all mutated presets must conform to
